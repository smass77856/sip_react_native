import 'dart:developer';
import 'dart:io';

//import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:siprix_voip_sdk/accounts_model.dart';
import 'package:siprix_voip_sdk/siprix_voip_sdk.dart';

/// Accounts list model (contains app level code of managing accіounts)
class AppAccountsModel extends AccountsModel {
  AppAccountsModel([this._logs]) : super(_logs);
  final ILogsModel? _logs;

  String? _lastPushToken;
  String? get lastPushToken => _lastPushToken;

  void _setLastPushToken(String? token) {
    if (_lastPushToken == token) return;
    _lastPushToken = token;
    notifyListeners();
  }

  @override
  Future<void> addAccount(AccountModel acc, {bool saveChanges = true}) async {
    String? token;
    if (Platform.isIOS) {
      token =
          await SiprixVoipSdk()
              .getPushKitToken(); //iOS - get PushKit VoIP token
      log('PushKit token: $token');
    } else if (Platform.isAndroid) {
      token =
          await FirebaseMessaging.instance
              .getToken(); //Android - get Firebase token
    }
    //Android - get Firebase token
    _setLastPushToken(token);

    //When resolved - put token into SIP REGISTER request
    if (token != null) {
      _logs?.print('AddAccount with push token: $token');
      acc.xheaders = {"X-Token": token}; //Put token into separate header
      acc.xContactUriParams = {
        "X-Token": token,
      }; //put token into ContactUriParams
    }
    return super.addAccount(acc, saveChanges: saveChanges);
  }
}
