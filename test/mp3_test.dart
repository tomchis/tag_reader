import 'package:path/path.dart';
import 'package:tag_reader/tag_reader.dart';
import 'package:test/test.dart';

import 'util.dart';

final _parent = join(mediaPath, 'mp3');

void main() {
  testNoTag();
  testV1Tag();
  testVbrDuration();
  testChapters();
  testSkipImages();
}

void testNoTag() {
  test('No tag', () async {
    final path = join(_parent, 'no-tag.mp3');
    final tags = await TagReader.tryReadTagsFrom(path);

    expect(tags?.title, null);
    expect(tags?.duration?.inSeconds, 6);
  });
}

void testV1Tag() {
  test('v1 tag', () async {
    final path = join(_parent, 'v1tag.mp3');
    final tags = await TagReader.readTagsFrom(path);

    expect(tags?.title, 'The Title');
    expect(tags?.artist, 'The Artist');
    expect(tags?.album, 'The Album');
    expect(tags?.description, 'An Album');
    expect(tags?.date, '1999');
    expect(tags?.trackNumber, '4');
    expect(tags?.genre, 'Rock');
    expect(tags?.chapters, null);
  });
}

void testVbrDuration() {
  test('VBR duration', () async {
    final path = join(_parent, 'vbr.mp3');
    final tags = await TagReader.readTagsFrom(path);

    expect(tags?.title, 'Title');
    expect(tags?.artist, 'Artist');
    expect(tags?.album, 'Album Title');
    expect(tags?.description, null);
    expect(tags?.date, '1888');
    expect(tags?.trackNumber, '10/10');
    expect(tags?.composer, 'Bob Dole');
    expect(tags?.genre, 'Audio');
    expect(tags?.chapters, null);
    expect(tags?.duration?.inSeconds, 5);
  });
}

void testChapters() {
  test('Chapters', () async {
    final path = join(_parent, 'chaptered.mp3');
    final tags = await TagReader.readTagsFrom(path);

    expect(tags?.title, 'Book 1');
    expect(tags?.artist, 'Author');
    expect(tags?.albumArtist, 'A Book');
    expect(tags?.album, 'Book');
    expect(tags?.description, 'An Audiobook');
    expect(tags?.date, '2024-01-01');
    expect(tags?.trackNumber, '01');
    expect(tags?.genre, 'Sci-Fi');
    expect(tags?.duration?.inSeconds, 4);
    expect(tags?.coverArt?.first.bytes.isNotEmpty, true);
    expect(tags?.chapters?.length, 3);
    expect(tags?.chapters?[0].title, 'Chapter 1');
    expect(tags?.chapters?[1].title, 'Chapter 2');
    expect(tags?.chapters?[2].title, 'Chapter 3');
  });

  test('OverDrive MediaMarkers', () async {
    final path =
        '/media/Stuff/Projects/Flutter/audius/plugins/tag_reader/test/media/mp3/chaptered-media-markers.mp3';
    final tags = await TagReader.readTagsFrom(path);

    expect(tags?.title, 'Book 1');
    expect(tags?.artist, 'Author');
    expect(tags?.album, 'Book');
    expect(tags?.chapters?.length, 2);
    expect(tags?.chapters?[0].title, 'Chapter 1');
    expect(tags?.chapters?[1].title, 'Chapter 2');
  });
}

void testSkipImages() {
  test('Skip images', () async {
    final path = join(_parent, 'chaptered.mp3');
    final tags = await TagReader.readTagsFrom(path, imageMode: .none);

    expect(tags?.title, 'Book 1');
    expect(tags?.coverArt, isNull);
  });
}
