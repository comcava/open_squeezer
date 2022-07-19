import 'package:photo_manager/photo_manager.dart';

typedef PhotoIdsSet = Set<String>;

class AlbumItem {
  final AssetPathEntity album;
  final List<PhotoItem> photos;

  AlbumItem({
    required this.album,
    required this.photos,
  });
}

class PhotoItem {
  final AssetEntity photo;
  final double varianceNum;

  const PhotoItem({
    required this.photo,
    required this.varianceNum,
  });
}
