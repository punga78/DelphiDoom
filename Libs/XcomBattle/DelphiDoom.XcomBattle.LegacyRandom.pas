{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom battlescape library - the C library rand() of the look      }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBattle.LegacyRandom;

interface

type
  /// <summary>
  ///   The rand() of the C library (the linear congruential generator of msvcrt and ucrt), that OpenXcom calls
  ///   with std::rand for the colors of the units. It never decides what happens in the battle, only how a unit
  ///   looks, and it is seeded by the caller (srand)
  /// </summary>
  TXcomLegacyRandom = class
  strict private
    FState: Cardinal;
  public
    constructor Create(ASeed: Cardinal);
    /// <summary>srand</summary>
    procedure Seed(ASeed: Cardinal);
    /// <summary>rand: from 0 to 32767</summary>
    function Next: Integer;
  end;

implementation

constructor TXcomLegacyRandom.Create(ASeed: Cardinal);
begin
  inherited Create;
  FState := ASeed;
end;

procedure TXcomLegacyRandom.Seed(ASeed: Cardinal);
begin
  FState := ASeed;
end;

function TXcomLegacyRandom.Next: Integer;
begin
  FState := Cardinal((UInt64(FState) * 214013 + 2531011) and $FFFFFFFF);
  Result := (FState shr 16) and $7FFF;
end;

end.
