library tag_reader;

import 'dart:developer';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:tag_reader/src/enums/image_mode.dart';
import 'package:tag_reader/src/exceptions/file_type_unsupported.dart';
import 'package:tag_reader/src/models/tag.dart';
import 'package:tag_reader/src/mp3/mp3_file.dart';
import 'package:tag_reader/src/mp4/mp4_file.dart';
import 'package:tag_reader/src/util/buffered_reader.dart';

export 'package:tag_reader/src/exceptions/file_type_unsupported.dart';
export 'package:tag_reader/src/models/cover_art.dart';
export 'package:tag_reader/src/models/tag.dart';

abstract class TagReader {
  /// Images will be retrieved according to `imageMode`.
  ///
  /// Like readTagsFrom() but returns null instead of throwing an error.
  static Future<Tag?> tryReadTagsFrom(
    String path, {
    ImageMode imageMode = .first,
    int bufferSize = BufferedReader.defaultBufferSize,
  }) => readTagsFrom(path, imageMode: imageMode, bufferSize: bufferSize)
      .catchError((e) {
        Logger('TagReader').warning(e);
        return null;
      });

  /// Images will be retrieved according to `imageMode`.
  ///
  /// Throws:
  /// IOError if the path cannot be read.
  /// FileTypeUnsupported if the file at path is unsupported.
  static Future<Tag?> readTagsFrom(
    String path, {
    ImageMode imageMode = .first,
    int bufferSize = BufferedReader.defaultBufferSize,
  }) async {
    Logger.root.onRecord.listen(
      (event) =>
          log(event.message, name: event.loggerName, level: event.level.value),
    );

    final ext = p.extension(path).toLowerCase();

    if (Mp3File.extensions.contains(ext)) {
      return Mp3File(
        path,
        imageMode: imageMode,
        bufferSize: bufferSize,
      ).parseTags();
    } else if (Mp4File.extensions.contains(ext)) {
      return Mp4File(
        path,
        imageMode: imageMode,
        bufferSize: bufferSize,
      ).parseTags();
    }

    throw FileTypeUnsupported('Unsupported file type "$ext".');
  }
}
