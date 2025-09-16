import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

/// Optimized image widget with caching and performance improvements
class OptimizedImage extends StatefulWidget {
  final String? imageUrl;
  final String? assetPath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;
  final bool enableMemoryCache;
  final bool enableDiskCache;
  final Duration fadeInDuration;

  const OptimizedImage({
    super.key,
    this.imageUrl,
    this.assetPath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
    this.enableMemoryCache = true,
    this.enableDiskCache = true,
    this.fadeInDuration = const Duration(milliseconds: 300),
  }) : assert(imageUrl != null || assetPath != null, 'Either imageUrl or assetPath must be provided');

  @override
  _OptimizedImageState createState() => _OptimizedImageState();
}

class _OptimizedImageState extends State<OptimizedImage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _imageLoaded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.fadeInDuration,
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;

    if (widget.assetPath != null) {
      imageWidget = _buildAssetImage();
    } else {
      imageWidget = _buildNetworkImage();
    }

    if (widget.borderRadius != null) {
      imageWidget = ClipRRect(
        borderRadius: widget.borderRadius!,
        child: imageWidget,
      );
    }

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: imageWidget,
    );
  }

  Widget _buildAssetImage() {
    return Image.asset(
      widget.assetPath!,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      cacheWidth: widget.width?.toInt(),
      cacheHeight: widget.height?.toInt(),
      errorBuilder: (context, error, stackTrace) {
        return _buildErrorWidget();
      },
    );
  }

  Widget _buildNetworkImage() {
    return Image.network(
      widget.imageUrl!,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      cacheWidth: widget.width?.toInt(),
      cacheHeight: widget.height?.toInt(),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          if (!_imageLoaded) {
            _imageLoaded = true;
            _animationController.forward();
          }
          return FadeTransition(
            opacity: _fadeAnimation,
            child: child,
          );
        }
        return _buildLoadingWidget(loadingProgress);
      },
      errorBuilder: (context, error, stackTrace) {
        if (kDebugMode) {
          debugPrint('OptimizedImage: Failed to load ${widget.imageUrl}: $error');
        }
        return _buildErrorWidget();
      },
    );
  }

  Widget _buildLoadingWidget(ImageChunkEvent loadingProgress) {
    if (widget.placeholder != null) {
      return widget.placeholder!;
    }

    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.grey.shade100,
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    if (widget.errorWidget != null) {
      return widget.errorWidget!;
    }

    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.grey.shade200,
      child: Center(
        child: Icon(
          Icons.broken_image,
          color: Colors.grey.shade400,
          size: 32,
        ),
      ),
    );
  }
}

/// Optimized avatar widget for user profiles
class OptimizedAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? name;
  final double radius;
  final Color? backgroundColor;
  final TextStyle? textStyle;

  const OptimizedAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.radius = 20,
    this.backgroundColor,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return OptimizedImage(
        imageUrl: imageUrl,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        borderRadius: BorderRadius.circular(radius),
        placeholder: _buildInitialsAvatar(theme),
        errorWidget: _buildInitialsAvatar(theme),
      );
    }

    return _buildInitialsAvatar(theme);
  }

  Widget _buildInitialsAvatar(ThemeData theme) {
    final initials = _getInitials(name);
    
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? theme.colorScheme.primary,
      child: Text(
        initials,
        style: textStyle ?? TextStyle(
          color: theme.colorScheme.onPrimary,
          fontSize: radius * 0.6,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return '?';
    
    final words = name.trim().split(' ');
    if (words.length == 1) {
      return words[0].substring(0, 1).toUpperCase();
    }
    
    return '${words[0].substring(0, 1)}${words[1].substring(0, 1)}'.toUpperCase();
  }
}

/// Optimized list tile with image
class OptimizedListTile extends StatelessWidget {
  final String? imageUrl;
  final String? title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsets? contentPadding;

  const OptimizedListTile({
    super.key,
    this.imageUrl,
    this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: contentPadding,
      leading: imageUrl != null
          ? OptimizedAvatar(
              imageUrl: imageUrl,
              name: title,
              radius: 24,
            )
          : null,
      title: title != null ? Text(title!) : null,
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: trailing,
      onTap: onTap,
    );
  }
}

/// Cached network image with better performance
class CachedNetworkImage extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const CachedNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  @override
  _CachedNetworkImageState createState() => _CachedNetworkImageState();
}

class _CachedNetworkImageState extends State<CachedNetworkImage> {
  static final Map<String, ImageProvider> _imageCache = {};

  @override
  Widget build(BuildContext context) {
    // Use cached image provider if available
    final imageProvider = _imageCache[widget.imageUrl] ?? NetworkImage(widget.imageUrl);
    
    // Cache the image provider
    if (!_imageCache.containsKey(widget.imageUrl)) {
      _imageCache[widget.imageUrl] = imageProvider;
    }

    return Image(
      image: imageProvider,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        
        return widget.placeholder ?? Container(
          width: widget.width,
          height: widget.height,
          color: Colors.grey.shade100,
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return widget.errorWidget ?? Container(
          width: widget.width,
          height: widget.height,
          color: Colors.grey.shade200,
          child: Icon(Icons.error, color: Colors.grey),
        );
      },
    );
  }

  @override
  void dispose() {
    // Clean up cache if it gets too large
    if (_imageCache.length > 100) {
      _imageCache.clear();
    }
    super.dispose();
  }
}
