import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DetailLaporanPelapor extends StatelessWidget {
  final String laporanId;

  const DetailLaporanPelapor({
    super.key,
    required this.laporanId,
  });

  Color _warnaStatus(String status) {
    switch (status) {
      case 'Selesai':
        return Colors.green;
      case 'Diproses':
        return Colors.orange;
      case 'Diverifikasi':
        return Colors.blue;
      case 'Ditolak':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Laporan'),
        backgroundColor: const Color(0xFF2E7D6F),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('laporan')
            .doc(laporanId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Gagal memuat detail laporan.'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text('Data laporan tidak ditemukan.'),
            );
          }

          final data = snapshot.data!.data()!;
          final judul =
              data['judul']?.toString() ?? 'Tanpa judul';
          final deskripsi =
              data['deskripsi']?.toString() ?? '-';
          final gedung =
              data['nama_gedung']?.toString() ?? '-';
          final lantai = data['lantai']?.toString() ?? '-';
          final ruangan =
              data['nama_ruangan']?.toString() ?? '-';
          final status =
              data['status']?.toString() ?? 'Diajukan';
          final alasan = data['alasan_penolakan'] ??
              data['alasan_ditolak'];
          final fotoUrl = data['foto_url']?.toString() ?? '';

          final warna = _warnaStatus(status);

          final waktu = data['created_at'];
          final tanggal = waktu is Timestamp
              ? waktu.toDate()
              : null;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFE4F1EE),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.assignment_outlined,
                      size: 40,
                      color: Color(0xFF2E7D6F),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      judul,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: warna.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: warna,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Informasi Lokasi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              _itemDetail(Icons.business_outlined, 'Gedung', gedung),
              _itemDetail(Icons.layers_outlined, 'Lantai', lantai),
              _itemDetail(Icons.meeting_room_outlined, 'Ruangan', ruangan),

              const SizedBox(height: 24),

              const Text(
                'Deskripsi Kerusakan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),

              Text(
                deskripsi,
                style: const TextStyle(fontSize: 15),
              ),

              if (fotoUrl.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Text(
                  'Foto Laporan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    fotoUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Text('Foto gagal ditampilkan.');
                    },
                  ),
                ),
              ],

              if (tanggal != null) ...[
                const SizedBox(height: 24),
                _itemDetail(
                  Icons.calendar_today_outlined,
                  'Tanggal Laporan',
                  '${tanggal.day.toString().padLeft(2, '0')}/'
                      '${tanggal.month.toString().padLeft(2, '0')}/'
                      '${tanggal.year}',
                ),
              ],

              if (status == 'Ditolak') ...[
                const SizedBox(height: 24),
                const Text(
                  'Alasan Penolakan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  alasan?.toString() ??
                      'Alasan penolakan belum tersedia.',
                ),
              ],

              const SizedBox(height: 24),

              const Text(
                'Alur Status Laporan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              _itemStatus('Diajukan', status),
              _itemStatus('Diverifikasi', status),
              _itemStatus('Diproses', status),
              _itemStatus('Selesai', status),

              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }

  Widget _itemDetail(
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF2E7D6F)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemStatus(String namaStatus, String statusSekarang) {
    const urutan = [
      'Diajukan',
      'Diverifikasi',
      'Diproses',
      'Selesai',
    ];

    final indeksSekarang = urutan.indexOf(statusSekarang);
    final indeksItem = urutan.indexOf(namaStatus);

    final aktif = statusSekarang == 'Ditolak'
        ? namaStatus == 'Diajukan'
        : indeksSekarang >= 0 && indeksItem <= indeksSekarang;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            aktif ? Icons.check_circle : Icons.circle_outlined,
            color: aktif ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 12),
          Text(
            namaStatus,
            style: TextStyle(
              color: aktif ? Colors.green.shade800 : Colors.grey,
              fontWeight: aktif ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (namaStatus == statusSekarang) ...[
            const SizedBox(width: 8),
            const Text(
              '(Status saat ini)',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}