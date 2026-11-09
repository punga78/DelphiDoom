{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - a movement host for a game without a net         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.MovementHost;

interface

uses
  DelphiDoom.Greed.Types, DelphiDoom.Greed.PlayerMovement;

type
  /// <summary>The game is not in a net game (netmode is false): there is nobody to tell about the doors</summary>
  TGreedMovementHost = class(TInterfacedObject, IGreedMovementHost)
  public
    function GetNetMode: Boolean;
    procedure NetOpenDoor(AX, AY: TGreedFixed);
  end;

implementation

{ TGreedMovementHost }

function TGreedMovementHost.GetNetMode: Boolean;
begin
  Result := False;
end;

procedure TGreedMovementHost.NetOpenDoor(AX, AY: TGreedFixed);
begin
end;

end.
