import 'dart:async';

import 'package:tag_reader/mp4/atoms/atom.dart';
import 'package:tag_reader/util/byte_reader.dart';

typedef SampleEntry = ({int count, int duration});

/// Sync sample atom:
/// Identifies the key frames in the media.
class Stts extends AtomLeaf {
  Stts(super.size);

  // Stores the durations of samples. If consecutive samples have the same
  // duration they are represented by an increase in count.
  final List<SampleEntry> samples = [];

  @override
  FutureOr<Stts> parse(ByteReader reader) async {
    // Skip version(1), flags(3), entryCount(4).
    reader.skip(8);

    while (reader.bytesRemaining >= 8) {
      final sampleCount = reader.readUint32();
      final sampleDuration = reader.readUint32();
      samples.add((count: sampleCount, duration: sampleDuration));
    }

    return this;
  }

  // int mediaDuration() => samples
  //     .fold<double>(
  //       0,
  //       (previousValue, element) =>
  //           previousValue + (element.count * element.duration),
  //     )
  //     .toInt();

  List<int> getStartTimes(int timeScale, int initialStartTime) {
    final startTimes = [initialStartTime];

    if (samples.isNotEmpty) {
      int currentTime = initialStartTime;

      if (samples.length > 1) {
        // Handle all but last sample.
        for (int i = 0; i < samples.length - 1; i++) {
          final sample = samples[i];
          int count = sample.count;
          while (count > 0) {
            final duration = (sample.duration / timeScale) * 1000;
            currentTime += duration.round().toInt();
            startTimes.add(currentTime);
            count -= 1;
          }
        }
      }

      // The final sample (samples.last where count == 1) will have a start time
      // of 0, skip it.
      final lastSample = samples.last;
      // if this sample count is 1, this won't be executed
      int count = lastSample.count - 1;
      while (count > 0) {
        currentTime += lastSample.duration.round().toInt();
        startTimes.add(currentTime);
        count -= 1;
      }
    }

    return startTimes;
  }
}
