{******************************************************************************}
{                                                                              }
{  DelphiDoom: input library - the keyboard read from Windows                   }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Input.WindowsKeyboard;

interface

uses
  DelphiDoom.Input.Types, DelphiDoom.Input.Intf;

type
  /// <summary>GetKeyboardState: the keys as the thread of the window sees them</summary>
  TWindowsKeyboard = class(TInterfacedObject, IKeyboardDevice)
  public
    procedure Initialize;
    procedure Shutdown;
    function ReadState(var AStates: TKeyStates): Boolean;
    procedure SetActive(AActive: Boolean);
    function IsCapsLockOn: Boolean;
  end;

implementation

uses
  Winapi.Windows;

{ TWindowsKeyboard }

procedure TWindowsKeyboard.Initialize;
begin
end;

procedure TWindowsKeyboard.Shutdown;
begin
end;

function TWindowsKeyboard.ReadState(var AStates: TKeyStates): Boolean;
var
  LState: TKeyboardState;
begin
  GetKeyboardState(LState);
  Move(LState, AStates, SizeOf(AStates));
  Result := True;
end;

procedure TWindowsKeyboard.SetActive(AActive: Boolean);
begin
end;

function TWindowsKeyboard.IsCapsLockOn: Boolean;
begin
  Result := (GetKeyState(VK_CAPITAL) and 1) <> 0;
end;

end.
