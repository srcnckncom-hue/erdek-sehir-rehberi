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
}

/// main() içinde ChannelSystemBridge ile override edilir.
final systemBridgeProvider = Provider<SystemBridge>((ref) => NoopSystemBridge());

final appVersionProvider = FutureProvider<String?>(
  (ref) => ref.watch(systemBridgeProvider).appVersion(),
);
