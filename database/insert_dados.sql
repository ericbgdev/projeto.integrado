-- Inserir dados das filiais (do Excel)
INSERT INTO DIM_FILIAL (ID_Filial, Nome_Filial, Cidade, Estado, Endereco, Gerente, Telefone, CEP) VALUES
(1, 'Aguai', 'Aguai', 'SP', 'Av. Francisco Gonçalves, 409', 'João Silva', '(19) 3652-1234', '13868-000'),
(2, 'Casa Branca', 'Casa Branca', 'SP', 'BLOCO B Estrada Acesso, SP-340', 'Maria Santos', '(19) 3671-5678', '13700-000');

-- Inserir dados dos sensores (do Excel)
INSERT INTO DIM_SENSOR (ID_Sensor, Tipo_Sensor, Modelo, Localizacao, ID_Filial, Status) VALUES
(1, 'Movimento', 'PIR HC-SR501', 'Entrada Principal', 1, 'Ativo'),
(2, 'Temperatura/Umidade', 'DHT11', 'Sala Principal', 1, 'Ativo'),
(4, 'Movimento', 'PIR HC-SR501', 'Entrada Principal', 2, 'Ativo'),
(5, 'Temperatura/Umidade', 'DHT11', 'Sala Principal', 2, 'Ativo'),
(7, 'Iluminacao', 'LED', 'Entrada Principal', 1, 'Ativo'),
(8, 'Iluminacao', 'LED', 'Entrada Principal', 2, 'Ativo');
