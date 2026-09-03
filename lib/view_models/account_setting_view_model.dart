
import 'dart:convert';
import 'package:flutter/material.dart';
import '../repository/repository.dart';

class UserSettingViewModel extends ChangeNotifier {
  final Repository repository;

  bool isLoading = false;
  String errorMsg = '';

  String mySelection = 'English';

  String userName, mobileNo, emailId;
  String countryCode;

  final TextEditingController controllerMblNo = TextEditingController();
  final TextEditingController controllerUsrName = TextEditingController();
  final TextEditingController controllerAccountTye = TextEditingController();
  final TextEditingController controllerEmail = TextEditingController();

  final TextEditingController controllerOldPwd = TextEditingController();
  final TextEditingController controllerNewPwd = TextEditingController();
  final TextEditingController controllerConfirmPwd = TextEditingController();
  bool isObscureOpw = true;
  bool isObscureNpw = true;
  bool isObscureCpw = true;

  final formKey = GlobalKey<FormState>();
  final formSKey = GlobalKey<FormState>();

  UserSettingViewModel(this.repository, this.userName, this.countryCode, this.mobileNo, this.emailId, String role) {
    _setupInitialValues(role);
  }

  void _setupInitialValues(String role) {
    controllerUsrName.text = userName;
    controllerAccountTye.text = role;
    controllerEmail.text = emailId;
    controllerMblNo.text = mobileNo;
  }

  String removeCountryCode(String phoneNumber) {
    RegExp regExp = RegExp(r'^\+\d{1,4}\s?');
    return phoneNumber.replaceAll(regExp, '');
  }

  void onIsObscureChangedToOpw() {
    isObscureOpw = !isObscureOpw;
    notifyListeners();
  }

  void onIsObscureChangedToNpw() {
    isObscureNpw = !isObscureNpw;
    notifyListeners();
  }

  void onIsObscureChangedToCpw() {
    isObscureCpw = !isObscureCpw;
    notifyListeners();
  }

  /// True if the user has edited name, email, mobile number, or country
  /// code away from the values the form was originally loaded with.
  bool get hasProfileFieldChanges {
    final cleanedCode = countryCode.replaceAll('+', '');
    return controllerUsrName.text.trim() != userName.trim() ||
        controllerEmail.text.trim() != emailId.trim() ||
        controllerMblNo.text.trim() != mobileNo.trim() ||
        cleanedCode != countryCode.replaceAll('+', ''); // kept for symmetry / future edits to countryCode source
  }

  bool get isChangingPassword =>
      controllerNewPwd.text.isNotEmpty || controllerConfirmPwd.text.isNotEmpty;

  Future<Map<String, dynamic>?> updateUserProfile(
      BuildContext context, int customerId, int userId) async {
    errorMsg = '';
    String oldPw = controllerOldPwd.text;
    String newPw = controllerNewPwd.text;
    String cnPw = controllerConfirmPwd.text;

    final profileChanged = hasProfileFieldChanges;
    final passwordChangeRequested = isChangingPassword;

    // Re-authentication is required for ANY sensitive change:
    // editing name/mobile/email, or setting a new password.
    if (profileChanged || passwordChangeRequested) {
      if (oldPw.isEmpty) {
        errorMsg = 'Please enter your current password to save changes';
        notifyListeners();
        return null;
      }
    }

    if (passwordChangeRequested) {
      if (cnPw.isEmpty) {
        errorMsg = 'Please confirm your password';
        notifyListeners();
        return null;
      } else if (newPw.length < 6 || cnPw.length < 6) {
        errorMsg = 'Password must be at least 6 characters';
        notifyListeners();
        return null;
      } else if (newPw != cnPw) {
        errorMsg = 'Passwords do not match';
        notifyListeners();
        return null;
      } else if (newPw == oldPw) {
        errorMsg = 'New password must be different from current password';
        notifyListeners();
        return null;
      }
    }

    if (!profileChanged && !passwordChangeRequested) {
      errorMsg = 'No changes to save';
      notifyListeners();
      return null;
    }

    if (formKey.currentState!.validate()) {
      final result = await showDialog<Map<String, dynamic>?>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: const Text("Confirm Update"),
            content: const Text("Are you sure you want to update your profile?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(null),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  String cleanedCode = countryCode.replaceAll('+', '');
                  final body = {
                    "userId": customerId,
                    "userName": controllerUsrName.text,
                    "countryCode": cleanedCode,
                    "mobileNumber": controllerMblNo.text,
                    "email": controllerEmail.text,
                    "modifyUser": userId,
                    // Sent for verification any time profile is edited,
                    // not just for password changes.
                    "oldPassword": oldPw,
                  };

                  if (passwordChangeRequested) {
                    body["password"] = newPw;
                  }

                  setLoading(true);
                  try {
                    var response = await repository.updateUserDetails(body);

                    if (response.statusCode == 200) {
                      final jsonData = jsonDecode(response.body);
                      Navigator.of(ctx).pop(jsonData);
                    } else if (response.statusCode == 401) {
                      // Convention: 401 = current password incorrect
                      final jsonData = jsonDecode(response.body);
                      errorMsg = jsonData["message"] ?? 'Current password is incorrect';
                      notifyListeners();
                      Navigator.of(ctx).pop({"error": errorMsg});
                    } else {
                      Navigator.of(ctx).pop({"error": "Server error"});
                    }
                  } catch (error) {
                    errorMsg = 'Error updating profile: $error';
                    Navigator.of(ctx).pop({"error": errorMsg});
                  } finally {
                    setLoading(false);
                  }
                },
                child: const Text("Confirm"),
              ),
            ],
          );
        },
      );

      return result;
    }

    return null;
  }


  void setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    controllerMblNo.dispose();
    controllerUsrName.dispose();
    controllerAccountTye.dispose();
    controllerEmail.dispose();
    controllerOldPwd.dispose();
    controllerNewPwd.dispose();
    controllerConfirmPwd.dispose();
    super.dispose();
  }

}

/*
import 'dart:convert';
import 'package:flutter/material.dart';
import '../repository/repository.dart';

class UserSettingViewModel extends ChangeNotifier {
  final Repository repository;

  bool isLoading = false;
  String errorMsg = '';

  String mySelection = 'English';

  String userName, mobileNo, emailId;
  String countryCode;

  final TextEditingController controllerMblNo = TextEditingController();
  final TextEditingController controllerUsrName = TextEditingController();
  final TextEditingController controllerAccountTye = TextEditingController();
  final TextEditingController controllerEmail = TextEditingController();

  final TextEditingController controllerOldPwd = TextEditingController();
  final TextEditingController controllerNewPwd = TextEditingController();
  final TextEditingController controllerConfirmPwd = TextEditingController();
  bool isObscureOpw = true;
  bool isObscureNpw = true;
  bool isObscureCpw = true;

  final formKey = GlobalKey<FormState>();
  final formSKey = GlobalKey<FormState>();

  UserSettingViewModel(this.repository, this.userName, this.countryCode, this.mobileNo, this.emailId, String role) {
    _setupInitialValues(role);
  }

  void _setupInitialValues(String role) {
    controllerUsrName.text = userName;
    controllerAccountTye.text = role;
    controllerEmail.text = emailId;
    controllerMblNo.text = mobileNo;
  }

  String removeCountryCode(String phoneNumber) {
    RegExp regExp = RegExp(r'^\+\d{1,4}\s?');
    return phoneNumber.replaceAll(regExp, '');
  }

  void onIsObscureChangedToOpw() {
    isObscureOpw = !isObscureOpw;
    notifyListeners();
  }

  void onIsObscureChangedToNpw() {
    isObscureNpw = !isObscureNpw;
    notifyListeners();
  }

  void onIsObscureChangedToCpw() {
    isObscureCpw = !isObscureCpw;
    notifyListeners();
  }

  Future<Map<String, dynamic>?> updateUserProfile(
      BuildContext context, int customerId, int userId) async {
    errorMsg = '';
    String newPw = controllerNewPwd.text;
    String cnPw = controllerConfirmPwd.text;

    if (newPw.isNotEmpty) {
      if (cnPw.isEmpty) {
        errorMsg = 'Please confirm your password';
        notifyListeners();
        return null;
      } else if (newPw.length < 6 || cnPw.length < 6) {
        errorMsg = 'Password must be at least 6 characters';
        notifyListeners();
        return null;
      } else if (newPw != cnPw) {
        errorMsg = 'Passwords do not match';
        notifyListeners();
        return null;
      }
    }

    if (formKey.currentState!.validate()) {
      final result = await showDialog<Map<String, dynamic>?>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: const Text("Confirm Update"),
            content: const Text("Are you sure you want to update your profile?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(null),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  String cleanedCode = countryCode.replaceAll('+', '');
                  final body = {
                    "userId": customerId,
                    "userName": controllerUsrName.text,
                    "countryCode": cleanedCode,
                    "mobileNumber": controllerMblNo.text,
                    "email": controllerEmail.text,
                    "modifyUser": userId,
                  };

                  if (controllerNewPwd.text.isNotEmpty) {
                    body["password"] = controllerNewPwd.text;
                  }

                  setLoading(true);
                  try {
                    var response = await repository.updateUserDetails(body);

                    if (response.statusCode == 200) {
                      final jsonData = jsonDecode(response.body);
                      Navigator.of(ctx).pop(jsonData);
                    } else {
                      Navigator.of(ctx).pop({"error": "Server error"});
                    }
                  } catch (error) {
                    errorMsg = 'Error updating profile: $error';
                    Navigator.of(ctx).pop({"error": errorMsg});
                  } finally {
                    setLoading(false);
                  }
                },
                child: const Text("Confirm"),
              ),
            ],
          );
        },
      );

      return result;
    }

    return null;
  }


  void setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    controllerMblNo.dispose();
    controllerUsrName.dispose();
    controllerAccountTye.dispose();
    controllerEmail.dispose();
    controllerNewPwd.dispose();
    controllerConfirmPwd.dispose();
    super.dispose();
  }

}*/
