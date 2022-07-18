import 'dart:typed_data';

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
  final AlbumItem albumItem;
  final PhotoIdsSet selectedPhotoIds;
  final Function(String photoId) onPhotoSelected;

  const Album({
    Key? key,
    required this.albumItem,
    required this.onPhotoSelected,
    required this.selectedPhotoIds,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        List<Widget> photoRows = List.empty(growable: true);

        var photosPerRow = (constraints.maxWidth / kPhotoSize).floor();

        for (var idx = 0; idx < albumItem.photos.length; idx += photosPerRow) {
          photoRows.add(
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              // TODO: different number of images
              //       in a row per screen size
              children: List.generate(3, (pos) {
                if ((pos + idx) < albumItem.photos.length) {
                  return buildPhotoItem(albumItem.photos[pos + idx]);
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
              _AlbumTitle(name: albumItem.album.name),
              ...photoRows,
            ],
          ),
        );
      },
    );
  }

  FutureBuilder<Uint8List> buildPhotoItem(PhotoItem item) {
    return FutureBuilder<Uint8List>(
      future: () async {
        var data = await item.photo.thumbnailData;
        return data!;
      }(),
      builder: (context, AsyncSnapshot<Uint8List> snapshot) {
        final theme = Theme.of(context);

        var photoImgSize = kPhotoSize - kPhotoPadding * 2;

        if (snapshot.hasData) {
          bool isChecked = selectedPhotoIds.contains(item.photo.id);

          return GestureDetector(
            onTap: () {
              onPhotoSelected(item.photo.id);
            },
            child: Container(
              padding: const EdgeInsets.all(kPhotoPadding),
              width: kPhotoSize,
              height: kPhotoSize,
              child: Stack(
                children: [
                  SizedBox(
                    height: photoImgSize,
                    width: photoImgSize,
                    child: Image.memory(
                      snapshot.data!,
                      fit: BoxFit.cover,
                    ),
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
                        value: isChecked,
                        fillColor: MaterialStateProperty.all(
                          theme.colorScheme.primary,
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        onChanged: (newVal) {
                          onPhotoSelected(item.photo.id);
                        },
                      ),
                    ),
                  )
                ],
              ),
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(kPhotoPadding),
          width: kPhotoSize,
          height: kPhotoSize,
          child: Container(
            color: theme.colorScheme.secondaryContainer,
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
