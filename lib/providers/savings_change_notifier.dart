import 'package:flutter/foundation.dart';

class SavingsChangeNotifier {
  const SavingsChangeNotifier._();

  static final ValueNotifier<int> version = ValueNotifier<int>(0);

  static void notifyChanged() {
    version.value++;
  }
}
