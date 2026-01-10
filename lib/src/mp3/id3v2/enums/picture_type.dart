enum PictureType {
  fileIcon(1),
  otherFileIcon(2),
  coverFront(3),
  coverBack(4),
  leafletPage(5),
  media(6),
  leadArtist(7),
  artist(8),
  conductor(9),
  band(10),
  composer(11),
  lyricist(12),
  recordingLocation(13),
  duringRecording(14),
  duringPerformance(15),
  videoCapture(16),
  fish(17),
  illustration(18),
  bandArtistLogo(19),
  publisherStudioLogo(20),
  unknown(0xff);

  const PictureType(this.identifier);
  final int identifier;
}
