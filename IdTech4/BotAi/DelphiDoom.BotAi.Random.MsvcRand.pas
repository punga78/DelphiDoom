{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - TBotMsvcRandom, srand and rand of the Microsoft C      }
{  runtime as the chat of Quake III Arena used them                             }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software):                 }
{  random() = (rand() & 0x7fff) / (float)0x7fff, code\game\q_shared.h.         }
{  Licensed under the GNU General Public License, version 2 or later.          }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Random.MsvcRand;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.BotAi.Import.Intf;

type
  /// <summary>
  ///   The linear congruential generator of the Microsoft C runtime (the state is the one of the
  ///   object, not global), so a seed gives the sequence of the original on Windows.
  /// </summary>
  TBotMsvcRandom = class(TInterfacedObject, IBotRandom)
  strict private
    FState: Cardinal;
  public
    /// <summary>srand(seed)</summary>
    constructor Create(const ASeed: Cardinal = 1);
    /// <summary>srand</summary>
    procedure SetSeed(const ASeed: Cardinal);
    /// <summary>rand(): 0..32767</summary>
    function Rand: Integer;
    /// <summary>random()</summary>
    function NextFloat: Single;
  end;

implementation

{ TBotMsvcRandom }

constructor TBotMsvcRandom.Create(const ASeed: Cardinal);
begin
  inherited Create;
  FState := ASeed;
end;

procedure TBotMsvcRandom.SetSeed(const ASeed: Cardinal);
begin
  FState := ASeed;
end;

function TBotMsvcRandom.Rand: Integer;
begin
  FState := FState * 214013 + 2531011;
  Result := (FState shr 16) and $7FFF;
end;

function TBotMsvcRandom.NextFloat: Single;
var
  LValue: Single;
  LDivisor: Single;
begin
  LValue := Rand;
  LDivisor := $7FFF;
  Result := LValue / LDivisor;
end;

end.
