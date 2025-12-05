//import 'dart:mirrors';
import 'dart:io';

import 'package:path/path.dart';

//String get testPath =>
//    dirname((reflectClass(_TestUtils).owner as LibraryMirror).uri.path);
//
String get testPath => join(Directory.current.path, 'test');

String get mediaPath => join(testPath, 'media');

String get dataPath => join(testPath, 'data');

//class _TestUtils {}
