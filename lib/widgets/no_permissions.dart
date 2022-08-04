import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:photo_manager/photo_manager.dart';

import '../config/constants.dart';

class NoPermissions extends StatelessWidget {
  const NoPermissions({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    return Center(
      child: Scrollbar(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(kDefaultPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  loc.weNeedGallery,
                  style: theme.textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: kDefaultPadding),
                Text(
                  loc.weNeedGalleryBody,
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: kDefaultPadding),
                ElevatedButton(
                  onPressed: () {
                    PhotoManager.openSetting();
                  },
                  child: Text(loc.grantAccess),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
