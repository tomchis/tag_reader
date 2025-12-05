import 'package:collection/collection.dart';
import 'package:tag_reader/mp4/atoms/atom.dart';
import 'package:tag_reader/mp4/atoms/moov/trak/trak.dart';
import 'package:tag_reader/mp4/atoms/moov/udta/udta.dart';
import 'package:tag_reader/mp4/enums/atoms.dart';
import 'package:tag_reader/mp4/extensions/atom_list_extensions.dart';

/// Movie atom:
/// Specifies the information that defines a movie.
class Moov extends AtomWithChildren {
  Moov(super.size);

  Udta? get udta => children.firstWhereType<Udta>();

  Iterable<Trak> get traks => children.whereType<Trak>();

  Trak? get videoTrak => traks.firstWhereOrNull((element) {
    final hdlr = element.mdia.hdlr;
    return hdlr != null && hdlr.subtype.startsWith(TrakType.vide.name);
  });

  Trak? get soundTrak => traks.firstWhereOrNull((element) {
    final hdlr = element.mdia.hdlr;
    return hdlr != null && hdlr.subtype.startsWith(TrakType.soun.name);
  });

  Trak? get chapterTrak {
    final chapterId = soundTrak?.chap?.ids.firstOrNull;
    if (chapterId == null) return null;

    return traks.firstWhereOrNull(
      (element) => element.tkhd.trackId == chapterId,
    );
  }

  /// Return root udta otherwise guess.
  Udta? get udtaWithMetadata {
    if (udta != null) return udta;

    final udtas = <Udta>[];
    final atomsWithChildren = <AtomWithChildren>[this];
    for (int i = 0; i < atomsWithChildren.length; i++) {
      for (final atom in atomsWithChildren[i].children) {
        if (atom is AtomWithChildren) {
          if (atom is Udta) udtas.add(atom);

          atomsWithChildren.add(atom);
        }
      }
    }

    if (udtas.length == 1) return udtas.first;

    for (final u in udtas) {
      final ilst = u.meta?.ilst;
      if (ilst == null) continue;

      // Some tags are using AtomEnum.nam for chapter names so look for other attributes.
      if (ilst.firstStringWith(identifier: Atoms.alb.identifier) != null ||
          ilst.firstStringWith(identifier: Atoms.art.identifier) != null) {
        return u;
      }
    }

    return null;
  }

  Duration? get duration {
    final videoTrakMdhd = videoTrak?.mdia.mdhd;
    final soundTrakMdhd = soundTrak?.mdia.mdhd;

    final videoDuration = videoTrakMdhd != null
        ? Duration(seconds: videoTrakMdhd.duration ~/ videoTrakMdhd.timeScale)
        : Duration.zero;
    final soundDuration = soundTrakMdhd != null
        ? Duration(seconds: soundTrakMdhd.duration ~/ soundTrakMdhd.timeScale)
        : Duration.zero;

    if (videoDuration == Duration.zero && soundDuration == Duration.zero) {
      return null;
    }

    return videoDuration.compareTo(soundDuration) > 0
        ? videoDuration
        : soundDuration;
  }
}
