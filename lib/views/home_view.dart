import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final AuthService _authService = AuthService();
  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final data = await _authService.getUserData();
    setState(() {
      userData = data;
    });
  }

  Future<void> _logout() async {
    await _authService.signOut();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginView()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
        actions: [IconButton(onPressed: _logout, icon: Icon(Icons.logout))],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selamat Datang!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            if (userData != null) ...[
              Text('Nama: ${userData!['namaLengkap'] ?? 'N/A'}'),
              SizedBox(height: 8),
              Text('Kode KKN: ${userData!['kodeKkn'] ?? 'N/A'}'),
              SizedBox(height: 8),
              Text('Email: ${userData!['email'] ?? 'N/A'}'),
            ] else
              CircularProgressIndicator(),
            SizedBox(height: 40),
            Text('Aplikasi Manajemen KKN', style: TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
