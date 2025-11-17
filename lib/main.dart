// ════════════════════════════════════════════════════════════════
// SISTEMA PACKBAG - MONITORAMENTO IoT v2.0
// 100 Lâmpadas LED 20W por Filial
// Tempo de Ativação: 10 minutos
// Tarifa: R$ 0,95/kWh
// ════════════════════════════════════════════════════════════════

import 'dart:async';
import 'services/simulador_service.dart';
import 'services/database_service.dart';
import 'services/firebase_realtime_service.dart';
import 'models/leitura_sensor.dart';

// Variável global para controlar se Firebase foi inicializado
bool _firebaseInicializado = false;

// ════════════════════════════════════════════════════════════════
// EXIBIR INFORMAÇÕES DO BANCO
// ════════════════════════════════════════════════════════════════
Future<void> demonstrarORM() async {
  print('\n═══════════════════════════════════════════════════════════');
  print('📊 DADOS DO SISTEMA');
  print('═══════════════════════════════════════════════════════════\n');
  
  // Filiais
  final filiais = await DatabaseService.getFiliais();
  print('🏢 FILIAIS (${filiais.length}):');
  for (final filial in filiais) {
    print('   ${filial['ID_Filial']}: ${filial['Nome_Filial']} - ${filial['Cidade']}/${filial['Estado']}');
    print('      💡 ${filial['Qtd_Lampadas']}x${filial['Potencia_Lampada_W']}W '
          '(${filial['Tempo_Ativacao_Min']}min)');
  }
  
  // Sensores
  final sensores = await DatabaseService.getSensores();
  print('\n📡 SENSORES ATIVOS (${sensores.length}):');
  for (final sensor in sensores) {
    final status = sensor['Status'] == 'Ativo' ? '✅' : '⚠️';
    print('   $status ${sensor['ID_Sensor']}: ${sensor['Tipo_Sensor']} - ${sensor['Nome_Filial']}');
  }

  // Últimas leituras
  final leituras = await DatabaseService.getLeituras(limite: 5);
  print('\n📝 ÚLTIMAS 5 LEITURAS (${leituras.length} encontradas):');
  if (leituras.isNotEmpty) {
    for (final leitura in leituras) {
      print('\n   📍 ${leitura['Nome_Filial']} - ${leitura['Tipo_Sensor']}');
      print('      ID: ${leitura['ID_Leitura']} | Sensor: ${leitura['ID_Sensor']}');
      print('      Timestamp: ${leitura['Timestamp']}');
      
      if (leitura['Temperatura'] != null) {
        print('      🌡️  Temperatura: ${leitura['Temperatura']}°C');
      }
      if (leitura['Umidade'] != null) {
        print('      💧 Umidade: ${leitura['Umidade']}%');
      }
      if (leitura['Lampada_Ligada'] == 1) {
        print('      💡 Lâmpadas: ${leitura['Qtd_Lampadas_Ativas']} unidades');
        print('      ⚡ Consumo: ${leitura['Consumo_kWh']} kWh');
        print('      💰 Custo: R\$ ${leitura['Custo_Reais']}');
      }
    }
  }
}

// ════════════════════════════════════════════════════════════════
// EXIBIR ESTATÍSTICAS COMPLETAS
// ════════════════════════════════════════════════════════════════
Future<void> demonstrarConsultasORM() async {
  print('\n═══════════════════════════════════════════════════════════');
  print('📈 ESTATÍSTICAS FINAIS');
  print('═══════════════════════════════════════════════════════════\n');
  
  final simulador = SimuladorService();
  await simulador.exibirEstatisticas();
  
  // Verificar Firebase se foi inicializado
  if (_firebaseInicializado) {
    final leiturasFirebase = await FirebaseRealtimeService.getLeituras();
    print('🔥 Firebase Real: ${leiturasFirebase.length} leituras sincronizadas');
  } else {
    print('⚠️  Firebase não disponível nesta sessão');
  }
}

// ════════════════════════════════════════════════════════════════
// FUNÇÃO PRINCIPAL
// ════════════════════════════════════════════════════════════════
void main() async {
  print('''
╔════════════════════════════════════════════════════════════════╗
║                                                                ║
║         🚀 SISTEMA PACKBAG - MONITORAMENTO IoT 🚀              ║
║                                                                ║
║  📡 Sensores: PIR HC-SR501 + DHT11                             ║
║  🏢 Filiais: Aguai e Casa Branca                               ║
║  💾 Banco: MySQL (entrega5) + Firebase Real                    ║
║                                                                ║
║  💡 NOVO SISTEMA DE ILUMINAÇÃO:                                ║
║     • 100 Lâmpadas LED por filial                              ║
║     • Potência: 20W cada                                       ║
║     • Tempo: 10 minutos por ativação                           ║
║     • Consumo: 0.33 kWh por ativação                           ║
║     • Custo: R\$ 0,3135 por ativação                           ║
║     • Tarifa: R\$ 0,95/kWh                                     ║
║                                                                ║
╚════════════════════════════════════════════════════════════════╝
''');

  try {
    // ════════════════════════════════════════════════════════════════
    // INICIALIZAR CONEXÕES
    // ════════════════════════════════════════════════════════════════
    await DatabaseService.testarConexao();
    print('');
    
    // Tentar inicializar Firebase (não crítico)
    try {
      await FirebaseRealtimeService.initialize();
      _firebaseInicializado = true;
      print('');
    } catch (e) {
      print('⚠️  Firebase não pôde ser inicializado: $e');
      print('💡 Continuando apenas com MySQL...\n');
      _firebaseInicializado = false;
    }
    
    // ════════════════════════════════════════════════════════════════
    // DEMONSTRAR DADOS EXISTENTES
    // ════════════════════════════════════════════════════════════════
    await demonstrarORM();

    // ════════════════════════════════════════════════════════════════
    // SIMULAÇÃO DE LEITURAS
    // ════════════════════════════════════════════════════════════════
    final simulador = SimuladorService();
    var contador = 0;
    const totalLeituras = 10;

    print('\n═══════════════════════════════════════════════════════════');
    print('🎯 INICIANDO SIMULAÇÃO - $totalLeituras LEITURAS');
    print('═══════════════════════════════════════════════════════════\n');
    
    final timer = Timer.periodic(Duration(seconds: 3), (timer) async {
      contador++;
      
      try {
        print('─────────────────────────────────────────────────────────');
        print('📝 LEITURA $contador/$totalLeituras');
        print('─────────────────────────────────────────────────────────');
        
        final leitura = await simulador.gerarLeituraSimulada();
        
        // Exibir detalhes completos
        if (leitura.lampadaLigada) {
          print(leitura.toDetailedString());
        } else {
          print('📊 ${leitura.toString()}');
          print('');
        }
        
      } catch (e) {
        print('❌ Erro na leitura: $e\n');
      }

      // ════════════════════════════════════════════════════════════════
      // FINALIZAR SIMULAÇÃO
      // ════════════════════════════════════════════════════════════════
      if (contador >= totalLeituras) {
        timer.cancel();
        
        await demonstrarConsultasORM();
        
        print('\n═══════════════════════════════════════════════════════════');
        print('✅ SIMULAÇÃO CONCLUÍDA COM SUCESSO!');
        print('═══════════════════════════════════════════════════════════\n');
        print('📊 Dados salvos no MySQL: entrega5');
        
        if (_firebaseInicializado) {
          print('🔥 Dados sincronizados no Firebase Console');
        }
        
        print('\n💡 PRÓXIMOS COMANDOS:');
        print('   • Executar novamente: dart run main.dart');
        print('   • Verificar banco: dart run verificar_banco.dart');
        print('   • Ver análises SQL: Execute analise_sql_completa.sql no MySQL Workbench');
        print('\n═══════════════════════════════════════════════════════════\n');
        
        await DatabaseService.close();
      }
    });
    
  } catch (e, stackTrace) {
    print('\n╔════════════════════════════════════════════════════════════╗');
    print('║  ❌ ERRO CRÍTICO NO SISTEMA                                 ║');
    print('╚════════════════════════════════════════════════════════════╝\n');
    print('Erro: $e\n');
    print('Stack Trace:');
    print(stackTrace);
    print('\n💡 VERIFICAÇÕES:');
    print('   1. MySQL está rodando?');
    print('   2. Banco "entrega5" foi criado?');
    print('   3. Senha correta em database_service.dart?');
    print('   4. Firebase credentials configurado? (opcional)');
    print('\n📝 Execute: dart run verificar_banco.dart para diagnóstico\n');
  }
}
