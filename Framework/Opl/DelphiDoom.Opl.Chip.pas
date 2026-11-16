{******************************************************************************}
{                                                                              }
{  DelphiDoom: OPL2 (YM3812) library - the chip                                 }
{                                                                              }
{  Port of fmopl.c (MAME 0.37a fork for OpenXcom, LGPL 2.1 or later)            }
{  See DelphiDoom.Opl.Types for the copyright notice                            }
{                                                                              }
{  The arithmetic is the one of the C with 32 bit integers: the unsigned        }
{  operations wrap around (the unit turns off the overflow checks) and the      }
{  right shifts of negative values are arithmetic (Sar), as MSVC and g++ do     }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Opl.Chip;

interface

uses
  System.SysUtils, System.Math, DelphiDoom.Opl.Types, DelphiDoom.Opl.Intf;

type
  /// <summary>
  ///   FM_OPL with its functions (OPLCreate, OPLResetChip, OPLWrite, OPLRead, OPLTimerOver, YM3812UpdateOne). The names
  ///   of the C are kept in the comments of the private methods
  /// </summary>
  TOplChip = class(TInterfacedObject, IOplChip)
  strict private
    FTables: IOplTables;
    FNoise: IOplNoiseSource;
    FTotalLevel: TArray<Integer>;
    FSinOffsets: TArray<Integer>;
    FEnvelopeCurve: TArray<Integer>;
    FAmsTable: TArray<Integer>;
    FVibTable: TArray<Integer>;
    FChipType: TOplChipType;
    FClock: Integer;
    FRate: Integer;
    FFreqBase: Double;
    FTimerBase: Double;
    FAddress: Byte;
    FStatus: Byte;
    FStatusMask: Byte;
    FMode: Cardinal;
    FTimers: array[0..1] of Integer;
    FTimerEnabled: array[0..1] of Byte;
    FChannels: array[0..OPL_MAX_CHANNELS - 1] of TOplChannel;
    FRhythm: Byte;
    FAttackTable: array[0..OPL_RATE_TABLE_SIZE - 1] of Integer;
    FDecayTable: array[0..OPL_RATE_TABLE_SIZE - 1] of Integer;
    FFrequencyTable: array[0..1023] of Cardinal;
    FAmsBase: Integer;
    FVibBase: Integer;
    FAmsCounter: Cardinal;
    FAmsIncrement: Integer;
    FVibCounter: Cardinal;
    FVibIncrement: Integer;
    FWaveSelect: Byte;
    FListener: IOplChipListener;
    FTimerParam: Integer;
    FIrqParam: Integer;
    FUpdateParam: Integer;
    FLegacyLfoCache: Boolean;
    FCacheValid: Boolean;
    // the statics of the C that live only while the samples are calculated
    FCachedAmsBase: Integer;
    FCachedVibBase: Integer;
    FCachedAmsIncrement: Integer;
    FCachedVibIncrement: Integer;
    FOutput: Integer;
    FAms: Integer;
    FVib: Integer;
    FFeedback2: Integer;
    class function Sar(AValue: Integer; ACount: Integer): Integer; static; inline;
    class function TruncToInteger(AValue: Single): Integer; static;
    procedure StatusSet(AFlag: Integer);
    procedure StatusReset(AFlag: Integer);
    procedure StatusMaskSet(AFlag: Integer);
    procedure KeyOn(var ASlot: TOplSlot);
    procedure KeyOff(var ASlot: TOplSlot);
    function CalcSlot(var ASlot: TOplSlot): Integer;
    procedure SetAlgorithm(var AChannel: TOplChannel);
    procedure CalcFcSlot(var AChannel: TOplChannel; ASlotIndex: Integer);
    function RateOf(ABase: Integer; AIndex: Integer; const ATable: array of Integer): Integer;
    procedure SetMul(ASlot: Integer; AValue: Integer);
    procedure SetKslTl(ASlot: Integer; AValue: Integer);
    procedure SetArDr(ASlot: Integer; AValue: Integer);
    procedure SetSlRr(ASlot: Integer; AValue: Integer);
    function OpOut(const ASlot: TOplSlot; AEnvelope: Integer; AConnection: Integer): Integer; inline;
    procedure AdvancePhase(var ASlot: TOplSlot);
    procedure CalcChannel(var AChannel: TOplChannel);
    procedure CalcRhythm;
    procedure InitTimeTables(AAttackRate, ADecayRate: Integer);
    procedure Initialize;
    procedure WriteReg(ARegister: Integer; AValue: Integer);
    procedure SwitchTo;
  public
    /// <param name="ATables">The shared tables</param>
    /// <param name="ANoise">The source of the white noise of the rhythm section</param>
    /// <param name="AClock">The master clock in Hz (3579545 for the AdLib)</param>
    /// <param name="ARate">The sampling rate in Hz</param>
    constructor Create(const ATables: IOplTables; const ANoise: IOplNoiseSource; AChipType: TOplChipType;
      AClock, ARate: Integer);
    destructor Destroy; override;
    procedure Reset;
    function Write(APort: Integer; AValue: Integer): Integer;
    procedure WriteRegister(ARegister: Byte; AValue: Byte);
    function Read(APort: Integer): Byte;
    function TimerOver(ATimer: Integer): Integer;
    procedure GenerateSamples(const ABuffer: TArray<SmallInt>; ACount: Integer); overload;
    procedure GenerateSamples(const ABuffer: TArray<SmallInt>; AOffset, ALength, AStripe: Integer;
      AVolume: Single); overload;
    procedure SetListener(const AListener: IOplChipListener; ATimerChannelOffset, AIrqParam, AUpdateParam: Integer);
    function GetLegacyLfoCache: Boolean;
    procedure SetLegacyLfoCache(AValue: Boolean);
    /// <summary>AR_TABLE[AIndex] of the chip (0..74; 75 is the 0 the C reads past it)</summary>
    function AttackRate(AIndex: Integer): Integer;
    /// <summary>DR_TABLE[AIndex] of the chip</summary>
    function DecayRate(AIndex: Integer): Integer;
    /// <summary>FN_TABLE[AIndex] of the chip: the frequency step of a fnumber (0..1023)</summary>
    function FrequencyStep(AIndex: Integer): Cardinal;
    /// <summary>amsIncr of the chip</summary>
    property AmsIncrement: Integer read FAmsIncrement;
    /// <summary>vibIncr of the chip</summary>
    property VibIncrement: Integer read FVibIncrement;
  end;

implementation

{$Q-}
{$R-}
// SetPrecisionMode limits the x87 to 53 bits on Win32 (the C is compiled for SSE); on Win64 it has no effect
{$WARN SYMBOL_PLATFORM OFF}

const
  SLOT_ARRAY: array[0..31] of Integer = (
    0, 2, 4, 1, 3, 5, -1, -1,
    6, 8, 10, 7, 9, 11, -1, -1,
    12, 14, 16, 13, 15, 17, -1, -1,
    18, 20, 22, 19, 21, 23, -1, -1);

  /// <summary>
  ///   KSL_TABLE in steps of 0.375 dB (the C divides the 3 dB per octave table by EG_STEP / 2, 0.375 dB is 32 steps)
  /// </summary>
  KSL_STEPS: array[0..127] of Byte = (
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 3, 4, 5, 6, 7, 8,
    0, 0, 0, 0, 0, 3, 5, 7, 8, 10, 11, 12, 13, 14, 15, 16,
    0, 0, 0, 5, 8, 11, 13, 15, 16, 18, 19, 20, 21, 22, 23, 24,
    0, 0, 8, 13, 16, 19, 21, 23, 24, 26, 27, 28, 29, 30, 31, 32,
    0, 8, 16, 21, 24, 27, 29, 31, 32, 34, 35, 36, 37, 38, 39, 40,
    0, 16, 24, 29, 32, 35, 37, 39, 40, 42, 43, 44, 45, 46, 47, 48,
    0, 24, 32, 37, 40, 43, 45, 47, 48, 50, 51, 52, 53, 54, 55, 56);

  /// <summary>MUL_TABLE with ML = 2</summary>
  MUL_TABLE: array[0..15] of Cardinal = (1, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 20, 24, 24, 30, 30);

  /// <summary>SC(db) of the sustain level table: db * 8388608 + EG_DST (the last entry is 31 dB)</summary>
  SL_DECIBELS: array[0..15] of Integer = (0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 31);

  /// <summary>(double)(EG_ENT << ENV_BITS)</summary>
  EG_SCALE: Double = 268435456.0;
  WHITE_NOISE_STEPS = 256; // WHITE_NOISE_db / EG_STEP
  CLOCK_DIVIDER = 72;

{ TOplChip }

constructor TOplChip.Create(const ATables: IOplTables; const ANoise: IOplNoiseSource; AChipType: TOplChipType;
  AClock, ARate: Integer);
var
  LChannel: Integer;
  LSlot: Integer;
  LPrecision: TFPUPrecisionMode;
begin
  inherited Create;
  if not Assigned(ATables) then
    raise EOplException.Create('The tables of the chip are missing');
  if not Assigned(ANoise) then
    raise EOplException.Create('The noise source of the chip is missing');
  FTables := ATables;
  FNoise := ANoise;
  FTotalLevel := ATables.TotalLevel;
  FSinOffsets := ATables.SinOffsets;
  FEnvelopeCurve := ATables.EnvelopeCurve;
  FAmsTable := ATables.AmsTable;
  FVibTable := ATables.VibTable;
  FChipType := AChipType;
  FClock := AClock;
  FRate := ARate;
  FLegacyLfoCache := True;
  for LChannel := 0 to OPL_MAX_CHANNELS - 1 do
    for LSlot := 0 to 1 do
    begin
      FChannels[LChannel].Slots[LSlot].ArBase := -1;
      FChannels[LChannel].Slots[LSlot].DrBase := -1;
    end;
  // init global tables (the C is compiled for SSE: every operation is rounded to double)
  LPrecision := SetPrecisionMode(pmDouble);
  try
    Initialize;
  finally
    SetPrecisionMode(LPrecision);
  end;
  Reset;
end;

destructor TOplChip.Destroy;
begin
  // a chip that is gone must not stay the "current chip" of the tables (the C resets cur_chip with the last chip)
  if Assigned(FTables) and (FTables.ActiveChip = NativeInt(Self)) then
    FTables.ActiveChip := 0;
  inherited Destroy;
end;

class function TOplChip.Sar(AValue: Integer; ACount: Integer): Integer;
begin
  if AValue >= 0 then
    Result := AValue shr ACount
  else
    Result := not ((not AValue) shr ACount);
end;

class function TOplChip.TruncToInteger(AValue: Single): Integer;
begin
  // the conversion of the CPU gives the "integer indefinite" value for what does not fit
  if (AValue >= 2147483648.0) or (AValue < -2147483648.0) or IsNan(AValue) then
    Result := Low(Integer)
  else
    Result := Trunc(AValue);
end;

procedure TOplChip.StatusSet(AFlag: Integer);
begin
  // OPL_STATUS_SET: set status flag
  FStatus := FStatus or Byte(AFlag);
  if (FStatus and $80) = 0 then
    if (FStatus and FStatusMask) <> 0 then
    begin
      // IRQ on
      FStatus := FStatus or $80;
      if Assigned(FListener) then
        FListener.IrqChanged(FIrqParam, 1);
    end;
end;

procedure TOplChip.StatusReset(AFlag: Integer);
begin
  // OPL_STATUS_RESET: reset status flag
  FStatus := FStatus and not Byte(AFlag);
  if (FStatus and $80) <> 0 then
    if (FStatus and FStatusMask) = 0 then
    begin
      FStatus := FStatus and $7F;
      if Assigned(FListener) then
        FListener.IrqChanged(FIrqParam, 0);
    end;
end;

procedure TOplChip.StatusMaskSet(AFlag: Integer);
begin
  // OPL_STATUSMASK_SET
  FStatusMask := Byte(AFlag);
  StatusSet(0);
  StatusReset(0);
end;

procedure TOplChip.KeyOn(var ASlot: TOplSlot);
begin
  // OPL_KEYON: sin wave restart, set attack
  ASlot.Cnt := 0;
  ASlot.evm := OPL_ENV_ATTACK;
  ASlot.evs := ASlot.evsa;
  ASlot.evc := OPL_EG_AST;
  ASlot.eve := OPL_EG_AED;
end;

procedure TOplChip.KeyOff(var ASlot: TOplSlot);
begin
  // OPL_KEYOFF
  if ASlot.evm > OPL_ENV_RELEASE then
  begin
    // set envelope counter from envelope output
    ASlot.evm := OPL_ENV_RELEASE;
    if (ASlot.evc and OPL_EG_DST) = 0 then
      ASlot.evc := (FEnvelopeCurve[ASlot.evc shr OPL_ENV_BITS] shl OPL_ENV_BITS) + OPL_EG_DST;
    ASlot.eve := OPL_EG_DED;
    ASlot.evs := ASlot.evsr;
  end;
end;

function TOplChip.CalcSlot(var ASlot: TOplSlot): Integer;
begin
  // OPL_CALC_SLOT: calculate envelope generator
  Inc(ASlot.evc, ASlot.evs);
  if ASlot.evc >= ASlot.eve then
    case ASlot.evm of
      OPL_ENV_ATTACK:
        begin
          // ATTACK -> DECAY1: next DR
          ASlot.evm := OPL_ENV_DECAY;
          ASlot.evc := OPL_EG_DST;
          ASlot.eve := ASlot.SL;
          ASlot.evs := ASlot.evsd;
        end;
      OPL_ENV_DECAY:
        begin
          // DECAY -> SL or RR
          ASlot.evc := ASlot.SL;
          ASlot.eve := OPL_EG_DED;
          if ASlot.EgTyp <> 0 then
            ASlot.evs := 0
          else
          begin
            ASlot.evm := OPL_ENV_RELEASE;
            ASlot.evs := ASlot.evsr;
          end;
        end;
      OPL_ENV_RELEASE:
        begin
          // RR -> OFF
          ASlot.evc := OPL_EG_OFF;
          ASlot.eve := OPL_EG_OFF + 1;
          ASlot.evs := 0;
        end;
    end;
  // calculate envelope
  Result := ASlot.TLL + FEnvelopeCurve[ASlot.evc shr OPL_ENV_BITS];
  if ASlot.ams <> 0 then
    Inc(Result, FAms);
end;

procedure TOplChip.SetAlgorithm(var AChannel: TOplChannel);
begin
  // set_algorythm: connect1 is the carrier output or the feedback of operator 2, connect2 is the carrier output
  AChannel.Connect1ToCarrier := AChannel.CON <> 0;
end;

function TOplChip.RateOf(ABase: Integer; AIndex: Integer; const ATable: array of Integer): Integer;
begin
  // RATE_0 is all zero
  if ABase < 0 then
    Result := 0
  else
    Result := ATable[ABase + AIndex];
end;

procedure TOplChip.CalcFcSlot(var AChannel: TOplChannel; ASlotIndex: Integer);
var
  LKsr: Integer;
begin
  // CALC_FCSLOT: frequency counter for operator update
  with AChannel.Slots[ASlotIndex] do
  begin
    // frequency step counter
    Incr := AChannel.fc * mul;
    LKsr := AChannel.kcode shr KsrShift;
    if ksr <> LKsr then
    begin
      ksr := Byte(LKsr);
      // attack, decay rate recalculation
      evsa := RateOf(ArBase, LKsr, FAttackTable);
      evsd := RateOf(DrBase, LKsr, FDecayTable);
      evsr := RateOf(RrBase, LKsr, FDecayTable);
    end;
    TLL := TL + Integer(AChannel.ksl_base shr ksl);
  end;
end;

procedure TOplChip.SetMul(ASlot: Integer; AValue: Integer);
var
  LChannel: Integer;
begin
  // set_mul: multi, am, vib, EG-TYP, KSR, mul
  LChannel := ASlot div 2;
  with FChannels[LChannel].Slots[ASlot and 1] do
  begin
    mul := MUL_TABLE[AValue and $0F];
    if (AValue and $10) <> 0 then
      KsrShift := 0
    else
      KsrShift := 2;
    EgTyp := Byte((AValue and $20) shr 5);
    vib := Byte(AValue and $40);
    ams := Byte(AValue and $80);
  end;
  CalcFcSlot(FChannels[LChannel], ASlot and 1);
end;

procedure TOplChip.SetKslTl(ASlot: Integer; AValue: Integer);
var
  LKsl: Integer;
begin
  // set_ksl_tl: ksl and tl
  LKsl := AValue shr 6; // 0 / 1.5 / 3 / 6 db/OCT
  with FChannels[ASlot div 2].Slots[ASlot and 1] do
  begin
    if LKsl <> 0 then
      ksl := Byte(3 - LKsl)
    else
      ksl := 31;
    TL := (AValue and $3F) * 32; // 0.75db step: 0.75 / EG_STEP
    if (FMode and $80) = 0 then
      // not CSM latch total level
      TLL := TL + Integer(FChannels[ASlot div 2].ksl_base shr ksl);
  end;
end;

procedure TOplChip.SetArDr(ASlot: Integer; AValue: Integer);
var
  LAttack: Integer;
  LDecay: Integer;
begin
  // set_ar_dr: attack rate and decay rate
  LAttack := AValue shr 4;
  LDecay := AValue and $0F;
  with FChannels[ASlot div 2].Slots[ASlot and 1] do
  begin
    if LAttack <> 0 then
      ArBase := LAttack shl 2
    else
      ArBase := -1;
    evsa := RateOf(ArBase, ksr, FAttackTable);
    if evm = OPL_ENV_ATTACK then
      evs := evsa;
    if LDecay <> 0 then
      DrBase := LDecay shl 2
    else
      DrBase := -1;
    evsd := RateOf(DrBase, ksr, FDecayTable);
    if evm = OPL_ENV_DECAY then
      evs := evsd;
  end;
end;

procedure TOplChip.SetSlRr(ASlot: Integer; AValue: Integer);
var
  LSustain: Integer;
  LRelease: Integer;
begin
  // set_sl_rr: sustain level and release rate
  LSustain := AValue shr 4;
  LRelease := AValue and $0F;
  with FChannels[ASlot div 2].Slots[ASlot and 1] do
  begin
    SL := SL_DECIBELS[LSustain] * 8388608 + OPL_EG_DST;
    if evm = OPL_ENV_DECAY then
      eve := SL;
    RrBase := LRelease shl 2;
    evsr := RateOf(RrBase, ksr, FDecayTable);
    if evm = OPL_ENV_RELEASE then
      evs := evsr;
  end;
end;

function TOplChip.OpOut(const ASlot: TOplSlot; AEnvelope: Integer; AConnection: Integer): Integer;
begin
  // OP_OUT: the phase is an unsigned 32 bit value, the connection a signed one converted to unsigned
  Result := FTotalLevel[FSinOffsets[ASlot.WaveBase +
    Integer(Cardinal(ASlot.Cnt + Cardinal(AConnection)) shr 13) and (OPL_SIN_ENT - 1)] + AEnvelope];
end;

procedure TOplChip.AdvancePhase(var ASlot: TOplSlot);
begin
  // PG: with vibrato the step is scaled by vib / VIB_RATE in unsigned arithmetic
  if ASlot.vib <> 0 then
    Inc(ASlot.Cnt, Cardinal(ASlot.Incr * Cardinal(FVib)) shr 8)
  else
    Inc(ASlot.Cnt, ASlot.Incr);
end;

procedure TOplChip.CalcChannel(var AChannel: TOplChannel);
var
  LEnvelope: Integer;
  LFeedback: Integer;
  LValue: Integer;
begin
  // OPL_CALC_CH: calculate one of channel
  FFeedback2 := 0;
  // SLOT 1
  LEnvelope := CalcSlot(AChannel.Slots[0]);
  if LEnvelope < OPL_EG_ENT - 1 then
  begin
    AdvancePhase(AChannel.Slots[0]);
    // connection
    if AChannel.FB <> 0 then
    begin
      LFeedback := Sar(AChannel.op1_out[0] + AChannel.op1_out[1], AChannel.FB);
      AChannel.op1_out[1] := AChannel.op1_out[0];
      LValue := OpOut(AChannel.Slots[0], LEnvelope, LFeedback);
      AChannel.op1_out[0] := LValue;
    end
    else
      LValue := OpOut(AChannel.Slots[0], LEnvelope, 0);
    if AChannel.Connect1ToCarrier then
      Inc(FOutput, LValue)
    else
      Inc(FFeedback2, LValue);
  end
  else
  begin
    AChannel.op1_out[1] := AChannel.op1_out[0];
    AChannel.op1_out[0] := 0;
  end;
  // SLOT 2
  LEnvelope := CalcSlot(AChannel.Slots[1]);
  if LEnvelope < OPL_EG_ENT - 1 then
  begin
    AdvancePhase(AChannel.Slots[1]);
    // connection
    Inc(FOutput, OpOut(AChannel.Slots[1], LEnvelope, FFeedback2));
  end;
end;

procedure TOplChip.CalcRhythm;
var
  LWhiteNoise: Integer;
  LEnvelope: Integer;
  LEnvelopeSd: Integer;
  LEnvelopeTam: Integer;
  LEnvelopeTop: Integer;
  LEnvelopeHh: Integer;
  LFeedback: Integer;
  LTone8: Integer;
begin
  // OPL_CALC_RH: calculate rythm block
  LWhiteNoise := FNoise.NextBit * WHITE_NOISE_STEPS;
  // BD: same as FM serial mode and output level is large
  FFeedback2 := 0;
  // SLOT 1
  LEnvelope := CalcSlot(FChannels[6].Slots[0]);
  if LEnvelope < OPL_EG_ENT - 1 then
  begin
    AdvancePhase(FChannels[6].Slots[0]);
    // connection
    if FChannels[6].FB <> 0 then
    begin
      LFeedback := Sar(FChannels[6].op1_out[0] + FChannels[6].op1_out[1], FChannels[6].FB);
      FChannels[6].op1_out[1] := FChannels[6].op1_out[0];
      FChannels[6].op1_out[0] := OpOut(FChannels[6].Slots[0], LEnvelope, LFeedback);
      FFeedback2 := FChannels[6].op1_out[0];
    end
    else
      FFeedback2 := OpOut(FChannels[6].Slots[0], LEnvelope, 0);
  end
  else
  begin
    FFeedback2 := 0;
    FChannels[6].op1_out[1] := FChannels[6].op1_out[0];
    FChannels[6].op1_out[0] := 0;
  end;
  // SLOT 2
  LEnvelope := CalcSlot(FChannels[6].Slots[1]);
  if LEnvelope < OPL_EG_ENT - 1 then
  begin
    AdvancePhase(FChannels[6].Slots[1]);
    // connection
    Inc(FOutput, OpOut(FChannels[6].Slots[1], LEnvelope, FFeedback2) * 2);
  end;

  // SD  (17) = mul14[fnum7] + white noise
  // TAM (15) = mul15[fnum8]
  // TOP (18) = fnum6(mul18[fnum8]+whitenoise)
  // HH  (14) = fnum7(mul18[fnum8]+whitenoise) + white noise
  LEnvelopeSd := CalcSlot(FChannels[7].Slots[1]) + LWhiteNoise;
  LEnvelopeTam := CalcSlot(FChannels[8].Slots[0]);
  LEnvelopeTop := CalcSlot(FChannels[8].Slots[1]);
  LEnvelopeHh := CalcSlot(FChannels[7].Slots[0]) + LWhiteNoise;

  // PG
  if FChannels[7].Slots[0].vib <> 0 then
    Inc(FChannels[7].Slots[0].Cnt, Cardinal(2 * FChannels[7].Slots[0].Incr * Cardinal(FVib)) shr 8)
  else
    Inc(FChannels[7].Slots[0].Cnt, 2 * FChannels[7].Slots[0].Incr);
  if FChannels[7].Slots[1].vib <> 0 then
    Inc(FChannels[7].Slots[1].Cnt, Cardinal(FChannels[7].fc * 8 * Cardinal(FVib)) shr 8)
  else
    Inc(FChannels[7].Slots[1].Cnt, FChannels[7].fc * 8);
  AdvancePhase(FChannels[8].Slots[0]);
  if FChannels[8].Slots[1].vib <> 0 then
    Inc(FChannels[8].Slots[1].Cnt, Cardinal(FChannels[8].fc * 48 * Cardinal(FVib)) shr 8)
  else
    Inc(FChannels[8].Slots[1].Cnt, FChannels[8].fc * 48);

  LTone8 := OpOut(FChannels[8].Slots[1], LWhiteNoise, 0);

  // SD
  if LEnvelopeSd < OPL_EG_ENT - 1 then
    Inc(FOutput, OpOut(FChannels[7].Slots[0], LEnvelopeSd, 0) * 8);
  // TAM
  if LEnvelopeTam < OPL_EG_ENT - 1 then
    Inc(FOutput, OpOut(FChannels[8].Slots[0], LEnvelopeTam, 0) * 2);
  // TOP-CY
  if LEnvelopeTop < OPL_EG_ENT - 1 then
    Inc(FOutput, OpOut(FChannels[7].Slots[1], LEnvelopeTop, LTone8) * 2);
  // HH
  if LEnvelopeHh < OPL_EG_ENT - 1 then
    Inc(FOutput, OpOut(FChannels[7].Slots[1], LEnvelopeHh, LTone8) * 2);
end;

procedure TOplChip.InitTimeTables(AAttackRate, ADecayRate: Integer);
var
  LIndex: Integer;
  LRate: Double;
  LQuotient: Double;
begin
  // init_timetables: make attack rate and decay rate tables
  for LIndex := 0 to 3 do
  begin
    FAttackTable[LIndex] := 0;
    FDecayTable[LIndex] := 0;
  end;
  for LIndex := 4 to 60 do
  begin
    LRate := FFreqBase; // frequency rate
    if LIndex < 60 then
      LRate := LRate * (1.0 + (LIndex and 3) * 0.25); // b0-1: x1, x1.25, x1.5, x1.75
    LRate := LRate * (1 shl ((LIndex shr 2) - 1)); // b2-5: shift bit
    LRate := LRate * EG_SCALE;
    LQuotient := LRate / AAttackRate;
    FAttackTable[LIndex] := Trunc(LQuotient);
    LQuotient := LRate / ADecayRate;
    FDecayTable[LIndex] := Trunc(LQuotient);
  end;
  for LIndex := 60 to 74 do
  begin
    FAttackTable[LIndex] := OPL_EG_AED - 1;
    FDecayTable[LIndex] := FDecayTable[60];
  end;
  // what the C reads past the end of the tables (the next array of the structure) is 0
  FAttackTable[75] := 0;
  FDecayTable[75] := 0;
end;

procedure TOplChip.Initialize;
var
  LFn: Integer;
  LValue: Double;
  LScale: Double;
  LClock: Double;
begin
  // OPL_initalize: frequency base
  if FRate <> 0 then
  begin
    LValue := FClock;
    LValue := LValue / FRate;
    FFreqBase := LValue / CLOCK_DIVIDER;
  end
  else
    FFreqBase := 0;
  // timer base time
  LValue := FClock;
  LValue := LValue / 72.0;
  FTimerBase := 1.0 / LValue;
  // make time tables
  InitTimeTables(OPL_ARRATE, OPL_DRRATE);
  // make fnumber -> increment counter table
  for LFn := 0 to 1023 do
  begin
    LValue := FFreqBase * LFn;
    LValue := LValue * OPL_FREQ_RATE;
    LValue := LValue * (1 shl 7);
    LValue := LValue / 2;
    FFrequencyTable[LFn] := Cardinal(Trunc(LValue));
  end;
  // LFO freq. table
  LClock := FClock;
  LClock := LClock / 3600000;
  if FRate <> 0 then
  begin
    LValue := 512.0;
    LValue := LValue * (1 shl OPL_AMS_SHIFT);
    LValue := LValue / FRate;
    LScale := 3.7;
    LValue := LValue * LScale;
    LValue := LValue * LClock;
    FAmsIncrement := Trunc(LValue);
    LValue := 512.0;
    LValue := LValue * (1 shl OPL_VIB_SHIFT);
    LValue := LValue / FRate;
    LScale := 6.4;
    LValue := LValue * LScale;
    LValue := LValue * LClock;
    FVibIncrement := Trunc(LValue);
  end
  else
  begin
    FAmsIncrement := 0;
    FVibIncrement := 0;
  end;
end;

procedure TOplChip.WriteReg(ARegister: Integer; AValue: Integer);
var
  LSlot: Integer;
  LChannel: Integer;
  LBlockFnum: Integer;
  LKey: Integer;
  LRhythmKey: Integer;
  LFeedback: Integer;
  LBlockReverse: Integer;
  LFnum: Integer;
  LInterval: Double;
  LTimer1: Byte;
  LTimer2: Byte;
begin
  // OPLWriteReg
  case ARegister and $E0 of
    $00: // 00-1f: control
      case ARegister and $1F of
        $01:
          begin
            // wave selector enable
            if (Ord(FChipType) and OPL_TYPE_WAVESEL) <> 0 then
            begin
              FWaveSelect := Byte(AValue and $20);
              if FWaveSelect = 0 then
                // preset compatible mode
                for LChannel := 0 to OPL_MAX_CHANNELS - 1 do
                begin
                  FChannels[LChannel].Slots[0].WaveBase := 0;
                  FChannels[LChannel].Slots[1].WaveBase := 0;
                end;
            end;
          end;
        $02: // Timer 1
          FTimers[0] := (256 - AValue) * 4;
        $03: // Timer 2
          FTimers[1] := (256 - AValue) * 16;
        $04: // IRQ clear / mask and Timer enable
          if (AValue and $80) <> 0 then
            // IRQ flag clear
            StatusReset($7F)
          else
          begin
            // set IRQ mask, timer enable
            LTimer1 := Byte(AValue and 1);
            LTimer2 := Byte((AValue shr 1) and 1);
            // IRQRST, T1MSK, t2MSK, EOSMSK, BRMSK, x, ST2, ST1
            StatusReset(AValue and $78);
            StatusMaskSet(((not AValue) and $78) or $01);
            // timer 2
            if FTimerEnabled[1] <> LTimer2 then
            begin
              if LTimer2 <> 0 then
                LInterval := FTimers[1] * FTimerBase
              else
                LInterval := 0.0;
              FTimerEnabled[1] := LTimer2;
              if Assigned(FListener) then
                FListener.TimerChanged(FTimerParam + 1, LInterval);
            end;
            // timer 1
            if FTimerEnabled[0] <> LTimer1 then
            begin
              if LTimer1 <> 0 then
                LInterval := FTimers[0] * FTimerBase
              else
                LInterval := 0.0;
              FTimerEnabled[0] := LTimer1;
              if Assigned(FListener) then
                FListener.TimerChanged(FTimerParam, LInterval);
            end;
          end;
      end;
    $20: // am, vib, ksr, eg type, mul
      begin
        LSlot := SLOT_ARRAY[ARegister and $1F];
        if LSlot <> -1 then
          SetMul(LSlot, AValue);
      end;
    $40:
      begin
        LSlot := SLOT_ARRAY[ARegister and $1F];
        if LSlot <> -1 then
          SetKslTl(LSlot, AValue);
      end;
    $60:
      begin
        LSlot := SLOT_ARRAY[ARegister and $1F];
        if LSlot <> -1 then
          SetArDr(LSlot, AValue);
      end;
    $80:
      begin
        LSlot := SLOT_ARRAY[ARegister and $1F];
        if LSlot <> -1 then
          SetSlRr(LSlot, AValue);
      end;
    $A0:
      begin
        if ARegister = $BD then
        begin
          // amsep, vibdep, r, bd, sd, tom, tc, hh
          LRhythmKey := FRhythm xor AValue;
          if (AValue and $80) <> 0 then
            FAmsBase := OPL_AMS_ENT
          else
            FAmsBase := 0;
          if (AValue and $40) <> 0 then
            FVibBase := OPL_VIB_ENT
          else
            FVibBase := 0;
          FRhythm := Byte(AValue and $3F);
          if (FRhythm and $20) <> 0 then
          begin
            // BD key on/off
            if (LRhythmKey and $10) <> 0 then
              if (AValue and $10) <> 0 then
              begin
                FChannels[6].op1_out[0] := 0;
                FChannels[6].op1_out[1] := 0;
                KeyOn(FChannels[6].Slots[0]);
                KeyOn(FChannels[6].Slots[1]);
              end
              else
              begin
                KeyOff(FChannels[6].Slots[0]);
                KeyOff(FChannels[6].Slots[1]);
              end;
            // SD key on/off
            if (LRhythmKey and $08) <> 0 then
              if (AValue and $08) <> 0 then
                KeyOn(FChannels[7].Slots[1])
              else
                KeyOff(FChannels[7].Slots[1]);
            // TAM key on/off
            if (LRhythmKey and $04) <> 0 then
              if (AValue and $04) <> 0 then
                KeyOn(FChannels[8].Slots[0])
              else
                KeyOff(FChannels[8].Slots[0]);
            // TOP-CY key on/off
            if (LRhythmKey and $02) <> 0 then
              if (AValue and $02) <> 0 then
                KeyOn(FChannels[8].Slots[1])
              else
                KeyOff(FChannels[8].Slots[1]);
            // HH key on/off
            if (LRhythmKey and $01) <> 0 then
              if (AValue and $01) <> 0 then
                KeyOn(FChannels[7].Slots[0])
              else
                KeyOff(FChannels[7].Slots[0]);
          end;
          Exit;
        end;
        // keyon, block, fnum
        if (ARegister and $0F) > 11 then
          Exit;
        LChannel := ARegister and $0F;
        if (ARegister and $10) = 0 then
          // a0-a8
          LBlockFnum := Integer(FChannels[LChannel].block_fnum and $1F00) or AValue
        else
        begin
          // b0-b8
          LKey := (AValue shr 5) and 1;
          LBlockFnum := ((AValue and $1F) shl 8) or Integer(FChannels[LChannel].block_fnum and $FF);
          if FChannels[LChannel].keyon <> LKey then
          begin
            FChannels[LChannel].keyon := Byte(LKey);
            if LKey <> 0 then
            begin
              FChannels[LChannel].op1_out[0] := 0;
              FChannels[LChannel].op1_out[1] := 0;
              KeyOn(FChannels[LChannel].Slots[0]);
              KeyOn(FChannels[LChannel].Slots[1]);
            end
            else
            begin
              KeyOff(FChannels[LChannel].Slots[0]);
              KeyOff(FChannels[LChannel].Slots[1]);
            end;
          end;
        end;
        // update
        if Integer(FChannels[LChannel].block_fnum) <> LBlockFnum then
        begin
          LBlockReverse := 7 - (LBlockFnum shr 10);
          LFnum := LBlockFnum and $3FF;
          FChannels[LChannel].block_fnum := Cardinal(LBlockFnum);
          FChannels[LChannel].ksl_base := Cardinal(KSL_STEPS[LBlockFnum shr 6]) * 32;
          FChannels[LChannel].fc := FFrequencyTable[LFnum] shr LBlockReverse;
          FChannels[LChannel].kcode := Byte(FChannels[LChannel].block_fnum shr 9);
          if ((FMode and $40) <> 0) and ((FChannels[LChannel].block_fnum and $100) <> 0) then
            FChannels[LChannel].kcode := FChannels[LChannel].kcode or 1;
          CalcFcSlot(FChannels[LChannel], 0);
          CalcFcSlot(FChannels[LChannel], 1);
        end;
      end;
    $C0:
      begin
        // FB, C
        if (ARegister and $0F) > 11 then
          Exit;
        LChannel := ARegister and $0F;
        LFeedback := (AValue shr 1) and 7;
        if LFeedback <> 0 then
          FChannels[LChannel].FB := Byte((8 + 1) - LFeedback)
        else
          FChannels[LChannel].FB := 0;
        FChannels[LChannel].CON := Byte(AValue and 1);
        SetAlgorithm(FChannels[LChannel]);
      end;
    $E0: // wave type
      begin
        LSlot := SLOT_ARRAY[ARegister and $1F];
        if LSlot = -1 then
          Exit;
        if FWaveSelect <> 0 then
          FChannels[LSlot div 2].Slots[LSlot and 1].WaveBase := (AValue and $03) * OPL_SIN_ENT;
      end;
  end;
end;

procedure TOplChip.Reset;
var
  LIndex: Integer;
  LChannel: Integer;
  LSlot: Integer;
begin
  // OPLResetChip: reset chip
  FMode := 0; // normal mode
  StatusReset($7F);
  // reset with register write
  WriteReg($01, 0); // wabesel disable
  WriteReg($02, 0); // Timer1
  WriteReg($03, 0); // Timer2
  WriteReg($04, 0); // IRQ mask clear
  for LIndex := $FF downto $20 do
    WriteReg(LIndex, 0);
  // reset OPerator parameter
  for LChannel := 0 to OPL_MAX_CHANNELS - 1 do
    for LSlot := 0 to 1 do
    begin
      FChannels[LChannel].Slots[LSlot].WaveBase := 0;
      FChannels[LChannel].Slots[LSlot].evc := OPL_EG_OFF;
      FChannels[LChannel].Slots[LSlot].eve := OPL_EG_OFF + 1;
      FChannels[LChannel].Slots[LSlot].evs := 0;
    end;
end;

function TOplChip.Write(APort: Integer; AValue: Integer): Integer;
begin
  // OPLWrite
  if (APort and 1) = 0 then
    // address port
    FAddress := Byte(AValue and $FF)
  else
  begin
    // data port
    if Assigned(FListener) then
      FListener.BeforeDataWrite(FUpdateParam);
    WriteReg(FAddress, AValue);
  end;
  Result := FStatus shr 7;
end;

procedure TOplChip.WriteRegister(ARegister: Byte; AValue: Byte);
begin
  Write(0, ARegister);
  Write(1, AValue);
end;

function TOplChip.Read(APort: Integer): Byte;
begin
  // OPLRead: the status port; the data port only answers for the keyboard and the I/O port of the Y8950
  if (APort and 1) = 0 then
    Result := FStatus and (FStatusMask or $80)
  else
    Result := 0;
end;

function TOplChip.TimerOver(ATimer: Integer): Integer;
begin
  // OPLTimerOver
  if ATimer <> 0 then
    // Timer B
    StatusSet($20)
  else
    // Timer A (the CSM mode is never set: the register 8 is only handled by the Y8950 build of the C)
    StatusSet($40);
  // reload timer
  if Assigned(FListener) then
    FListener.TimerChanged(FTimerParam + ATimer, FTimers[Ord(ATimer <> 0)] * FTimerBase);
  Result := FStatus shr 7;
end;

procedure TOplChip.SetListener(const AListener: IOplChipListener; ATimerChannelOffset, AIrqParam,
  AUpdateParam: Integer);
begin
  FListener := AListener;
  FTimerParam := ATimerChannelOffset;
  FIrqParam := AIrqParam;
  FUpdateParam := AUpdateParam;
end;

function TOplChip.AttackRate(AIndex: Integer): Integer;
begin
  Result := FAttackTable[AIndex];
end;

function TOplChip.DecayRate(AIndex: Integer): Integer;
begin
  Result := FDecayTable[AIndex];
end;

function TOplChip.FrequencyStep(AIndex: Integer): Cardinal;
begin
  Result := FFrequencyTable[AIndex];
end;

function TOplChip.GetLegacyLfoCache: Boolean;
begin
  Result := FLegacyLfoCache;
end;

procedure TOplChip.SetLegacyLfoCache(AValue: Boolean);
begin
  FLegacyLfoCache := AValue;
end;

procedure TOplChip.SwitchTo;
begin
  // the first block of this chip after another one: copy what the C keeps in globals
  if (FTables.ActiveChip <> NativeInt(Self)) or not FLegacyLfoCache or not FCacheValid then
  begin
    FTables.ActiveChip := NativeInt(Self);
    FCacheValid := True;
    FCachedAmsIncrement := FAmsIncrement;
    FCachedVibIncrement := FVibIncrement;
    FCachedAmsBase := FAmsBase;
    FCachedVibBase := FVibBase;
  end;
end;

procedure TOplChip.GenerateSamples(const ABuffer: TArray<SmallInt>; ACount: Integer);
begin
  GenerateSamples(ABuffer, 0, ACount, 1, 1.0);
end;

procedure TOplChip.GenerateSamples(const ABuffer: TArray<SmallInt>; AOffset, ALength, AStripe: Integer;
  AVolume: Single);
var
  LIndex: Integer;
  LChannel: Integer;
  LLast: Integer;
  LData: Integer;
  LRhythm: Boolean;
  LScaled: Single;
  LPrecision: TFPUPrecisionMode;
begin
  // YM3812UpdateOne
  if AStripe < 1 then
    raise EOplException.CreateFmt('The stripe of the samples must be 1 or more (%d)', [AStripe]);
  if (ALength > 0) and ((AOffset < 0) or (AOffset + ((ALength - 1) div AStripe) * AStripe >= Length(ABuffer))) then
    raise EOplException.CreateFmt('The buffer of %d samples is too short for %d slots from %d', [Length(ABuffer),
      ALength, AOffset]);
  LPrecision := SetPrecisionMode(pmDouble);
  try
    SwitchTo;
    LRhythm := (FRhythm and $20) <> 0;
    if LRhythm then
      LLast := 5
    else
      LLast := OPL_SOUND_CHANNELS - 1;
    LIndex := 0;
    while LIndex < ALength do
    begin
      // LFO
      Inc(FAmsCounter, Cardinal(FCachedAmsIncrement));
      FAms := FAmsTable[FCachedAmsBase + Integer(FAmsCounter shr OPL_AMS_SHIFT)];
      Inc(FVibCounter, Cardinal(FCachedVibIncrement));
      FVib := FVibTable[FCachedVibBase + Integer(FVibCounter shr OPL_VIB_SHIFT)];
      FOutput := 0;
      // FM part
      for LChannel := 0 to LLast do
        CalcChannel(FChannels[LChannel]);
      // Rythm part
      if LRhythm then
        CalcRhythm;
      LScaled := FOutput; // converted (and rounded) to single precision, as the float multiplication of the C does
      LScaled := LScaled * AVolume;
      FOutput := TruncToInteger(LScaled);
      // limit check
      LData := FOutput;
      if LData > OPL_MAXOUT then
        LData := OPL_MAXOUT
      else if LData < OPL_MINOUT then
        LData := OPL_MINOUT;
      // store to sound buffer
      ABuffer[AOffset + LIndex] := SmallInt(Sar(LData, OPL_OUTSB));
      Inc(LIndex, AStripe);
    end;
  finally
    SetPrecisionMode(LPrecision);
  end;
end;

end.
