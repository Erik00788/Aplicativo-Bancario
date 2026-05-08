import 'package:flutter/material.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Hello World!'),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:vibration/vibration.dart';

void main() => runApp(MaterialApp(home: AppSegurancaBancaria()));

class AppSegurancaBancaria extends StatefulWidget {
  @override
  _AppSegurancaBancariaState createState() => _AppSegurancaBancariaState();
}

class _AppSegurancaBancariaState extends State<AppSegurancaBancaria> {
  final _notificacoes = FlutterLocalNotificationsPlugin();
  String _statusCamera = "Verificando..."; // Nível 1
  double _eixoX = 0, _eixoY = 0, _eixoZ = 0; // Nível 2
  String _logEvento = "Nenhum movimento detectado"; // Nível 6
  bool _podeNotificar = true; // Nível 5

  @override
  void initState() {
    super.initState();
    _inicializarConfiguracoes();
  }

  void _inicializarConfiguracoes() async {
    // Nível 1: Solicitar permissão de câmera
    var status = await Permission.camera.request();
    setState(() => _statusCamera = status.isGranted ? "Concedida" : "Negada");

    // Nível 4: Configurar notificações locais
    await _notificacoes.initialize(const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ));

    // Níveis 2, 3, 5 e 6: Monitorar acelerômetro e lógica anti-furto
    accelerometerEvents.listen((event) {
      setState(() {
        _eixoX = event.x; _eixoY = event.y; _eixoZ = event.z;
      });

      // Nível 3 e 6: Regra de movimento brusco (X > 8)
      if (event.x.abs() > 8 && _podeNotificar) {
        _dispararSistemaAntiFurto();
      }
    });
  }

  void _dispararSistemaAntiFurto() async {
    _podeNotificar = false; // Nível 5: Início do bloqueio de spam

    // Nível 6: Registrar horário do evento
    final hora = DateTime.now().toString().substring(11, 19);

    // Nível 6: Vibrar dispositivo
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 500);
    }

    // Nível 4 e 6: Emitir notificação local
    _notificacoes.show(0, "ALERTA ANTI-FURTO", "Movimento detectado às $hora", null);

    setState(() => _logEvento = "MOVIMENTO DETECTADO: $hora");

    // Nível 5: Aguardar 10 segundos para permitir novo evento
    Future.delayed(Duration(seconds: 10), () {
      setState(() => _podeNotificar = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Banco Digital - Segurança"), backgroundColor: Colors.blueGrey),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            // UI Nível 1
            ListTile(
              leading: Icon(Icons.camera_alt),
              title: Text("Permissão de Câmera"),
              subtitle: Text(_statusCamera),
            ),
            Divider(),
            // UI Nível 2
            Text("Monitoramento em Tempo Real:", style: TextStyle(fontWeight: FontWeight.bold)),
            Text("X: ${_eixoX.toStringAsFixed(2)} | Y: ${_eixoY.toStringAsFixed(2)} | Z: ${_eixoZ.toStringAsFixed(2)}"),
            SizedBox(height: 30),
            // UI Nível 3, 5 e 6
            Container(
              padding: EdgeInsets.all(20),
              color: _podeNotificar ? Colors.green[50] : Colors.red[100],
              child: Column(
                children: [
                  Icon(_podeNotificar ? Icons.shield : Icons.warning, size: 50, color: _podeNotificar ? Colors.green : Colors.red),
                  SizedBox(height: 10),
                  Text(_logEvento, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  if (!_podeNotificar) Text("\nSistema em espera (10s)...", style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}