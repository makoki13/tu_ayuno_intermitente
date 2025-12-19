import 'package:flutter/material.dart';

class ConfiguracionPage extends StatefulWidget {
  @override
  _ConfiguracionPageState createState() => _ConfiguracionPageState();
}

class _ConfiguracionPageState extends State<ConfiguracionPage> {
  // Estado para el conmutador de tema
  bool _temaOscuroSeleccionado = false; // Valor inicial

  // Estado para las horas de alimentación
  String _horasAlimentacion = '12'; // Valor inicial

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
            // Título del primer apartado
            Text('Tema', style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 8), // Espacio debajo del título
            // Conmutador (Switch) para Tema Oscuro/Claro
            Row(
              children: [
                Text('Tema Oscuro'),
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
                  'Horas de alimentación',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Spacer(), // Empuja el TextField hacia la derecha
                SizedBox(
                  width: 8,
                ), // Pequeño espacio entre el texto y el campo (opcional)
                SizedBox(
                  // Limitar el ancho del TextField
                  width: 100, // Ancho fijo para el campo numérico
                  child: TextField(
                    keyboardType: TextInputType.number, // Teclado numérico
                    controller: TextEditingController(
                      text: _horasAlimentacion,
                    ), // Controlador con valor inicial
                    onChanged: (String value) {
                      // Opcional: Validar el valor aquí mismo
                      int? horas = int.tryParse(value);
                      if (horas != null && horas >= 0 && horas <= 24) {
                        setState(() {
                          _horasAlimentacion = value; // Actualizar el estado
                        });
                        // Aquí se podría guardar el valor si se implementa persistencia
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
                      hintText: '0-24', // Texto de ayuda
                      border: OutlineInputBorder(), // Borde del campo
                      // isDense: true, // Opcional: para que el campo sea más compacto verticalmente
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
