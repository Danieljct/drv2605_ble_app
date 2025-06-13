import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ble_service.dart';
import '../models/drv2605_params.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DRV2605L BLE Control'),
      ),
      body: Consumer2<BleService, DRV2605Params>(
        builder: (context, bleService, drvParams, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sección de Conexión BLE
                Card(
                  margin: const EdgeInsets.only(bottom: 20),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Connection Status: ${bleService.connectionStatus}',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: bleService.isConnected
                                    ? null // Deshabilitar si ya está conectado
                                    : () => bleService.scanAndConnect(),
                                child: const Text('Scan & Connect'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: bleService.isConnected
                                    ? () => bleService.disconnect()
                                    : null,
                                child: const Text('Disconnect'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text('Latest Response from ESP32: ${bleService.latestResponse}',
                            style: const TextStyle(fontStyle: FontStyle.italic)),
                      ],
                    ),
                  ),
                ),

                // Controles del DRV2605L
                _buildDRV2605Controls(context, bleService, drvParams),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: bleService.isConnected
                      ? () => drvParams.devReset = true // Actualiza el modelo para que el botón de aplicar lo use
                      : null,
                  child: const Text('Apply All Parameters & Reset (if Dev_Reset)'),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: bleService.isConnected
                      ? () => bleService.calibrate()
                      : null,
                  child: const Text('Run Auto-Calibration'),
                ),
                const SizedBox(height: 10),
                 ElevatedButton(
                  onPressed: bleService.isConnected
                      ? () => bleService.motorSetActive()
                      : null,
                  child: const Text('Set Motor Active Mode'),
                ),
                const SizedBox(height: 10),
                 ElevatedButton(
                  onPressed: bleService.isConnected
                      ? () => bleService.motorSetOff()
                      : null,
                  child: const Text('Set Motor Off Mode'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDRV2605Controls(BuildContext context, BleService bleService, DRV2605Params drvParams) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('DRV2605L Parameters:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),

        // --- Registro 0x01: MODE Register ---
        _buildRegisterSection(
          title: 'Register 0x01: MODE, STANDBY, DEV_RESET',
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: drvParams.mode,
                    decoration: const InputDecoration(labelText: 'MODE[2:0] (Haptic Mode)'),
                    items: const [
                      DropdownMenuItem(value: 0, child: Text('0: Internal Trigger')), // 
                      DropdownMenuItem(value: 1, child: Text('1: External Trigger (Edge)')), // 
                      DropdownMenuItem(value: 2, child: Text('2: External Trigger (Level)')), // 
                      DropdownMenuItem(value: 3, child: Text('3: PWM/Analog Input')), // 
                      DropdownMenuItem(value: 4, child: Text('4: Audio-to-Vibe')), // 
                      DropdownMenuItem(value: 5, child: Text('5: Real-Time Playback (RTP)')), // 
                      DropdownMenuItem(value: 6, child: Text('6: Diagnostics')), // 
                      DropdownMenuItem(value: 7, child: Text('7: Auto Calibration')), // 
                    ],
                    onChanged: (value) {
                      if (value != null) drvParams.updateParam('mode', value);
                    },
                  ),
                ),
              ],
            ),
            CheckboxListTile(
              title: const Text('STANDBY (Bit 6)'),
              value: drvParams.standby,
              onChanged: (value) {
                if (value != null) drvParams.updateParam('standby', value);
              },
            ),
            CheckboxListTile(
              title: const Text('DEV_RESET (Bit 7 - Auto-clears)'),
              value: drvParams.devReset,
              onChanged: (value) {
                if (value != null) drvParams.updateParam('devReset', value);
              },
            ),
            ElevatedButton(
              onPressed: bleService.isConnected
                  ? () => bleService.writeRegister(0x01, drvParams.getModeRegisterValue())
                  : null,
              child: const Text('Apply Mode Register (0x01)'),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // --- Registro 0x1A: FEEDBACK_CONTROL ---
        _buildRegisterSection(
          title: 'Register 0x1A: FEEDBACK_CONTROL',
          children: [
            DropdownButtonFormField<int>(
              value: drvParams.nErmLra,
              decoration: const InputDecoration(labelText: 'N_ERM_LRA (Bit 7)'),
              items: const [
                DropdownMenuItem(value: 0, child: Text('0: ERM Mode')), // 
                DropdownMenuItem(value: 1, child: Text('1: LRA Mode')), // 
              ],
              onChanged: (value) {
                if (value != null) drvParams.updateParam('nErmLra', value);
              },
            ),
            DropdownButtonFormField<int>(
              value: drvParams.fbBrakeFactor,
              decoration: const InputDecoration(labelText: 'FB_BRAKE_FACTOR[2:0] (Bits 6:4)'),
              items: const [
                DropdownMenuItem(value: 0, child: Text('0: 1x')), // 
                DropdownMenuItem(value: 1, child: Text('1: 2x')), // 
                DropdownMenuItem(value: 2, child: Text('2: 3x')), // 
                DropdownMenuItem(value: 3, child: Text('3: 4x (Default)')), // 
                DropdownMenuItem(value: 4, child: Text('4: 6x')), // 
                DropdownMenuItem(value: 5, child: Text('5: 8x')), // 
                DropdownMenuItem(value: 6, child: Text('6: 16x')), // 
                DropdownMenuItem(value: 7, child: Text('7: Braking disabled')), // 
              ],
              onChanged: (value) {
                if (value != null) drvParams.updateParam('fbBrakeFactor', value);
              },
            ),
            DropdownButtonFormField<int>(
              value: drvParams.loopGain,
              decoration: const InputDecoration(labelText: 'LOOP_GAIN[1:0] (Bits 3:2)'),
              items: const [
                DropdownMenuItem(value: 0, child: Text('0: Low')), // 
                DropdownMenuItem(value: 1, child: Text('1: Medium (Default)')), // 
                DropdownMenuItem(value: 2, child: Text('2: High')), // 
                DropdownMenuItem(value: 3, child: Text('3: Very High')), // 
              ],
              onChanged: (value) {
                if (value != null) drvParams.updateParam('loopGain', value);
              },
            ),
            DropdownButtonFormField<int>(
              value: drvParams.bemfGain,
              decoration: const InputDecoration(labelText: 'BEMF_GAIN[1:0] (Bits 1:0)'),
              items: const [
                DropdownMenuItem(value: 0, child: Text('0: ERM:0.255x/LRA:3.75x')), // 
                DropdownMenuItem(value: 1, child: Text('1: ERM:0.7875x/LRA:7.5x')), // 
                DropdownMenuItem(value: 2, child: Text('2: ERM:1.365x/LRA:15x (Default)')), // 
                DropdownMenuItem(value: 3, child: Text('3: ERM:3.0x/LRA:22.5x')), // 
              ],
              onChanged: (value) {
                if (value != null) drvParams.updateParam('bemfGain', value);
              },
            ),
            ElevatedButton(
              onPressed: bleService.isConnected
                  ? () => bleService.writeRegister(0x1A, drvParams.getFeedbackControlRegisterValue())
                  : null,
              child: const Text('Apply Feedback Control Register (0x1A)'),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // --- Registro 0x1D: Control3 ---
        _buildRegisterSection(
          title: 'Register 0x1D: Control3',
          children: [
            DropdownButtonFormField<int>(
              value: drvParams.ngThresh,
              decoration: const InputDecoration(labelText: 'NG_THRESH[1:0] (Bits 7:6)'),
              items: const [
                DropdownMenuItem(value: 0, child: Text('0: Disabled')), // 
                DropdownMenuItem(value: 1, child: Text('1: 2%')), // 
                DropdownMenuItem(value: 2, child: Text('2: 4% (Default)')), // 
                DropdownMenuItem(value: 3, child: Text('3: 8%')), // 
              ],
              onChanged: (value) {
                if (value != null) drvParams.updateParam('ngThresh', value);
              },
            ),
            DropdownButtonFormField<int>(
              value: drvParams.ermOpenLoop,
              decoration: const InputDecoration(labelText: 'ERM_OPEN_LOOP (Bit 5)'),
              items: const [
                DropdownMenuItem(value: 0, child: Text('0: Closed Loop')), // 
                DropdownMenuItem(value: 1, child: Text('1: Open Loop (Default)')), // 
              ],
              onChanged: (value) {
                if (value != null) drvParams.updateParam('ermOpenLoop', value);
              },
            ),
            DropdownButtonFormField<int>(
              value: drvParams.supplyCompDis,
              decoration: const InputDecoration(labelText: 'SUPPLY_COMP_DIS (Bit 4)'),
              items: const [
                DropdownMenuItem(value: 0, child: Text('0: Enabled (Default)')), // 
                DropdownMenuItem(value: 1, child: Text('1: Disabled')), // 
              ],
              onChanged: (value) {
                if (value != null) drvParams.updateParam('supplyCompDis', value);
              },
            ),
            DropdownButtonFormField<int>(
              value: drvParams.dataFormatRTP,
              decoration: const InputDecoration(labelText: 'DATA_FORMAT_RTP (Bit 3)'),
              items: const [
                DropdownMenuItem(value: 0, child: Text('0: Signed (Default)')), // 
                DropdownMenuItem(value: 1, child: Text('1: Unsigned')), // 
              ],
              onChanged: (value) {
                if (value != null) drvParams.updateParam('dataFormatRTP', value);
              },
            ),
            DropdownButtonFormField<int>(
              value: drvParams.lraDriveMode,
              decoration: const InputDecoration(labelText: 'LRA_DRIVE_MODE (Bit 2)'),
              items: const [
                DropdownMenuItem(value: 0, child: Text('0: Once per cycle (Default)')), // 
                DropdownMenuItem(value: 1, child: Text('1: Twice per cycle')), // 
              ],
              onChanged: (value) {
                if (value != null) drvParams.updateParam('lraDriveMode', value);
              },
            ),
            DropdownButtonFormField<int>(
              value: drvParams.nPwmAnalog,
              decoration: const InputDecoration(labelText: 'N_PWM_ANALOG (Bit 1)'),
              items: const [
                DropdownMenuItem(value: 0, child: Text('0: PWM Input (Default)')), // 
                DropdownMenuItem(value: 1, child: Text('1: Analog Input')), // 
              ],
              onChanged: (value) {
                if (value != null) drvParams.updateParam('nPwmAnalog', value);
              },
            ),
            DropdownButtonFormField<int>(
              value: drvParams.lraOpenLoop,
              decoration: const InputDecoration(labelText: 'LRA_OPEN_LOOP (Bit 0)'),
              items: const [
                DropdownMenuItem(value: 0, child: Text('0: Auto-resonance (Default)')), // 
                DropdownMenuItem(value: 1, child: Text('1: LRA open-loop mode')), // 
              ],
              onChanged: (value) {
                if (value != null) drvParams.updateParam('lraOpenLoop', value);
              },
            ),
            ElevatedButton(
              onPressed: bleService.isConnected
                  ? () => bleService.writeRegister(0x1D, drvParams.getControl3RegisterValue())
                  : null,
              child: const Text('Apply Control3 Register (0x1D)'),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // --- Registro 0x1E: Control4 ---
        _buildRegisterSection(
          title: 'Register 0x1E: Control4',
          children: [
            DropdownButtonFormField<int>(
              value: drvParams.zcDetTime,
              decoration: const InputDecoration(labelText: 'ZC_DET_TIME[1:0] (Bits 7:6)'),
              items: const [
                DropdownMenuItem(value: 0, child: Text('0: 100 µs (Default)')), // 
                DropdownMenuItem(value: 1, child: Text('1: 200 µs')), // 
                DropdownMenuItem(value: 2, child: Text('2: 300 µs')), // 
                DropdownMenuItem(value: 3, child: Text('3: 390 µs')), // 
              ],
              onChanged: (value) {
                if (value != null) drvParams.updateParam('zcDetTime', value);
              },
            ),
            DropdownButtonFormField<int>(
              value: drvParams.autoCalTime,
              decoration: const InputDecoration(labelText: 'AUTO_CAL_TIME[1:0] (Bits 5:4)'),
              items: const [
                DropdownMenuItem(value: 0, child: Text('0: 150-350 ms')), // 
                DropdownMenuItem(value: 1, child: Text('1: 250-450 ms')), // 
                DropdownMenuItem(value: 2, child: Text('2: 500-700 ms (Default)')), // 
                DropdownMenuItem(value: 3, child: Text('3: 1000-1200 ms')), // 
              ],
              onChanged: (value) {
                if (value != null) drvParams.updateParam('autoCalTime', value);
              },
            ),
            CheckboxListTile(
              title: const Text('OTP_PROGRAM (Bit 0 - One-Time Write!)'),
              subtitle: const Text('Sets OTP memory for 0x16-0x1A. Can only be set once.'), // 
              value: drvParams.otpProgram,
              onChanged: (value) {
                if (value != null) drvParams.updateParam('otpProgram', value);
              },
            ),
            ElevatedButton(
              onPressed: bleService.isConnected
                  ? () => bleService.writeRegister(0x1E, drvParams.getControl4RegisterValue())
                  : null,
              child: const Text('Apply Control4 Register (0x1E)'),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // --- Registro 0x16: RATED_VOLTAGE ---
        _buildRegisterSection(
          title: 'Register 0x16: RATED_VOLTAGE',
          children: [
            TextFormField(
              initialValue: drvParams.ratedVoltage.toString(),
              decoration: const InputDecoration(labelText: 'Rated Voltage (0-255)'),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                drvParams.updateParam('ratedVoltage', int.tryParse(value) ?? 0);
              },
            ),
            ElevatedButton(
              onPressed: bleService.isConnected
                  ? () => bleService.writeRegister(0x16, drvParams.ratedVoltage)
                  : null,
              child: const Text('Apply Rated Voltage (0x16)'),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // --- Registro 0x17: OD_CLAMP ---
        _buildRegisterSection(
          title: 'Register 0x17: OD_CLAMP',
          children: [
            TextFormField(
              initialValue: drvParams.odClamp.toString(),
              decoration: const InputDecoration(labelText: 'Overdrive Clamp Voltage (0-255)'),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                drvParams.updateParam('odClamp', int.tryParse(value) ?? 0);
              },
            ),
            ElevatedButton(
              onPressed: bleService.isConnected
                  ? () => bleService.writeRegister(0x17, drvParams.odClamp)
                  : null,
              child: const Text('Apply OD Clamp (0x17)'),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // --- Lectura de Registros ---
        _buildRegisterSection(
          title: 'Read Specific Register (Hex Address)',
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: TextEditingController(),
                    decoration: const InputDecoration(labelText: 'Register Address (e.g., 0x00 for Status)'),
                    onSubmitted: (value) {
                      final int? regAddr = int.tryParse(value.startsWith('0x') ? value.substring(2) : value, radix: 16);
                      if (regAddr != null && bleService.isConnected) {
                        bleService.readRegister(regAddr);
                      } else {
                        // Anteriormente: bleService.updateConnectionStatus("Invalid address or not connected.");
                        // Ahora, podemos mostrar un SnackBar o simplemente logear.
                        // Para que el usuario lo vea, un SnackBar es buena idea.
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Invalid register address or not connected to a device.'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRegisterSection({required String title, required List<Widget> children}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }
}