import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:jura/core/router/navigator_key.dart';

// Toast type "danger", "default" constants
enum ToastType { destructive, normal }

BuildContext _rootToastContext([BuildContext? context]) {
  final rootContext = rootNavigatorKey.currentContext;
  if (rootContext != null) return rootContext;

  if (context != null) {
    return Navigator.of(context, rootNavigator: true).context;
  }

  throw StateError(
    'No root navigator context available. '
    'Pass a BuildContext to showAppToast(context: ...) or ensure the app is mounted.',
  );
}

ToastOverlay showAppToast({
  BuildContext? context,
  required String title,
  String? subtitle,
  bool dismissible = true,
  Curve curve = Curves.easeOutCubic,
  Duration entryDuration = const Duration(milliseconds: 500),
  VoidCallback? onClosed,
  Duration showDuration = const Duration(seconds: 5),
  ToastType type = ToastType.normal,
}) {
  return showToast(
    context: _rootToastContext(context),
    location: ToastLocation.topCenter,
    dismissible: dismissible,
    curve: curve,
    entryDuration: entryDuration,
    onClosed: onClosed,
    showDuration: showDuration,
    builder: (toastContext, overlay) =>
        buildToast(toastContext, overlay, title, subtitle, type),
  );
}

Widget buildToast(
  BuildContext context,
  ToastOverlay overlay,
  String title,
  String? subtitle,
  ToastType type,
) {
  final theme = Theme.of(context);
  return SurfaceCard(
    fillColor: type == ToastType.destructive
        ? theme.colorScheme.destructive
        : null,
    borderColor: type == ToastType.destructive
        ? theme.colorScheme.destructive
        : null,
    filled: true,
    child: Basic(
      title: Text(title, style: TextStyle(color: Colors.white)).bold,
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle,
              style: TextStyle(color: Colors.white.withAlpha(200)),
            ),
      trailing: IconButton.text(
        size: ButtonSize.small,
        onPressed: () {
          overlay.close();
        },
        icon: Icon(RadixIcons.cross1, color: Colors.white),
      ),
      trailingAlignment: Alignment.center,
    ),
  );
}
