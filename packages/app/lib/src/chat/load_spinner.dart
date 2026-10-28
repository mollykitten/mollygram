import 'package:flutter/widgets.dart';
import 'package:mollygram_ui_kit/mollygram_ui_kit.dart';

/// The small spinner a list shows while its first page loads: shown only
/// when loading takes long enough to notice.
class LoadSpinner extends StatelessWidget {
  const LoadSpinner({super.key});

  @override
  Widget build(BuildContext context) =>
      const MgSpinner(delay: Duration(milliseconds: 300));
}
