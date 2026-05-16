import 'package:flutter/material.dart';

class ColorRangeModel extends ChangeNotifier {
  double _hueStart = 0, _hueEnd = 360;
  double _valueStart = 0, _valueEnd = 60;
  double _saturationStart = 0, _saturationEnd = 60;

  double get hueStart => _hueStart;
  double get hueEnd => _hueEnd;

  double get valueStart => _valueStart;
  double get valueEnd =>   _valueEnd;

  double get saturationStart => _saturationStart;
  double get saturationEnd => _saturationEnd;

  void setHue(double start, double end) {
    _hueStart = start;
    _hueEnd = end;
  }

  void updateHue(double start, double end) {
    setHue(start, end);
    notifyListeners();
  }

  void setSaturation(double start, double end) {
    _saturationStart = start;
    _saturationEnd = end;
  }

  void updateSaturation(double start, double end) {
    setSaturation(start, end);
    notifyListeners();
  }

  void setValue(double start, double end) {
    _valueStart = start;
    _valueEnd = end;
  }

  void updateValue(double start, double end) {
    setValue(start, end);
    notifyListeners();
  }
}