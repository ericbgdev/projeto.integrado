import 'services/mysql_service.dart';

void main() async {
  print('🚀 Sistema Packbag - MySQL Test');
  await MySQLService.testarConexao();
}
