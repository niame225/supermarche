// lib/services/print_service.dart

import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:esc_pos_printer/esc_pos_printer.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_bluetooth_basic/flutter_bluetooth_basic.dart';

class PrintService {
  static const int _printerPort = 9100; // Port standard pour imprimantes réseau (Wi-Fi)
  static const PaperSize _paperSize = PaperSize.mm80;

  // Liste des imprimantes Bluetooth détectées
  final FlutterBluetoothBasic _bluetooth = FlutterBluetoothBasic.instance;

  // ----------------------------
  // IMPRESSION VIA BLUETOOTH
  // ----------------------------

  Future<void> printViaBluetooth({
    required String deviceAddress,
    required List<LineText> lines,
  }) async {
    if (kIsWeb) {
      throw Exception("L'impression Bluetooth n'est pas supportée sur le Web.");
    }

    // Vérifier les permissions (Android uniquement)
    if (!kIsWeb) {
      final status = await Permission.bluetooth.request();
      if (status.isDenied || status.isPermanentlyDenied) {
        throw Exception("Permission Bluetooth requise pour imprimer.");
      }
    }

    try {
      // Se connecter à l'imprimante
      await _bluetooth.connect(deviceAddress);
      final profile = await _bluetooth.getDeviceProfile(deviceAddress);
      final printer = Printer.connect(
        BluetoothPrinter(
          address: deviceAddress,
          name: profile?.deviceName ?? 'Imprimante Bluetooth',
        ),
        type: PrinterType.bluetooth,
      );

      // Générer le ticket
      final generator = Generator(_paperSize, Profile.PAPER_FULLCUT);
      final bytes = generator.generate(lines);

      // Envoyer à l'imprimante
      await printer.send(bytes);
      await printer.cut();
      await _bluetooth.disconnect();
    } catch (e) {
      await _bluetooth.disconnect();
      throw Exception("Échec de l'impression Bluetooth : $e");
    }
  }

  // ----------------------------
  // IMPRESSION VIA WI-FI (TCP/IP)
  // ----------------------------

  Future<void> printViaWifi({
    required String ipAddress,
    required int port,
    required List<LineText> lines,
  }) async {
    try {
      final printer = Printer.network(
        NetworkPrinter(
          address: ipAddress,
          port: port,
        ),
        type: PrinterType.network,
      );

      final generator = Generator(_paperSize, Profile.PAPER_FULLCUT);
      final bytes = generator.generate(lines);

      await printer.send(bytes);
      await printer.cut();
    } catch (e) {
      throw Exception("Échec de l'impression Wi-Fi : $e");
    }
  }

  // ----------------------------
  // UTILITAIRE : Générer un ticket standard
  // ----------------------------

  List<LineText> generateReceipt({
    required String title,
    required List<Map<String, dynamic>> items, // ex: [{'libelle': 'Pommes', 'qte': 2, 'prix': 1000}]
    required int total,
  }) {
    final List<LineText> lines = [];

    lines.add(LineText(type: LineText.TYPE_TEXT, content: title, align: Align.center, weight: 1, height: 2));
    lines.add(LineText(type: LineText.TYPE_TEXT, content: '', align: Align.left));
    lines.add(LineText(type: LineText.TYPE_TEXT, content: 'Article           Qté   Prix', align: Align.left, weight: 1));
    lines.add(LineText(type: LineText.TYPE_TEXT, content: '-' * 32, align: Align.left));

    for (var item in items) {
      final libelle = item['libelle'] as String;
      final qte = item['qte'] as int;
      final prix = item['prix'] as int;
      final line = '${libelle.padRight(18)}${qte.toString().padLeft(3)}  ${prix.toString().padLeft(8)}';
      lines.add(LineText(type: LineText.TYPE_TEXT, content: line, align: Align.left));
    }

    lines.add(LineText(type: LineText.TYPE_TEXT, content: '-' * 32, align: Align.left));
    lines.add(LineText(type: LineText.TYPE_TEXT, content: 'TOTAL: ${total.toString().padLeft(24)}', align: Align.right, weight: 1));
    lines.add(LineText(type: LineText.TYPE_TEXT, content: '', align: Align.left));
    lines.add(LineText(type: LineText.TYPE_TEXT, content: 'Merci de votre achat !', align: Align.center));
    lines.add(LineText(type: LineText.TYPE_TEXT, content: DateTime.now().toString().substring(0, 19), align: Align.center));

    return lines;
  }
}