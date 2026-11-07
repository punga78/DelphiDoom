{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the OpenGL math library - the scenarios of parity      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.GlMath.Scenarios;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.GlMath.Types;

type
  /// <summary>
  ///   What a scenario asks: the new classes in the tests, a copy of the old unit in the
  ///   temporary harness that made the golden files (the harness is not committed)
  /// </summary>
  IGlMathSubject = interface
    procedure CalculateFrustum(const AProjection, AModelView: TGlMatrix4);
    function Plane(const ASide, AIndex: Integer): Single;
    function ContainsPoint(const AX, AY, AZ: Single): Boolean;
    function ContainsSphere(const AX, AY, AZ, ARadius: Single): Boolean;
    function ContainsBox(const AX, AY, AZ, ASizeX, ASizeY, ASizeZ: Single): Boolean;
    function ContainsCube(const AX, AY, AZ, ASize: Single): Boolean;
    procedure ClipperClear;
    procedure ClipperSafeAdd(const AStart, AEnd: Cardinal);
    function ClipperSafeCheck(const AStart, AEnd: Cardinal): Boolean;
    function ClipperCount: Integer;
    function ClipperStart(const AIndex: Integer): Cardinal;
    function ClipperFinish(const AIndex: Integer): Cardinal;
    function FrustumAngle(const ALookDirection16: Integer; const AAspect: Double): Cardinal;
  end;

  /// <summary>The same inputs for the old code and the new one: xorshift32 with a fixed seed</summary>
  TGlMathRandom = class
  private
    FState: Cardinal;
  public
    constructor Create(const ASeed: Cardinal);
    function NextCardinal: Cardinal;
    /// <summary>A number between AMin and AMax (the Double is made a Single)</summary>
    function NextSingle(const AMin, AMax: Double): Single;
    function NextInteger(const ARange: Integer): Integer;
  end;

  TGlMathScenarios = class
  public
    /// <summary>The 24 values of the planes and the tests of 250 probes of each kind, for each pair of matrices</summary>
    class function FrustumPlanes(const ASubject: IGlMathSubject): string; static;
    class function FrustumPoints(const ASubject: IGlMathSubject): string; static;
    class function FrustumSpheres(const ASubject: IGlMathSubject): string; static;
    class function FrustumBoxes(const ASubject: IGlMathSubject): string; static;
    class function FrustumCubes(const ASubject: IGlMathSubject): string; static;
    /// <summary>Sequences of adds, checks and clears with ranges of all sizes; the list after each step</summary>
    class function ClipperSequences(const ASubject: IGlMathSubject): string; static;
    /// <summary>The view angle for a sweep of look directions and some aspects</summary>
    class function ViewAngles(const ASubject: IGlMathSubject): string; static;
  end;

implementation

uses
  System.SysUtils, System.Math, DelphiDoom.Tests.GlMath.Fingerprint;

const
  MATRIX_PAIRS = 80;
  PROBES = 250;
  CLIPPER_SEQUENCES = 40;
  CLIPPER_STEPS = 400;

{ TGlMathRandom }

constructor TGlMathRandom.Create(const ASeed: Cardinal);
begin
  inherited Create;
  FState := ASeed;
  if FState = 0 then
    FState := $9E3779B9;
end;

function TGlMathRandom.NextCardinal: Cardinal;
begin
  FState := FState xor (FState shl 13);
  FState := FState xor (FState shr 17);
  FState := FState xor (FState shl 5);
  Result := FState;
end;

function TGlMathRandom.NextSingle(const AMin, AMax: Double): Single;
begin
  Result := AMin + (AMax - AMin) * (NextCardinal / 4294967296.0);
end;

function TGlMathRandom.NextInteger(const ARange: Integer): Integer;
begin
  Result := Integer(NextCardinal mod Cardinal(ARange));
end;

{ helpers }

procedure MakeMatrices(const ARandom: TGlMathRandom; const AIndex: Integer;
  out AProjection, AModelView: TGlMatrix4);
var
  LFov, LAspect, LNear, LFar, LFocal: Double;
  LAx, LAy, LAz, LSx, LCx, LSy, LCy, LSz, LCz: Double;
  LIndex: Integer;
begin
  if AIndex mod 8 = 7 then
  begin
    // a matrix of any values, that is not a camera
    for LIndex := 0 to 15 do
    begin
      AProjection[LIndex] := ARandom.NextSingle(-3, 3);
      AModelView[LIndex] := ARandom.NextSingle(-3, 3);
    end;
    Exit;
  end;
  LFov := ARandom.NextSingle(20, 130) * Pi / 180;
  LAspect := ARandom.NextSingle(0.5, 2.5);
  LNear := ARandom.NextSingle(0.02, 1.0);
  LFar := ARandom.NextSingle(100, 6000);
  LFocal := 1 / Tan(LFov / 2);
  FillChar(AProjection, SizeOf(AProjection), 0);
  AProjection[0] := LFocal / LAspect;
  AProjection[5] := LFocal;
  AProjection[10] := (LFar + LNear) / (LNear - LFar);
  AProjection[11] := -1;
  AProjection[14] := 2 * LFar * LNear / (LNear - LFar);

  LAx := ARandom.NextSingle(-Pi, Pi);
  LAy := ARandom.NextSingle(-Pi, Pi);
  LAz := ARandom.NextSingle(-Pi, Pi);
  LSx := Sin(LAx); LCx := Cos(LAx);
  LSy := Sin(LAy); LCy := Cos(LAy);
  LSz := Sin(LAz); LCz := Cos(LAz);
  FillChar(AModelView, SizeOf(AModelView), 0);
  AModelView[0] := LCy * LCz;
  AModelView[1] := LCx * LSz + LSx * LSy * LCz;
  AModelView[2] := LSx * LSz - LCx * LSy * LCz;
  AModelView[4] := -LCy * LSz;
  AModelView[5] := LCx * LCz - LSx * LSy * LSz;
  AModelView[6] := LSx * LCz + LCx * LSy * LSz;
  AModelView[8] := LSy;
  AModelView[9] := -LSx * LCy;
  AModelView[10] := LCx * LCy;
  AModelView[12] := ARandom.NextSingle(-500, 500);
  AModelView[13] := ARandom.NextSingle(-200, 200);
  AModelView[14] := ARandom.NextSingle(-500, 500);
  AModelView[15] := 1;
end;

function RandomAngle(const ARandom: TGlMathRandom): Cardinal;
var
  LKind: Integer;
begin
  LKind := ARandom.NextInteger(8);
  case LKind of
    0: Result := 0;
    1: Result := $FFFFFFFF;
    2: Result := ARandom.NextCardinal and $000FFFFF;
    3: Result := $FFFFFFFF - (ARandom.NextCardinal and $000FFFFF);
  else
    Result := ARandom.NextCardinal;
  end;
end;

{ TGlMathScenarios }

class function TGlMathScenarios.FrustumPlanes(const ASubject: IGlMathSubject): string;
var
  LRandom: TGlMathRandom;
  LFingerprint: TFingerprint;
  LProjection, LModelView: TGlMatrix4;
  LPair, LSide, LIndex: Integer;
begin
  LRandom := TGlMathRandom.Create(20240101);
  LFingerprint := TFingerprint.Create;
  try
    for LPair := 0 to MATRIX_PAIRS - 1 do
    begin
      MakeMatrices(LRandom, LPair, LProjection, LModelView);
      ASubject.CalculateFrustum(LProjection, LModelView);
      for LSide := 0 to 5 do
        for LIndex := 0 to 3 do
          LFingerprint.AddSingle(ASubject.Plane(LSide, LIndex));
    end;
    Result := LFingerprint.ToHex;
  finally
    LFingerprint.Free;
    LRandom.Free;
  end;
end;

class function TGlMathScenarios.FrustumPoints(const ASubject: IGlMathSubject): string;
var
  LRandom, LProbe: TGlMathRandom;
  LFingerprint: TFingerprint;
  LProjection, LModelView: TGlMatrix4;
  LPair, LCount: Integer;
begin
  LRandom := TGlMathRandom.Create(20240101);
  LProbe := TGlMathRandom.Create(777);
  LFingerprint := TFingerprint.Create;
  try
    for LPair := 0 to MATRIX_PAIRS - 1 do
    begin
      MakeMatrices(LRandom, LPair, LProjection, LModelView);
      ASubject.CalculateFrustum(LProjection, LModelView);
      for LCount := 1 to PROBES do
        LFingerprint.AddBoolean(ASubject.ContainsPoint(LProbe.NextSingle(-300, 300),
          LProbe.NextSingle(-300, 300), LProbe.NextSingle(-300, 300)));
    end;
    Result := LFingerprint.ToHex;
  finally
    LFingerprint.Free;
    LProbe.Free;
    LRandom.Free;
  end;
end;

class function TGlMathScenarios.FrustumSpheres(const ASubject: IGlMathSubject): string;
var
  LRandom, LProbe: TGlMathRandom;
  LFingerprint: TFingerprint;
  LProjection, LModelView: TGlMatrix4;
  LPair, LCount: Integer;
begin
  LRandom := TGlMathRandom.Create(20240101);
  LProbe := TGlMathRandom.Create(778);
  LFingerprint := TFingerprint.Create;
  try
    for LPair := 0 to MATRIX_PAIRS - 1 do
    begin
      MakeMatrices(LRandom, LPair, LProjection, LModelView);
      ASubject.CalculateFrustum(LProjection, LModelView);
      for LCount := 1 to PROBES do
        LFingerprint.AddBoolean(ASubject.ContainsSphere(LProbe.NextSingle(-300, 300),
          LProbe.NextSingle(-300, 300), LProbe.NextSingle(-300, 300), LProbe.NextSingle(0, 60)));
    end;
    Result := LFingerprint.ToHex;
  finally
    LFingerprint.Free;
    LProbe.Free;
    LRandom.Free;
  end;
end;

class function TGlMathScenarios.FrustumBoxes(const ASubject: IGlMathSubject): string;
var
  LRandom, LProbe: TGlMathRandom;
  LFingerprint: TFingerprint;
  LProjection, LModelView: TGlMatrix4;
  LPair, LCount: Integer;
  LX, LY, LZ: Single;
begin
  LRandom := TGlMathRandom.Create(20240101);
  LProbe := TGlMathRandom.Create(779);
  LFingerprint := TFingerprint.Create;
  try
    for LPair := 0 to MATRIX_PAIRS - 1 do
    begin
      MakeMatrices(LRandom, LPair, LProjection, LModelView);
      ASubject.CalculateFrustum(LProjection, LModelView);
      for LCount := 1 to PROBES do
      begin
        LX := LProbe.NextSingle(-300, 300);
        LY := LProbe.NextSingle(-300, 300);
        LZ := LProbe.NextSingle(-300, 300);
        LFingerprint.AddBoolean(ASubject.ContainsBox(LX, LY, LZ, LX + LProbe.NextSingle(0, 80),
          LY + LProbe.NextSingle(0, 80), LZ + LProbe.NextSingle(0, 80)));
      end;
    end;
    Result := LFingerprint.ToHex;
  finally
    LFingerprint.Free;
    LProbe.Free;
    LRandom.Free;
  end;
end;

class function TGlMathScenarios.FrustumCubes(const ASubject: IGlMathSubject): string;
var
  LRandom, LProbe: TGlMathRandom;
  LFingerprint: TFingerprint;
  LProjection, LModelView: TGlMatrix4;
  LPair, LCount: Integer;
begin
  LRandom := TGlMathRandom.Create(20240101);
  LProbe := TGlMathRandom.Create(780);
  LFingerprint := TFingerprint.Create;
  try
    for LPair := 0 to MATRIX_PAIRS - 1 do
    begin
      MakeMatrices(LRandom, LPair, LProjection, LModelView);
      ASubject.CalculateFrustum(LProjection, LModelView);
      for LCount := 1 to PROBES do
        LFingerprint.AddBoolean(ASubject.ContainsCube(LProbe.NextSingle(-300, 300),
          LProbe.NextSingle(-300, 300), LProbe.NextSingle(-300, 300), LProbe.NextSingle(0, 60)));
    end;
    Result := LFingerprint.ToHex;
  finally
    LFingerprint.Free;
    LProbe.Free;
    LRandom.Free;
  end;
end;

class function TGlMathScenarios.ClipperSequences(const ASubject: IGlMathSubject): string;
var
  LRandom: TGlMathRandom;
  LFingerprint: TFingerprint;
  LSequence, LStep, LKind, LIndex: Integer;
  LStart, LEnd, LWidth: Cardinal;
begin
  LRandom := TGlMathRandom.Create(4242);
  LFingerprint := TFingerprint.Create;
  try
    for LSequence := 0 to CLIPPER_SEQUENCES - 1 do
    begin
      ASubject.ClipperClear;
      for LStep := 0 to CLIPPER_STEPS - 1 do
      begin
        LKind := LRandom.NextInteger(20);
        // different sizes in different sequences: wide ranges fill the list quickly, narrow ones fragment it
        case LSequence mod 4 of
          0: LWidth := LRandom.NextCardinal shr 4;
          1: LWidth := LRandom.NextCardinal shr 12;
          2: LWidth := LRandom.NextCardinal shr 20;
        else
          LWidth := LRandom.NextCardinal shr 8;
        end;
        LStart := RandomAngle(LRandom);
        if LRandom.NextInteger(3) = 0 then
          LEnd := RandomAngle(LRandom)
        else
          LEnd := LStart + LWidth;
        if LKind = 0 then
          ASubject.ClipperClear
        else if LKind < 8 then
          LFingerprint.AddBoolean(ASubject.ClipperSafeCheck(LStart, LEnd))
        else
          ASubject.ClipperSafeAdd(LStart, LEnd);
        if LStep mod 4 = 3 then
        begin
          LFingerprint.AddInteger(ASubject.ClipperCount);
          for LIndex := 0 to ASubject.ClipperCount - 1 do
          begin
            LFingerprint.AddCardinal(ASubject.ClipperStart(LIndex));
            LFingerprint.AddCardinal(ASubject.ClipperFinish(LIndex));
          end;
        end;
      end;
    end;
    Result := LFingerprint.ToHex;
  finally
    LFingerprint.Free;
    LRandom.Free;
  end;
end;

class function TGlMathScenarios.ViewAngles(const ASubject: IGlMathSubject): string;
const
  ASPECTS: array[0..7] of Double = (1.0, 4 / 3, 16 / 9, 0.75, 2.39, 0.5, 3.0, 1.2345);
var
  LFingerprint: TFingerprint;
  LLook, LAspect: Integer;
begin
  LFingerprint := TFingerprint.Create;
  try
    for LAspect := 0 to High(ASPECTS) do
      for LLook := -2400 to 2400 do
        LFingerprint.AddCardinal(ASubject.FrustumAngle(LLook, ASPECTS[LAspect]));
    Result := LFingerprint.ToHex;
  finally
    LFingerprint.Free;
  end;
end;

end.
