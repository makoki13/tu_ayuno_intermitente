import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mi_ayuno_intermitente/splash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mi_ayuno_intermitente/notification_service.dart';

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
  Timer? _autoChangeTimer; // Timer para la comprobación automática
  Timer? _warningTimer; // Timer para la verificación de advertencia de 60 minutos
  EstadoAyuno _estadoActual = EstadoAyuno.none;

  // Claves para SharedPreferences
  static const String _prefsKeyEstado = 'estado_actual';
  static const String _prefsKeyTimestamp = 'ultimo_cambio_timestamp';
  static const String _prefsKeyHorasAlimentacion = 'horas_alimentacion';
  static const String _prefsKeyCambioAutomatico = 'cambio_automatico';

  int _horasAlimentacionConfiguradas = 8; // Valor por defecto temporal
  bool _cambioAutomaticoHabilitado = false; // Valor para cambio automático

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

  // Para controlar la notificación de advertencia
  bool _warningNotificationShown = false;
  static const int _warningNotificationId = 1001;

  // Para el sistema de logging de sesiones
  static const String _prefsKeySesiones = 'sesiones_registro';
  List<Map<String, dynamic>> _registroSesiones = [];

  @override
  void initState() {
    super.initState();
    //_cargarEstadoDesdeSharedPreferences(); // Cargar estado al iniciar

    // Initialize notification service
    NotificationService().initialize();

    _cargarPreferencias().then((_) {
      // --- CARGAR EL REGISTRO DE SESIONES ---
      _cargarRegistroSesiones();
      // --- ACTUALIZAR OBJETIVOS DESPUÉS DE CARGAR LAS HORAS ---
      _actualizarObjetivos();
      // --- LUEGO CARGAR EL ESTADO DEL CRONÓMETRO ---
      _cargarEstadoDesdeSharedPreferences();
      // --- INICIAR EL TEMPORIZADOR DE CAMBIO AUTOMÁTICO ---
      _iniciarAutoChangeTimer();
      // --- INICIAR EL TEMPORIZADOR DE ADVERTENCIA ---
      _iniciarWarningTimer();
    });
  }

  // --- FUNCIÓN PARA CARGAR LAS PREFERENCIAS DESDE SHARED PREFERENCES ---
  Future<void> _cargarPreferencias() async {
    final prefs = await SharedPreferences.getInstance();

    // Cargar horas de alimentación
    String? horasStr = prefs.getString(_prefsKeyHorasAlimentacion);
    int horas = 8; // Valor por defecto
    if (horasStr != null) {
      int? horasParsed = int.tryParse(horasStr);
      if (horasParsed != null && horasParsed >= 0 && horasParsed <= 24) {
        horas = horasParsed;
      }
      // Si la conversión falla o el valor no es válido, se mantiene el valor por defecto (8)
    }

    // Cargar cambio automático
    bool cambioAutomatico = prefs.getBool(_prefsKeyCambioAutomatico) ?? false;

    setState(() {
      _horasAlimentacionConfiguradas = horas;
      _cambioAutomaticoHabilitado = cambioAutomatico;
    });
  }

  // --- FUNCIÓN PARA CARGAR EL REGISTRO DE SESIONES ---
  Future<void> _cargarRegistroSesiones() async {
    final prefs = await SharedPreferences.getInstance();
    final sesionesJson = prefs.getStringList(_prefsKeySesiones) ?? [];

    _registroSesiones = sesionesJson.map((json) {
      Map<String, dynamic> map = Map<String, dynamic>.from(
        Map<String, dynamic>.from(jsonDecode(json))
      );
      return map;
    }).toList();
  }

  // --- FUNCIÓN PARA GUARDAR EL REGISTRO DE SESIONES ---
  Future<void> _guardarRegistroSesiones() async {
    final prefs = await SharedPreferences.getInstance();
    final sesionesJson = _registroSesiones.map((sesion) => jsonEncode(sesion)).toList();
    await prefs.setStringList(_prefsKeySesiones, sesionesJson);
  }

  // --- FUNCIÓN PARA AGREGAR UNA NUEVA SESIÓN AL REGISTRO ---
  Future<void> _agregarSesionAlRegistro(EstadoAyuno estado, Duration duracion, DateTime inicio, DateTime fin) async {
    final nuevaSesion = {
      'id': DateTime.now().millisecondsSinceEpoch, // Usar timestamp como ID único
      'estado': _estadoAyunoToString(estado),
      'duracion_horas': duracion.inHours,
      'duracion_minutos': duracion.inMinutes.remainder(60),
      'duracion_segundos': duracion.inSeconds.remainder(60),
      'fecha_inicio': inicio.toIso8601String(),
      'fecha_fin': fin.toIso8601String(),
      'timestamp_registro': DateTime.now().millisecondsSinceEpoch,
    };

    _registroSesiones.add(nuevaSesion);
    await _guardarRegistroSesiones();
  }

  // --- FUNCIÓN PARA ACTUALIZAR LOS OBJETIVOS CON BASE EN LAS HORAS CARGADAS ---
  void _actualizarObjetivos() {
    setState(() {
      _objetivoFeeding = Duration(hours: _horasAlimentacionConfiguradas);
      _objetivoFasting = Duration(hours: 24) - _objetivoFeeding;
    });

    // Reiniciar la notificación de advertencia cuando se actualizan los objetivos
    _warningNotificationShown = false;

    // Verificar si hay que hacer un cambio automático después de actualizar objetivos
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verificarCambioAutomatico();
    });
  }

  // --- MÉTODO PARA INICIAR EL TEMPORIZADOR DE CAMBIO AUTOMÁTICO ---
  void _iniciarAutoChangeTimer() {
    // Cancelar cualquier timer anterior
    _detenerAutoChangeTimer();

    // Iniciar un nuevo timer que verifica cada minuto
    _autoChangeTimer = Timer.periodic(Duration(minutes: 1), (timer) async {
      // Cargar la configuración actual de cambio automático periódicamente
      await _cargarCambioAutomaticoSetting();
      _verificarCambioAutomatico();
    });
  }

  // --- MÉTODO PARA CARGAR SÓLO LA CONFIGURACIÓN DE CAMBIO AUTOMÁTICO ---
  Future<void> _cargarCambioAutomaticoSetting() async {
    final prefs = await SharedPreferences.getInstance();
    bool cambioAutomatico = prefs.getBool(_prefsKeyCambioAutomatico) ?? false;

    setState(() {
      _cambioAutomaticoHabilitado = cambioAutomatico;
    });
  }

  // --- MÉTODO PARA DETENER EL TEMPORIZADOR DE CAMBIO AUTOMÁTICO ---
  void _detenerAutoChangeTimer() {
    if (_autoChangeTimer != null && _autoChangeTimer!.isActive) {
      _autoChangeTimer!.cancel();
    }
  }

  // --- MÉTODO PARA INICIAR EL TEMPORIZADOR DE ADVERTENCIA ---
  void _iniciarWarningTimer() {
    // Cancelar cualquier timer anterior
    _detenerWarningTimer();

    // Iniciar un nuevo timer que verifica cada minuto
    _warningTimer = Timer.periodic(Duration(minutes: 1), (timer) {
      _verificarAdvertenciaCambio();
    });
  }

  // --- MÉTODO PARA DETENER EL TEMPORIZADOR DE ADVERTENCIA ---
  void _detenerWarningTimer() {
    if (_warningTimer != null && _warningTimer!.isActive) {
      _warningTimer!.cancel();
    }
  }

  // --- MÉTODO PARA VERIFICAR SI ES NECESARIO MOSTRAR UNA ADVERTENCIA DE CAMBIO ---
  void _verificarAdvertenciaCambio() async {
    // Si el estado actual es 'none', no hacer nada
    if (_estadoActual == EstadoAyuno.none || _ultimoCambioTimestamp == null) {
      return;
    }

    // Calcular el tiempo transcurrido
    Duration tiempoTranscurrido = DateTime.now().difference(_ultimoCambioTimestamp!);

    // Determinar el objetivo actual según el estado
    Duration objetivoActual = _estadoActual == EstadoAyuno.feeding ? _objetivoFeeding : _objetivoFasting;

    // Calcular el tiempo restante para el cambio
    Duration tiempoRestante = objetivoActual - tiempoTranscurrido;

    // Verificar si faltan 60 minutos o menos para el cambio
    if (tiempoRestante.inMinutes <= 60 &&
        tiempoRestante.inMinutes > 0 &&
        !_warningNotificationShown) {
      // Mostrar notificación de advertencia
      await _mostrarAdvertenciaCambio();
      _warningNotificationShown = true;
    }
    // Reiniciar el indicador si ya pasó el tiempo de advertencia
    else if (tiempoRestante.isNegative && _warningNotificationShown) {
      _warningNotificationShown = false;
    }
  }

  // --- MÉTODO PARA MOSTRAR LA ADVERTENCIA DE CAMBIO ---
  Future<void> _mostrarAdvertenciaCambio() async {
    String titulo = '';
    String cuerpo = '';

    if (_estadoActual == EstadoAyuno.feeding) {
      titulo = 'Cambio a Ayuno';
      cuerpo = 'Faltan 60 minutos para que termine el periodo de alimentación';
    } else if (_estadoActual == EstadoAyuno.fasting) {
      titulo = 'Cambio a Alimentación';
      cuerpo = 'Faltan 60 minutos para que termine el periodo de ayuno';
    }

    await NotificationService().showWarningNotification(
      title: titulo,
      body: cuerpo,
      id: _warningNotificationId,
    );
  }

  // --- MÉTODO PARA VERIFICAR SI ES NECESARIO CAMBIAR DE ESTADO AUTOMÁTICAMENTE ---
  void _verificarCambioAutomatico() {
    // Si el estado actual es 'none' o el cambio automático está deshabilitado, no hacer nada
    if (_estadoActual == EstadoAyuno.none || !_cambioAutomaticoHabilitado) {
      return;
    }

    // Verificar si ha pasado el tiempo objetivo
    if (_ultimoCambioTimestamp != null) {
      Duration tiempoTranscurrido = DateTime.now().difference(
        _ultimoCambioTimestamp!,
      );

      bool debeCambiar = false;

      if (_estadoActual == EstadoAyuno.feeding) {
        // Si estamos en estado feeding, cambiar si hemos superado el objetivo de alimentación
        if (tiempoTranscurrido > _objetivoFeeding) {
          debeCambiar = true;
        }
      } else if (_estadoActual == EstadoAyuno.fasting) {
        // Si estamos en estado fasting, cambiar si hemos alcanzado o superado el objetivo de ayuno
        if (tiempoTranscurrido >= _objetivoFasting) {
          debeCambiar = true;
        }
      }

      if (debeCambiar) {
        // Cambiar de estado
        if (_estadoActual == EstadoAyuno.fasting) {
          _realizarStartFeeding();
        } else if (_estadoActual == EstadoAyuno.feeding) {
          _realizarStartFasting();
        }
      }
    }
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

    // Verificar inmediatamente si hay que hacer un cambio automático al cargar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verificarCambioAutomatico();
    });
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

    // Si hay un estado activo, registrar la sesión antes de resetear
    if (_estadoActual != EstadoAyuno.none && _ultimoCambioTimestamp != null) {
      Duration duracionSesion = DateTime.now().difference(_ultimoCambioTimestamp!);
      await _agregarSesionAlRegistro(_estadoActual, duracionSesion, _ultimoCambioTimestamp!, DateTime.now());
    }

    // Resetear variables locales
    _estadoActual = EstadoAyuno.none;
    _ultimoCambioTimestamp = null;

    // Reiniciar la notificación de advertencia al resetear
    _warningNotificationShown = false;

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
  void _realizarStartFasting() async {
    // Si hay un estado anterior activo, registrar la sesión antes de cambiar
    if (_estadoActual != EstadoAyuno.none && _ultimoCambioTimestamp != null) {
      Duration duracionSesion = DateTime.now().difference(_ultimoCambioTimestamp!);
      await _agregarSesionAlRegistro(_estadoActual, duracionSesion, _ultimoCambioTimestamp!, DateTime.now());
    }

    _ultimoCambioTimestamp = DateTime.now(); // Registrar la fecha/hora actual

    _startTimer();
    setState(() {
      _estadoActual = EstadoAyuno.fasting;
    });

    // Reiniciar la notificación de advertencia al cambiar de estado
    _warningNotificationShown = false;

    _guardarEstadoEnSharedPreferences(); // Guardar estado
  }

  // Función auxiliar para encapsular la lógica de inicio de Feeding
  void _realizarStartFeeding() async {
    // Si hay un estado anterior activo, registrar la sesión antes de cambiar
    if (_estadoActual != EstadoAyuno.none && _ultimoCambioTimestamp != null) {
      Duration duracionSesion = DateTime.now().difference(_ultimoCambioTimestamp!);
      await _agregarSesionAlRegistro(_estadoActual, duracionSesion, _ultimoCambioTimestamp!, DateTime.now());
    }

    _ultimoCambioTimestamp = DateTime.now(); // Registrar la fecha/hora actual

    _startTimer();
    setState(() {
      _estadoActual = EstadoAyuno.feeding;
    });

    // Reiniciar la notificación de advertencia al cambiar de estado
    _warningNotificationShown = false;

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
      return 'Faltan $horasStr:$minutosStr horas para el cambio a $estadoStr';
    }
  }

  // --- NUEVA FUNCIÓN: Obtener texto de modo (manual o automático) ---
  String _getModoTexto() {
    return _cambioAutomaticoHabilitado ? 'cambio automático' : 'cambio manual';
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
    _detenerAutoChangeTimer(); // Detener el timer de cambio automático
    _detenerWarningTimer(); // Detener el timer de advertencia
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
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                  Text(
                    _getModoTexto(), // Texto que indica si es manual o automático
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
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
