import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'daftar_laporan.dart';
import 'monitoring.dart';

class PicLantaiHome extends StatefulWidget {
  const PicLantaiHome({super.key});

  @override
  State<PicLantaiHome> createState() => _PicLantaiHomeState();
}

class _PicLantaiHomeState extends State<PicLantaiHome> {
  // Warna identitas LaporKampus
  static const Color warnaUtama = Color(0xFF2E7D6F);
  static const Color warnaMuda = Color(0xFFE5F2EF);

  String namaPic = 'PIC Lantai';
  int lantai = 0;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _ambilDataPic();
  }

  Future<void> _ambilDataPic() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data();

        if (data != null) {
          setState(() {
            namaPic =
                (data['nama'] ?? 'PIC Lantai').toString();

            lantai =
                data['lantai_tanggung_jawab'] ?? 0;

            loading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();

    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/',
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dashboard PIC Lantai',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,

        // Warna identitas LaporKampus
        backgroundColor: warnaUtama,
        foregroundColor: Colors.white,
      ),

      body: loading
          ? const Center(
              child: CircularProgressIndicator(
                color: warnaUtama,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  // =========================
                  // HEADER
                  // =========================

                  const Text(
                    'Halo, PIC Lantai 👋',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: warnaUtama,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Halo $namaPic',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade700,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    'Bertanggung jawab atas Lantai $lantai',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade600,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // =========================
                  // DAFTAR LAPORAN
                  // =========================

                  _menuCard(
                    icon: Icons.assignment,
                    title: 'Daftar Laporan',
                    subtitle:
                        'Lihat laporan fasilitas di lantai $lantai',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const DaftarLaporanPage(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // =========================
                  // MONITORING
                  // =========================

                  _menuCard(
                    icon: Icons.bar_chart,
                    title: 'Monitoring',
                    subtitle:
                        'Pantau status laporan lantai $lantai',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const MonitoringPage(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // =========================
                  // LOGOUT
                  // =========================

                  _menuCard(
                    icon: Icons.logout,
                    title: 'Logout',
                    subtitle:
                        'Keluar dari akun PIC Lantai',
                    onTap: _logout,
                  ),
                ],
              ),
            ),
    );
  }

  // =========================
  // MENU CARD
  // =========================

  Widget _menuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),

      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,

        child: Padding(
          padding: const EdgeInsets.all(18),

          child: Row(
            children: [
              // =========================
              // ICON
              // =========================

              Container(
                width: 52,
                height: 52,

                decoration: BoxDecoration(
                  color: warnaMuda,
                  borderRadius:
                      BorderRadius.circular(14),
                ),

                child: Icon(
                  icon,
                  size: 28,
                  color: warnaUtama,
                ),
              ),

              const SizedBox(width: 16),

              // =========================
              // TEXT
              // =========================

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              // =========================
              // ARROW
              // =========================

              const Icon(
                Icons.arrow_forward_ios,
                size: 18,
                color: warnaUtama,
              ),
            ],
          ),
        ),
      ),
    );
  }
}