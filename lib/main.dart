import 'dart:async';
import 'services/simulador_service.dart';

void main() async {
  print('🚀 SISTEMA PACKBAG - VERSÃO COMPLETA');
  print('📡 Sensores: PIR HC-SR501 + DHT11');
  print('🏢 Filiais: Aguai e Casa Branca');
  print('💾 MySQL + 🔥 Firebase + 📊 Dados Excel\n');

  final simulador = SimuladorService();
  var contador = 0;

  // Simular por 2 minutos
  final timer = Timer.periodic(Duration(seconds: 5), (timer) async {
    contador++;
    
    try {
      print('\n--- Leitura ${contador} ---');
      final leitura = await simulador.gerarLeituraSimulada();
      print('✅ ${leitura.toString()}');
    } catch (e) {
      print('❌ Erro na leitura: $e');
    }

    // Parar após 10 leituras
    if (contador >= 10) {
      timer.cancel();
      print('\n🎯 SIMULAÇÃO CONCLUÍDA!');
      print('💡 Verifique os dados no MySQL Workbench:');
      print('   SELECT * FROM FATO_LEITURAS ORDER BY Timestamp DESC;');
    }
  });
}
