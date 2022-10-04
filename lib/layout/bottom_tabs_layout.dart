import 'package:flutter/material.dart';
import "package:persistent_bottom_nav_bar/persistent_tab_view.dart";
import 'package:qrcode_keeper/pages/qrcode_add_page.dart';
import 'package:qrcode_keeper/pages/qrcode_display_page.dart';
import 'package:qrcode_keeper/pages/qrcode_lookup_page.dart';

class BottomTabsLayout extends StatefulWidget {
  const BottomTabsLayout({super.key});

  @override
  State<BottomTabsLayout> createState() => _BottomTabsLayoutState();
}

class _BottomTabsLayoutState extends State<BottomTabsLayout> {
  final PersistentTabController _controller = PersistentTabController(
    initialIndex: 1,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PersistentTabView(
      context,
      controller: _controller,
      screens: _buildScreens(),
      items: _navBarsItems(),
      confineInSafeArea: true,
      backgroundColor: Colors.white,
      handleAndroidBackButtonPress: true,
      resizeToAvoidBottomInset:
          true, // This needs to be true if you want to move up the screen when keyboard appears. Default is true.
      stateManagement: true,
      hideNavigationBarWhenKeyboardShows:
          true, // Recommended to set 'resizeToAvoidBottomInset' as true while using this argument. Default is true.
      decoration: NavBarDecoration(
        borderRadius: BorderRadius.circular(10.0),
        colorBehindNavBar: Colors.white,
      ),
      popAllScreensOnTapOfSelectedTab: true,
      popActionScreens: PopActionScreensType.all,
      itemAnimationProperties: const ItemAnimationProperties(
        duration: Duration(milliseconds: 200),
        curve: Curves.ease,
      ),
      screenTransitionAnimation: const ScreenTransitionAnimation(
        animateTabTransition: true,
        curve: Curves.ease,
        duration: Duration(milliseconds: 200),
      ),
      navBarStyle: NavBarStyle.style1,
    );
  }

  List<Widget> _buildScreens() {
    return [
      QRLookupPage(tabBarController: _controller),
      QRCodeDisplayPage(tabBarController: _controller),
      QRCodeAddPage(tabBarController: _controller),
    ];
  }

  List<PersistentBottomNavBarItem> _navBarsItems() {
    return [
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.search),
        title: "Lookup",
        activeColorPrimary: Colors.teal,
        inactiveColorPrimary: Colors.grey,
        routeAndNavigatorSettings: RouteAndNavigatorSettings(
          routes: {
            '/': (context) => QRLookupPage(tabBarController: _controller),
            '/qr-display': (context) =>
                QRCodeDisplayPage(tabBarController: _controller),
          },
        ),
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.qr_code_2_outlined),
        title: "Display",
        activeColorPrimary: Colors.green.shade600,
        inactiveColorPrimary: Colors.grey,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.add),
        title: "Add",
        activeColorPrimary: Colors.blueAccent,
        inactiveColorPrimary: Colors.grey,
      ),
    ];
  }
}
