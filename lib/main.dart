import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'controllers/gemini_live_controller.dart';
import 'views/home_view.dart';
import 'firebase_options.dart';
void main() async {
  print("GFlux: Starting application...");
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  print("GFlux: Environment loaded.");
  print("GFlux: Widgets initialized.");
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ); 
    print("GFlux: Firebase initialized successfully.");
  } catch (e) {
    print("GFlux: Firebase initialization failed: $e");
  }
  
  print("GFlux: Running app...");
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GeminiLiveController()),
      ],
      child: const GFluxApp(),
    ),
  );
}

class GFluxApp extends StatelessWidget {
  const GFluxApp({super.key});

  @override
  Widget build(BuildContext context) {
    print("GFlux: App build");
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GFlux: Gemini Live AI',
      themeMode: ThemeMode.dark,
      theme: ThemeData(
        brightness: Brightness.dark,
        textTheme: GoogleFonts.spaceGroteskTextTheme(
          ThemeData(brightness: Brightness.dark).textTheme,
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFA855F7), 
          brightness: Brightness.dark
        ),
        useMaterial3: true,
      ),
      home: const HomeView(),
    );
  }
}