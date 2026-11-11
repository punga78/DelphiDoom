{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom battlescape library - the eight directions                  }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBattle.Directions;

interface

uses
  DelphiDoom.XcomMod.MapBlock;

type
  /// <summary>Pathfinding::directionToVector and vectorToDirection: north is 0 and it goes clockwise</summary>
  TXcomDirections = class
  public
    /// <summary>The vector of a direction 0..9 (8 is up, 9 is down); another number is a range error</summary>
    class function ToVector(ADirection: Integer): TXcomPosition; static;
    /// <summary>The direction 0..7 of a plane vector, or -1</summary>
    class function FromVector(const AVector: TXcomPosition): Integer; static;
  end;

implementation

const
  VECTOR_X: array[0..9] of Integer = (0, 1, 1, 1, 0, -1, -1, -1, 0, 0);
  VECTOR_Y: array[0..9] of Integer = (-1, -1, 0, 1, 1, 1, 0, -1, 0, 0);
  VECTOR_Z: array[0..9] of Integer = (0, 0, 0, 0, 0, 0, 0, 0, 1, -1);

class function TXcomDirections.ToVector(ADirection: Integer): TXcomPosition;
begin
  Result := TXcomPosition.Make(VECTOR_X[ADirection], VECTOR_Y[ADirection], VECTOR_Z[ADirection]);
end;

class function TXcomDirections.FromVector(const AVector: TXcomPosition): Integer;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 7 do
    if (VECTOR_X[LIndex] = AVector.X) and (VECTOR_Y[LIndex] = AVector.Y) then
      Exit(LIndex);
  Result := -1;
end;

end.
