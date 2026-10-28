
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

import 'scan_qr_page.dart';

const Color warnaUtama = Color(0xFF2E7D6F);

class TambahLaporanPage extends StatefulWidget {
  const TambahLaporanPage({super.key});

  @override
  State<TambahLaporanPage> createState() => _TambahLaporanPageState();
}

class _TambahLaporanPageState extends State<TambahLaporanPage> {
  final _formKey = GlobalKey<FormState>();
  final _judulController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  // Konfigurasi Cloudinary
  static const String _cloudName = 'yd6fqogz';
  static const String _uploadPreset = 'laporkampus_upload';

  String? _namaGedung;
  int? _lantai;
  String? _namaRuangan;

  File? _fotoKerusakan;
  bool _isLoading = false;

  // Memilih foto dari kamera atau galeri
  Future<void> _pilihFoto(ImageSource source) async {
    try {
      final XFile? foto = await _picker.pickImage(
        source: source,
        imageQuality: 75,
      );

      if (foto != null && mounted) {
        setState(() {
          _fotoKerusakan = File(foto.path);
        });
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memilih foto: $e')),
      );
    }
  }

  // Scan QR ruangan
  Future<void> _scanQR() async {
    final hasil = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => ScanQrPage(),
      ),
    );

    if (!mounted || hasil == null) return;

    setState(() {
      _namaGedung = hasil['nama_gedung']?.toString();

      _lantai = hasil['lantai'] is int
          ? hasil['lantai'] as int
          : int.tryParse(hasil['lantai'].toString());

      _namaRuangan = hasil['nama_ruangan']?.toString();
    });
  }

  // Upload foto ke Cloudinary
  Future<String> _uploadFotoCloudinary(File foto) async {
    final uri = Uri.parse(
  'https://api.cloudinary.com/v1_1/yd6fqogz/image/upload',
);

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = _uploadPreset
      ..files.add(
        await http.MultipartFile.fromPath('file', foto.path),
      );

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Upload Cloudinary gagal: $responseBody');
    }

    final data = jsonDecode(responseBody) as Map<String, dynamic>;
    final secureUrl = data['secure_url'] as String?;

    if (secureUrl == null || secureUrl.isEmpty) {
      throw Exception('URL foto tidak ditemukan dari Cloudinary.');
    }

    return secureUrl;
  }

  // Kirim laporan
  Future<void> _kirimLaporan() async {
    if (!_formKey.currentState!.validate()) return;

    if (_namaGedung == null ||
        _lantai == null ||
        _namaRuangan == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan scan QR ruangan terlebih dahulu.'),
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan login terlebih dahulu.'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Foto bersifat opsional.
      String fotoUrl = '';

      if (_fotoKerusakan != null) {
        fotoUrl = await _uploadFotoCloudinary(_fotoKerusakan!);
      }

      // Simpan laporan ke Firestore.
      await FirebaseFirestore.instance.collection('laporan').add({
        'judul': _judulController.text.trim(),
        'deskripsi': _deskripsiController.text.trim(),
        'nama_gedung': _namaGedung,
        'lantai': _lantai,
        'nama_ruangan': _namaRuangan,
        'status': 'Diajukan',
        'pelapor_uid': user.uid,
        'created_at': FieldValue.serverTimestamp(),
        'foto_url': fotoUrl,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Laporan berhasil dikirim!'),
          backgroundColor: warnaUtama,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengirim laporan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _judulController.dispose();
    _deskripsiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Laporan'),
        backgroundColor: warnaUtama,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'Laporkan Fasilitas Kampus',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Scan QR ruangan, tambahkan foto, '
                'lalu jelaskan kerusakannya.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),

              // Tombol scan QR
              OutlinedButton.icon(
                onPressed: _isLoading ? null : _scanQR,
                icon: const Icon(
                  Icons.qr_code_scanner,
                  color: warnaUtama,
                ),
                label: const Text('Scan QR Ruangan'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: warnaUtama,
                  side: const BorderSide(color: warnaUtama),
                ),
              ),

              const SizedBox(height: 12),

              if (_namaRuangan != null)
                Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.location_on,
                      color: warnaUtama,
                    ),
                    title: Text(_namaRuangan!),
                    subtitle: Text(
                      'Gedung: ${_namaGedung ?? "-"}\n'
                      'Lantai: ${_lantai ?? "-"}',
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              const Text(
                'Foto Kerusakan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),

              if (_fotoKerusakan != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _fotoKerusakan!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _isLoading
                        ? null
                        : () {
                            setState(() {
                              _fotoKerusakan = null;
                            });
                          },
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Hapus Foto'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ),
              ] else
                Container(
                  height: 140,
                  decoration: BoxDecoration(
                    color: warnaUtama.withValues(alpha: 0.05),
                    border: Border.all(color: warnaUtama),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_a_photo_outlined,
                          size: 42,
                          color: warnaUtama,
                        ),
                        SizedBox(height: 8),
                        Text('Belum ada foto kerusakan'),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isLoading
                          ? null
                          : () => _pilihFoto(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Ambil Foto'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: warnaUtama,
                        side: const BorderSide(color: warnaUtama),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isLoading
                          ? null
                          : () => _pilihFoto(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Pilih Galeri'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: warnaUtama,
                        side: const BorderSide(color: warnaUtama),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              TextFormField(
                controller: _judulController,
                decoration: const InputDecoration(
                  labelText: 'Judul Laporan',
                  hintText: 'Contoh: Lampu ruangan mati',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Judul laporan wajib diisi.';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _deskripsiController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi Kerusakan',
                  hintText:
                      'Jelaskan kondisi fasilitas yang bermasalah...',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Deskripsi laporan wajib diisi.';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 28),

              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _kirimLaporan,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send),
                  label: Text(
                    _isLoading ? 'Mengirim...' : 'Kirim Laporan',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: warnaUtama,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
