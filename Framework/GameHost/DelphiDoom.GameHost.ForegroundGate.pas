{******************************************************************************}
{                                                                              }
{  DelphiDoom: game host library - listen to a device only while the window of  }
{  the game is the one the player is working with                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.GameHost.ForegroundGate;

interface

uses
  System.SysUtils, DelphiDoom.Input.Intf, DelphiDoom.GameHost.Events.Intf;

type
  /// <summary>
  ///   The gate of Framework\Input that is open while the window is in the foreground and not minimized: a joystick (or
  ///   any device that is read when the game asks, not when the window gets a message) must not move a game that
  ///   the player is not looking at
  /// </summary>
  TGameHostForegroundGate = class(TInterfacedObject, IInputGate)
  strict private
    FArea: IGameHostCursorArea;
  public
    /// <param name="AArea">Where the window is; EArgumentNilException if nil</param>
    constructor Create(const AArea: IGameHostCursorArea);
    function IsInputAllowed: Boolean;
  end;

implementation

{ TGameHostForegroundGate }

constructor TGameHostForegroundGate.Create(const AArea: IGameHostCursorArea);
begin
  inherited Create;
  if not Assigned(AArea) then
    raise EArgumentNilException.Create('AArea');
  FArea := AArea;
end;

function TGameHostForegroundGate.IsInputAllowed: Boolean;
begin
  Result := FArea.IsForeground;
end;

end.
