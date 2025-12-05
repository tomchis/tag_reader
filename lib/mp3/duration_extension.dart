import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:tag_reader/mp3/id3v2/enums/mpeg_versions.dart';
import 'package:tag_reader/util/buffered_reader.dart';

const _mp3HeaderVersionBitShift = 3;
const _mp3HeaderVersionBitMask = 1 << 4 | 1 << 3;
const _mp3HeaderLayerBitShift = 1;
const _mp3HeaderLayerBitMask = 1 << 2 | 1 << 1;
const _mp3HeaderBitrateBitShift = 4;
const _mp3HeaderSamplerateShift = 2;
const _mp3HeaderSamplerateMask = 1 << 3 | 1 << 2;

// Bitrates in kbps.
// x = MpegVersion/Layer: [V1/L1, V1/L2, V1/L3, V2/L1, V2/L2&L3]
// y = Bitrate index: 0..16. Row 0 and 16 are not in the matrix as they are unsupported.
const _mp3HeaderBitrateMatrix = [
  [32, 32, 32, 32, 8],
  [64, 48, 40, 48, 16],
  [96, 56, 48, 56, 24],
  [128, 64, 56, 64, 32],
  [160, 80, 64, 80, 40],
  [192, 96, 80, 96, 48],
  [224, 112, 96, 112, 56],
  [256, 128, 112, 128, 64],
  [288, 160, 128, 144, 80],
  [320, 192, 160, 160, 96],
  [352, 224, 192, 176, 112],
  [384, 256, 224, 192, 128],
  [416, 320, 256, 224, 144],
  [448, 384, 320, 256, 160],
];

// Samplerates in Hz.
// x = MpegVersion [1, 2, 2.5]
// y = Samplerate index: 0..3. Column 3 is reserved and not in the matrix.
const _mp3SamplerateMatrix = [
  [44100, 22050, 11025],
  [48000, 24000, 12000],
  [32000, 16000, 8000],
];

// x = MpegVersion [1, 2, 2.5]
// y = Layer [Layer I, Layer II, Layer III]
const _mp3SamplesPerFrameMatrix = [
  [384, 384, 384],
  [1152, 1152, 1152],
  [1152, 576, 576],
];
const _lastThreeSyncBits = 1 << 7 | 1 << 6 | 1 << 5;

extension Mp3DurationExtension on BufferedReader {
  Future<Duration?> determineMp3Duration({int? tagSize}) async {
    tagSize ??= 0;
    await setPosition(tagSize);

    // Find the sync, 11 (1 bits). Should be right after or close after tagSize.
    Uint8List buffer;
    int syncIndex = -1;

    outer:
    while (true) {
      buffer = await read(100);
      if (buffer.isEmpty) return null;

      for (int i = 0; i < buffer.length - 1; i++) {
        if (buffer[i] == 255 && (buffer[i + 1] & _lastThreeSyncBits != 0)) {
          syncIndex = i;
          break outer;
        }
      }
    }

    if (syncIndex == -1) return null;

    final Uint8List mp3HeaderBytes;
    if (buffer.length - syncIndex >= 4) {
      final start = syncIndex + 1;
      final end = start + 3;
      mp3HeaderBytes = buffer.sublist(start, end);
    } else {
      await setPosition(tagSize + syncIndex + 1);
      mp3HeaderBytes = await read(3);
    }

    final versionLayerBits = mp3HeaderBytes[0];
    final bitrateSampleRateBits = mp3HeaderBytes[1];

    final versionInt =
        (versionLayerBits & _mp3HeaderVersionBitMask) >>
        _mp3HeaderVersionBitShift;
    final version = MpegVersion.values.firstWhereIndexedOrNull(
      (index, element) => element.identifier == versionInt,
    );
    if (version == null || version == .reserved) return null;

    final layerInt =
        (versionLayerBits & _mp3HeaderLayerBitMask) >> _mp3HeaderLayerBitShift;
    final layer = Layer.values.firstWhereOrNull(
      (element) => element.identifier == layerInt,
    );
    if (layer == null || layer == .reserved) return null;

    // Skip padding before potential xing header, indicating VBR.
    await setPosition(tagSize + syncIndex + 4 + 32);
    //final vbrHeaderReader = ByteReader(await read(32));
    //if (vbrHeaderReader.bytesRemaining >= 4) {
    final headerId = String.fromCharCodes(await read(4));
    if (headerId == 'Xing' || headerId == 'Info' || headerId == 'VBRI') {
      // Xing or Info(CBR)
      if (headerId != 'VBRI') {
        // Flags:
        // 0x0001 - Frames field is present
        // 0x0002 - Bytes field is present
        // 0x0004 - TOC field is present
        // 0x0008 - Quality indicator field is present
        final hasFrameField = (await readUint32()) & 1 != 0;
        if (!hasFrameField) {
          if (headerId == 'Info') {
            return _calculateCbrDuration(
              bitrateSampleRateBits: bitrateSampleRateBits,
              version: version,
              layer: layer,
              tagSize: tagSize,
            );
          }
          return null;
        }
      } else {
        // Skip versionId(2), delay(2), quality indicator(2), number of bytes(4).
        await skip(10);
      }
      final numberOfFrames = await readUint32();

      final samplerateIndex =
          (bitrateSampleRateBits & _mp3HeaderSamplerateMask) >>
          _mp3HeaderSamplerateShift;
      if (samplerateIndex < 0 ||
          samplerateIndex >= _mp3SamplerateMatrix.length) {
        return null;
      }
      final sampleRate = switch ((version)) {
        .one => _mp3SamplerateMatrix[samplerateIndex][0],
        .two => _mp3SamplerateMatrix[samplerateIndex][1],
        .twoPointFive => _mp3SamplerateMatrix[samplerateIndex][2],
        _ => -1,
      };
      if (sampleRate == -1) return null;

      final samplesPerFrame = switch ((layer, version)) {
        (Layer.one, MpegVersion.one) => _mp3SamplesPerFrameMatrix[0][0],
        (Layer.one, MpegVersion.two) => _mp3SamplesPerFrameMatrix[0][1],
        (Layer.one, MpegVersion.twoPointFive) =>
          _mp3SamplesPerFrameMatrix[0][2],
        (Layer.two, MpegVersion.one) => _mp3SamplesPerFrameMatrix[1][0],
        (Layer.two, MpegVersion.two) => _mp3SamplesPerFrameMatrix[1][1],
        (Layer.two, MpegVersion.twoPointFive) =>
          _mp3SamplesPerFrameMatrix[1][2],
        (Layer.three, MpegVersion.one) => _mp3SamplesPerFrameMatrix[2][0],
        (Layer.three, MpegVersion.two) => _mp3SamplesPerFrameMatrix[2][1],
        (Layer.three, MpegVersion.twoPointFive) =>
          _mp3SamplesPerFrameMatrix[2][2],
        _ => -1,
      };
      if (samplesPerFrame == -1) return null;

      final millis = ((numberOfFrames * samplesPerFrame) / sampleRate) * 1000;
      return Duration(milliseconds: millis.toInt());
    }

    return _calculateCbrDuration(
      bitrateSampleRateBits: bitrateSampleRateBits,
      version: version,
      layer: layer,
      tagSize: tagSize,
    );
  }

  Future<Duration?> _calculateCbrDuration({
    required int bitrateSampleRateBits,
    required MpegVersion version,
    required Layer layer,
    required int tagSize,
  }) async {
    final bitrateIndex = bitrateSampleRateBits >> _mp3HeaderBitrateBitShift;
    // bitrateIndex of 0 and 16 are unsupported.
    if (bitrateIndex < 1 || bitrateIndex > _mp3HeaderBitrateMatrix.length) {
      return null;
    }

    final layerIndex = switch ((version, layer)) {
      (MpegVersion.one, Layer.one) => 0,
      (MpegVersion.one, Layer.two) => 1,
      (MpegVersion.one, Layer.three) => 2,
      (MpegVersion.two, Layer.one) ||
      (MpegVersion.twoPointFive, Layer.one) => 3,
      (MpegVersion.two, Layer.two) ||
      (MpegVersion.two, Layer.three) ||
      (MpegVersion.twoPointFive, Layer.two) ||
      (MpegVersion.twoPointFive, Layer.three) => 4,
      _ => -1,
    };
    if (layerIndex == -1) return null;

    final bitrate = _mp3HeaderBitrateMatrix[bitrateIndex - 1][layerIndex];
    final mp3Size = await length() - tagSize;

    // mp3Size * 8 to convert from bytes to bits. bitrate * 1000 to covert
    // from kbps to bps. * 1000 to convert from seconds into millis.
    final durationMillis = ((mp3Size * 8) / (bitrate * 1000)) * 1000;

    return Duration(milliseconds: durationMillis.toInt());
  }
}
