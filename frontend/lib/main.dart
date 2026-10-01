import 'package:flutter/material.dart';
import 'screens/login_screen.dart'; // Importa a nova tela de login

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
      home: const LoginScreen(), // Inicia diretamente na tela de login
    );
  }
}