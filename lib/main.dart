import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'controllers/gemini_live_controller.dart';
import 'views/home_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Note: Firebase project configuration must be present in android/ios folders.
  // E.g., via firebase configure or adding google-services.json manually.
  await Firebase.initializeApp(); 
  
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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GFlux: Gemini Live AI',
      themeMode: ThemeMode.dark,
      theme: ThemeData(
        brightness: Brightness.dark,
        textTheme: GoogleFonts.outfitTextTheme(
          ThemeData(brightness: Brightness.dark).textTheme,
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.cyanAccent, 
          brightness: Brightness.dark
        ),
        useMaterial3: true,
      ),
      home: const HomeView(),
    );
  }
}