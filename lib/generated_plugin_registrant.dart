//
// Generated file. Do not edit.
//

// ignore: unused_import
import 'dart:ui';

import 'package:firebase_core_web/firebase_core_web.dart';
import 'package:image_picker_for_web/image_picker_for_web.dart';
import 'package:url_launcher_web/url_launcher_web.dart';

import 'package:flutter_web_plugins/flutter_web_plugins.dart';

// ignore: public_member_api_docs
void registerPlugins(PluginRegistry registry) {
  FirebaseCoreWeb.registerWith(registry.registrarFor(FirebaseCoreWeb));
  ImagePickerPlugin.registerWith(registry.registrarFor(ImagePickerPlugin));
  UrlLauncherPlugin.registerWith(registry.registrarFor(UrlLauncherPlugin));
  registry.registerMessageHandler();
}
