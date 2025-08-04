import 'package:fluent_ui/fluent_ui.dart';
import 'dart:io';

class AppImageWidget extends StatelessWidget {
  final String path;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;

  const AppImageWidget({
    super.key,
    required this.path,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.errorWidget,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;
    
    // Check if it's a file path or asset path
    if (path.startsWith('assets/')) {
      // Asset image
      imageWidget = Image.asset(
        path,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return errorWidget ?? _defaultErrorWidget(context);
        },
      );
    } else if (path.startsWith('http') || path.startsWith('https')) {
      imageWidget = FadeInImage.assetNetwork(
        placeholder: 'assets/icons/default.png',
        image: path,
        width: width,
        height: height,
        fit: fit,
        imageCacheWidth: width?.toInt(),
        imageCacheHeight: height?.toInt(),
        imageErrorBuilder: (context, error, stackTrace) {
          return errorWidget ?? _defaultErrorWidget(context);
        },
        placeholderErrorBuilder: (context, error, stackTrace) {
          return _defaultErrorWidget(context);
        },
      );
    }
    else {
      // File image
      try {
        final file = File(path);
        if (file.existsSync()) {
          imageWidget = Image.file(
            file,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (context, error, stackTrace) {
              return errorWidget ?? _defaultErrorWidget(context);
            },
          );
        } else {
          imageWidget = errorWidget ?? _defaultErrorWidget(context);
        }
      } catch (e) {
        imageWidget = errorWidget ?? _defaultErrorWidget(context);
      }
    }

    // Apply border radius if specified
    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  Widget _defaultErrorWidget(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: FluentTheme.of(context).accentColor.withValues(alpha: 0.1),
      child: Icon(
        FluentIcons.photo,
        color: FluentTheme.of(context).accentColor.withValues(alpha: 0.5),
      ),
    );
  }
}


class CircleAvatarImage extends StatefulWidget {
  final String path;
  final double? radius;
  final Widget? errorWidget;

  const CircleAvatarImage({super.key, required this.path, this.radius, this.errorWidget});

  @override
  State<CircleAvatarImage> createState() => _CircleAvatarImageState();
}

class _CircleAvatarImageState extends State<CircleAvatarImage> {
  bool isError = false;
  @override
  Widget build(BuildContext context) {
    bool isNetworkImage = widget.path.startsWith('http') || widget.path.startsWith('https');
    ImageProvider? imageProvider;
    if(isNetworkImage){
      imageProvider = NetworkImage(widget.path);
    }
    else if(widget.path.startsWith('assets/')){
      imageProvider = AssetImage(widget.path);
    }
    else{
      imageProvider = FileImage(File(widget.path));
    }
    if(isError){
      return CircleAvatar(
        radius: widget.radius,
        backgroundColor: FluentTheme.of(context).accentColor,
        child: widget.errorWidget ?? Icon(
          FluentIcons.photo,
          color: Colors.white,
        ),
      );
    }

    return CircleAvatar(
      radius: widget.radius,
      backgroundImage: imageProvider,
      onBackgroundImageError: (error, stackTrace) {
        setState(() {
          isError = true;
        });
      },
      backgroundColor: FluentTheme.of(context).accentColor,
    );
  }
}