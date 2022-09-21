import 'package:byo_driver/Dashboard/home.dart';
import 'package:byo_driver/Dashboard/settings.dart';
import 'package:byo_driver/Dashboard/trips.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import "package:flutter/material.dart";
import 'package:flutter/services.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

import '../constants.dart';

class DashboardUi extends StatefulWidget {
  const DashboardUi({Key? key}) : super(key: key);

  @override
  State<DashboardUi> createState() => _DashboardUiState();
}

class _DashboardUiState extends State<DashboardUi> {
  double totalIncome = 0.0;
  int _selectedPage = 0;
  List<dynamic> _pages = [HomeUi(), TripsUi(), SettingsUi()];
  String tokenId = '';

  @override
  void initState() {
    super.initState();
    getTokenID();
  }

  getTokenID() async {
    var status = await OneSignal.shared.getDeviceState();
    tokenId = status!.userId!;
    print('My Token ID ---> ' + tokenId);

    FirebaseFirestore.instance
        .collection('drivers')
        .doc(Constants.driverDetails['id'])
        .update({'tokenId': tokenId});

    Constants.driverDetails['tokenId'] = tokenId;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.light.copyWith(
        statusBarBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.dark,
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Book your Own",
          style: TextStyle(
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: _pages[_selectedPage],
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            _selectedPage = index;
          });
        },
        selectedIndex: _selectedPage,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        animationDuration: Duration(milliseconds: 500),
        destinations: <Widget>[
          NavigationDestination(
            selectedIcon: Icon(Icons.home),
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.explore),
            icon: Icon(Icons.explore_outlined),
            label: 'Trips',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.settings),
            icon: Icon(Icons.settings_outlined),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
