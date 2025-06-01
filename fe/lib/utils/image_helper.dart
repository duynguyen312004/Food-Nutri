// lib/utils/image_helper.dart

const _baseUrl = 'http://10.0.2.2:5000';

String normalizeImageUrl(String? imagePath) {
  if (imagePath == null || imagePath.isEmpty) return '';
  if (imagePath.startsWith('http')) return imagePath;
  if (imagePath.startsWith('/static/')) return '$_baseUrl$imagePath';
  return imagePath;
}
