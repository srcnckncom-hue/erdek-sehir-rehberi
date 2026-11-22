import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Gerçek bir Android cihazda mı çalışıyoruz? Testlerde (ana makine Linux/macOS) false;
/// bu yüzden Android'e özel yerel parçalar testleri etkilemez.
bool get isAndroidDevice => !kIsWeb && Platform.isAndroid;

/// Yerel harita (iOS: MapKit, Android: OpenStreetMap) gösterilebilir mi?
bool get hasNativeMap => isAndroidDevice || (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS);

/// 'erdek/map' yerel harita görünümü; parametreler iki platformda aynı
/// (pins, path, fit, centerLat, centerLng).
Widget nativeMapView({required Map<String, Object?> params, PlatformViewCreatedCallback? onCreated}) =>
    isAndroidDevice
        ? AndroidView(
            viewType: 'erdek/map',
            creationParams: params,
            creationParamsCodec: const StandardMessageCodec(),
            onPlatformViewCreated: onCreated,
          )
        : UiKitView(
            viewType: 'erdek/map',
            creationParams: params,
            creationParamsCodec: const StandardMessageCodec(),
            onPlatformViewCreated: onCreated,
          );
