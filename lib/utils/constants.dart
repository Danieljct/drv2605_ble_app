// UUIDs deben coincidir con ble.h en la ESP32
const String SERVICE_UUID = "000000aa-0000-1000-8000-00805f9b34fb";
const String COMMAND_CHAR_UUID = "0000aa01-0000-1000-8000-00805f9b34fb";
const String RESPONSE_CHAR_UUID = "0000aa02-0000-1000-8000-00805f9b34fb";

// Nombre del dispositivo BLE que el ESP32 anuncia
const String ESP32_DEVICE_NAME = "ESP32_DRV2605"; // Asegúrate de que coincida EXACTAMENTE con tu ESP32