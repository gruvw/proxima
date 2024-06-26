import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:intl/intl.dart";
import "package:timeago/timeago.dart" as timeago;

/// A function that returns the current date/time as [DateTime]
typedef CurrentDateTimeCallback = DateTime Function();

/// Human Time Service is a service that uses dependency injection
/// to provide related time as a human readable text given a [DateTime]
class HumanTimeService {
  static final _absoluteTimeFormatter = DateFormat("EEEE, MMMM d, yyyy HH:mm");
  static const _relativeLocale = "en_short";
  static const _agoSuffix = "ago";
  static const _agoExceptions = ["now"];

  final CurrentDateTimeCallback currentDateTimeCallback;

  HumanTimeService({
    required this.currentDateTimeCallback,
  });

  /// Converts a [DateTime] to a human readable time ago string
  /// Examples of format: "5m ago", "now", "2 days ago"
  String textTimeSince(DateTime dateTime) {
    final referenceClock = currentDateTimeCallback();

    final textTime = timeago.format(
      dateTime,
      locale: _relativeLocale,
      clock: referenceClock,
    );

    if (_agoExceptions.contains(textTime)) {
      return textTime;
    }

    return "$textTime $_agoSuffix";
  }

  /// Converts a [DateTime] to a human readable date time string
  /// Example of format: "Friday, April 19, 2024 18:04"
  String textTimeAbsolute(DateTime dateTime) {
    return _absoluteTimeFormatter.format(dateTime);
  }
}

final currentDateTimeCallbackProvider =
    Provider<CurrentDateTimeCallback>((ref) {
  return DateTime.now;
});

final humanTimeServiceProvider = Provider<HumanTimeService>((ref) {
  final currentDateTimeCallback = ref.watch(currentDateTimeCallbackProvider);

  return HumanTimeService(
    currentDateTimeCallback: currentDateTimeCallback,
  );
});
