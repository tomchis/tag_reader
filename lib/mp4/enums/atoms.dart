enum Atoms {
  co64('co64'),
  data('data'),
  edts('edts'),
  elst('elst'),
  hdlr('hdlr'),
  ilst('ilst'),
  mdhd('mdhd'),
  mdia('mdia'),
  minf('minf'),
  meta('meta'),
  moov('moov'),
  //Unused
  //mvhd('mvhd'),
  stbl('stbl'),
  stco('stco'),
  stsz('stsz'),
  stts('stts'),
  tkhd('tkhd'),
  trak('trak'),
  tref('tref'),
  udta('udta'),

  /// iTunes chapter ids
  chap('chap'),

  /// Nero chapters
  chpl('chpl'),

  // Part and Total values //
  /// Track number
  trkn('trkn'),

  /// Disk number
  disk('disk'),

  // String values //

  /// Album artist
  aArt('aART'),

  /// Album
  alb('©alb'),

  /// Artist or Author
  art('©ART'),

  /// Composer or narrator
  com('©com'),

  // Cover art
  covr('covr'),

  /// Creation date
  day('©day'),

  /// Description short
  des('©des'),

  /// Media item description
  desc('desc'),

  /// Genre
  genr('genr'),

  /// Genre alt
  gen('©gen'),

  /// Genre alt
  gnre('gnre'),

  /// Title
  nam('©nam'),

  /// Narrator, used by audible.
  nrt('©nrt'),

  // Integer values //

  /// iTunes genre id
  geId('geID');

  const Atoms(this.identifier);
  final String identifier;
}
