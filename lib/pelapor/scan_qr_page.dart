import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScanQrPage extends StatefulWidget {
  const ScanQrPage({super.key});

  @override
  State<ScanQrPage> createState() => _ScanQrPageState();
}

class _ScanQrPageState extends State<ScanQrPage> {
  final MobileScannerController _controller =
      MobileScannerController();

  bool _hasScanned = false;


void _onDetect(BarcodeCapture capture) {
  if (_hasScanned) return;

  for (final barcode in capture.barcodes) {
    final value = barcode.rawValue;
    if (value == null || value.trim().isEmpty) continue;

    final cleanedValue = value
        .replaceFirst('\uFEFF', '')
        .trim();

    debugPrint('ISI QR TERBACA: "$cleanedValue"');

    final parts = cleanedValue
        .split('|')
        .map((part) => part.trim())
        .toList();

    debugPrint('BAGIAN QR: $parts');

    if (parts.length != 4 ||
        parts[0].toUpperCase() != 'RUANGAN') {
      continue;
    }

    final namaGedung = parts[1];

    final teksLantai = parts[2].replaceFirst(
      RegExp(r'^(LT\.?|LANTAI)\s*', caseSensitive: false),
      '',
    );

    final lantai = int.tryParse(teksLantai);

    final namaRuangan = parts[3].replaceFirst(
      RegExp(r'^RUANGAN\s*', caseSensitive: false),
      '',
    ).trim();

    if (namaGedung.isEmpty ||
        lantai == null ||
        lantai < 1 ||
        namaRuangan.isEmpty) {
      continue;
    }

    _hasScanned = true;

    debugPrint('QR VALID');
    debugPrint('GEDUNG: $namaGedung');
    debugPrint('LANTAI: $lantai');
    debugPrint('RUANGAN: $namaRuangan');

    Navigator.pop(context, {
      'nama_gedung': namaGedung.replaceAll('_', ' '),
      'lantai': lantai,
      'nama_ruangan': 'Ruangan $namaRuangan',
    });
    return;
  }

  _tampilkanPesanTidakValid();
}

void _tampilkanPesanTidakValid() {
  if (_hasScanned || !mounted) return;

  _hasScanned = true;

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text(
        'QR tidak valid. Silakan scan QR ruangan LaporKampus.',
      ),
      duration: Duration(seconds: 2),
    ),
  );

  Future.delayed(const Duration(seconds: 2), () {
    if (mounted) {
      _hasScanned = false;
    }
  });
}


  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan QR Ruangan'),
        backgroundColor: const Color(0xFF2E7D6F),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFF2E7D6F),
                  width: 4,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          Positioned(
            bottom: 45,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Arahkan kamera ke QR Code ruangan.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}