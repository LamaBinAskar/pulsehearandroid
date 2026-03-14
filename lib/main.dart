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

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final bluetoothService = BluetoothService();
    final bleService = BleAudioService(bleService: bluetoothService);

    return MaterialApp(
      title: 'PulseHear',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.purple,
      ),
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/start': (context) => const StartScreen(),
        '/signin': (context) => const SignInScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/bluetooth': (context) => const PairWristbandScreen(),
        '/dashboard': (context) => DashboardScreen(service: bleService),
        '/sounds': (context) => const SoundLibraryScreen(),
        '/keywords': (context) => const KeywordsScreen(),
      },
    );
  }
}
