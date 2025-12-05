import 'package:tag_reader/enums/image_mode.dart';
import 'package:tag_reader/mp4/atoms/atom.dart';
import 'package:tag_reader/mp4/atoms/moov/udta/meta/ilst/covr.dart';
import 'package:tag_reader/mp4/enums/atoms.dart';
import 'package:tag_reader/mp4/extensions/atom_list_extensions.dart';

final _descriptionStripRegex = RegExp(r'\\\\[rnt]|\\.');

/// Metadata item list atom:
/// Holds a list of actual metadata values that are present
/// in the metadata atom.
/// Children may contain metadata such as title, artist,
/// album, genre, cover art etc..
class Ilst extends AtomWithChildren {
  Ilst(super.size);

  String? firstStringWith({required String identifier}) =>
      children.firstGenericStringWith(identifier: identifier)?.value;

  String? preferedStringContaining({required List<String> identifiers}) =>
      children.preferedGenericStringContaining(identifiers: identifiers)?.value;

  String? firstPartAndTotalWith({required String identifier}) =>
      children.firstPartAndTotalWith(identifier: identifier)?.stringValue();

  String? genreFromAtoms() =>
      children
          .firstGenericStringContaining(
            identifiers: [
              Atoms.genr.identifier,
              Atoms.gnre.identifier,
              Atoms.gen.identifier,
            ],
          )
          ?.value ??
      children
          .firstGenericIntegerWith(identifier: Atoms.geId.identifier)
          ?.valueToItunesGenre();

  String? descriptionFromAtoms() {
    var description = children
        .firstGenericStringContaining(
          identifiers: [Atoms.desc.identifier, Atoms.des.identifier],
        )
        ?.value;
    if (description != null) {
      description =
          // Strip leading backslashes and covert new lines/tabs/returns in description.
          description.replaceAllMapped(
            _descriptionStripRegex,
            (m) => switch (m.group(0)!) {
              r'\\n' => '\n',
              r'\\r' => '\r',
              r'\\t' => '\t',
              r'\n' => '\n',
              r'\r' => '\r',
              r'\t' => '\t',
              _ => m.group(0)![1],
            },
          );
    }
    return description;
  }

  List<Covr>? covrAtoms(ImageMode imageMode) {
    if (imageMode == .none) return null;

    final atoms = children.whereType<Covr>();
    if (atoms.isEmpty) return null;

    if (imageMode == .first) return [atoms.first];

    return atoms.toList();
  }
}
