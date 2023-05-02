import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:open_squeezer/config/constants.dart';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutButton extends StatefulWidget {
  const AboutButton({super.key});

  @override
  State<AboutButton> createState() => _AboutButtonState();
}

class _AboutButtonState extends State<AboutButton> {
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();

    _init();
  }

  _init() async {
    _packageInfo = await PackageInfo.fromPlatform();

    if (mounted) {
      setState(() {});
    }
  }

  _openPrivacy() async {
    final Uri url = Uri.parse(kPrivacyPolicyUrl);
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint("Error launching url: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    final appIcon = Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
        ),
        clipBehavior: Clip.antiAlias,
        width: 40,
        height: 40,
        child: Image.asset('assets/logo.png'));

    return IconButton(
      onPressed: () {
        showAboutDialog(
            context: context,
            applicationIcon: appIcon,
            applicationName: _packageInfo?.appName,
            applicationVersion: _packageInfo?.version,
            applicationLegalese: loc.appLegalese,
            children: [
              TextButton(
                onPressed: _openPrivacy,
                child: Text(loc.privacyPolicy),
              )
            ]);
      },
      icon: const Icon(Icons.info_outline),
      tooltip: loc.about,
    );
  }
}
