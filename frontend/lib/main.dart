import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'screens/home_screen.dart';
import 'screens/register_screen.dart';
import 'screens/beekeeper_home_screen.dart';

void main() {
  runApp(const BeeCoffeeApp());
}

class BeeCoffeeApp extends StatelessWidget {
  const BeeCoffeeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BeeCoffee Connect',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.brown, 
          primary: Colors.green[700], 
        ),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // === AQUI ESTÃO OS CONTROLADORES QUE TINHAM SUMIDO! ===
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
        Uri.parse('http://localhost:3000/api/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      setState(() { _isLoading = false; });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        final userId = data['user']['id'];
        final userRole = data['user']['role'];
        final userName = data['user']['full_name'];
        final userLocation = data['user']['location'] ?? 'Local não informado';

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
        const SnackBar(content: Text('Não foi possível conectar ao servidor backend.')),
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
                scale: 1.5, // Ajuste este multiplicador (1.3, 1.6, 2.0...) até ficar com o tamanho perfeito
                child: Image.asset(
                  'assets/images/logo.png', 
                  height: 220, // Mantém a altura base original para não desalinhar o resto
                ),
              ),
              const SizedBox(height: 48), // O espaço para o campo de e-mail continua intacto
              
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