import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// iOS'un yerel özellikleri (ios/Runner/AppDelegate.swift, kanal 'erdek/system'):
/// paylaşım penceresi, Apple'ın puanlama penceresi, sürüm numarası.
/// Paket eklemeden; hata olursa sessizce geçer.
abstract interface class SystemBridge {
  /// iOS paylaşım penceresini açar (metin + bağlantı).
  Future<void> share(String text);

  /// Apple'ın kendi "Uygulamayı değerlendir" penceresi. Ne zaman ve kaç kez
  /// gösterileceğine iOS karar verir (yılda en fazla 3).
  Future<void> requestReview();

  /// "1.0.0 (5)" gibi; bilinmiyorsa null.
  Future<String?> appVersion();

  /// iOS'un kendi "Etkinlik ekle" penceresini doldurulmuş açar.
  /// Sonuç: [CalendarResult].
  Future<CalendarResult> addToCalendar(CalendarEntry entry);
}

enum CalendarResult { saved, canceled, denied, unavailable }

/// Takvime eklenecek etkinlik. Saatler Erdek saatiyle (alanlar).
class CalendarEntry {
  const CalendarEntry({
    required this.title,
    required this.start,
    required this.end,
    this.allDay = false,
    this.location,
    this.notes,
    this.url,
  });

  final String title;
  final DateTime start;
  final DateTime end;
  final bool allDay;
  final String? location;
  final String? notes;
  final String? url;

  static List<int> _parts(DateTime d) => [d.year, d.month, d.day, d.hour, d.minute];

  Map<String, Object?> toArgs() => {
        'title': title,
        'start': _parts(start),
        'end': _parts(end),
        'allDay': allDay,
        'location': location,
        'notes': notes,
        'url': url,
      };
}

class ChannelSystemBridge implements SystemBridge {
  static const _channel = MethodChannel('erdek/system');

  @override
  Future<void> share(String text) async {
    try {
      await _channel.invokeMethod<void>('share', {'text': text});
    } on Exception {
      // Paylaşım açılamadıysa yapılacak bir şey yok.
    }
  }

  @override
  Future<void> requestReview() async {
    try {
      await _channel.invokeMethod<void>('requestReview');
    } on Exception {
      // iOS göstermeyebilir; sorun değil.
    }
  }

  @override
  Future<String?> appVersion() async {
    try {
      return await _channel.invokeMethod<String>('appVersion');
    } on Exception {
      return null;
    }
  }

  @override
  Future<CalendarResult> addToCalendar(CalendarEntry entry) async {
    try {
      final r = await _channel.invokeMethod<String>('addToCalendar', entry.toArgs());
      return CalendarResult.values.where((v) => v.name == r).firstOrNull ?? CalendarResult.unavailable;
    } on Exception {
      return CalendarResult.unavailable;
    }
  }
}

/// Testler ve önizlemeler.
class NoopSystemBridge implements SystemBridge {
  final shared = <String>[];
  var reviewRequests = 0;

  @override
  Future<void> share(String text) async => shared.add(text);

  @override
  Future<void> requestReview() async => reviewRequests++;

  @override
  Future<String?> appVersion() async => null;

  final calendar = <CalendarEntry>[];

  @override
  Future<CalendarResult> addToCalendar(CalendarEntry entry) async {
    calendar.add(entry);
    return CalendarResult.saved;
  }
}

/// main() içinde ChannelSystemBridge ile override edilir.
final systemBridgeProvider = Provider<SystemBridge>((ref) => NoopSystemBridge());

final appVersionProvider = FutureProvider<String?>(
  (ref) => ref.watch(systemBridgeProvider).appVersion(),
);
