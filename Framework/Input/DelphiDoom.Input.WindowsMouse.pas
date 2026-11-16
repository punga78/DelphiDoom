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
  DelphiDoom.Input.Types, DelphiDoom.Input.Intf;

type
  /// <summary>The cursor of the system and the buttons with GetKeyState</summary>
  TWindowsMouse = class(TInterfacedObject, IMouseDevice)
  private
    FSystem: ICursorSystem;
  public
    /// <summary>Raises EArgumentNilException if ASystem is nil</summary>
    constructor Create(const ASystem: ICursorSystem);
    procedure Initialize;
    procedure Shutdown;
    procedure GetPosition(out AX, AY: Integer);
    procedure SetPosition(AX, AY: Integer);
    function IsButtonDown(AButton: TMouseButton): Boolean;
  end;

implementation

uses
  System.SysUtils, Winapi.Windows;

const
  SSystemIsNil = 'TWindowsMouse: the system is nil';

{ TWindowsMouse }

constructor TWindowsMouse.Create(const ASystem: ICursorSystem);
begin
  inherited Create;
  if not Assigned(ASystem) then
    raise EArgumentNilException.Create(SSystemIsNil);
  FSystem := ASystem;
end;

procedure TWindowsMouse.Initialize;
begin
  FSystem.Open;
end;

procedure TWindowsMouse.Shutdown;
begin
  FSystem.Close;
end;

procedure TWindowsMouse.GetPosition(out AX, AY: Integer);
begin
  FSystem.GetCursorPosition(AX, AY);
end;

procedure TWindowsMouse.SetPosition(AX, AY: Integer);
begin
  FSystem.SetCursorPosition(AX, AY);
end;

function TWindowsMouse.IsButtonDown(AButton: TMouseButton): Boolean;
const
  LVirtualKeys: array[TMouseButton] of Integer = (VK_LBUTTON, VK_RBUTTON, VK_MBUTTON);
begin
  Result := FSystem.GetKeyState(LVirtualKeys[AButton]) < 0;
end;

end.
