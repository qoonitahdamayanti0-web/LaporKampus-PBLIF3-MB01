
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

const String isiQr = 'RUANGAN|GEDUNG_UTAMA|7|701';

class BuatQrRuanganPage extends StatelessWidget {
  const BuatQrRuanganPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Ruangan LaporKampus'),
        backgroundColor: const Color(0xFF2E7D6F),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'QR Code Ruangan',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              QrImageView(
                data: isiQr,
                version: QrVersions.auto,
                size: 280,
                backgroundColor: Colors.white,
              ),
              const SizedBox(height: 20),
              const Text('Gedung Utama'),
              const Text('Lantai 7 — Ruangan 701'),
              const SizedBox(height: 12),
              const SelectableText(
                isiQr,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
