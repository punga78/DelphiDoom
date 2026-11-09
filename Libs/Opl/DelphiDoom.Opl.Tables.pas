{******************************************************************************}
{                                                                              }
{  DelphiDoom: OPL2 (YM3812) library - the shared tables                        }
{                                                                              }
{  Port of fmopl.c (MAME 0.37a fork for OpenXcom, LGPL 2.1 or later)            }
{  See DelphiDoom.Opl.Types for the copyright notice                            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Opl.Tables;

interface

uses
  System.SysUtils, System.Math, DelphiDoom.Opl.Types, DelphiDoom.Opl.Intf;

type
  /// <summary>
  ///   OPLOpenTable: the tables the C builds with pow, sin and log10 in double precision the first time a chip is
  ///   created and keeps in globals. Here they belong to an object the chips are given; they are calculated with Double
  ///   in the same order as the C, so the integers are the same (the parity test compares all of them)
  /// </summary>
  TOplTables = class(TInterfacedObject, IOplTables)
  strict private
    FTotalLevel: TArray<Integer>;
    FSinOffsets: TArray<Integer>;
    FEnvelopeCurve: TArray<Integer>;
    FAmsTable: TArray<Integer>;
    FVibTable: TArray<Integer>;
    FActiveChip: NativeInt;
    procedure BuildTotalLevel;
    procedure BuildSine;
    procedure BuildEnvelope;
    procedure BuildLfo;
    function GetTotalLevel: TArray<Integer>;
    function GetSinOffsets: TArray<Integer>;
    function GetEnvelopeCurve: TArray<Integer>;
    function GetAmsTable: TArray<Integer>;
    function GetVibTable: TArray<Integer>;
    function GetActiveChip: NativeInt;
    procedure SetActiveChip(AValue: NativeInt);
  public
    constructor Create;
  end;

implementation

// SetPrecisionMode limits the x87 to 53 bits on Win32 (the C is compiled for SSE); on Win64 it has no effect
{$WARN SYMBOL_PLATFORM OFF}

const
  /// <summary>PI of fmopl.cpp</summary>
  OPL_PI: Double = 3.14159265358979323846;
  EG_STEP: Double = OPL_EG_STEP;

{ TOplTables }

constructor TOplTables.Create;
var
  LPrecision: TFPUPrecisionMode;
begin
  inherited Create;
  // the C is compiled for SSE: every operation is rounded to double. With the x87 of Win32 the precision of the
  // operations has to be limited to 53 bits to give the same integers
  LPrecision := SetPrecisionMode(pmDouble);
  try
    BuildTotalLevel;
    BuildSine;
    BuildEnvelope;
    BuildLfo;
  finally
    SetPrecisionMode(LPrecision);
  end;
end;

procedure TOplTables.BuildTotalLevel;
var
  LStep: Integer;
  LExponent: Double;
  LPower: Double;
  LRate: Double;
begin
  SetLength(FTotalLevel, OPL_TL_MAX * 2);
  // make total level table
  for LStep := 0 to OPL_EG_ENT - 2 do
  begin
    LExponent := EG_STEP * LStep / 20;
    LPower := Power(10, LExponent);
    LRate := ((1 shl OPL_TL_BITS) - 1) / LPower;
    FTotalLevel[LStep] := Trunc(LRate);
    FTotalLevel[OPL_TL_MAX + LStep] := -FTotalLevel[LStep];
  end;
  // fill volume off area
  for LStep := OPL_EG_ENT - 1 to OPL_TL_MAX - 1 do
  begin
    FTotalLevel[LStep] := 0;
    FTotalLevel[OPL_TL_MAX + LStep] := 0;
  end;
end;

procedure TOplTables.BuildSine;
var
  LAngle: Integer;
  LSin: Double;
  LDecibel: Double;
  LTerm: Integer;
begin
  SetLength(FSinOffsets, OPL_SIN_ENT * 4);
  // degree 0 = degree 180 = off
  FSinOffsets[0] := OPL_EG_ENT - 1;
  FSinOffsets[OPL_SIN_ENT div 2] := OPL_EG_ENT - 1;
  for LAngle := 1 to OPL_SIN_ENT div 4 do
  begin
    LSin := System.Sin(2 * OPL_PI * LAngle / OPL_SIN_ENT);
    LDecibel := 20 * Log10(1 / LSin);
    LTerm := Trunc(LDecibel / EG_STEP);
    // degree 0 - 90, degree 180 - 90: plus section
    FSinOffsets[LAngle] := LTerm;
    FSinOffsets[OPL_SIN_ENT div 2 - LAngle] := LTerm;
    // degree 180 - 270, degree 360 - 270: minus section
    FSinOffsets[OPL_SIN_ENT div 2 + LAngle] := OPL_TL_MAX + LTerm;
    FSinOffsets[OPL_SIN_ENT - LAngle] := OPL_TL_MAX + LTerm;
  end;
  for LAngle := 0 to OPL_SIN_ENT - 1 do
  begin
    if LAngle < OPL_SIN_ENT div 2 then
      FSinOffsets[OPL_SIN_ENT + LAngle] := FSinOffsets[LAngle]
    else
      FSinOffsets[OPL_SIN_ENT + LAngle] := OPL_EG_ENT;
    FSinOffsets[OPL_SIN_ENT * 2 + LAngle] := FSinOffsets[LAngle mod (OPL_SIN_ENT div 2)];
    if ((LAngle div (OPL_SIN_ENT div 4)) and 1) <> 0 then
      FSinOffsets[OPL_SIN_ENT * 3 + LAngle] := OPL_EG_ENT
    else
      FSinOffsets[OPL_SIN_ENT * 3 + LAngle] := FSinOffsets[OPL_SIN_ENT * 2 + LAngle];
  end;
end;

procedure TOplTables.BuildEnvelope;
var
  LIndex: Integer;
  LBase: Double;
  LPower: Double;
begin
  SetLength(FEnvelopeCurve, 2 * OPL_EG_ENT + 1);
  // envelope counter -> envelope output table
  for LIndex := 0 to OPL_EG_ENT - 1 do
  begin
    // ATTACK curve: pow(x, 8) * EG_ENT
    LBase := (OPL_EG_ENT - 1 - LIndex) / OPL_EG_ENT;
    LPower := Power(LBase, 8) * OPL_EG_ENT;
    FEnvelopeCurve[LIndex] := Trunc(LPower);
    // DECAY, RELEASE curve
    FEnvelopeCurve[(OPL_EG_DST shr OPL_ENV_BITS) + LIndex] := LIndex;
  end;
  // off
  FEnvelopeCurve[OPL_EG_OFF shr OPL_ENV_BITS] := OPL_EG_ENT - 1;
end;

procedure TOplTables.BuildLfo;
var
  LIndex: Integer;
  LPhase: Double;
  LDepth: Double;
  LFactor: Double;
begin
  SetLength(FAmsTable, OPL_AMS_ENT * 2);
  SetLength(FVibTable, OPL_VIB_ENT * 2);
  // make LFO ams table
  for LIndex := 0 to OPL_AMS_ENT - 1 do
  begin
    LPhase := (1.0 + System.Sin(2 * OPL_PI * LIndex / OPL_AMS_ENT)) / 2;
    LFactor := 1.0 / EG_STEP;
    FAmsTable[LIndex] := Trunc(LFactor * LPhase); // 1dB
    LFactor := 4.8 / EG_STEP;
    FAmsTable[OPL_AMS_ENT + LIndex] := Trunc(LFactor * LPhase); // 4.8dB
  end;
  // make LFO vibrate table
  for LIndex := 0 to OPL_VIB_ENT - 1 do
  begin
    // 100cent = 1seminote = 6% ??
    LDepth := OPL_VIB_RATE;
    LDepth := LDepth * 0.06;
    LPhase := System.Sin(2 * OPL_PI * LIndex / OPL_VIB_ENT);
    LDepth := LDepth * LPhase; // +-100sect step
    LFactor := LDepth * 0.07;
    FVibTable[LIndex] := Trunc(OPL_VIB_RATE + LFactor); // +- 7cent
    LFactor := LDepth * 0.14;
    FVibTable[OPL_VIB_ENT + LIndex] := Trunc(OPL_VIB_RATE + LFactor); // +-14cent
  end;
end;

function TOplTables.GetTotalLevel: TArray<Integer>;
begin
  Result := FTotalLevel;
end;

function TOplTables.GetSinOffsets: TArray<Integer>;
begin
  Result := FSinOffsets;
end;

function TOplTables.GetEnvelopeCurve: TArray<Integer>;
begin
  Result := FEnvelopeCurve;
end;

function TOplTables.GetAmsTable: TArray<Integer>;
begin
  Result := FAmsTable;
end;

function TOplTables.GetVibTable: TArray<Integer>;
begin
  Result := FVibTable;
end;

function TOplTables.GetActiveChip: NativeInt;
begin
  Result := FActiveChip;
end;

procedure TOplTables.SetActiveChip(AValue: NativeInt);
begin
  FActiveChip := AValue;
end;

end.
