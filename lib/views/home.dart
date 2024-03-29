import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_fgbg/flutter_fgbg.dart';

import 'package:auto_route/auto_route.dart';
import 'package:isolate_handler/isolate_handler.dart' as ih;
import 'package:photo_manager/photo_manager.dart' as pm;

import '../services/laplacian_analyzer.dart';

import '../widgets/album.dart';
import '../widgets/no_permissions.dart';
import '../widgets/button_about.dart';

import '../config/constants.dart';
import '../controllers/home_controller.dart';

import '../router.gr.dart';

part 'home_laplacian_isolate.dart';

@RoutePage()
class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late HomeController _controller;
  late StreamSubscription<FGBGType> _bgSubscription;

  @override
  void initState() {
    super.initState();

    _controller = HomeController(onChanged: () {
      if (mounted) {
        setState(() {});
      }
    });

    _controller.init();

    _bgSubscription = FGBGEvents.stream.listen((FGBGType event) {
      if (event == FGBGType.foreground) {
        if (_controller.noPermissions) {
          _controller.init();
        }

        _controller.clearCache();
      }
    });
  }

  @override
  void dispose() {
    _bgSubscription.cancel();

    super.dispose();
  }

  _confirmDelete() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        if (_controller.selectedPhotoIds.isEmpty) {
          return const AlertNoPhotosSelected();
        }

        return AlertDeletePhotos(
          onYes: () async {
            await _controller.deleteSelectedPhotos();
            await _controller.clearCache();

            if (mounted) {
              AutoRouter.of(context).replaceAll([const ClearDoneRoute()]);
            }
          },
          onNo: () async {
            AutoRouter.of(context).pop();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    Widget? actionButton;

    if (!_controller.isLoading &&
        !_controller.noPermissions &&
        !_controller.noPhotosVideos) {
      actionButton = FloatingActionButton(
        onPressed: () {
          _confirmDelete();
        },
        child: const Icon(Icons.cleaning_services_outlined),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.appName),
        actions: const [AboutButton()],
      ),
      body: Padding(
        padding: const EdgeInsets.all(kScaffoldPadding),
        child: _HomePageBody(controller: _controller),
      ),
      floatingActionButton: actionButton,
    );
  }
}

class _HomePageBody extends StatelessWidget {
  final HomeController controller;

  const _HomePageBody({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    if (controller.noPermissions) {
      return const NoPermissions();
    }

    if (controller.isLoading) {
      return _buildLoading(loc);
    }

    if (controller.noPhotosVideos) {
      return _buildEmpty(loc);
    }

    return ListView(
      children: [
        Album(
            name: loc.videos,
            itemsLength: controller.videos.length,
            builder: (index) {
              var video = controller.videos[index];
              return VideoThumbnail(
                isChecked: controller.photoSelected(video.video.id),
                onSelected: (id) {
                  controller.toggleSelectedPhoto(id);
                },
                item: video,
              );
            }),
        ...controller.photos.map(
          (p) => Album(
              name: p.album.name,
              itemsLength: p.photos.length,
              builder: (index) {
                var photo = p.photos[index];

                return PhotoThumbnail(
                  isChecked: controller.photoSelected(photo.photo.id),
                  onPhotoSelected: (id) {
                    controller.toggleSelectedPhoto(id);
                  },
                  item: photo,
                );
              }),
        ),
      ],
    );
  }

  Widget _buildLoading(AppLocalizations loc) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(kDefaultPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            if (controller.processingAlbumName != null) ...[
              const SizedBox(height: kDefaultPadding),
              Text(loc.processingAlbum(controller.processingAlbumName!)),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(AppLocalizations loc) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(kDefaultPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              Icons.camera_roll_rounded,
              size: kLargeIconSize,
            ),
            const SizedBox(height: kDefaultPadding),
            Text(loc.noPhotos),
          ],
        ),
      ),
    );
  }
}

class AlertNoPhotosSelected extends StatelessWidget {
  const AlertNoPhotosSelected({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(loc.noPhotosSelected),
      content: Text(loc.goSelectPhotos),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(loc.ok),
        )
      ],
    );
  }
}

class AlertDeletePhotos extends StatefulWidget {
  final VoidCallback onYes;
  final VoidCallback onNo;

  const AlertDeletePhotos({
    Key? key,
    required this.onYes,
    required this.onNo,
  }) : super(key: key);

  @override
  State<AlertDeletePhotos> createState() => _AlertDeletePhotosState();
}

class _AlertDeletePhotosState extends State<AlertDeletePhotos> {
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    Widget content;
    List<Widget> actions = [];

    if (isLoading) {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Padding(
            padding: EdgeInsets.all(kDefaultPadding),
            child: CircularProgressIndicator(),
          ),
        ],
      );
    } else {
      content = Text(loc.alertDeletePhotosBody);
      actions = [
        TextButton(
          child: Text(
            loc.no,
            style: theme.textTheme.bodyMedium,
          ),
          onPressed: () async {
            widget.onNo();
          },
        ),
        TextButton(
          child: Text(
            loc.yes,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.red,
            ),
          ),
          onPressed: () {
            widget.onYes();
            setState(() {
              isLoading = true;
            });
          },
        ),
      ];
    }

    return AlertDialog(
      title: Text(loc.alertDeletePhotosTitle),
      content: content,
      actions: actions,
    );
  }
}
