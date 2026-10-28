import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DetailLaporanPage extends StatelessWidget {
  final DocumentSnapshot laporan;

  const DetailLaporanPage({
    super.key,
    required this.laporan,
  });

  @override
  Widget build(BuildContext context) {
    final data = laporan.data() as Map<String, dynamic>;

    final namaPelapor = (data['nama_pelapor'] ?? '-').toString();
    final namaGedung = (data['nama_gedung'] ?? '-').toString();
    final lantai = (data['lantai'] ?? '-').toString();
    final namaRuangan = (data['nama_ruangan'] ?? '-').toString();
    final deskripsi = (data['deskripsi'] ?? '-').toString();
    final status = (data['status'] ?? 'Diajukan').toString();
    final alasanPenolakan =
        (data['alasan_penolakan'] ?? '').toString();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Laporan'),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informasi Laporan',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            // =========================
            // INFORMASI LAPORAN
            // =========================

            _infoItem(
              'Nama Pelapor',
              namaPelapor,
              Icons.person,
            ),

            _infoItem(
              'Gedung',
              namaGedung,
              Icons.business,
            ),

            _infoItem(
              'Lantai',
              lantai,
              Icons.layers,
            ),

            _infoItem(
              'Ruangan',
              namaRuangan,
              Icons.meeting_room,
            ),

            _infoItem(
              'Deskripsi',
              deskripsi,
              Icons.description,
            ),

            const SizedBox(height: 10),

            // =========================
            // STATUS
            // =========================

            const Text(
              'Status',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // =========================
            // ALASAN PENOLAKAN
            // =========================

            if (status == 'Ditolak' &&
                alasanPenolakan.isNotEmpty) ...[
              const SizedBox(height: 16),

              const Text(
                'Alasan Penolakan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.red.shade200,
                  ),
                ),
                child: Text(
                  alasanPenolakan,
                  style: const TextStyle(
                    fontSize: 15,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 30),

            // =========================
            // VERIFIKASI
            // =========================

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await laporan.reference.update({
                    'status': 'Diverifikasi',
                  });

                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
                icon: const Icon(Icons.check),
                label: const Text(
                  'Verifikasi Laporan',
                ),
              ),
            ),

            const SizedBox(height: 12),

            // =========================
            // TOLAK
            // =========================

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final controller =
                      TextEditingController();

                  final alasan =
                      await showDialog<String>(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text(
                          'Tolak Laporan',
                        ),
                        content: TextField(
                          controller: controller,
                          maxLines: 3,
                          decoration:
                              const InputDecoration(
                            hintText:
                                'Masukkan alasan penolakan',
                            border:
                                OutlineInputBorder(),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text(
                              'Batal',
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              final text =
                                  controller.text.trim();

                              if (text.isNotEmpty) {
                                Navigator.pop(
                                  context,
                                  text,
                                );
                              }
                            },
                            child: const Text(
                              'Tolak',
                            ),
                          ),
                        ],
                      );
                    },
                  );

                  if (alasan == null ||
                      alasan.trim().isEmpty) {
                    return;
                  }

                  await laporan.reference.update({
                    'status': 'Ditolak',
                    'alasan_penolakan':
                        alasan.trim(),
                  });

                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
                icon: const Icon(Icons.close),
                label: const Text(
                  'Tolak Laporan',
                ),
              ),
            ),

            const SizedBox(height: 12),

            // =========================
            // UPDATE STATUS
            // =========================

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  String statusBaru;

                  if (status == 'Diverifikasi' ||
                      status == 'Diproses' ||
                      status == 'Selesai') {
                    statusBaru = status;
                  } else {
                    statusBaru = 'Diverifikasi';
                  }

                  final hasil =
                      await showDialog<String>(
                    context: context,
                    builder: (context) {
                      return StatefulBuilder(
                        builder: (
                          context,
                          setState,
                        ) {
                          return AlertDialog(
                            title: const Text(
                              'Update Status',
                            ),

                            content:
                                DropdownButton<String>(
                              value: statusBaru,
                              isExpanded: true,

                              items: const [
                                DropdownMenuItem(
                                  value:
                                      'Diverifikasi',
                                  child: Text(
                                    'Diverifikasi',
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'Diproses',
                                  child: Text(
                                    'Diproses',
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'Selesai',
                                  child: Text(
                                    'Selesai',
                                  ),
                                ),
                              ],

                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    statusBaru =
                                        value;
                                  });
                                }
                              },
                            ),

                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(
                                    context,
                                  );
                                },
                                child: const Text(
                                  'Batal',
                                ),
                              ),

                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(
                                    context,
                                    statusBaru,
                                  );
                                },
                                child: const Text(
                                  'Simpan',
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  );

                  if (hasil == null) {
                    return;
                  }

                  await laporan.reference.update({
                    'status': hasil,
                  });

                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
                icon: const Icon(Icons.sync),
                label: const Text(
                  'Update Status',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================
  // WIDGET INFORMASI
  // =========================

  Widget _infoItem(
    String label,
    String value,
    IconData icon,
  ) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 14,
      ),
      padding: const EdgeInsets.all(14),

      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey.shade300,
        ),
        borderRadius:
            BorderRadius.circular(12),
      ),

      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Icon(icon),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.w600,
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