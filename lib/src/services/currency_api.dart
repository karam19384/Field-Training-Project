import 'dart:convert';
import 'package:http/http.dart' as http;

class CurrencyApi {
  static Future<double?> getRate(String from, String to) async {
    final uri = Uri.parse('https://api.exchangerate.host/convert?from=$from&to=$to');
    final res = await http.get(uri);
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return (data['result'] as num?)?.toDouble();
    }
    return null;
  }
}
