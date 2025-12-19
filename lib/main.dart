import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mi_ayuno_intermitente/splash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mi_ayuno_intermitente/pages/ayuda.dart';
import 'package:mi_ayuno_intermitente/pages/configuracion.dart';
import 'package:mi_ayuno_intermitente/pages/historico.dart';

// Definición del enum para los estados de la aplicación
enum EstadoAyuno { fasting, feeding, none }

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mi Ayuno Intermitente',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  // ignore: library_private_types_in_public_api
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  DateTime? _ultimoCambioTimestamp;
  Timer? _timer;
  EstadoAyuno _estadoActual = EstadoAyuno.none;

  // Claves para SharedPreferences
  static const String _prefsKeyEstado = 'estado_actual';
  static const String _prefsKeyTimestamp = 'ultimo_cambio_timestamp';
  static const String _prefsKeyHorasAlimentacion = 'horas_alimentacion';

  int _horasAlimentacionConfiguradas = 8; // Valor por defecto temporal

  // --- OBJETIVO ---
  /* static const Duration _objetivoFeeding = Duration(
    hours: 8,
  ); // Constante de objetivo
  // El objetivo de ayuno es el tiempo restante en un día
  // Cambiamos 'const' por 'final'
  static final Duration _objetivoFasting =
      Duration(hours: 24) - _objetivoFeeding; // 24 - 8 = 16 horas */
  Duration _objetivoFeeding = Duration(
    hours: 8,
  ); // Inicializado con valor por defecto, se actualizará
  Duration _objetivoFasting = Duration(
    hours: 16,
  ); // Inicializado con valor por defecto, se actualizará

  @override
  void initState() {
    super.initState();
    //_cargarEstadoDesdeSharedPreferences(); // Cargar estado al iniciar
    _cargarHorasAlimentacionConfiguradas().then((_) {
      // --- ACTUALIZAR OBJETIVOS DESPUÉS DE CARGAR LAS HORAS ---
      _actualizarObjetivos();
      // --- LUEGO CARGAR EL ESTADO DEL CRONÓMETRO ---
      _cargarEstadoDesdeSharedPreferences();
    });
  }

  // --- FUNCIÓN PARA CARGAR LAS HORAS DESDE SHARED PREFERENCES ---
  Future<void> _cargarHorasAlimentacionConfiguradas() async {
    /* final prefs = await SharedPreferences.getInstance();
    int horas =
        prefs.getInt(_prefsKeyHorasAlimentacion) ?? 8; // Valor por defecto 8
    //int horas = 8; */

    final prefs = await SharedPreferences.getInstance();
    String? horasStr = prefs.getString(_prefsKeyHorasAlimentacion);
    int horas = 8; // Valor por defecto
    if (horasStr != null) {
      int? horasParsed = int.tryParse(horasStr);
      if (horasParsed != null && horasParsed >= 0 && horasParsed <= 24) {
        horas = horasParsed;
      }
      // Si la conversión falla o el valor no es válido, se mantiene el valor por defecto (8)
    }

    setState(() {
      _horasAlimentacionConfiguradas = horas;
    });
  }

  // --- FUNCIÓN PARA ACTUALIZAR LOS OBJETIVOS CON BASE EN LAS HORAS CARGADAS ---
  void _actualizarObjetivos() {
    setState(() {
      _objetivoFeeding = Duration(hours: _horasAlimentacionConfiguradas);
      _objetivoFasting = Duration(hours: 24) - _objetivoFeeding;
    });
  }

  Future<void> _cargarEstadoDesdeSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    // Recuperar el estado
    String estadoStr = prefs.getString(_prefsKeyEstado) ?? 'none';
    _estadoActual = _stringToEstadoAyuno(estadoStr);

    // Recuperar el tiempo transcurrido en milisegundos
    int? timestampMs = prefs.getInt(_prefsKeyTimestamp);
    if (timestampMs != null) {
      _ultimoCambioTimestamp = DateTime.fromMillisecondsSinceEpoch(timestampMs);
    } else {
      // Si no hay timestamp guardado (primera vez), dejar _ultimoCambioTimestamp como null
      _ultimoCambioTimestamp = null;
    }

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
    if (_ultimoCambioTimestamp != null) {
      await prefs.setInt(
        _prefsKeyTimestamp,
        _ultimoCambioTimestamp!.millisecondsSinceEpoch,
      );
    } else {
      // Si es null, lo borramos o guardamos null como 0 o no lo guardamos, dependiendo de la lógica.
      // Es mejor borrarlo si es null para evitar inconsistencias.
      await prefs.remove(_prefsKeyTimestamp);
    }
  }

  Future<void> _resetearEstado() async {
    _stopTimer(); // Detener el temporizador actual

    // Resetear variables locales
    _estadoActual = EstadoAyuno.none;
    _ultimoCambioTimestamp = null;

    // Limpiar datos persistentes
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKeyEstado);
    await prefs.remove(_prefsKeyTimestamp);

    // Actualizar la UI
    setState(() {});
  }

  void _startTimer() {
    _stopTimer(); // Detiene cualquier temporizador anterior

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      // No es necesario setState aquí solo para guardar, pero sí para actualizar el display
      // Calculamos el tiempo transcurrido desde _ultimoCambioTimestamp
      // Solo actualizamos la UI si hay un timestamp válido
      if (_ultimoCambioTimestamp != null) {
        setState(() {
          // _elapsedTime calculado dinámicamente
        });
      }
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
    _ultimoCambioTimestamp = DateTime.now(); // Registrar la fecha/hora actual

    _startTimer();
    setState(() {
      _estadoActual = EstadoAyuno.fasting;
    });

    _guardarEstadoEnSharedPreferences(); // Guardar estado
  }

  // Función auxiliar para encapsular la lógica de inicio de Feeding
  void _realizarStartFeeding() {
    _ultimoCambioTimestamp = DateTime.now(); // Registrar la fecha/hora actual

    _startTimer();
    setState(() {
      _estadoActual = EstadoAyuno.feeding;
    });

    _guardarEstadoEnSharedPreferences(); // Guardar estado
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

  void _mostrarDialogoConfirmacionReset() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmar Reset'),
          content: Text(
            '¿Estás seguro de que quieres resetear la aplicación? Se perderán los datos actuales.',
          ),
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
                _resetearEstado(); // Ejecuta la acción de reseteo
              },
              child: Text('Resetear'),
            ),
          ],
        );
      },
    );
  }

  // --- NUEVA FUNCIÓN: Calcular tiempo restante para el objetivo actual (Feeding o Fasting) ---
  String _getTiempoRestanteObjetivo() {
    if (_estadoActual == EstadoAyuno.none || _ultimoCambioTimestamp == null) {
      // Si no hay estado o no hay timestamp, no mostrar tiempo restante
      return ''; // O un mensaje como "No activo"
    }

    Duration tiempoTranscurrido = DateTime.now().difference(
      _ultimoCambioTimestamp!,
    );
    Duration objetivoActual = _estadoActual == EstadoAyuno.feeding
        ? _objetivoFeeding
        : _objetivoFasting;
    Duration tiempoRestante = objetivoActual - tiempoTranscurrido;

    if (tiempoRestante.isNegative) {
      return 'Tiempo superado';
    } else {
      // Formatear la duración restante como HH:MM
      int horas = tiempoRestante.inHours;
      int minutos = tiempoRestante.inMinutes.remainder(60);
      String horasStr = horas.toString().padLeft(2, '0');
      String minutosStr = minutos.toString().padLeft(2, '0');
      String estadoStr = _estadoActual == EstadoAyuno.feeding
          ? 'ayuno'
          : 'alimentación';
      return 'Faltan $horasStr:$minutosStr horas para $estadoStr';
    }
  }

  Duration get _elapsedTime {
    if (_ultimoCambioTimestamp != null && _estadoActual != EstadoAyuno.none) {
      return DateTime.now().difference(_ultimoCambioTimestamp!);
    } else {
      // Si no hay timestamp o el estado es 'none', devolver Duration.zero
      return Duration.zero;
    }
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

  // FUNCIÓN PARA NAVEGAR A OTRAS PÁGINAS DESDE LA BARRA
  void _irAPagina(Widget pagina) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => pagina));
  }

  // FUNCIÓN PARA MANEJAR LA SELECCIÓN DE LA BARRA
  void _onItemTapped(int index) {
    switch (index) {
      case 0: // Ayuda
        _irAPagina(AyudaPage());
        break;
      case 1: // Configuración
        _irAPagina(ConfiguracionPage());
        break;
      case 2: // Histórico
        _irAPagina(HistoricoPage());
        break;
    }
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
                color: Colors.brown, // Cambiar color si se desea
                fontWeight: FontWeight.w600, // Grosor de la fuente
              ),
              textAlign: TextAlign.center,
            ),
            // --- NUEVO WIDGET: Mostrar tiempo restante para el objetivo ---
            // Mostrar solo en modo Feeding o Fasting
            if (_estadoActual != EstadoAyuno.none)
              Padding(
                padding: const EdgeInsets.all(16.0), // Espacio alrededor
                child: Text(
                  _getTiempoRestanteObjetivo(), // Llama a la nueva función
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    // Puedes usar otro estilo si prefieres
                    //fontSize: 18,
                    //fontWeight: FontWeight.w500,
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
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
            SizedBox(height: 20), // Espacio adicional antes del botón de reset
            ElevatedButton(
              onPressed:
                  _mostrarDialogoConfirmacionReset, // Llama al diálogo de confirmación
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.grey[600], // Color gris para diferenciarlo
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              ),
              child: Text('Resetear', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        // Barra de navegación inferior
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.help), label: 'Ayuda'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Configuración',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Histórico',
          ),
        ],
        currentIndex:
            0, // Siempre se muestra como seleccionado el índice 0 (cronómetro)
        onTap: _onItemTapped, // Manejar la pulsación
      ),
    );
  }
}
