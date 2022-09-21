import 'package:byo_driver/constants.dart';
import 'package:byo_driver/Dashboard/dashboard.dart';
import 'package:byo_driver/login.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:page_route_transition/page_route_transition.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashUi extends StatefulWidget {
  const SplashUi({Key? key}) : super(key: key);

  @override
  State<SplashUi> createState() => _SplashUiState();
}

class _SplashUiState extends State<SplashUi> {
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  @override
  void initState() {
    super.initState();
    PageRouteTransition.effect = TransitionEffect.fade;
    _getExistingUserVerified();
  }

  _getExistingUserVerified() async {
    final SharedPreferences prefs = await _prefs;
    String mobile = (prefs.getString('mobile') ?? '0');
    String password = (prefs.getString('password') ?? "0");
    _firestore
        .collection("drivers")
        .where('mobile', isEqualTo: mobile)
        .where('password', isEqualTo: password)
        .get()
        .then((value) {
      if (value.size > 0) {
        Constants.driverDetails = value.docs[0].data();
        PageRouteTransition.pushReplacement(context, const DashboardUi());
      } else {
        PageRouteTransition.pushReplacement(context, const LoginUi());
      }
    });
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RichText(
              text: const TextSpan(
                text: 'Book your Own\n',
                style: TextStyle(
                    fontSize: 30, color: Color.fromARGB(255, 7, 36, 30)),
                children: <TextSpan>[
                  TextSpan(
                      text: 'for Driver',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontStyle: FontStyle.italic,
                          fontSize: 15)),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20, horizontal: 150),
              child: LinearProgressIndicator(
                color: Colors.black,
                backgroundColor: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
