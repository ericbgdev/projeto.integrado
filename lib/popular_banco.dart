import 'package:mysql1/mysql1.dart';

void main() async {
  print('Populando banco de dados...\n');

  final settings = ConnectionSettings(
    host: 'localhost',
    port: 3306,
    user: 'root',
    password: 'unifeob@123',
    db: 'entrega5',
  );

  final conn = await MySqlConnection.connect(settings);

  try {
  
    await conn.query('''
      INSERT INTO dim_filial (ID_Filial, Nome_Filial, Cidade, Estado, Endereco, Gerente, Telefone, CEP) VALUES
      (1, 'Aguai', 'Aguai', 'SP', 'Av. Francisco Gonçalves, 409', 'João Silva', '(19) 3652-1234', '13868-000'),
      (2, 'Casa Branca', 'Casa Branca', 'SP', 'BLOCO B Estrada Acesso, SP-340', 'Maria Santos', '(19) 3671-5678', '13700-000')
    ''');
    print('Filiais inseridas');

  
    await conn.query('''
      INSERT INTO dim_sensor (ID_Sensor, Tipo_Sensor, Modelo, Localizacao, ID_Filial, Status) VALUES
      (1, 'Movimento', 'PIR HC-SR501', 'Entrada Principal', 1, 'Ativo'),
      (2, 'Temperatura/Umidade', 'DHT11', 'Sala Principal', 1, 'Ativo'),
      (4, 'Movimento', 'PIR HC-SR501', 'Entrada Principal', 2, 'Ativo'),
      (5, 'Temperatura/Umidade', 'DHT11', 'Sala Principal', 2, 'Ativo'),
      (7, 'Iluminacao', 'LED', 'Entrada Principal', 1, 'Ativo'),
      (8, 'Iluminacao', 'LED', 'Entrada Principal', 2, 'Ativo')
    ''');
    print('Sensores inseridos');

   
    final filiais = await conn.query('SELECT * FROM dim_filial');
    print('\n Filiais: ${filiais.length}');

    final sensores = await conn.query('SELECT * FROM dim_sensor');
    print('Sensores: ${sensores.length}');

    print('\n Banco populado com sucesso!');
    print('Agora execute: dart run main.dart');

  } catch (e) {
    print('Erro: $e');
  } finally {
    await conn.close();
  }
}
