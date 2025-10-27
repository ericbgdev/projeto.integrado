import 'services/simulador_service.dart';
import 'services/mysql_service.dart';
import 'services/firebase_service.dart';

void main() async {
  print('🚀 SISTEMA PACKBAG - FIREBASE + SQL + EXCEL + SIMULAÇÃO');
  
  final simulador = SimuladorService();

  // Simular leituras a cada 3 segundos
  Timer.periodic(Duration(seconds: 3), (timer) async {
    final leitura = await simulador.gerarLeitura();
    print('📡 Leitura: ${leitura.filial} - ${leitura.tipoSensor}');
    
    if (leitura.temperatura != null) {
      print('   🌡️ Temperatura: ${leitura.temperatura!.toStringAsFixed(1)}°C');
    }
    if (leitura.movimentoDetectado) {
      print('   🏃 Movimento Detectado!');
    }
  });
}
