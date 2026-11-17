{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the recorded games: a reading of the controls    }
{  as a source of commands                                                      }
{                                                                              }
{  xGreed (Jim Valavanis) and Raven 3D engine (c) 1996 Softdisk Publishing:    }
{  the user declares this port GPL v2 or later; the right on the parts         }
{  derived from the Softdisk code is not verified (docs\LICENZE.md)            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.Demo.Source;

interface

uses
  System.SysUtils, DelphiDoom.Greed.PlayerControl.Intf, DelphiDoom.Greed.CommandState,
  DelphiDoom.Greed.Demo.Types;

type
  /// <summary>
  ///   What the recorder and the player of a tape have in common: the reading of the controls of this moment
  ///   (BeginReading of the descendant sets it with SetReading) is what the game is answered, so that the game that
  ///   is recorded and the game that is played see the same commands, characters and mouse
  /// </summary>
  TGreedDemoSource = class abstract(TInterfacedObject, IGreedCommandSource)
  strict private
    FReading: TGreedDemoReading;
    FTypedPosition: Integer;
    FMoveTaken: Boolean;
  strict protected
    procedure SetReading(const AReading: TGreedDemoReading);
  public
    procedure BeginReading; virtual; abstract;
    function IsPressed(ACommand: TGreedCommand): Boolean;
    function TakeTyped(out ACharacter: Char): Boolean;
    function IsMousePressed(AButton: TGreedMouseButton): Boolean;
    /// <summary>The movement of the reading, once: a second call before the next reading gives 0</summary>
    procedure TakeMouseMove(out ADeltaX, ADeltaY: Integer);
  end;

implementation

procedure TGreedDemoSource.SetReading(const AReading: TGreedDemoReading);
begin
  FReading := AReading;
  FTypedPosition := 1;
  FMoveTaken := False;
end;

function TGreedDemoSource.IsPressed(ACommand: TGreedCommand): Boolean;
begin
  Result := ACommand in FReading.Commands;
end;

function TGreedDemoSource.TakeTyped(out ACharacter: Char): Boolean;
begin
  Result := FTypedPosition <= Length(FReading.Typed);
  if Result then
  begin
    ACharacter := FReading.Typed[FTypedPosition];
    Inc(FTypedPosition);
  end
  else
    ACharacter := #0;
end;

function TGreedDemoSource.IsMousePressed(AButton: TGreedMouseButton): Boolean;
begin
  Result := AButton in FReading.MouseButtons;
end;

procedure TGreedDemoSource.TakeMouseMove(out ADeltaX, ADeltaY: Integer);
begin
  if FMoveTaken then
  begin
    ADeltaX := 0;
    ADeltaY := 0;
    Exit;
  end;
  ADeltaX := FReading.MouseDeltaX;
  ADeltaY := FReading.MouseDeltaY;
  FMoveTaken := True;
end;

end.
