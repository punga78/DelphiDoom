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
  private
    FSystem: IKeyboardSystem;
  public
    /// <summary>Raises EArgumentNilException if ASystem is nil</summary>
    constructor Create(const ASystem: IKeyboardSystem);
    procedure Initialize;
    procedure Shutdown;
    function ReadState(var AStates: TKeyStates): Boolean;
    procedure SetActive(AActive: Boolean);
    function IsCapsLockOn: Boolean;
  end;

implementation

uses
  System.SysUtils, Winapi.Windows;

const
  SSystemIsNil = 'TWindowsKeyboard: the system is nil';

{ TWindowsKeyboard }

constructor TWindowsKeyboard.Create(const ASystem: IKeyboardSystem);
begin
  inherited Create;
  if not Assigned(ASystem) then
    raise EArgumentNilException.Create(SSystemIsNil);
  FSystem := ASystem;
end;

procedure TWindowsKeyboard.Initialize;
begin
end;

procedure TWindowsKeyboard.Shutdown;
begin
end;

function TWindowsKeyboard.ReadState(var AStates: TKeyStates): Boolean;
begin
  // as before: the table is used even if the system refuses to fill it
  FSystem.ReadKeyboardState(AStates);
  Result := True;
end;

procedure TWindowsKeyboard.SetActive(AActive: Boolean);
begin
end;

function TWindowsKeyboard.IsCapsLockOn: Boolean;
begin
  Result := (FSystem.GetKeyState(VK_CAPITAL) and 1) <> 0;
end;

end.
