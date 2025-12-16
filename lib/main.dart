import 'dart:async';

import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tu Ayuno Intermitente',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Tu Ayuno Intermitente'),
    );
  }
}

// Definición del enum para los estados de la aplicación
enum EstadoAyuno { fasting, feeding, none }

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  // ignore: library_private_types_in_public_api
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Duration _elapsedTime = Duration.zero;
  Timer? _timer;
  EstadoAyuno _estadoActual = EstadoAyuno.none;

  void _startTimer() {
    _stopTimer();

    _elapsedTime = Duration.zero;
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedTime += Duration(seconds: 1);
      });
    });
  }

  void _stopTimer() {
    if (_timer != null && _timer!.isActive) {
      _timer!.cancel();
    }
  }

  void _startFasting() {
    _mostrarDialogoConfirmacion('Fasting', _realizarStartFasting);
  }

  void _startFeeding() {
    _mostrarDialogoConfirmacion('Feeding', _realizarStartFeeding);
  }

  // Función auxiliar para encapsular la lógica de inicio de Fasting
  void _realizarStartFasting() {
    _startTimer();
    setState(() {
      _estadoActual = EstadoAyuno.fasting;
    });
  }

  // Función auxiliar para encapsular la lógica de inicio de Feeding
  void _realizarStartFeeding() {
    _startTimer();
    setState(() {
      _estadoActual = EstadoAyuno.feeding;
    });
  }

  // Función para mostrar el diálogo de confirmación
  void _mostrarDialogoConfirmacion(String accion, VoidCallback onConfirmar) {
    String texto = '';

    if (_estadoActual == EstadoAyuno.none) {
      //Navigator.of(context).pop(); // Cierra el diálogo
      onConfirmar();
      return;
    }

    if (((accion == "Fasting") && (_estadoActual == EstadoAyuno.fasting)) ||
        ((accion == "Feeding") && (_estadoActual == EstadoAyuno.feeding))) {
      texto =
          'Ya estás en modo $accion. ¿Estás seguro de que quieres reiniciar el cronómetro?';
    } else {
      texto = '¿Cambiamos a modo $accion ?';
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmar Acción'),
          content: Text(texto),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cierra el diálogo
              },
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cierra el diálogo
                onConfirmar(); // Ejecuta la acción de inicio
              },
              child: Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));

    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  String _getEstadoTexto(EstadoAyuno estado) {
    switch (estado) {
      case EstadoAyuno.fasting:
        return 'Ayuno';
      case EstadoAyuno.feeding:
        return 'Alimentación';
      case EstadoAyuno.none:
        return 'Selecciona una acción';
    }
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: TextStyle(
            color: Colors.blueGrey,
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Tiempo transcurrido:',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            SizedBox(height: 20),
            Text(
              _formatDuration(_elapsedTime),
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                fontSize: 48,
                fontFamily: 'Courier New',
              ),
            ),
            SizedBox(height: 20),
            Text(
              _getEstadoTexto(_estadoActual),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 24, // Tamaño de fuente personalizado
                fontStyle: FontStyle.italic, // Estilo de fuente en cursiva
                // Puedes añadir otras propiedades aquí también
                // color: Colors.orange, // Cambiar color si se desea
                // fontWeight: FontWeight.w600, // Grosor de la fuente
              ),
            ),
            SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _startFasting,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  ),
                  child: Text('Start Fasting', style: TextStyle(fontSize: 18)),
                ),
                ElevatedButton(
                  onPressed: _startFeeding,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  ),
                  child: Text('Start Feeding', style: TextStyle(fontSize: 18)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
