import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:firebase_messaging/firebase_messaging.dart'; // Uncomment when using background message handler

import 'package:siprix_voip_sdk/accounts_model.dart';
import 'package:siprix_voip_sdk/cdrs_model.dart';
import 'package:siprix_voip_sdk/devices_model.dart';
import 'package:siprix_voip_sdk/logs_model.dart';
import 'package:siprix_voip_sdk/messages_model.dart';
import 'package:siprix_voip_sdk/network_model.dart';
import 'package:siprix_voip_sdk/siprix_voip_sdk.dart';
import 'package:siprix_voip_sdk/subscriptions_model.dart';

import 'accouns_model_app.dart';
import 'account_add.dart';
import 'call_add.dart';
import 'calls_model_app.dart';
import 'firebase_options.dart';
import 'home.dart';
import 'settings.dart';
import 'subscr_add.dart';
import 'subscr_model_app.dart';

//const FirebaseOptions gFCMOptions = FirebaseOptions(
//      apiKey: '...',            //Copy from `google-services.json` - `client.api_key.current_key`
//      appId: '...',             //Copy from `google-services.json` - `client.client_info.mobilesdk_app_id`
//      messagingSenderId: '...', //Copy from `google-services.json` - `project_info.project_number`
//      projectId: '...',         //Copy from `google-services.json` - `project_info.project_id`
//      storageBucket: '...'      //Copy from `google-services.json` - `project_info.storage_bucket`
//);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase only on supported platforms (NOT macOS)
  if (!Platform.isMacOS && !Platform.isWindows) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize FCM for Android
  }
  if (Platform.isAndroid) {
    await _initializeFCM();
  }
  await _loadEnv();

  //Create models
  LogsModel logsModel = LogsModel(
    true,
  ); //Set 'false' when logs won't rendering on UI
  CdrsModel cdrsModel =
      CdrsModel(); //List of recent calls (Call Details Records)

  DevicesModel devicesModel = DevicesModel(logsModel); //List of devices
  NetworkModel networkModel = NetworkModel(logsModel); //Network state details
  AppAccountsModel accountsModel = AppAccountsModel(
    logsModel,
  ); //List of accounts
  MessagesModel messagesModel = MessagesModel(accountsModel, logsModel);
  AppCallsModel callsModel = AppCallsModel(
    accountsModel,
    logsModel,
    cdrsModel,
  ); //List of calls
  SubscriptionsModel subscrModel = SubscriptionsModel<AppBlfSubscrModel>(
    accountsModel,
    AppBlfSubscrModel.fromJson,
    logsModel,
  ); //List of subscriptions

  //Run app
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => accountsModel),
        ChangeNotifierProvider(create: (context) => networkModel),
        ChangeNotifierProvider(create: (context) => devicesModel),
        ChangeNotifierProvider(create: (context) => messagesModel),
        ChangeNotifierProvider(create: (context) => subscrModel),
        ChangeNotifierProvider(create: (context) => callsModel),
        ChangeNotifierProvider(create: (context) => cdrsModel),
        ChangeNotifierProvider(create: (context) => logsModel),
      ],
      child: const MyApp(),
    ),
  );
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Only for Android (this handler should never be called on macOS)
  if (!Platform.isMacOS) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  //!!! Method is working in the background isolate!
  //!!! At this moment Activity may not exist or whole App could be completely stopped
  //!!! Code below initializes Siprix, adds saved accounts and refreshes registration (makes app ready to receive incoming call)

  debugPrint(
    "[!!!] Handling a background message id:'${message.messageId}' data:'${message.data}'",
  );

  try {
    await _loadEnv();
    debugPrint("Initialize siprix");
    await _MyAppState._initializeSiprix();

    debugPrint("Read and add accounts");
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String accJsonStr = prefs.getString('accounts') ?? '';
    if (accJsonStr.isNotEmpty) {
      AppAccountsModel tmpAccsModel = AppAccountsModel();
      await tmpAccsModel.loadFromJson(accJsonStr);
      tmpAccsModel.refreshRegistration();
    }
  } on Exception catch (err, stackTrace) {
    debugPrint('Error: ${err.toString()}');
    debugPrint(stackTrace.toString());
  }
}

Future<void> _initializeFCM() async {
  if (Platform.isAndroid) {
    WidgetsFlutterBinding.ensureInitialized();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }
}

Future<void> _loadEnv() async {
  if (dotenv.isInitialized) {
    return;
  }
  const primaryEnv = ".env";
  const fallbackEnv = ".env.example";

  Future<void> loadFile(String file) async {
    await dotenv.load(fileName: file);
    debugPrint("Loaded environment from $file");
  }

  try {
    await loadFile(primaryEnv);
  } catch (err, stackTrace) {
    debugPrint("Failed to load $primaryEnv: $err\n$stackTrace");
    try {
      await loadFile(fallbackEnv);
    } catch (fallbackErr) {
      debugPrint("Failed to load $fallbackEnv: $fallbackErr");
      // Don't rethrow - allow app to continue with empty env
      // The license check will happen later in _initializeSiprix
    }
  }
}

class MyApp extends StatefulWidget {
  static String _ringtonePath = "";
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();

  /// Write ringtone file from asset to device
  void writeRingtoneAsset() async {
    _ringtonePath = await writeAssetAndGetFilePath("ringtone.mp3");
  }

  /// Returns path and file name for recorded file
  static Future<String> getRecFilePathName(int callId) async {
    String dateTime = DateFormat('yyyyMMdd_HHmmss_').format(DateTime.now());
    var homeFolder = await SiprixVoipSdk().homeFolder();
    var filePath = '$homeFolder$dateTime$callId.mp3';
    return filePath;
  }

  /// Returns ringtone's path saved on device
  static String getRingtonePath() => _ringtonePath;

  /// Write file from assest to device and returns path to it
  static Future<String> writeAssetAndGetFilePath(String assetsFileName) async {
    var homeFolder = await SiprixVoipSdk().homeFolder();
    var filePath = '$homeFolder$assetsFileName';

    var file = File(filePath);
    var exists = file.existsSync();
    debugPrint("writeAsset: '$filePath' exists:$exists");
    if (exists) return filePath;

    final byteData = await rootBundle.load('assets/$assetsFileName');
    await file.create(recursive: true);
    file.writeAsBytes(byteData.buffer.asUint8List(), flush: true);
    return filePath;
  }
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute:
          WidgetsBinding.instance.platformDispatcher.defaultRouteName != '/'
              ? WidgetsBinding.instance.platformDispatcher.defaultRouteName
              : null,
      onGenerateRoute: (settings) {
        final uri = Uri.tryParse(settings.name ?? '');
        if (uri?.path == '/call_screen') {
          return MaterialPageRoute(
            settings: settings,
            builder: (context) => const CallAddPage(true),
          );
        }
        return null;
      },
      routes: <String, WidgetBuilder>{
        CallAddPage.routeName:
            (BuildContext context) => const CallAddPage(true),
        SettingsPage.routeName: (BuildContext context) => const SettingsPage(),
        AccountPage.routeName: (BuildContext context) => const AccountPage(),
        SubscrAddPage.routeName:
            (BuildContext context) => const SubscrAddPage(),
        '/call_screen': (BuildContext context) {
          // Ở đây bạn có thể bóc tách params từ defaultRouteName để hiển thị call
          return const CallAddPage(true); // Tạm trả về trang gọi
        },
      },
      home: const HomePage(),
      title: 'OneCX (Flutter framework)',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    // Delay initialization to ensure context is ready
    // On macOS, add extra delay to wait for native SDK initialization
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (Platform.isMacOS) {
        // Wait for native SDK initialization to complete
        await Future.delayed(const Duration(milliseconds: 500));
      }
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    try {
      // Initialize Siprix SDK from Flutter on all platforms
      await _initializeSiprix(context.read<LogsModel>());
      widget
          .writeRingtoneAsset(); //after initialize Siprix as uses its 'homeFolder'
      _readSavedState();
    } catch (err, stackTrace) {
      debugPrint('Error initializing app: $err');
      debugPrint(stackTrace.toString());
      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to initialize: $err')));
      }
    }
  }

  void _loadModels(
    String accJsonStr,
    String cdrsJsonStr,
    String subsJsonStr,
    String msgsJsonStr,
  ) async {
    //Accounts
    AppAccountsModel accs = context.read<AppAccountsModel>();
    accs.onSaveChanges = _saveAccountChanges;

    //Subscriptions
    SubscriptionsModel subs = context.read<SubscriptionsModel>();
    subs.onSaveChanges = _saveSubscriptionChanges;

    MessagesModel msgs = context.read<MessagesModel>();
    msgs.onSaveChanges = _saveMessagesChanges;

    //CDRs (Call Details Records)
    CdrsModel cdrs = context.read<CdrsModel>();
    cdrs.onSaveChanges = _saveCdrsChanges;

    //Load messages, than accounts, then other models
    msgs.loadFromJson(msgsJsonStr);
    accs.loadFromJson(accJsonStr);
    subs.loadFromJson(subsJsonStr);
    cdrs.loadFromJson(cdrsJsonStr);

    //Assign contact name resolver
    context.read<AppCallsModel>().onResolveContactName = _resolveContactName;

    //Load devices
    context.read<DevicesModel>().load();
  }

  void _readSavedState() {
    debugPrint('_readSavedState');
    SharedPreferences.getInstance().then((prefs) {
      String accJsonStr = prefs.getString('accounts') ?? '';
      String subsJsonStr = prefs.getString('subscriptions') ?? '';
      String cdrsJsonStr = prefs.getString('cdrs') ?? '';
      String msgsJsonStr = prefs.getString('msgs') ?? '';
      _loadModels(accJsonStr, cdrsJsonStr, subsJsonStr, msgsJsonStr);
    });
  }

  String _resolveContactName(String phoneNumber) {
    return ""; //TODO add own implementation
    //if(phoneNumber=="100") { return "MyFriend100"; } else
    //if(phoneNumber=="101") { return "MyFriend101"; }
    //else                  { return "";        }
  }

  void _saveAccountChanges(String accountsJsonStr) {
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('accounts', accountsJsonStr);
    });
  }

  void _saveCdrsChanges(String cdrsJsonStr) {
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('cdrs', cdrsJsonStr);
    });
  }

  void _saveMessagesChanges(String msgsJsonStr) {
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('msgs', msgsJsonStr);
    });
  }

  void _saveSubscriptionChanges(String subscrJsonStr) {
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('subscriptions', subscrJsonStr);
    });
  }

  static Future<void> _initializeSiprix([LogsModel? logsModel]) async {
    // Try to get license from .env, fallback to hardcoded value
    String? licenseKey = dotenv.env['SIPRIX_LICENSE'];

    // Fallback to hardcoded license if .env not loaded (common on iOS)
    if (licenseKey == null || licenseKey.isEmpty) {
      licenseKey =
          "LicensedTo[Internation_Distribution_Corporation]_Platforms[WIN_ANDR_IOS_OSX_LIN]_Features[V_MC_MA_MSG]_SupportTill[20260719]_UpdatesTill[20260719]_Key[MC0CFFkvOliKHLf/W7rkgasgYkDEs88pAhUAwpIH1r8ECvWm9HgnESfX8yCBweA=]";
      debugPrint("Using hardcoded SIPRIX_LICENSE (env file not loaded)");
    }

    debugPrint("=== Creating InitData ===");
    InitData iniData = InitData();
    iniData.license = licenseKey;
    iniData.logLevelFile = LogLevel.debug;
    iniData.logLevelIde = LogLevel.info;
    iniData.singleCallMode = false;
    iniData.tlsVerifyServer = false;

    if (Platform.isIOS) {
      debugPrint("=== Configuring iOS settings ===");
      // Disable both CallKit and PushKit temporarily to test
      iniData.enableCallKit = true;
      iniData.enablePushKit = true;
      iniData.unregOnDestroy = false;
      debugPrint("iOS: CallKit=false, PushKit=false (testing mode)");
    }
    if (Platform.isAndroid) {
      iniData.listenTelState = true;
      iniData.listenVolChange = true;
      iniData.serviceClassName = "com.siprix.voip_sdk_example.MyNotifService";
    }

    debugPrint("=== Calling SiprixVoipSdk().initialize() ===");
    try {
      await SiprixVoipSdk().initialize(iniData, logsModel);
      debugPrint("=== Siprix initialized successfully ===");
    } catch (err, stackTrace) {
      debugPrint("=== ERROR initializing Siprix ===");
      debugPrint("Error: $err");
      debugPrint("StackTrace: $stackTrace");
      rethrow;
    }

    //Set video params (if required)
    //VideoData vdoData = VideoData();
    //vdoData.noCameraImgPath = await MyApp.writeAssetAndGetFilePath("noCamera.jpg");
    //vdoData.bitrateKbps = 800;
    //SiprixVoipSdk().setVideoParams(vdoData);
  }
}

/*
//=======================================//
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:siprix_voip_sdk/accounts_model.dart';
import 'package:siprix_voip_sdk/calls_model.dart';
import 'package:siprix_voip_sdk/logs_model.dart';
import 'package:siprix_voip_sdk/siprix_voip_sdk.dart';

void main() async {
  AccountsModel accountsModel = AccountsModel();
  CallsModel callsModel = CallsModel(accountsModel);
  runApp(
    MultiProvider(providers:[
      ChangeNotifierProvider(create: (context) => accountsModel),
      ChangeNotifierProvider(create: (context) => callsModel),
    ],
    child: const MyApp(),
  ));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _initializeSiprix();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OneCX',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: Scaffold(body:buildBody())
    );
  }

  Widget buildBody() {
    final accounts = context.watch<AppAccountsModel>();
    final calls = context.watch<AppCallsModel>();
    return Column(children: [
      ListView.separated(
        shrinkWrap: true,
        itemCount: accounts.length,
        separatorBuilder: (BuildContext context, int index) => const Divider(height: 1),
        itemBuilder: (BuildContext context, int index) {
          AccountModel acc = accounts[index];
          return
            ListTile(title: Text(acc.uri, style: Theme.of(context).textTheme.titleSmall),
                subtitle: Text(acc.regText),
                tileColor: Colors.blue
            );
        },
      ),
      ElevatedButton(onPressed: _addAccount, child: const Icon(Icons.add_card)),
      const Divider(height: 1),
      ListView.separated(
        shrinkWrap: true,
        itemCount: calls.length,
        separatorBuilder: (BuildContext context, int index) => const Divider(height: 1),
        itemBuilder: (BuildContext context, int index) {
          CallModel call = calls[index];
          return
            ListTile(title: Text(call.nameAndExt, style: Theme.of(context).textTheme.titleSmall),
              subtitle: Text(call.state.name), tileColor: Colors.amber,
              trailing: IconButton(
                onPressed: (){ call.bye(); },
                icon: const Icon(Icons.call_end))
            );
        },
      ),
      ElevatedButton(onPressed: _addCall, child: const Icon(Icons.add_call)),
      const Spacer(),
    ]);
  }

  void _initializeSiprix([LogsModel? logsModel]) async {
    InitData iniData = InitData();
    iniData.license  = "...license-credentials...";
    iniData.logLevelFile = LogLevel.info;
    SiprixVoipSdk().initialize(iniData, logsModel);
  }

  void _addAccount() {
    AccountModel account = AccountModel();
    account.sipServer = "192.168.0.122";
    account.sipExtension = "1016";
    account.sipPassword = "12345";
    account.expireTime = 300;
    context.read<AppAccountsModel>().addAccount(account)
      .catchError(showSnackBar);
  }

  void _addCall() {
    final accounts = context.read<AppAccountsModel>();
    if(accounts.selAccountId==null) return;

    CallDestination dest = CallDestination("1012", accounts.selAccountId!, false);

    context.read<AppCallsModel>().invite(dest)
      .catchError(showSnackBar);
  }

  void showSnackBar(dynamic err) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
  }
}
*/
