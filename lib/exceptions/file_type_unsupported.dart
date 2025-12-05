class FileTypeUnsupported implements Exception {
  FileTypeUnsupported(this.message);
  final String message;

  @override
  String toString() => message;
}
