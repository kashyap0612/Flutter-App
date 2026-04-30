import 'package:intl/intl.dart';

class Formatters {
  static String dateTime(DateTime dt) => DateFormat('dd MMM yyyy, hh:mm a').format(dt);
  static String percent(double value) => '${(value * 100).toStringAsFixed(2)}%';
}
