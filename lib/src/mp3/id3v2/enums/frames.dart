enum Frames {
  comment(['COMM', 'COM']),
  coverArt(['APIC', 'PIC']),
  chapters(['CHAP']),
  userDefinedText(['TXXX', 'TXX']),

  // Text frames //
  title(['TIT2', 'TT2']),
  artist(['TPE1', 'TP1']),
  album(['TALB', 'TAL']),
  albumArtist(['TPE2', 'TP2']),
  description(['TIT3', 'TT3']),
  genres(['TCON', 'TCO']),

  /// Composer or Narrator
  composer(['TCOM', 'TCM']),

  /// Track number/Position in set i.e (4/9)
  trackNumber(['TRCK', 'TRK']),

  /// Year YYYY
  year(['TYER', 'TYE']),

  /// DayMonth DDMM
  dayMonth(['TDAT', 'TDA']),
  dateRecording(['TDRC', 'TRD']),
  dateRelease(['TDOR']);

  const Frames(this.identifier);
  final List<String> identifier;
}
