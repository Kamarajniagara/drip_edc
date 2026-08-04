import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:oro_drip_irrigation/Screens/login_screenOTP/widget/custom_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../repository/repository.dart';
import '../../services/http_service.dart';
import '../../utils/secure_storage_helper.dart';
import '../../views/common/login/login_screen.dart';
import 'otp_verification.dart';

class LoginScreenOTP extends StatefulWidget {
  const LoginScreenOTP({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreenOTP> {
  bool isManualDialCodeEntry = false;
  final TextEditingController _contactEditingController = TextEditingController();
  String? dialCodeError;
  int _clickCount = 0;
  String isoCode = 'IN';

  String? selectedCountryDialCode = "+91";
  String deveicetoken = '';

  @override
  void initState() {
    super.initState();
    getDeviceToken();
    // Security Fix: Clear clipboard on entry to prevent data leakage from other apps
    Clipboard.setData(const ClipboardData(text: ''));
  }

  @override
  void dispose() {
    _contactEditingController.dispose();
    // Security Fix: Clear clipboard on exit
    Clipboard.setData(const ClipboardData(text: ''));
    super.dispose();
  }

  Future<void> clickOnLogin(BuildContext context) async {
    if (deveicetoken.isEmpty) {
      await getDeviceToken();
    }

    if (_contactEditingController.text.isEmpty) {
      showErrorDialog(context, 'Register number can\'t be empty.');
    } else {
      String checkval = await checkNumber(selectedCountryDialCode!, _contactEditingController.text);
      if (checkval == 'true') {
        final responseMessage = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OtpVerifyScreen(
              contact: "$selectedCountryDialCode ${_contactEditingController.text}",
            ),
          ),
        );
        if (responseMessage != null) {
          showErrorDialog(context, responseMessage as String);
        }
      } else {
        _contactEditingController.text = '';
        showErrorDialog(context, 'This is Not Register Number \n Enter Register Correct Number');
      }
    }
  }

  Future<void> getDeviceToken() async {
    // 1. Try to get the token from Secure Storage (Keychain)
    String? token = await SecureStorageHelper.getDeviceToken();
    
    // 2. Migration logic: Purge legacy token from insecure storage (SharedPreferences)
    try {
      final legacyPrefs = await SharedPreferences.getInstance();
      if (legacyPrefs.containsKey('deviceToken')) {
        final legacyToken = legacyPrefs.getString('deviceToken');
        if ((token == null || token.isEmpty) && legacyToken != null) {
          // Migrate to secure storage
          await SecureStorageHelper.saveDeviceToken(legacyToken);
          token = legacyToken;
        }
        // Securely remove from plaintext storage to close Finding #1
        await legacyPrefs.remove('deviceToken');
      }
    } catch (e) {
      // SharedPreferences error, ignore and move on
    }

    // 3. If token is still missing, fetch it from FirebaseMessaging
    if (token == null || token.isEmpty) {
      try {
        token = await FirebaseMessaging.instance.getToken();
        if (token != null) {
          await SecureStorageHelper.saveDeviceToken(token);
        }
      } catch (e) {
        // FCM error
      }
    }

    if (mounted) {
      setState(() {
        deveicetoken = token ?? '';
      });
    }
  }

  Future<String> checkNumber(String countryCode, String mobileNumber) async {
    if (deveicetoken.isEmpty) {
      await getDeviceToken();
    }
    Map<String, Object> body = {
      'countryCode': countryCode.replaceFirst('+', ''),
      'mobileNumber': mobileNumber,
      'deviceToken': deveicetoken,
      'isMobile': true
    };
    final repository = Repository(HttpService());
    final response = await repository.checkMobileNumber(body);

    if (response.statusCode == 200) {
       if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/dashboard',
              (Route<dynamic> route) => false,
        );
       }
       return 'true';
    } else {
      return 'false';
    }
  }

  void showErrorDialog(BuildContext context, String message) {
    final CupertinoAlertDialog alert = CupertinoAlertDialog(
      title: const Text('Warning'),
      content: Text('\n$message'),
      actions: <Widget>[
        CupertinoDialogAction(
          isDefaultAction: true,
          child: const Text('Ok'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        )
      ],
    );
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  void _handleTap() {
    setState(() {
      _clickCount++;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
      _clickCount = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(16.0),
            width: double.infinity,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: screenHeight * 0.05,
                  ),
                  GestureDetector(
                    onTap: _handleTap,
                    child: Image.asset(
                      'assets/Images/otpmobile.png',
                      height: screenHeight * 0.3,
                      fit: BoxFit.contain,
                    ),
                  ),
                  SizedBox(
                    height: screenHeight * 0.02,
                  ),
                  const Text(
                    'Login with OTP',
                    style: TextStyle(fontSize: 28, color: Colors.black),
                  ),
                  SizedBox(
                    height: screenHeight * 0.02,
                  ),
                  const SizedBox(
                    height: 40,
                    width: 50,
                  ),
                  const Text(
                    'Enter your Register mobile number to get an OTP and complete the verification',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(
                    height: screenHeight * 0.06,
                  ),
                  Container(
                    width: 465,
                    padding: const EdgeInsets.fromLTRB(5, 35, 10, 0),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.grey,
                            offset: Offset(0.0, 1.0),
                            blurRadius: 6.0,
                          ),
                        ],
                        borderRadius: BorderRadius.circular(16.0)),
                    child: Column(
                      children: [
                        SizedBox(
                          width: 450,
                          height: 77,
                          child: Column(
                            children: [
                              IntlPhoneField(
                                controller: _contactEditingController,
                                decoration: InputDecoration(
                                  labelText: 'Phone Number',
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.clear, color: Colors.red),
                                    onPressed: () {
                                      _contactEditingController.clear();
                                    },
                                  ),
                                  border: const OutlineInputBorder(
                                    borderSide: BorderSide(),
                                  ),
                                ),
                                initialCountryCode: 'IN',
                                onChanged: (phone) {
                                  selectedCountryDialCode = phone.countryCode;
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        CustomButton(clickOnLogin),
                        const Text(
                          'or',
                        ),
                        TextButton(
                          onPressed: _handleTap,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: const Text(
                            'Login with Password',
                            style: TextStyle(fontSize: 18, color: Color.fromARGB(255, 28, 123, 137)),
                          ),
                        )
                      ],
                    ),
                  ),
                ]),
          ),
        ),
      ),
    );
  }
}
