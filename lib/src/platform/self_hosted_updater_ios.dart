/// iOS side of the plugin.
///
/// iOS needs no native code: the install is handed to the system through an
/// `itms-services://` link. This Dart-only class exists so Flutter (and
/// pub.dev) list iOS as a supported platform.
class SelfHostedUpdaterIos {
  /// Called by Flutter's generated plugin registrant. Nothing to set up.
  static void registerWith() {}
}
