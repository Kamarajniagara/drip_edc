import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
//import 'package:screen_protector/screen_protector.dart';
import '../../../layouts/user_layout.dart';
import '../../../repository/repository.dart';
import '../../../security/device_security.dart';
import '../../../services/http_service.dart';
import '../../../view_models/login_view_model.dart';
import '../../screen_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  @override
  void initState() {
    super.initState();
    //_protectScreen();
  }

  /*Future<void> _protectScreen() async {
    await ScreenProtector.protectDataLeakageOn(); // enables FLAG_SECURE on Android, blur-on-background on iOS
  }*/

  @override
  Widget build(BuildContext context) {

    if (DeviceSecurity.isRooted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Disabled on rooted devices.')),
      );
      return const SizedBox();
    }

    return ChangeNotifierProvider(
      create: (_) => LoginViewModel(
        repository: RepositoryImpl(HttpService()),
        onLoginSuccess: (message) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const ScreenController()),
                (route) => false,
          );
        },
      ),
      child: const LoginScreenLayout(),
    );
  }

  @override
  void dispose() {
    //ScreenProtector.protectDataLeakageOff();
    super.dispose();
  }
}