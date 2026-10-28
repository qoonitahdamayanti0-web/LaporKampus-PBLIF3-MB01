
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'tambah_laporan_page.dart';
import 'riwayat_laporan_page.dart';

class DashboardPage extends StatefulWidget {
  final String username;
  final String role;

  const DashboardPage({
    super.key,
    required this.username,
    required this.role,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int selectedIndex = 0;

  final Color warnaUtama = const Color(0xFF2E7D6F);
  final Color warnaLatar = const Color(0xFFF5F8F7);

  // Mengambil laporan milik pengguna yang sedang login.
  Stream<QuerySnapshot<Map<String, dynamic>>> get laporanStream {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection('laporan')
        .where('pelapor_uid', isEqualTo: user.uid)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: warnaLatar,
      appBar: AppBar(
        backgroundColor: warnaUtama,
        foregroundColor: Colors.white,
        title: const Text(
          'LaporKampus',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none),
          ),
        ],
      ),
      body: IndexedStack(
        index: selectedIndex,
        children: [
          dashboard(),
          const RiwayatLaporanPage(),
          profil(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: 'Laporan',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
      floatingActionButton: widget.role == 'Pelapor'
          ? FloatingActionButton.extended(
              onPressed: bukaTambahLaporan,
              backgroundColor: warnaUtama,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Lapor'),
            )
          : null,
    );
  }

  // Membuka halaman tambah laporan.
  Future<void> bukaTambahLaporan() async {
    final hasil = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const TambahLaporanPage(),
      ),
    );

    if (!mounted) return;

    if (hasil == true) {
      setState(() {
        selectedIndex = 1;
      });
    }
  }

  // BERANDA: menggunakan data Firestore, bukan data dummy.
  Widget dashboard() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: laporanStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Gagal memuat laporan.\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: warnaUtama),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        final reports = docs.map((doc) {
          final data = doc.data();

          final gedung =
              (data['nama_gedung'] ?? data['gedung'] ?? '').toString();
          final lantai = (data['lantai'] ?? '').toString();
          final ruangan =
              (data['nama_ruangan'] ?? data['ruangan'] ?? '').toString();

          String lokasi = gedung;

          if (lantai.isNotEmpty) {
            lokasi += lokasi.isEmpty ? 'Lantai $lantai' : ' - Lantai $lantai';
          }

          if (ruangan.isNotEmpty) {
            lokasi += ' - $ruangan';
          }

          return <String, dynamic>{
            'id': doc.id,
            'title': (data['judul'] ?? 'Laporan tanpa judul').toString(),
            'location': lokasi.isEmpty ? 'Lokasi belum tersedia' : lokasi,
            'status': (data['status'] ?? 'Diajukan').toString(),
            'created_at': data['created_at'],
          };
        }).toList();

        // Urutkan laporan terbaru berdasarkan created_at.
        reports.sort((a, b) {
          final waktuA = a['created_at'];
          final waktuB = b['created_at'];

          final dateA = waktuA is Timestamp
              ? waktuA.toDate()
              : DateTime.fromMillisecondsSinceEpoch(0);

          final dateB = waktuB is Timestamp
              ? waktuB.toDate()
              : DateTime.fromMillisecondsSinceEpoch(0);

          return dateB.compareTo(dateA);
        });

        final total = reports.length;
        final diproses = reports.where((r) {
          final status = r['status'].toString().toLowerCase();
          return status == 'diproses';
        }).length;

        final selesai = reports.where((r) {
          final status = r['status'].toString().toLowerCase();
          return status == 'selesai';
        }).length;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Halo, ${widget.username} 👋',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                widget.role,
                style: TextStyle(
                  color: warnaUtama,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),

              // KARTU BUAT LAPORAN
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: warnaUtama,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ada fasilitas bermasalah?',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Laporkan kerusakan fasilitas kampus '
                            'dengan mudah.',
                            style: TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 14),
                          if (widget.role == 'Pelapor')
                            ElevatedButton(
                              onPressed: bukaTambahLaporan,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: warnaUtama,
                              ),
                              child: const Text('Buat Laporan'),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(
                      Icons.campaign_rounded,
                      color: Colors.white,
                      size: 55,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              const Text(
                'Ringkasan Laporan',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  statistik(
                    '$total',
                    'Total',
                    Icons.assignment,
                  ),
                  const SizedBox(width: 10),
                  statistik(
                    '$diproses',
                    'Diproses',
                    Icons.sync,
                  ),
                  const SizedBox(width: 10),
                  statistik(
                    '$selesai',
                    'Selesai',
                    Icons.check_circle,
                  ),
                ],
              ),

              const SizedBox(height: 25),

              const Text(
                'Laporan Terbaru',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              if (reports.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.assignment_outlined,
                        size: 42,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Belum ada laporan',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Laporan yang kamu kirim akan muncul di sini.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              else
                ...reports.take(3).map(
                  (report) => kartuLaporan(report),
                ),
            ],
          ),
        );
      },
    );
  }

  // KARTU STATISTIK
  Widget statistik(
    String angka,
    String nama,
    IconData icon,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 17,
          horizontal: 5,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: warnaUtama),
            const SizedBox(height: 7),
            Text(
              angka,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              nama,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // MENU LAPORAN
  Widget laporan() {
    return const RiwayatLaporanPage();
  }

  // KARTU LAPORAN: tetap memakai gaya UI lama.
  Widget kartuLaporan(Map<String, dynamic> report) {
    final status = (report['status'] ?? 'Diajukan').toString();

    Color statusColor;

    if (status.toLowerCase() == 'selesai') {
      statusColor = Colors.green;
    } else if (status.toLowerCase() == 'diproses') {
      statusColor = Colors.orange;
    } else if (status.toLowerCase() == 'ditolak') {
      statusColor = Colors.red;
    } else if (status.toLowerCase() == 'diverifikasi') {
      statusColor = Colors.blue;
    } else {
      statusColor = Colors.blue;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFE4F1EE),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.build_outlined,
              color: warnaUtama,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report['title']?.toString() ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  report['location']?.toString() ?? '',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right,
            color: Colors.grey,
          ),
        ],
      ),
    );
  }

  // PROFIL
  Widget profil() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const CircleAvatar(
            radius: 50,
            backgroundColor: Color(0xFFE4F1EE),
            child: Icon(
              Icons.person,
              size: 55,
              color: Color(0xFF2E7D6F),
            ),
          ),
          const SizedBox(height: 15),
          Text(
            widget.username,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            widget.role,
            style: TextStyle(color: warnaUtama),
          ),
          const SizedBox(height: 25),
          infoProfil(
            Icons.badge_outlined,
            'Nama',
            widget.username,
          ),
          infoProfil(
            Icons.school_outlined,
            'NIM',
            '3312511015',
          ),
          infoProfil(
            Icons.work_outline,
            'Role',
            widget.role,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.logout),
              label: const Text('Keluar'),
            ),
          ),
        ],
      ),
    );
  }

  // INFORMASI PROFIL
  Widget infoProfil(
    IconData icon,
    String label,
    String value,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: warnaUtama),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 3),
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
}
