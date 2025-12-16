import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; 

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

  // Claves para SharedPreferences
  static const String _prefsKeyEstado = 'estado_actual';
  static const String _prefsKeyTiempo = 'tiempo_transcurrido_ms';

  @override
  void initState() {
    super.initState();
    _cargarEstadoDesdeSharedPreferences(); // Cargar estado al iniciar
  }

  Future<void> _cargarEstadoDesdeSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    // Recuperar el estado
    String estadoStr = prefs.getString(_prefsKeyEstado) ?? 'none';
    _estadoActual = _stringToEstadoAyuno(estadoStr);

    // Recuperar el tiempo transcurrido en milisegundos
    int tiempoMs = prefs.getInt(_prefsKeyTiempo) ?? 0;
    _elapsedTime = Duration(milliseconds: tiempoMs);

    // Si el estado era Fasting o Feeding, se debe reanudar el temporizador
    if (_estadoActual != EstadoAyuno.none) {
      _startTimer(); // Iniciar el temporizador sin reiniciar _elapsedTime
    }

    // Llama a setState para actualizar la UI con los valores cargados
    setState(() {});
  }

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

  // Función auxiliar para convertir EstadoAyuno a String
  String _estadoAyunoToString(EstadoAyuno estado) {
    switch (estado) {
      case EstadoAyuno.fasting:
        return 'fasting';
      case EstadoAyuno.feeding:
        return 'feeding';
      case EstadoAyuno.none:
        return 'none';
    }
  }

  // Método para guardar estado y tiempo
  Future<void> _guardarEstadoEnSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKeyEstado, _estadoAyunoToString(_estadoActual));
    await prefs.setInt(_prefsKeyTiempo, _elapsedTime.inMilliseconds);
  }

  void _startTimer() {
    _stopTimer();

    /* _elapsedTime = Duration.zero;
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedTime += Duration(seconds: 1);
      });
    }); */

    // IMPORTANTE: No reiniciar _elapsedTime aquí, se gestiona al inicio o al confirmar acción
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedTime += Duration(seconds: 1);
      });

      _guardarEstadoEnSharedPreferences(); //Cada segundo
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
    _elapsedTime = Duration.zero; // Reiniciar tiempo al iniciar Fasting

    _startTimer();
    setState(() {
      _estadoActual = EstadoAyuno.fasting;
    });

    //_guardarEstadoEnSharedPreferences(); // Guardar estado
  }

  // Función auxiliar para encapsular la lógica de inicio de Feeding
  void _realizarStartFeeding() {
    _elapsedTime = Duration.zero; // Reiniciar tiempo al iniciar Feeding

    _startTimer();
    setState(() {
      _estadoActual = EstadoAyuno.feeding;
    });

    //_guardarEstadoEnSharedPreferences(); // Guardar estado
  }

  // Función para mostrar el diálogo de confirmación
  void _mostrarDialogoConfirmacion(String accion, VoidCallback onConfirmar) {
    String texto = '';

    if (_estadoActual == EstadoAyuno.none) {
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
    _guardarEstadoEnSharedPreferences(); // Tal vez no sea necesario de momento si se guarda cada segundo
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
