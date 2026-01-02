import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'persistent_sidebar.dart';
import 'sucursal_selector.dart';
import '../services/navigation_service.dart';

class MainScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? drawer;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final Future<void> Function()? onRefresh;
  final String currentRoute;

  const MainScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.drawer,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.onRefresh,
    this.currentRoute = '/',
  });

  @override
  Widget build(BuildContext context) {
    Widget bodyWidget = body;
    
    if (onRefresh != null) {
      bodyWidget = RefreshIndicator(
        onRefresh: onRefresh!,
        child: body,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: NavigationHelper.buildBackButton(context),
        actions: [
          ...?actions,
          const SucursalSelector(),
        ],
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          NavigationHelper.buildBreadcrumbs(context),
          Expanded(
            child: PersistentSidebar(
              currentRoute: currentRoute,
              child: bodyWidget,
            ),
          ),
        ],
      ),
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
    );
  }
}
