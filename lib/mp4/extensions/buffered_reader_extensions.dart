import 'dart:convert';

import 'package:tag_reader/mp4/atoms/atom.dart';
import 'package:tag_reader/mp4/atoms/unhandled.dart';
import 'package:tag_reader/mp4/enums/atoms.dart';
import 'package:tag_reader/shared_extensions.dart';
import 'package:tag_reader/util/buffered_reader.dart';

const atomHeaderSize = 8;
const _atomHeaderExtendedSize = 16;
typedef _AtomHeader = ({int size, String type});

extension AtomExtensions on BufferedReader {
  /// Returns the size and type of the atom or null if end of the file is reached.
  Future<_AtomHeader?> _readAtomHeader() async {
    final bytes = await read(atomHeaderSize);
    if (bytes.isEmpty) return null;

    final size = bytes.getUint32();
    final type = latin1.decode(bytes.getRange(4, bytes.length).toList());

    return (size: size, type: type);
  }

  /// Returns the atom, null if end of file.
  Future<Atom?> readNextAtom() async {
    final startPos = await position();

    final header = await _readAtomHeader();
    if (header == null) return null;

    int size = header.size;
    int headerSize;
    // Indicates that the atom extends to the end of the file.
    if (size == 0) {
      headerSize = atomHeaderSize;
      size = await length() - startPos - atomHeaderSize;
    }
    // Indicates the header size is stored in a 64 bit extended size field.
    else if (size == 1) {
      headerSize = _atomHeaderExtendedSize;
      size = (await readUint64()) - _atomHeaderExtendedSize;
    } else {
      headerSize = atomHeaderSize;
      size -= atomHeaderSize;
    }

    if (header.type == Atoms.covr.name) {
      if (imageMode == .none) {
        await setPosition(startPos + headerSize + size);
        return Unhandled(size, 'Covr, skipped as none set.');
      } else if (imageMode == .first) {
        imageMode = .none;
      }
    }

    Atom atom;
    try {
      atom = await Atom.parseFrom(
        identifier: header.type,
        size: size,
        reader: this,
      );
    } catch (e) {
      await setPosition(startPos + headerSize + size);
      rethrow;
    }

    return atom;
  }
}
