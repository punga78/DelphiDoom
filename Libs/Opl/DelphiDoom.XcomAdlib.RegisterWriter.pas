{******************************************************************************}
{                                                                              }
{  DelphiDoom: X-COM Adlib player - the register writer (adlib_reg, Transpose)  }
{                                                                              }
{  Port of adlplayer.cpp (X-COM Adlib Player by Volutar, OpenXcom,              }
{  GPL v3 or later): see Libs\Opl\README.md for the license                     }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomAdlib.RegisterWriter;

interface

uses
  System.SysUtils, System.Math, DelphiDoom.Opl.Intf, DelphiDoom.XcomAdlib.Types, DelphiDoom.XcomAdlib.Intf;

type
  /// <summary>
  ///   adlib_reg: every register goes to the first chip as it is and to the second one (the right channel) transposed
  ///   by about a 128th of the frequency, so the two sound with a slight harmonic effect; the second chip gets no
  ///   tremolo and vibrato and only the sine waveforms. The state of the C (iFMReg, iTweakedFMReg...) belongs to the
  ///   object
  /// </summary>
  TXcomAdlibRegisterWriter = class(TInterfacedObject, IXcomAdlibRegisterWriter)
  strict private
    FLeft: IOplChip;
    FRight: IOplChip;
    FFmRegisters: array[0..255] of Byte;
    FTweakedRegisters: array[0..255] of Byte;
    FCurrentTweakedBlock: array[0..XCOM_ADLIB_CHANNELS - 1] of Byte;
    FCurrentFNum: array[0..XCOM_ADLIB_CHANNELS - 1] of Byte;
    procedure Transpose(ARegister, AValue: Integer; out AValue2, ARegister3, AValue3: Integer);
  public
    constructor Create(const ALeft, ARight: IOplChip);
    procedure WriteRegister(ARegister: Integer; AValue: Integer);
  end;

implementation

{$Q-}
{$R-}
// SetPrecisionMode limits the x87 to 53 bits on Win32 (the C is compiled for SSE); on Win64 it has no effect
{$WARN SYMBOL_PLATFORM OFF}

const
  /// <summary>FREQ_OFFSET</summary>
  FREQ_OFFSET: Double = 128.0;
  /// <summary>NEWBLOCK_LIMIT</summary>
  NEWBLOCK_LIMIT = 32;
  OPL_NATIVE_RATE: Double = 49716.0;

{ TXcomAdlibRegisterWriter }

constructor TXcomAdlibRegisterWriter.Create(const ALeft, ARight: IOplChip);
begin
  inherited Create;
  if not Assigned(ALeft) or not Assigned(ARight) then
    raise EXcomAdlibException.Create('The Adlib needs two chips');
  FLeft := ALeft;
  FRight := ARight;
end;

procedure TXcomAdlibRegisterWriter.Transpose(ARegister, AValue: Integer; out AValue2, ARegister3,
  AValue3: Integer);
var
  LChannel: Integer;
  LValue: Integer;
  LBlock: Integer;
  LFNum: Integer;
  LNewBlock: Integer;
  LNewFNum: Integer;
  LOriginalFrequency: Double;
  LNewFNumValue: Double;
  LDivisor: Double;
  LScaled: Double;
  LAdditionalRegister: Integer;
  LAdditionalValue: Integer;
  LNewB0Value: Byte;

  function CalcFNum: Double;
  var
    LSum: Double;
    LShifted: Double;
  begin
    // calcFNum(): (orig + orig / FREQ_OFFSET) / (49716.0 / 2^(20 - newblock)), every step in double
    LShifted := LOriginalFrequency / FREQ_OFFSET;
    LSum := LOriginalFrequency + LShifted;
    LDivisor := 1 shl (20 - LNewBlock);
    LDivisor := OPL_NATIVE_RATE / LDivisor;
    Result := LSum / LDivisor;
  end;

begin
  // Transpose the other channel to produce the harmonic effect
  LChannel := -1;
  LValue := AValue;
  ARegister3 := -1;
  AValue3 := 0;
  if ((ARegister shr 4) = $A) or ((ARegister shr 4) = $B) then
    LChannel := ARegister and $0F;

  // Remember the FM state, so that the harmonic effect can access previously assigned register values
  FFmRegisters[ARegister] := Byte(LValue);

  if (LChannel >= 0) and (LChannel < 12) then
  begin
    LBlock := (FFmRegisters[$B0 + LChannel] shr 2) and $07;
    LFNum := ((FFmRegisters[$B0 + LChannel] and $03) shl 8) or FFmRegisters[$A0 + LChannel];
    LDivisor := 1 shl (20 - LBlock);
    LScaled := OPL_NATIVE_RATE * LFNum;
    LOriginalFrequency := LScaled / LDivisor;

    LNewBlock := LBlock;
    // Adjust the frequency and calculate the new FNum
    LNewFNumValue := CalcFNum;

    // Make sure it's in range for the OPL chip
    if LNewFNumValue > 1023 - NEWBLOCK_LIMIT then
    begin
      // It's too high, so move up one block (octave) and recalculate
      if LNewBlock > 6 then
      begin
        // already at the highest octave: play the same note out of the second OPL
        LNewBlock := LBlock;
        LNewFNum := LFNum;
      end
      else
      begin
        Inc(LNewBlock);
        LNewFNum := Word(Trunc(CalcFNum));
      end;
    end
    else if LNewFNumValue < 0 + NEWBLOCK_LIMIT then
    begin
      // It's too low, so move down one block (octave) and recalculate
      if LNewBlock = 0 then
      begin
        // already at the lowest octave
        LNewBlock := LBlock;
        LNewFNum := LFNum;
      end
      else
      begin
        Dec(LNewBlock);
        LNewFNum := Word(Trunc(CalcFNum));
      end;
    end
    else
      // Original calculation is within range, use that
      LNewFNum := Word(Trunc(LNewFNumValue));

    // Sanity check
    if LNewFNum > 1023 then
    begin
      LNewBlock := LBlock;
      LNewFNum := LFNum;
    end;

    if (ARegister >= $B0) and (ARegister <= $BC) then
    begin
      // Overwrite the supplied value with the new F-Number and Block
      LValue := (LValue and not $1F) or (LNewBlock shl 2) or ((LNewFNum shr 8) and $03);
      // save it so we don't have to update register 0xB0 later on
      FCurrentTweakedBlock[LChannel] := Byte(LNewBlock);
      FCurrentFNum[LChannel] := Byte(LNewFNum);
      if FTweakedRegisters[$A0 + LChannel] <> (LNewFNum and $FF) then
      begin
        // Need to write out low bits
        LAdditionalRegister := $A0 + LChannel;
        LAdditionalValue := LNewFNum and $FF;
        ARegister3 := LAdditionalRegister;
        AValue3 := LAdditionalValue;
        FTweakedRegisters[LAdditionalRegister] := Byte(LAdditionalValue);
      end;
    end
    else if (ARegister >= $A0) and (ARegister <= $AC) then
    begin
      // Overwrite the supplied value with the new F-Number
      LValue := LNewFNum and $FF;
      // See if we need to update the block number, which is stored in a different register
      LNewB0Value := Byte((FFmRegisters[$B0 + LChannel] and not $1F) or (LNewBlock shl 2) or ((LNewFNum shr 8) and $03));
      if ((LNewB0Value and $20) <> 0) and (FTweakedRegisters[$B0 + LChannel] <> LNewB0Value) then
      begin
        // The note is already playing, so we need to adjust the upper bits too
        LAdditionalRegister := $B0 + LChannel;
        ARegister3 := LAdditionalRegister;
        AValue3 := LNewB0Value;
        FTweakedRegisters[LAdditionalRegister] := LNewB0Value;
      end;
    end;
  end;

  // Now write to the original register with a possibly modified value
  AValue2 := LValue;
  FTweakedRegisters[ARegister] := Byte(LValue);
end;

procedure TXcomAdlibRegisterWriter.WriteRegister(ARegister: Integer; AValue: Integer);
var
  LValue2: Integer;
  LRegister3: Integer;
  LValue3: Integer;
  LPrecision: TFPUPrecisionMode;
begin
  if (ARegister < 0) or (ARegister > 255) then
    raise EXcomAdlibException.CreateFmt('The Adlib register %d does not exist', [ARegister]);
  // the C is compiled for SSE: every operation is rounded to double
  LPrecision := SetPrecisionMode(pmDouble);
  try
    Transpose(ARegister, AValue, LValue2, LRegister3, LValue3);
  finally
    SetPrecisionMode(LPrecision);
  end;

  FLeft.Write(0, ARegister);
  FLeft.Write(1, AValue);
  FRight.Write(0, ARegister);
  if (ARegister >= $20) and (ARegister <= $3F) then // no tremolo/vibrato
    LValue2 := LValue2 and $3F;
  if (ARegister >= $E0) and (ARegister <= $FC) then
    if (XCOM_ADLIB_SLOT_ARRAY[ARegister and $1F] and 1) = 1 then // wave form
      LValue2 := LValue2 and $02;
  FRight.Write(1, LValue2);
  if LRegister3 <> -1 then
  begin
    FRight.Write(0, LRegister3);
    FRight.Write(1, LValue3);
  end;
end;

end.
