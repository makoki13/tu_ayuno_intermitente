import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConfiguracionPage extends StatefulWidget {
  const ConfiguracionPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ConfiguracionPageState createState() => _ConfiguracionPageState();
}

class _ConfiguracionPageState extends State<ConfiguracionPage> {
  // Estado para el conmutador de tema
  bool _temaOscuroSeleccionado = false; // Valor inicial

  // Estado para las horas de alimentación
  String _horasAlimentacion = '12'; // Valor inicial

  late TextEditingController _horasController;

  static const String _prefsKeyHorasAlimentacion = 'horas_alimentacion';

  @override
  void initState() {
    super.initState();
    // --- INICIALIZAR EL CONTROLADOR AQUÍ ---
    _cargarHorasAlimentacion();
    //_horasController = TextEditingController(text: _horasAlimentacion);
  }

  Future<void> _cargarHorasAlimentacion() async {
    final prefs = await SharedPreferences.getInstance();
    String horasGuardadas =
        prefs.getString(_prefsKeyHorasAlimentacion) ??
        '12'; // Valor por defecto '12'
    setState(() {
      _horasAlimentacion = horasGuardadas;
      // Inicializar el controlador con el valor cargado
      _horasController = TextEditingController(text: _horasAlimentacion);
    });
  }

  Future<void> _guardarHorasAlimentacion(String horas) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKeyHorasAlimentacion, horas);
  }

  @override
  void dispose() {
    // --- DESCARTAR EL CONTROLADOR AQUÍ PARA LIBERAR RECURSOS ---
    _horasController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Configuración')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start, // Alinear hijos a la izquierda
          children: [
            // Conmutador (Switch) para Tema Oscuro/Claro
            Row(
              children: [
                Text(
                  'Tema Oscuro:',
                  style: Theme.of(
                    context,
                  ).textTheme.displayLarge?.copyWith(fontSize: 22),
                ),
                Spacer(), // Empuja el Switch hacia la derecha
                Switch(
                  value: _temaOscuroSeleccionado,
                  onChanged: (bool newValue) {
                    setState(() {
                      _temaOscuroSeleccionado = newValue;
                    });
                    // Aquí se podría guardar el valor si se implementa persistencia
                    // y se notificaría al ThemeProvider o MaterialApp para cambiar el tema globalmente.
                  },
                ),
              ],
            ),
            SizedBox(height: 24), // Espacio entre apartados
            // Título del segundo apartado
            Row(
              // Nuevo Row para alinear título y campo
              children: [
                Text(
                  'Horas de alimentación:',
                  style: Theme.of(
                    context,
                  ).textTheme.displayLarge?.copyWith(fontSize: 18),
                ),
                Spacer(), // Empuja el TextField hacia la derecha
                SizedBox(
                  width: 8,
                ), // Pequeño espacio entre el texto y el campo (opcional)
                SizedBox(
                  // Limitar el ancho del TextField
                  width: 80, // Ancho fijo para el campo numérico
                  child: TextField(
                    keyboardType: TextInputType.number, // Teclado numérico
                    /* controller: TextEditingController(
                      text: _horasAlimentacion,
                    ), */
                    // Controlador con valor inicial
                    controller: _horasController,
                    textAlign: TextAlign
                        .center, // <-- Añadir esta línea para centrar el texto
                    style: TextStyle(
                      // Cambia el estilo del texto dentro del campo
                      fontSize:
                          24, // <-- Cambiar el tamaño de fuente aquí (ej: 24)
                      fontWeight: FontWeight.bold, // Negrita (opcional)
                      // color: Colors.black, // Color del texto (opcional)
                    ),
                    onChanged: (String value) {
                      // Opcional: Validar el valor aquí mismo
                      int? horas = int.tryParse(value);
                      if (horas != null && horas >= 0 && horas <= 24) {
                        setState(() {
                          _horasAlimentacion = value; // Actualizar el estado
                        });
                        _guardarHorasAlimentacion(value);
                      } else if (value.isEmpty) {
                        // Permitir borrar, pero no dejar un valor inválido guardado si se sale
                        setState(() {
                          _horasAlimentacion =
                              ''; // O podrías dejar el valor anterior
                        });
                      }
                      // Si el valor no es un número o está fuera de rango, no se actualiza _horasAlimentacion
                    },
                    decoration: InputDecoration(
                      hintText:
                          '0-24', // Texto de ayuda (se puede quitar si no se desea)
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                      ), // Estilo del texto de ayuda
                      filled: true, // Habilita el color de fondo
                      fillColor: Colors.grey[200], // Color de fondo del campo
                      border: OutlineInputBorder(
                        // Borde estándar
                        borderRadius: BorderRadius.circular(
                          8.0,
                        ), // Bordes redondeados
                        borderSide: BorderSide(
                          color: Colors.grey,
                        ), // Color del borde
                      ),
                      focusedBorder: OutlineInputBorder(
                        // Borde cuando el campo está enfocado
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(
                          color: Colors.blue,
                          width: 2.0,
                        ), // Borde azul más grueso
                      ),
                      enabledBorder: OutlineInputBorder(
                        // Borde cuando el campo está habilitado pero no enfocado
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(
                          color: Colors.grey[400]!,
                        ), // Borde gris claro
                      ),
                      errorBorder: OutlineInputBorder(
                        // Borde cuando hay un error (si se usa validator)
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(
                          color: Colors.red,
                        ), // Borde rojo para errores
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        // Borde cuando hay un error y está enfocado
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(color: Colors.red, width: 2.0),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ), // Relleno interno
                      isDense:
                          true, // Opcional: para que el campo sea más compacto verticalmente
                    ),
                  ),
                ),
              ],
            ),
            // Opcional: Mostrar mensaje de error si el valor no es válido
            if (_horasAlimentacion.isNotEmpty)
              if (int.tryParse(_horasAlimentacion) == null ||
                  int.parse(_horasAlimentacion) < 0 ||
                  int.parse(_horasAlimentacion) > 24)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Valor inválido. Debe ser entre 0 y 24.',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
