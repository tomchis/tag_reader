# Tag Reader

A tag reader for mp3 (id3) and mp4/m4a/m4b.

Tag Fields:

* Title
* Artist
* Album Artist
* Album
* Genre
* Description
* Track Number
* Date
* Duration
* Cover Art
* Chapters (mp3 - Chap/Overdrive. mp4 - iTunes/Nero)

<a href='https://ko-fi.com/I3I71BCGSU' target='_blank'><img height='36' style='border:0px;height:36px;' src='https://storage.ko-fi.com/cdn/kofi6.png?v=6' border='0' alt='Buy Me a Coffee at ko-fi.com' /></a>

## Getting started

```dart
import 'package:tag_reader/tag_reader.dart';
```

## Usage

```dart
final tag = tryReadTagsFrom('/path/to/file.mp3');
```
