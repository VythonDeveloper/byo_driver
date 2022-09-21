import 'package:byo_driver/Dashboard/dashboard.dart';
import 'package:byo_driver/components.dart';
import 'package:byo_driver/constants.dart';
import 'package:byo_driver/tracktrip_ui.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:page_route_transition/page_route_transition.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginUi extends StatefulWidget {
  const LoginUi({Key? key}) : super(key: key);

  @override
  _LoginUiState createState() => _LoginUiState();
}

class _LoginUiState extends State<LoginUi> {
  final mobile = TextEditingController();
  final password = TextEditingController();
  bool isLoading = false;
  final formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  @override
  void initState() {
    super.initState();
    PageRouteTransition.effect = TransitionEffect.fade;
  }

  @override
  void dispose() {
    super.dispose();
    mobile.dispose();
    password.dispose();
  }

  loginAccount() {
    FocusScope.of(context).unfocus();
    setState(() {
      isLoading = true;
    });

    _firestore
        .collection("drivers")
        .where('mobile', isEqualTo: "+91" + mobile.text)
        .where('password', isEqualTo: password.text)
        .get()
        .then((value) async {
      if (value.size > 0) {
        final pref = await _prefs;
        pref.setString("mobile", "+91" + mobile.text);
        pref.setString("password", password.text);
        Constants.driverDetails = value.docs[0].data();

        if (Constants.driverDetails['status'] == "Tripping") {
          _firestore
              .collection("rideRequest")
              .where("driverId", isEqualTo: Constants.driverDetails['id'])
              .where("status", isEqualTo: "Active")
              .get()
              .then((value) {
            if (value.size > 0) {
              PageRouteTransition.pushReplacement(
                context,
                TrackTripUi(
                  rideDetails: value.docs[0].data(),
                ),
              );
            }
          });
        } else {
          PageRouteTransition.pushReplacement(context, const DashboardUi());
        }
      } else {
        setState(() {
          isLoading = false;
        });
        showSnackBar(context, "Invalid Mobile or password");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.dark.copyWith(
        statusBarIconBrightness: Brightness.dark,
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.grey.shade300,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
    return Scaffold(
      // resizeToAvoidBottomInset: false,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: formKey,
              child: Column(
                children: [
                  Center(
                    child: Image.asset(
                      'lib/assets/images/logo.png',
                      height: 40,
                    ),
                  ),
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
                                fontSize: 22)),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.05,
                  ),
                  buildCustomTextField(
                    label: 'Mobile',
                    obsecureText: false,
                    maxLength: 10,
                    textCapitalization: TextCapitalization.none,
                    textEditingController: mobile,
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'This Field is required';
                      }
                      return null;
                    },
                  ),
                  buildCustomTextField(
                    label: 'Password',
                    obsecureText: true,
                    maxLength: 5,
                    textCapitalization: TextCapitalization.none,
                    textEditingController: password,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value!.length != 5) {
                        return 'Password must be 5 digits';
                      } else if (value.isEmpty) {
                        return 'This Field is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  MaterialButton(
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        loginAccount();
                      }
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    color: Colors.black,
                    elevation: 0,
                    highlightElevation: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      width: double.infinity,
                      child: Center(
                        child: isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                'Login',
                                style: TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
