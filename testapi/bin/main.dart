/// This API Server only implements one request, it fetches all data needed for visualizing the list of October, 2019
/// The only purpose of this, should be to evaluate the performance of an 3rd party API Server vs. web-scraping on the mobile device itself.

import 'package:testapi/testapi.dart';

Future main() async {
  final app = Application<TestapiChannel>()
      ..options.configurationFilePath = "config.yaml"
      ..options.port = 8888;

  final count = Platform.numberOfProcessors ~/ 2;
  await app.start(numberOfInstances: count > 0 ? count : 1);

  print("Application started on port: ${app.options.port}.");
  print("Use Ctrl-C (SIGINT) to stop running the application.");
}