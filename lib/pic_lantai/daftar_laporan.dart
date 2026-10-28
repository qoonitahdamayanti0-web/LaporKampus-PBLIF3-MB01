import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'detail_laporan.dart';

class DaftarLaporanPage extends StatelessWidget {
  const DaftarLaporanPage({super.key});

  Future<int> ambilLantaiPIC() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return 0;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!doc.exists) return 0;

    return doc.data()?['lantai_tanggung_jawab'] ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Laporan'),
        centerTitle: true,
      ),

      body: FutureBuilder<int>(
        future: ambilLantaiPIC(),

        builder: (context, lantaiSnapshot) {
          if (lantaiSnapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final lantai = lantaiSnapshot.data ?? 0;

          if (lantai == 0) {
            return const Center(
              child: Text('Data lantai PIC tidak ditemukan.'),
            );
          }

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('laporan')
                .where('lantai', isEqualTo: lantai)
                .snapshots(),

            builder: (context, snapshot) {
              if (snapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Terjadi kesalahan: ${snapshot.error}',
                  ),
                );
              }

              final laporan = snapshot.data?.docs ?? [];

              if (laporan.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.assignment_outlined,
                        size: 70,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 15),
                      Text(
                        'Belum ada laporan untuk lantai $lantai',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 17,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: laporan.length,

                itemBuilder: (context, index) {
                  final data =
                      laporan[index].data()
                          as Map<String, dynamic>;

                  final ruangan =
                      data['nama_ruangan'] ?? 'Ruangan';

                  final deskripsi =
                      data['deskripsi'] ?? 'Tidak ada deskripsi';

                  final status =
                      data['status'] ?? 'Diajukan';

               return Card(
  margin: const EdgeInsets.only(bottom: 12),

  child: InkWell(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DetailLaporanPage(
            laporan: laporan[index],
          ),
        ),
      );
    },

    child: ListTile(
      
                      leading: const CircleAvatar(
                        child: Icon(Icons.report_problem),
                      ),

                      title: Text(
                        ruangan,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      subtitle: Text(
                        deskripsi,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),

                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius:
                              BorderRadius.circular(12),
                        ),

                        child: Text(
                          status,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => DetailLaporanPage(
        laporan: laporan[index],
      ),
    ),
  );
},
                    ),
                  ),
                  ); // Card
                },
              );
            },
          );
        },
      ),
    );
  }
}