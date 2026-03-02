import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart'; // Ensure 'provider' is in pubspec.yaml
import 'core/gflux_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Ensure you have added your google-services.json / GoogleService-Info.plist
  await Firebase.initializeApp(); 
  
  runApp(
    ChangeNotifierProvider(
      create: (_) => GFluxClient(),
      child: const GFluxApp(),
    ),
  );
}

class GFluxApp extends StatelessWidget {
  const GFluxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GFlux Agent',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.cyan, 
          brightness: Brightness.dark
        ),
        useMaterial3: true,
      ),
      home: const GFluxHomeScreen(),
    );
  }
}

class GFluxHomeScreen extends StatelessWidget {
  const GFluxHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gflux = context.watch<GFluxClient>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("GFLUX // LIVE"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: gflux.transcript.length,
              itemBuilder: (context, i) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(gflux.transcript[i]),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (gflux.isConnecting)
                  const CircularProgressIndicator()
                else if (!gflux.isConnected)
                  ElevatedButton.icon(
                    onPressed: () => gflux.startStreaming(),
                    icon: const Icon(Icons.flash_on),
                    label: const Text("INITIALIZE FLUX"),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 54),
                    ),
                  )
                else
                  const Text("GFlux is Active and Listening..."),
              ],
            ),
          ),
        ],
      ),
    );
  }
}