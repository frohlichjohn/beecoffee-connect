import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';

class RegisterScreen extends StatefulWidget {
  final String initialRole;

  const RegisterScreen({super.key, required this.initialRole});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // 1. CHAVE DO FORMULÁRIO MOVIDA PARA AQUI (Escopo global da classe)
  final _formKey = GlobalKey<FormState>();

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
    // 2. EXECUTA A VALIDAÇÃO AQUI
    // Se algum validator falhar, ele para a função e mostra os erros em vermelho
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final location = _locationController.text.trim(); 

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
          // 3. ENVOLVENDO A COLUMN COM O WIDGET FORM
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.person_add, size: 70, color: Colors.green),
                const SizedBox(height: 24),
                
                // NOME
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Nome Completo / Fazenda',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'O nome é obrigatório.';
                    }
                    if (value.trim().length < 3) {
                      return 'O nome deve ter pelo menos 3 letras.';
                    }
                    if (RegExp(r'[0-9]').hasMatch(value)) {
                      return 'O nome não pode conter números.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // E-MAIL
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'E-mail',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.email),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'O e-mail é obrigatório.';
                    }
                    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                    if (!emailRegex.hasMatch(value)) {
                      return 'Digite um e-mail válido (ex: joao@email.com).';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // SENHA
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Senha',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.lock),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'A senha é obrigatória.';
                    }
                    if (value.length < 6) {
                      return 'A senha deve ter no mínimo 6 caracteres.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // CIDADE / ESTADO
                TextFormField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    labelText: 'Cidade / Estado',
                    hintText: 'Ex: Mogi Mirim/SP',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.location_city),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'A localização é obrigatória.';
                    }
                    final cidadeRegex = RegExp(r'^[a-zA-ZÀ-ÿ\s]+/[A-Z]{2}$', caseSensitive: false);
                    if (!cidadeRegex.hasMatch(value.trim())) {
                      return 'Use o formato Cidade/UF (Ex: Mogi Mirim/SP).';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // TIPO DE PERFIL
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
                
                // BOTÃO CADASTRAR
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
      ),
    );
  }
}