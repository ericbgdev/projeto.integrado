import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "sua-api-key",
          authDomain: "seu-projeto.firebaseapp.com",
          projectId: "seu-projeto-id",
          storageBucket: "seu-projeto.appspot.com",
          messagingSenderId: "seu-sender-id",
          appId: "sua-app-id",
        ),
      );
      print('Firebase inicializado com sucesso');
    } catch (e) {
      print('Erro ao inicializar Firebase: $e');
      rethrow;
    }
  }

  static Future<void> salvarLeitura(Map<String, dynamic> dados) async {
    try {
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
            'timestamp': FieldValue.serverTimestamp(),
            'fonte': dados['fonte'] ?? 'Firebase_Direto',
            'qualidadeSinal': dados['qualidadeSinal'] ?? 100,
            'statusLeitura': dados['statusLeitura'] ?? 'Valida',
            'idLeitura': dados['idLeitura'],
            'tipoSensor': dados['tipoSensor'],
            'sincronizadoEm': FieldValue.serverTimestamp(),
          });
      
      print('Firebase: Leitura ${dados['idSensor']} - ${dados['filial']} salva');
    } catch (e) {
      print('Erro ao salvar leitura no Firebase: $e');
      rethrow;
    }
  }

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
      
      print('Firebase: Filial ${filial['nome']} salva');
    } catch (e) {
      print('Erro ao salvar filial no Firebase: $e');
    }
  }

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
      
      print('Firebase: Sensor ${sensor['tipo']} - ${sensor['filial']} salvo');
    } catch (e) {
      print('Erro ao salvar sensor no Firebase: $e');
    }
  }

  static Future<void> testarConexao() async {
    try {
      final snapshot = await _firestore.collection('leituras').limit(1).get();
      print('Firebase: Conectado! ${snapshot.docs.length} leituras encontradas');
    } catch (e) {
      print('Firebase Connection Error: $e');
      rethrow;
    }
  }
}
