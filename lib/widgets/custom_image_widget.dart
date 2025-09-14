import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CustomImageWidget extends StatelessWidget {
  final String? imageUrl;
  final String? imagePath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;
  final Color? color;

  const CustomImageWidget({
    Key? key,
    this.imageUrl,
    this.imagePath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;

    // Default placeholder
    Widget defaultPlaceholder = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: borderRadius,
      ),
      child: Icon(
        Icons.person,
        size: (width != null && height != null) 
            ? (width! < height! ? width! * 0.6 : height! * 0.6)
            : 24,
        color: Colors.grey.shade400,
      ),
    );

    // Default error widget
    Widget defaultErrorWidget = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: borderRadius,
      ),
      child: Icon(
        Icons.broken_image,
        size: (width != null && height != null) 
            ? (width! < height! ? width! * 0.6 : height! * 0.6)
            : 24,
        color: Colors.grey.shade400,
      ),
    );

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      // Network image
      imageWidget = CachedNetworkImage(
        imageUrl: imageUrl!,
        width: width,
        height: height,
        fit: fit,
        color: color,
        placeholder: (context, url) => placeholder ?? defaultPlaceholder,
        errorWidget: (context, url, error) => errorWidget ?? defaultErrorWidget,
      );
    } else if (imagePath != null && imagePath!.isNotEmpty) {
      // Asset image
      imageWidget = Image.asset(
        imagePath!,
        width: width,
        height: height,
        fit: fit,
        color: color,
        errorBuilder: (context, error, stackTrace) => errorWidget ?? defaultErrorWidget,
      );
    } else {
      // No image provided, show placeholder
      imageWidget = placeholder ?? defaultPlaceholder;
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }
}
