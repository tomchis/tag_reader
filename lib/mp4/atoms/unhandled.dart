import 'package:tag_reader/mp4/atoms/atom.dart';

class Unhandled extends Atom {
  Unhandled(super.size, this.identifier);

  final String identifier;
}
