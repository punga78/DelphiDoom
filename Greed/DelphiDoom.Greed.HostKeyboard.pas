{******************************************************************************}
{                                                                              }
{  DelphiDoom: Greed32 - the keys of the screens on the window of the host      }
{  Port of xGreed (Jim Valavanis, GPL v2 or later)                              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.HostKeyboard;

interface

uses
  Winapi.Windows, System.SysUtils, DelphiDoom.Greed.Application.Intf, DelphiDoom.GameHost.Events.Intf;

type
  /// <summary>
  ///   IGreedKeyboard on the key state of the window of Libs\GameHost: the keys that the menus and the screens read
  ///   (the arrows, Enter, Escape, Space, Backspace, the letters, the digits and the few signs of the names of the
  ///   saved games), each by the scan code of the original
  /// </summary>
  TGreedHostKeyboard = class(TInterfacedObject, IGreedKeyboard)
  strict private
    const
      KEY_COUNT = 128;
    var
      FKeys: IGameHostKeyState;
      FVirtualKeys: array[0..KEY_COUNT - 1] of Integer;
    procedure Bind(AScanCode, AVirtualKey: Integer);
  public
    /// <summary>EArgumentNilException if AKeys is nil</summary>
    constructor Create(const AKeys: IGameHostKeyState);
    function IsDown(AScanCode: Integer): Boolean;
  end;

implementation

uses
  DelphiDoom.Greed.MenuInput;

{ TGreedHostKeyboard }

constructor TGreedHostKeyboard.Create(const AKeys: IGameHostKeyState);
var
  LCharacter: Char;
begin
  inherited Create;
  if not Assigned(AKeys) then
    raise EArgumentNilException.Create('AKeys');
  FKeys := AKeys;
  Bind(GREED_SC_ESCAPE, VK_ESCAPE);
  Bind(GREED_SC_BACKSPACE, VK_BACK);
  Bind(GREED_SC_ENTER, VK_RETURN);
  Bind(GREED_SC_SPACE, VK_SPACE);
  Bind(GREED_SC_UPARROW, VK_UP);
  Bind(GREED_SC_DOWNARROW, VK_DOWN);
  Bind(GREED_SC_LEFTARROW, VK_LEFT);
  Bind(GREED_SC_RIGHTARROW, VK_RIGHT);
  for LCharacter := 'A' to 'Z' do
    Bind(TGreedMenuInput.ScanCodeOfChar(LCharacter), Ord(LCharacter));
  for LCharacter := '0' to '9' do
    Bind(TGreedMenuInput.ScanCodeOfChar(LCharacter), Ord(LCharacter));
  Bind(TGreedMenuInput.ScanCodeOfChar('-'), VK_OEM_MINUS);
  Bind(TGreedMenuInput.ScanCodeOfChar('.'), VK_OEM_PERIOD);
  Bind(TGreedMenuInput.ScanCodeOfChar(','), VK_OEM_COMMA);
end;

procedure TGreedHostKeyboard.Bind(AScanCode, AVirtualKey: Integer);
begin
  if (AScanCode > 0) and (AScanCode < KEY_COUNT) then
    FVirtualKeys[AScanCode] := AVirtualKey;
end;

function TGreedHostKeyboard.IsDown(AScanCode: Integer): Boolean;
begin
  Result := (AScanCode > 0) and (AScanCode < KEY_COUNT) and (FVirtualKeys[AScanCode] <> 0) and
    FKeys.IsDown(FVirtualKeys[AScanCode]);
end;

end.
