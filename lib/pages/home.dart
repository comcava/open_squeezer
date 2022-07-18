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
    );
  }
}

class ImageList extends StatefulWidget {
  const ImageList({Key? key}) : super(key: key);

  @override
  State<ImageList> createState() => _ImageListState();
}

// TODO: from settings
const double blurryBefore = 100;

class _ImageListState extends State<ImageList> {
  final List<AlbumItem> _blurryPhotos = List.empty(growable: true);

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

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

    print("got paths: $paths");

    // TODO: page size to constant
    final pageSize = 50;

    _isLoading = true;
    if (mounted) {
      setState(() {
        _isLoading;
      });
    }

    // TODO: check all paths
    for (var path in paths.take(1)) {
      var totalPages = (path.assetCount / pageSize).ceil();

      List<PhotoItem> photos = List.empty(growable: true);

      var page = 0;
      // for (var page = 0; page <= totalPages; page++) {
      var pageList = await path.getAssetListPaged(page: page, size: pageSize);
      print("got page list: $pageList");

      for (var listItem in pageList) {
        var blurNum = await LaplacianBlurAnalyzer.assetBlur(listItem);
        if (blurNum == null) {
          debugPrint("Blur item is null for ${listItem.title}");
          continue;
        }

        if (blurNum <= blurryBefore) {
          photos.add(PhotoItem(photo: listItem, varianceNum: 40));
        }
      }
      // }

      _blurryPhotos.add(
        AlbumItem(album: path, photos: photos),
      );
    }

    _isLoading = true;
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
          ),
        ),
      ],
    );
  }
}
