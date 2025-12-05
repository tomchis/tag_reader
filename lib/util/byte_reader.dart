import 'dart:convert';
import 'dart:typed_data';

import 'package:charset/charset.dart';
import 'package:tag_reader/mp3/id3v2/enums/text_encoding.dart';
import 'package:tag_reader/shared_extensions.dart';

class ByteReader {
  ByteReader(Uint8List bytes) : _bytes = bytes;
  ByteReader.empty() : this(Uint8List(0));

  Uint8List _bytes;
  int _offset = 0;

  void setBytes(Uint8List bytes) {
    _bytes = bytes;
    _offset = 0;
  }

  // Clears the stored bytes.
  void clear() => setBytes(Uint8List(0));

  int get offset => _offset;

  int get bytesRemaining {
    if (_offset >= _bytes.length) return 0;

    return _bytes.length - _offset;
  }

  List<int> readToEnd() => read(_bytes.length - _offset);

  Uint8List read(int length) {
    assert(length > 0);
    if (bytesRemaining == 0) return Uint8List(0);

    if (bytesRemaining < length) {
      final bytes = _bytes.sublist(_offset);
      _offset += bytesRemaining;
      return bytes;
    }

    final bytes = _bytes.sublist(_offset, _offset + length);
    _offset += length;
    return bytes;
  }

  int readByte() {
    final byte = _bytes[_offset];
    _offset += 1;
    return byte;
  }

  int readInt(int size) {
    assert(size > 0);
    final int = _bytes.getInt(size, offset: _offset);
    _offset += size;
    return int;
  }

  int readInt8() {
    final int = _bytes.getInt8(_offset);
    _offset += 1;
    return int;
  }

  int readInt16([Endian endian = Endian.big]) {
    final int = _bytes.getInt16(_offset, endian);
    _offset += 2;
    return int;
  }

  int readInt32([Endian endian = Endian.big]) {
    final int = _bytes.getInt32(_offset, endian);
    _offset += 4;
    return int;
  }

  int readInt64([Endian endian = Endian.big]) {
    final int = _bytes.getInt64(_offset, endian);
    _offset += 8;
    return int;
  }

  int readUint(int size) {
    final int = _bytes.getUint(size, offset: _offset);
    _offset += size;
    return int;
  }

  int readUint8() {
    final int = _bytes.getUint8(_offset);
    _offset += 1;
    return int;
  }

  int readUint16([Endian endian = Endian.big]) {
    final int = _bytes.getUint16(_offset, endian);
    _offset += 2;
    return int;
  }

  int readUint32([Endian endian = Endian.big]) {
    final int = _bytes.getUint32(_offset, endian);
    _offset += 4;
    return int;
  }

  int readUint64([Endian endian = Endian.big]) {
    final int = _bytes.getUint64(_offset, endian);
    _offset += 8;
    return int;
  }

  double readFloat32([Endian endian = Endian.big]) {
    final float = _bytes.getFloat32(_offset, endian);
    _offset += 4;
    return float;
  }

  double readFloat64([Endian endian = Endian.big]) {
    final float = _bytes.getFloat64(_offset, endian);
    _offset += 8;
    return float;
  }

  int readSyncSafeInt() {
    final int = _bytes.getSyncsafeInt(_offset);
    _offset += 4;
    return int;
  }

  String? readToEndString(TextEncoding encoding) {
    final bytes = readToEnd();
    if (bytes.isEmpty) return null;

    return switch (encoding) {
      .latin => latin1.decode(bytes).trim(),
      .utf8 => utf8.decode(bytes).trim(),
      .utf16 || .utf16be => utf16.decode(bytes).trimIncludingNullBytes(),
    };
  }

  String? readNullTerminatedString(TextEncoding encoding, {int? lengthLimit}) {
    int nullCharIndex = _bytes.indexOfNullChar(_offset, encoding);
    if (nullCharIndex == -1) return null;

    if (nullCharIndex == _offset) {
      _offset++;
      return null;
    }

    if (lengthLimit != null && nullCharIndex > _offset + lengthLimit) {
      nullCharIndex = _offset + lengthLimit;
    }

    final String string;
    switch (encoding) {
      case .latin:
        final bytes = _bytes.getRange(_offset, nullCharIndex);
        string = latin1.decode(bytes.toList()).trim();
      case .utf8:
        final bytes = _bytes.getRange(_offset, nullCharIndex);
        string = utf8.decode(bytes.toList()).trim();
      case .utf16 || .utf16be:
        final bytes = _bytes.getRange(
          _offset,
          nullCharIndex + (nullCharIndex >= _bytes.length ? 0 : 1),
        );
        string = utf16.decode(bytes.toList()).trimIncludingNullBytes();
    }

    _offset = nullCharIndex + 1;

    return string;
  }

  String? readNullTerminatedStringIn(
    int length, {
    required TextEncoding encoding,
  }) {
    assert(length > 0);
    final startOffset = _offset;
    final string = readNullTerminatedString(encoding, lengthLimit: length);
    final diff = _offset - startOffset;
    skip(length - diff);
    return string;
  }

  /// Skips forward or back by `length`.
  ///
  /// Throws a RangeError if length will put the offset
  /// less than 0 or greater/equal to the buffers length.
  void skip(int length) {
    final newOffset = _offset + length;
    if (newOffset < 0 || newOffset >= _bytes.length) {
      throw RangeError(
        'Offset $newOffset outside of buffer range 0-${_bytes.length}.',
      );
    }
    _offset = newOffset;
  }

  void skipNullBytes() {
    while (_bytes.elementAt(_offset) == 0) {
      if (bytesRemaining > 1) {
        _offset += 1;
      } else {
        break;
      }
    }
  }

  void skipNullTerminatedString(TextEncoding encoding) {
    final nullCharIndex = _bytes.indexOfNullChar(_offset, encoding);
    if (nullCharIndex != -1) {
      _offset = nullCharIndex + 1;
    }
  }
}

extension on Uint8List {
  int indexOfNullChar(int offset, TextEncoding? encoding) {
    final list = (offset > 0 ? sublist(offset) : this);
    for (int i = 0; i < list.length; i++) {
      if (encoding == .utf16 || encoding == .utf16be) {
        if (i + 1 >= list.length) {
          // return the original lists length
          return length;
        }

        if ((i + 1).isOdd &&
            list.elementAt(i) == 0 &&
            list.elementAt(i + 1) == 0) {
          return i + 1 + offset;
        }
      } else {
        if (list.elementAt(i) == 0) {
          return i + offset;
        }
      }
    }
    return length;
  }
}
