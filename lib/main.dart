import 'dart:async';
import 'services/simulador_service.dart';
import 'services/mysql_service.dart';
import 'models/filial.dart';
import 'models/sensor.dart';
import 'models/leitura_sensor.dart';

void main() async {
  print('🚀 SISTEMA PACKBAG - ORM COMPLETO');
  print('📡 Sensores: PIR HC-SR501 + DHT11');
  print('🏢 Filiais: Aguai e Casa Branca');
  print('💾 MySQL ORM + 🔥 Firebase + 📊 Dados Excel\n');

  // Testar conexão e ORM
  await MySQLService.testarConexao();
  
  // Demonstrar operações ORM
  await demonstrarORM();

  final simulador = SimuladorService();
  var contador = 0;

  // Simular por 2 minutos
  final timer = Timer.periodic(Duration(seconds: 5), (timer) async {
    contador++;
    
    try {
      print('\n--- Leitura ${contador} ---');
      final leitura = await simulador.gerarLeituraSimulada();
      print('✅ ${leitura.toString()}');
      
      // Salvar via ORM
      await MySQLService.salvarLeitura(leitura);
    } catch (e) {
      print('❌ Erro na leitura: $e');
    }

    // Parar após 10 leituras
    if (contador >= 10) {
      timer.cancel();
      await demonstrarConsultasORM();
      print('\n🎯 SIMULAÇÃO CONCLUÍDA!');
    }
  });
}

// Demonstrar operações ORM
Future<void> demonstrarORM() async {
  print('\n🔍 DEMONSTRANDO OPERAÇÕES ORM:');
  
  // 1. Buscar filiais
  final filiais = await MySQLService.buscarFiliais();
  print('🏢 Filiais encontradas: ${filiais.length}');
  for (var filial in filiais) {
    print('   - ${filial.nome} (${filial.cidade}/${filial.estado})');
  }
  
  // 2. Buscar sensores
  final sensores = await MySQLService.buscarSensores();
  print('📡 Sensores ativos: ${sensores.length}');
  for (var sensor in sensores) {
    print('   - ${sensor.tipo} (ID:${sensor.id}) - ${sensor.localizacao}');
  }
  
  // 3. Buscar leituras recentes
  final leituras = await MySQLService.buscarLeituras(limite: 5);
  print('📊 Últimas leituras: ${leituras.length}');
  for (var leitura in leituras) {
    print('   - ${leitura.toString()}');
  }
}

// Demonstrar consultas após simulação
Future<void> demonstrarConsultasORM() async {
  print('\n🔍 CONSULTAS ORM APÓS SIMULAÇÃO:');
  
  // Buscar todas as leituras da simulação
  final leiturasRecentes = await MySQLService.buscarLeituras(limite: 10);
  print('📊 Leituras totais no banco: ${leiturasRecentes.length}');
  
  // Buscar leituras por filial
  final leiturasAguai = await MySQLService.buscarLeituras(idFilial: 1, limite: 3);
  print('🏢 Leituras Aguai: ${leiturasAguai.length}');
  
  // Buscar leituras por sensor específico
  final leiturasSensor2 = await MySQLService.buscarLeiturasPorSensor(2, limite: 3);
  print('📡 Leituras Sensor 2: ${leiturasSensor2.length}');
}
