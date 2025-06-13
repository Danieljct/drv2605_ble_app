// UUIDs deben coincidir con ble.h en la ESP32
const String SERVICE_UUID = "00aa";
const String COMMAND_CHAR_UUID = "aa01";
const String RESPONSE_CHAR_UUID = "aa02";

// Nombre del dispositivo BLE que el ESP32 anuncia
const String ESP32_DEVICE_NAME = "ESP32_DRV2605"; // Asegúrate de que coincida EXACTAMENTE con tu ESP32