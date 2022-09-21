import 'dart:async';

import 'package:byo_driver/components.dart';
import 'package:byo_driver/constants.dart';
import 'package:byo_driver/services/notification_function.dart';
import 'package:byo_driver/tracktrip_ui.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:page_route_transition/page_route_transition.dart';
import 'package:slide_to_confirm/slide_to_confirm.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeUi extends StatefulWidget {
  const HomeUi({Key? key}) : super(key: key);

  @override
  State<HomeUi> createState() => _HomeUiState();
}

class _HomeUiState extends State<HomeUi> {
  double totalIncome = 0.0;
  final startOTP = TextEditingController();
  String errorMsg = '';

  late Timer timer;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(Duration(seconds: 5), (Timer t) => setState(() {}));
  }

  @override
  void dispose() {
    super.dispose();
    timer.cancel();
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
    return SizedBox(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Card(
                    elevation: 0,
                    color: Colors.blue.withOpacity(0.1),
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
                            'Total Trips',
                            style: TextStyle(
                              fontSize: 17,
                              color: Colors.blue.shade800,
                              fontWeight: FontWeight.w900,
                              // fontStyle: FontStyle.italic,
                            ),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          FutureBuilder<dynamic>(
                            future: FirebaseFirestore.instance
                                .collection("rideRequest")
                                .where("driverId",
                                    isEqualTo: Constants.driverDetails['id'])
                                .get(),
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                return Text(
                                  snapshot.data.docs.length.toString(),
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600),
                                );
                              }
                              return Text(
                                '0',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Expanded(
                    child: Card(
                      elevation: 0,
                      color: Colors.blue.withOpacity(0.1),
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
                              'Total Income',
                              style: TextStyle(
                                fontSize: 17,
                                color: Colors.blue.shade800,
                                fontWeight: FontWeight.w900,
                                // fontStyle: FontStyle.italic,
                              ),
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            FutureBuilder<dynamic>(
                              future: FirebaseFirestore.instance
                                  .collection("rideRequest")
                                  .where("driverId",
                                      isEqualTo: Constants.driverDetails['id'])
                                  .where('status', isEqualTo: 'Completed')
                                  .get(),
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  totalIncome = 0.0;
                                  for (int i = 0;
                                      i < snapshot.data.docs.length;
                                      i++) {
                                    totalIncome +=
                                        snapshot.data.docs[i]['cost'];
                                  }
                                  return Text(
                                    "₹ " + totalIncome.toStringAsFixed(2),
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  );
                                }
                                return Text(
                                  "₹ " + '0',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            FutureBuilder<dynamic>(
              future: FirebaseFirestore.instance
                  .collection('rideRequest')
                  .where('driverId', isEqualTo: Constants.driverDetails['id'])
                  .where('status', whereIn: ['Pending', 'Active']).get(),
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
                      SizedBox(
                        height: 50,
                      ),
                      GestureDetector(
                        onTap: () {
                          sendNotification(
                            [Constants.driverDetails['tokenId']],
                            'No Trips Yet...',
                            'BYO',
                            '',
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Center(
                            child: Image.asset(
                              './lib/assets/images/clock.png',
                              height: 150,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Text(
                        "No Trips for now",
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 25,
                          fontWeight: FontWeight.w900,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(
                        height: 5,
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          "Take rest and wait for upcoming trips. We'll notify you!",
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  );
                }
                return Center(
                  child: CircularProgressIndicator(),
                );
              },
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            'Ongoing Trip',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
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
                children: [
                  Expanded(
                    flex: 3,
                    child: OutlinedButton(
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
                      style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.blueGrey, width: 1)),
                      child: Text(
                        "Check Map",
                        style: TextStyle(color: Colors.blueGrey),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Expanded(
                    flex: 3,
                    child: OutlinedButton(
                      onPressed: () async {
                        Uri url = Uri.parse('tel:' + ds['customerMobile']);
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url);
                        } else {
                          throw "cannot make call";
                        }
                      },
                      style: OutlinedButton.styleFrom(
                          side: BorderSide(
                              color: Color.fromARGB(255, 54, 130, 244),
                              width: 1)),
                      child: Text(
                        "Call - " + ds['customerName'].split(' ')[0],
                        style:
                            TextStyle(color: Color.fromARGB(255, 54, 130, 244)),
                      ),
                    ),
                  ),
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
            : OutlinedButton(
                style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.blueGrey.shade900)),
                onPressed: () {
                  PageRouteTransition.push(
                      context, TrackTripUi(rideDetails: ds));
                },
                child: Row(
                  children: [
                    Text("Go to Tracking Page"),
                    Spacer(),
                    Icon(Icons.arrow_right)
                  ],
                ),
              ),
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
