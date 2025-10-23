// lib/services/print_service_manager.dart

import 'bluetooth_printer_service.dart';
import 'tcp_printer_service.dart';

enum PrintMode { bluetooth, wifi }

class PrintServiceManager {
  static PrintMode _mode = PrintMode.bluetooth;

  static set mode(PrintMode mode) => _mode = mode;
  static PrintMode get mode => _mode;

  static Future<void> printReceipt(String receiptText) async {
    if (_mode == PrintMode.bluetooth) {
      await BluetoothPrinterService.instance.printReceipt(receiptText);
    } else {
      await TcpPrinterService.instance.printReceipt(receiptText);
    }
  }

  static bool get isConnected {
    if (_mode == PrintMode.bluetooth) {
      return BluetoothPrinterService.instance.isConnected;
    } else {
      return TcpPrinterService.instance.isConnected;
    }
  }
}