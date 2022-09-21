import 'package:byo_driver/Booking_History/booking_history.dart';
import 'package:byo_driver/components.dart';
import 'package:byo_driver/constants.dart';
import 'package:byo_driver/login.dart';
import 'package:byo_driver/tracktrip_ui.dart';
import 'package:byo_driver/webView_ui.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:page_route_transition/page_route_transition.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slide_to_confirm/slide_to_confirm.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class DashboardUi extends StatefulWidget {
  const DashboardUi({Key? key}) : super(key: key);

  @override
  State<DashboardUi> createState() => _DashboardUiState();
}

class _DashboardUiState extends State<DashboardUi> with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final startOTP = TextEditingController();
  String errorMsg = '';
  String vehicleImage = '';
  bool engagedAlert = false;
  double totalIncome = 0.0;
  bool availabilityToggler = false;
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  final dateFormat = new DateFormat('MMMM d, yyyy HH:mm');

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
  void dispose() {
    super.dispose();
    startOTP.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.light.copyWith(
        statusBarBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.dark,
        statusBarColor: Constants.driverDetails['bookingStatus'] == 'Available'
            ? Colors.green.shade100
            : Colors.red.shade100,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
    return Scaffold(
      key: _scaffoldKey,
      body: RefreshIndicator(
        onRefresh: () {
          return Future(() {
            setState(() {});
          });
        },
        child: SafeArea(
          child: Stack(
            children: [
              Container(
                height: 150,
                width: double.infinity,
                color: Constants.driverDetails['bookingStatus'] == 'Available'
                    ? Colors.green.shade100
                    : Colors.red.shade100,
              ),
              SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            children: [
                              Image.asset(
                                vehicleImage,
                                height: 60,
                              ),
                              Text(
                                Constants.driverDetails['vehicleType'],
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                Constants.driverDetails['vehicleName'],
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                Constants.driverDetails['vehicleNumber'],
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              GestureDetector(
                                onTap: () =>
                                    _scaffoldKey.currentState?.openDrawer(),
                                child: Image.asset(
                                  './lib/assets/images/menu.png',
                                  height: 30,
                                ),
                              ),
                              const SizedBox(
                                height: 15,
                              ),
                              const Text(
                                'Driver',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                Constants.driverDetails['fullname'],
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 50,
                      ),
                      Row(
                        children: [
                          FutureBuilder<dynamic>(
                            future: FirebaseFirestore.instance
                                .collection("rideRequest")
                                .where("driverId",
                                    isEqualTo: Constants.driverDetails['id'])
                                .get(),
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                return Expanded(
                                  child: statsCard(
                                      label: 'Total Trips',
                                      content:
                                          snapshot.data.docs.length.toString()),
                                );
                              }
                              return Center(
                                child: CircularProgressIndicator(),
                              );
                            },
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          FutureBuilder<dynamic>(
                            future: FirebaseFirestore.instance
                                .collection("rideRequest")
                                .where("driverId",
                                    isEqualTo: Constants.driverDetails['id'])
                                .get(),
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                totalIncome = 0.0;
                                for (int i = 0;
                                    i < snapshot.data.docs.length;
                                    i++) {
                                  totalIncome += snapshot.data.docs[i]['cost'];
                                }
                                return Expanded(
                                  child: statsCard(
                                      label: 'Total Income',
                                      content: "₹ " +
                                          totalIncome.toStringAsFixed(2)),
                                );
                              }
                              return Center(
                                child: CircularProgressIndicator(),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      Row(
                        children: [
                          Expanded(
                            flex: 4,
                            child: Column(
                              children: [
                                Text(
                                  "Availability Status",
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                    "Turn on to let the customer's schedule for further dates")
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Transform.scale(
                              scale: 1.5,
                              child: Switch(
                                onChanged: (value) {
                                  setState(() {
                                    availabilityToggler = value;
                                    if (availabilityToggler) {
                                      Constants.driverDetails['bookingStatus'] =
                                          "Available";
                                    } else {
                                      Constants.driverDetails['bookingStatus'] =
                                          "Busy";
                                    }
                                    FirebaseFirestore.instance
                                        .collection("drivers")
                                        .doc(Constants.driverDetails['id'])
                                        .update({
                                      'bookingStatus': Constants
                                          .driverDetails['bookingStatus']
                                    });
                                  });
                                },
                                value: availabilityToggler,
                                activeColor: Colors.blue,
                                activeTrackColor: Colors.yellow,
                                inactiveThumbColor: Colors.redAccent,
                                inactiveTrackColor: Colors.orange,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 30,
                      ),
                      Text(
                        "Current Ongoing Trip",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(
                        height: 15,
                      ),
                      FutureBuilder<dynamic>(
                        future: FirebaseFirestore.instance
                            .collection('rideRequest')
                            .where('driverId',
                                isEqualTo: Constants.driverDetails['id'])
                            .where('status',
                                whereIn: ['Pending', 'Active']).get(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            var rideData;
                            snapshot.data.docs.forEach((element) {
                              if (element['status'] == "Active") {
                                rideData = element;
                              }
                              if (element['tripStartTime'] <=
                                      DateTime.now().millisecondsSinceEpoch &&
                                  element['tripEndTime'] >
                                      DateTime.now().millisecondsSinceEpoch) {
                                rideData = element;
                              }
                            });

                            if (rideData != null) {
                              return tripCard(rideData);
                            }

                            return Column(
                              children: [
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  child: Center(
                                    child: Image.asset(
                                      './lib/assets/images/clock.png',
                                      height: 150,
                                    ),
                                  ),
                                ),
                                Text(
                                  "No Trips for now. Take rest and wait for upcoming trips. We'll notify you!",
                                  style: TextStyle(
                                      color: Color.fromARGB(255, 87, 22, 131),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500),
                                  textAlign: TextAlign.center,
                                )
                              ],
                            );
                          }
                          return Center(
                            child: CircularProgressIndicator(),
                          );
                        },
                      ),
                      SizedBox(
                        height: 30,
                      ),
                      Row(
                        children: [
                          Expanded(
                            flex: 4,
                            child: Text(
                              "Upcoming Scheduled Trips",
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.black),
                              ),
                              onPressed: () {
                                PageRouteTransition.push(
                                    context, ScheduledTrips());
                              },
                              child: Text("See all"),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      StreamBuilder<dynamic>(
                        stream: FirebaseFirestore.instance
                            .collection('rideRequest')
                            .where('driverId',
                                isEqualTo: Constants.driverDetails['id'])
                            .where('status', whereIn: ['Active', 'Pending'])
                            .orderBy('tripStartTime', descending: false)
                            .limit(3)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return ListView.builder(
                              itemCount: snapshot.data.docs.length,
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemBuilder: (context, index) {
                                DocumentSnapshot ds = snapshot.data.docs[index];
                                return historyCard(ds);
                              },
                            );
                          } else {
                            return const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text("No booking..."),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                child: Column(
                  children: [
                    Center(
                      child: Image.asset(
                        './lib/assets/images/icon.png',
                        height: 150,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 15,
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(
                              "Profile",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            child: Text(
                              Constants.driverDetails['fullname'],
                              style: TextStyle(fontSize: 18),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            child: Text(
                              Constants.driverDetails['mobile'],
                              style: TextStyle(fontSize: 15),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          "Terms and Privacy",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ),
                      ListTile(
                        onTap: () {
                          PageRouteTransition.effect = TransitionEffect.fade;
                          PageRouteTransition.push(
                            context,
                            WebViewUI(
                                url: "https://aryagold.co.in/terms-conditions"),
                          );
                        },
                        leading: Icon(Icons.gavel),
                        title: Text("Terms & Conditions"),
                        subtitle: Text(
                          "Read terms & conditions",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Icon(Icons.arrow_forward_ios_rounded),
                        // tileColor: Colors.blueGrey[100],
                        iconColor: Colors.blueGrey[800],
                      ),
                      ListTile(
                        onTap: () {
                          PageRouteTransition.effect = TransitionEffect.fade;
                          PageRouteTransition.push(
                            context,
                            WebViewUI(
                                url: "https://aryagold.co.in/privacy-policy"),
                          );
                        },
                        leading: Icon(Icons.privacy_tip),
                        title: Text("Privacy Policy"),
                        subtitle: Text(
                          "Read privacy policy",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Icon(Icons.arrow_forward_ios_rounded),
                        // tileColor: Colors.blueGrey[100],
                        iconColor: Colors.blueGrey[800],
                      ),
                      ListTile(
                        onTap: () {
                          PageRouteTransition.effect = TransitionEffect.fade;
                          PageRouteTransition.push(
                            context,
                            WebViewUI(
                                url: "https://aryagold.co.in/refund-policy"),
                          );
                        },
                        leading: Icon(Icons.privacy_tip),
                        title: Text("Return, Refund, & Cancellation Policy"),
                        subtitle: Text(
                          "Read Return, Refund, & Cancellation Policy",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Icon(Icons.arrow_forward_ios_rounded),
                        // tileColor: Colors.blueGrey[100],
                        iconColor: Colors.blueGrey[800],
                      ),
                      const SizedBox(height: 20),
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
                          padding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 10),
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
                      const SizedBox(
                        height: 10,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget historyCard(var tripDetails) {
    return GestureDetector(
      onTap: () {
        if (tripDetails['status'] == "Active") {
          PageRouteTransition.push(
              context, TrackTripUi(rideDetails: tripDetails));
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(10),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: Colors.grey,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                "Trk. Id " + tripDetails['id'],
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(
              height: 10,
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade700,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SvgPicture.asset(
                              'lib/assets/icons/homeMarker.svg',
                              color: Colors.white,
                              height: 15,
                            ),
                            const SizedBox(
                              width: 8,
                            ),
                            Text(
                              'Source',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 15,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Text(
                        tripDetails['pickAddress'],
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.red.shade700,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SvgPicture.asset(
                              'lib/assets/icons/destination.svg',
                              color: Colors.white,
                              height: 15,
                            ),
                            const SizedBox(
                              width: 8,
                            ),
                            const Text(
                              'Destination',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 15,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Text(
                        tripDetails['dropAddress'],
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 10,
            ),
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        'Status: ',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Constants.statusColor[tripDetails['status']],
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Text(
                          tripDetails['status'],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Scheduled on",
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(dateFormat.format(
                          DateTime.fromMillisecondsSinceEpoch(
                              tripDetails['tripStartTime']))),
                    ],
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget statsCard({final label, content}) {
    return Card(
      elevation: 0,
      color: Colors.grey.shade300,
      // shadowColor: Colors.grey.shade400,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            Text(
              content,
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget tripCard(final ds) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade700,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SvgPicture.asset(
                                'lib/assets/icons/homeMarker.svg',
                                color: Colors.white,
                                height: 15,
                              ),
                              const SizedBox(
                                width: 8,
                              ),
                              Text(
                                'Source',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 15,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Text(
                          ds['pickAddress'],
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.red.shade700,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SvgPicture.asset(
                                'lib/assets/icons/destination.svg',
                                color: Colors.white,
                                height: 15,
                              ),
                              const SizedBox(
                                width: 8,
                              ),
                              const Text(
                                'Destination',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 15,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Text(
                          ds['dropAddress'],
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 15,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(11),
                            bottomLeft: Radius.circular(11),
                          ),
                          color: Colors.blue.shade200,
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.map,
                              color: Colors.blue.shade900,
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                            Text(
                              ds['distance'],
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: Colors.blue.shade900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(0),
                          color: Colors.amber.shade200,
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.watch_later_outlined,
                              color: Colors.amber.shade900,
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                            Text(
                              ds['transitTime'],
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: Colors.amber.shade900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(11),
                            bottomRight: Radius.circular(11),
                          ),
                          color: Colors.green.shade200,
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.attach_money_rounded,
                              color: Colors.green.shade900,
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                            Text(
                              '₹ ' + Constants.cF.format(ds['cost']),
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: Colors.green.shade900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 15,
              ),
              Text(
                "Customer",
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                    fontSize: 16,
                    decoration: TextDecoration.underline),
              ),
              Text(ds['customerName']),
              Text(ds['customerMobile']),
              const SizedBox(
                height: 10,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  MaterialButton(
                    onPressed: () async {
                      Uri url = Uri.parse('tel:' + ds['customerMobile']);
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url,
                            mode: LaunchMode.externalApplication);
                      } else {
                        throw "cannot make call";
                      }
                    },
                    child: Container(
                      color: Colors.blueAccent,
                      padding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      child: Row(
                        children: [
                          Icon(
                            Icons.phone,
                            color: Colors.white,
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          Text(
                            "Call - " + ds['customerName'].split(' ')[0],
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                  MaterialButton(
                    onPressed: () async {
                      Uri url = Uri.parse(
                          "https://www.google.com/maps/dir/?api=1&origin=" +
                              ds['pickAddress'] +
                              "&destination=" +
                              ds['dropAddress'] +
                              "&travelmode=car");
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url,
                            mode: LaunchMode.externalApplication);
                      } else {
                        throw "cannot open map";
                      }
                    },
                    child: Container(
                      color: Colors.blueGrey,
                      padding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      child: Row(
                        children: [
                          Icon(
                            Icons.map,
                            color: Colors.white,
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          Text(
                            "Check Map",
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
              const SizedBox(
                height: 10,
              ),
            ],
          ),
        ),
        SizedBox(
          height: 25,
        ),
        ds['status'] == "Pending"
            ? Center(
                child: ConfirmationSlider(
                  // stickToEnd: true,
                  height: 50,
                  backgroundShape: const BorderRadius.all(Radius.circular(7)),
                  backgroundColor: Color.fromARGB(255, 176, 241, 210),
                  foregroundColor: Color.fromARGB(255, 43, 138, 46),
                  sliderButtonContent: Icon(
                    Icons.keyboard_double_arrow_right,
                    color: Colors.white,
                  ),
                  textStyle: TextStyle(color: Colors.black),
                  foregroundShape: BorderRadius.all(Radius.circular(7)),
                  onConfirmation: () {
                    // PageRouteTransition.push(context, TrackTripUi());
                    showModalBottomSheet<void>(
                      isScrollControlled: true,
                      enableDrag: false,
                      isDismissible: false,
                      backgroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                      context: context,
                      builder: (BuildContext context) {
                        return startConfirmation(ds);
                      },
                    );
                  },
                ),
              )
            : SizedBox(),
      ],
    );
  }

  Widget startConfirmation(var rideDetails) {
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return Container(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom),
            constraints: const BoxConstraints(maxHeight: 700),
            child: SingleChildScrollView(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Start Confirmation',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.grey,
                              ),
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    buildCustomTextField(
                      label: 'Start OTP',
                      obsecureText: false,
                      maxLength: 5,
                      textCapitalization: TextCapitalization.none,
                      textEditingController: startOTP,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value!.length != 5) {
                          return 'Otp must be of 5 digits';
                        } else if (value.isEmpty) {
                          return 'This Field is required';
                        }
                        return null;
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        errorMsg,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                    MaterialButton(
                      onPressed: () async {
                        showAlertDialog(context);
                        FocusScope.of(context).unfocus();
                        FirebaseFirestore.instance
                            .collection('rideRequest')
                            .where("id", isEqualTo: rideDetails['id'])
                            .where('driverId',
                                isEqualTo: Constants.driverDetails['id'])
                            .where('status', isEqualTo: "Pending")
                            .where('startOtp', isEqualTo: startOTP.text)
                            .get()
                            .then((value) {
                          if (value.size > 0) {
                            Constants.driverDetails['driverLifeCycle'] =
                                "Tripping";
                            FirebaseFirestore.instance
                                .collection("drivers")
                                .doc(Constants.driverDetails['id'])
                                .update({"driverLifeCycle": "Tripping"});

                            FirebaseFirestore.instance
                                .collection("rideRequest")
                                .doc(rideDetails['id'])
                                .update({"status": "Active"});
                            errorMsg = "OTP Matched";
                            PageRouteTransition.pop(context);
                            PageRouteTransition.pushReplacement(
                                context,
                                TrackTripUi(
                                  rideDetails: rideDetails,
                                ));
                          } else {
                            errorMsg = "Invalid OTP. Try again.";
                          }
                          setModalState(() {});
                        });
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.blueGrey[700],
                        ),
                        child: const Center(
                          child: Text(
                            "Verify and Start",
                            style: TextStyle(color: Colors.white),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
