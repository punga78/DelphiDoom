{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - a random generator with a seed                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Sound.SeededRandom;

interface

uses
  DelphiDoom.War.Sound.Intf;

type
  /// <summary>
  ///   IWarRandom with its own state (no global generator): the same seed gives the same numbers on every
  ///   machine and at 32 and 64 bit. The original uses SDL_rand, which has no seed that can be reproduced
  /// </summary>
  TWarSeededRandom = class(TInterfacedObject, IWarRandom)
  strict private
    FState: Cardinal;
    function NextBits: Cardinal;
  public
    class var
      /// <summary>
      ///   The state after the last draw of any generator: an aid to find where two runs part (the script runner writes it when
      ///   DELPHIDOOM_WAR_RNGTRACE is set); nothing reads it for the game
      /// </summary>
      LastState: Cardinal;
    constructor Create(ASeed: Cardinal);
    function Below(ALimit: Integer): Integer;
  end;

implementation

{$Q-}
{$R-}
// the multiplication of the generator wraps around on purpose

{ TWarSeededRandom }

constructor TWarSeededRandom.Create(ASeed: Cardinal);
begin
  inherited Create;
  FState := ASeed;
end;

function TWarSeededRandom.NextBits: Cardinal;
begin
  // the linear congruential generator of Numerical Recipes; the high bits are the good ones
  FState := FState * 1664525 + 1013904223;
  LastState := FState;
  Result := FState shr 8;
end;

function TWarSeededRandom.Below(ALimit: Integer): Integer;
begin
  if ALimit <= 0 then
    Exit(0);
  Result := Integer(NextBits mod Cardinal(ALimit));
end;

end.
