{******************************************************************************}
{                                                                              }
{  DelphiDoom: keen library - a script of keys for a run without a player       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.Script;

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.Keen.Types;

const
  /// <summary>The tics between the make code and the break code of a "press"</summary>
  KEEN_SCRIPT_PRESS_TICS = 4;
  /// <summary>The tics that a "press" takes in all: the game sees the key up before the next command</summary>
  KEEN_SCRIPT_PRESS_TOTAL = 8;

type
  TKeenScriptEventKind = (ksePort, kseShot, kseQuit);

  /// <summary>What happens at a tic of the script: a byte of the keyboard port, a picture of the screen, the end</summary>
  TKeenScriptEvent = record
    Tic: Integer;
    Kind: TKeenScriptEventKind;
    /// <summary>ksePort: the byte that the keyboard sends (a make code, or a break code with the bit 7)</summary>
    Port: Byte;
    /// <summary>kseShot: the name of the picture</summary>
    Name: string;
  end;

  /// <summary>
  ///   A script of a run of the game, one command per line: "wait n" lets n tics go by, "press key" pushes a key
  ///   and lets it go, "down key" and "up key" do one of the two, "type text" presses the keys of a text (letters,
  ///   digits and spaces), "shot name" takes a picture of the screen, "quit" ends the program. A line that starts
  ///   with # is a comment. The keys have the names of the PC keyboard: enter, esc, space, up, down, left,
  ///   right, ctrl, alt, lshift, rshift, tab, backspace, f1..f10, pgup, pgdn, home, end, ins, del, the letters
  ///   and the digits
  /// </summary>
  TKeenScript = class
  public
    /// <summary>The events of a script in the order of their tics; a command that is not known is an EKeenException</summary>
    class function Parse(const AText: string): TArray<TKeenScriptEvent>; static;
    /// <summary>The scan code of a key name; false if there is no such key</summary>
    class function TryScanCode(const AName: string; out AScan: Byte): Boolean; static;
  end;

implementation

const
  SScriptBadLine = 'Keen: the line %d of the script is not a command (%s)';
  SScriptBadKey = 'Keen: the line %d of the script names a key that is not known (%s)';

type
  TKeyName = record
    Name: string;
    Scan: Byte;
  end;

const
  KEY_NAMES: array[0..32] of TKeyName = (
    (Name: 'enter'; Scan: $1C), (Name: 'return'; Scan: $1C), (Name: 'esc'; Scan: $01), (Name: 'escape'; Scan: $01),
    (Name: 'space'; Scan: $39), (Name: 'up'; Scan: $48), (Name: 'down'; Scan: $50), (Name: 'left'; Scan: $4B),
    (Name: 'right'; Scan: $4D), (Name: 'ctrl'; Scan: $1D), (Name: 'alt'; Scan: $38), (Name: 'lshift'; Scan: $2A),
    (Name: 'rshift'; Scan: $36), (Name: 'tab'; Scan: $0F), (Name: 'backspace'; Scan: $0E), (Name: 'f1'; Scan: $3B),
    (Name: 'f2'; Scan: $3C), (Name: 'f3'; Scan: $3D), (Name: 'f4'; Scan: $3E), (Name: 'f5'; Scan: $3F),
    (Name: 'f6'; Scan: $40), (Name: 'f7'; Scan: $41), (Name: 'f8'; Scan: $42), (Name: 'f9'; Scan: $43),
    (Name: 'f10'; Scan: $44), (Name: 'pgup'; Scan: $49), (Name: 'pgdn'; Scan: $51), (Name: 'home'; Scan: $47),
    (Name: 'end'; Scan: $4F), (Name: 'ins'; Scan: $52), (Name: 'del'; Scan: $53), (Name: 'capslock'; Scan: $3A),
    (Name: 'pause'; Scan: $45)
  );
  ROW_QWERTY = 'qwertyuiop';
  ROW_ASDF = 'asdfghjkl';
  ROW_ZXCV = 'zxcvbnm';
  ROW_DIGITS = '1234567890';

{ TKeenScript }

class function TKeenScript.TryScanCode(const AName: string; out AScan: Byte): Boolean;
var
  LName: string;
  LIndex: Integer;
  LPosition: Integer;
begin
  LName := LowerCase(Trim(AName));
  for LIndex := Low(KEY_NAMES) to High(KEY_NAMES) do
    if KEY_NAMES[LIndex].Name = LName then
    begin
      AScan := KEY_NAMES[LIndex].Scan;
      Exit(True);
    end;
  Result := False;
  AScan := 0;
  if Length(LName) <> 1 then
    Exit;
  LPosition := Pos(LName, ROW_QWERTY);
  if LPosition > 0 then
  begin
    AScan := $10 + LPosition - 1;
    Exit(True);
  end;
  LPosition := Pos(LName, ROW_ASDF);
  if LPosition > 0 then
  begin
    AScan := $1E + LPosition - 1;
    Exit(True);
  end;
  LPosition := Pos(LName, ROW_ZXCV);
  if LPosition > 0 then
  begin
    AScan := $2C + LPosition - 1;
    Exit(True);
  end;
  LPosition := Pos(LName, ROW_DIGITS);
  if LPosition > 0 then
  begin
    AScan := $02 + LPosition - 1;
    Exit(True);
  end;
end;

class function TKeenScript.Parse(const AText: string): TArray<TKeenScriptEvent>;
var
  LLines: TStringList;
  LLineNumber: Integer;
  LLine: string;
  LCommand: string;
  LArgument: string;
  LSpace: Integer;
  LTic: Integer;
  LCount: Integer;
  LScan: Byte;
  LEvents: TArray<TKeenScriptEvent>;
  LIndex: Integer;

  procedure Add(AKind: TKeenScriptEventKind; APort: Byte; const AName: string);
  begin
    if LCount >= Length(LEvents) then
      SetLength(LEvents, (LCount + 16) * 2);
    LEvents[LCount].Tic := LTic;
    LEvents[LCount].Kind := AKind;
    LEvents[LCount].Port := APort;
    LEvents[LCount].Name := AName;
    Inc(LCount);
  end;

  procedure Press(AScan: Byte);
  begin
    Add(ksePort, AScan, '');
    Inc(LTic, KEEN_SCRIPT_PRESS_TICS);
    Add(ksePort, AScan or $80, '');
    Inc(LTic, KEEN_SCRIPT_PRESS_TOTAL - KEEN_SCRIPT_PRESS_TICS);
  end;

  function NeedKey: Byte;
  begin
    if not TryScanCode(LArgument, Result) then
      raise EKeenException.CreateFmt(SScriptBadKey, [LLineNumber + 1, LArgument]);
  end;

begin
  LCount := 0;
  LTic := 0;
  LLines := TStringList.Create;
  try
    LLines.Text := AText;
    for LLineNumber := 0 to LLines.Count - 1 do
    begin
      LLine := Trim(LLines[LLineNumber]);
      if (LLine = '') or (LLine[1] = '#') then
        Continue;
      LSpace := Pos(' ', LLine);
      if LSpace > 0 then
      begin
        LCommand := LowerCase(Copy(LLine, 1, LSpace - 1));
        LArgument := Trim(Copy(LLine, LSpace + 1, MaxInt));
      end
      else
      begin
        LCommand := LowerCase(LLine);
        LArgument := '';
      end;
      if LCommand = 'wait' then
      begin
        if StrToIntDef(LArgument, -1) < 0 then
          raise EKeenException.CreateFmt(SScriptBadLine, [LLineNumber + 1, LLine]);
        Inc(LTic, StrToIntDef(LArgument, 0));
      end
      else if LCommand = 'press' then
        Press(NeedKey)
      else if LCommand = 'down' then
      begin
        Add(ksePort, NeedKey, '');
        Inc(LTic);
      end
      else if LCommand = 'up' then
      begin
        Add(ksePort, NeedKey or $80, '');
        Inc(LTic);
      end
      else if LCommand = 'type' then
      begin
        for LIndex := 1 to Length(LArgument) do
        begin
          if LArgument[LIndex] = ' ' then
            LScan := $39
          else if not TryScanCode(LArgument[LIndex], LScan) then
            raise EKeenException.CreateFmt(SScriptBadKey, [LLineNumber + 1, LArgument[LIndex]]);
          Press(LScan);
        end;
      end
      else if LCommand = 'shot' then
        Add(kseShot, 0, LArgument)
      else if LCommand = 'quit' then
        Add(kseQuit, 0, '')
      else
        raise EKeenException.CreateFmt(SScriptBadLine, [LLineNumber + 1, LLine]);
    end;
  finally
    LLines.Free;
  end;
  SetLength(LEvents, LCount);
  Result := LEvents;
end;

end.
