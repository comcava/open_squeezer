import 'package:flutter/material.dart';

import '../config/constants.dart';
import '../domain/album.dart';

/// Size of one photo  (pixels)
const double kPhotoSize = 100;

/// Padding around a photo (pixels)
const double kPhotoPadding = 2.5;

/// Size of a checkbox
const double kCheckboxSize = 25;

final BoxDecoration containerDecoration = BoxDecoration(
  color: Colors.black.withAlpha(120),
  borderRadius: BorderRadius.circular(kSmallBorderRadius),
);

class Album extends StatelessWidget {
  final String name;
  final int itemsLength;
  final Widget Function(int index) builder;

  const Album({
    Key? key,
    required this.name,
    required this.itemsLength,
    required this.builder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        List<Widget> photoRows = List.empty(growable: true);

        var photosPerRow = (constraints.maxWidth / kPhotoSize).floor();

        for (var idx = 0; idx < itemsLength; idx += photosPerRow) {
          photoRows.add(
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(photosPerRow, (pos) {
                if ((pos + idx) < itemsLength) {
                  return SizedBox(
                    width: kPhotoSize,
                    height: kPhotoSize,
                    child: builder(pos + idx),
                  );
                } else {
                  return const SizedBox(
                    width: kPhotoSize,
                    height: kPhotoSize,
                  );
                }
              }),
            ),
          );
        }

        var albumTitle = _AlbumTitle(name: name);

        return SizedBox(
          height: albumTitle.height(context) +
              photoRows.length * (kPhotoSize + kPhotoPadding * 2),
          child: Column(
            children: [
              albumTitle,
              ...photoRows,
            ],
          ),
        );
      },
    );
  }
}

class _AlbumTitle extends StatelessWidget {
  final String? name;

  const _AlbumTitle({Key? key, this.name}) : super(key: key);

  double height(BuildContext context) {
    final theme = Theme.of(context);

    return
        // from padding
        kDefaultPadding * 2 +
            // 16 is the default font size
            (theme.textTheme.headlineSmall?.fontSize ?? 16) * 2;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(kDefaultPadding),
      child: Text(
        name ?? "",
        textAlign: TextAlign.start,
        style: theme.textTheme.headlineSmall,
      ),
    );
  }
}

class PhotoThumbnail extends StatefulWidget {
  final bool isChecked;
  final Function(String photoId) onPhotoSelected;
  final PhotoItem item;

  const PhotoThumbnail({
    Key? key,
    required this.isChecked,
    required this.onPhotoSelected,
    required this.item,
  }) : super(key: key);

  @override
  State<PhotoThumbnail> createState() => _PhotoThumbnailState();
}

class _PhotoThumbnailState extends State<PhotoThumbnail> {
  Widget? _imageWidget;

  @override
  initState() {
    super.initState();
    _fetchImage();
  }

  _fetchImage() async {
    var data = await widget.item.photo.thumbnailData;

    if (data == null) {
      return;
    }

    _imageWidget ??= Image.memory(
      data,
      fit: BoxFit.cover,
    );

    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_imageWidget == null) {
      return _buildPlaceholder(theme);
    }

    var photoPadding = widget.isChecked ? kPhotoPadding * 4 : kPhotoPadding;

    return GestureDetector(
      onTap: () {
        widget.onPhotoSelected(widget.item.photo.id);
      },
      child: AnimatedContainer(
        duration: kDefaultAnimationDuration,
        padding: EdgeInsets.all(photoPadding),
        width: kPhotoSize,
        height: kPhotoSize,
        child: Stack(
          children: [
            SizedBox(
              height: kPhotoSize,
              width: kPhotoSize,
              child: _imageWidget,
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Container(
                width: kCheckboxSize,
                height: kCheckboxSize,
                decoration: containerDecoration,
                child: Checkbox(
                  value: widget.isChecked,
                  fillColor: MaterialStateProperty.all(
                    theme.colorScheme.primary,
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onChanged: (newVal) {
                    widget.onPhotoSelected(widget.item.photo.id);
                  },
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Container _buildPlaceholder(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(kPhotoPadding),
      width: kPhotoSize,
      height: kPhotoSize,
      child: Container(
        color: theme.colorScheme.secondaryContainer,
      ),
    );
  }
}

class VideoThumbnail extends StatefulWidget {
  final bool isChecked;
  final Function(String id) onSelected;
  final VideoItem item;

  const VideoThumbnail({
    Key? key,
    required this.isChecked,
    required this.onSelected,
    required this.item,
  }) : super(key: key);
  @override
  State<VideoThumbnail> createState() => _VideoThumbnailState();
}

class _VideoThumbnailState extends State<VideoThumbnail> {
  Widget? _imageWidget;
  String? _lenText;

  @override
  initState() {
    super.initState();
    _fetchImage();
    _genLenText();
  }

  _fetchImage() async {
    var data = await widget.item.video.thumbnailData;

    if (data == null) {
      return;
    }

    _imageWidget ??= Image.memory(
      data,
      fit: BoxFit.cover,
    );

    if (!mounted) return;
    setState(() {});
  }

  _genLenText() {
    var lenBytes = widget.item.lengthBytes;

    if (lenBytes == null) return;

    const kbBytes = 1024;
    const mbBytes = 1024 * kbBytes;
    const gbBytes = 1024 * mbBytes;

    var lenGb = lenBytes / gbBytes;
    if (lenGb > 1) {
      _lenText = "${lenGb.toStringAsFixed(1)} gb";
      return;
    }
    var lenMb = lenBytes / mbBytes;
    if (lenMb > 1) {
      _lenText = "${lenMb.round()} mb";
      return;
    }

    var lenKb = lenBytes / kbBytes;
    if (lenKb > 1) {
      _lenText = "${lenKb.round()} kb";
      return;
    }

    _lenText = "$lenBytes b";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    _genLenText();

    if (_imageWidget == null) {
      return _buildPlaceholder(theme);
    }

    var photoPadding = widget.isChecked ? kPhotoPadding * 4 : kPhotoPadding;

    return GestureDetector(
      onTap: () {
        widget.onSelected(widget.item.video.id);
      },
      child: AnimatedContainer(
        duration: kDefaultAnimationDuration,
        padding: EdgeInsets.all(photoPadding),
        width: kPhotoSize,
        height: kPhotoSize,
        child: Stack(
          children: [
            SizedBox(
              height: kPhotoSize,
              width: kPhotoSize,
              child: _imageWidget,
            ),
            Align(
              alignment: Alignment.topLeft,
              child: Container(
                decoration: containerDecoration,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.play_arrow,
                      color: Colors.grey.shade200,
                      size: kCheckboxSize,
                    ),
                    if (_lenText != null)
                      Padding(
                        // Icon before already has padding
                        padding: const EdgeInsets.only(right: 5),
                        child: Text(
                          _lenText!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade200,
                          ),
                        ),
                      )
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Container(
                width: kCheckboxSize,
                height: kCheckboxSize,
                decoration: containerDecoration,
                child: Checkbox(
                  value: widget.isChecked,
                  fillColor: MaterialStateProperty.all(
                    theme.colorScheme.primary,
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onChanged: (newVal) {
                    widget.onSelected(widget.item.video.id);
                  },
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Container _buildPlaceholder(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(kPhotoPadding),
      width: kPhotoSize,
      height: kPhotoSize,
      child: Container(
        color: theme.colorScheme.secondaryContainer,
      ),
    );
  }
}
