// main.dart
import 'dart:async';
import 'services/simulador_service.dart';
import 'services/database_service.dart';
import 'services/firebase_service.dart';
import 'models/leitura_sensor.dart';

Future<void> demonstrarORM() async {
  print('\n=== 🗃️  DEMONSTRANDO ORM ===');
  
  // Mostrar dados do banco
  final filiais = DatabaseService.getFiliais();
  final sensores = DatabaseService.getSensores();
  
  print('Filiais no sistema:');
  for (final filial in filiais) {
    print('  ${filial['ID_Filial']}: ${filial['Nome_Filial']} - ${filial['Cidade']}/${filial['Estado']}');
  }
  
  print('\nSensores ativos:');
  for (final sensor in sensores) {
    final filial = filiais.firstWhere((f) => f['ID_Filial'] == sensor['ID_Filial']);
    print('  ${sensor['ID_Sensor']}: ${sensor['Tipo_Sensor']} - ${filial['Nome_Filial']}');
  }
}

Future<void> demonstrarConsultasORM() async {
  print('\n=== 📊 ESTATÍSTICAS DO SISTEMA ===');
  
  final estatisticas = DatabaseService.getEstatisticas();
  estatisticas.forEach((key, value) {
    print('  $key: $value');
  });
  
  final leiturasFirebase = FirebaseService.getLeiturasFirebase();
  print('\n🔥 Leituras no Firebase: ${leiturasFirebase.length}');
  
  final leiturasDB = DatabaseService.getLeituras();
  print('💾 Leituras no Banco Local: ${leiturasDB.length}');
}

void main() async {
  print('''
🚀 SISTEMA PACKBAG - DART PURO
📡 Sensores: PIR HC-SR501 + DHT11
🏢 Filiais: Aguai e Casa Branca
💾 MySQL Simulado + 🔥 Firebase Simulado
''');

  // Inicializar serviços
  await DatabaseService.initialize();
  await FirebaseService.initialize();
  
  await demonstrarORM();

  final simulador = SimuladorService();
  var contador = 0;

  print('\n=== 🎯 INICIANDO SIMULAÇÃO ===');
  
  final timer = Timer.periodic(Duration(seconds: 2), (timer) async {
    contador++;
    
    try {
      print('\n--- 📝 Leitura $contador ---');
      final leitura = await simulador.gerarLeituraSimulada();
      print('📊 Dados: ${leitura.toString()}');
      
      // Salvar no banco
      await DatabaseService.salvarLeitura(leitura);
      
    } catch (e) {
      print('❌ Erro na leitura: $e');
    }

    if (contador >= 10) {
      timer.cancel();
      await demonstrarConsultasORM();
      print('\n✅ SIMULAÇÃO CONCLUÍDA!');
      print('💾 Dados salvos em: database.json');
      print('🔥 Dados Firebase em: firebase_data.json');
      print('📋 Log completo em: leituras_log.txt');
      print('\n🎯 Execute novamente: dart main.dart');
    }
  });
}
