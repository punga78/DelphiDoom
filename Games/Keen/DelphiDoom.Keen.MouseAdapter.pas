{******************************************************************************}
{                                                                              }
{  DelphiDoom: keen library - the mouse of Windows as the mouse driver of DOS   }
{  Port of Commander Keen in Keen Dreams (id Software), GPL v2 or later         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.MouseAdapter;

interface

uses
  System.SysUtils, DelphiDoom.Keen.Intf, DelphiDoom.Input.Types, DelphiDoom.Input.Intf;

type
  /// <summary>
  ///   The DOS driver counts how far the mouse moved since the last time that it was asked. The mouse of
  ///   Windows has a position: the movement is the distance from the centre of the screen, and the cursor is
  ///   brought back to the centre after each look. The buttons are the bits 0, 1 and 2 of the driver.
  ///   While the gate is closed (the window is not the one the player is working with) the mouse does not move
  ///   and has no buttons, and the cursor is left alone; when the gate opens the cursor is put at the centre
  ///   before the first look, so that the first movement is not the distance from where the cursor was
  /// </summary>
  TKeenMouseAdapter = class(TInterfacedObject, IKeenMouse)
  strict private
    FMouse: IMouseDevice;
    FScreen: IScreenSize;
    FGate: IInputGate;
    FListening: Boolean;
    function IsAllowed: Boolean;
  public
    /// <param name="AMouse">The cursor, in the coordinates that the screen size is in</param>
    /// <param name="AScreen">The size of the area where the cursor moves: its centre is where it is brought back</param>
    /// <param name="AGate">When the program listens to the mouse (the window in the foreground); nil for always</param>
    constructor Create(const AMouse: IMouseDevice; const AScreen: IScreenSize; const AGate: IInputGate = nil);
    function IsPresent: Boolean;
    procedure GetDelta(out ADeltaX, ADeltaY: Integer);
    function GetButtons: Word;
  end;

implementation

{ TKeenMouseAdapter }

constructor TKeenMouseAdapter.Create(const AMouse: IMouseDevice; const AScreen: IScreenSize;
  const AGate: IInputGate);
begin
  inherited Create;
  if not Assigned(AMouse) then
    raise EArgumentNilException.Create('AMouse');
  if not Assigned(AScreen) then
    raise EArgumentNilException.Create('AScreen');
  FMouse := AMouse;
  FScreen := AScreen;
  FGate := AGate;
  // without a gate the mouse is always listened to, from the first look
  FListening := not Assigned(AGate);
end;

function TKeenMouseAdapter.IsAllowed: Boolean;
begin
  Result := (not Assigned(FGate)) or FGate.IsInputAllowed;
end;

function TKeenMouseAdapter.IsPresent: Boolean;
begin
  Result := True;
end;

procedure TKeenMouseAdapter.GetDelta(out ADeltaX, ADeltaY: Integer);
var
  LX: Integer;
  LY: Integer;
  LCenterX: Integer;
  LCenterY: Integer;
begin
  ADeltaX := 0;
  ADeltaY := 0;
  if not IsAllowed then
  begin
    FListening := False;
    Exit;
  end;
  LCenterX := FScreen.Width div 2;
  LCenterY := FScreen.Height div 2;
  if not FListening then
  begin
    // the window has just got the focus: the cursor is anywhere, the movement starts from the centre
    FListening := True;
    FMouse.SetPosition(LCenterX, LCenterY);
    Exit;
  end;
  FMouse.GetPosition(LX, LY);
  ADeltaX := LX - LCenterX;
  ADeltaY := LY - LCenterY;
  if (ADeltaX <> 0) or (ADeltaY <> 0) then
    FMouse.SetPosition(LCenterX, LCenterY);
end;

function TKeenMouseAdapter.GetButtons: Word;
begin
  Result := 0;
  if not IsAllowed then
    Exit;
  if FMouse.IsButtonDown(TMouseButton.Left) then
    Result := Result or 1;
  if FMouse.IsButtonDown(TMouseButton.Right) then
    Result := Result or 2;
  if FMouse.IsButtonDown(TMouseButton.Middle) then
    Result := Result or 4;
end;

end.
