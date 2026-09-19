import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart'; // Pacote correto para GPS

class RegisterScreen extends StatefulWidget {
  final String initialRole;

  const RegisterScreen({super.key, required this.initialRole});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  
  late String _selectedRole;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialRole; 
  }

  Future<void> _cadastrarUsuario() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final location = _locationController.text.trim(); 

    if (name.isEmpty || email.isEmpty || password.isEmpty || location.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os campos, incluindo a localização!')),
      );
      return;
    }

    setState(() { _isLoading = true; });

    try {
      // --- CAPTURA DE COORDENADAS VIA GPS ---
      double? latitudeCalculada;
      double? longitudeCalculada;

      try {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }

        if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
          Position position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high);
          latitudeCalculada = position.latitude;
          longitudeCalculada = position.longitude;
        }
      } catch (e) {
        debugPrint("Erro ao capturar a localização do GPS: $e");
      }
      // --- FIM DA CAPTURA ---

      final response = await http.post(
        Uri.parse('https://beecoffee-connect.onrender.com/api/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'full_name': name,
          'email': email,
          'password': password,
          'role': _selectedRole,
          'location': location,
          'city': location,                  
          'latitude': latitudeCalculada,     
          'longitude': longitudeCalculada    
        }),
      );

      setState(() { _isLoading = false; });

      if (response.statusCode == 201) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cadastro realizado com sucesso! Faça login.')),
        );
        Navigator.pop(context); 
      } else {
        final data = jsonDecode(response.body);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['error'] ?? 'Erro no cadastro')),
        );
      }
    } catch (e) {
      setState(() { _isLoading = false; });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao conectar com o servidor.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastro - BeeCoffee Connect'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Voltar',
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_add, size: 70, color: Colors.green),
              const SizedBox(height: 24),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nome Completo / Fazenda',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
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
              const SizedBox(height: 16),
              TextField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: 'Cidade / Estado',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.location_city),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedRole,
                decoration: InputDecoration(
                  labelText: 'Tipo de Perfil',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.group),
                ),
                items: const [
                  DropdownMenuItem(value: 'CAFEICULTOR', child: Text('Cafeicultor')),
                  DropdownMenuItem(value: 'APICULTOR', child: Text('Apicultor')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedRole = value!;
                  });
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _cadastrarUsuario,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('CADASTRAR CONTA', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}