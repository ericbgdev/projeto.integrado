import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../services/mysql_service.dart';
import '../services/simulador_service.dart';
import '../models/leitura_sensor.dart';
import '../utils/constants.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final SimuladorService _simulador = SimuladorService();
  final List<LeituraSensor> _historico = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Packbag'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            _buildHeader(),
            const SizedBox(height: 20),
            
            _buildEstatisticas(),
            const SizedBox(height: 20),
            
            _buildLeiturasRecentes(),
            const SizedBox(height: 20),
            
            _buildAlertas(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _simularNovaLeitura,
        backgroundColor: Colors.green,
        child: const Icon(Icons.add_chart, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.business, size: 40, color: Colors.blue),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppConstants.companyName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  Text(
                    'Monitoramento IoT - ${AppConstants.filiais.join(' & ')}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstatisticas() {
    return StreamBuilder<List<LeituraSensor>>(
      stream: FirebaseService.getLeiturasRecentes(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final leituras = snapshot.data!;
        if (leituras.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: Text('Nenhuma leitura disponível')),
            ),
          );
        }

        final tempMedia = leituras.map((l) => l.temperatura).reduce((a, b) => a + b) / leituras.length;
        final umidMedia = leituras.map((l) => l.umidade).reduce((a, b) => a + b) / leituras.length;
        final totalMovimentos = leituras.where((l) => l.movimentoDetectado).length;

        return Card(
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Estatísticas em Tempo Real',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCard('${tempMedia.toStringAsFixed(1)}°C', 'Temp Média'),
                    _buildStatCard('${umidMedia.toStringAsFixed(1)}%', 'Umidade Média'),
                    _buildStatCard('$totalMovimentos', 'Movimentos'),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String emoji, String valor, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(valor, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildLeiturasRecentes() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Leituras Recentes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<LeituraSensor>>(
              stream: FirebaseService.getLeiturasRecentes(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final leituras = snapshot.data!;
                return Column(
                  children: leituras.take(5).map((leitura) => _buildLeituraItem(leitura)).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeituraItem(LeituraSensor leitura) {
    return ListTile(
      leading: Icon(
        leitura.movimentoDetectado ? Icons.motion_photos_on : Icons.motion_photos_off,
        color: leitura.movimentoDetectado ? Colors.green : Colors.grey,
      ),
      title: Text('${leitura.localFilial} - Sensor ${leitura.idSensor}'),
      subtitle: Text(
        '${leitura.temperatura}°C | ${leitura.umidade}% | '
        'Lâmpada: ${leitura.lampada ? "LIGADA" : "DESLIGADA"}',
      ),
      trailing: Text(
        '${leitura.timestamp.hour}:${leitura.timestamp.minute.toString().padLeft(2, '0')}',
        style: const TextStyle(color: Colors.grey),
      ),
    );
  }

  Widget _buildAlertas() {
    return Card(
      elevation: 3,
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Alertas do Sistema',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange),
            ),
            const SizedBox(height: 8),
            const Text('• Sistema de monitoramento ativo'),
            const Text('• Sensores PIR HC-SR501 e DHT11 operacionais'),
            const Text('• Conexão com Firebase estabelecida'),
            const SizedBox(height: 8),
            Text(
              'Desenvolvido por: Eric, Gabrielly e Lindsay',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  void _simularNovaLeitura() async {
    final novaLeitura = _simulador.gerarLeituraSimulada();
    
    try {
      
      await FirebaseService.salvarLeitura(novaLeitura);
      

      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nova leitura simulada: $novaLeitura'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
