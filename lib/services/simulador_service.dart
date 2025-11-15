// ════════════════════════════════════════════════════════════════
// SERVIÇO: SimuladorService
// Gerador de leituras simuladas - Sistema 100 Lâmpadas
// ════════════════════════════════════════════════════════════════

import 'dart:math';
import '../models/leitura_sensor.dart';
import '../data/sensores_data.dart';
import 'database_service.dart';
import 'firebase_realtime_service.dart';

class SimuladorService {
  final Random _random = Random();
  bool _conexoesTestadas = false;
  
  // ════════════════════════════════════════════════════════════════
  // GERAR LEITURA SIMULADA
  // ════════════════════════════════════════════════════════════════
  Future<LeituraSensor> gerarLeituraSimulada() async {
    if (!_conexoesTestadas) {
      await _testarConexoes();
      _conexoesTestadas = true;
    }

    // Selecionar sensor aleatório
    final sensoresIds = SensoresData.sensores.keys.toList();
    final sensorId = sensoresIds[_random.nextInt(sensoresIds.length)];
    final sensor = SensoresData.sensores[sensorId]!;
    final filial = SensoresData.filiais[sensor['id_filial']]!;

    // Variáveis da leitura
    double? temperatura;
    double? umidade;
    bool movimentoDetectado = false;
    bool lampadaLigada = false;

    // ════════════════════════════════════════════════════════════════
    // SIMULAR DADOS POR TIPO DE SENSOR
    // ════════════════════════════════════════════════════════════════
    switch(sensor['tipo']) {
      case 'Temperatura/Umidade':
        // Temperatura normal: 18-32°C, com 10% de chance de temperatura alta
        temperatura = 18.0 + _random.nextDouble() * 14.0;
        if (_random.nextDouble() < 0.1) {
          temperatura = 33.0 + _random.nextDouble() * 5.0; // 33-38°C (alerta)
        }
        
        // Umidade normal: 35-85%, com 10% de chance de umidade alta
        umidade = 35.0 + _random.nextDouble() * 50.0;
        if (_random.nextDouble() < 0.1) {
          umidade = 90.0 + _random.nextDouble() * 8.0; // 90-98% (alerta)
        }
        break;
      
      case 'Movimento':
        // 40% de chance de detectar movimento
        movimentoDetectado = _random.nextDouble() < 0.4;
        lampadaLigada = movimentoDetectado; // Lâmpadas ligam com movimento
        break;
      
      case 'Iluminacao':
        // 40% de chance de estar ligado
        movimentoDetectado = _random.nextDouble() < 0.4;
        lampadaLigada = movimentoDetectado;
        break;
    }

    // ════════════════════════════════════════════════════════════════
    // CRIAR LEITURA
    // Os cálculos de consumo e custo são feitos automaticamente no modelo
    // ════════════════════════════════════════════════════════════════
    final leitura = LeituraSensor(
      idSensor: sensorId,
      idFilial: sensor['id_filial'],
      tipoSensor: sensor['tipo'],
      localizacao: sensor['localizacao'],
      filial: filial['nome'],
      temperatura: temperatura,
      umidade: umidade,
      movimentoDetectado: movimentoDetectado,
      lampadaLigada: lampadaLigada,
      timestamp: DateTime.now(),
      qualidadeSinal: 90 + _random.nextInt(11), // 90-100%
    );

    // Salvar no banco (MySQL + Firebase)
    await DatabaseService.salvarLeitura(leitura);
    
    return leitura;
  }

  // ════════════════════════════════════════════════════════════════
  // GERAR MÚLTIPLAS LEITURAS
  // ════════════════════════════════════════════════════════════════
  Future<List<LeituraSensor>> gerarMultiplasLeituras(int quantidade) async {
    final leituras = <LeituraSensor>[];
    
    print('\n🔄 Gerando $quantidade leituras simuladas...\n');
    
    for (int i = 0; i < quantidade; i++) {
      try {
        final leitura = await gerarLeituraSimulada();
        leituras.add(leitura);
        
        print('✅ Leitura ${i + 1}/$quantidade: ${leitura.toString()}');
        
        // Pequeno delay para não sobrecarregar
        await Future.delayed(Duration(milliseconds: 500));
      } catch (e) {
        print('❌ Erro na leitura ${i + 1}: $e');
      }
    }
    
    return leituras;
  }

  // ════════════════════════════════════════════════════════════════
  // SIMULAR DIA COMPLETO (24h)
  // ════════════════════════════════════════════════════════════════
  Future<void> simularDiaCompleto() async {
    print('\n📅 Simulando dia completo (24 horas)...\n');
    
    final leiturasHora = <int, int>{
      0: 2, 1: 1, 2: 1, 3: 1, 4: 1, 5: 2,     // Madrugada (pouco movimento)
      6: 5, 7: 8, 8: 10, 9: 8, 10: 6, 11: 5,  // Manhã (movimento crescente)
      12: 6, 13: 4, 14: 4, 15: 5, 16: 7, 17: 9, // Tarde (movimento moderado)
      18: 12, 19: 10, 20: 8, 21: 6, 22: 4, 23: 3, // Noite (pico no início)
    };
    
    int totalLeituras = 0;
    double consumoTotal = 0.0;
    double custoTotal = 0.0;
    
    for (final entrada in leiturasHora.entries) {
      final hora = entrada.key;
      final quantidade = entrada.value;
      
      print('⏰ Hora ${hora.toString().padLeft(2, '0')}:00 - ${quantidade} leituras');
      
      for (int i = 0; i < quantidade; i++) {
        final leitura = await gerarLeituraSimulada();
        totalLeituras++;
        
        if (leitura.lampadaLigada) {
          consumoTotal += leitura.consumoKwh;
          custoTotal += leitura.custoReais;
        }
        
        await Future.delayed(Duration(milliseconds: 100));
      }
    }
    
    print('\n═══════════════════════════════════════════════════════════');
    print('📊 RESUMO DO DIA SIMULADO:');
    print('   Total de leituras: $totalLeituras');
    print('   Consumo total: ${consumoTotal.toStringAsFixed(4)} kWh');
    print('   Custo total: R\$ ${custoTotal.toStringAsFixed(2)}');
    print('═══════════════════════════════════════════════════════════\n');
  }

  // ════════════════════════════════════════════════════════════════
  // TESTAR CONEXÕES
  // ════════════════════════════════════════════════════════════════
  Future<void> _testarConexoes() async {
    print('🔌 Testando conexões...\n');
    
    try {
      await DatabaseService.testarConexao();
      print('');
      await FirebaseRealtimeService.testarConexao();
      print('');
    } catch (e) {
      print('❌ Erro ao testar conexões: $e');
      rethrow;
    }
  }

  // ════════════════════════════════════════════════════════════════
  // ESTATÍSTICAS DE SIMULAÇÃO
  // ════════════════════════════════════════════════════════════════
  Future<void> exibirEstatisticas() async {
    print('\n═══════════════════════════════════════════════════════════');
    print('📊 ESTATÍSTICAS DO SISTEMA');
    print('═══════════════════════════════════════════════════════════\n');
    
    final stats = await DatabaseService.getEstatisticas();
    
    print('📈 GERAL:');
    stats.forEach((key, value) {
      final label = key.replaceAll('_', ' ').toUpperCase();
      print('   $label: $value');
    });
    
    print('\n💡 CONFIGURAÇÃO DO SISTEMA:');
    print('   Lâmpadas por filial: ${LeituraSensor.LAMPADAS_POR_FILIAL} unidades');
    print('   Potência unitária: ${LeituraSensor.POTENCIA_LAMPADA_W}W');
    print('   Tempo de ativação: ${LeituraSensor.TEMPO_ATIVACAO_MIN} minutos');
    print('   Tarifa de energia: R\$ ${LeituraSensor.TARIFA_KWH}/kWh');
    print('   Consumo por ativação: ${LeituraSensor._calcularConsumo(true).toStringAsFixed(4)} kWh');
    print('   Custo por ativação: R\$ ${LeituraSensor._calcularCusto(true).toStringAsFixed(4)}');
    
    print('\n💰 ANÁLISE POR FILIAL:');
    final consumoPorFilial = await DatabaseService.getConsumoPorFilial();
    for (final filial in consumoPorFilial) {
      print('   ${filial['Nome_Filial']}:');
      print('      Leituras: ${filial['total_leituras']}');
      print('      Ativações: ${filial['ativacoes']}');
      print('      Consumo: ${double.parse(filial['consumo_total_kwh'].toString()).toStringAsFixed(4)} kWh');
      print('      Custo: R\$ ${double.parse(filial['custo_total_reais'].toString()).toStringAsFixed(2)}');
    }
    
    print('\n═══════════════════════════════════════════════════════════\n');
  }
}
