# These names form the durable version-1 JSON schema, across releases and R8 runs.
-keep class com.aw.huda.prayer.**Data { *; }
-keep class com.aw.huda.prayer.PlanRequest { *; }
-keep class com.aw.huda.prayer.PlanReceipt { *; }
# WorkManager persists this class name across process death and app updates.
-keep class com.aw.huda.prayer.PrayerCoverageRenewalWorker { public <init>(android.content.Context, androidx.work.WorkerParameters); }
