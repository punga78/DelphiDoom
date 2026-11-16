{******************************************************************************}
{                                                                              }
{  DelphiDoom: game host library - the keyboard of Windows                      }
{  Derived from the window of Xcom32 (OpenXcom, the OpenXcom Developers),       }
{  GPL v3 or later: see Libs\XcomFormats\README.md for the license of this unit }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.GameHost.Win.Keyboard;

interface

uses
  Winapi.Windows, DelphiDoom.GameHost.Types, DelphiDoom.GameHost.Events.Intf;

type
  /// <summary>IGameHostKeyboard on the keyboard state of the calling thread (GetKeyState and ToUnicode)</summary>
  TGameHostWinKeyboard = class(TInterfacedObject, IGameHostKeyboard)
  public
    function Modifiers: TGameHostModifiers;
    function CharacterOf(AVirtualKey: Cardinal; AScanCode: Cardinal): Cardinal;
  end;

implementation

function TGameHostWinKeyboard.Modifiers: TGameHostModifiers;
begin
  Result := [];
  if GetKeyState(VK_SHIFT) < 0 then
    Include(Result, hmShift);
  if GetKeyState(VK_CONTROL) < 0 then
    Include(Result, hmControl);
  if GetKeyState(VK_MENU) < 0 then
    Include(Result, hmAlt);
end;

function TGameHostWinKeyboard.CharacterOf(AVirtualKey: Cardinal; AScanCode: Cardinal): Cardinal;
var
  LState: TKeyboardState;
  LBuffer: array[0..3] of WideChar;
begin
  Result := 0;
  if not GetKeyboardState(LState) then
    Exit;
  if ToUnicode(AVirtualKey, AScanCode, LState, LBuffer, Length(LBuffer), 0) = 1 then
    if Ord(LBuffer[0]) >= 32 then
      Result := Ord(LBuffer[0]);
end;

end.
