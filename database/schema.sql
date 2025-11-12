-- MySQL Workbench Forward Engineering

SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

-- -----------------------------------------------------
-- Schema mydb
-- -----------------------------------------------------
-- -----------------------------------------------------
-- Schema entrega5
-- -----------------------------------------------------

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
  PRIMARY KEY (`ID_Filial`))
ENGINE = InnoDB
AUTO_INCREMENT = 3
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_0900_ai_ci;


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
    REFERENCES `entrega5`.`dim_filial` (`ID_Filial`))
ENGINE = InnoDB
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
  PRIMARY KEY (`ID_Data`))
ENGINE = InnoDB
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
  `Consumo_kWh` DECIMAL(6,4) NULL DEFAULT '0.0000',
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
    REFERENCES `entrega5`.`dim_tempo` (`ID_Data`))
ENGINE = InnoDB
AUTO_INCREMENT = 234
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_0900_ai_ci;

USE `entrega5` ;

-- -----------------------------------------------------
-- procedure sp_inserir_leitura
-- -----------------------------------------------------

DELIMITER $$
USE `entrega5`$$
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
  DECLARE v_consumo DECIMAL(6,4);
  DECLARE v_timestamp DATETIME;
  DECLARE v_periodo VARCHAR(15);
  DECLARE v_dia_semana VARCHAR(15);

  -- Pegar ID da filial do sensor
  SELECT ID_Filial INTO v_id_filial 
  FROM DIM_SENSOR 
  WHERE ID_Sensor = p_id_sensor;

  -- Calcular consumo
  SET v_consumo = CASE WHEN p_lampada = 1 THEN 0.0500 ELSE 0.0000 END;

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

  -- Inserir leitura
  INSERT INTO FATO_LEITURAS (
    ID_Sensor, ID_Filial, ID_Data, Temperatura, Umidade, 
    Movimento_Detectado, Lampada_Ligada, Consumo_kWh, Timestamp
  ) VALUES (
    p_id_sensor, v_id_filial, v_id_data, p_temperatura, p_umidade, 
    p_movimento, p_lampada, v_consumo, v_timestamp
  );
END$$

DELIMITER ;

SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;
