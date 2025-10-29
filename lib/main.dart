import 'dart:async';
import 'services/simulador_service.dart';
import 'services/mysql_service.dart';
import 'models/filial.dart';
import 'models/sensor.dart';
import 'models/leitura_sensor.dart';

void main() async {
  print('SISTEMA PACKBAG - ORM COMPLETO');
  print('Sensores: PIR HC-SR501 + DHT11');
  print('Filiais: Aguai e Casa Branca');
  print('MySQL ORM + Firebase + Dados Excel');

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

Future<void> demonstrarORM() async {
  print('\nDEMONSTRANDO OPERACOES ORM:');
  
  final filiais = await MySQLService.buscarFiliais();
  print('Filiais encontradas: ${filiais.length}');
  for (var filial in filiais) {
    print(' - ${filial.nome} (${filial.cidade}/${filial.estado})');
  }
  
  final sensores = await MySQLService.buscarSensores();
  print('Sensores ativos: ${sensores.length}');
  for (var sensor in sensores) {
    print(' - ${sensor.tipo} (ID:${sensor.id}) - ${sensor.localizacao}');
  }
  
  final leituras = await MySQLService.buscarLeituras(limite: 5);
  print('Ultimas leituras: ${leituras.length}');
  for (var leitura in leituras) {
    print(' - ${leitura.toString()}');
  }
}

Future<void> demonstrarConsultasORM() async {
  print('\nCONSULTAS ORM APOS SIMULACAO:');
  
  final leiturasRecentes = await MySQLService.buscarLeituras(limite: 10);
  print('Leituras totais no banco: ${leiturasRecentes.length}');
  
  final leiturasAguai = await MySQLService.buscarLeituras(idFilial: 1, limite: 3);
  print('Leituras Aguai: ${leiturasAguai.length}');
  
  final leiturasSensor2 = await MySQLService.buscarLeiturasPorSensor(2, limite: 3);
  print('Leituras Sensor 2: ${leiturasSensor2.length}');
}
