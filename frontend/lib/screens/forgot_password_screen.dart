import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKeyEmail = GlobalKey<FormState>();
  final _formKeyReset = GlobalKey<FormState>();
  
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _codigoEnviado = false; // Controla se estamos a mostrar o ecrã de E-mail ou o ecrã de PIN

  // ==========================================
  // FASE 1: Pedir ao servidor para enviar o PIN
  // ==========================================
  Future<void> _solicitarCodigo() async {
    if (!_formKeyEmail.currentState!.validate()) return;

    setState(() { _isLoading = true; });

    try {
      final response = await http.post(
        Uri.parse('https://beecoffee-connect.onrender.com/api/recover-password/request'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': _emailController.text.trim()}),
      );

      setState(() { _isLoading = false; });

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() { _codigoEnviado = true; }); // Muda a interface para pedir o PIN
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('E-mail enviado! Verifique a sua caixa de entrada.'), backgroundColor: Colors.green),
        );
      } else {
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['error'] ?? 'Erro ao enviar código.'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      setState(() { _isLoading = false; });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro de conexão com o servidor.'), backgroundColor: Colors.red));
    }
  }

  // ==========================================
  // FASE 2: Enviar o PIN validado e a Nova Senha
  // ==========================================
  Future<void> _redefinirSenha() async {
    if (!_formKeyReset.currentState!.validate()) return;

    setState(() { _isLoading = true; });

    try {
      final response = await http.post(
        Uri.parse('https://beecoffee-connect.onrender.com/api/recover-password/reset'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text.trim(),
          'pin': _pinController.text.trim(),
          'nova_senha': _passwordController.text.trim(),
        }),
      );

      setState(() { _isLoading = false; });

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sucesso! Pode fazer login com a nova senha.'), backgroundColor: Colors.green),
        );
        Navigator.pop(context); // Volta automaticamente para o ecrã de Login
      } else {
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['error'] ?? 'Erro ao redefinir senha.'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      setState(() { _isLoading = false; });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro de conexão.'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Recuperar Senha'), backgroundColor: Colors.green[700], foregroundColor: Colors.white),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          // A magia acontece aqui: se o código não foi enviado, mostra o formulário de e-mail. Se já foi, mostra o de senha.
          child: !_codigoEnviado ? _buildFaseEmail() : _buildFaseReset(),
        ),
      ),
    );
  }

  // ==========================================
  // ECRÃ 1: Pedir o E-mail
  // ==========================================
  Widget _buildFaseEmail() {
    return Form(
      key: _formKeyEmail,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.mark_email_read, size: 80, color: Colors.amber),
          const SizedBox(height: 16),
          const Text('Esqueceu a sua senha?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.brown)),
          const SizedBox(height: 8),
          const Text('Insira o seu e-mail e enviaremos um código de segurança de 6 dígitos.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 32),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(labelText: 'E-mail de Cadastro', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), prefixIcon: const Icon(Icons.email)),
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'O e-mail é obrigatório.';
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) return 'Digite um e-mail válido.';
              return null;
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity, height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _solicitarCodigo,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('ENVIAR CÓDIGO', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // ECRÃ 2: Inserir PIN e Nova Senha
  // ==========================================
  Widget _buildFaseReset() {
    return Form(
      key: _formKeyReset,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_reset, size: 80, color: Colors.amber),
          const SizedBox(height: 16),
          const Text('Criar Nova Senha', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.brown)),
          const SizedBox(height: 8),
          Text('Código enviado para ${_emailController.text}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 32),
          TextFormField(
            controller: _pinController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: InputDecoration(labelText: 'Código de 6 dígitos (PIN)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), prefixIcon: const Icon(Icons.pin)),
            validator: (value) => (value == null || value.length != 6) ? 'O código deve ter 6 dígitos.' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(labelText: 'Nova Senha', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), prefixIcon: const Icon(Icons.lock_outline)),
            validator: (value) => (value == null || value.length < 6) ? 'A senha deve ter no mínimo 6 caracteres.' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: true,
            decoration: InputDecoration(labelText: 'Confirmar Nova Senha', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), prefixIcon: const Icon(Icons.check_circle_outline)),
            validator: (value) => value != _passwordController.text ? 'As senhas não coincidem.' : null,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity, height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _redefinirSenha,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber[800], foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('REDEFINIR SENHA', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            // Permite ao utilizador recuar caso tenha digitado o e-mail errado
            onPressed: () => setState(() { _codigoEnviado = false; _pinController.clear(); }),
            child: const Text('Voltar e usar outro e-mail', style: TextStyle(color: Colors.grey)),
          )
        ],
      ),
    );
  }
}