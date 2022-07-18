import 'package:after_layout/after_layout.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:photo_manager/photo_manager.dart';

import '../services/blur_analyzer.dart';
import '../widgets/album.dart';
import '../config/constants.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(loc.appName)),
      body: const Padding(
        padding: EdgeInsets.all(kScaffoldPadding),
        child: ImageList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.cleaning_services_outlined),
      ),
    );
  }
}

class ImageList extends StatefulWidget {
  const ImageList({Key? key}) : super(key: key);

  @override
  State<ImageList> createState() => _ImageListState();
}

class _ImageListState extends State<ImageList>
    with AfterLayoutMixin<ImageList> {
  List<AlbumItem> _blurryPhotos = List.empty(growable: true);

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  void afterFirstLayout(context) {
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
    if (mounted) {
      setState(() {
        _isLoading;
      });
    }

    // TODO: check all paths
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
        _blurryPhotos.add(
          AlbumItem(
            album: path,
            photos: allPhotos,
          ),
        );
      }
    }

    _isLoading = false;
    if (mounted) {
      setState(() {
        _isLoading;
      });
    }

    // TODO: after done, clear cache
    // PhotoManager.clearFileCache();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return ListView(
      children: [
        ..._blurryPhotos.map(
          (p) => Album(
              albumItem: p,
              onPhotoSelected: (photo) {
                var contains = p.selectedPhotoIds.contains(photo.photo.id);

                var selected = _blurryPhotos
                    .firstWhere((element) => element.album.id == p.album.id);

                if (contains) {
                  selected.selectedPhotoIds.remove(photo.photo.id);
                } else {
                  selected.selectedPhotoIds.add(photo.photo.id);
                }
              }),
        ),
      ],
    );
  }
}
