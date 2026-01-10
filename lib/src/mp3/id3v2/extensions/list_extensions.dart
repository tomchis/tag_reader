import 'package:collection/collection.dart';
import 'package:intl/intl.dart';
import 'package:intl/intl_standalone.dart';
import 'package:logging/logging.dart';
import 'package:tag_reader/src/enums/image_mode.dart';
import 'package:tag_reader/src/models/chapter.dart';
import 'package:tag_reader/src/models/cover_art.dart';
import 'package:tag_reader/src/mp3/id3v2/enums/frames.dart';
import 'package:tag_reader/src/mp3/id3v2/frames/apic.dart';
import 'package:tag_reader/src/mp3/id3v2/frames/chap.dart';
import 'package:tag_reader/src/mp3/id3v2/frames/comment_frame.dart';
import 'package:tag_reader/src/mp3/id3v2/frames/frame.dart';
import 'package:tag_reader/src/mp3/id3v2/frames/text_frame.dart';
import 'package:tag_reader/src/mp3/id3v2/frames/user_text_frame.dart';
import 'package:tag_reader/src/shared_extensions.dart';
import 'package:xml/xml.dart';

extension FrameListExtensions on List<Frame> {
  List<CoverArt>? coverArtFromFrames(ImageMode imageMode) {
    final covers = switch (imageMode) {
      .first =>
        whereType<Apic>()
            .take(1)
            .map((e) => CoverArt.fromApicFrame(e))
            .toList(),
      .all => whereType<Apic>().map((e) => CoverArt.fromApicFrame(e)).toList(),
      .none => null,
    };
    return covers != null && covers.isNotEmpty ? covers : null;
  }

  List<Chapter>? chaptersFromChapterFrames() {
    final chaps = whereType<Chap>();
    if (chaps.isNotEmpty) {
      return chaps
          .map(
            (c) => Chapter(
              title: c.title ?? c.id,
              description: c.description,
              start: c.startMillis,
              end: c.endMillis,
            ),
          )
          .toList();
    }

    final mediaMarkers = where(
      (element) =>
          element is UserTextFrame &&
          element.description == 'OverDrive MediaMarkers',
    ).cast<UserTextFrame>();
    if (mediaMarkers.isNotEmpty) {
      final List<Chapter> chapters = [];
      for (final markers in mediaMarkers) {
        if (markers.text != null) {
          try {
            final xml = XmlDocument.parse(markers.text!);
            final titles = xml
                .findAllElements('Name')
                .map((e) => e.innerText.trim());
            final times = xml
                .findAllElements('Time')
                .map((e) => e.innerText.trim());
            if (titles.length != times.length) return null;

            for (int i = 0; i < titles.length; i++) {
              final start = times.elementAt(i).toMillis();
              if (start == null) return null;

              chapters.add(
                Chapter(title: titles.elementAt(i), start: start, end: -1),
              );
            }
          } catch (e) {
            Logger(
              'FrameListExtensions',
            ).warning('Failed to parse media marker xml. $e.');
          }
        }
      }
      return chapters;
    }

    return null;
  }

  Future<String?> descriptionFromFrames() async {
    var description = textFrameValueWithIdentifier(.description);
    description ??= await commentFrameText();
    return description?.trim();
  }

  String? dateFromFrames() {
    final dateRelease = textFrameValueWithIdentifier(.dateRelease);
    if (dateRelease != null) return dateRelease;

    final dateRecording = textFrameValueWithIdentifier(.dateRecording);
    if (dateRecording != null) return dateRecording;

    final year = textFrameValueWithIdentifier(.year);
    final dayMonth = textFrameValueWithIdentifier(.dayMonth);

    return '$year${dayMonth != null ? '-$dayMonth' : ''}';
  }

  String? textFrameValueWithIdentifier(Frames indentifier) {
    final frame =
        firstWhereOrNull(
              (element) =>
                  element is TextFrame &&
                  indentifier.identifier.contains(element.identifier),
            )
            as TextFrame?;
    return frame?.text;
  }

  Future<String?> commentFrameText() async {
    final commentFrames = where(
      (element) => element is CommentFrame,
    ).cast<CommentFrame>();
    if (commentFrames.isEmpty) return null;

    // Try to match with system locale.
    final systemLocale = await findSystemLocale();
    final systemLocaleShort = Intl.shortLocale(systemLocale);

    CommentFrame? systemLangFrame;
    CommentFrame? engFrame;
    CommentFrame? otherFrame;

    for (final c in commentFrames) {
      if (c.text == null ||
          (c.shortText != null &&
              !c.shortText!.contains(RegExp('desc', caseSensitive: false)))) {
        continue;
      }

      if (c.language.startsWith(systemLocaleShort)) {
        systemLangFrame = c;
        break;
      } else if (c.language.startsWith('en')) {
        engFrame ??= c;
      } else {
        otherFrame ??= c;
      }
    }

    return systemLangFrame?.text ?? engFrame?.text ?? otherFrame?.text;
  }
}
