import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:manajemensekolah/services/api_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isLoading = false;
  bool _serverConnected = true;
  bool _showSchoolSelection = false;
  List<dynamic> _sekolahList = [];
  Map<String, dynamic>? _userData;
  String? _selectedSekolahId;

  @override
  void initState() {
    super.initState();
    _checkServerConnection();
  }

  Future<void> _checkServerConnection() async {
    try {
      await ApiService.checkHealth();
      setState(() {
        _serverConnected = true;
      });
    } catch (e) {
      setState(() {
        _serverConnected = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Server tidak terhubung. Pastikan backend berjalan.'),
        ),
      );
    }
  }

  Future<void> login() async {
    if (!_serverConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Server tidak terhubung. Tidak dapat login.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final String email = emailController.text.trim();
    final String password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email dan password harus diisi')),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final responseData = await ApiService.login(
        email, 
        password,
        sekolahId: _selectedSekolahId,
      );

      // Jika perlu memilih sekolah
      if (responseData['pilih_sekolah'] == true) {
        setState(() {
          _showSchoolSelection = true;
          _sekolahList = responseData['sekolah_list'];
          _userData = responseData['user'];
          _isLoading = false;
        });
        return;
      }

      // Simpan token dan user data ke shared preferences
      await _saveLoginData(responseData);

      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        '/${responseData['user']['role']}',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Login berhasil! Selamat datang ${responseData['user']['nama']}',
          ),
        ),
      );
    } catch (error) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveLoginData(Map<String, dynamic> responseData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', responseData['token']);
    await prefs.setString('user', json.encode(responseData['user']));
  }

  Future<void> _selectSchool(String sekolahId) async {
    setState(() {
      _isLoading = true;
      _selectedSekolahId = sekolahId;
    });

    try {
      final responseData = await ApiService.login(
        emailController.text.trim(),
        passwordController.text,
        sekolahId: sekolahId,
      );

      await _saveLoginData(responseData);

      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        '/${responseData['user']['role']}',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Login berhasil! Selamat datang di ${responseData['user']['nama_sekolah']}',
          ),
        ),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
      setState(() {
        _isLoading = false;
        _showSchoolSelection = false;
      });
    }
  }

  Widget _buildSchoolSelection() {
    return Column(
      children: [
        SizedBox(height: 20),
        Text(
          'Pilih Sekolah',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        Text(
          'Halo ${_userData?['nama']}, silakan pilih sekolah:',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        SizedBox(height: 20),
        Expanded(
          child: ListView.builder(
            itemCount: _sekolahList.length,
            itemBuilder: (context, index) {
              final sekolah = _sekolahList[index];
              return Card(
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 0),
                child: ListTile(
                  leading: Icon(Icons.school, color: Colors.blue),
                  title: Text(sekolah['nama_sekolah']),
                  subtitle: Text(sekolah['alamat'] ?? ''),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _selectSchool(sekolah['sekolah_id']),
                ),
              );
            },
          ),
        ),
        SizedBox(height: 20),
        TextButton(
          onPressed: () {
            setState(() {
              _showSchoolSelection = false;
              _isLoading = false;
            });
          },
          child: Text('Kembali ke Login'),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.school, size: 80, color: Colors.blue),
        SizedBox(height: 20),
        Text(
          'Sistem Manajemen Sekolah',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),

        if (!_serverConnected) ...[
          SizedBox(height: 10),
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red[50],
              border: Border.all(color: Colors.red),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.red),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Server tidak terhubung',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
        ],

        SizedBox(height: 30),
        TextField(
          controller: emailController,
          decoration: InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.email),
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        SizedBox(height: 15),
        TextField(
          controller: passwordController,
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: Icon(Icons.lock),
            border: OutlineInputBorder(),
          ),
          obscureText: true,
          onSubmitted: (_) => login(),
        ),
        SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: _isLoading
              ? Center(child: CircularProgressIndicator())
              : ElevatedButton(
                  onPressed: _serverConnected ? login : null,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: Text('LOGIN'),
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[400]!, Colors.blue[800]!],
          ),
        ),
        child: Center(
          child: Card(
            margin: EdgeInsets.all(20),
            elevation: 8,
            child: Padding(
              padding: EdgeInsets.all(30),
              child: _showSchoolSelection 
                  ? _buildSchoolSelection()
                  : _buildLoginForm(),
            ),
          ),
        ),
      ),
    );
  }
}
