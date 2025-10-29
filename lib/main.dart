import 'dart:async';
import 'services/simulador_service.dart';
import 'services/mysql_service.dart';
import 'services/firebase_service.dart';
import 'models/filial.dart';
import 'models/sensor.dart';
import 'models/leitura_sensor.dart';

void main() async {
  print('SISTEMA PACKBAG - ORM COMPLETO');
  print('Sensores: PIR HC-SR501 + DHT11');
  print('Filiais: Aguai e Casa Branca');
  print('MySQL ORM + Firebase + Dados Excel');

  // Inicializar Firebase
  await FirebaseService.initialize();
  await MySQLService.testarConexao();
  
  await demonstrarORM();

  final simulador = SimuladorService();
  var contador = 0;

  final timer = Timer.periodic(Duration(seconds: 5), (timer) async {
    contador++;
    
    try {
      print('\n--- Leitura $contador ---');
      final leitura = await simulador.gerarLeituraSimulada();
      print('Leitura: ${leitura.toString()}');
    } catch (e) {
      print('Erro na leitura: $e');
    }

    if (contador >= 10) {
      timer.cancel();
      await demonstrarConsultasORM();
      print('\nSIMULACAO CONCLUIDA!');
    }
  });
}

// ... (manter métodos demonstrarORM e demonstrarConsultasORM)
