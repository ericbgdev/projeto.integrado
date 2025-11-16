// ════════════════════════════════════════════════════════════════
// SERVIÇO: Firebase Realtime Database v2.0
// Com sistema de iluminação 100 lâmpadas
// ════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import '../models/leitura_sensor.dart';

class FirebaseRealtimeService {
  static String? _databaseUrl;
  static String? _projectId;
  static Map<String, dynamic>? _serviceAccount;
  static String? _accessToken;
  static DateTime? _tokenExpiry;

  // ════════════════════════════════════════════════════════════════
  // INICIALIZAR FIREBASE
  // ════════════════════════════════════════════════════════════════
  static Future<void> initialize() async {
    print('🔥 Inicializando Firebase Real...');
    
    try {
      // Carregar credenciais - CAMINHO CORRETO
      final credentialsFile = File('lib/config/firebase-credentials.json');
      
      if (!await credentialsFile.exists()) {
        throw Exception('❌ Arquivo firebase-credentials.json não encontrado em lib/config/!');
      }

      final credentialsContent = await credentialsFile.readAsString();
      _serviceAccount = json.decode(credentialsContent);
      
      _projectId = _serviceAccount!['project_id'];
      _databaseUrl = 'https://$_projectId-default-rtdb.firebaseio.com';
      
      // Gerar token de acesso
      await _refreshAccessToken();
      
      print('✅ Firebase conectado: $_databaseUrl');
      print('📁 Projeto: $_projectId');
      
    } catch (e) {
      print('❌ Erro ao inicializar Firebase: $e');
      print('💡 Certifique-se que firebase-credentials.json existe em lib/config/');
      rethrow;
    }
  }

  // ════════════════════════════════════════════════════════════════
  // REFRESH ACCESS TOKEN
  // ════════════════════════════════════════════════════════════════
  static Future<void> _refreshAccessToken() async {
    try {
      final now = DateTime.now();
      
      // Token válido por 1 hora
      if (_accessToken != null && _tokenExpiry != null && now.isBefore(_tokenExpiry!)) {
        return; // Token ainda válido
      }

      // Criar JWT
      final jwt = JWT(
        {
          'iss': _serviceAccount!['client_email'],
          'sub': _serviceAccount!['client_email'],
          'aud': 'https://oauth2.googleapis.com/token',
          'iat': now.millisecondsSinceEpoch ~/ 1000,
          'exp': now.add(Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000,
          'scope': 'https://www.googleapis.com/auth/firebase.database '
                   'https://www.googleapis.com/auth/userinfo.email'
        },
      );

      final privateKey = _serviceAccount!['private_key'];
      final token = jwt.sign(RSAPrivateKey(privateKey), algorithm: JWTAlgorithm.RS256);

      // Trocar JWT por Access Token
      final response = await http.post(
        Uri.parse('https://oauth2.googleapis.com/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'urn:ietf:params:oauth:grant-type:jwt-bearer',
          'assertion': token,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _accessToken = data['access_token'];
        _tokenExpiry = now.add(Duration(seconds: data['expires_in'] - 300)); // 5 min antes
      } else {
        throw Exception('Erro ao obter token: ${response.body}');
      }
      
    } catch (e) {
      print('❌ Erro ao gerar token: $e');
      rethrow;
    }
  }

  // ════════════════════════════════════════════════════════════════
  // SALVAR LEITURA (atualizado com novos campos v2.0)
  // ════════════════════════════════════════════════════════════════
  static Future<void> salvarLeitura(LeituraSensor leitura) async {
    try {
      await _refreshAccessToken();

      final leituraData = {
        'id': '${leitura.idSensor}_${leitura.timestamp.millisecondsSinceEpoch}',
        'idSensor': leitura.idSensor,
        'idFilial': leitura.idFilial,
        'filial': leitura.filial,
        'tipoSensor': leitura.tipoSensor,
        'localizacao': leitura.localizacao,
        'temperatura': leitura.temperatura,
        'umidade': leitura.umidade,
        'movimentoDetectado': leitura.movimentoDetectado,
        'lampadaLigada': leitura.lampadaLigada,
        // Novos campos v2.0
        'qtdLampadasAtivas': leitura.qtdLampadasAtivas,
        'potenciaLampadaW': LeituraSensor.POTENCIA_LAMPADA_W,
        'tempoLigadoMin': leitura.tempoLigadoMin,
        'consumoKwh': leitura.consumoKwh,
        'custoReais': leitura.custoReais,
        'tarifaKwh': LeituraSensor.TARIFA_KWH,
        // Metadados
        'timestamp': leitura.timestamp.toIso8601String(),
        'qualidadeSinal': leitura.qualidadeSinal,
        'statusLeitura': leitura.statusLeitura,
        'sincronizadoEm': DateTime.now().toIso8601String(),
        'fonte': 'MySQL_Real',
        'versao': '2.0',
      };

      // Enviar para Firebase
      final url = '$_databaseUrl/leituras.json?auth=$_accessToken';
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(leituraData),
      );

      if (response.statusCode == 200) {
        print('🔥 Leitura salva no Firebase: ${leitura.filial}');
      } else {
        throw Exception('Erro HTTP ${response.statusCode}: ${response.body}');
      }
      
    } catch (e) {
      print('❌ Erro ao salvar no Firebase: $e');
      rethrow;
    }
  }

  // ════════════════════════════════════════════════════════════════
  // BUSCAR LEITURAS
  // ════════════════════════════════════════════════════════════════
  static Future<List<Map<String, dynamic>>> getLeituras() async {
    try {
      await _refreshAccessToken();

      final url = '$_databaseUrl/leituras.json?auth=$_accessToken';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data == null) return [];

        return (data as Map<String, dynamic>)
            .entries
            .map((entry) => {
                  'firebaseKey': entry.key,
                  ...entry.value as Map<String, dynamic>
                })
            .toList();
      }
      
      return [];
    } catch (e) {
      print('❌ Erro ao buscar leituras: $e');
      return [];
    }
  }

  // ════════════════════════════════════════════════════════════════
  // TESTAR CONEXÃO
  // ════════════════════════════════════════════════════════════════
  static Future<void> testarConexao() async {
    print('🔥 Testando conexão Firebase Real...');
    
    try {
      await _refreshAccessToken();
      
      final url = '$_databaseUrl/.json?auth=$_accessToken';
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        print('✅ Firebase Real conectado com sucesso!');
      } else {
        throw Exception('Erro na conexão: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erro na conexão: $e');
      rethrow;
    }
  }
}
