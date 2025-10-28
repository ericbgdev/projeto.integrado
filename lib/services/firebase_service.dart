import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Inicializar Firebase
  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
      print('🔥 Firebase inicializado com sucesso!');
    } catch (e) {
      print('❌ Erro ao inicializar Firebase: $e');
      rethrow;
    }
  }

  // 🔥 MÉTODO PARA SALVAR LEITURAS (usado pelo MySQLService)
  static Future<void> salvarLeitura(Map<String, dynamic> dados) async {
    try {
      // Criar ID único baseado no timestamp
      final docId = '${dados['idSensor']}_${DateTime.now().millisecondsSinceEpoch}';
      
      await _firestore
          .collection('leituras')
          .doc(docId)
          .set({
            'idSensor': dados['idSensor'],
            'idFilial': dados['idFilial'],
            'filial': dados['filial'],
            'temperatura': dados['temperatura'],
            'umidade': dados['umidade'],
            'movimentoDetectado': dados['movimentoDetectado'],
            'lampadaLigada': dados['lampadaLigada'],
            'consumo_kWh': dados['consumo_kWh'] ?? (dados['lampadaLigada'] ? 0.05 : 0.0),
            'timestamp': dados['timestamp'] != null 
                ? Timestamp.fromDate(dados['timestamp'] is DateTime 
                    ? dados['timestamp'] 
                    : DateTime.parse(dados['timestamp'].toString()))
                : FieldValue.serverTimestamp(),
            'fonte': dados['fonte'] ?? 'Firebase_Direto',
            'qualidadeSinal': dados['qualidadeSinal'] ?? 100,
            'statusLeitura': dados['statusLeitura'] ?? 'Válida',
            'idLeitura': dados['idLeitura'],
            'tipoSensor': dados['tipoSensor'],
            'sincronizadoEm': FieldValue.serverTimestamp(),
          });
      
      print('   🔥 Firebase: Leitura ${dados['idSensor']} - ${dados['filial']} salva');
    } catch (e) {
      print('   ⚠️ Erro ao salvar leitura no Firebase: $e');
      rethrow;
    }
  }

  // 🔥 SALVAR FILIAIS (usado na sincronização)
  static Future<void> salvarFilial(Map<String, dynamic> filial) async {
    try {
      await _firestore
          .collection('filiais')
          .doc(filial['id'].toString())
          .set({
            'id': filial['id'],
            'nome': filial['nome'],
            'cidade': filial['cidade'],
            'estado': filial['estado'],
            'endereco': filial['endereco'],
            'gerente': filial['gerente'],
            'telefone': filial['telefone'],
            'cep': filial['cep'],
            'importadoEm': FieldValue.serverTimestamp(),
          });
      
      print('   🏢 Firebase: Filial ${filial['nome']} salva');
    } catch (e) {
      print('   ⚠️ Erro ao salvar filial no Firebase: $e');
    }
  }

  // 🔥 SALVAR SENSORES (usado na sincronização)
  static Future<void> salvarSensor(Map<String, dynamic> sensor) async {
    try {
      await _firestore
          .collection('sensores')
          .doc(sensor['id'].toString())
          .set({
            'id': sensor['id'],
            'tipo': sensor['tipo'],
            'modelo': sensor['modelo'],
            'localizacao': sensor['localizacao'],
            'idFilial': sensor['idFilial'],
            'filial': sensor['filial'],
            'status': sensor['status'],
            'importadoEm': FieldValue.serverTimestamp(),
          });
      
      print('   📡 Firebase: Sensor ${sensor['tipo']} - ${sensor['filial']} salvo');
    } catch (e) {
      print('   ⚠️ Erro ao salvar sensor no Firebase: $e');
    }
  }

  // 🔥 BUSCAR LEITURAS EM TEMPO REAL (para o Dashboard)
  static Stream<List<Map<String, dynamic>>> getLeiturasRecentes({int limite = 20}) {
    return _firestore
        .collection('leituras')
        .orderBy('timestamp', descending: true)
        .limit(limite)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return {
                'id': doc.id,
                ...data,
                'timestamp': data['timestamp'] is Timestamp 
                    ? data['timestamp'].toDate() 
                    : DateTime.now(),
              };
            }).toList());
  }

  // 🔥 BUSCAR LEITURAS POR FILIAL
  static Stream<List<Map<String, dynamic>>> getLeiturasPorFilial(String filial, {int limite = 15}) {
    return _firestore
        .collection('leituras')
        .where('filial', isEqualTo: filial)
        .orderBy('timestamp', descending: true)
        .limit(limite)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return {
                'id': doc.id,
                ...data,
                'timestamp': data['timestamp'] is Timestamp 
                    ? data['timestamp'].toDate() 
                    : DateTime.now(),
              };
            }).toList());
  }

  // 🔥 BUSCAR FILIAIS
  static Stream<List<Map<String, dynamic>>> getFiliais() {
    return _firestore
        .collection('filiais')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data(),
                })
            .toList());
  }

  // 🔥 BUSCAR SENSORES
  static Stream<List<Map<String, dynamic>>> getSensores() {
    return _firestore
        .collection('sensores')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data(),
                })
            .toList());
  }

  // 🔥 ESTATÍSTICAS EM TEMPO REAL
  static Stream<Map<String, dynamic>> getEstatisticas() {
    return _firestore
        .collection('leituras')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) {
            return {
              'totalLeituras': 0,
              'temperaturaMedia': 0.0,
              'umidadeMedia': 0.0,
              'totalMovimentos': 0,
              'totalLampadas': 0,
              'ultimaAtualizacao': DateTime.now(),
            };
          }

          final leituras = snapshot.docs;
          final temperaturas = leituras
              .map((doc) => doc['temperatura'] as double? ?? 0.0)
              .where((temp) => temp > 0)
              .toList();

          final umidades = leituras
              .map((doc) => doc['umidade'] as double? ?? 0.0)
              .where((umid) => umid > 0)
              .toList();

          return {
            'totalLeituras': leituras.length,
            'temperaturaMedia': temperaturas.isEmpty 
                ? 0.0 
                : double.parse((temperaturas.reduce((a, b) => a + b) / temperaturas.length).toStringAsFixed(1)),
            'umidadeMedia': umidades.isEmpty 
                ? 0.0 
                : double.parse((umidades.reduce((a, b) => a + b) / umidades.length).toStringAsFixed(1)),
            'totalMovimentos': leituras.where((doc) => doc['movimentoDetectado'] == true).length,
            'totalLampadas': leituras.where((doc) => doc['lampadaLigada'] == true).length,
            'ultimaAtualizacao': DateTime.now(),
          };
        });
  }

  // 🔥 LIMPAR DADOS (apenas para desenvolvimento)
  static Future<void> limparDadosDesenvolvimento() async {
    try {
      // CUIDADO: Este método apaga dados - usar apenas em desenvolvimento
      final batch = _firestore.batch();
      
      final leituras = await _firestore.collection('leituras').get();
      for (final doc in leituras.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      print('🧹 Dados de desenvolvimento limpos');
    } catch (e) {
      print('❌ Erro ao limpar dados: $e');
    }
  }

  // 🔥 TESTAR CONEXÃO
  static Future<void> testarConexao() async {
    try {
      final snapshot = await _firestore.collection('leituras').limit(1).get();
      print('   ✅ Firebase: Conectado! ${snapshot.docs.length} leituras encontradas');
    } catch (e) {
      print('   ❌ Firebase Connection Error: $e');
      rethrow;
    }
  }
}
