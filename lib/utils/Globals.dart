library tribeka.globals;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tribeka/utils/Session.dart';

final Session session = new Session();
final String baseURL = "http://intra.tribeka.at/";
final String loginURL = "login/";
final String hoursURL = "stunden/";
final String monthURL = "Default.asp";
final storage = new FlutterSecureStorage();
bool autoLogin;
String empId;
String selYear;
String selMonth;
String defBranch;
