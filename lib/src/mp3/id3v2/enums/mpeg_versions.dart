enum MpegVersion {
  twoPointFive(0),
  reserved(1),
  two(2),
  one(3);

  const MpegVersion(this.identifier);
  final int identifier;
}

enum Layer {
  reserved(0),
  three(1),
  two(2),
  one(3);

  const Layer(this.identifier);
  final int identifier;
}
