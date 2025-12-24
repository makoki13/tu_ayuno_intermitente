import 'package:flutter/material.dart';

class AyudaPage extends StatelessWidget {
  const AyudaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ayuda'),
        // Opcional: Añadir botón de "Atrás" personalizado si lo prefieres
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Introducción
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bienvenido a Mi Ayuno Intermitente',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey[800],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'La aplicación te permite saber cuánto tiempo llevas en estado fasting (ayuno) o en estado feeding (alimentación). Además indica cuánto tiempo falta para que tengas que pasar al otro estado.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            // Botones principales
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Funciones Principales',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey[800],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildHelpItem(
                    icon: Icons.timer,
                    title: 'Start Fasting',
                    description: 'Comienza el periodo de ayuno',
                    color: Colors.red,
                  ),
                  _buildHelpItem(
                    icon: Icons.restaurant,
                    title: 'Start Feeding',
                    description: 'Comienza el periodo de alimentación',
                    color: Colors.green,
                  ),
                  _buildHelpItem(
                    icon: Icons.refresh,
                    title: 'Reset',
                    description: 'Reinicia la aplicación',
                    color: Colors.grey,
                  ),
                ],
              ),
            ),

            // Configuración
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Opciones de Configuración',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey[800],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildHelpItem(
                    icon: Icons.dark_mode,
                    title: 'Tema Oscuro',
                    description: 'Conmuta entre un tema oscuro o claro',
                    color: Colors.blue,
                  ),
                  _buildHelpItem(
                    icon: Icons.access_time,
                    title: 'Horas de alimentación',
                    description: 'El periodo de tiempo en horas en las que se va a alimentar',
                    color: Colors.orange,
                  ),
                ],
              ),
            ),

            // Historial
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Historial',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey[800],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildHelpItem(
                    icon: Icons.history,
                    title: 'Histórico',
                    description: 'Muestra el historial detallado de tus sesiones de ayuno y alimentación',
                    color: Colors.purple,
                  ),
                ],
              ),
            ),

            // Información adicional
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blueGrey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blueGrey[200]!, width: 1),
              ),
              child: Text(
                'Consejo: Utiliza la función de cambio automático en la configuración para que la aplicación cambie automáticamente entre ayuno y alimentación según tus preferencias.',
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: Colors.blueGrey[700],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Método para construir elementos de ayuda con bullets y estilo profesional
  Widget _buildHelpItem({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bullet point con ícono
          Container(
            width: 20,
            height: 20,
            margin: const EdgeInsets.only(top: 3, right: 10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 1.5),
            ),
            child: Icon(
              icon,
              size: 14,
              color: color,
            ),
          ),
          // Contenido
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
