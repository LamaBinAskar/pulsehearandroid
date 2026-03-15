import 'package:flutter/material.dart';

class SoundLibraryService extends ChangeNotifier {
  final Map<String, bool> _enabled = {
    'Fire Alarm': true,
    'Car Horn':   true,
    'My Name':    true,
    'Baby Cry':   true,
    'Adhan':      true,
    'Doorbell':   false,
  };

  bool isEnabled(String title) => _enabled[title] ?? true;

  void setEnabled(String title, bool value) {
    if (_enabled[title] == value) return;
    _enabled[title] = value;
    notifyListeners();
  }

  // Map YAMNet friendly labels → sound library title, then check enabled
  bool isLabelEnabled(String friendlyLabel) {
    const labelToTitle = {
      'FIRE ALARM':  'Fire Alarm',
      'SMOKE ALARM': 'Fire Alarm',
      'ALARM':       'Fire Alarm',
      'BABY CRY':    'Baby Cry',
      'CRY':         'Baby Cry',
      'DOORBELL':    'Doorbell',
      'KNOCK':       'Doorbell',
      'SIREN':       'Car Horn',
      'AMBULANCE':   'Car Horn',
      'POLICE':      'Car Horn',
    };
    final title = labelToTitle[friendlyLabel.toUpperCase()];
    if (title == null) return true; // unknown sound → allow by default
    return _enabled[title] ?? true;
  }
}
