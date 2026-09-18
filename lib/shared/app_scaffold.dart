import 'package:flutter/material.dart';
import '../core/widgets/brand_app_bar.dart';
import 'bottom_nav_bar.dart';

class AppScaffold extends StatelessWidget {
  final String? title;
  final Widget body;
  final Widget? floatingActionButton;
  final bool showBottomNav;
  final List<Widget>? actions;
  final Widget? leading;
  const AppScaffold({super.key, this.title, required this.body, this.floatingActionButton, this.showBottomNav = true, this.actions, this.leading});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BrandAppBar(title: title, leading: leading, actions: actions),
      body: body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: showBottomNav ? const BottomNavBar() : null,
    );
  }
}
