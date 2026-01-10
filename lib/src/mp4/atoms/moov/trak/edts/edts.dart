import 'package:tag_reader/src/mp4/atoms/atom.dart';
import 'package:tag_reader/src/mp4/atoms/moov/trak/edts/elst.dart';
import 'package:tag_reader/src/mp4/extensions/atom_list_extensions.dart';

/// Edit atom:
/// Defines the portions of the media that are to be used to build
/// up a track for a movie.
/// If the edit atom or the edit list atom is missing, you can assume
/// that the entire media is used by the track.
class Edts extends AtomWithChildren {
  Edts(super.size);

  Elst? get elst => children.firstWhereType<Elst>();
}
