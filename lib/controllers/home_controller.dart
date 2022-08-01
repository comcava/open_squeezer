import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../services/laplacian_analyzer.dart' as la;
import '../config/constants.dart';
import '../domain/album.dart';

class HomeController {
  final List<PhotoAlbumItem> _photos = List.empty(growable: true);
  List<PhotoAlbumItem> get photos => _photos;

  final List<VideoItem> _videos = List.empty(growable: true);
  List<VideoItem> get videos => _videos;

  bool get noPhotosVideos => _videos.isEmpty && _photos.isEmpty;

  PhotoIdsSet selectedPhotoIds = {};

  String? _processingAlbumName;
  String? get processingAlbumName => _processingAlbumName;

  bool get isLoading => _isLoading;
  bool _isLoading = false;
  bool get noPermissions => _noPermissions;
  bool _noPermissions = false;

  /// Is called when a value was changed (such as isLoading)
  VoidCallback onChanged;

  HomeController({required this.onChanged});

  Future<void> init() async {
    await _checkGalleryPermissions();

    _isLoading = true;
    onChanged();

    await clearCache();

    await Future.wait([_loadAlbums(), _loadVideos()]);
    _isLoading = false;
    onChanged();
  }

  Future<void> clearCache() async {
    await PhotoManager.clearFileCache();
    debugPrint("Cache cleared");
  }

  Future<void> _checkGalleryPermissions() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();

    if (!ps.isAuth) {
      _noPermissions = true;
      debugPrint("Permission denied");
    } else {
      _noPermissions = false;
    }

    onChanged();
  }

  Future<void> _loadVideos() async {
    if (_noPermissions) {
      return;
    }

    if (_noPermissions) {
      return;
    }

    _videos.clear();

    final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
      type: RequestType.video,
      onlyAll: true,
    );

    for (final path in paths) {
      // TODO: fix
      // var totalPages = (path.assetCount / kPhotoPageSize).ceil();
      var totalPages = 1;

      for (var page = 0; page <= totalPages; page++) {
        var videos =
            await path.getAssetListPaged(page: page, size: kPhotoPageSize);

        for (var video in videos) {
          var videoFile = await video.file;
          var lenBytes = await videoFile?.length();

          _videos.add(VideoItem(
            video: video,
            lengthBytes: lenBytes,
          ));
        }
      }
    }

    _videos.sort(
      (v1, v2) => (v2.lengthBytes ?? 0).compareTo(v1.lengthBytes ?? 0),
    );

    _videos.length = min(videos.length, kMaxVideos);
  }

  Future<void> _loadAlbums() async {
    if (_noPermissions) {
      return;
    }

    _photos.clear();

    final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
      type: RequestType.image,
    );

    for (var path in paths) {
      _processingAlbumName = path.name;
      onChanged();

      bool isScreenshots = false;

      if (kScreenshotsFolders.contains(path.name)) {
        isScreenshots = true;
      }

      // TODO: fix
      var totalPages = 1;
      // var totalPages = (path.assetCount / kPhotoPageSize).ceil();

      List<PhotoItem> resPhotos = List.empty(growable: true);

      for (var page = 0; page < totalPages; page++) {
        print(
          "processing ${path.name}, page $page, isScreenshots: $isScreenshots",
        );

        var pageList =
            await path.getAssetListPaged(page: page, size: kPhotoPageSize);

        print("got asset list");

        if (isScreenshots) {
          resPhotos.addAll(
            pageList.map(
              (photo) => PhotoItem(
                photo: photo,
                varianceNum: 0,
              ),
            ),
          );
        } else {
          print("start processing asset blur");

          Map<String, AssetEntity> pageAssets = {};

          for (var photo in pageList) {
            pageAssets.putIfAbsent(photo.id, () => photo);
          }

          var photoVariances = await la.allAssetsBlur(pageAssets.keys);

          for (var photo in photoVariances) {
            // resPhotos.add(PhotoItem(
            //   photo: pageAssets["9"],
            //   varianceNum: 0,
            // ));
          }
          print("  done processing asset blur");
        }
      }

      if (resPhotos.isNotEmpty) {
        _photos.add(
          PhotoAlbumItem(
            album: path,
            photos: resPhotos,
          ),
        );
      }
    }

    _sortPhotos();

    _processingAlbumName = null;
    onChanged();
  }

  _sortPhotos() {
    if (_photos.isEmpty) {
      return;
    }

    var screenshotIdx = _photos.indexWhere(
      (element) => kScreenshotsFolders.contains(element.album.name),
    );

    if (screenshotIdx != -1) {
      var screenshotsFolder = _photos.removeAt(screenshotIdx);
      _photos.add(screenshotsFolder);
    }
  }

  static Future<void> openSettings() async {
    await PhotoManager.openSetting();
  }

  bool photoSelected(String id) {
    return selectedPhotoIds.contains(id);
  }

  toggleSelectedPhoto(String id) {
    final bool contains = photoSelected(id);

    if (contains) {
      selectedPhotoIds.remove(id);
    } else {
      selectedPhotoIds.add(id);
    }

    onChanged();
  }

  /// Delete selected photos and clear the selected photos buffer.
  /// This cannot be undone
  Future<void> deleteSelectedPhotos() async {
    if (selectedPhotoIds.isEmpty) {
      return;
    }

    await PhotoManager.editor.deleteWithIds(
      selectedPhotoIds.toList(),
    );

    selectedPhotoIds.clear();

    _loadAlbums();
  }
}
