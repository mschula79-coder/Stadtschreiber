import 'package:flutter/material.dart';
import 'package:stadtschreiber/layout/app_breakpoints.dart';

class AppLayout {
  static double menuWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width < AppBreakpoints.compact) {
      return width * 0.95;
    }
    return 450;
  }

  static double modalHeight(BuildContext context) {
    return MediaQuery.of(context).size.height * 0.75;
  }


  
  static double poiListPanelWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width < AppBreakpoints.compact) {
      return width;
    }
    return 450;
  }


}