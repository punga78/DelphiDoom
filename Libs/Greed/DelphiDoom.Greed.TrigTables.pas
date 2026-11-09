{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the trigonometric tables                         }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): RF_Startup of r_public.pas  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.TrigTables;

interface

uses
  DelphiDoom.Greed.Types;

type
  /// <summary>
  ///   sintable and costable of the original: 1024 angles for the full circle, values in 16.16. The original
  ///   pi is 3.14159265 (not the real one) and the rounding is rint = Trunc(x + 0.5): both are kept
  /// </summary>
  TGreedTrigTables = class
  strict private
    class var FSine: array[0..GREED_ANGLES] of TGreedFixed;
    class var FCosine: array[0..GREED_ANGLES] of TGreedFixed;
    class constructor Create;
  public
    /// <summary>sintable[angle]; the angle is taken modulo 1024</summary>
    class function Sine(AAngle: Integer): TGreedFixed; static;
    /// <summary>costable[angle]; the angle is taken modulo 1024</summary>
    class function Cosine(AAngle: Integer): TGreedFixed; static;
  end;

implementation

const
  // g_PI of r_public_h.pas, not Pi
  GREED_PI = 3.14159265;

{ TGreedTrigTables }

class constructor TGreedTrigTables.Create;
var
  LIndex: Integer;
  LAngle: Double;
begin
  for LIndex := 0 to GREED_ANGLES do
  begin
    LAngle := (LIndex * GREED_PI * 2) / (GREED_ANGLES + 1);
    FSine[LIndex] := Trunc(Sin(LAngle) * GREED_FRACUNIT + 0.5);
    FCosine[LIndex] := Trunc(Cos(LAngle) * GREED_FRACUNIT + 0.5);
  end;
end;

class function TGreedTrigTables.Sine(AAngle: Integer): TGreedFixed;
begin
  Result := FSine[AAngle and GREED_ANGLES];
end;

class function TGreedTrigTables.Cosine(AAngle: Integer): TGreedFixed;
begin
  Result := FCosine[AAngle and GREED_ANGLES];
end;

end.
