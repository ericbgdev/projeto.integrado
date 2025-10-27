import 'dart:math';
import '../models/leitura_sensor.dart';
import '../data/sensores_data.dart';
import 'mysql_service.dart';
import 'firebase_service.dart';

class SimuladorService {
  Random random = Random();
  
  Future<LeituraSensor> gerarLeitura() async 
