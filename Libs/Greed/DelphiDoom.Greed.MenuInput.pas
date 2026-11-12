{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the keyboard and the clock of the menus          }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): INT_TimerISR,               }
{  INT_ReadControls and eat_key of d_ints.pas                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.MenuInput;

interface

uses
  System.SysUtils;

const
  /// <summary>NUMCODES: the scan codes of the keyboard table</summary>
  GREED_MENU_SCAN_CODES = 128;
  /// <summary>The scan codes that the menus, the intro and the movies read (SC_* of d_ints_h.pas)</summary>
  GREED_SC_ESCAPE = $01;
  GREED_SC_BACKSPACE = $0E;
  GREED_SC_ENTER = $1C;
  GREED_SC_SPACE = $39;
  GREED_SC_UPARROW = $48;
  GREED_SC_LEFTARROW = $4B;
  GREED_SC_RIGHTARROW = $4D;
  GREED_SC_DOWNARROW = $50;
  GREED_SC_Y = $15;
  GREED_SC_N = $31;

type
  /// <summary>The keys of a menu by name; a letter or a digit is given with ScanCodeOfChar</summary>
  TGreedMenuKey = (gmkUp, gmkDown, gmkLeft, gmkRight, gmkEnter, gmkEscape, gmkSpace, gmkBackspace);

  /// <summary>
  ///   What the timer interrupt of the original leaves to a menu: timecount (70 tics a second), the table keyboard
  ///   (0 up, 1 down, 2 down and already used: eat_key), newascii and lastascii. The program says which keys are
  ///   down (SetKey, by scan code as the original; PressKey by name) and each screen calls TimerTick once a tic: on
  ///   the odd tics the keys are read as INT_ReadControls does (a key that goes down gives its upper case character
  ///   in LastAscii and sets NewAscii; LastAscii is cleared at each read, NewAscii only by who uses it).
  ///   Differences from the original: a key pressed and released between two reads is still seen by the next read
  ///   (the original loses it); the half second without keys after the window gets the focus, the mouse and the
  ///   joystick are not here
  /// </summary>
  TGreedMenuInput = class
  strict private
    FDown: array[0..GREED_MENU_SCAN_CODES - 1] of Boolean;
    FLatched: array[0..GREED_MENU_SCAN_CODES - 1] of Boolean;
    FOldKeyboard: array[0..GREED_MENU_SCAN_CODES - 1] of SmallInt;
    FKeyboard: array[0..GREED_MENU_SCAN_CODES - 1] of SmallInt;
    FTimeCount: Integer;
    FNewAscii: Boolean;
    FLastAscii: AnsiChar;
    function GetKeyboard(AScanCode: Integer): Integer;
  public
    /// <summary>The key with that scan code (0..127) is down or up; other codes are ignored</summary>
    procedure SetKey(AScanCode: Integer; ADown: Boolean);
    /// <summary>The same for a key with a name</summary>
    procedure PressKey(AKey: TGreedMenuKey; ADown: Boolean);
    /// <summary>Every key up, nothing pending (timecount is not changed)</summary>
    procedure ReleaseAll;
    /// <summary>INT_TimerISR without the hook: one more tic, and on the odd tics the keys are read</summary>
    procedure TimerTick;
    /// <summary>INT_ReadControls: the part of the keys</summary>
    procedure ReadControls;
    /// <summary>eat_key: a key that is down (1) becomes used (2) until it is released</summary>
    procedure EatKey(AScanCode: Integer);
    /// <summary>The scan code of a key by name</summary>
    class function ScanCodeOf(AKey: TGreedMenuKey): Integer; static;
    /// <summary>The scan code whose unshifted character (ASCIINames) is that one, without case; -1 if none</summary>
    class function ScanCodeOfChar(ACharacter: Char): Integer; static;
    /// <summary>keyboard[code]: 0, 1 or 2; 0 for a code outside the table</summary>
    property Keyboard[AScanCode: Integer]: Integer read GetKeyboard;
    /// <summary>timecount: the screens compare it and some set it</summary>
    property TimeCount: Integer read FTimeCount write FTimeCount;
    property NewAscii: Boolean read FNewAscii write FNewAscii;
    property LastAscii: AnsiChar read FLastAscii write FLastAscii;
  end;

implementation

const
  // ASCIINames of d_ints.pas: the unshifted character of each scan code
  ASCII_NAMES: array[0..GREED_MENU_SCAN_CODES - 1] of AnsiChar = (
    #0, #27, '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '-', '=', #8, #9,
    'q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p', '[', ']', #13, #0, 'a', 's',
    'd', 'f', 'g', 'h', 'j', 'k', 'l', ';', #39, '`', #0, #92, 'z', 'x', 'c', 'v',
    'b', 'n', 'm', ',', '.', '/', #0, '*', #0, ' ', #0, #0, #0, #0, #0, #0,
    #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, '-', #0, #0, #0, '+', #0,
    #0, #0, #0, #127, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0,
    #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0,
    #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0
  );

  KEY_SCAN_CODES: array[TGreedMenuKey] of Integer = (GREED_SC_UPARROW, GREED_SC_DOWNARROW, GREED_SC_LEFTARROW,
    GREED_SC_RIGHTARROW, GREED_SC_ENTER, GREED_SC_ESCAPE, GREED_SC_SPACE, GREED_SC_BACKSPACE);

{ TGreedMenuInput }

function TGreedMenuInput.GetKeyboard(AScanCode: Integer): Integer;
begin
  if (AScanCode < 0) or (AScanCode >= GREED_MENU_SCAN_CODES) then
    Result := 0
  else
    Result := FKeyboard[AScanCode];
end;

procedure TGreedMenuInput.SetKey(AScanCode: Integer; ADown: Boolean);
begin
  if (AScanCode < 0) or (AScanCode >= GREED_MENU_SCAN_CODES) then
    Exit;
  FDown[AScanCode] := ADown;
  if ADown then
    FLatched[AScanCode] := True;
end;

procedure TGreedMenuInput.PressKey(AKey: TGreedMenuKey; ADown: Boolean);
begin
  SetKey(KEY_SCAN_CODES[AKey], ADown);
end;

procedure TGreedMenuInput.ReleaseAll;
begin
  FillChar(FDown, SizeOf(FDown), 0);
  FillChar(FLatched, SizeOf(FLatched), 0);
  FillChar(FKeyboard, SizeOf(FKeyboard), 0);
  FillChar(FOldKeyboard, SizeOf(FOldKeyboard), 0);
  FNewAscii := False;
  FLastAscii := #0;
end;

procedure TGreedMenuInput.TimerTick;
begin
  Inc(FTimeCount);
  if (FTimeCount and 1) <> 0 then
    ReadControls;
end;

procedure TGreedMenuInput.ReadControls;
var
  LIndex: Integer;
  LCharacter: AnsiChar;
begin
  FLastAscii := #0;
  for LIndex := 0 to GREED_MENU_SCAN_CODES - 1 do
  begin
    if FDown[LIndex] or FLatched[LIndex] then
    begin
      if FKeyboard[LIndex] = 0 then
        FKeyboard[LIndex] := 1;
      if FOldKeyboard[LIndex] = 0 then
      begin
        LCharacter := UpCase(ASCII_NAMES[LIndex]);
        if LCharacter <> #0 then
        begin
          FLastAscii := LCharacter;
          FNewAscii := True;
        end;
      end;
    end
    else
      FKeyboard[LIndex] := 0;
    FLatched[LIndex] := False;
    FOldKeyboard[LIndex] := FKeyboard[LIndex];
  end;
end;

procedure TGreedMenuInput.EatKey(AScanCode: Integer);
begin
  if (AScanCode >= 0) and (AScanCode < GREED_MENU_SCAN_CODES) and (FKeyboard[AScanCode] = 1) then
    FKeyboard[AScanCode] := 2;
end;

class function TGreedMenuInput.ScanCodeOf(AKey: TGreedMenuKey): Integer;
begin
  Result := KEY_SCAN_CODES[AKey];
end;

class function TGreedMenuInput.ScanCodeOfChar(ACharacter: Char): Integer;
var
  LIndex: Integer;
  LWanted: AnsiChar;
begin
  Result := -1;
  if (ACharacter = #0) or (Ord(ACharacter) > 127) then
    Exit;
  LWanted := UpCase(AnsiChar(Ord(ACharacter)));
  for LIndex := 0 to GREED_MENU_SCAN_CODES - 1 do
    if UpCase(ASCII_NAMES[LIndex]) = LWanted then
      Exit(LIndex);
end;

end.
