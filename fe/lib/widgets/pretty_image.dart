import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../utils/image_helper.dart';

class PrettyImage extends StatelessWidget {
  final String imagePath;
  final double width;
  final double height;
  final BoxFit fit;
  final String fallbackAsset;

  const PrettyImage({
    super.key,
    required this.imagePath,
    required this.width,
    required this.height,
    this.fit = BoxFit.cover,
    this.fallbackAsset = 'assets/images/food.jpg',
  });

  @override
  Widget build(BuildContext context) {
    final url = normalizeImageUrl(imagePath);
    // Nếu asset (bắt đầu bằng assets/)
    if (url.startsWith('assets/')) {
      return Image.asset(url, width: width, height: height, fit: fit);
    }
    // Ảnh BE hoặc ảnh mạng
    if (url.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: url,
        width: width,
        height: height,
        fit: fit,
        fadeInDuration: const Duration(milliseconds: 250),
        placeholder: (_, __) => Stack(
          children: [
            Image.asset(fallbackAsset, width: width, height: height, fit: fit),
            Container(
              width: width,
              height: height,
              color: Colors.black.withOpacity(0.2),
              child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2)),
            )
          ],
        ),
        errorWidget: (_, __, ___) => Image.asset(
          fallbackAsset,
          width: width,
          height: height,
          fit: fit,
        ),
      );
    }
    // fallback
    return Image.asset(fallbackAsset, width: width, height: height, fit: fit);
  }
}
