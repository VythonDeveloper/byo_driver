import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Constants {
  static var cF = NumberFormat('#,##,###');

  static Map<String, dynamic> rideDetails = {
    "id": 0,
    "customerId": '',
    "customerName": "",
    "customerMobile": '',
    "driverId": 0,
    "driverName": "",
    "driverMobile": "",
    "driverLat": 0.0,
    "driverLng": 0.0,
    "vehicleType": '',
    "vehicleName": '',
    "vehicleNumber": '',
    "pickAddress": '',
    "pickLat": 0.0,
    "pickLng": 0.0,
    "dropAddress": '',
    "dropLat": 23.558613,
    "dropLng": 87.269232,
    "distance": '0 km',
    "transitTime": '00:00 hrs',
    "cost": '',
    "startOtp": 00000,
    "endOtp": 00000,
    "status": '',
    "bookedOn": 0,
  };

  static Map<String, dynamic> driverDetails = {
    "id": 0,
    "fullname": '',
    "mobile": '',
    "email": '',
    "licenseNumber": '',
    "address": '',
    "password": '',
    "rating": 0.0,
    "vehicleType": '',
    "vehicleName": '',
    "vehicleNumber": '',
    "status": '',
    "registeredOn": 0,
    'tokenId': '',
  };

  static Map<String, dynamic> statusColor = {
    "Pending": Colors.amber,
    "Active": Colors.purple,
    "Completed": Colors.green,
    "Cancelled": Colors.red
  };
}
