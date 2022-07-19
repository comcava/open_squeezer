import 'package:photo_manager/photo_manager.dart';

typedef PhotoIdsSet = Set<String>;

// TODO: rename to PhotoAlbumItem
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

class VideoItem {
  final AssetEntity video;
  final int? lengthBytes;

  const VideoItem({
    required this.video,
    required this.lengthBytes,
  });
}
