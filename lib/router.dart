import 'package:auto_route/auto_route.dart';

import 'views/clear_done.dart';
import 'views/home.dart';

@MaterialAutoRouter(
  replaceInRouteName: 'Page,Route',
  routes: <AutoRoute>[
    AutoRoute(page: HomePage, initial: true),
    AutoRoute(page: ClearDonePage),
  ],
)
class $AppRouter {}
