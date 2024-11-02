import 'package:flutter/material.dart';
import 'package:sphia/app/helper/init.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const initHelper = InitHelper();
  try {
    await initHelper.configureApp();
  } catch (e, st) {
    await initHelper.showErrorMsg(
      'An error occurred while starting Sphia: $e',
      st.toString(),
    );
  }
}
