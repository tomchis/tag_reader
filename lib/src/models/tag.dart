import 'package:tag_reader/src/models/chapter.dart';
import 'package:tag_reader/src/models/cover_art.dart';

class Tag {
  const Tag({
    this.title,
    this.artist,
    this.albumArtist,
    this.album,
    this.composer,
    this.genre,
    this.description,
    this.trackNumber,
    this.date,
    this.duration,
    this.coverArt,
    this.chapters,
  });

  final String? title;
  final String? artist;
  final String? albumArtist;
  final String? album;
  final String? composer;
  final String? genre;
  final String? description;

  /// May be in format trackNum/totalTracks
  final String? trackNumber;
  final String? date;
  final Duration? duration;

  /// If singleImage is set (default) will contain a single image prioritizing
  /// the front cover.
  final List<CoverArt>? coverArt;
  final List<Chapter>? chapters;
}
