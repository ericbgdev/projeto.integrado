-- MySQL Workbench Forward Engineering
SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

-- -----------------------------------------------------
-- Schema pi-entrega5
-- -----------------------------------------------------
CREATE SCHEMA IF NOT EXISTS `pi-entrega5` DEFAULT CHARACTER SET utf8 ;
USE `pi-entrega5` ;

-- -----------------------------------------------------
-- Table `pi-entrega5`.`DIM_FILIAL`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `pi-entrega5`.`DIM_FILIAL` (
  `ID_Filial` INT NOT NULL AUTO_INCREMENT,
  `Nome_Filial` VARCHAR(100) NOT NULL,
  `Cidade` VARCHAR(50) NOT NULL,
  `Estado` CHAR(2) NOT NULL,
  `Endereco` VARCHAR(200) NOT NULL,
  `Gerente` VARCHAR(100) NOT NULL,
  `Telefone` VARCHAR(20) NOT NULL,
  `CEP` VARCHAR(10) NOT NULL,
  `Data_Criacao` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `Data_Atualizacao` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`ID_Filial`),
  INDEX `idx_filial_cidade` (`Cidade` ASC) VISIBLE,
  INDEX `idx_filial_estado` (`Estado` ASC) VISIBLE);

-- -----------------------------------------------------
-- Table `pi-entrega5`.`DIM_SENSOR`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `pi-entrega5`.`DIM_SENSOR` (
  `ID_Sensor` INT NOT NULL AUTO_INCREMENT,
  `Tipo_Sensor` VARCHAR(50) NOT NULL,
  `Modelo` VARCHAR(50) NOT NULL,
  `Localizacao` VARCHAR(100) NOT NULL,
  `ID_Filial` INT NOT NULL,
  `Status` ENUM('Ativo', 'Inativo', 'Manutenção') NULL DEFAULT 'Ativo',
  `Data_Instalacao` DATE NOT NULL,
  `Data_Criacao` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `Data_Atualizacao` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`ID_Sensor`),
  INDEX `idx_sensor_filial` (`ID_Filial` ASC) VISIBLE,
  INDEX `idx_sensor_tipo` (`Tipo_Sensor` ASC) VISIBLE,
  INDEX `idx_sensor_status` (`Status` ASC) VISIBLE,
  INDEX `fk_sensor_filial` (`ID_Filial` ASC) VISIBLE,
  CONSTRAINT `fk_sensor_filial`
    FOREIGN KEY (`ID_Filial`)
    REFERENCES `pi-entrega5`.`DIM_FILIAL` (`ID_Filial`)
    ON DELETE CASCADE);

-- -----------------------------------------------------
-- Table `pi-entrega5`.`DIM_TEMPO`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `pi-entrega5`.`DIM_TEMPO` (
  `ID_Data` INT NOT NULL,
  `Data_Completa` DATETIME NOT NULL,
  `Ano` SMALLINT NOT NULL,
  `Mes` TINYINT NOT NULL,
  `Dia` TINYINT NOT NULL,
  `DiaSemana` VARCHAR(15) NOT NULL,
  `Hora` TINYINT NOT NULL,
  `Periodo_Dia` ENUM('Madrugada', 'Manhã', 'Tarde', 'Noite') NOT NULL,
  `Final_Semana` ENUM('Sim', 'Não') NOT NULL,
  `Feriado` ENUM('Sim', 'Não') NULL DEFAULT 'Não',
  PRIMARY KEY (`ID_Data`),
  UNIQUE INDEX `uk_data_completa` (`Data_Completa` ASC) VISIBLE,
  INDEX `idx_tempo_data` (`Data_Completa` ASC) VISIBLE,
  INDEX `idx_tempo_ano_mes` (`Ano` ASC, `Mes` ASC) VISIBLE,
  INDEX `idx_tempo_periodo` (`Periodo_Dia` ASC) VISIBLE);

-- -----------------------------------------------------
-- Table `pi-entrega5`.`FATO_LEITURAS`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `pi-entrega5`.`FATO_LEITURAS` (
  `ID_Leitura` BIGINT NOT NULL AUTO_INCREMENT,
  `ID_Sensor` INT NOT NULL,
  `ID_Filial` INT NOT NULL,
  `ID_Data` INT NOT NULL,
  `Temperatura` DECIMAL(4,1) NULL DEFAULT NULL,
  `Umidade` DECIMAL(4,1) NULL DEFAULT NULL,
  `Movimento_Detectado` TINYINT NULL DEFAULT 0,
  `Lampada_Ligada` TINYINT NULL DEFAULT 0,
  `Consumo_kWh` DECIMAL(6,4) NULL DEFAULT 0.0000,
  `Timestamp` DATETIME NOT NULL,
  `Qualidade_Sinal` TINYINT NULL DEFAULT 100,
  `Status_Leitura` ENUM('Válida', 'Erro', 'Suspeita') NULL DEFAULT 'Válida',
  PRIMARY KEY (`ID_Leitura`),
  INDEX `idx_leitura_sensor_data` (`ID_Sensor` ASC, `ID_Data` ASC) VISIBLE,
  INDEX `idx_leitura_filial_data` (`ID_Filial` ASC, `ID_Data` ASC) VISIBLE,
  INDEX `idx_leitura_timestamp` (`Timestamp` ASC) VISIBLE,
  INDEX `idx_leitura_temperatura` (`Temperatura` ASC) VISIBLE,
  INDEX `idx_leitura_movimento` (`Movimento_Detectado` ASC) VISIBLE,
  INDEX `fk_leitura_sensor` (`ID_Sensor` ASC) VISIBLE,
  INDEX `fk_leitura_filial` (`ID_Filial` ASC) VISIBLE,
  INDEX `fk_leitura_tempo` (`ID_Data` ASC) VISIBLE,
  CONSTRAINT `fk_leitura_sensor`
    FOREIGN KEY (`ID_Sensor`)
    REFERENCES `pi-entrega5`.`DIM_SENSOR` (`ID_Sensor`)
    ON DELETE CASCADE,
  CONSTRAINT `fk_leitura_filial`
    FOREIGN KEY (`ID_Filial`)
    REFERENCES `pi-entrega5`.`DIM_FILIAL` (`ID_Filial`)
    ON DELETE CASCADE,
  CONSTRAINT `fk_leitura_tempo`
    FOREIGN KEY (`ID_Data`)
    REFERENCES `pi-entrega5`.`DIM_TEMPO` (`ID_Data`)
    ON DELETE CASCADE);

-- -----------------------------------------------------
-- Inserindo dados na tabela DIM_FILIAL
-- -----------------------------------------------------
INSERT INTO `pi-entrega5`.`DIM_FILIAL` (`ID_Filial`, `Nome_Filial`, `Cidade`, `Estado`, `Endereco`, `Gerente`, `Telefone`, `CEP`) VALUES
(1, 'Aguai', 'Aguai', 'SP', 'Av. Francisco Gonçalves, 409', 'João Silva', '(19) 3652-1234', '13868-000'),
(2, 'Casa Branca', 'Casa Branca', 'SP', 'BLOCO B Estrada Acesso, SP-340', 'Maria Santos', '(19) 3671-5678', '13700-000');

-- -----------------------------------------------------
-- Inserindo dados na tabela DIM_SENSOR
-- -----------------------------------------------------
INSERT INTO `pi-entrega5`.`DIM_SENSOR` (`ID_Sensor`, `Tipo_Sensor`, `Modelo`, `Localizacao`, `ID_Filial`, `Status`, `Data_Instalacao`) VALUES
(1, 'Movimento', 'PIR HC-SR501', 'Entrada Principal', 1, 'Ativo', '2024-01-15'),
(2, 'Temperatura/Umidade', 'DHT11', 'Sala Principal', 1, 'Ativo', '2024-01-15'),
(4, 'Movimento', 'PIR HC-SR501', 'Entrada Principal', 2, 'Ativo', '2024-02-10'),
(5, 'Temperatura/Umidade', 'DHT11', 'Sala Principal', 2, 'Ativo', '2024-02-10'),
(7, 'Iluminacao', 'LED', 'Entrada Principal', 1, 'Ativo', '2024-03-05'),
(8, 'Iluminacao', 'LED', 'Entrada Principal', 2, 'Ativo', '2024-03-05');

-- -----------------------------------------------------
-- Inserindo dados na tabela DIM_TEMPO (apenas alguns registros representativos)
-- -----------------------------------------------------
INSERT INTO `pi-entrega5`.`DIM_TEMPO` (`ID_Data`, `Data_Completa`, `Ano`, `Mes`, `Dia`, `DiaSemana`, `Hora`, `Periodo_Dia`, `Final_Semana`, `Feriado`) VALUES
(1, '2024-11-01 08:00:00', 2024, 11, 1, 'Quinta', 8, 'Manhã', 'Não', 'Não'),
(2, '2024-11-01 08:30:00', 2024, 11, 1, 'Quinta', 8, 'Manhã', 'Não', 'Não'),
(3, '2024-11-01 09:00:00', 2024, 11, 1, 'Quinta', 9, 'Manhã', 'Não', 'Não'),
(4, '2024-11-01 09:30:00', 2024, 11, 1, 'Quinta', 9, 'Manhã', 'Não', 'Não'),
(5, '2024-11-01 10:00:00', 2024, 11, 1, 'Quinta', 10, 'Manhã', 'Não', 'Não'),
(6, '2024-11-01 10:30:00', 2024, 11, 1, 'Quinta', 10, 'Manhã', 'Não', 'Não'),
(33, '2024-11-02 00:00:00', 2024, 11, 2, 'Sexta', 0, 'Madrugada', 'Não', 'Não'),
(34, '2024-11-02 00:30:00', 2024, 11, 2, 'Sexta', 0, 'Madrugada', 'Não', 'Não'),
(81, '2024-11-03 00:00:00', 2024, 11, 3, 'Sábado', 0, 'Madrugada', 'Sim', 'Não'),
(82, '2024-11-03 00:30:00', 2024, 11, 3, 'Sábado', 0, 'Madrugada', 'Sim', 'Não');

-- -----------------------------------------------------
-- Inserindo dados na tabela FATO_LEITURAS (apenas alguns registros representativos)
-- -----------------------------------------------------
INSERT INTO `pi-entrega5`.`FATO_LEITURAS` (`ID_Leitura`, `ID_Sensor`, `ID_Filial`, `ID_Data`, `Temperatura`, `Umidade`, `Movimento_Detectado`, `Lampada_Ligada`, `Consumo_kWh`, `Timestamp`) VALUES
(1, 2, 1, 1, 22.5, 62.5, NULL, 0, 0.0000, '2024-11-01 08:00:00'),
(2, 1, 1, 1, NULL, NULL, 1, 1, 0.0500, '2024-11-01 08:00:00'),
(3, 7, 1, 1, NULL, NULL, NULL, 1, 0.0500, '2024-11-01 08:00:00'),
(4, 5, 2, 1, 24.2, 58.2, NULL, 0, 0.0000, '2024-11-01 08:00:00'),
(5, 4, 2, 1, NULL, NULL, 1, 1, 0.0500, '2024-11-01 08:00:00'),
(6, 8, 2, 1, NULL, NULL, NULL, 1, 0.0500, '2024-11-01 08:00:00'),
(7, 2, 1, 2, 22.8, 61.9, NULL, 0, 0.0000, '2024-11-01 08:30:00'),
(8, 1, 1, 2, NULL, NULL, 0, 0, 0.0000, '2024-11-01 08:30:00'),
(9, 7, 1, 2, NULL, NULL, NULL, 0, 0.0000, '2024-11-01 08:30:00'),
(10, 5, 2, 2, 24.6, 57.8, NULL, 0, 0.0000, '2024-11-01 08:30:00'),
(193, 5, 2, 33, NULL, NULL, 1, 1, 0.0500, '2024-11-02 00:00:00'),
(194, 5, 1, 33, 23.6, 82.3, NULL, 0, 0.0000, '2024-11-02 00:00:00'),
(195, 1, 1, 33, NULL, NULL, NULL, 0, 0.0000, '2024-11-02 00:00:00'),
(196, 4, 1, 33, 22.0, 68.3, NULL, 0, 0.0000, '2024-11-02 00:00:00'),
(197, 5, 2, 33, 23.5, 45.4, 1, 1, 0.0500, '2024-11-02 00:00:00'),
(198, 1, 1, 33, 22.1, 38.9, NULL, 0, 0.0000, '2024-11-02 00:00:00');

-- -----------------------------------------------------
-- procedure sp_inserir_leitura
-- -----------------------------------------------------
DELIMITER $$
USE `pi-entrega5`$$
-- Procedure para inserir leitura
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

    -- Obter ID da dimensão tempo
    SELECT ID_Data INTO v_id_data
    FROM DIM_TEMPO
    WHERE Data_Completa = DATE_FORMAT(NOW(), '%Y-%m-%d %H:00:00');

    -- Inserir leitura
    INSERT INTO FATO_LEITURAS (ID_Sensor, ID_Filial, ID_Data, Temperatura, Umidade, Movimento_Detectado, Lampada_Ligada, Consumo_kWh, Timestamp)
    VALUES (p_id_sensor, v_id_filial, v_id_data, p_temperatura, p_umidade, p_movimento, p_lampada, v_consumo, NOW());
END$$
DELIMITER ;

SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;