import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'home_screen.dart';
import 'register_screen.dart';
import 'beekeeper_home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _fazerLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha o e-mail e a senha!')),
      );
      return;
    }

    setState(() { _isLoading = true; });

    try {
      final response = await http.post(
        Uri.parse('https://beecoffee-connect.onrender.com/api/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      setState(() { _isLoading = false; });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        final userId = data['user']['id'].toString(); // Garantir que é String
        final userRole = data['user']['role'];
        final userName = data['user']['full_name'];
        final userLocation = data['user']['location'] ?? 'Local não informado';
        
        // --- AQUI ESTÁ A MÁGICA PARA O MAPA ---
        // Pegamos as coordenadas do banco (ou usamos 0.0 se falhar)
        final double lat = double.tryParse(data['user']['latitude']?.toString() ?? '0') ?? 0.0;
        final double lng = double.tryParse(data['user']['longitude']?.toString() ?? '0') ?? 0.0;

        if (!mounted) return;

        if (userRole == 'APICULTOR') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => BeekeeperHomeScreen(
                userId: userId, 
                userName: userName,
                location: userLocation,
              ),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomeScreen(
                userId: userId, 
                userName: userName,
                location: userLocation,
                latitude: lat,   // Enviando GPS Real!
                longitude: lng,  // Enviando GPS Real!
              ),
            ),
          );
        }
      } else {
        final data = jsonDecode(response.body);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['error'] ?? 'Erro ao fazer login')),
        );
      }
    } catch (e) {
      setState(() { _isLoading = false; });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro de conexão: $e')), // Mostrar o erro exato
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ==========================================
              // LOGÓTIPO ISOLADO (Escala visual ajustada)
              // ==========================================
              Transform.scale(
                scale: 1.5, 
                child: Image.asset(
                  'assets/images/logo.png', 
                  height: 220, 
                ),
              ),
              const SizedBox(height: 48), 
              
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'E-mail',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Senha',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.lock),
                ),
                obscureText: true,
              ),
              
              Align(
                alignment: Alignment.centerRight, 
                child: TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Em breve: Tela de recuperação de senha!'))
                    );
                  },
                  child: const Text('Esqueci minha senha', style: TextStyle(color: Colors.brown)),
                ),
              ),
              
              const SizedBox(height: 8),
              
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _fazerLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('ENTRAR', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              
              const SizedBox(height: 32),
              
              const Text('Novo por aqui?', style: TextStyle(color: Colors.grey)),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RegisterScreen(initialRole: 'CAFEICULTOR')),
                  );
                },
                child: const Text(
                  'Criar nova conta', 
                  style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}