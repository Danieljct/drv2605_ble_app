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