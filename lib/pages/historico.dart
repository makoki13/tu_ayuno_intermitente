import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../main.dart'; // Importar el enum EstadoAyuno y las claves

class HistoricoPage extends StatefulWidget {
  const HistoricoPage({super.key});

  @override
  State<HistoricoPage> createState() => _HistoricoPageState();
}

class _HistoricoPageState extends State<HistoricoPage> {
  static const String _prefsKeySesiones = 'sesiones_registro';
  List<Map<String, dynamic>> _registroSesiones = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarHistorial();
  }

  Future<void> _cargarHistorial() async {
    final prefs = await SharedPreferences.getInstance();
    final sesionesJson = prefs.getStringList(_prefsKeySesiones) ?? [];
    
    List<Map<String, dynamic>> sesiones = sesionesJson.map((json) {
      Map<String, dynamic> map = Map<String, dynamic>.from(
        Map<String, dynamic>.from(jsonDecode(json))
      );
      return map;
    }).toList();
    
    // Ordenar por fecha de registro en orden descendente (más reciente primero)
    sesiones.sort((a, b) => 
      (b['timestamp_registro'] as int).compareTo(a['timestamp_registro'] as int)
    );

    setState(() {
      _registroSesiones = sesiones;
      _isLoading = false;
    });
  }

  // Función para convertir el string del estado a enum
  EstadoAyuno _stringToEstadoAyuno(String str) {
    switch (str) {
      case 'fasting':
        return EstadoAyuno.fasting;
      case 'feeding':
        return EstadoAyuno.feeding;
      case 'none':
      default:
        return EstadoAyuno.none;
    }
  }

  // Función para formatear la duración como string legible
  String _formatDuracion(int horas, int minutos, int segundos) {
    List<String> partes = [];
    if (horas > 0) partes.add('${horas}h');
    if (minutos > 0) partes.add('${minutos}m');
    if (segundos > 0) partes.add('${segundos}s');
    return partes.join(' ');
  }

  // Función para formatear la fecha de manera legible
  String _formatFecha(String isoDate) {
    DateTime dateTime = DateTime.parse(isoDate);
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de Estados'),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _registroSesiones.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No hay registros aún',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Comienza a usar la app para ver tu historial aquí',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _cargarHistorial,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _registroSesiones.length,
                    itemBuilder: (context, index) {
                      final sesion = _registroSesiones[index];
                      final estado = _stringToEstadoAyuno(sesion['estado']);
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 4,
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: estado == EstadoAyuno.fasting 
                                  ? Colors.red.shade100 
                                  : Colors.green.shade100,
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                color: estado == EstadoAyuno.fasting 
                                    ? Colors.red 
                                    : Colors.green,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              estado == EstadoAyuno.fasting 
                                  ? Icons.local_cafe 
                                  : Icons.restaurant,
                              color: estado == EstadoAyuno.fasting 
                                  ? Colors.red 
                                  : Colors.green,
                            ),
                          ),
                          title: Row(
                            children: [
                              Text(
                                estado == EstadoAyuno.fasting 
                                    ? 'Ayuno' 
                                    : 'Alimentación',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: estado == EstadoAyuno.fasting 
                                      ? Colors.red.shade50 
                                      : Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: estado == EstadoAyuno.fasting 
                                        ? Colors.red.shade200 
                                        : Colors.green.shade200,
                                  ),
                                ),
                                child: Text(
                                  _formatDuracion(
                                    sesion['duracion_horas'],
                                    sesion['duracion_minutos'],
                                    sesion['duracion_segundos'],
                                  ),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: estado == EstadoAyuno.fasting 
                                        ? Colors.red 
                                        : Colors.green,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              Text(
                                'Inicio: ${_formatFecha(sesion['fecha_inicio'])}',
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Fin: ${_formatFecha(sesion['fecha_fin'])}',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                          isThreeLine: true,
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: _registroSesiones.isNotEmpty
          ? FloatingActionButton(
              onPressed: () {
                _mostrarDialogoConfirmacionBorrar();
              },
              backgroundColor: Colors.red,
              child: const Icon(Icons.delete, color: Colors.white),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  void _mostrarDialogoConfirmacionBorrar() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar borrado'),
          content: const Text(
            '¿Estás seguro de que quieres borrar todo el historial? Esta acción no se puede deshacer.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cierra el diálogo
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Cierra el diálogo
                await _borrarHistorial();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red, // Color del texto
              ),
              child: const Text('Borrar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _borrarHistorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKeySesiones);
    
    setState(() {
      _registroSesiones = [];
    });
  }
}