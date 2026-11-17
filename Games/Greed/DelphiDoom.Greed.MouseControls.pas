{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the mouse among the commands of the game         }
{  Port of xGreed (Jim Valavanis): the call of INT_ReadMouse                    }
{  at the end of INT_ReadControls of d_ints.pas                                 }
{                                                                              }
{  xGreed (Jim Valavanis) and Raven 3D engine (c) 1996 Softdisk Publishing:    }
{  the user declares this port GPL v2 or later; the right on the parts         }
{  derived from the Softdisk code is not verified (docs\LICENZE.md)            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.MouseControls;

interface

uses
  System.SysUtils, DelphiDoom.Greed.PlayerControl.Intf, DelphiDoom.Greed.CommandState, DelphiDoom.Greed.Mouse.Intf;

type
  /// <summary>
  ///   IGreedCommandSource that takes the keys from another source and the mouse from the mouse of the game: at
  ///   each reading of the controls the keys are read first, then the mouse (INT_ReadControls); the buttons and
  ///   the movement are the ones of that reading (mouse.flags, mouse.dx, mouse.dy)
  /// </summary>
  TGreedMouseControls = class(TInterfacedObject, IGreedCommandSource)
  strict private
    FKeys: IGreedCommandSource;
    FMouse: IGreedMouse;
  public
    /// <summary>EArgumentNilException if AKeys or AMouse is nil</summary>
    constructor Create(const AKeys: IGreedCommandSource; const AMouse: IGreedMouse);
    procedure BeginReading;
    function IsPressed(ACommand: TGreedCommand): Boolean;
    function TakeTyped(out ACharacter: Char): Boolean;
    function IsMousePressed(AButton: TGreedMouseButton): Boolean;
    procedure TakeMouseMove(out ADeltaX, ADeltaY: Integer);
  end;

implementation

{ TGreedMouseControls }

constructor TGreedMouseControls.Create(const AKeys: IGreedCommandSource; const AMouse: IGreedMouse);
begin
  inherited Create;
  if not Assigned(AKeys) then
    raise EArgumentNilException.Create('AKeys');
  if not Assigned(AMouse) then
    raise EArgumentNilException.Create('AMouse');
  FKeys := AKeys;
  FMouse := AMouse;
end;

procedure TGreedMouseControls.BeginReading;
begin
  FKeys.BeginReading;
  FMouse.Read;
end;

function TGreedMouseControls.IsPressed(ACommand: TGreedCommand): Boolean;
begin
  Result := FKeys.IsPressed(ACommand);
end;

function TGreedMouseControls.TakeTyped(out ACharacter: Char): Boolean;
begin
  Result := FKeys.TakeTyped(ACharacter);
end;

function TGreedMouseControls.IsMousePressed(AButton: TGreedMouseButton): Boolean;
begin
  Result := FMouse.IsDown(AButton);
end;

procedure TGreedMouseControls.TakeMouseMove(out ADeltaX, ADeltaY: Integer);
begin
  ADeltaX := FMouse.DeltaX;
  ADeltaY := FMouse.DeltaY;
end;

end.
