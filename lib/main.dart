import 'package:flutter/material.dart';
import 'views/splash-elaf/splash_screen.dart';
import 'views/auth-elaf/start_screen.dart';
import 'views/auth-elaf/sign_in_screen.dart';
import 'views/auth-elaf/sign_up_screen.dart';
import 'views/bluetooth-asayel/bluetooth_search_screen.dart';
import 'views/dashboard-asayel/dashboard_screen.dart';
import 'views/soundlibrary-asayel/sound_library_screen.dart';
import 'views/keywords-elaf/add_keywords_screen.dart';
import 'services/ble_audio_service.dart';
import 'services/bluetooth_service.dart';
import 'services/sound_library_service.dart';
import 'services/vosk_keyword_service.dart';

// Services created once here — not inside build()
final BluetoothService    _bluetoothService    = BluetoothService();
final SoundLibraryService _soundLibraryService = SoundLibraryService();
final VoskKeywordService  _voskKeywordService  = VoskKeywordService();
final BleAudioService     _bleService          = BleAudioService(
  bleService:   _bluetoothService,
  soundLibrary: _soundLibraryService,
  voskService:  _voskKeywordService,
);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  _voskKeywordService.init();
  _voskKeywordService.onKeywordDetected = (keyword) {
    _bleService.sendKeywordAlert(keyword);
  };
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PulseHear',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.purple,
      ),
      initialRoute: '/splash',
      routes: {
        '/splash':    (context) => const SplashScreen(),
        '/start':     (context) => const StartScreen(),
        '/signin':    (context) => const SignInScreen(),
        '/signup':    (context) => const SignUpScreen(),
        '/bluetooth': (context) => PairWristbandScreen(service: _bleService),
        '/dashboard': (context) => DashboardScreen(service: _bleService),
        '/sounds':    (context) => SoundLibraryScreen(service: _soundLibraryService),
        '/keywords':  (context) => KeywordsScreen(service: _voskKeywordService),
      },
    );
  }
}
