{******************************************************************************}
{                                                                              }
{  DelphiDoom: input library - the mouse read from Windows                      }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Input.WindowsMouse;

interface

uses
  Winapi.Windows, DelphiDoom.Input.Types, DelphiDoom.Input.Intf;

type
  /// <summary>
  ///   The cursor in physical pixels (GetPhysicalCursorPos, or GetCursorPos on old systems) and
  ///   the buttons with GetKeyState
  /// </summary>
  TWindowsMouse = class(TInterfacedObject, IMouseDevice)
  private
    type
      TGetCursorPosFunc = function(var APoint: TPoint): BOOL; stdcall;
      TSetCursorPosFunc = function(AX, AY: Integer): BOOL; stdcall;
    var
      FUser32: THandle;
      FGetCursorPos: TGetCursorPosFunc;
      FSetCursorPos: TSetCursorPosFunc;
  public
    procedure Initialize;
    procedure Shutdown;
    procedure GetPosition(out AX, AY: Integer);
    procedure SetPosition(AX, AY: Integer);
    function IsButtonDown(AButton: TMouseButton): Boolean;
  end;

implementation

{ TWindowsMouse }

procedure TWindowsMouse.Initialize;
begin
  FUser32 := LoadLibrary(user32);
  FGetCursorPos := GetProcAddress(FUser32, 'GetPhysicalCursorPos');
  if not Assigned(FGetCursorPos) then
    FGetCursorPos := GetProcAddress(FUser32, 'GetCursorPos');
  FSetCursorPos := GetProcAddress(FUser32, 'SetPhysicalCursorPos');
  if not Assigned(FSetCursorPos) then
    FSetCursorPos := GetProcAddress(FUser32, 'SetCursorPos');
end;

procedure TWindowsMouse.Shutdown;
begin
  FreeLibrary(FUser32);
  FUser32 := 0;
end;

procedure TWindowsMouse.GetPosition(out AX, AY: Integer);
var
  LPoint: TPoint;
begin
  FGetCursorPos(LPoint);
  AX := LPoint.X;
  AY := LPoint.Y;
end;

procedure TWindowsMouse.SetPosition(AX, AY: Integer);
begin
  FSetCursorPos(AX, AY);
end;

function TWindowsMouse.IsButtonDown(AButton: TMouseButton): Boolean;
const
  LVirtualKeys: array[TMouseButton] of Integer = (VK_LBUTTON, VK_RBUTTON, VK_MBUTTON);
begin
  Result := GetKeyState(LVirtualKeys[AButton]) < 0;
end;

end.
