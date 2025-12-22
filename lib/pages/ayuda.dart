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
        // Añadir un poco de padding alrededor del contenido
        padding: const EdgeInsets.all(16.0),
        child: RichText(
          // Usar RichText para texto con formato mixto
          text: TextSpan(
            // TextSpan principal
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
              fontSize: 18,
              fontFamily: 'Courier New',
              fontWeight: FontWeight.normal,
            ), // Usa el estilo por defecto del tema
            children: <TextSpan>[
              TextSpan(
                text:
                    'La aplicación te permite saber cuánto tiempo llevas en estado ',
              ), // Texto normal
              TextSpan(
                // Texto en cursiva
                text: 'fasting',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
              TextSpan(text: ' (ayuno) o en estado '), // Texto normal
              TextSpan(
                // Texto en cursiva
                text: 'feeding',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
              TextSpan(text: ' (alimentación).'), // Texto normal
              TextSpan(
                text:
                    ' Además indica cuánto tiempo falta para que tengas que pasar al otro estado.',
              ), // Texto normal
              TextSpan(text: '\n\n'),

              TextSpan(text: '· Las opciones del menú inferior son.'),
              TextSpan(text: '\n'),
              TextSpan(text: ' El botón "'),
              TextSpan(
                text: 'Start Fasting',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.deepOrange,
                ),
              ),
              TextSpan(text: '": Comienza el periodo de ayuno'),
              TextSpan(text: '\n'),
              TextSpan(text: ' El botón "'),
              TextSpan(
                text: 'Start Feeding',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.deepOrange,
                ),
              ),
              TextSpan(text: '": Comienza el periodo de alimentación'),
              TextSpan(text: '\n'),
              TextSpan(text: ' El botón "'),
              TextSpan(
                text: 'Reset',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.deepOrange,
                ),
              ),
              TextSpan(text: '": Reinicia la aplicación'),

              TextSpan(text: '\n\n'),
              TextSpan(text: '· Las opciones de configuración son.'),
              TextSpan(text: '\n'),
              TextSpan(
                text: 'Tema Oscuro',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.deepOrange,
                ),
              ),
              TextSpan(text: ': Conmute entre un tema oscuro o claro'),
              TextSpan(text: '\n'),
              TextSpan(
                text: 'Horas de alimentación',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.deepOrange,
                ),
              ),
              TextSpan(
                text:
                    ': El periodo de tiempo en horas en las que se va a alimentar',
              ),

              TextSpan(text: '\n\n'),
              TextSpan(
                text:
                    '· El historial nos muestra cuanto tiempo hemos estado en cada estado.',
              ),
              TextSpan(text: '\n\n'),
              TextSpan(
                text: ' El botón "',
              ),
              TextSpan(
                text: 'Histórico',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.deepOrange,
                ),
              ),
              TextSpan(
                text: '": Muestra el historial detallado de tus sesiones de ayuno y alimentación',
              ),

            ],
          ),
        ),
      ),
    );
  }
}
