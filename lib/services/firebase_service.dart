import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/leitura_sensor.dart';

class FirebaseService {
  static bool _inicializado = false;

  static Future<void> inicializar() async {
    if (_inicializado) return;
    
    try {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "sua-api-key",
          authDomain: "seu-projeto.firebaseapp.com",
          projectId: "seu-projeto",
          storageBucket: "seu-projeto.appspot.com",
          messagingSenderId: "123456789",
          appId: "sua-app-id"
        ),
      );
      _inicializado = true;
      print('   🔥 Firebase: Inicializado com sucesso');
    } catch (e) {
      print('   ⚠️ Firebase: Não configurado - $e');
    }
  }

  static Future<void> salvarLeitura(LeituraSensor leitura) async {
    if (!_inicializado) {
      print('   🔥 Firebase: Pulando (não configurado)');
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('leituras').add({
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
      print('   🔥 Firebase: Salvo em tempo real');
    } catch (e) {
      print('   ❌ Firebase Error: $e');
    }
  }
}
