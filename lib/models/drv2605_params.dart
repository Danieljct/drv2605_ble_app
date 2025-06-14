import 'package:flutter/foundation.dart';

class DRV2605Params extends ChangeNotifier {
  // Parámetros basados en el datasheet (Registro 0x01, 0x1A, 0x1D, 0x1E)
  int mode; // Register 0x01, bits 2:0
  bool standby; // Register 0x01, bit 6
  bool devReset; // Register 0x01, bit 7

  int nErmLra; // Register 0x1A, bit 7 (0: ERM, 1: LRA)
  int fbBrakeFactor; // Register 0x1A, bits 6:4
  int loopGain; // Register 0x1A, bits 3:2
  int bemfGain; // Register 0x1A, bits 1:0

  int supplyCompDis; // Register 0x1D, bit 4
  int ermOpenLoop; // Register 0x1D, bit 5 (0: Closed, 1: Open)
  int ngThresh; // Register 0x1D, bits 7:6
  int lraDriveMode; // Register 0x1D, bit 2
  int dataFormatRTP; // Register 0x1D, bit 3
  int nPwmAnalog; // Register 0x1D, bit 1
  int lraOpenLoop; // Register 0x1D, bit 0

  int autoCalTime; // Register 0x1E, bits 5:4
  int zcDetTime; // Register 0x1E, bits 7:6
  bool otpProgram; // Register 0x1E, bit 0 (¡Cuidado, es de un solo uso!)

  // Registros de Voltaje (0x16, 0x17)
  int ratedVoltage; // Register 0x16
  int odClamp; // Register 0x17

  DRV2605Params({
    this.mode = 0x00, // Internal trigger mode
    this.standby = true, // Default: Standby
    this.devReset = false,
    this.nErmLra = 0, // Default: ERM Mode
    this.fbBrakeFactor = 3, // Default: 4x brake factor
    this.loopGain = 1, // Default: Medium gain
    this.bemfGain = 2, // Default: 1.365x (ERM) or 15x (LRA)

    this.supplyCompDis = 0, // Default: Enabled
    this.ermOpenLoop = 1, // Default: Open loop ERM
    this.ngThresh = 2, // Default: 4%
    this.lraDriveMode = 0, // Default: Once per cycle
    this.dataFormatRTP = 0, // Default: Signed
    this.nPwmAnalog = 0, // Default: PWM Input
    this.lraOpenLoop = 0, // Default: Auto-resonance (LRA)

    this.autoCalTime = 2, // Default: 500ms min, 700ms max
    this.zcDetTime = 0, // Default: 100us
    this.otpProgram = false,

    this.ratedVoltage = 0x3E, // Default (approx. 1.3V for ERM)
    this.odClamp = 0x8C, // Default (approx. 2.9V)
  });

  String _interpretedRegisterResult = 'N/A';
  String get interpretedRegisterResult => _interpretedRegisterResult;

  static const Map<int, String> registerNames = {
    0x00: 'STATUS',
    0x01: 'MODE',
    0x02: 'RTP_INPUT',
    0x03: 'LIBRARY_SEL',
    0x04: 'WAV_FRM_SEQ1',
    0x0C: 'GO',
    0x0D: 'ODT',
    0x0E: 'SPT',
    0x0F: 'SNT',
    0x10: 'BRT',
    0x11: 'AUDIO_VIBE_CTRL',
    0x12: 'ATH_MIN_INPUT',
    0x13: 'ATH_MAX_INPUT',
    0x14: 'ATH_MIN_DRIVE',
    0x15: 'ATH_MAX_DRIVE',
    0x16: 'RATED_VOLTAGE',
    0x17: 'OD_CLAMP',
    0x18: 'A_CAL_COMP',
    0x19: 'A_CAL_BEMF',
    0x1A: 'FEEDBACK_CONTROL',
    0x1B: 'CONTROL1',
    0x1C: 'CONTROL2',
    0x1D: 'CONTROL3',
    0x1E: 'CONTROL4',
    0x1F: 'CONTROL5',
    0x20: 'OL_LRA_PERIOD',
    0x21: 'VBAT_VOLTAGE_MONITOR',
    0x22: 'LRA_RESONANCE_PERIOD',
  };

  void interpretRegister(int regAddr, int regValue) {
    String interpretation = '';
    String regName = registerNames[regAddr] ?? 'UNKNOWN_REGISTER';

    switch (regAddr) {
      case 0x00: // STATUS Register 
        int deviceId = (regValue >> 5) & 0x07; // Bits 7:5 
        bool diagResult = ((regValue >> 3) & 0x01) == 1; // Bit 3 
        bool overTemp = ((regValue >> 1) & 0x01) == 1; // Bit 1 
        bool ocDetect = (regValue & 0x01) == 1; // Bit 0 

        interpretation = 'Device ID: $deviceId, ';
        interpretation += 'Diag Result: ${diagResult ? 'Failed' : 'Passed'}, ';
        interpretation += 'Over Temp: $overTemp, ';
        interpretation += 'OC Detect: $ocDetect.';
        break;

      case 0x01: // MODE Register 
        bool devReset = ((regValue >> 7) & 0x01) == 1; // Bit 7 
        bool standby = ((regValue >> 6) & 0x01) == 1; // Bit 6 
        int modeBits = regValue & 0x07; // Bits 2:0 
        String modeDescription = '';
        switch (modeBits) {
          case 0: modeDescription = 'Internal Trigger'; break;
          case 1: modeDescription = 'External Trigger (Edge)'; break;
          case 2: modeDescription = 'External Trigger (Level)'; break;
          case 3: modeDescription = 'PWM/Analog Input'; break;
          case 4: modeDescription = 'Audio-to-Vibe'; break;
          case 5: modeDescription = 'Real-Time Playback (RTP)'; break;
          case 6: modeDescription = 'Diagnostics'; break;
          case 7: modeDescription = 'Auto Calibration'; break;
        }
        interpretation = 'DEV_RESET: $devReset , STANDBY: $standby , MODE: $modeDescription (0x${modeBits.toRadixString(16)}).';
        break;

      case 0x02: // RTP_INPUT 
        interpretation = 'RTP Input Value: $regValue (0x${regValue.toRadixString(16)}).';
        break;

      case 0x03: // LIBRARY_SEL 
        bool hiZ = ((regValue >> 4) & 0x01) == 1; 
        int librarySel = regValue & 0x07; 
        String libDescription = '';
        switch (librarySel) {
          case 0: libDescription = 'Empty'; break; 
          case 1: libDescription = 'TS2200 Library A'; break; 
          case 2: libDescription = 'TS2200 Library B'; break; 
          case 3: libDescription = 'TS2200 Library C'; break; 
          case 4: libDescription = 'TS2200 Library D'; break; 
          case 5: libDescription = 'TS2200 Library E'; break; 
          case 6: libDescription = 'LRA Library'; break; 
          case 7: libDescription = 'TS2200 Library F'; break; 
        }
        interpretation = 'HI_Z: $hiZ , Library Selected: $libDescription (0x${librarySel.toRadixString(16)}).';
        break;
      
      case 0x0C: // GO Register 
        bool goBit = (regValue & 0x01) == 1; // Bit 0 
        interpretation = 'GO Bit: $goBit.';
        break;

      case 0x1A: // FEEDBACK_CONTROL Register 
        bool nErmLra = ((regValue >> 7) & 0x01) == 1; // Bit 7 
        int fbBrakeFactor = (regValue >> 4) & 0x07; // Bits 6:4 
        int loopGain = (regValue >> 2) & 0x03; // Bits 3:2 
        int bemfGain = regValue & 0x03; // Bits 1:0 

        String nErmLraStr = nErmLra ? 'LRA Mode' : 'ERM Mode'; 
        String fbBrakeFactorStr = '';
        switch (fbBrakeFactor) {
          case 0: fbBrakeFactorStr = '1x'; break; 
          case 1: fbBrakeFactorStr = '2x'; break; 
          case 2: fbBrakeFactorStr = '3x'; break; 
          case 3: fbBrakeFactorStr = '4x (Default)'; break; 
          case 4: fbBrakeFactorStr = '6x'; break; 
          case 5: fbBrakeFactorStr = '8x'; break; 
          case 6: fbBrakeFactorStr = '16x'; break; 
          case 7: fbBrakeFactorStr = 'Braking disabled'; break; 
        }
        String loopGainStr = '';
        switch (loopGain) {
          case 0: loopGainStr = 'Low'; break; 
          case 1: loopGainStr = 'Medium (Default)'; break; 
          case 2: loopGainStr = 'High'; break; 
          case 3: loopGainStr = 'Very High'; break; 
        }
        String bemfGainStr = '';
        if (!nErmLra) { // ERM Mode 
          switch (bemfGain) {
            case 0: bemfGainStr = '0.255x'; break; 
            case 1: bemfGainStr = '0.7875x'; break; 
            case 2: bemfGainStr = '1.365x (Default)'; break; 
            case 3: bemfGainStr = '3.0x'; break; 
          }
        } else { // LRA Mode 
          switch (bemfGain) {
            case 0: bemfGainStr = '3.75x'; break; 
            case 1: bemfGainStr = '7.5x'; break; 
            case 2: bemfGainStr = '15x (Default)'; break; 
            case 3: bemfGainStr = '22.5x'; break; 
          }
        }
        interpretation = 'N_ERM_LRA: $nErmLraStr , FB_BRAKE_FACTOR: $fbBrakeFactorStr , LOOP_GAIN: $loopGainStr , BEMF_GAIN: $bemfGainStr.';
        break;

      case 0x1D: // Control3 Register 
        int ngThresh = (regValue >> 6) & 0x03; // Bits 7:6 
        bool ermOpenLoop = ((regValue >> 5) & 0x01) == 1; // Bit 5 
        bool supplyCompDis = ((regValue >> 4) & 0x01) == 1; // Bit 4 
        bool dataFormatRTP = ((regValue >> 3) & 0x01) == 1; // Bit 3 
        bool lraDriveMode = ((regValue >> 2) & 0x01) == 1; // Bit 2 
        bool nPwmAnalog = ((regValue >> 1) & 0x01) == 1; // Bit 1 
        bool lraOpenLoop = (regValue & 0x01) == 1; // Bit 0 

        String ngThreshStr = '';
        switch (ngThresh) {
          case 0: ngThreshStr = 'Disabled'; break; 
          case 1: ngThreshStr = '2%'; break; 
          case 2: ngThreshStr = '4% (Default)'; break; 
          case 3: ngThreshStr = '8%'; break; 
        }
        interpretation = 'NG_THRESH: $ngThreshStr, ERM_OPEN_LOOP: ${ermOpenLoop ? 'Open Loop' : 'Closed Loop'}, ';
        interpretation += 'SUPPLY_COMP_DIS: ${supplyCompDis ? 'Disabled' : 'Enabled'}, DATA_FORMAT_RTP: ${dataFormatRTP ? 'Unsigned' : 'Signed'}, ';
        interpretation += 'LRA_DRIVE_MODE: ${lraDriveMode ? 'Twice per cycle' : 'Once per cycle'}, N_PWM_ANALOG: ${nPwmAnalog ? 'Analog Input' : 'PWM Input'}, ';
        interpretation += 'LRA_OPEN_LOOP: ${lraOpenLoop ? 'Open-loop' : 'Auto-resonance'}.';
        break;

      case 0x1E: // Control4 Register 
        int zcDetTime = (regValue >> 6) & 0x03; // Bits 7:6 
        int autoCalTime = (regValue >> 4) & 0x03; // Bits 5:4 
        bool otpStatus = ((regValue >> 2) & 0x01) == 1; // Bit 2 
        bool otpProgram = (regValue & 0x01) == 1; // Bit 0 

        String zcDetTimeStr = '';
        switch (zcDetTime) {
          case 0: zcDetTimeStr = '100 µs (Default)'; break; 
          case 1: zcDetTimeStr = '200 µs'; break; 
          case 2: zcDetTimeStr = '300 µs'; break; 
          case 3: zcDetTimeStr = '390 µs'; break; 
        }
        String autoCalTimeStr = '';
        switch (autoCalTime) {
          case 0: autoCalTimeStr = '150-350 ms'; break; 
          case 1: autoCalTimeStr = '250-450 ms'; break; 
          case 2: autoCalTimeStr = '500-700 ms (Default)'; break; 
          case 3: autoCalTimeStr = '1000-1200 ms'; break; 
        }
        interpretation = 'ZC_DET_TIME: $zcDetTimeStr , AUTO_CAL_TIME: $autoCalTimeStr, ';
        interpretation += 'OTP Status: ${otpStatus ? 'Programmed' : 'Not Programmed'} , OTP Program Bit: $otpProgram.';
        break;

      case 0x16: // RATED_VOLTAGE 
        interpretation = 'Rated Voltage: $regValue (0x${regValue.toRadixString(16)}).';
        break;

      case 0x17: // OD_CLAMP 
        interpretation = 'Overdrive Clamp Voltage: $regValue (0x${regValue.toRadixString(16)}).';
        break;

      case 0x21: // VBAT_VOLTAGE_MONITOR 
        // VDD(V) = VBAT[7:0] * 5.6V / 255 
        double vbatVoltage = (regValue * 5.6) / 255.0; 
        interpretation = 'Vbat Voltage Monitor: $regValue (0x${regValue.toRadixString(16)}) -> ${vbatVoltage.toStringAsFixed(2)} V.';
        break;

      case 0x22: // LRA_RESONANCE_PERIOD 
        // LRA period (us) = LRA_Period [7:0] x 98.46 µs 
        double lraPeriodUs = regValue * 98.46; 
        interpretation = 'LRA Resonance Period: $regValue (0x${regValue.toRadixString(16)}) -> ${lraPeriodUs.toStringAsFixed(2)} µs.';
        break;

      default:
        interpretation = 'Value: $regValue (0x${regValue.toRadixString(16)}). No specific interpretation available.';
        break;
    }

    _interpretedRegisterResult = 'Register 0x${regAddr.toRadixString(16)} ($regName):\n$interpretation';
    notifyListeners();
  }


  // Método para actualizar un parámetro y notificar a los listeners
  void updateParam(String paramName, dynamic newValue) {
    switch (paramName) {
      case 'mode':
        mode = newValue as int;
        break;
      case 'standby':
        standby = newValue as bool;
        break;
      case 'devReset':
        devReset = newValue as bool;
        break;
      case 'nErmLra':
        nErmLra = newValue as int;
        break;
      case 'fbBrakeFactor':
        fbBrakeFactor = newValue as int;
        break;
      case 'loopGain':
        loopGain = newValue as int;
        break;
      case 'bemfGain':
        bemfGain = newValue as int;
        break;
      case 'supplyCompDis':
        supplyCompDis = newValue as int;
        break;
      case 'ermOpenLoop':
        ermOpenLoop = newValue as int;
        break;
      case 'ngThresh':
        ngThresh = newValue as int;
        break;
      case 'lraDriveMode':
        lraDriveMode = newValue as int;
        break;
      case 'dataFormatRTP':
        dataFormatRTP = newValue as int;
        break;
      case 'nPwmAnalog':
        nPwmAnalog = newValue as int;
        break;
      case 'lraOpenLoop':
        lraOpenLoop = newValue as int;
        break;
      case 'autoCalTime':
        autoCalTime = newValue as int;
        break;
      case 'zcDetTime':
        zcDetTime = newValue as int;
        break;
      case 'otpProgram':
        otpProgram = newValue as bool;
        break;
      case 'ratedVoltage':
        ratedVoltage = newValue as int;
        break;
      case 'odClamp':
        odClamp = newValue as int;
        break;
      default:
        debugPrint('Unknown parameter: $paramName');
    }
    notifyListeners();
  }

  // Método para generar el valor del Registro 0x01 (MODE)
  int getModeRegisterValue() {
    int value = 0;
    if (standby) value |= (1 << 6); // Set STANDBY bit 
    if (devReset) value |= (1 << 7); // Set DEV_RESET bit 
    value |= (mode & 0x07); // Set MODE[2:0] 
    return value;
  }

  // Método para generar el valor del Registro 0x1A (FEEDBACK_CONTROL)
  int getFeedbackControlRegisterValue() {
    int value = 0;
    if (nErmLra == 1) value |= (1 << 7); // Set N_ERM_LRA bit for LRA mode 
    value |= ((fbBrakeFactor & 0x07) << 4); // Set FB_BRAKE_FACTOR[2:0] 
    value |= ((loopGain & 0x03) << 2); // Set LOOP_GAIN[1:0] 
    value |= (bemfGain & 0x03); // Set BEMF_GAIN[1:0] 
    return value;
  }

  // Método para generar el valor del Registro 0x1D (CONTROL3)
  int getControl3RegisterValue() {
    int value = 0;
    value |= ((ngThresh & 0x03) << 6); // Set NG_THRESH[1:0] 
    if (ermOpenLoop == 1) value |= (1 << 5); // Set ERM_OPEN_LOOP bit 
    if (supplyCompDis == 1) value |= (1 << 4); // Set SUPPLY_COMP_DIS bit 
    if (dataFormatRTP == 1) value |= (1 << 3); // Set DATA_FORMAT_RTP bit 
    if (lraDriveMode == 1) value |= (1 << 2); // Set LRA_DRIVE_MODE bit 
    if (nPwmAnalog == 1) value |= (1 << 1); // Set N_PWM_ANALOG bit 
    if (lraOpenLoop == 1) value |= (1 << 0); // Set LRA_OPEN_LOOP bit 
    return value;
  }

  // Método para generar el valor del Registro 0x1E (CONTROL4)
  int getControl4RegisterValue() {
    int value = 0;
    value |= ((zcDetTime & 0x03) << 6); // Set ZC_DET_TIME[1:0] 
    value |= ((autoCalTime & 0x03) << 4); // Set AUTO_CAL_TIME[1:0] 
    if (otpProgram) value |= (1 << 0); // Set OTP_PROGRAM bit 
    // OTP_STATUS (bit 2) es de solo lectura, no se setea aquí.
    return value;
  }
}