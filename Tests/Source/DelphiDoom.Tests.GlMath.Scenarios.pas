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
    function NextInteger(const ARange: Integer): Integer;
  end;

  TGlMathScenarios = class
  public
    /// <summary>Sequences of adds, checks and clears with ranges of all sizes; the list after each step</summary>
    class function ClipperSequences(const ASubject: IGlMathSubject): string; static;
    /// <summary>The view angle for a sweep of look directions and some aspects</summary>
    class function ViewAngles(const ASubject: IGlMathSubject): string; static;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Tests.GlMath.Fingerprint;

const
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

function TGlMathRandom.NextInteger(const ARange: Integer): Integer;
begin
  Result := Integer(NextCardinal mod Cardinal(ARange));
end;

{ helpers }

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
