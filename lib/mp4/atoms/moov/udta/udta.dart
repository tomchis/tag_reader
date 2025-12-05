import 'package:tag_reader/mp4/atoms/atom.dart';
import 'package:tag_reader/mp4/atoms/moov/udta/chpl.dart';
import 'package:tag_reader/mp4/atoms/moov/udta/meta/meta.dart';
import 'package:tag_reader/mp4/extensions/atom_list_extensions.dart';

/// User data atom
/// An atom where data associated with an object is defined and stored.
/// Children atoms contain the majority of the metadata we need.
class Udta extends AtomWithChildren {
  Udta(super.size);

  Meta? get meta => children.firstWhereType<Meta>();

  /// Chpl may be here or in the Meta atom. This will check both.
  Chpl? get chpl => children.firstWhereType<Chpl>() ?? meta?.chpl;
}
