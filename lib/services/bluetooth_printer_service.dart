// lib/services/bluetooth_printer_service.dart

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothPrinterService {
  static BluetoothPrinterService? _instance;
  static BluetoothPrinterService get instance => _instance ??= BluetoothPrinterService._();

  BluetoothPrinterService._();

  BluetoothDevice? _connectedDevice;
  BluetoothConnection? _connection;

  Future<List<BluetoothDevice>> scanDevices() async {
    final scanResults = await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5)).toList();
    await FlutterBluePlus.stopScan();
    return scanResults.map((r) => r.device).toList();
  }

  Future<bool> connectToDevice(BluetoothDevice device) async {
    try {
      _connection?.dispose();
      final connection = await device.connect();
      _connectedDevice = device;
      _connection = connection;
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> disconnect() async {
    await _connection?.dispose();
    _connection = null;
    _connectedDevice = null;
  }

  bool get isConnected => _connection != null && _connection!.isConnected;

  /// Imprime un reçu texte brut formaté sur 32 colonnes
  /// Compatible avec la majorité des imprimantes thermiques (Xprinter, Epson, Bixolon, etc.)
  Future<void> printReceipt(String receiptText) async {
    if (!isConnected) {
      throw Exception("Pas de connexion Bluetooth");
    }

    try {
      // 🔧 Conversion en ISO-8859-1 (Latin-1) pour compatibilité imprimante
      // Beaucoup d'imprimantes ne supportent PAS UTF-8
      final latin1Encoder = Latin1Codec(allowInvalid: true);
      final Uint8List textBytes = Uint8List.fromList(
        latin1Encoder.encode(receiptText + '\n\n'),
      );

      // Avance de 3 lignes (ESC d n)
      final Uint8List feedBytes = Uint8List.fromList([0x1B, 0x64, 0x03]);

      // Coupe partielle du papier (GS V 0)
      final Uint8List cutBytes = Uint8List.fromList([0x1D, 0x56, 0x00]);

      // Envoi séquentiel
      await _connection!.output.add(textBytes);
      await _connection!.output.add(feedBytes);
      await _connection!.output.add(cutBytes);
    } catch (e) {
      throw Exception("Erreur impression : $e");
    }
  }
}