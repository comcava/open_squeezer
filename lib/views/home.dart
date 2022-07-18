import 'package:blur_detector/controllers/home_controller.dart';
import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:photo_manager/photo_manager.dart';

import '../domain/album.dart';
import '../services/blur_analyzer.dart';
import '../widgets/album.dart';
import '../config/constants.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late HomeController _controller;

  @override
  void initState() {
    super.initState();

    _controller = HomeController(onChanged: () {
      if (mounted) {
        setState(() {});
      }
    });

    _controller.init();
  }

  _confirmDelete() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDeletePhotos(
          onYes: () async {
            await _controller.deleteSelectedPhotos();

            if (mounted) {
              Navigator.of(context).pop();
            }
          },
          onNo: () async {
            Navigator.of(context).pop();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    Widget? actionButton;

    if (!_controller.isLoading) {
      actionButton = FloatingActionButton(
        onPressed: () {
          _confirmDelete();
        },
        child: const Icon(Icons.cleaning_services_outlined),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(loc.appName)),
      body: Padding(
        padding: const EdgeInsets.all(kScaffoldPadding),
        child: _HomePageBody(controller: _controller),
      ),
      floatingActionButton: actionButton,
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

class _HomePageBody extends StatelessWidget {
  final HomeController controller;

  const _HomePageBody({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (controller.isLoading) {
      return _buildLoading();
    }

    return ListView(
      children: [
        ...controller.photos.map(
          (p) => Album(albumItem: p, controller: controller),
        ),
      ],
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}
