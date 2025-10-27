import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/leitura_sensor.dart';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> salvarLeitura(LeituraSensor leitura) async {
    try {
      await _firestore.collection('leituras').add({
        'id_sensor': leitura.idSensor,
        'id_filial': leitura.idFilial,
        'tipo_sensor': leitura.tipoSensor,
        'localizacao': leitura.localizacao,
        'filial': leitura.filial,
        'temperatura': leitura.temperatura,
        'umidade': leitura.umidade,
        'movimento_detectado': leitura.movimentoDetectado,
        'lampada_ligada': leitura.lampadaLigada,
        'timestamp': FieldValue.serverTimestamp(),
      });
      print('🔥 Firebase: Leitura em tempo real salva');
    } catch (e) {
      print('❌ Firebase Error: $e');
    }
  }

  static Stream<QuerySnapshot> ouvirLeiturasTempoReal() {
    return _firestore
        .collection('leituras')
        .orderBy('timestamp', descending: true)
        .limit(10)
        .snapshots();
  }
}
