class Chapter {
  const Chapter({
    required this.title,
    this.description,
    required this.start,
    this.end,
  });
  final String title;
  final String? description;

  /// In milliseconds
  final int start;

  /// In milliseconds, may be -1
  final int? end;
}
