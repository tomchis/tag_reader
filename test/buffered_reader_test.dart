import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart';
import 'package:tag_reader/src/util/buffered_reader.dart';
import 'package:tag_reader/src/util/byte_reader.dart';
import 'package:test/test.dart';

import 'util.dart';

void main() {
  final path = join(dataPath, 'lorem.txt');
  test('read', () async {
    final reader = await BufferedReader.open(path, bufferSize: 10);
    final bytes1 = await reader.read(4);
    final bytes2 = await reader.read(4);
    final string = String.fromCharCodes([...bytes1, ...bytes2]);
    expect(string, 'Lorem ip');
  });

  test('read to end', () async {
    final length = await File(path).length();
    final reader = await BufferedReader.open(path);
    final bytes = await reader.read(length);
    expect(bytes.length, length);
    final bytes2 = await reader.read(10);
    expect(bytes2.isEmpty, true);
  });

  test('read bigger than buffer', () async {
    final reader = await BufferedReader.open(path, bufferSize: 10);
    final bytes1 = await reader.read(4);
    final bytes2 = await reader.read(20);
    final string = String.fromCharCodes([...bytes1, ...bytes2]);
    expect(string, 'Lorem ipsum dolor sit am');
  });

  test('postion', () async {
    final reader = await BufferedReader.open(path, bufferSize: 100);
    await reader.read(30);
    expect(await reader.position(), 30);
    await reader.read(80);
    expect(await reader.position(), 110);
  });

  test('setPosition no buffer', () async {
    final reader = await BufferedReader.open(path, bufferSize: 1);
    await reader.setPosition(4);
    final string = String.fromCharCodes(await reader.read(3));
    expect(string, 'm i');
  }, timeout: Timeout(Duration(seconds: 10)));

  test('setPosition buffer', () async {
    final reader = await BufferedReader.open(path, bufferSize: 10);
    await reader.read(3);
    await reader.setPosition(4);
    var string = String.fromCharCodes(await reader.read(3));
    expect(await reader.position(), 7);
    expect(string, 'm i');
    await reader.setPosition(4);
    string = String.fromCharCodes(await reader.read(3));
    expect(string, 'm i');
  });

  test('bytes remaining in file', () async {
    final length = await File(path).length();
    final reader = await BufferedReader.open(path, bufferSize: 10);
    await reader.read(5);
    expect(await reader.bytesInFileRemaining(), length - 5);
  });

  test('skip', () async {
    final reader = await BufferedReader.open(path, bufferSize: 10);
    await reader.read(5);
    await reader.skip(2);
    expect(await reader.position(), 7);
    await reader.skip(4);
    expect(await reader.position(), 11);
  });

  test('skip negative', () async {
    final reader = await BufferedReader.open(path, bufferSize: 10);
    await reader.read(5);
    await reader.skip(-5);
    expect(await reader.position(), 0);
    await reader.read(15);
    expect(await reader.position(), 15);
    await reader.skip(-10);
    expect(await reader.position(), 5);
  });

  test('ByteReader skip out of range throws', () async {
    final byteReader = ByteReader(Uint8List(10));
    byteReader.read(5);

    expect(() async => byteReader.skip(-6), throwsRangeError);

    expect(() => byteReader.skip(5), throwsRangeError);
  });
}
