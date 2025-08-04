import 'package:package_info_plus/package_info_plus.dart';

typedef AppVersion = ({
  String version,
  String buildNumber,
});

class Utils {
  static AppVersion _currentVersion = (version: '1.0.0', buildNumber: '1');

  static AppVersion get currentVersion => _currentVersion;
  static String get version => _currentVersion.version;
  static String get buildNumber => _currentVersion.buildNumber;

  //fetch from pacakge info
  static Future<AppVersion> fetchAppVersion() async {
   try{
    final packageInfo = await PackageInfo.fromPlatform();
    AppVersion version = (version: packageInfo.version, buildNumber: packageInfo.buildNumber);
    _currentVersion = version;
    return version;
   }catch(e){
    throw Exception('Failed to fetch app version: $e');
   }
  }

}


