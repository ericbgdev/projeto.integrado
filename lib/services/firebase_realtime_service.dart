// ════════════════════════════════════════════════════════════════
// SERVIÇO: Firebase Realtime Database v2.0 - CORRIGIDO
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
  static bool _inicializado = false;

  static bool get isInitialized => _inicializado;

  // ════════════════════════════════════════════════════════════════
  // BUSCAR ARQUIVO DE CREDENCIAIS
  // ════════════════════════════════════════════════════════════════
  static Future<File?> _buscarCredenciais() async {
    final possiveisCaminhos = [
      'config/firebase-credentials.json',
      '../config/firebase-credentials.json',
      'lib/config/firebase-credentials.json',
      './lib/config/firebase-credentials.json',
    ];
    
    for (final caminho in possiveisCaminhos) {
      try {
        final arquivo = File(caminho);
        if (await arquivo.exists()) {
          print('✅ Credenciais encontradas: ${arquivo.absolute.path}\n');
          return arquivo;
        }
      } catch (e) {
        // Ignorar e tentar próximo
      }
    }
    
    return null;
  }

  // ════════════════════════════════════════════════════════════════
  // INICIALIZAR FIREBASE
  // ════════════════════════════════════════════════════════════════
  static Future<void> initialize() async {
    if (_inicializado) {
      return;
    }
    
    print('🔥 Inicializando Firebase...');
    
    try {
      final credentialsFile = await _buscarCredenciais();
      
      if (credentialsFile == null) {
        throw Exception('Arquivo firebase-credentials.json não encontrado');
      }

      final credentialsContent = await credentialsFile.readAsString();
      _serviceAccount = json.decode(credentialsContent);
      
      _projectId = _serviceAccount!['project_id'];
      _databaseUrl = 'https://$_projectId-default-rtdb.firebaseio.com';
      
      // Gerar token ANTES de marcar como inicializado
      final now = DateTime.now();
      
      final jwt = JWT({
        'iss': _serviceAccount!['client_email'],
        'sub': _serviceAccount!['client_email'],
        'aud': 'https://oauth2.googleapis.com/token',
        'iat': now.millisecondsSinceEpoch ~/ 1000,
        'exp': now.add(Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000,
        'scope': 'https://www.googleapis.com/auth/firebase.database '
                 'https://www.googleapis.com/auth/userinfo.email'
      });

      final token = jwt.sign(
        RSAPrivateKey(_serviceAccount!['private_key']), 
        algorithm: JWTAlgorithm.RS256
      );

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
        _tokenExpiry = now.add(Duration(seconds: data['expires_in'] - 300));
        
        // AGORA SIM marcar como inicializado
        _inicializado = true;
        
        print('✅ Firebase conectado!');
        print('🌐 URL: $_databaseUrl');
        print('📁 Projeto: $_projectId\n');
      } else {
        throw Exception('Erro ao obter token: ${response.body}');
      }
      
    } catch (e) {
      print('❌ Erro ao inicializar Firebase: $e\n');
      _inicializado = false;
      rethrow;
    }
  }

  // ════════════════════════════════════════════════════════════════
  // REFRESH ACCESS TOKEN
  // ════════════════════════════════════════════════════════════════
  static Future<void> _refreshAccessToken() async {
    if (!_inicializado) {
      throw Exception('Firebase não inicializado');
    }
    
    final now = DateTime.now();
    
    if (_accessToken != null && _tokenExpiry != null && now.isBefore(_tokenExpiry!)) {
      return;
    }

    final jwt = JWT({
      'iss': _serviceAccount!['client_email'],
      'sub': _serviceAccount!['client_email'],
      'aud': 'https://oauth2.googleapis.com/token',
      'iat': now.millisecondsSinceEpoch ~/ 1000,
      'exp': now.add(Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000,
      'scope': 'https://www.googleapis.com/auth/firebase.database '
               'https://www.googleapis.com/auth/userinfo.email'
    });

    final token = jwt.sign(
      RSAPrivateKey(_serviceAccount!['private_key']), 
      algorithm: JWTAlgorithm.RS256
    );

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
      _tokenExpiry = now.add(Duration(seconds: data['expires_in'] - 300));
    } else {
      throw Exception('Erro ao refresh token: ${response.body}');
    }
  }

  // ════════════════════════════════════════════════════════════════
  // SALVAR LEITURA
  // ════════════════════════════════════════════════════════════════
  static Future<void> salvarLeitura(LeituraSensor leitura) async {
    if (!_inicializado) {
      throw Exception('Firebase não inicializado');
    }
    
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
        'qtdLampadasAtivas': leitura.qtdLampadasAtivas,
        'potenciaLampadaW': LeituraSensor.POTENCIA_LAMPADA_W,
        'tempoLigadoMin': leitura.tempoLigadoMin,
        'consumoKwh': leitura.consumoKwh,
        'custoReais': leitura.custoReais,
        'tarifaKwh': LeituraSensor.TARIFA_KWH,
        'timestamp': leitura.timestamp.toIso8601String(),
        'qualidadeSinal': leitura.qualidadeSinal,
        'statusLeitura': leitura.statusLeitura,
        'sincronizadoEm': DateTime.now().toIso8601String(),
        'fonte': 'MySQL_Real',
        'versao': '2.0',
      };

      final url = '$_databaseUrl/leituras.json?auth=$_accessToken';
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(leituraData),
      );

      if (response.statusCode == 200) {
        print('🔥 Firebase: Leitura salva - ${leitura.filial}');
      } else {
        throw Exception('Erro HTTP ${response.statusCode}: ${response.body}');
      }
      
    } catch (e) {
      print('❌ Erro Firebase: $e');
      rethrow;
    }
  }

  // ════════════════════════════════════════════════════════════════
  // BUSCAR LEITURAS
  // ════════════════════════════════════════════════════════════════
  static Future<List<Map<String, dynamic>>> getLeituras() async {
    if (!_inicializado) return [];
    
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
      print('❌ Erro ao buscar Firebase: $e');
      return [];
    }
  }

  // ════════════════════════════════════════════════════════════════
  // TESTAR CONEXÃO
  // ════════════════════════════════════════════════════════════════
  static Future<void> testarConexao() async {
    if (!_inicializado) {
      throw Exception('Firebase não inicializado');
    }
    
    print('🔥 Testando Firebase...');
    
    try {
      await _refreshAccessToken();
      
      final url = '$_databaseUrl/.json?auth=$_accessToken';
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        print('✅ Firebase OK!\n');
      } else {
        throw Exception('Erro: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erro Firebase: $e\n');
      rethrow;
    }
  }
}
