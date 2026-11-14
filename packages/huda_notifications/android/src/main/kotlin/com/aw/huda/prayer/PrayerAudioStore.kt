package com.aw.huda.prayer

import android.media.MediaMetadataRetriever
import android.media.MediaExtractor
import android.media.MediaFormat
import java.io.File
import java.security.MessageDigest
import java.io.RandomAccessFile
import java.nio.ByteBuffer
import java.nio.ByteOrder

internal class PrayerAudioStore(private val runtime: PrayerNotificationRuntime) {
    private val store get() = runtime.store
    val root: File = File(runtime.context.createDeviceProtectedStorageContext().filesDir, "PrayerAudio")
    val staging: File = File(root, "staging")
    private val bundled = AudioAssetData("huda-default", "v1", "full", "android-resource:azan_sound",
        1328173, "feee769abf90bb687c5c9a9a55d129d68b824f86ab6880ab53afe6385fd3daee", 202868)
    fun storage(): AudioStorageData {
        root.mkdirs(); staging.mkdirs()
        return AudioStorageData(root.path, staging.path, bundled)
    }
    private fun key(id: String, version: String, variant: String) = "asset:$version:$id:$variant"
    fun asset(id: String, version: String, variant: String): AudioAssetData? =
        if (id == "huda-default" && version == "v1") bundled.copy(variant = variant)
        else store.read(key(id, version, variant), AudioAssetData::class.java)
    fun selectionReady(id: String, version: String) = if (id == "huda-default" && version == "v1") true else
        listOf("full", "short").all { asset(id, version, it)?.let { a -> File(a.path).isFile && File(a.path).length() == a.bytes } == true }

    fun register(pair: List<AudioAssetData>) {
        require(pair.size == 2 && pair.map { it.variant }.toSet() == setOf("full", "short") &&
            pair.map { it.reciterId to it.version }.toSet().size == 1) { "invalidAsset" }
        val promoted = pair.map { descriptor ->
            require(descriptor.reciterId != "huda-default" && PrayerRules.idPattern.matches(descriptor.reciterId) &&
                PrayerRules.versionPattern.matches(descriptor.version) && PrayerRules.digestPattern.matches(descriptor.sha256) &&
                descriptor.bytes in 1..PrayerRules.MAX_ASSET_BYTES && descriptor.durationMillis in 1..PrayerRules.MAX_DURATION_MS) { "invalidAsset" }
            require(listOf(descriptor.nameEnglish, descriptor.nameArabic).all { it == null || it.length in 1..200 }) { "invalidAsset" }
            val source = File(descriptor.path).canonicalFile
            require(source.path.startsWith(staging.canonicalPath + File.separator) && source.isFile &&
                source.length() == descriptor.bytes) { "invalidAssetPath" }
            val digest = MessageDigest.getInstance("SHA-256")
            source.inputStream().use { input ->
                val buffer = ByteArray(64 * 1024)
                while (true) { val count = input.read(buffer); if (count < 0) break; digest.update(buffer, 0, count) }
            }
            require(digest.digest().joinToString("") { "%02x".format(it) } == descriptor.sha256) { "invalidAssetHash" }
            validateCodec(source, descriptor.variant)
            val retriever = MediaMetadataRetriever()
            val duration = try {
                retriever.setDataSource(source.path)
                retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)?.toLong() ?: error("invalidAssetDuration")
            } finally { retriever.release() }
            require(duration in 1..PrayerRules.MAX_DURATION_MS && kotlin.math.abs(duration - descriptor.durationMillis) <= 1500) { "invalidAssetDuration" }
            val directory = File(root, "${descriptor.version}/${descriptor.reciterId}").apply { mkdirs() }
            val extension = if (descriptor.variant == "short") "wav" else "mp3"
            val target = File(directory, "${descriptor.variant}-${descriptor.sha256}.$extension")
            if (!target.exists()) {
                val temporary = File(directory, "${target.name}.tmp")
                source.inputStream().use { input -> temporary.outputStream().use { output -> input.copyTo(output); output.fd.sync() } }
                require(temporary.renameTo(target)) { "persistenceFailed" }
            }
            descriptor.copy(path = target.canonicalPath, durationMillis = duration)
        }
        // Immutable hash paths protect every currently selected/open version on partial failure.
        synchronized(runtime.assetLock) { store.transaction {
            promoted.forEach { descriptor ->
                val prior = asset(descriptor.reciterId, descriptor.version, descriptor.variant)
                require(prior == null || prior.sha256 == descriptor.sha256) { "immutableAssetConflict" }
                store.write(key(descriptor.reciterId, descriptor.version, descriptor.variant), descriptor)
            }
        } }
    }
    private fun validateCodec(source: File, variant: String) {
        if (variant == "full") {
            val extractor = MediaExtractor()
            try {
                extractor.setDataSource(source.path)
                require((0 until extractor.trackCount).any {
                    extractor.getTrackFormat(it).getString(MediaFormat.KEY_MIME) == "audio/mpeg"
                }) { "invalidAssetCodec" }
            } finally { extractor.release() }
        } else {
            RandomAccessFile(source, "r").use { input ->
                fun tag(): String = ByteArray(4).also { input.readFully(it) }.toString(Charsets.US_ASCII)
                fun uint32(): Long = ByteBuffer.wrap(ByteArray(4).also { input.readFully(it) })
                    .order(ByteOrder.LITTLE_ENDIAN).int.toLong() and 0xffffffffL
                require(tag() == "RIFF") { "invalidAssetCodec" }; uint32()
                require(tag() == "WAVE") { "invalidAssetCodec" }
                var pcm = false
                var data = false
                while (input.filePointer + 8 <= input.length()) {
                    val chunk = tag(); val size = uint32(); val position = input.filePointer
                    require(position + size <= input.length()) { "invalidAssetCodec" }
                    if (chunk == "fmt ") {
                        require(size >= 16) { "invalidAssetCodec" }
                        val format = ByteBuffer.wrap(ByteArray(16).also { input.readFully(it) }).order(ByteOrder.LITTLE_ENDIAN)
                        val encoding = format.short.toInt(); val channels = format.short.toInt(); val rate = format.int
                        format.int; format.short
                        val bits = format.short.toInt()
                        require(encoding == 1 && channels in 1..2 && rate in 8000..96000 && bits == 16) { "invalidAssetCodec" }
                        pcm = true
                    }
                    if (chunk == "data") data = size > 0
                    input.seek(position + size + (size % 2))
                }
                require(pcm && data) { "invalidAssetCodec" }
            }
        }
    }
    /** [only] limits removal to one recording (reciter id to version); it is still kept while in use. */
    fun removeUnreferenced(only: Pair<String, String>? = null): List<String> = synchronized(runtime.assetLock) {
        val selected = PrayerRules.prayers.map { PrayerPolicy.effective(runtime.policy(), it) }
            .map { it.reciterId to it.version }.toSet()
        val active = runtime.liveSession?.reciterId
        val deleted = mutableListOf<String>()
        for (row in store.dao.states("asset:%")) {
            val asset = store.gson.fromJson(row.value, AudioAssetData::class.java)
            if (only != null && (asset.reciterId to asset.version) != only) continue
            if ((asset.reciterId to asset.version) in selected || asset.reciterId == active) continue
            val file = File(asset.path).canonicalFile
            if (file.path.startsWith(root.canonicalPath + File.separator) && (!file.exists() || file.delete())) {
                store.dao.deleteState(row.key); deleted.add(row.key)
            }
        }
        val referenced = store.dao.states("asset:%").map { store.gson.fromJson(it.value, AudioAssetData::class.java).path }.toSet()
        root.walkTopDown().onEnter { it != staging }.filter { it.isFile && it.path !in referenced &&
            it.lastModified() < runtime.nowMillis() - 24 * 60 * 60 * 1000 }.forEach {
            if (it.delete()) deleted.add(it.name)
        }
        deleted
    }
}
