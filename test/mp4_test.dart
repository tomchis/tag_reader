import 'package:path/path.dart';
import 'package:tag_reader/tag_reader.dart';
import 'package:test/test.dart';

import 'util.dart';

final _parent = join(mediaPath, 'mp4');

void main() {
  testNoTag();
  testItunesChapters();
  testNeroChapters();
  testSkipImages();
}

void testNoTag() {
  test('No tag', () async {
    final path = join(_parent, 'no-tag.m4a');
    final tags = await TagReader.tryReadTagsFrom(path);

    expect(tags?.title, isNull);
    expect(tags?.duration?.inSeconds, 7);
  });
}

void testItunesChapters() {
  test('iTunes chapters', () async {
    final path = join(_parent, 'chap.m4b');
    final tags = await TagReader.readTagsFrom(path);

    expect(tags?.title, 'AdventuresSherlockHolmes_librivox');
    expect(tags?.artist, 'Sir Arthur Conan Doyle');
    expect(tags?.album, 'The Adventures of Sherlock Holmes (version 5)');
    expect(tags?.trackNumber, '1');
    expect(tags?.duration?.inSeconds, 100);
    expect(tags?.chapters?.length, 14);
    expect(tags?.chapters?.first.title, '01 - A Scandal In Bohemia Part 1');
    expect(
      tags?.chapters?.elementAt(1).title,
      '02 - A Scandal In Bohemia Part 2',
    );
    expect(tags?.chapters?.elementAt(1).start, 1272007);
  });
}

void testNeroChapters() {
  test('Nero chapters', () async {
    final path = join(_parent, 'chpl.m4b');
    final tags = await TagReader.readTagsFrom(path);

    expect(tags?.title, 'Chpl');
    expect(tags?.artist, 'An Artist');
    expect(tags?.duration?.inSeconds, 7);
    expect(tags?.chapters?.length, 2);
    expect(tags?.chapters?.first.title, 'Chapter 1');
    expect(tags?.chapters?.first.start, 0);
    expect(tags?.coverArt?.length, 1);
    expect(tags?.coverArt?.first.bytes.isEmpty, false);
  });
}

void testSkipImages() {
  test('Skip images', () async {
    final path = join(_parent, 'chpl.m4b');
    final tags = await TagReader.readTagsFrom(path, imageMode: .none);

    expect(tags?.title, 'Chpl');
    expect(tags?.coverArt, null);
  });
}
