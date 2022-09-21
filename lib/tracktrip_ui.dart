import 'dart:async';
import 'package:byo_driver/Dashboard/dashboard.dart';
import 'package:byo_driver/components.dart';
import 'package:byo_driver/constants.dart';
import 'package:byo_driver/location_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:page_route_transition/page_route_transition.dart';
import 'package:slide_to_confirm/slide_to_confirm.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:location/location.dart' as loc;
import 'package:permission_handler/permission_handler.dart';

class TrackTripUi extends StatefulWidget {
  final rideDetails;
  const TrackTripUi({Key? key, required this.rideDetails}) : super(key: key);

  @override
  State<TrackTripUi> createState() =>
      _TrackTripUiState(rideDetails: rideDetails);
}

class _TrackTripUiState extends State<TrackTripUi> {
  final loc.Location location = loc.Location();
  StreamSubscription<loc.LocationData>? _locationSubscription;

  final rideDetails;
  _TrackTripUiState({this.rideDetails});

  Set<Marker> _markers = <Marker>{};
  final Set<Polygon> _polygons = <Polygon>{};
  Set<Polyline> _polylines = <Polyline>{};
  List<LatLng> polygonLatLngs = <LatLng>[];
  // int _polygonIdCounter = 1;
  int _polylineIdCounter = 1;
  final Completer<GoogleMapController> _controller = Completer();
  final endOTP = TextEditingController();
  String errorMsg = '';

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(20.5937, 78.9629),
    zoom: 4.5,
  );

  @override
  void initState() {
    super.initState();
    _getDirection();
    _requestPermission();
    location.changeSettings(
        interval: 10000, accuracy: loc.LocationAccuracy.high);
    location.enableBackgroundMode(enable: true);
  }

  _requestPermission() async {
    var status = await Permission.location.request();
    if (status.isGranted) {
      print('done');
      _listenLocation();
    } else if (status.isDenied) {
      _requestPermission();
    } else if (status.isPermanentlyDenied) {
      openAppSettings();
    }
  }

  _getSetLocation(String address) async {
    try {
      final loc.LocationData _locationResult = await location.getLocation();
      if (address == "PickAddress") {
        await FirebaseFirestore.instance
            .collection('rideRequest')
            .doc(rideDetails['id'])
            .set({
          'pickLat': _locationResult.latitude,
          'pickLng': _locationResult.longitude
        }, SetOptions(merge: true));
      } else {
        await FirebaseFirestore.instance
            .collection('rideRequest')
            .doc(rideDetails['id'])
            .set({
          'dropLat': _locationResult.latitude,
          'dropLng': _locationResult.longitude
        }, SetOptions(merge: true));
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> _listenLocation() async {
    _locationSubscription = location.onLocationChanged.handleError((onError) {
      print(onError);
      _locationSubscription?.cancel();
      setState(() {
        _locationSubscription = null;
      });
    }).listen((loc.LocationData currentlocation) async {
      print(currentlocation.latitude.toString() +
          ', ' +
          currentlocation.longitude.toString());
      await FirebaseFirestore.instance
          .collection('rideRequest')
          .doc(rideDetails['id'])
          .set({
        'driverLat': currentlocation.latitude,
        'driverLng': currentlocation.longitude
      }, SetOptions(merge: true));
    });
  }

  _stopListening() {
    _locationSubscription?.cancel();
    setState(() {
      _locationSubscription = null;
    });
    print("Stopped Locating");
    PageRouteTransition.pop(context);
  }

  _getDirection() async {
    var directions = await LocationService()
        .getDirections(rideDetails['pickAddress'], rideDetails['dropAddress']);

    _goToThePlace(
      directions['start_location']['lat'],
      directions['start_location']['lng'],
      directions['end_location']['lat'],
      directions['end_location']['lng'],
      directions['bounds_ne'],
      directions['bounds_sw'],
    );
    _polylines = {};
    _setPolyline(directions['polyline_decoded']);
  }

  void _setMarker(
      LatLng point, BitmapDescriptor icon, String id, String placeName) {
    setState(() {
      _markers.add(
        Marker(
            markerId: MarkerId(id),
            position: point,
            icon: icon,
            infoWindow: InfoWindow(title: placeName)),
      );
    });
  }

  void _setPolyline(List<PointLatLng> points) {
    final String polylineIdVal = 'polyline_$_polylineIdCounter';
    _polylineIdCounter++;

    _polylines.add(
      Polyline(
        polylineId: PolylineId(polylineIdVal),
        width: 2,
        color: Colors.blue,
        points: points
            .map(
              (point) => LatLng(point.latitude, point.longitude),
            )
            .toList(),
      ),
    );
  }

  Future<void> _goToThePlace(
      double originLat,
      double originLng,
      double destLat,
      double destLng,
      Map<String, dynamic> boundsNe,
      Map<String, dynamic> boundsSw) async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
      target: LatLng(originLat, originLng),
      zoom: 12,
    )));

    controller.animateCamera(CameraUpdate.newLatLngBounds(
        LatLngBounds(
            southwest: LatLng(boundsSw['lat'], boundsSw['lng']),
            northeast: LatLng(boundsNe['lat'], boundsNe['lng'])),
        25));

    _markers = {};
    _setMarker(
        LatLng(originLat, originLng),
        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        'origin',
        rideDetails['pickAddress']);
    _setMarker(LatLng(destLat, destLng), BitmapDescriptor.defaultMarker,
        'destination', rideDetails['dropAddress']);
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.light.copyWith(
        statusBarBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.dark,
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            markers: _markers,
            polygons: _polygons,
            polylines: _polylines,
            initialCameraPosition: _kGooglePlex,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
            onTap: (point) {
              if (kDebugMode) {
                print(point);
              }
            },
          ),
          Align(
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(
                    height: 10,
                  ),
                  const Spacer(),
                  MaterialButton(
                    onPressed: () {
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
                          return tripDetails();
                        },
                      );
                    },
                    padding: EdgeInsets.zero,
                    color: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 10,
                    child: Container(
                      height: 60,
                      width: double.infinity,
                      child: const Center(
                        child: Text(
                          'Trip Details',
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
        ],
      ),
    );
  }

  Widget tripDetails() {
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setModalState) {
        return Container(
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
                        'Trip Details',
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
                  Center(
                    child: Text(
                      "Trk. Id " + rideDetails['id'],
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
                              padding: EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
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
                              rideDetails['pickAddress'],
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
                              padding: EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
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
                              rideDetails['dropAddress'],
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(15),
                              bottomLeft: Radius.circular(15),
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
                                rideDetails['distance'],
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
                                rideDetails['transitTime'],
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
                              topRight: Radius.circular(15),
                              bottomRight: Radius.circular(15),
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
                                '₹ ' + Constants.cF.format(rideDetails['cost']),
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
                  const SizedBox(
                    height: 15,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Customer",
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                  fontSize: 16,
                                  decoration: TextDecoration.underline),
                            ),
                            Text(rideDetails['customerName']),
                            Text(rideDetails['customerMobile']),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Driver",
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                  fontSize: 16,
                                  decoration: TextDecoration.underline),
                            ),
                            Text(rideDetails['driverName']),
                            Text(rideDetails['driverMobile']),
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
                        flex: 3,
                        child: OutlinedButton(
                          onPressed: () async {
                            Uri url = Uri.parse(
                                "https://www.google.com/maps/dir/?api=1&origin=" +
                                    rideDetails['pickAddress'] +
                                    "&destination=" +
                                    rideDetails['dropAddress'] +
                                    "&travelmode=car");
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url,
                                  mode: LaunchMode.externalApplication);
                            } else {
                              throw "cannot open map";
                            }
                          },
                          style: OutlinedButton.styleFrom(
                              side:
                                  BorderSide(color: Colors.blueGrey, width: 1)),
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
                            Uri url = Uri.parse(
                                'tel:' + rideDetails['customerMobile']);
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
                            "Call - " +
                                rideDetails['customerName'].split(' ')[0],
                            style: TextStyle(
                                color: Color.fromARGB(255, 54, 130, 244)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Center(
                    child: ConfirmationSlider(
                      text: "Slide to end",
                      // stickToEnd: true,
                      height: 50,
                      backgroundShape:
                          const BorderRadius.all(Radius.circular(7)),
                      backgroundColor: Color.fromARGB(255, 241, 178, 176),
                      foregroundColor: Color.fromARGB(255, 182, 52, 1),
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
                            return endConfirmation(rideDetails);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget endConfirmation(var rideDetails) {
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
                          'End Confirmation',
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
                      label: 'End OTP',
                      obsecureText: false,
                      maxLength: 5,
                      textCapitalization: TextCapitalization.none,
                      textEditingController: endOTP,
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
                            .where('status', isEqualTo: "Active")
                            .where('endOtp', isEqualTo: endOTP.text)
                            .get()
                            .then((value) {
                          if (value.size > 0) {
                            Constants.driverDetails['driverLifeCycle'] = "Free";
                            FirebaseFirestore.instance
                                .collection("drivers")
                                .doc(Constants.driverDetails['id'])
                                .update({"driverLifeCycle": "Free"});
                            FirebaseFirestore.instance
                                .collection("drivers")
                                .doc(Constants.driverDetails['id'])
                                .update({
                              'busyTime': FieldValue.arrayRemove([
                                {
                                  'from': rideDetails['tripStartTime'],
                                  'to': rideDetails['tripEndTime']
                                }
                              ])
                            });
                            FirebaseFirestore.instance
                                .collection("rideRequest")
                                .doc(rideDetails['id'])
                                .update({"status": "Completed"});
                            // _getSetLocation("DropAddress");
                            _stopListening();
                            errorMsg = "OTP Matched";
                            Navigator.popUntil(context, (route) => false);
                            PageRouteTransition.push(context, DashboardUi());
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
                            "Verify and End",
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
