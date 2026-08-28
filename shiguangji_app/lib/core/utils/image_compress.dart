import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_image_compress/flutter_image_compress.dart';

/// 图片压缩工具：发布菜谱前把封面压到 ≤500KB（统一转 JPEG，最长边 ≤1200）。
///
/// 策略与后端 UploadService 兜底保持一致：
///   质量 80 起步 → 仍超则 -10 逐档降（下限 50），每轮从原图重压避免累积劣化
///   → 仍未达标再缩到最长边 1080 + 质量 50，保证 ≤500KB。
///
/// 例外（原样返回，不视为失败）：
///   * web 端插件不可用
///   * gif 动图（重压会丢动画）
/// 压缩过程抛错返回 failed=true：调用方提示用户后照常上传原图（后端兜底）。
class ImageCompressor {
  static const _targetBytes = 500 * 1024;

  /// 压缩图片。返回 (压缩后字节, 建议上传的文件名, 是否失败)。
  static Future<({Uint8List data, String fileName, bool failed})> compress(
      Uint8List bytes, String fileName) async {
    if (kIsWeb || _isGif(bytes)) {
      return (data: bytes, fileName: fileName, failed: false);
    }
    try {
      // 已是 JPEG 且达标：跳过重压，避免一次不必要的画质损失
      if (_isJpeg(bytes) && bytes.length <= _targetBytes) {
        return (data: bytes, fileName: fileName, failed: false);
      }
      var out = await _encode(bytes, quality: 80);
      var q = 80;
      while (out.length > _targetBytes && q > 50) {
        q -= 10;
        out = await _encode(bytes, quality: q);
      }
      if (out.length > _targetBytes) {
        out = await _encode(bytes, quality: 50, side: 1080);
      }
      return (
        data: out,
        fileName: '${_baseName(fileName)}.jpg',   // 格式已转 JPEG，文件名同步改
        failed: false,
      );
    } catch (_) {
      return (data: bytes, fileName: fileName, failed: true);
    }
  }

  /// 按扩展名给出 multipart Content-Type 子类型（后端校验要求 image/*）
  static String mediaSubtype(String fileName) {
    final e = fileName.contains('.')
        ? fileName.substring(fileName.lastIndexOf('.') + 1).toLowerCase()
        : '';
    return const {'jpg': 'jpeg', 'jpeg': 'jpeg', 'png': 'png', 'gif': 'gif', 'webp': 'webp'}[e]
        ?? 'jpeg';
  }

  static Future<Uint8List> _encode(Uint8List bytes,
      {required int quality, int side = 1200}) {
    return FlutterImageCompress.compressWithList(
      bytes,
      // minWidth/minHeight 语义是"装进 side×side 的框"等比缩小 → 最长边 ≤ side
      minWidth: side,
      minHeight: side,
      quality: quality,
      format: CompressFormat.jpeg,
      keepExif: true,   // 保留 EXIF 方向信息，避免竖拍照片被压横
    );
  }

  static bool _isGif(Uint8List b) =>
      b.length > 3 && b[0] == 0x47 && b[1] == 0x49 && b[2] == 0x46;   // 'GIF' 魔数
  static bool _isJpeg(Uint8List b) =>
      b.length > 2 && b[0] == 0xFF && b[1] == 0xD8;   // SOI 魔数
  static String _baseName(String name) {
    final dot = name.lastIndexOf('.');
    return dot > 0 ? name.substring(0, dot) : name;
  }
}
