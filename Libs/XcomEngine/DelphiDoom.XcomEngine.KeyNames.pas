{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom engine library - the names of the keys (SDL_GetKeyName of   }
{  SDL 1.2, the codes that the options store)                                   }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomEngine.KeyNames;

interface

uses
  System.SysUtils;

type
  /// <summary>SDL_GetKeyName on the key codes of SDL 1.2, and the ucWords of OptionsControlsState</summary>
  TXcomKeyNames = class
  public
    /// <summary>The name of the key in lowercase ("return", "page up", "left shift", "a", "unknown key")</summary>
    class function Name(ACode: Integer): string; static;
    /// <summary>OptionsControlsState::ucWords: the first letter of every word in uppercase</summary>
    class function UpperWords(const AText: string): string; static;
    /// <summary>The text shown for a key in the controls list: empty for SDLK_UNKNOWN</summary>
    class function Display(ACode: Integer): string; static;
  end;

implementation

const
  SYMBOLS_32_TO_64: array[0..32] of string = ('space', '!', '"', '#', '$', '%', '&', '''', '(', ')', '*', '+', ',', '-',
    '.', '/', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', ':', ';', '<', '=', '>', '?', '@');
  FUNCTION_KEYS_START = 282;
  MODIFIER_KEYS: array[0..22] of string = ('numlock', 'caps lock', 'scroll lock', 'right shift', 'left shift',
    'right ctrl', 'left ctrl', 'right alt', 'left alt', 'right meta', 'left meta', 'left super', 'right super',
    'alt gr', 'compose', 'help', 'print screen', 'sys req', 'break', 'menu', 'power', 'euro', 'undo');

class function TXcomKeyNames.Name(ACode: Integer): string;
begin
  case ACode of
    8:
      Result := 'backspace';
    9:
      Result := 'tab';
    12:
      Result := 'clear';
    13:
      Result := 'return';
    19:
      Result := 'pause';
    27:
      Result := 'escape';
    32..64:
      Result := SYMBOLS_32_TO_64[ACode - 32];
    91:
      Result := '[';
    92:
      Result := '\';
    93:
      Result := ']';
    94:
      Result := '^';
    95:
      Result := '_';
    96:
      Result := '`';
    97..122:
      Result := Chr(ACode);
    127:
      Result := 'delete';
    160..255:
      Result := 'world ' + IntToStr(ACode - 160);
    256..265:
      Result := '[' + IntToStr(ACode - 256) + ']';
    266:
      Result := '[.]';
    267:
      Result := '[/]';
    268:
      Result := '[*]';
    269:
      Result := '[-]';
    270:
      Result := '[+]';
    271:
      Result := 'enter';
    272:
      Result := 'equals';
    273:
      Result := 'up';
    274:
      Result := 'down';
    275:
      Result := 'right';
    276:
      Result := 'left';
    277:
      Result := 'insert';
    278:
      Result := 'home';
    279:
      Result := 'end';
    280:
      Result := 'page up';
    281:
      Result := 'page down';
    FUNCTION_KEYS_START..296:
      Result := 'f' + IntToStr(ACode - FUNCTION_KEYS_START + 1);
    300..322:
      Result := MODIFIER_KEYS[ACode - 300];
  else
    Result := 'unknown key';
  end;
end;

class function TXcomKeyNames.UpperWords(const AText: string): string;
var
  LIndex: Integer;
begin
  Result := AText;
  if Result = '' then
    Exit;
  Result[1] := UpCase(Result[1]);
  LIndex := Pos(' ', Result);
  while LIndex > 0 do
  begin
    if Length(Result) > LIndex then
      Result[LIndex + 1] := UpCase(Result[LIndex + 1])
    else
      Break;
    LIndex := Pos(' ', Result, LIndex + 1);
  end;
end;

class function TXcomKeyNames.Display(ACode: Integer): string;
begin
  if ACode = 0 then
    Exit('');
  Result := UpperWords(Name(ACode));
end;

end.