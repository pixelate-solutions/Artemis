import 'package:intl/intl.dart';

final DateFormat _timestampFormat = DateFormat('MMM d, yyyy • h:mm a');
final DateFormat _dateGroupFormat = DateFormat('EEEE, MMM d');

String formatTimestamp(int millis) {
  final dt = DateTime.fromMillisecondsSinceEpoch(millis);
  return _timestampFormat.format(dt);
}

String formatTimestampFromDate(DateTime date) {
  return _timestampFormat.format(date);
}

String formatDateGroup(DateTime date) {
  return _dateGroupFormat.format(date);
}
