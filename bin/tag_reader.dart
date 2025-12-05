#! /bin/env dart

import 'dart:io';

import 'package:logging/logging.dart';
import 'package:tag_reader/tag_reader.dart';

void main(List<String> arguments) async {
  if (arguments.isEmpty || arguments.length > 3) {
    _printUsage();
    exit(1);
  }

  if (arguments.length >= 2) {
    final regex = RegExp('-l ?([iws])');
    final argument = arguments.length == 2
        ? arguments[0]
        : '${arguments[0]} ${arguments[1]}';
    final match = regex.firstMatch(argument);
    if (match == null) {
      stderr.writeln('Invalid logLevel');
      _printUsage();
      exit(3);
    }
    final level = match.group(1);
    Logger.root.level = switch (level) {
      'o' => Level.OFF,
      'i' => Level.INFO,
      'w' => Level.WARNING,
      's' || _ => Level.SEVERE,
    };
  } else {
    Logger.root.level = Level.SEVERE;
  }

  final file = File(arguments.last);
  if (!await file.exists()) {
    stderr.writeln("${file.path} doesn't exist");
    exit(2);
  }

  Logger.root.onRecord.listen((event) => stderr.writeln(event.message));

  final tag = await TagReader.tryReadTagsFrom(arguments.last);
  if (tag == null) {
    stderr.writeln('No tag or failed to read tag.');
    exit(4);
  }

  print(
    '''
Title: ${tag.title}
Artist: ${tag.artist}
Album artist: ${tag.albumArtist}
Album: ${tag.album}
Composer: ${tag.composer}
Genre: ${tag.genre}
Track num: ${tag.trackNumber}
Date: ${tag.date}
Description: ${tag.description}
Duration: ${tag.duration}
HasArt: ${tag.coverArt != null}
Chapters: ${tag.chapters != null ? "\n" : ""}${tag.chapters?.map((e) => '${e.title} start: ${e.start} end: ${e.end} desc: ${e.description}').join('\n')}''',
  );
}

void _printUsage() {
  print('''
Usage:
tag_reader [-l logLevel(o|i|w|s)] file

logLevel: o(off, all messages) i(info and above) w(warning and above) s(severe and above, default)
''');
}
