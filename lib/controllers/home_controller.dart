import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../config/constants.dart';
import '../domain/album.dart';
import '../services/blur_analyzer.dart';

class HomeController {
  final List<AlbumItem> _photos = List.empty(growable: true);
  List<AlbumItem> get photos => _photos;

  PhotoIdsSet selectedPhotoIds = {};

  bool get isLoading => _isLoading;

  bool _isLoading = true;

  /// Is called when a value was changed (such as isLoading)
  VoidCallback onChanged;

  HomeController({required this.onChanged});

  init() {
    _loadAlbums();
  }

  _loadAlbums() async {
    final PermissionState _ps = await PhotoManager.requestPermissionExtend();

    if (_ps.isAuth) {
      // Granted.
    } else {
      print("Permission denied");
      // TODO: show permission denied screen

      // Limited(iOS) or Rejected, use `==` for more precise judgements.
      // You can call `PhotoManager.openSetting()`    to open settings for further steps.
      PhotoManager.openSetting();
      return;
    }

    final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList();

    // TODO: page size to constant
    final pageSize = 50;

    _isLoading = true;
    onChanged();

    for (var path in paths) {
      if (path.isAll) {
        continue;
      }

      var totalPages = (path.assetCount / pageSize).ceil();

      List<PhotoItem> allPhotos = List.empty(growable: true);

      for (var page = 0; page <= totalPages; page++) {
        var pageList = await path.getAssetListPaged(page: page, size: pageSize);
        // TODO: add 'processing {album name}'

        print("got page list: $pageList");
        var photos = await LaplacianBlurAnalyzer().assetBlur4Threads(pageList);
        allPhotos.addAll(photos);
      }

      if (allPhotos.isNotEmpty) {
        _photos.add(
          AlbumItem(
            album: path,
            photos: allPhotos,
          ),
        );
      }
    }

    _isLoading = false;
    onChanged();

    // TODO: after done, clear cache
    // PhotoManager.clearFileCache();
  }

  bool photoSelected(String id) {
    return selectedPhotoIds.contains(id);
  }

  toggleSelectedPhoto(String id) {
    print("toggle selected: $id");

    final bool contains = photoSelected(id);

    if (contains) {
      selectedPhotoIds.remove(id);
    } else {
      selectedPhotoIds.add(id);
    }

    onChanged();
  }
}
