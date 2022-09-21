import 'package:byo_driver/constants.dart';
import 'package:byo_driver/tracktrip_ui.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:page_route_transition/page_route_transition.dart';

class TripsUi extends StatefulWidget {
  const TripsUi({Key? key}) : super(key: key);

  @override
  State<TripsUi> createState() => _TripsUiState();
}

class _TripsUiState extends State<TripsUi> {
  int _selectedTab = 0;
  final dateFormat = new DateFormat('MMMM d, yyyy HH:mm');

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.only(left: 8.0, bottom: 10, top: 10),
          child: Row(
            children: [
              TabBarItem("Pending", 0),
              TabBarItem("Active", 1),
              TabBarItem("Completed", 2)
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Container(
              child: _selectedTab == 0
                  ? PendingList()
                  : _selectedTab == 1
                      ? ActiveList()
                      : CompletedList(),
            ),
          ),
        )
      ],
    );
  }

  Widget TabBarItem(label, index) {
    return Expanded(
      // flex: 2,
      child: Padding(
        padding: EdgeInsets.only(right: 8),
        child: ElevatedButton(
          onPressed: () {
            setState(() {
              _selectedTab = index;
            });
          },
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(7),
            ),
            surfaceTintColor: Colors.blue,
            shadowColor: Colors.grey.shade100.withOpacity(0.5),
            elevation: _selectedTab == index ? 1 : 5,
            primary:
                _selectedTab == index ? Colors.blue.shade700 : Colors.white,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: _selectedTab == index ? Colors.white : Colors.grey,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget PendingList() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: FutureBuilder<dynamic>(
        future: FirebaseFirestore.instance
            .collection('rideRequest')
            .where('driverId', isEqualTo: Constants.driverDetails['id'])
            .where('status', isEqualTo: 'Pending')
            .orderBy('tripStartTime', descending: false)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data.docs.length > 0) {
              return ListView.builder(
                itemCount: snapshot.data.docs.length,
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  DocumentSnapshot ds = snapshot.data.docs[index];
                  return TripCard(ds);
                },
              );
            } else {
              return Center(child: Text("No booking..."));
            }
          }
          return Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget ActiveList() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: FutureBuilder<dynamic>(
        future: FirebaseFirestore.instance
            .collection('rideRequest')
            .where('driverId', isEqualTo: Constants.driverDetails['id'])
            .where('status', isEqualTo: 'Active')
            .orderBy('tripStartTime', descending: false)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data.docs.length > 0) {
              return ListView.builder(
                itemCount: snapshot.data.docs.length,
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  DocumentSnapshot ds = snapshot.data.docs[index];
                  return TripCard(ds);
                },
              );
            } else {
              return Center(child: Text("No booking..."));
            }
          } else {
            return Center(child: Text("No booking..."));
          }
        },
      ),
    );
  }

  Widget CompletedList() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: FutureBuilder<dynamic>(
        future: FirebaseFirestore.instance
            .collection('rideRequest')
            .where('driverId', isEqualTo: Constants.driverDetails['id'])
            .where('status', isEqualTo: 'Completed')
            .orderBy('tripStartTime', descending: false)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data.docs.length > 0) {
              return ListView.builder(
                itemCount: snapshot.data.docs.length,
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  DocumentSnapshot ds = snapshot.data.docs[index];
                  return TripCard(ds);
                },
              );
            } else {
              return Center(child: Text("No booking..."));
            }
          } else {
            return Center(child: Text("No booking..."));
          }
        },
      ),
    );
  }

  Widget TripCard(var tripDetails) {
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
          borderRadius: BorderRadius.circular(10),
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
              // mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      Text(
                        dateFormat.format(
                          DateTime.fromMillisecondsSinceEpoch(
                            tripDetails['tripStartTime'],
                          ),
                        ),
                      ),
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
}
