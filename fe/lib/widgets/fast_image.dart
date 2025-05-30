import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class FastImage extends StatelessWidget {
  final String imagePath;
  final double width;
  final double height;
  final BoxFit fit;
  final String fallbackAsset;

  const FastImage({
    super.key,
    required this.imagePath,
    required this.width,
    required this.height,
    this.fit = BoxFit.cover,
    this.fallbackAsset = 'assets/images/food.jpg',
  });

  @override
  Widget build(BuildContext context) {
    if (imagePath.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: imagePath,
        width: width,
        height: height,
        fit: fit,
        fadeInDuration: Duration.zero,
        placeholder: (_, __) => Image.asset(
          fallbackAsset,
          width: width,
          height: height,
          fit: fit,
        ),
        errorWidget: (_, __, ___) => Image.asset(
          fallbackAsset,
          width: width,
          height: height,
          fit: fit,
        ),
      );
    }
    return Image.asset(
      imagePath,
      width: width,
      height: height,
      fit: fit,
    );
  }
}
