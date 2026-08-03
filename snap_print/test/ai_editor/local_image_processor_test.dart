import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:snap_print/features/ai_editor/data/local_image_processor.dart';

void main() {
  final processor = LocalImageProcessor();

  test('reads PNG dimensions without decoding image pixels', () async {
    final bytes = Uint8List(24);
    bytes.setAll(0, const [0x89, 0x50, 0x4E, 0x47]);
    final data = ByteData.sublistView(bytes);
    data.setUint32(16, 4000);
    data.setUint32(20, 3000);

    final metrics = await processor.metricsFromBytes(bytes);
    expect(metrics.width, 4000);
    expect(metrics.height, 3000);
    expect(metrics.megapixels, 12);
  });

  test('reads JPEG SOF dimensions without decoding image pixels', () async {
    final bytes = Uint8List.fromList([
      0xFF,
      0xD8,
      0xFF,
      0xC0,
      0x00,
      0x0B,
      0x08,
      0x0B,
      0xB8,
      0x0F,
      0xA0,
      0x03,
      0x01,
      0x11,
      0x00,
    ]);

    final metrics = await processor.metricsFromBytes(bytes);
    expect(metrics.width, 4000);
    expect(metrics.height, 3000);
  });

  test('rejects unsupported headers without allocating a bitmap', () async {
    await expectLater(
      processor.metricsFromBytes(Uint8List.fromList([1, 2, 3, 4])),
      throwsA(isA<UnsupportedImageFormatException>()),
    );
  });
}
