import 'dart:async';
import 'services/simulador_service.dart';

void main() async {
  print('🚀 SISTEMA PACKBAG INICIADO');
  print('📡 Simulando sensores PIR HC-SR501 + DHT11');
  print('🏢 Filiais: Aguai e Casa Branca\n');

  final simulador = SimuladorService();
 
  // Simular leituras a cada 5 segundos
  Timer.periodic(Duration(seconds: 5), (timer) async {
    try {
      final leitura = await simulador.gerarLeituraSimulada();
      print('✅ ${leitura.toString()}');
    } catch (e) {
      print('❌ Erro na simulação: $e');
    }
  });

  // Parar após 1 minuto (para teste)
  Timer(Duration(minutes: 1), () {
    print('\n🛑 Simulação finalizada');
    timer.cancel();
  });
}
