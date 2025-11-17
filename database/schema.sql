-- ════════════════════════════════════════════════════════════════
-- SISTEMA PACKBAG IoT - SCHEMA FINAL v2.0
-- Data: 2025-11-16
-- Autores: Eric Butzloff Gudera, Gabrielly Cristina dos Reis, 
--          Lindsay Cristine Oliveira Souza
-- 
-- SISTEMA DE ILUMINAÇÃO:
-- • 100 Lâmpadas LED por filial
-- • Potência: 20W cada
-- • Tempo de ativação: 10 minutos
-- • Consumo por ativação: 0.33 kWh
-- • Custo por ativação: R$ 0,3135
-- • Tarifa: R$ 0,95/kWh
-- ════════════════════════════════════════════════════════════════

SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

-- ════════════════════════════════════════════════════════════════
-- CRIAR DATABASE
-- ════════════════════════════════════════════════════════════════
CREATE SCHEMA IF NOT EXISTS `entrega5` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE `entrega5`;

-- ════════════════════════════════════════════════════════════════
-- DIMENSÃO: FILIAL
-- Armazena informações das filiais Packbag
-- NOVO: Campos de configuração de iluminação
-- ════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS `dim_filial` (
  `ID_Filial` INT NOT NULL AUTO_INCREMENT,
  `Nome_Filial` VARCHAR(100) NOT NULL,
  `Cidade` VARCHAR(50) NOT NULL,
  `Estado` CHAR(2) NOT NULL,
  `Endereco` VARCHAR(200) NOT NULL,
  `Gerente` VARCHAR(100) NOT NULL,
  `Telefone` VARCHAR(20) NOT NULL,
  `CEP` VARCHAR(10) NOT NULL,
  -- NOVOS CAMPOS v2.0
  `Qtd_Lampadas` INT DEFAULT 100 COMMENT 'Quantidade de lâmpadas LED na filial',
  `Potencia_Lampada_W` INT DEFAULT 20 COMMENT 'Potência de cada lâmpada em Watts',
  `Tempo_Ativacao_Min` INT DEFAULT 10 COMMENT 'Tempo que as lâmpadas ficam ligadas (minutos)',
  PRIMARY KEY (`ID_Filial`),
  INDEX `idx_cidade` (`Cidade`),
  INDEX `idx_estado` (`Estado`)
) ENGINE = InnoDB
AUTO_INCREMENT = 3
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_0900_ai_ci
COMMENT = 'Dimensão Filial - Inclui configuração de iluminação LED';

-- ════════════════════════════════════════════════════════════════
-- DIMENSÃO: SENSOR
-- Armazena informações dos sensores IoT
-- ════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS `dim_sensor` (
  `ID_Sensor` INT NOT NULL AUTO_INCREMENT,
  `Tipo_Sensor` VARCHAR(50) NOT NULL COMMENT 'Movimento, Temperatura/Umidade, Iluminacao',
  `Modelo` VARCHAR(50) NOT NULL COMMENT 'Ex: PIR HC-SR501, DHT11, LED Sistema 100x20W',
  `Localizacao` VARCHAR(100) NOT NULL,
  `ID_Filial` INT NOT NULL,
  `Status` ENUM('Ativo', 'Inativo', 'Manutenção') NULL DEFAULT 'Ativo',
  PRIMARY KEY (`ID_Sensor`),
  INDEX `idx_filial` (`ID_Filial` ASC) VISIBLE,
  INDEX `idx_tipo` (`Tipo_Sensor`),
  INDEX `idx_status` (`Status`),
  CONSTRAINT `fk_sensor_filial`
    FOREIGN KEY (`ID_Filial`)
    REFERENCES `dim_filial` (`ID_Filial`)
    ON DELETE RESTRICT
    ON UPDATE CASCADE
) ENGINE = InnoDB
AUTO_INCREMENT = 9
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_0900_ai_ci
COMMENT = 'Dimensão Sensor - PIR HC-SR501, DHT11, Sistema LED';

-- ════════════════════════════════════════════════════════════════
-- DIMENSÃO: TEMPO
-- Dimensão temporal para análises OLAP
-- ════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS `dim_tempo` (
  `ID_Data` INT NOT NULL COMMENT 'Unix Timestamp',
  `Data_Completa` DATETIME NOT NULL,
  `Ano` SMALLINT NOT NULL,
  `Mes` TINYINT NOT NULL,
  `Dia` TINYINT NOT NULL,
  `DiaSemana` VARCHAR(15) NOT NULL,
  `Hora` TINYINT NOT NULL,
  `Periodo_Dia` ENUM('Madrugada', 'Manhã', 'Tarde', 'Noite') NOT NULL,
  PRIMARY KEY (`ID_Data`),
  INDEX `idx_data_completa` (`Data_Completa`),
  INDEX `idx_ano_mes` (`Ano`, `Mes`),
  INDEX `idx_periodo` (`Periodo_Dia`)
) ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_0900_ai_ci
COMMENT = 'Dimensão Tempo para análises temporais';

-- ════════════════════════════════════════════════════════════════
-- FATO: LEITURAS
-- Tabela fato com todas as métricas de sensores e consumo energético
-- ATUALIZADA v2.0: Novos campos de iluminação e custo
-- ════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS `fato_leituras` (
  `ID_Leitura` BIGINT NOT NULL AUTO_INCREMENT,
  `ID_Sensor` INT NOT NULL,
  `ID_Filial` INT NOT NULL,
  `ID_Data` INT NOT NULL,
  -- Métricas de sensores
  `Temperatura` DECIMAL(4,1) NULL DEFAULT NULL COMMENT 'Celsius',
  `Umidade` DECIMAL(4,1) NULL DEFAULT NULL COMMENT 'Percentual',
  `Movimento_Detectado` TINYINT NULL DEFAULT 0 COMMENT '0=Não, 1=Sim',
  `Lampada_Ligada` TINYINT NULL DEFAULT 0 COMMENT '0=Desligada, 1=Ligada',
  -- NOVOS CAMPOS v2.0 - Sistema de Iluminação
  `Qtd_Lampadas_Ativas` INT NULL DEFAULT 0 COMMENT 'Quantidade de lâmpadas acionadas',
  `Tempo_Ligado_Min` INT NULL DEFAULT 0 COMMENT 'Tempo ligado em minutos',
  `Consumo_kWh` DECIMAL(8,4) NULL DEFAULT 0.0000 COMMENT 'Consumo em kWh',
  `Custo_Reais` DECIMAL(8,4) NULL DEFAULT 0.0000 COMMENT 'Custo em R$',
  -- Metadados
  `Timestamp` DATETIME NOT NULL,
  `Qualidade_Sinal` TINYINT NULL DEFAULT 100 COMMENT 'Percentual de qualidade',
  `Status_Leitura` ENUM('Válida', 'Erro', 'Suspeita') NULL DEFAULT 'Válida',
  PRIMARY KEY (`ID_Leitura`),
  INDEX `idx_sensor` (`ID_Sensor` ASC) VISIBLE,
  INDEX `idx_filial` (`ID_Filial` ASC) VISIBLE,
  INDEX `idx_data` (`ID_Data` ASC) VISIBLE,
  INDEX `idx_timestamp` (`Timestamp`),
  INDEX `idx_lampada` (`Lampada_Ligada`),
  INDEX `idx_movimento` (`Movimento_Detectado`),
  CONSTRAINT `fk_leituras_sensor`
    FOREIGN KEY (`ID_Sensor`)
    REFERENCES `dim_sensor` (`ID_Sensor`)
    ON DELETE RESTRICT
    ON UPDATE CASCADE,
  CONSTRAINT `fk_leituras_filial`
    FOREIGN KEY (`ID_Filial`)
    REFERENCES `dim_filial` (`ID_Filial`)
    ON DELETE RESTRICT
    ON UPDATE CASCADE,
  CONSTRAINT `fk_leituras_tempo`
    FOREIGN KEY (`ID_Data`)
    REFERENCES `dim_tempo` (`ID_Data`)
    ON DELETE RESTRICT
    ON UPDATE CASCADE
) ENGINE = InnoDB
AUTO_INCREMENT = 1
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_0900_ai_ci
COMMENT = 'Tabela Fato - Leituras IoT com métricas de energia';

-- ════════════════════════════════════════════════════════════════
-- STORED PROCEDURE: INSERIR LEITURA
-- Calcula automaticamente consumo e custo energético
-- ATUALIZADA v2.0: Cálculo de 100 lâmpadas 20W
-- ════════════════════════════════════════════════════════════════
DELIMITER $$

DROP PROCEDURE IF EXISTS `sp_inserir_leitura`$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_inserir_leitura`(
  IN p_id_sensor INT,
  IN p_temperatura DECIMAL(4,1),
  IN p_umidade DECIMAL(4,1),
  IN p_movimento TINYINT,
  IN p_lampada TINYINT
)
BEGIN
  -- Variáveis
  DECLARE v_id_filial INT;
  DECLARE v_id_data INT;
  DECLARE v_consumo DECIMAL(8,4);
  DECLARE v_custo DECIMAL(8,4);
  DECLARE v_timestamp DATETIME;
  DECLARE v_periodo VARCHAR(15);
  DECLARE v_dia_semana VARCHAR(15);
  DECLARE v_qtd_lampadas INT;
  DECLARE v_potencia_w INT;
  DECLARE v_tempo_min INT;
  DECLARE v_tarifa_kwh DECIMAL(6,4);

  -- Configuração da tarifa de energia
  SET v_tarifa_kwh = 0.9500; -- R$ 0,95 por kWh

  -- Buscar configuração da filial
  SELECT 
    ds.ID_Filial, 
    df.Qtd_Lampadas, 
    df.Potencia_Lampada_W, 
    df.Tempo_Ativacao_Min
  INTO 
    v_id_filial, 
    v_qtd_lampadas, 
    v_potencia_w, 
    v_tempo_min
  FROM DIM_SENSOR ds
  JOIN DIM_FILIAL df ON ds.ID_Filial = df.ID_Filial
  WHERE ds.ID_Sensor = p_id_sensor;

  -- Calcular consumo e custo se lâmpada ligada
  -- Fórmula: (Potência_W × Quantidade × Tempo_H) / 1000 = kWh
  -- Exemplo: (20W × 100 × 0.167h) / 1000 = 0.33 kWh
  IF p_lampada = 1 THEN
    SET v_consumo = (v_potencia_w * v_qtd_lampadas * (v_tempo_min / 60.0)) / 1000.0;
    SET v_custo = v_consumo * v_tarifa_kwh;
  ELSE
    SET v_consumo = 0.0000;
    SET v_custo = 0.0000;
    SET v_qtd_lampadas = 0;
    SET v_tempo_min = 0;
  END IF;

  -- Timestamp atual
  SET v_timestamp = NOW();
  SET v_id_data = UNIX_TIMESTAMP(v_timestamp);

  -- Calcular período do dia
  SET v_periodo = CASE
    WHEN HOUR(v_timestamp) >= 0 AND HOUR(v_timestamp) < 6 THEN 'Madrugada'
    WHEN HOUR(v_timestamp) >= 6 AND HOUR(v_timestamp) < 12 THEN 'Manhã'
    WHEN HOUR(v_timestamp) >= 12 AND HOUR(v_timestamp) < 18 THEN 'Tarde'
    ELSE 'Noite'
  END;

  -- Calcular dia da semana
  SET v_dia_semana = CASE DAYOFWEEK(v_timestamp)
    WHEN 1 THEN 'Domingo'
    WHEN 2 THEN 'Segunda'
    WHEN 3 THEN 'Terça'
    WHEN 4 THEN 'Quarta'
    WHEN 5 THEN 'Quinta'
    WHEN 6 THEN 'Sexta'
    WHEN 7 THEN 'Sábado'
  END;

  -- Inserir na DIM_TEMPO se não existir
  INSERT IGNORE INTO DIM_TEMPO (
    ID_Data, Data_Completa, Ano, Mes, Dia, DiaSemana, Hora, Periodo_Dia
  ) VALUES (
    v_id_data,
    v_timestamp,
    YEAR(v_timestamp),
    MONTH(v_timestamp),
    DAY(v_timestamp),
    v_dia_semana,
    HOUR(v_timestamp),
    v_periodo
  );

  -- Inserir leitura com TODOS os campos
  INSERT INTO FATO_LEITURAS (
    ID_Sensor, ID_Filial, ID_Data, 
    Temperatura, Umidade, 
    Movimento_Detectado, Lampada_Ligada, 
    Qtd_Lampadas_Ativas, Tempo_Ligado_Min,
    Consumo_kWh, Custo_Reais, 
    Timestamp, Qualidade_Sinal, Status_Leitura
  ) VALUES (
    p_id_sensor, v_id_filial, v_id_data, 
    p_temperatura, p_umidade, 
    p_movimento, p_lampada, 
    v_qtd_lampadas, v_tempo_min,
    v_consumo, v_custo, 
    v_timestamp, 100, 'Válida'
  );
  
END$$

DELIMITER ;

-- ════════════════════════════════════════════════════════════════
-- VIEW: CONSUMO DETALHADO
-- Visão consolidada para análise de consumo energético
-- ════════════════════════════════════════════════════════════════
CREATE OR REPLACE VIEW `vw_consumo_detalhado` AS
SELECT 
  fl.ID_Leitura,
  df.Nome_Filial,
  df.Cidade,
  ds.Tipo_Sensor,
  ds.Modelo,
  ds.Localizacao,
  fl.Timestamp,
  dt.DiaSemana,
  dt.Periodo_Dia,
  -- Sensores
  fl.Temperatura,
  fl.Umidade,
  fl.Movimento_Detectado,
  fl.Lampada_Ligada,
  -- Sistema de Iluminação
  fl.Qtd_Lampadas_Ativas,
  df.Potencia_Lampada_W,
  fl.Tempo_Ligado_Min,
  (fl.Qtd_Lampadas_Ativas * df.Potencia_Lampada_W) AS Potencia_Total_W,
  -- Energia
  fl.Consumo_kWh,
  ROUND(fl.Consumo_kWh * 1000, 2) AS Consumo_Wh,
  fl.Custo_Reais,
  -- Metadados
  fl.Qualidade_Sinal,
  fl.Status_Leitura
FROM FATO_LEITURAS fl
JOIN DIM_SENSOR ds ON fl.ID_Sensor = ds.ID_Sensor
JOIN DIM_FILIAL df ON fl.ID_Filial = df.ID_Filial
JOIN DIM_TEMPO dt ON fl.ID_Data = dt.ID_Data
ORDER BY fl.Timestamp DESC;

-- ════════════════════════════════════════════════════════════════
-- DADOS INICIAIS: FILIAIS
-- ════════════════════════════════════════════════════════════════
INSERT INTO dim_filial (
  ID_Filial, Nome_Filial, Cidade, Estado, Endereco, 
  Gerente, Telefone, CEP, 
  Qtd_Lampadas, Potencia_Lampada_W, Tempo_Ativacao_Min
) VALUES
(1, 'Aguai', 'Aguai', 'SP', 'Av. Francisco Gonçalves, 409', 
 'João Silva', '(19) 3652-1234', '13868-000', 100, 20, 10),
(2, 'Casa Branca', 'Casa Branca', 'SP', 'BLOCO B Estrada Acesso, SP-340', 
 'Maria Santos', '(19) 3671-5678', '13700-000', 100, 20, 10)
ON DUPLICATE KEY UPDATE 
  Qtd_Lampadas = VALUES(Qtd_Lampadas),
  Potencia_Lampada_W = VALUES(Potencia_Lampada_W),
  Tempo_Ativacao_Min = VALUES(Tempo_Ativacao_Min);

-- ════════════════════════════════════════════════════════════════
-- DADOS INICIAIS: SENSORES
-- ════════════════════════════════════════════════════════════════
INSERT INTO dim_sensor (ID_Sensor, Tipo_Sensor, Modelo, Localizacao, ID_Filial, Status) VALUES
-- Aguai
(1, 'Movimento', 'PIR HC-SR501', 'Entrada Principal', 1, 'Ativo'),
(2, 'Temperatura/Umidade', 'DHT11', 'Sala Principal', 1, 'Ativo'),
(7, 'Iluminacao', 'LED Sistema 100x20W', 'Entrada Principal', 1, 'Ativo'),
-- Casa Branca
(4, 'Movimento', 'PIR HC-SR501', 'Entrada Principal', 2, 'Ativo'),
(5, 'Temperatura/Umidade', 'DHT11', 'Sala Principal', 2, 'Ativo'),
(8, 'Iluminacao', 'LED Sistema 100x20W', 'Entrada Principal', 2, 'Ativo')
ON DUPLICATE KEY UPDATE 
  Modelo = VALUES(Modelo),
  Status = VALUES(Status);

-- ════════════════════════════════════════════════════════════════
-- MENSAGEM FINAL
-- ════════════════════════════════════════════════════════════════
SELECT '' AS '';
SELECT '════════════════════════════════════════════════════════════════' AS '';
SELECT '✅ SCHEMA v2.0 CRIADO COM SUCESSO!' AS '';
SELECT '════════════════════════════════════════════════════════════════' AS '';
SELECT '' AS '';
SELECT '📊 ESTRUTURA CRIADA:' AS '';
SELECT '   • 4 Tabelas (3 dimensões + 1 fato)' AS '';
SELECT '   • 1 Stored Procedure (sp_inserir_leitura)' AS '';
SELECT '   • 1 View (vw_consumo_detalhado)' AS '';
SELECT '   • 2 Filiais configuradas' AS '';
SELECT '   • 6 Sensores ativos' AS '';
SELECT '' AS '';
SELECT '💡 CONFIGURAÇÃO DO SISTEMA:' AS '';
SELECT '   • 100 Lâmpadas LED por filial' AS '';
SELECT '   • Potência: 20W cada' AS '';
SELECT '   • Tempo de ativação: 10 minutos' AS '';
SELECT '   • Consumo por ativação: 0.33 kWh' AS '';
SELECT '   • Custo por ativação: R$ 0,3135' AS '';
SELECT '   • Tarifa de energia: R$ 0,95/kWh' AS '';
SELECT '' AS '';
SELECT '🎯 PRÓXIMOS PASSOS:' AS '';
SELECT '   1. Execute: dart pub get' AS '';
SELECT '   2. Execute: dart run lib/main.dart' AS '';
SELECT '   3. Opcional: mysql -u root -p entrega5 < database/insert.sql' AS '';
SELECT '   4. Análises: Execute database/analise_sql_completa.sql' AS '';
SELECT '' AS '';
SELECT '════════════════════════════════════════════════════════════════' AS '';

SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;
