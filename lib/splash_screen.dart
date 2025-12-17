import 'dart:async'; // Importar para usar Timer
import 'package:flutter/material.dart';

// Importar la pantalla principal
import 'main.dart'; // Asumiendo que MyHomePage está en main.dart

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  // Controlador de animación
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // Inicializar el controlador de animación
    // Duración total de la animación de entrada: 1 segundo
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1),
    );

    // Crear la animación de opacidad (de 0.0 a 1.0)
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    // Iniciar la animación
    _controller.forward();

    // Lógica de navegación después de 3 segundos
    Timer(Duration(seconds: 3), () {
      // Navegar a la pantalla principal y reemplazar esta pantalla
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MyHomePage(title: 'Mi Ayuno Intermitente'),
        ),
      );
    });
  }

  @override
  void dispose() {
    // Liberar recursos del controlador de animación
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Puedes cambiar el color de fondo del splash aquí
      backgroundColor: Colors.blueGrey.shade100, // Un gris azulado claro
      body: Center(
        child: FadeTransition(
          opacity: _animation, // Conectar la animación de opacidad
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icono o Imagen (opcional)
              // Icon(Icons.local_dining, size: 100, color: Colors.blue,), // Ejemplo de ícono
              // Image.asset('assets/images/logo.png', height: 100,), // Ejemplo con imagen local

              // Texto principal del Splash
              Text(
                'Mi Ayuno\nIntermitente',
                textAlign: TextAlign.center, // Centrar el texto multilínea
                style: TextStyle(
                  fontSize: 32, // Tamaño de fuente grande
                  fontWeight: FontWeight.bold,
                  color: Colors.blue, // Color del texto
                ),
              ),
              SizedBox(height: 20), // Espacio debajo del texto
              CircularProgressIndicator(
                // Indicador opcional de carga
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
