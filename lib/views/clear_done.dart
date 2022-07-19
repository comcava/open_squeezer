import 'package:blur_detector/config/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ClearDonePage extends StatelessWidget {
  const ClearDonePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(kDefaultPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check,
                  size: kLargeIconSize,
                ),
                const SizedBox(height: kDefaultPadding),
                Text(
                  loc.allClean,
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: kDefaultPadding * 4),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.refresh),
                  label: Text(loc.cleanAgain),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
