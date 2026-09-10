import 'package:flutter/material.dart';

class AppResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final Widget? drawer;

  const AppResponsiveContainer({
    required this.child,
    super.key,
    this.maxWidth = 600.0,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.drawer,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > maxWidth;

    if (!isWideScreen) {
      // Mobile screen: display full width (fluid)
      return Scaffold(
        appBar: appBar,
        drawer: drawer,
        body: child,
        bottomNavigationBar: bottomNavigationBar,
        floatingActionButton: floatingActionButton,
      );
    }

    // Wide screen (Tablet, Web, Foldable): center the content with a max-width and outer background
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: Center(
        child: Container(
          width: maxWidth,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(13),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
            border: const Border(
              left: BorderSide(color: Color(0xFFE4E9F2)),
              right: BorderSide(color: Color(0xFFE4E9F2)),
            ),
          ),
          child: Scaffold(
            appBar: appBar,
            drawer: drawer,
            body: child,
            bottomNavigationBar: bottomNavigationBar,
            floatingActionButton: floatingActionButton,
          ),
        ),
      ),
    );
  }
}
