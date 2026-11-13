{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - Quake III player models, the words of a     }
{  text file                                                                   }
{                                                                              }
{  Port of COM_Parse / COM_ParseExt(allowLineBreaks) and Q_stricmp of          }
{  game\q_shared.c. Based on the Quake III Arena GPL Source Code (id           }
{  Software). Copyright (C) 1999-2005 Id Software, Inc. This unit is derived   }
{  from the Quake III Arena source code and is therefore available under the   }
{  GNU General Public License, version 2 or (at your option) any later         }
{  version.                                                                    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Q3Player.TokenReader;

interface

uses
  System.SysUtils;

type
  /// <summary>Where a reader is, to go back to it (the "char *prev" of the original)</summary>
  TQ3TokenState = record
    Position: Integer;
    Ended: Boolean;
  end;

  /// <summary>
  ///   COM_Parse on a text: words separated by blanks (bytes up to 32, which include the line
  ///   breaks), a word in quotes keeps its blanks, "//" and "/* */" are comments. Never fails: at
  ///   the end of the text, and for a word of 1024 characters or more (discarded), the word is empty.
  /// </summary>
  TQ3TokenReader = class
  strict private
    FText: AnsiString;
    FState: TQ3TokenState;
    function CharAt(const APosition: Integer): Integer;
  public
    constructor Create(const AText: AnsiString);
    /// <summary>COM_Parse: the next word</summary>
    function Next: AnsiString;
    function SaveState: TQ3TokenState;
    procedure RestoreState(const AState: TQ3TokenState);
    /// <summary>True once the end of the text was met (the original sets its pointer to NULL)</summary>
    function Ended: Boolean;
    /// <summary>The line (from 1) of the point where the reader is</summary>
    function Line: Integer;
    /// <summary>Q_stricmp = 0: equal ignoring the case of the ASCII letters</summary>
    class function SameWord(const AFirst, ASecond: AnsiString): Boolean; static;
  end;

implementation

const
  // MAX_TOKEN_CHARS
  MAX_TOKEN_CHARS = 1024;

constructor TQ3TokenReader.Create(const AText: AnsiString);
begin
  inherited Create;
  FText := AText;
  FState.Position := 1;
  FState.Ended := False;
end;

// the byte at a position as a signed char; zero at and after the end
function TQ3TokenReader.CharAt(const APosition: Integer): Integer;
begin
  if (APosition < 1) or (APosition > System.Length(FText)) then
    Exit(0);
  Result := ShortInt(Byte(FText[APosition]));
end;

function TQ3TokenReader.SaveState: TQ3TokenState;
begin
  Result := FState;
end;

procedure TQ3TokenReader.RestoreState(const AState: TQ3TokenState);
begin
  FState := AState;
end;

function TQ3TokenReader.Ended: Boolean;
begin
  Result := FState.Ended;
end;

function TQ3TokenReader.Line: Integer;
var
  LIndex, LLast: Integer;
begin
  Result := 1;
  LLast := FState.Position - 1;
  if LLast > System.Length(FText) then
    LLast := System.Length(FText);
  for LIndex := 1 to LLast do
    if FText[LIndex] = #10 then
      Inc(Result);
end;

class function TQ3TokenReader.SameWord(const AFirst, ASecond: AnsiString): Boolean;
var
  LIndex: Integer;
  LFirst, LSecond: AnsiChar;
begin
  if System.Length(AFirst) <> System.Length(ASecond) then
    Exit(False);
  for LIndex := 1 to System.Length(AFirst) do
  begin
    LFirst := AFirst[LIndex];
    LSecond := ASecond[LIndex];
    if LFirst = LSecond then
      Continue;
    if (LFirst >= 'a') and (LFirst <= 'z') then
      LFirst := AnsiChar(Ord(LFirst) - 32);
    if (LSecond >= 'a') and (LSecond <= 'z') then
      LSecond := AnsiChar(Ord(LSecond) - 32);
    if LFirst <> LSecond then
      Exit(False);
  end;
  Result := True;
end;

function TQ3TokenReader.Next: AnsiString;
var
  LPosition, LChar: Integer;
  LWord: AnsiString;
begin
  Result := '';
  if FState.Ended then
    Exit;
  LPosition := FState.Position;
  while True do
  begin
    // skip white space
    while CharAt(LPosition) <= 32 do
    begin
      // the end of the text, or a NUL byte (the end of a C string)
      if CharAt(LPosition) = 0 then
      begin
        FState.Ended := True;
        FState.Position := LPosition;
        Exit;
      end;
      Inc(LPosition);
    end;
    LChar := CharAt(LPosition);
    if (LChar = Ord('/')) and (CharAt(LPosition + 1) = Ord('/')) then
    begin
      Inc(LPosition, 2);
      while (CharAt(LPosition) <> 0) and (CharAt(LPosition) <> 10) do
        Inc(LPosition);
    end
    else if (LChar = Ord('/')) and (CharAt(LPosition + 1) = Ord('*')) then
    begin
      Inc(LPosition, 2);
      while (CharAt(LPosition) <> 0) and ((CharAt(LPosition) <> Ord('*')) or (CharAt(LPosition + 1) <> Ord('/'))) do
        Inc(LPosition);
      if CharAt(LPosition) <> 0 then
        Inc(LPosition, 2);
    end
    else
      Break;
  end;

  LWord := '';
  // a word in quotes
  if LChar = Ord('"') then
  begin
    Inc(LPosition);
    while True do
    begin
      LChar := CharAt(LPosition);
      Inc(LPosition);
      if (LChar = Ord('"')) or (LChar = 0) then
      begin
        FState.Position := LPosition;
        Result := LWord;
        Exit;
      end;
      if System.Length(LWord) < MAX_TOKEN_CHARS then
        LWord := LWord + AnsiChar(Byte(LChar));
    end;
  end;

  // a regular word
  repeat
    if System.Length(LWord) < MAX_TOKEN_CHARS then
      LWord := LWord + AnsiChar(Byte(LChar));
    Inc(LPosition);
    LChar := CharAt(LPosition);
  until LChar <= 32;
  if System.Length(LWord) = MAX_TOKEN_CHARS then
    LWord := '';
  FState.Position := LPosition;
  Result := LWord;
end;

end.
