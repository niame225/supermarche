// lib/services/tcp_printer_service.dart

import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';

class TcpPrinterService {
  static TcpPrinterService? _instance;
  static TcpPrinterService get instance => _instance ??= TcpPrinterService._();

  TcpPrinterService._();

  String? _ipAddress;
  int _port = 9100; // Port standard pour les imprimantes ESC/POS
  Socket? _socket;

  bool get isConnected => _socket != null && _socket!.connected;

  /// Configure l'adresse IP et le port de l'imprimante
  void configure(String ipAddress, {int port = 9100}) {
    _ipAddress = ipAddress;
    _port = port;
  }

  /// Se connecte à l'imprimante via TCP
  Future<bool> connect() async {
    if (_ipAddress == null) {
      throw Exception("IP non configurée");
    }
    try {
      _socket = await Socket.connect(_ipAddress!, _port, timeout: const Duration(seconds: 5));
      return true;
    } catch (e) {
      _socket = null;
      return false;
    }
  }

  /// Déconnecte proprement
  Future<void> disconnect() async {
    await _socket?.close();
    _socket = null;
  }

  /// Imprime un reçu texte brut formaté sur 32 colonnes
  Future<void> printReceipt(String receiptText) async {
    if (_socket == null || !_socket!.connected) {
      throw Exception("Pas de connexion TCP");
    }

    try {
      // 🔧 Encodage compatible imprimante : Latin-1 (ISO-8859-1)
      final latin1Encoder = Latin1Codec(allowInvalid: true);
      final Uint8List textBytes = Uint8List.fromList(
        latin1Encoder.encode(receiptText + '\n\n'),
      );

      // Commandes ESC/POS
      final Uint8List feedBytes = Uint8List.fromList([0x1B, 0x64, 0x03]); // Avance 3 lignes
      final Uint8List cutBytes = Uint8List.fromList([0x1D, 0x56, 0x00]);  // Coupe partielle

      // Envoi
      _socket!.add(textBytes);
      await _socket!.flush();
      _socket!.add(feedBytes);
      await _socket!.flush();
      _socket!.add(cutBytes);
      await _socket!.flush();
    } catch (e) {
      throw Exception("Erreur impression TCP : $e");
    }
  }
}