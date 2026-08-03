import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../domain/local_image_metrics.dart';

const int kMaxEditableImageBytes = 50 * 1024 * 1024;

class UnsupportedImageFormatException implements Exception {
  const UnsupportedImageFormatException([
    this.message = "This image format isn't supported. Try JPG, PNG, or WebP.",
  ]);
  final String message;
  @override
  String toString() => message;
}

class ImageTooLargeException implements Exception {
  const ImageTooLargeException([
    this.message = 'Image is too large to edit (max 50MB).',
  ]);
  final String message;
  @override
  String toString() => message;
}

/// Downloads the working image and reads only its format header. It never
/// allocates a decoded full-resolution bitmap, keeping print-quality checks
/// safe on low-memory phones even for large camera files.
class LocalImageProcessor {
  Future<Uint8List> downloadBytes(String url) async {
    final response = await Dio().get<List<int>>(
      url,
      options: Options(
        responseType: ResponseType.bytes,
        receiveTimeout: const Duration(seconds: 30),
      ),
    );
    final bytes = Uint8List.fromList(response.data ?? const []);
    if (bytes.length > kMaxEditableImageBytes) {
      throw const ImageTooLargeException();
    }
    return bytes;
  }

  Future<LocalImageMetrics> metricsFromBytes(Uint8List bytes) async {
    final dimensions = _readDimensions(bytes);
    if (dimensions == null) throw const UnsupportedImageFormatException();
    return LocalImageMetrics(
      width: dimensions.$1,
      height: dimensions.$2,
      fileSizeBytes: bytes.length,
    );
  }
}

(int, int)? _readDimensions(Uint8List bytes) {
  if (bytes.length >= 24 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4E &&
      bytes[3] == 0x47) {
    final data = ByteData.sublistView(bytes);
    return (data.getUint32(16), data.getUint32(20));
  }
  if (bytes.length >= 4 && bytes[0] == 0xFF && bytes[1] == 0xD8) {
    return _readJpegDimensions(bytes);
  }
  if (bytes.length >= 30 &&
      String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF' &&
      String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP') {
    return _readWebpDimensions(bytes);
  }
  return null;
}

(int, int)? _readJpegDimensions(Uint8List bytes) {
  var offset = 2;
  final data = ByteData.sublistView(bytes);
  while (offset + 8 < bytes.length) {
    if (bytes[offset] != 0xFF) {
      offset++;
      continue;
    }
    final marker = bytes[offset + 1];
    offset += 2;
    if (marker == 0xD8 || marker == 0xD9) continue;
    if (offset + 2 > bytes.length) return null;
    final length = data.getUint16(offset);
    if (length < 2 || offset + length > bytes.length) return null;
    final isStartOfFrame =
        marker >= 0xC0 &&
        marker <= 0xCF &&
        !{0xC4, 0xC8, 0xCC}.contains(marker);
    if (isStartOfFrame && offset + 7 < bytes.length) {
      return (data.getUint16(offset + 5), data.getUint16(offset + 3));
    }
    offset += length;
  }
  return null;
}

(int, int)? _readWebpDimensions(Uint8List bytes) {
  final chunk = String.fromCharCodes(bytes.sublist(12, 16));
  final data = ByteData.sublistView(bytes);
  if (chunk == 'VP8X') {
    final width = 1 + bytes[24] + (bytes[25] << 8) + (bytes[26] << 16);
    final height = 1 + bytes[27] + (bytes[28] << 8) + (bytes[29] << 16);
    return (width, height);
  }
  if (chunk == 'VP8 ') {
    return (
      data.getUint16(26, Endian.little) & 0x3FFF,
      data.getUint16(28, Endian.little) & 0x3FFF,
    );
  }
  if (chunk == 'VP8L' && bytes[20] == 0x2F) {
    final bits = data.getUint32(21, Endian.little);
    return ((bits & 0x3FFF) + 1, ((bits >> 14) & 0x3FFF) + 1);
  }
  return null;
}
