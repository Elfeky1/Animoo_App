import 'package:flutter/material.dart';

class LoadingController {
  static final ValueNotifier<bool> isLoading =
      ValueNotifier<bool>(false);

  static void show() {
    isLoading.value = true;
  }

  static void hide() {
    isLoading.value = false;
  }
}
