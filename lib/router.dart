import 'package:auto_route/auto_route.dart';

import 'views/clear_done.dart';
import 'views/home.dart';

import 'router.gr.dart';

@AutoRouterConfig()
class AppRouter extends $AppRouter {
  @override
  RouteType get defaultRouteType => RouteType.material();

  @override
  List<AutoRoute> get routes => [
        AutoRoute(page: HomePage.page, initial: true),
        AutoRoute(page: ClearDonePage.page),
      ];
}
