import 'dart:convert';

import 'package:charset/charset.dart';
import 'package:logging/logging.dart';
import 'package:tag_reader/mp4/atoms/atom.dart';

import 'package:tag_reader/mp4/atoms/moov/trak/mdia/minf/stbl/stco.dart';
import 'package:tag_reader/mp4/atoms/moov/trak/mdia/minf/stbl/stsz.dart';
import 'package:tag_reader/mp4/atoms/moov/trak/mdia/minf/stbl/stts.dart';
import 'package:tag_reader/mp4/extensions/atom_list_extensions.dart';
import 'package:tag_reader/shared_extensions.dart';
import 'package:tag_reader/util/buffered_reader.dart';

/// Sample table atom:
/// Contains information for converting from media time to
/// sample number to sample location.
class Stbl extends AtomWithChildren {
  Stbl(super.size);

  Stco? get stco => children.firstWhereType<Stco>();
  Stts? get stts => children.firstWhereType<Stts>();
  Stsz? get stsz => children.firstWhereType<Stsz>();

  Future<List<String>> getChapterTitles({
    required List<int> offsets,
    required List<int> sizes,
    required BufferedReader reader,
  }) async {
    final List<String> titles = [];

    if (offsets.length == sizes.length) {
      // Don't assume samples are consecutive.
      for (final (index, size) in sizes.indexed) {
        final start = offsets[index];
        final end = start + size;
        await reader.setPosition(start);
        final chunk = await reader.read(end - start);
        final stringLength = chunk.getUint16();
        final stringBytes = chunk.getRange(2, 2 + stringLength);
        String string;
        try {
          // Check for bom at start of bytes.
          if (stringBytes.take(2) == [0xfe, 0xff]) {
            string = utf16
                .decode(stringBytes.toList())
                .trimIncludingNullBytes();
          } else {
            string = utf8.decode(stringBytes.toList());
          }
        } catch (e) {
          Logger('Stbl').warning(
            'Failed to decode title for chapter at index $index (${reader.path})',
          );
          string = 'Chapter ${index + 1}';
        }
        titles.add(string);
      }
    } else {
      // Assume samples are consecutive, since we only have the first
      // index to work with.
      int? offset = offsets.firstOrNull;
      if (offset != null) {
        await reader.setPosition(offset);
        for (final size in sizes) {
          final next = offset! + size;
          final chunk = await reader.read(next - offset);
          final stringLength = chunk.getUint16();
          final stringBytes = chunk.getRange(2, 2 + stringLength);
          final string = utf8.decode(stringBytes.toList());
          titles.add(string);
          offset = next;
        }
      }
    }

    return titles;
  }
}
