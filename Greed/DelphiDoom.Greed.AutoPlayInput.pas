{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed - an input that plays by itself                            }
{  A test aid of Greed32 (-autoplay): walks forward and turns left now and then }
{  so that a run without a person shows the map and the movement                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.AutoPlayInput;

interface

uses
  System.SysUtils, DelphiDoom.Greed.Frame.Intf;

type
  /// <summary>
  ///   Walks forward; in the frames 60..89 of every 200 it also turns left. The events of the system come from the
  ///   input that it wraps (the window): the player can still close the window or quit
  /// </summary>
  TGreedAutoPlayInput = class(TInterfacedObject, IGreedInput)
  strict private
    FInner: IGreedInput;
    FFrame: Integer;
  public
    constructor Create(const AInner: IGreedInput);
    function Pump: Boolean;
    function IsDown(AKey: TGreedKey): Boolean;
  end;

implementation

{ TGreedAutoPlayInput }

constructor TGreedAutoPlayInput.Create(const AInner: IGreedInput);
begin
  inherited Create;
  if not Assigned(AInner) then
    raise EArgumentNilException.Create('AInner');
  FInner := AInner;
end;

function TGreedAutoPlayInput.Pump: Boolean;
begin
  Inc(FFrame);
  Result := FInner.Pump;
end;

function TGreedAutoPlayInput.IsDown(AKey: TGreedKey): Boolean;
begin
  case AKey of
    gkForward:
      Result := True;
    gkTurnLeft:
      Result := (FFrame mod 200) in [60..89];
  else
    Result := FInner.IsDown(AKey);
  end;
end;

end.
