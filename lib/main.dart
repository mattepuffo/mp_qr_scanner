import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MP QR Scanner',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'MP QR Scanner'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String? scannedValue;
  bool isScanning = true;

  bool _isUrl(String text) {
    final uri = Uri.tryParse(text);
    return uri != null &&
        (uri.isScheme('http') ||
            uri.isScheme('https') ||
            uri.isScheme('mailto') ||
            uri.isScheme('tel'));
  }

  Future<void> _openLink(String url) async {
    final uri = Uri.parse(url);

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossibile aprire il link')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Errore nell\'apertura del link')),
        );
      }
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Testo copiato negli appunti')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          if (!isScanning)
            IconButton(
              icon: const Icon(Icons.qr_code_scanner),
              onPressed: () {
                setState(() {
                  isScanning = true;
                  scannedValue = null;
                });
              },
              tooltip: 'Scansiona di nuovo',
            ),
        ],
      ),
      body: isScanning
          ? MobileScanner(
              onDetect: (capture) {
                final barcodes = capture.barcodes;
                if (barcodes.isNotEmpty) {
                  final value = barcodes.first.rawValue;
                  if (value != null && value.isNotEmpty) {
                    setState(() {
                      scannedValue = value;
                      isScanning = false;
                    });
                  }
                }
              },
            )
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 64,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Contenuto del QR Code:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SelectableText(
                      scannedValue ?? 'Nessun valore',
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // Pulsanti
                    if (scannedValue != null) ...[
                      // Se è un link → mostra "Apri link"
                      if (_isUrl(scannedValue!)) ...[
                        ElevatedButton.icon(
                          onPressed: () => _openLink(scannedValue!),
                          icon: const Icon(Icons.open_in_browser),
                          label: const Text('Apri link'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(220, 48),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Pulsante Copia (sempre presente)
                      ElevatedButton.icon(
                        onPressed: () => _copyToClipboard(scannedValue!),
                        icon: const Icon(Icons.copy),
                        label: const Text('Copia testo'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(220, 48),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          isScanning = true;
                          scannedValue = null;
                        });
                      },
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text('Scansiona un altro QR'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
