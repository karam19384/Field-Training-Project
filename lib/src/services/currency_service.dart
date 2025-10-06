// lib/src/services/currency_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class CurrencyService {
  static const String baseCurrency = '₪'; // الشيكل الإسرائيلي الجديد
  
  static final Map<String, String> currencySymbols = {
    '₪': '₪',
    '\$': '\$',
    '€': '€',
    '£': '£',
    
  };

  static final Map<String, String> currencyNames = {
    '₪': 'شيكل إسرائيلي جديد',
    '\$': 'دولار أمريكي',
    '€': 'يورو',
    '£': 'جنيه إسترليني',
  };

  // رموز العملات لـ API
  static final Map<String, String> currencyCodes = {
    '₪': 'ILS',
    '\$': 'USD',
    '€': 'EUR',
    '£': 'GBP',
  };

  // الحصول على سعر الصرف
  static Future<double?> getExchangeRate(String fromCurrency, String toCurrency) async {
    if (fromCurrency == toCurrency) return 1.0;
    
    try {
      final fromCode = currencyCodes[fromCurrency] ?? fromCurrency;
      final toCode = currencyCodes[toCurrency] ?? toCurrency;
      
      final uri = Uri.parse('https://api.exchangerate.host/convert?from=$fromCode&to=$toCode');
      final res = await http.get(uri);
      
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return (data['result'] as num?)?.toDouble();
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting exchange rate: $e');
      }
      return null;
    }
  }

  // تحويل المبلغ بين العملات
  static Future<double?> convertAmount(double amount, String fromCurrency, String toCurrency) async {
    if (fromCurrency == toCurrency) return amount;
    
    final rate = await getExchangeRate(fromCurrency, toCurrency);
    return rate != null ? amount * rate : null;
  }

  // الحصول على رمز العملة
  static String getCurrencySymbol(String currency) {
    return currencySymbols[currency] ?? currency;
  }

  // الحصول على اسم العملة
  static String getCurrencyName(String currency) {
    return currencyNames[currency] ?? currency;
  }

  // الحصول على كود العملة للـ API
  static String getCurrencyCode(String currency) {
    return currencyCodes[currency] ?? currency;
  }

  // الحصول على جميع العملات المدعومة
  static List<String> getSupportedCurrencies() {
    return currencySymbols.keys.toList();
  }
}