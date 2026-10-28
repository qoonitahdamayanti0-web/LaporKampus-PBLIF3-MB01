import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';
import 'pelapor/pelapor_home.dart';
import 'pic_lantai/pic_lantai_home.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const LaporKampusApp());
}

class LaporKampusApp extends StatelessWidget {
  const LaporKampusApp({super.key});

  @override
  Widget build(BuildContext context) {
   return MaterialApp(
  debugShowCheckedModeBanner: false,
  title: 'LaporKampus',

  theme: ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF2E7D6F),
    ),
    useMaterial3: true,
  ),

  // DAFTAR ROUTE HALAMAN

  home: const LoginPage(),
);
  }
}

// ======================================================
// LOGIN
// ======================================================

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  String selectedRole = 'Pelapor';
  bool hidePassword = true;
  bool isLoading = false;

  Future<void> login() async {
    final email = usernameController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email dan password harus diisi.'),
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      debugPrint('========== LOGIN DIMULAI ==========');
      debugPrint('EMAIL: $email');

      // 1. LOGIN FIREBASE AUTHENTICATION
      final credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
        email: email,
        password: password,
      )
          .timeout(
        const Duration(seconds: 20),
      );

      final uid = credential.user!.uid;

      debugPrint('AUTH BERHASIL');
      debugPrint('UID AUTH: $uid');

      // 2. CARI DATA USER BERDASARKAN EMAIL
      final usersRef =
          FirebaseFirestore.instance.collection('users');

      final userQuery = await usersRef
          .where('email', isEqualTo: email)
          .limit(1)
          .get()
          .timeout(
        const Duration(seconds: 20),
      );

      debugPrint(
        'JUMLAH DOKUMEN BERDASARKAN EMAIL: '
        '${userQuery.docs.length}',
      );

      // 3. JIKA DATA USER TIDAK DITEMUKAN
      if (userQuery.docs.isEmpty) {
        await FirebaseAuth.instance.signOut();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Data pengguna belum ditemukan di Firestore. '
              'Pastikan email terdaftar di koleksi users.',
            ),
          ),
        );
        return;
      }

      // 4. AMBIL DATA USER
      final userDoc = userQuery.docs.first;
      final data = userDoc.data();

      final role = data['role']
          ?.toString()
          .trim()
          .toLowerCase();

      final nama = data['nama']?.toString() ?? email;

      debugPrint('DOKUMEN USER: ${userDoc.id}');
      debugPrint('DATA USER: $data');
      debugPrint('ROLE USER: $role');

      if (!mounted) return;

      // 5. HALAMAN PIC LANTAI
      if (role == 'pic_lantai') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const PicLantaiHome(),
          ),
        );
        return;
      }

      // 6. HALAMAN PELAPOR
      if (role == 'pelapor') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DashboardPage(
              username: nama,
              role: 'Pelapor',
            ),
          ),
        );
        return;
      }

      // 7. ROLE TIDAK DIKENALI
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Role pengguna tidak dikenali: $role',
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('FIREBASE AUTH ERROR: ${e.code}');
      debugPrint('PESAN: ${e.message}');

      String pesan = 'Login gagal.';

      if (e.code == 'invalid-credential' ||
          e.code == 'invalid-login-credentials') {
        pesan = 'Email atau password salah.';
      } else if (e.code == 'user-not-found') {
        pesan = 'Akun tidak ditemukan.';
      } else if (e.code == 'wrong-password') {
        pesan = 'Password salah.';
      } else if (e.code == 'invalid-email') {
        pesan = 'Format email tidak valid.';
      } else if (e.code == 'network-request-failed') {
        pesan = 'Tidak dapat terhubung ke Firebase.';
      } else if (e.code == 'too-many-requests') {
        pesan =
            'Terlalu banyak percobaan login. Coba lagi nanti.';
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(pesan),
        ),
      );
    } on TimeoutException {
      debugPrint('LOGIN TIMEOUT');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Koneksi ke Firebase terlalu lama. '
            'Periksa internet HP.',
          ),
        ),
      );
    } catch (e) {
      debugPrint('LOGIN ERROR: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F7),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // LOGO
                Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D6F),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.campaign_rounded,
                    color: Colors.white,
                    size: 45,
                  ),
                ),

                const SizedBox(height: 18),

                const Text(
                  'LaporKampus',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF245F55),
                  ),
                ),

                const SizedBox(height: 7),

                const Text(
                  'Pelaporan dan Monitoring\nFasilitas Kampus',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 30),

                // CARD LOGIN
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Masuk',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 5),

                      const Text(
                        'Masuk untuk melanjutkan ke LaporKampus',
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),

                      const SizedBox(height: 25),

                      const Text(
                        'Email',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 8),

                      TextField(
                        controller: usernameController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: 'Masukkan email',
                          prefixIcon: const Icon(
                            Icons.email_outlined,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF5F7F7),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      const Text(
                        'Password',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 8),

                      TextField(
                        controller: passwordController,
                        obscureText: hidePassword,
                        decoration: InputDecoration(
                          hintText: 'Masukkan password',
                          prefixIcon: const Icon(
                            Icons.lock_outline,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              hidePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () {
                              setState(() {
                                hidePassword = !hidePassword;
                              });
                            },
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF5F7F7),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      const Text(
                        'Masuk sebagai',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 8),

                      DropdownButtonFormField<String>(
                        initialValue: selectedRole,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(
                            Icons.supervisor_account_outlined,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF5F7F7),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Pelapor',
                            child: Text('Pelapor'),
                          ),
                          DropdownMenuItem(
                            value: 'PIC Lantai',
                            child: Text('PIC Lantai'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              selectedRole = value;
                            });
                          }
                        },
                      ),

                      const SizedBox(height: 25),

                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D6F),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text(
                                  'MASUK',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                const Text(
                  'LaporKampus • Politeknik Negeri Batam',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 5),

                const Text(
                  'NIM: 3312511015',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
