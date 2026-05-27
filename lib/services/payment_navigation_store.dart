import 'package:shared_preferences/shared_preferences.dart';

class PaymentNavigationStore {
  static const String _prefix = 'pns_';

  static Future<void> set({
    required String bookingRef,
    required String table,
    required String date,
    required String time,
    required String amount,
    required String accessCode,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pns_bookingRef', bookingRef);
    await prefs.setString('pns_table', table);
    await prefs.setString('pns_date', date);
    await prefs.setString('pns_time', time);
    await prefs.setString('pns_amount', amount);
    await prefs.setString('pns_accessCode', accessCode);
    await prefs.setString('pns_startTime', startTime.toIso8601String());
    await prefs.setString('pns_endTime', endTime.toIso8601String());
    await prefs.setBool('pns_hasPending', true);
  }

  static Future<PaymentNavigationData?> consume() async {
    final prefs = await SharedPreferences.getInstance();
    final pending = prefs.getBool('pns_hasPending') ?? false;
    if (!pending) return null;

    final data = PaymentNavigationData(
      bookingRef: prefs.getString('pns_bookingRef') ?? '',
      table: prefs.getString('pns_table') ?? '',
      date: prefs.getString('pns_date') ?? '',
      time: prefs.getString('pns_time') ?? '',
      amount: prefs.getString('pns_amount') ?? '',
      accessCode: prefs.getString('pns_accessCode') ?? '',
      startTime: DateTime.parse(prefs.getString('pns_startTime')!),
      endTime: DateTime.parse(prefs.getString('pns_endTime')!),
    );

    await prefs.setBool('pns_hasPending', false);
    return data;
  }

  static Future<bool> get hasPending async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('pns_hasPending') ?? false;
  }
}

class PaymentNavigationData {
  final String bookingRef;
  final String table;
  final String date;
  final String time;
  final String amount;
  final String accessCode;
  final DateTime startTime;
  final DateTime endTime;

  PaymentNavigationData({
    required this.bookingRef,
    required this.table,
    required this.date,
    required this.time,
    required this.amount,
    required this.accessCode,
    required this.startTime,
    required this.endTime,
  });
}
