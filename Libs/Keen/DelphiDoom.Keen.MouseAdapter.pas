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
  ///   brought back to the centre after each look. The buttons are the bits 0, 1 and 2 of the driver
  /// </summary>
  TKeenMouseAdapter = class(TInterfacedObject, IKeenMouse)
  strict private
    FMouse: IMouseDevice;
    FScreen: IScreenSize;
  public
    constructor Create(const AMouse: IMouseDevice; const AScreen: IScreenSize);
    function IsPresent: Boolean;
    procedure GetDelta(out ADeltaX, ADeltaY: Integer);
    function GetButtons: Word;
  end;

implementation

{ TKeenMouseAdapter }

constructor TKeenMouseAdapter.Create(const AMouse: IMouseDevice; const AScreen: IScreenSize);
begin
  inherited Create;
  if not Assigned(AMouse) then
    raise EArgumentNilException.Create('AMouse');
  if not Assigned(AScreen) then
    raise EArgumentNilException.Create('AScreen');
  FMouse := AMouse;
  FScreen := AScreen;
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
  LCenterX := FScreen.Width div 2;
  LCenterY := FScreen.Height div 2;
  FMouse.GetPosition(LX, LY);
  ADeltaX := LX - LCenterX;
  ADeltaY := LY - LCenterY;
  if (ADeltaX <> 0) or (ADeltaY <> 0) then
    FMouse.SetPosition(LCenterX, LCenterY);
end;

function TKeenMouseAdapter.GetButtons: Word;
begin
  Result := 0;
  if FMouse.IsButtonDown(TMouseButton.Left) then
    Result := Result or 1;
  if FMouse.IsButtonDown(TMouseButton.Right) then
    Result := Result or 2;
  if FMouse.IsButtonDown(TMouseButton.Middle) then
    Result := Result or 4;
end;

end.
