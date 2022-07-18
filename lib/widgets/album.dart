import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:blur_detector/config/constants.dart';
import 'package:photo_manager/photo_manager.dart';

const double kPhotoSize = 100;
const double kPhotoPadding = 2.5;
const double kLowerSize = 20;

// TODO: better names
class AlbumItem {
  final AssetPathEntity album;
  final List<PhotoItem> photos;

  AlbumItem({required this.album, required this.photos});
}

class PhotoItem {
  final AssetEntity photo;
  final double varianceNum;

  const PhotoItem({required this.photo, required this.varianceNum});
}

class Album extends StatelessWidget {
  final AlbumItem albumItem;

  const Album({Key? key, required this.albumItem}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        List<Widget> photoRows = List.empty(growable: true);

        var photosPerRow = (constraints.maxWidth / kPhotoSize).floor();

        for (var idx = 0; idx < albumItem.photos.length; idx += photosPerRow) {
          photoRows.add(Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (pos) {
              if ((pos + idx) < albumItem.photos.length) {
                return buildPhotoItem(albumItem.photos[pos + idx]);
              } else {
                return Container();
              }
            }),
          ));
        }

        return SizedBox(
          height: _AlbumTitle.height +
              photoRows.length * (kPhotoSize + kLowerSize + kPhotoPadding * 2),
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
        // (const ThumbnailSize.square(150));
        return data!;
      }(),
      builder: (context, AsyncSnapshot<Uint8List> snapshot) {
        if (snapshot.hasData) {
          return Container(
            padding: const EdgeInsets.all(kPhotoPadding),
            child: Column(children: [
              SizedBox(
                height: kPhotoSize,
                width: kPhotoSize,
                child: Image.memory(
                  snapshot.data!,
                  fit: BoxFit.cover,
                ),
              ),
              Container(
                height: kLowerSize,
                child: Text("v: ${item.varianceNum}"),
              )
            ]),
          );
        }

        return Container(
          padding: const EdgeInsets.all(kPhotoPadding),
          width: kPhotoSize,
          height: kPhotoSize,
          color: Colors.grey,
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
