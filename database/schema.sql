-- ════════════════════════════════════════════════════════════════
-- SISTEMA PACKBAG - SCHEMA ATUALIZADO
-- 100 Lâmpadas LED 20W por Filial
-- Tempo de Ativação: 10 minutos
-- Consumo por Ativação: 0.33 kWh (100 × 20W × 10min)
-- Custo por Ativação: R$ 0,3135 (0.33 kWh × R$ 0,95)
-- ════════════════════════════════════════════════════════════════

SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

-- -----------------------------------------------------
-- Schema entrega5
-- -----------------------------------------------------
CREATE SCHEMA IF NOT EXISTS `entrega5` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci ;
USE `entrega5` ;

-- -----------------------------------------------------
-- Table `entrega5`.`dim_filial`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `entrega5`.`dim_filial` (
  `ID_Filial` INT NOT NULL AUTO_INCREMENT,
  `Nome_Filial` VARCHAR(100) NOT NULL,
  `Cidade` VARCHAR(50) NOT NULL,
  `Estado` CHAR(2) NOT NULL,
  `Endereco` VARCHAR(200) NOT NULL,
  `Gerente` VARCHAR(100) NOT NULL,
  `Telefone` VARCHAR(20) NOT NULL,
  `CEP` VARCHAR(10) NOT NULL,
  `Qtd_Lampadas` INT DEFAULT 100 COMMENT 'Quantidade de lâmpadas LED na filial',
  `Potencia_Lampada_W` INT DEFAULT 20 COMMENT 'Potência de cada lâmpada em Watts',
  `Tempo_Ativacao_Min` INT DEFAULT 10 COMMENT 'Tempo que as lâmpadas ficam ligadas (minutos)',
  PRIMARY KEY (`ID_Filial`)
) ENGINE = InnoDB
AUTO_INCREMENT = 3
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_0900_ai_ci
COMMENT = 'Dimensão Filial - Inclui configuração de iluminação';

-- -----------------------------------------------------
-- Table `entrega5`.`dim_sensor`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `entrega5`.`dim_sensor` (
  `ID_Sensor` INT NOT NULL AUTO_INCREMENT,
  `Tipo_Sensor` VARCHAR(50) NOT NULL,
  `Modelo` VARCHAR(50) NOT NULL,
  `Localizacao` VARCHAR(100) NOT NULL,
  `ID_Filial` INT NOT NULL,
  `Status` ENUM('Ativo', 'Inativo', 'Manutenção') NULL DEFAULT 'Ativo',
  PRIMARY KEY (`ID_Sensor`),
  INDEX `ID_Filial` (`ID_Filial` ASC) VISIBLE,
  CONSTRAINT `dim_sensor_ibfk_1`
    FOREIGN KEY (`ID_Filial`)
    REFERENCES `entrega5`.`dim_filial` (`ID_Filial`)
) ENGINE = InnoDB
AUTO_INCREMENT = 9
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_0900_ai_ci;

-- -----------------------------------------------------
-- Table `entrega5`.`dim_tempo`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `entrega5`.`dim_tempo` (
  `ID_Data` INT NOT NULL,
  `Data_Completa` DATETIME NOT NULL,
  `Ano` SMALLINT NOT NULL,
  `Mes` TINYINT NOT NULL,
  `Dia` TINYINT NOT NULL,
  `DiaSemana` VARCHAR(15) NOT NULL,
  `Hora` TINYINT NOT NULL,
  `Periodo_Dia` ENUM('Madrugada', 'Manhã', 'Tarde', 'Noite') NOT NULL,
  PRIMARY KEY (`ID_Data`)
) ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_0900_ai_ci;

-- -----------------------------------------------------
-- Table `entrega5`.`fato_leituras`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `entrega5`.`fato_leituras` (
  `ID_Leitura` BIGINT NOT NULL AUTO_INCREMENT,
  `ID_Sensor` INT NOT NULL,
  `ID_Filial` INT NOT NULL,
  `ID_Data` INT NOT NULL,
  `Temperatura` DECIMAL(4,1) NULL DEFAULT NULL,
  `Umidade` DECIMAL(4,1) NULL DEFAULT NULL,
  `Movimento_Detectado` TINYINT NULL DEFAULT '0',
  `Lampada_Ligada` TINYINT NULL DEFAULT '0',
  `Qtd_Lampadas_Ativas` INT NULL DEFAULT 0 COMMENT 'Quantidade de lâmpadas que foram acionadas',
  `Tempo_Ligado_Min` INT NULL DEFAULT 0 COMMENT 'Tempo que as lâmpadas ficaram ligadas (minutos)',
  `Consumo_kWh` DECIMAL(8,4) NULL DEFAULT '0.0000' COMMENT 'Consumo total em kWh',
  `Custo_Reais` DECIMAL(8,4) NULL DEFAULT '0.0000' COMMENT 'Custo em reais (R$)',
  `Timestamp` DATETIME NOT NULL,
  `Qualidade_Sinal` TINYINT NULL DEFAULT '100',
  `Status_Leitura` ENUM('Válida', 'Erro', 'Suspeita') NULL DEFAULT 'Válida',
  PRIMARY KEY (`ID_Leitura`),
  INDEX `ID_Sensor` (`ID_Sensor` ASC) VISIBLE,
  INDEX `ID_Filial` (`ID_Filial` ASC) VISIBLE,
  INDEX `ID_Data` (`ID_Data` ASC) VISIBLE,
  CONSTRAINT `fato_leituras_ibfk_1`
    FOREIGN KEY (`ID_Sensor`)
    REFERENCES `entrega5`.`dim_sensor` (`ID_Sensor`),
  CONSTRAINT `fato_leituras_ibfk_2`
    FOREIGN KEY (`ID_Filial`)
    REFERENCES `entrega5`.`dim_filial` (`ID_Filial`),
  CONSTRAINT `fato_leituras_ibfk_3`
    FOREIGN KEY (`ID_Data`)
    REFERENCES `entrega5`.`dim_tempo` (`ID_Data`)
) ENGINE = InnoDB
AUTO_INCREMENT = 234
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_0900_ai_ci;

-- ════════════════════════════════════════════════════════════════
-- STORED PROCEDURE - sp_inserir_leitura
-- Atualizada para calcular consumo de 100 lâmpadas de 20W
-- ════════════════════════════════════════════════════════════════

DELIMITER $$
USE `entrega5`$$
DROP PROCEDURE IF EXISTS `sp_inserir_leitura`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_inserir_leitura`(
  IN p_id_sensor INT,
  IN p_temperatura DECIMAL(4,1),
  IN p_umidade DECIMAL(4,1),
  IN p_movimento TINYINT,
  IN p_lampada TINYINT
)
BEGIN
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

  -- Configurações do sistema
  SET v_tarifa_kwh = 0.9500; -- R$ 0,95 por kWh

  -- Pegar dados da filial e do sensor
  SELECT ds.ID_Filial, df.Qtd_Lampadas, df.Potencia_Lampada_W, df.Tempo_Ativacao_Min
  INTO v_id_filial, v_qtd_lampadas, v_potencia_w, v_tempo_min
  FROM DIM_SENSOR ds
  JOIN DIM_FILIAL df ON ds.ID_Filial = df.ID_Filial
  WHERE ds.ID_Sensor = p_id_sensor;

  -- Calcular consumo se lâmpada ligada
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

  -- Inserir leitura com todos os novos campos
  INSERT INTO FATO_LEITURAS (
    ID_Sensor, ID_Filial, ID_Data, 
    Temperatura, Umidade, 
    Movimento_Detectado, Lampada_Ligada, 
    Qtd_Lampadas_Ativas, Tempo_Ligado_Min,
    Consumo_kWh, Custo_Reais, 
    Timestamp
  ) VALUES (
    p_id_sensor, v_id_filial, v_id_data, 
    p_temperatura, p_umidade, 
    p_movimento, p_lampada, 
    v_qtd_lampadas, v_tempo_min,
    v_consumo, v_custo, 
    v_timestamp
  );
  
  -- Log para debug
  SELECT CONCAT(
    '✅ Leitura inserida: ',
    'Sensor=', p_id_sensor, ', ',
    'Filial=', v_id_filial, ', ',
    'Lâmpadas=', v_qtd_lampadas, ', ',
    'Tempo=', v_tempo_min, 'min, ',
    'Consumo=', v_consumo, 'kWh, ',
    'Custo=R$', v_custo
  ) AS Info;
  
END$$

DELIMITER ;

-- ════════════════════════════════════════════════════════════════
-- VIEW - vw_consumo_detalhado
-- Visão para análise de consumo e custos
-- ════════════════════════════════════════════════════════════════

CREATE OR REPLACE VIEW vw_consumo_detalhado AS
SELECT 
  fl.ID_Leitura,
  df.Nome_Filial,
  ds.Tipo_Sensor,
  ds.Localizacao,
  fl.Timestamp,
  fl.Movimento_Detectado,
  fl.Lampada_Ligada,
  fl.Qtd_Lampadas_Ativas,
  df.Potencia_Lampada_W,
  fl.Tempo_Ligado_Min,
  fl.Consumo_kWh,
  fl.Custo_Reais,
  dt.Periodo_Dia,
  dt.DiaSemana,
  -- Métricas calculadas
  (fl.Qtd_Lampadas_Ativas * df.Potencia_Lampada_W) AS Potencia_Total_W,
  ROUND(fl.Consumo_kWh * 1000, 2) AS Consumo_Wh,
  CONCAT('R$ ', FORMAT(fl.Custo_Reais, 2, 'pt_BR')) AS Custo_Formatado
FROM FATO_LEITURAS fl
JOIN DIM_SENSOR ds ON fl.ID_Sensor = ds.ID_Sensor
JOIN DIM_FILIAL df ON fl.ID_Filial = df.ID_Filial
JOIN DIM_TEMPO dt ON fl.ID_Data = dt.ID_Data
ORDER BY fl.Timestamp DESC;

-- ════════════════════════════════════════════════════════════════
-- DADOS INICIAIS - Filiais com configuração de iluminação
-- ════════════════════════════════════════════════════════════════

INSERT INTO dim_filial (ID_Filial, Nome_Filial, Cidade, Estado, Endereco, Gerente, Telefone, CEP, Qtd_Lampadas, Potencia_Lampada_W, Tempo_Ativacao_Min) VALUES
(1, 'Aguai', 'Aguai', 'SP', 'Av. Francisco Gonçalves, 409', 'João Silva', '(19) 3652-1234', '13868-000', 100, 20, 10),
(2, 'Casa Branca', 'Casa Branca', 'SP', 'BLOCO B Estrada Acesso, SP-340', 'Maria Santos', '(19) 3671-5678', '13700-000', 100, 20, 10)
ON DUPLICATE KEY UPDATE 
  Qtd_Lampadas = VALUES(Qtd_Lampadas),
  Potencia_Lampada_W = VALUES(Potencia_Lampada_W),
  Tempo_Ativacao_Min = VALUES(Tempo_Ativacao_Min);

-- ════════════════════════════════════════════════════════════════
-- DADOS INICIAIS - Sensores
-- ════════════════════════════════════════════════════════════════

INSERT INTO dim_sensor (ID_Sensor, Tipo_Sensor, Modelo, Localizacao, ID_Filial, Status) VALUES
(1, 'Movimento', 'PIR HC-SR501', 'Entrada Principal', 1, 'Ativo'),
(2, 'Temperatura/Umidade', 'DHT11', 'Sala Principal', 1, 'Ativo'),
(4, 'Movimento', 'PIR HC-SR501', 'Entrada Principal', 2, 'Ativo'),
(5, 'Temperatura/Umidade', 'DHT11', 'Sala Principal', 2, 'Ativo'),
(7, 'Iluminacao', 'LED Sistema 100x20W', 'Entrada Principal', 1, 'Ativo'),
(8, 'Iluminacao', 'LED Sistema 100x20W', 'Entrada Principal', 2, 'Ativo')
ON DUPLICATE KEY UPDATE 
  Modelo = VALUES(Modelo),
  Status = VALUES(Status);

-- ════════════════════════════════════════════════════════════════
-- INFORMAÇÕES DO SISTEMA
-- ════════════════════════════════════════════════════════════════

SELECT '════════════════════════════════════════════════════════════════' AS '';
SELECT '✅ SCHEMA ATUALIZADO COM SUCESSO!' AS '';
SELECT '════════════════════════════════════════════════════════════════' AS '';
SELECT '' AS '';
SELECT '📊 CONFIGURAÇÃO DO SISTEMA:' AS '';
SELECT '   • 100 Lâmpadas LED por filial' AS '';
SELECT '   • Potência: 20W cada' AS '';
SELECT '   • Tempo de ativação: 10 minutos' AS '';
SELECT '   • Consumo por ativação: 0.33 kWh' AS '';
SELECT '   • Custo por ativação: R$ 0,3135' AS '';
SELECT '   • Tarifa de energia: R$ 0,95/kWh' AS '';
SELECT '' AS '';
SELECT '🎯 PRÓXIMOS PASSOS:' AS '';
SELECT '   1. Execute: dart pub get' AS '';
SELECT '   2. Execute: dart run main.dart' AS '';
SELECT '   3. Verifique os custos em tempo real!' AS '';
SELECT '════════════════════════════════════════════════════════════════' AS '';

SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;
