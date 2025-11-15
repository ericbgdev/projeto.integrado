import 'dart:async';
import 'services/simulador_service.dart';
import 'services/database_service.dart';
import 'services/firebase_realtime_service.dart'; 

Future<void> demonstrarORM() async {
  print('\n=== DEMONSTRANDO DADOS DO BANCO ===');
  
  final filiais = await DatabaseService.getFiliais();
  final sensores = await DatabaseService.getSensores();
  
  print('FILIAIS (${filiais.length}):');
  for (final filial in filiais) {
    print('  ${filial['ID_Filial']}: ${filial['Nome_Filial']} - ${filial['Cidade']}/${filial['Estado']}');
  }
  
  print('\n SENSORES ATIVOS (${sensores.length}):');
  for (final sensor in sensores) {
    print('  ${sensor['ID_Sensor']}: ${sensor['Tipo_Sensor']} - ${sensor['Nome_Filial']}');
  }

  final leituras = await DatabaseService.getLeituras();
  print('\n ÚLTIMAS LEITURAS (${leituras.length} no total):');
  if (leituras.isNotEmpty) {
    final ultimas = leituras.take(3);
    for (final leitura in ultimas) {
      print('  ${leitura['Timestamp']} - Sensor ${leitura['ID_Sensor']}: '
            'Temp: ${leitura['Temperatura']}°C, '
            'Umid: ${leitura['Umidade']}%');
    }
  }
}

Future<void> demonstrarConsultasORM() async {
  print('\n=== ESTATÍSTICAS DO SISTEMA ===');
  
  final estatisticas = await DatabaseService.getEstatisticas();
  estatisticas.forEach((key, value) {
    print('  $key: $value');
  });
  
  final leiturasFirebase = await FirebaseRealtimeService.getLeituras();
  print('\n Leituras no Firebase Real: ${leiturasFirebase.length}');
}

void main() async {
  print('''
 SISTEMA PACKBAG - DART PURO + MySQL + Firebase REAL
 Sensores: PIR HC-SR501 + DHT11
 Filiais: Aguai e Casa Branca
 Banco: entrega5 (MySQL) +  Firebase Realtime Database
''');

  try {
    await DatabaseService.testarConexao();
    await FirebaseRealtimeService.initialize(); // ← MUDANÇA AQUI
    
    await demonstrarORM();

    final simulador = SimuladorService();
    var contador = 0;

    print('\n=== INICIANDO SIMULAÇÃO ===');
    
    final timer = Timer.periodic(Duration(seconds: 3), (timer) async {
      contador++;
      
      try {
        print('\n--- Leitura $contador ---');
        final leitura = await simulador.gerarLeituraSimulada();
        print(' Dados: ${leitura.toString()}');
        
      } catch (e) {
        print(' Erro na leitura: $e');
      }

      if (contador >= 8) {
        timer.cancel();
        await demonstrarConsultasORM();
        print('\n SIMULAÇÃO CONCLUÍDA!');
        print(' Dados salvos no MySQL: entrega5');
        print(' Dados no Firebase Console');
        print('\n Execute novamente: dart main.dart');
      }
    });
    
  } catch (e) {
    print('\n ERRO CRÍTICO: $e');
    print(' Verifique MySQL e Firebase configurados');
  }
}
