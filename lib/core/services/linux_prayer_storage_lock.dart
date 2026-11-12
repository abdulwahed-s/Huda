import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

/// Linux ownership belongs to the open file description. Keep the lock file
/// permanently: unlinking it could give a waiting process a different inode.
final class LinuxPrayerStorageLock {
  LinuxPrayerStorageLock._(this._descriptor);

  static final _library = DynamicLibrary.open('libc.so.6');
  static final _allocate = _library
      .lookupFunction<
        Pointer<Void> Function(IntPtr),
        Pointer<Void> Function(int)
      >('malloc');
  static final _free = _library
      .lookupFunction<
        Void Function(Pointer<Void>),
        void Function(Pointer<Void>)
      >('free');
  static final _open = _library
      .lookupFunction<
        Int32 Function(Pointer<Uint8>, Int32, Uint32),
        int Function(Pointer<Uint8>, int, int)
      >('open');
  static final _flock = _library
      .lookupFunction<Int32 Function(Int32, Int32), int Function(int, int)>(
        'flock',
      );
  static final _close = _library
      .lookupFunction<Int32 Function(Int32), int Function(int)>('close');
  static final _errno = _library
      .lookupFunction<Pointer<Int32> Function(), Pointer<Int32> Function()>(
        '__errno_location',
      );
  final int _descriptor;

  static LinuxPrayerStorageLock open(String path) {
    final bytes = utf8.encode(path);
    final memory = _allocate(bytes.length + 1);
    if (memory.address == 0) {
      throw FileSystemException('Lock allocation failed', path);
    }
    try {
      final pointer = memory.cast<Uint8>();
      pointer.asTypedList(bytes.length + 1)
        ..setRange(0, bytes.length, bytes)
        ..[bytes.length] = 0;
      // O_RDWR | O_CREAT | O_CLOEXEC, owner read/write only.
      final descriptor = _open(pointer, 0x80042, 0x180);
      if (descriptor < 0) {
        throw FileSystemException(
          'Cannot open prayer lock',
          path,
          OSError('', _errno().value),
        );
      }
      return LinuxPrayerStorageLock._(descriptor);
    } finally {
      _free(memory);
    }
  }

  bool tryClaim() {
    if (_flock(_descriptor, 6) == 0) return true; // LOCK_EX | LOCK_NB
    final error = _errno().value;
    if (error == 11 || error == 4) return false; // EWOULDBLOCK / EINTR
    throw FileSystemException(
      'Cannot claim prayer ownership',
      '',
      OSError('', error),
    );
  }

  void close() =>
      _close(_descriptor); // Kernel release also covers process death.
}
