
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LaporanService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _laporanRef =>
      _firestore.collection('laporan');

  // Menambahkan laporan baru
  Future<String> tambahLaporan({
    required String judul,
    required String deskripsi,
    required String namaGedung,
    required int lantai,
    required String namaRuangan,
    String fotoUrl = '',
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('Pengguna belum login.');
    }

    final dokumen = await _laporanRef.add({
      'judul': judul.trim(),
      'deskripsi': deskripsi.trim(),
      'nama_gedung': namaGedung,
      'lantai': lantai,
      'nama_ruangan': namaRuangan,
      'status': 'Diajukan',
      'pelapor_uid': user.uid,
      'created_at': FieldValue.serverTimestamp(),
      'foto_url': fotoUrl,
    });

    return dokumen.id;
  }

  // Mengambil laporan berdasarkan ID
  Future<DocumentSnapshot<Map<String, dynamic>>> ambilDetail(
    String laporanId,
  ) {
    return _laporanRef.doc(laporanId).get();
  }

  // Memantau seluruh laporan secara real-time
  Stream<QuerySnapshot<Map<String, dynamic>>> pantauSemuaLaporan() {
    return _laporanRef
        .orderBy('created_at', descending: true)
        .snapshots();
  }

  // Memantau laporan milik Pelapor yang sedang login
  Stream<QuerySnapshot<Map<String, dynamic>>> pantauLaporanPelapor(
    String pelaporUid,
  ) {
    return _laporanRef
        .where('pelapor_uid', isEqualTo: pelaporUid)
        .snapshots();
  }

  // Memantau laporan berdasarkan lantai tanggung jawab PIC
  Stream<QuerySnapshot<Map<String, dynamic>>> pantauLaporanPerLantai(
    int lantai,
  ) {
    return _laporanRef
        .where('lantai', isEqualTo: lantai)
        .snapshots();
  }

  // Mengubah status laporan
  Future<void> ubahStatus({
    required String laporanId,
    required String status,
    String? alasanPenolakan,
  }) async {
    const statusValid = [
      'Diajukan',
      'Diverifikasi',
      'Diproses',
      'Selesai',
      'Ditolak',
    ];

    if (!statusValid.contains(status)) {
      throw Exception('Status laporan tidak valid.');
    }

    final data = <String, dynamic>{
      'status': status,
    };

    if (status == 'Ditolak') {
      if (alasanPenolakan == null ||
          alasanPenolakan.trim().isEmpty) {
        throw Exception(
          'Alasan penolakan wajib diisi.',
        );
      }

      data['alasan_penolakan'] =
          alasanPenolakan.trim();
    } else {
      data['alasan_penolakan'] = FieldValue.delete();
    }

    await _laporanRef.doc(laporanId).update(data);
  }
}
