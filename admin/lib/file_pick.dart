import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

class PickedImage {
  const PickedImage({required this.name, required this.type, required this.bytes});

  final String name;
  final String type;
  final Uint8List bytes;
}

/// Tarayıcının dosya seçme penceresini açar (JPG/PNG/WEBP).
/// Vazgeçilirse null döner.
Future<PickedImage?> pickImage() {
  final completer = Completer<PickedImage?>();
  final input = web.HTMLInputElement()
    ..type = 'file'
    ..accept = 'image/jpeg,image/png,image/webp';

  Future<void> read() async {
    final file = input.files?.item(0);
    if (file == null) {
      if (!completer.isCompleted) completer.complete(null);
      return;
    }
    final buffer = await file.arrayBuffer().toDart;
    if (!completer.isCompleted) {
      completer.complete(
        PickedImage(name: file.name, type: file.type, bytes: buffer.toDart.asUint8List()),
      );
    }
  }

  input.addEventListener(
    'change',
    ((web.Event _) {
      unawaited(read());
    }).toJS,
  );
  input.addEventListener(
    'cancel',
    ((web.Event _) {
      if (!completer.isCompleted) completer.complete(null);
    }).toJS,
  );
  input.click();
  return completer.future;
}
