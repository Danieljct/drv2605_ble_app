import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../utils/constants.dart';
import '../models/drv2605_params.dart'; // Importación añadida

class BleService extends ChangeNotifier {
  // Elimina la instancia local de FlutterBluePlus, ya que ahora es un singleton global.
  // FlutterBluePlus flutterBlue = FlutterBluePlus.instance; // <--- ELIMINAR O COMENTAR

  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _commandCharacteristic;
  BluetoothCharacteristic? _responseCharacteristic;

  String _connectionStatus = 'Disconnected';
  String _latestResponse = 'No response yet.';

  String get connectionStatus => _connectionStatus;
  String get latestResponse => _latestResponse;
  bool get isConnected => _connectedDevice != null;

  BleService() {
    // Escuchar cambios de estado del adaptador Bluetooth
    // Usar FlutterBluePlus.adapterState en lugar de flutterBlue.state
    FlutterBluePlus.adapterState.listen((BluetoothAdapterState state) { // <--- CORREGIDO
      if (state == BluetoothAdapterState.off) { // <--- CORREGIDO
        _connectionStatus = 'Bluetooth OFF';
        _connectedDevice = null;
        notifyListeners();
      } else if (state == BluetoothAdapterState.on) { // <--- CORREGIDO
        _connectionStatus = 'Bluetooth ON';
        notifyListeners();
      }
    });
  }

  void _updateConnectionStatus(String status) {
    _connectionStatus = status;
    notifyListeners();
  }

  void _updateLatestResponse(String response) {
    _latestResponse = response;
    notifyListeners();
  }

  // Escanear y conectar
 
Future<void> scanAndConnect() async {
  if (await FlutterBluePlus.isSupported == false) {
    _updateConnectionStatus("BLE not supported by this device.");
    return;
  }

  if (await FlutterBluePlus.isOn == false) {
    _updateConnectionStatus("Bluetooth is off. Please turn it on.");
    return;
  }

  _updateConnectionStatus("Scanning...");
  _connectedDevice = null;
  _commandCharacteristic = null;
  _responseCharacteristic = null;

  try {
    // Detener cualquier escaneo previo antes de iniciar uno nuevo
    FlutterBluePlus.stopScan();

    // Declarar la suscripción antes de usarla en el listener
    late final StreamSubscription<List<ScanResult>> scanSubscription;

    // Iniciar el escaneo y escuchar los resultados en tiempo real
    // Agregamos una suscripción para escuchar los resultados de escaneo
    scanSubscription = FlutterBluePlus.scanResults.listen(
      (results) {
        for (ScanResult r in results) {
          debugPrint('Device found: ${r.device.platformName}, ID: ${r.device.id}, RSSI: ${r.rssi}');
          if (r.advertisementData.serviceUuids.isNotEmpty) {
            debugPrint('  Service UUIDs in adv data: ${r.advertisementData.serviceUuids.map((u) => u.str.toLowerCase()).join(', ')}');
          }

          // Verifica que el nombre sea el que esperas
          if (r.device.platformName == ESP32_DEVICE_NAME) {
            debugPrint('MATCH FOUND: ${ESP32_DEVICE_NAME}');
            FlutterBluePlus.stopScan(); // Detener escaneo al encontrar el dispositivo
            scanSubscription.cancel(); // Cancelar la suscripción para evitar más escuchas
            _connectToDevice(r.device); // Intentar conectar
            return; // Salir del bucle y de la función de listener
          }
        }
      },
      onError: (e) => debugPrint("Scan stream error: $e"),
      onDone: () => debugPrint("Scan stream done."),
    );

    // Iniciar el escaneo con un timeout
    // Sin filtro de servicio si el problema persiste, o con filtro si el UUID está en el advertising data.
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));

    // Esperar a que el escaneo termine o que el dispositivo se encuentre
    // Si el dispositivo se encontró y la conexión se inició, la suscripción se cancelará.
    // Si el timeout se cumple y no se encontró el dispositivo, este delay terminará.
    await Future.delayed(const Duration(seconds: 11)); // Pequeño extra para asegurar que el scan `onDone` se procese

    // Si después del timeout y la espera aún no estamos conectados, significa que no se encontró el dispositivo
    if (_connectedDevice == null) {
      _updateConnectionStatus("Scan complete. Device not found.");
    }

  } catch (e) {
    _updateConnectionStatus("Scan failed: $e");
    debugPrint("Scan failed in catch block: $e");
  } finally {
    // Asegurarse de detener el escaneo y cancelar la suscripción si no se hizo antes
    FlutterBluePlus.stopScan();
    // Asegúrate de que la suscripción esté cancelada si no se encontró el dispositivo
    // No es necesario cancelar explícitamente aquí si `_connectToDevice` ya la canceló.
    // Pero si no se encontró nada, `onDone` ya la habrá limpiado.
  }
}
  


  Future<void> _connectToDevice(BluetoothDevice device) async {
    _updateConnectionStatus("Connecting to ${device.platformName}..."); // <--- CORREGIDO
    try {
      await device.connect(timeout: const Duration(seconds: 15));
      _connectedDevice = device;
      _updateConnectionStatus("Connected to ${device.platformName}"); // <--- CORREGIDO

      // Listen for device disconnection
      device.connectionState.listen((BluetoothConnectionState state) async {
        if (state == BluetoothConnectionState.disconnected) {
          _updateConnectionStatus("Disconnected from ${device.platformName}"); // <--- CORREGIDO
          _connectedDevice = null;
          _commandCharacteristic = null;
          _responseCharacteristic = null;
          notifyListeners();
        }
      });

      // Discover services
      await _discoverServices(device);
    } catch (e) {
      _updateConnectionStatus("Failed to connect: $e");
      _connectedDevice = null;
    }
  }

  Future<void> _discoverServices(BluetoothDevice device) async {
    _updateConnectionStatus("Discovering services...");
    try {
      List<BluetoothService> services = await device.discoverServices();
      for (BluetoothService service in services) {
        if (service.uuid.toString().toLowerCase() == SERVICE_UUID) {
          _updateConnectionStatus("Found our custom service: ${service.uuid.toString().toUpperCase()}");
          for (BluetoothCharacteristic characteristic in service.characteristics) {
            if (characteristic.uuid.toString().toLowerCase() == COMMAND_CHAR_UUID) {
              _commandCharacteristic = characteristic;
              _updateConnectionStatus("Found Command Characteristic: ${characteristic.uuid.toString().toUpperCase()}");
            } else if (characteristic.uuid.toString().toLowerCase() == RESPONSE_CHAR_UUID) {
              _responseCharacteristic = characteristic;
              _updateConnectionStatus("Found Response Characteristic: ${characteristic.uuid.toString().toUpperCase()}");
              // Enable notifications
              if (characteristic.properties.notify) {
                await characteristic.setNotifyValue(true);
                // Escuchar el stream de valores de la característica
                characteristic.lastValueStream.listen((value) { // <--- CORREGIDO: value -> lastValueStream
                  String response = String.fromCharCodes(value);
                  _updateLatestResponse("ESP32: $response");
                  debugPrint("Received from ESP32: $response");
                });
                _updateConnectionStatus("Response notifications enabled.");
              }
            }
          }
          if (_commandCharacteristic != null && _responseCharacteristic != null) {
            _updateConnectionStatus("Ready to send commands.");
          } else {
            _updateConnectionStatus("Required characteristics not found in service.");
          }
          return; // Found our service, no need to check others
        }
      }
      _updateConnectionStatus("Our custom service not found.");
    } catch (e) {
      _updateConnectionStatus("Failed to discover services: $e");
    }
  }

  Future<void> disconnect() async {
    if (_connectedDevice != null) {
      try {
        await _connectedDevice!.disconnect();
        _updateConnectionStatus("Disconnected manually.");
      } catch (e) {
        _updateConnectionStatus("Error disconnecting: $e");
      }
    }
  }

  // Enviar un comando al ESP32
  Future<String> sendCommand(String command) async {
    if (_commandCharacteristic == null) {
      return "Error: Command characteristic not found or not connected.";
    }
    if (!isConnected) {
      return "Error: Not connected to any device.";
    }

    try {
      List<int> bytes = command.codeUnits;
      // write() ahora devuelve un Future<void>, no un Future<String>
      await _commandCharacteristic!.write(bytes, withoutResponse: true);
      debugPrint("Command sent: $command");
      return "Command sent: $command";
    } catch (e) {
      debugPrint("Error sending command: $e");
      return "Error sending command: $e";
    }
  }

  // Leer un registro específico desde el DRV2605L (enviando comando READ_REG)
  Future<String> readRegister(int regAddress) async {
    String command = "READ_REG $regAddress";
    return await sendCommand(command);
  }

  // Escribir un registro específico en el DRV2605L (enviando comando WRITE_REG)
  Future<String> writeRegister(int regAddress, int value) async {
    String command = "WRITE_REG $regAddress $value";
    return await sendCommand(command);
  }

  // Enviar comando de calibración
  Future<String> calibrate() async {
    return await sendCommand("CALIBRATE");
  }

  // Reiniciar el driver DRV2605L (asumiendo comando "RESTART" en ESP32)
  Future<String> restartDriver() async {
    _updateLatestResponse("Sending restart command...");
    return await sendCommand("RESTART");
  }

  // Enviar MOT_ACTIVE
  Future<String> motorSetActive() async {
    return await sendCommand("MOT_ACTIVE");
  }

  // Enviar MOT_OFF
  Future<String> motorSetOff() async {
    return await sendCommand("MOT_OFF");
  }

  // Setear Input Mode
  Future<String> setInputMode(int mode) async {
    return await sendCommand("SET_INPUT_MODE $mode");
  }

  // Método para aplicar los parámetros actuales del modelo a los registros
  Future<void> applyDRV2605Params(DRV2605Params params) async {
    _updateLatestResponse("Applying DRV2605 parameters...");
    // Escribir Registro 0x01 (MODE)
    await writeRegister(0x01, params.getModeRegisterValue());
    await Future.delayed(const Duration(milliseconds: 50));

    // Escribir Registro 0x1A (FEEDBACK_CONTROL)
    await writeRegister(0x1A, params.getFeedbackControlRegisterValue());
    await Future.delayed(const Duration(milliseconds: 50));

    // Escribir Registro 0x1D (CONTROL3)
    await writeRegister(0x1D, params.getControl3RegisterValue());
    await Future.delayed(const Duration(milliseconds: 50));

    // Escribir Registro 0x1E (CONTROL4)
    await writeRegister(0x1E, params.getControl4RegisterValue());
    await Future.delayed(const Duration(milliseconds: 50));

    // Escribir Registro 0x16 (RATED_VOLTAGE)
    await writeRegister(0x16, params.ratedVoltage);
    await Future.delayed(const Duration(milliseconds: 50));

    // Escribir Registro 0x17 (OD_CLAMP)
    await writeRegister(0x17, params.odClamp);
    await Future.delayed(const Duration(milliseconds: 50));

    if (params.otpProgram) {
      _updateLatestResponse("OTP Program requested. Device restart needed.");
    }

    _updateLatestResponse("All parameters applied.");
  }
}