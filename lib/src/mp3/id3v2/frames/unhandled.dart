import 'package:tag_reader/src/mp3/id3v2/frames/frame.dart';
import 'package:tag_reader/src/util/byte_reader.dart';

class Unhandled extends Frame {
  Unhandled(this.identifier, super.size);

  final String identifier;

  @override
  // ignore: must_call_super
  Unhandled parse(ByteReader reader) => throw UnimplementedError();
}
