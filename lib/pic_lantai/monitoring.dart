import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MonitoringPage extends StatefulWidget {
  const MonitoringPage({super.key});

  @override
  State<MonitoringPage> createState() => _MonitoringPageState();
}

class _MonitoringPageState extends State<MonitoringPage> {
  int lantai = 0;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _ambilDataPic();
  }

  Future<void> _ambilDataPic() async {
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
          lantai = data['lantai_tanggung_jawab'] ?? 0;
          loading = false;
        });
      }
    }
  }

  Stream<QuerySnapshot> _streamLaporan() {
    return FirebaseFirestore.instance
        .collection('laporan')
        .where('lantai', isEqualTo: lantai)
        .snapshots();
  }

  int _hitungStatus(
    List<QueryDocumentSnapshot> laporan,
    String status,
  ) {
    return laporan.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['status'] == status;
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monitoring'),
        centerTitle: true,
      ),

      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : StreamBuilder<QuerySnapshot>(
              stream: _streamLaporan(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      'Terjadi kesalahan saat mengambil data.',
                    ),
                  );
                }

                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final laporan =
                    snapshot.data?.docs ?? [];

                final total = laporan.length;

                final diajukan = _hitungStatus(
                  laporan,
                  'Diajukan',
                );

                final diverifikasi = _hitungStatus(
                  laporan,
                  'Diverifikasi',
                );

                final diproses = _hitungStatus(
                  laporan,
                  'Diproses',
                );

                final selesai = _hitungStatus(
                  laporan,
                  'Selesai',
                );

                final ditolak = _hitungStatus(
                  laporan,
                  'Ditolak',
                );

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Monitoring Laporan',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'Lantai $lantai',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),

                      const SizedBox(height: 25),

                      // TOTAL
                      _statusCard(
                        'Total Laporan',
                        total,
                        Icons.assignment,
                      ),

                      const SizedBox(height: 12),

                      // DIAJUKAN
                      _statusCard(
                        'Diajukan',
                        diajukan,
                        Icons.pending_actions,
                      ),

                      const SizedBox(height: 12),

                      // DIVERIFIKASI
                      _statusCard(
                        'Diverifikasi',
                        diverifikasi,
                        Icons.verified,
                      ),

                      const SizedBox(height: 12),

                      // DIPROSES
                      _statusCard(
                        'Diproses',
                        diproses,
                        Icons.autorenew,
                      ),

                      const SizedBox(height: 12),

                      // SELESAI
                      _statusCard(
                        'Selesai',
                        selesai,
                        Icons.check_circle,
                      ),

                      const SizedBox(height: 12),

                      // DITOLAK
                      _statusCard(
                        'Ditolak',
                        ditolak,
                        Icons.cancel,
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _statusCard(
    String title,
    int jumlah,
    IconData icon,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey.shade300,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 32,
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          Text(
            jumlah.toString(),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}