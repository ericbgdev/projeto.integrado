-- Estrutura do Data Warehouse (MySQL)
-- Tabela Fato: FATO_LEITURAS
CREATE TABLE IF NOT EXISTS FATO_LEITURAS (
  ID_Leitura BIGINT AUTO_INCREMENT PRIMARY KEY,
  ID_Sensor INT NOT NULL,
  ID_Filial INT NOT NULL,
  ID_Data INT NOT NULL,
  Temperatura DECIMAL(4,1),
  Umidade DECIMAL(4,1),
  Movimento_Detectado TINYINT DEFAULT 0,
  Lampada_Ligada TINYINT DEFAULT 0,
  Consumo_kWh DECIMAL(6,4) DEFAULT 0.0000,
  Timestamp DATETIME NOT NULL,
  Qualidade_Sinal TINYINT DEFAULT 100,
  Status_Leitura ENUM('Válida', 'Erro', 'Suspeita') DEFAULT 'Válida'
);

-- Dimensão: DIM_FILIAL
CREATE TABLE IF NOT EXISTS DIM_FILIAL (
  ID_Filial INT AUTO_INCREMENT PRIMARY KEY,
  Nome_Filial VARCHAR(100) NOT NULL,
  Cidade VARCHAR(50) NOT NULL,
  Estado CHAR(2) NOT NULL,
  Endereco VARCHAR(200) NOT NULL,
  Gerente VARCHAR(100) NOT NULL,
  Telefone VARCHAR(20) NOT NULL,
  CEP VARCHAR(10) NOT NULL
);

-- Dimensão: DIM_SENSOR
CREATE TABLE IF NOT EXISTS DIM_SENSOR (
  ID_Sensor INT AUTO_INCREMENT PRIMARY KEY,
  Tipo_Sensor VARCHAR(50) NOT NULL,
  Modelo VARCHAR(50) NOT NULL,
  Localizacao VARCHAR(100) NOT NULL,
  ID_Filial INT NOT NULL,
  Status ENUM('Ativo', 'Inativo', 'Manutenção') DEFAULT 'Ativo'
);

-- Dimensão: DIM_TEMPO
CREATE TABLE IF NOT EXISTS DIM_TEMPO (
  ID_Data INT PRIMARY KEY,
  Data_Completa DATETIME NOT NULL,
  Ano SMALLINT NOT NULL,
  Mes TINYINT NOT NULL,
  Dia TINYINT NOT NULL,
  DiaSemana VARCHAR(15) NOT NULL,
  Hora TINYINT NOT NULL,
  Periodo_Dia ENUM('Madrugada', 'Manhã', 'Tarde', 'Noite') NOT NULL
);

-- Stored Procedure para inserir leituras
DELIMITER $$
CREATE PROCEDURE sp_inserir_leitura(
  IN p_id_sensor INT,
  IN p_temperatura DECIMAL(4,1),
  IN p_umidade DECIMAL(4,1),
  IN p_movimento TINYINT,
  IN p_lampada TINYINT
)
BEGIN
  DECLARE v_id_filial INT;
  DECLARE v_id_data INT;
  DECLARE v_consumo DECIMAL(6,4);

  -- Obter ID da filial do sensor
  SELECT ID_Filial INTO v_id_filial FROM DIM_SENSOR WHERE ID_Sensor = p_id_sensor;

  -- Calcular consumo (0.05 kWh quando lâmpada ligada)
  SET v_consumo = CASE WHEN p_lampada = 1 THEN 0.0500 ELSE 0.0000 END;

  -- Obter ID da dimensão tempo (exemplo simplificado)
  SET v_id_data = UNIX_TIMESTAMP(NOW());

  -- Inserir leitura
  INSERT INTO FATO_LEITURAS (ID_Sensor, ID_Filial, ID_Data, Temperatura, Umidade, Movimento_Detectado, Lampada_Ligada, Consumo_kWh, Timestamp)
  VALUES (p_id_sensor, v_id_filial, v_id_data, p_temperatura, p_umidade, p_movimento, p_lampada, v_consumo, NOW());
END$$
DELIMITER ;
