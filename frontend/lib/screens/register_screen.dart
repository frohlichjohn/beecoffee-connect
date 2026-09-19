import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RegisterScreen extends StatefulWidget {
  final String initialRole; // Recebe o tipo de perfil escolhido na tela anterior

  const RegisterScreen({super.key, required this.initialRole});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Controladores para capturar o texto digitado pelo usuário nos campos de texto
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  
  late String _selectedRole; // Declarado como late para ser iniciado no initState
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Inicia o dropdown com o valor enviado pelo botão correspondente na tela anterior
    _selectedRole = widget.initialRole; 
  }

  // Função responsável por enviar os dados de cadastro para a API Node.js
  Future<void> _cadastrarUsuario() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final location = _locationController.text.trim(); 

    // Validação básica para garantir que nenhum campo ficou vazio
    if (name.isEmpty || email.isEmpty || password.isEmpty || location.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os campos, incluindo a localização!')),
      );
      return;
    }

    setState(() { _isLoading = true; });

    try {
      final response = await http.post(
        Uri.parse('https://beecoffee-connect.onrender.com/api/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'full_name': name,
          'email': email,
          'password': password,
          'role': _selectedRole,
          'location': location, // Envia a cidade e estado para o PostgreSQL
        }),
      );

      setState(() { _isLoading = false; });

      if (response.statusCode == 201) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cadastro realizado com sucesso! Faça login.')),
        );
        Navigator.pop(context); // Retorna para a tela de login
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
        // CORREÇÃO: Força o texto "Voltar" em português ao passar o mouse ou segurar o botão de retorno
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
              
              // Campo para Nome Completo ou Nome da Fazenda/Apiário
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nome Completo / Fazenda',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
              
              // Campo para o E-mail de acesso
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
              
              // Campo para a Senha
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

              // Campo de Localização genérico (Ex: Cidade / Estado)
              TextField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: 'Cidade / Estado',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.location_city),
                ),
              ),
              const SizedBox(height: 16),
              
              // Dropdown para Seleção de Perfil
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
              
              // Botão Principal de Cadastro
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