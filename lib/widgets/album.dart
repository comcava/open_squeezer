import 'package:blur_detector/controllers/home_controller.dart';
import 'package:flutter/material.dart';

import '../config/constants.dart';
import '../domain/album.dart';

/// Size of one photo  (pixels)
const double kPhotoSize = 100;

/// Padding around a photo (pixels)
const double kPhotoPadding = 2.5;

/// Size of a checkbox
const double kCheckboxSize = 25;

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
                if ((pos + idx) < photosPerRow) {
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

        return SizedBox(
          height: _AlbumTitle.height +
              photoRows.length * (kPhotoSize + kPhotoPadding * 2),
          child: Column(
            children: [
              _AlbumTitle(name: name),
              ...photoRows,
            ],
          ),
        );
      },
    );
  }
}

class _AlbumTitle extends StatelessWidget {
  // TODO: replace 50 with font size
  static const height = 50 + kDefaultPadding;

  final String? name;

  const _AlbumTitle({Key? key, this.name}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // todo: consider coloring it
    return Container(
      width: double.infinity,
      height: height,
      padding: const EdgeInsets.all(kDefaultPadding),
      // TODO: make text size 20
      child: Text(
        name ?? "",
        textAlign: TextAlign.start,
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
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(120),
                  borderRadius: BorderRadius.circular(kSmallBorderRadius),
                ),
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
