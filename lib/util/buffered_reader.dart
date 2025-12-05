import 'dart:io';
import 'dart:typed_data';

import 'package:tag_reader/enums/image_mode.dart';
import 'package:tag_reader/mp3/id3v2/enums/text_encoding.dart';
import 'package:tag_reader/shared_extensions.dart';
import 'package:tag_reader/util/byte_reader.dart';

class BufferedReader {
  BufferedReader._(this._file, {required int bufferSize, this.imageMode})
    : _bufferSize = bufferSize;

  // 8kb
  static const defaultBufferSize = 8192;
  final RandomAccessFile _file;
  final int _bufferSize;

  /// Determines whether a apic or cover should be parsed.
  ImageMode? imageMode;

  final _buffer = ByteReader.empty();

  /// Throws FileSystemException if the opening the path fails.
  static Future<BufferedReader> open(
    String path, {
    int bufferSize = defaultBufferSize,
    ImageMode? imageMode,
  }) async {
    final file = await File(path).open();
    final reader = BufferedReader._(
      file,
      bufferSize: bufferSize,
      imageMode: imageMode,
    );
    return reader;
  }

  /// Continues reading from the current position in the file unless
  /// `startAtBeginning` is true.
  static Future<BufferedReader> fromOpenedFile(
    RandomAccessFile file, {
    int bufferSize = defaultBufferSize,
    bool startAtBeginning = false,
    ImageMode? imageMode,
  }) async {
    if (startAtBeginning) await file.setPosition(0);
    return BufferedReader._(file, bufferSize: bufferSize, imageMode: imageMode);
  }

  Future<void> dispose() => _file.close();

  String get path => _file.path;

  Future<int> position() async =>
      (await _file.position()) - _buffer.bytesRemaining;

  Future<void> setPosition(int position) async {
    assert(position >= 0);
    final currentPostion = await this.position();
    if (position == currentPostion) return;

    try {
      _buffer.skip(position - currentPostion);
    } on RangeError {
      await _file.setPosition(position);
      _buffer.clear();
    }
  }

  Future<int> length() => _file.length();

  Future<void> _fillBufferIfNeeded(int bytesToRead) async {
    final bytesRemainingInBuffer = _buffer.bytesRemaining;
    if (bytesRemainingInBuffer < bytesToRead) {
      if (bytesToRead <= _bufferSize) {
        bytesToRead = _bufferSize - bytesRemainingInBuffer;
      }

      var bytes = await _file.read(bytesToRead);
      if (bytesRemainingInBuffer > 0) {
        bytes = Uint8List.fromList([..._buffer.readToEnd(), ...bytes]);
      }
      _buffer.setBytes(bytes);
    }
  }

  /// The number of bytes remaining in the file.
  Future<int> bytesInFileRemaining() async =>
      (await _file.length() - await _file.position()) + _buffer.bytesRemaining;

  Future<Uint8List> read(int length) async {
    await _fillBufferIfNeeded(length);
    return _buffer.read(length);
  }

  Future<void> skip(int length) async {
    if (length == 0) return;

    try {
      _buffer.skip(length);
    } on RangeError {
      final amount = switch (length) {
        > 0 => length - _buffer.bytesRemaining,
        _ => _buffer.offset - length,
      };
      await _file.skip(amount);
      _buffer.clear();
    }
  }

  Future<int> readByte() async {
    await _fillBufferIfNeeded(1);
    return _buffer.readByte();
  }

  Future<double> readFloat32([Endian endian = Endian.big]) async {
    await _fillBufferIfNeeded(4);
    return _buffer.readFloat32(endian);
  }

  Future<double> readFloat64([Endian endian = Endian.big]) async {
    await _fillBufferIfNeeded(8);
    return _buffer.readFloat64(endian);
  }

  Future<int> readInt(int size) async {
    await _fillBufferIfNeeded(size);
    return _buffer.readInt(size);
  }

  Future<int> readInt16([Endian endian = Endian.big]) async {
    await _fillBufferIfNeeded(2);
    return _buffer.readInt16(endian);
  }

  Future<int> readInt32([Endian endian = Endian.big]) async {
    await _fillBufferIfNeeded(4);
    return _buffer.readInt32(endian);
  }

  Future<int> readInt64([Endian endian = Endian.big]) async {
    await _fillBufferIfNeeded(8);
    return _buffer.readInt64(endian);
  }

  Future<int> readInt8() async {
    await _fillBufferIfNeeded(1);
    return _buffer.readInt8();
  }

  Future<int> readSyncSafeInt() async {
    await _fillBufferIfNeeded(4);
    return _buffer.readSyncSafeInt();
  }

  Future<int> readUint(int size) async {
    await _fillBufferIfNeeded(size);
    return _buffer.readUint(size);
  }

  Future<int> readUint16([Endian endian = Endian.big]) async {
    await _fillBufferIfNeeded(2);
    return _buffer.readUint16(endian);
  }

  Future<int> readUint32([Endian endian = Endian.big]) async {
    await _fillBufferIfNeeded(4);
    return _buffer.readUint32(endian);
  }

  Future<int> readUint64([Endian endian = Endian.big]) async {
    await _fillBufferIfNeeded(8);
    return _buffer.readUint64(endian);
  }

  Future<int> readUint8() async {
    await _fillBufferIfNeeded(1);
    return _buffer.readUint8();
  }

  Future<String?> readNullTerminatedStringIn(
    int length, {
    required TextEncoding encoding,
  }) async {
    await _fillBufferIfNeeded(length);
    return _buffer.readNullTerminatedStringIn(length, encoding: encoding);
  }
}
