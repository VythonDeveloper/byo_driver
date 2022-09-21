import 'package:byo_driver/constants.dart';
import 'package:byo_driver/login.dart';
import 'package:byo_driver/webView_ui.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:page_route_transition/page_route_transition.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsUi extends StatefulWidget {
  const SettingsUi({Key? key}) : super(key: key);

  @override
  State<SettingsUi> createState() => _SettingsUiState();
}

class _SettingsUiState extends State<SettingsUi> {
  String vehicleImage = '';
  bool availabilityToggler = false;
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  @override
  void initState() {
    super.initState();

    if (Constants.driverDetails['vehicleType'] == "Rickshaw") {
      vehicleImage = "./lib/assets/images/rickshaw.png";
    } else if (Constants.driverDetails['vehicleType'] == "Tractor") {
      vehicleImage = "./lib/assets/images/tractor.png";
    } else if (Constants.driverDetails['vehicleType'] == "Mini Truck") {
      vehicleImage = "./lib/assets/images/mini-truck.png";
    } else if (Constants.driverDetails['vehicleType'] == "Delivery Truck") {
      vehicleImage = "./lib/assets/images/delivery-truck.png";
    } else if (Constants.driverDetails['vehicleType'] == "Truck") {
      vehicleImage = "./lib/assets/images/truck.png";
    }

    availabilityToggler =
        Constants.driverDetails['bookingStatus'] == "Available" ? true : false;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 15,
          ),
          Center(
            child: CircleAvatar(
              backgroundColor: Color.fromARGB(255, 155, 117, 161),
              radius: 40,
              backgroundImage: AssetImage('./lib/assets/images/driver.png'),
            ),
          ),
          SizedBox(
            height: 10,
          ),
          Center(
            child: Text(
              Constants.driverDetails['fullname'],
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(
            height: 10,
          ),
          Center(
            child: Text(
              'License Number',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
                // letterSpacing: 1.0,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          Center(
            child: Text(
              Constants.driverDetails['licenseNumber'],
              style: TextStyle(
                fontSize: 20,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.0,
              ),
            ),
          ),
          SizedBox(
            height: 15,
          ),
          Stack(
            children: <Widget>[
              Container(
                width: double.infinity,
                margin: EdgeInsets.fromLTRB(20, 20, 20, 10),
                padding: EdgeInsets.only(top: 20, bottom: 10),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey.shade300,
                  ),
                  borderRadius: BorderRadius.circular(5),
                  shape: BoxShape.rectangle,
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Image.asset(
                        vehicleImage,
                        height: 70,
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Type: " + Constants.driverDetails['vehicleType'],
                          ),
                          Text(
                            "Name: " + Constants.driverDetails['vehicleName'],
                          ),
                          Text(
                            "Number: " +
                                Constants.driverDetails['vehicleNumber'],
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 35,
                top: 10,
                child: Container(
                  padding: EdgeInsets.only(
                    left: 5,
                    right: 5,
                  ),
                  color: Colors.white,
                  child: Text(
                    'Vehicle Details',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(
            height: 20,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Availability Status",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Turn on to let the customers schedule for further dates",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                      )
                    ],
                  ),
                ),
                Transform.scale(
                  scale: 1.1,
                  child: Switch(
                    onChanged: (value) {
                      setState(() {
                        availabilityToggler = value;
                        if (availabilityToggler) {
                          Constants.driverDetails['bookingStatus'] =
                              "Available";
                        } else {
                          Constants.driverDetails['bookingStatus'] = "Busy";
                        }
                        FirebaseFirestore.instance
                            .collection("drivers")
                            .doc(Constants.driverDetails['id'])
                            .update({
                          'bookingStatus':
                              Constants.driverDetails['bookingStatus']
                        });
                      });
                    },
                    value: availabilityToggler,
                    activeColor: Colors.blue.shade800,
                    activeTrackColor: Colors.blue.shade100,
                    inactiveThumbColor: Colors.redAccent,
                    inactiveTrackColor: Colors.red.shade100,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 20,
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 20),
            child: Row(
              children: [
                Text(
                  'Total Rating',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(
                  width: 20,
                ),
                FutureBuilder<dynamic>(
                  future: FirebaseFirestore.instance
                      .collection('rideRequest')
                      .where('driverId',
                          isEqualTo: Constants.driverDetails['id'])
                      .where('ratings', isNotEqualTo: 0)
                      .get(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      var avgRate = 0.0;
                      if (snapshot.data.docs.length > 0) {
                        for (int i = 0; i < snapshot.data.docs.length; i++) {
                          avgRate += snapshot.data.docs[i]['rating'];
                        }
                        avgRate = avgRate / snapshot.data.docs.length;
                        return Text(
                          avgRate.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        );
                      }
                      return Text(
                        avgRate.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      );
                    }
                    return Center(
                      child: Transform.scale(
                        scale: 0.5,
                        child: CircularProgressIndicator(
                          color: Colors.black,
                          strokeWidth: 6,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          SizedBox(
            height: 20,
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Readable Docs",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          ListTile(
            onTap: () {
              PageRouteTransition.push(
                context,
                WebViewUI(url: "https://aryagold.co.in/terms-conditions"),
              );
            },
            leading: Icon(Icons.privacy_tip),
            title: Text("Terms and Conditions"),
            subtitle: Text("Click to read terms and conditions"),
            trailing: Icon(Icons.open_in_browser),
          ),
          ListTile(
            onTap: () {
              PageRouteTransition.push(
                context,
                WebViewUI(url: "https://aryagold.co.in/privacy-policy"),
              );
            },
            leading: Icon(Icons.privacy_tip),
            title: Text("Privacy Policy"),
            subtitle: Text("Click to read privacy and policy"),
            trailing: Icon(Icons.open_in_browser),
          ),
          SizedBox(
            height: 30,
          ),
          MaterialButton(
            onPressed: () async {
              final pref = await _prefs;
              Constants.driverDetails = {};
              pref.setString("mobile", "");
              pref.setString("password", "");
              Navigator.popUntil(context, (route) => false);
              PageRouteTransition.push(context, const LoginUi());
            },
            elevation: 0,
            color: Colors.red[900],
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
              child: const Center(
                child: Text(
                  'Logout',
                  style: TextStyle(
                    fontSize: 17,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
