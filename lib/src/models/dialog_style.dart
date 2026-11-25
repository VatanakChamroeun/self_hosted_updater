/// Look of the update UI.
enum DialogStyle {
  /// Material 3 dialogs.
  material,

  /// iOS-style alert dialogs.
  cupertino,

  /// A card that slides up from the bottom of the screen.
  bottomSheet;

  /// Renamed to [bottomSheet] in 2.0.0.
  @Deprecated('Use DialogStyle.bottomSheet. Will be removed in 3.0.0.')
  static const DialogStyle snackbar = bottomSheet;
}
