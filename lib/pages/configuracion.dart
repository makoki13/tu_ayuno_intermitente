import 'package:flutter/material.dart';

class ConfiguracionPage extends StatelessWidget {
  const ConfiguracionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Configuración'), // Título de la página
        // leading: IconButton( // Botón de "Atrás" personalizado (opcional)
        //   icon: Icon(Icons.arrow_back),
        //   onPressed: () => Navigator.pop(context),
        // ),
      ),
      body: Center(
        child: Text('Contenido de la página de Configuración'),
      ),
    );
  }
}