import 'dart:io';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:tag_reader/mp3/id3v2/enums/frames.dart';
import 'package:tag_reader/mp3/id3v2/frames/apic.dart';
import 'package:tag_reader/mp3/id3v2/frames/chap.dart';
import 'package:tag_reader/mp3/id3v2/frames/comment_frame.dart';
import 'package:tag_reader/mp3/id3v2/frames/text_frame.dart';
import 'package:tag_reader/mp3/id3v2/frames/unhandled.dart';
import 'package:tag_reader/mp3/id3v2/frames/user_text_frame.dart';
import 'package:tag_reader/util/buffered_reader.dart';
import 'package:tag_reader/util/byte_reader.dart';

abstract class Frame {
  Frame(this.size);

  final int size;

  late final log = Logger(runtimeType.toString());

  /// super.parse should be called to clean up after parsing is complete.
  @mustCallSuper
  Frame parse(ByteReader reader);

  static Future<Frame> parseFrom({
    required String identifier,
    required int size,
    required BufferedReader reader,
    bool compressed = false,
  }) async {
    // 5mb limit
    if (size > 5_000_000) {
      Logger('Frame').warning('Frame size to big ($size). Skipping.');
      return Unhandled(identifier, size);
    }

    final frame = Frames.values.firstWhereOrNull(
      (element) => element.identifier.contains(identifier),
    );

    if (frame == null) {
      await reader.skip(size);
      return Unhandled(identifier, size);
    }

    final byteReader = ByteReader(
      compressed
          ? Uint8List.fromList(zlib.decode(await reader.read(size)))
          : await reader.read(size),
    );

    return switch (frame) {
      .coverArt => Apic(
        size,
        majorVersionLessThanThree: identifier.length == 3,
      ).parse(byteReader),
      .comment => CommentFrame(size).parse(byteReader),
      .chapters => Chap(size).parse(byteReader),
      .userDefinedText => UserTextFrame(size).parse(byteReader),
      .title ||
      .artist ||
      .albumArtist ||
      .album ||
      .composer ||
      .genres ||
      .description ||
      .trackNumber ||
      .year ||
      .dayMonth ||
      .dateRecording ||
      .dateRelease => TextFrame(identifier, size).parse(byteReader),
    };
  }
}
