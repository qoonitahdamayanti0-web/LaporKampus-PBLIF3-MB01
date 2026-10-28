import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'detail_laporan_pelapor.dart';

class RiwayatLaporanPage extends StatelessWidget {
  const RiwayatLaporanPage({super.key});

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
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Silakan login terlebih dahulu.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Laporan'),
        backgroundColor: const Color(0xFF2E7D6F),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('laporan')
            .where('pelapor_uid', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Gagal memuat riwayat laporan.'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final dokumen = snapshot.data?.docs ?? [];

          if (dokumen.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Belum ada laporan.\n'
                  'Laporan yang kamu kirim akan muncul di sini.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final laporan = [...dokumen];
          laporan.sort((a, b) {
            final waktuA = a.data()['created_at'];
            final waktuB = b.data()['created_at'];

            final tanggalA = waktuA is Timestamp
                ? waktuA.toDate()
                : DateTime(2000);
            final tanggalB = waktuB is Timestamp
                ? waktuB.toDate()
                : DateTime(2000);

            return tanggalB.compareTo(tanggalA);
          });

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: laporan.length,
            itemBuilder: (context, index) {
              final data = laporan[index].data();
              final judul = data['judul']?.toString() ??
                  'Tanpa judul';
              final gedung =
                  data['nama_gedung']?.toString() ?? '-';
              final lantai = data['lantai']?.toString() ?? '-';
              final ruangan =
                  data['nama_ruangan']?.toString() ?? '-';
              final status =
                  data['status']?.toString() ?? 'Diajukan';

              final warna = _warnaStatus(status);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => DetailLaporanPelapor(
        laporanId: laporan[index].id,
      ),
    ),
  );
},
                  contentPadding: const EdgeInsets.all(14),
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE4F1EE),
                    child: Icon(
                      Icons.assignment_outlined,
                      color: Color(0xFF2E7D6F),
                    ),
                  ),
                  title: Text(
                    judul,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Gedung: $gedung'),
                        Text('Lantai: $lantai'),
                        Text('Ruangan: $ruangan'),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: warna.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              color: warna,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (status == 'Ditolak' &&
                            (data['alasan_penolakan'] ??
                                    data['alasan_ditolak']) !=
                                null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'Alasan: ${data['alasan_penolakan'] ?? data['alasan_ditolak']}',
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}