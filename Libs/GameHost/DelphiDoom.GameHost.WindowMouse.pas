{******************************************************************************}
{                                                                              }
{  DelphiDoom: game host library - the mouse of the system as a game reads it,  }
{  inside the window of the game                                                }
{  Born in Greed32 (port of xGreed, Jim Valavanis, GPL v2 or later:             }
{  lbuttondown, rbuttondown and mbuttondown of d_ints.pas, getcursorposfunc,    }
{  setcursorposfunc, I_WindowWidth, I_WindowHeight and the test of the window   }
{  in the foreground of INT_ReadControls) and shared with Keen32 (issue #165)   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.GameHost.WindowMouse;

interface

uses
  System.SysUtils, DelphiDoom.Input.Types, DelphiDoom.Input.Intf, DelphiDoom.GameHost.Types,
  DelphiDoom.GameHost.Events.Intf;

type
  /// <summary>
  ///   The device that the mouse of the game reads, on the window of Libs\GameHost: the cursor comes from the mouse
  ///   of Libs\Input (the cursor of the system, in pixels of the screen) and is given in pixels of the client area
  ///   of the window, so that the middle of the window is where the game puts it back; the three buttons are the
  ///   ones that the window saw go down (they are released when the focus changes, as I_SynchronizeInput does);
  ///   the size is the one of the client area; the program listens while the window is in the foreground.
  ///   Difference from the original: xGreed puts the cursor at half the size of its window counted from the corner
  ///   of the screen, which is the middle of the window only at full screen
  /// </summary>
  TGameHostWindowMouse = class(TInterfacedObject, IMouseDevice, IScreenSize, IInputGate)
  strict private
    FCursor: IMouseDevice;
    FArea: IGameHostCursorArea;
    FButtons: IGameHostMouseState;
  public
    /// <summary>EArgumentNilException if one is nil</summary>
    /// <param name="ACursor">The cursor of the system</param>
    /// <param name="AArea">Where the client area of the window is on the screen</param>
    /// <param name="AButtons">The buttons that the window says are down</param>
    constructor Create(const ACursor: IMouseDevice; const AArea: IGameHostCursorArea;
      const AButtons: IGameHostMouseState);
    // IMouseDevice
    procedure Initialize;
    procedure Shutdown;
    procedure GetPosition(out AX, AY: Integer);
    procedure SetPosition(AX, AY: Integer);
    function IsButtonDown(AButton: TMouseButton): Boolean;
    // IScreenSize
    function GetWidth: Integer;
    function GetHeight: Integer;
    // IInputGate
    function IsInputAllowed: Boolean;
  end;

implementation

const
  HOST_BUTTONS: array[TMouseButton] of TGameHostMouseButton = (hmbLeft, hmbRight, hmbMiddle);

{ TGameHostWindowMouse }

constructor TGameHostWindowMouse.Create(const ACursor: IMouseDevice; const AArea: IGameHostCursorArea;
  const AButtons: IGameHostMouseState);
begin
  inherited Create;
  if not Assigned(ACursor) then
    raise EArgumentNilException.Create('ACursor');
  if not Assigned(AArea) then
    raise EArgumentNilException.Create('AArea');
  if not Assigned(AButtons) then
    raise EArgumentNilException.Create('AButtons');
  FCursor := ACursor;
  FArea := AArea;
  FButtons := AButtons;
end;

procedure TGameHostWindowMouse.Initialize;
begin
  FCursor.Initialize;
end;

procedure TGameHostWindowMouse.Shutdown;
begin
  FCursor.Shutdown;
end;

procedure TGameHostWindowMouse.GetPosition(out AX, AY: Integer);
var
  LOriginX: Integer;
  LOriginY: Integer;
begin
  FCursor.GetPosition(AX, AY);
  if FArea.ClientOrigin(LOriginX, LOriginY) then
  begin
    AX := AX - LOriginX;
    AY := AY - LOriginY;
  end;
end;

procedure TGameHostWindowMouse.SetPosition(AX, AY: Integer);
var
  LOriginX: Integer;
  LOriginY: Integer;
begin
  // without a window there is no place to put the cursor
  if FArea.ClientOrigin(LOriginX, LOriginY) then
    FCursor.SetPosition(AX + LOriginX, AY + LOriginY);
end;

function TGameHostWindowMouse.IsButtonDown(AButton: TMouseButton): Boolean;
begin
  Result := FButtons.IsDown(HOST_BUTTONS[AButton]);
end;

function TGameHostWindowMouse.GetWidth: Integer;
begin
  Result := FArea.ClientWidth;
end;

function TGameHostWindowMouse.GetHeight: Integer;
begin
  Result := FArea.ClientHeight;
end;

function TGameHostWindowMouse.IsInputAllowed: Boolean;
begin
  Result := FArea.IsForeground;
end;

end.
