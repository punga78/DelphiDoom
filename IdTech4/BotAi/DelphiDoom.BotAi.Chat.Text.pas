{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - TBotChatText, the string rules of the chat             }
{                                                                              }
{  Port of Quake III Arena (id Software, GPL v2 or later): IsWhiteSpace,       }
{  BotRemoveTildes, UnifyWhiteSpaces, StringContains, StringContainsWord and   }
{  StringReplaceWords of code\botlib\be_ai_chat.c. Based on the Quake III      }
{  Arena GPL Source Code (id Software). Copyright (C) 1999-2005 Id Software.   }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Chat.Text;

{$Q-}
{$R-}

interface

uses
  System.SysUtils;

type
  /// <summary>
  ///   The functions on C strings of the chat. Positions are 0-based as the pointers of the original; a
  ///   character after the end reads as zero. The original works in place: the strings are shifted
  ///   exactly as it does (UnifyWhiteSpaces keeps its defect, see the README).
  /// </summary>
  TBotChatText = class
  public
    /// <summary>The character at a 0-based position, #0 after the end</summary>
    class function CharAt(const AText: AnsiString; const APosition: Integer): AnsiChar; static;
    /// <summary>A char of C (signed): the bytes from 128 are negative</summary>
    class function SignedChar(const AChar: AnsiChar): Integer; static;
    /// <summary>toupper in the C locale</summary>
    class function UpperAscii(const AChar: AnsiChar): AnsiChar; static;
    /// <summary>Q_stricmp = 0: equal without case (ASCII)</summary>
    class function SameTextAscii(const ALeft, ARight: AnsiString): Boolean; static;
    /// <summary>IsWhiteSpace: everything but letters, digits and ( ) ? : ' / , . [ ] - _ + =</summary>
    class function IsWhiteSpace(const AChar: AnsiChar): Boolean; static;
    /// <summary>BotRemoveTildes</summary>
    class function RemoveTildes(const AText: AnsiString): AnsiString; static;
    /// <summary>UnifyWhiteSpaces</summary>
    class function UnifyWhiteSpaces(const AText: AnsiString): AnsiString; static;
    /// <summary>StringContains: the index of the second string in the first, -1 if missing</summary>
    class function StringContains(const AText, AFind: AnsiString; const ACaseSensitive: Boolean): Integer; static;
    /// <summary>StringContainsWord: the index of the word in the text, -1 if missing</summary>
    class function StringContainsWord(const AText, AWord: AnsiString; const ACaseSensitive: Boolean): Integer; static;
    /// <summary>StringReplaceWords</summary>
    class function ReplaceWords(const AText, ASynonym, AReplacement: AnsiString): AnsiString; static;
  end;

implementation

{ TBotChatText }

class function TBotChatText.CharAt(const AText: AnsiString; const APosition: Integer): AnsiChar;
begin
  if (APosition >= 0) and (APosition < Length(AText)) then
    Result := AText[APosition + 1]
  else
    Result := #0;
end;

class function TBotChatText.SignedChar(const AChar: AnsiChar): Integer;
begin
  Result := ShortInt(Byte(AChar));
end;

class function TBotChatText.UpperAscii(const AChar: AnsiChar): AnsiChar;
begin
  if (AChar >= 'a') and (AChar <= 'z') then
    Result := AnsiChar(Byte(AChar) - 32)
  else
    Result := AChar;
end;

class function TBotChatText.SameTextAscii(const ALeft, ARight: AnsiString): Boolean;
var
  LIndex: Integer;
begin
  if Length(ALeft) <> Length(ARight) then
    Exit(False);
  for LIndex := 1 to Length(ALeft) do
  begin
    if UpperAscii(ALeft[LIndex]) <> UpperAscii(ARight[LIndex]) then
      Exit(False);
  end;
  Result := True;
end;

class function TBotChatText.IsWhiteSpace(const AChar: AnsiChar): Boolean;
begin
  case AChar of
    'a'..'z', 'A'..'Z', '0'..'9', '(', ')', '?', ':', '''', '/', ',', '.', '[', ']', '-', '_', '+', '=':
      Result := False;
  else
    Result := True;
  end;
end;

class function TBotChatText.RemoveTildes(const AText: AnsiString): AnsiString;
var
  LIndex: Integer;
begin
  Result := AText;
  LIndex := 0;
  // the character moved to the place of a removed tilde is not looked at (the for of the original goes on)
  while CharAt(Result, LIndex) <> #0 do
  begin
    if Result[LIndex + 1] = '~' then
      Delete(Result, LIndex + 1, 1);
    Inc(LIndex);
  end;
end;

class function TBotChatText.UnifyWhiteSpaces(const AText: AnsiString): AnsiString;
var
  LBuffer: TBytes;
  LPointer: Integer;
  LOldPointer: Integer;
  LRestLength: Integer;
begin
  // a zero-terminated buffer edited in place: the bytes behind the new end stay as they were, and
  // the original keeps scanning from the old pointer, so it can read them
  SetLength(LBuffer, Length(AText) + 1);
  if Length(AText) > 0 then
    Move(AText[1], LBuffer[0], Length(AText));
  LPointer := 0;
  LOldPointer := 0;
  while LBuffer[LPointer] <> 0 do
  begin
    while (LBuffer[LPointer] <> 0) and IsWhiteSpace(AnsiChar(LBuffer[LPointer])) do
      Inc(LPointer);
    if LPointer > LOldPointer then
    begin
      // if not at the start and not at the end of the string write only one space
      if (LOldPointer > 0) and (LBuffer[LPointer] <> 0) then
      begin
        LBuffer[LOldPointer] := Ord(' ');
        Inc(LOldPointer);
      end;
      // memmove(oldptr, ptr, strlen(ptr) + 1): ptr is not moved, as in the original
      if LPointer > LOldPointer then
      begin
        LRestLength := 0;
        while LBuffer[LPointer + LRestLength] <> 0 do
          Inc(LRestLength);
        Move(LBuffer[LPointer], LBuffer[LOldPointer], LRestLength + 1);
      end;
    end;
    while (LBuffer[LPointer] <> 0) and not IsWhiteSpace(AnsiChar(LBuffer[LPointer])) do
      Inc(LPointer);
    LOldPointer := LPointer;
  end;
  LRestLength := 0;
  while LBuffer[LRestLength] <> 0 do
    Inc(LRestLength);
  SetLength(Result, LRestLength);
  if LRestLength > 0 then
    Move(LBuffer[0], Result[1], LRestLength);
end;

class function TBotChatText.StringContains(const AText, AFind: AnsiString; const ACaseSensitive: Boolean): Integer;
var
  LLength: Integer;
  LIndex: Integer;
  LCharIndex: Integer;
  LLeft: AnsiChar;
  LRight: AnsiChar;
begin
  LLength := Length(AText) - Length(AFind);
  for LIndex := 0 to LLength do
  begin
    LCharIndex := 0;
    while LCharIndex < Length(AFind) do
    begin
      LLeft := AText[LIndex + LCharIndex + 1];
      LRight := AFind[LCharIndex + 1];
      if not ACaseSensitive then
      begin
        LLeft := UpperAscii(LLeft);
        LRight := UpperAscii(LRight);
      end;
      if LLeft <> LRight then
        Break;
      Inc(LCharIndex);
    end;
    if LCharIndex = Length(AFind) then
      Exit(LIndex);
  end;
  Result := -1;
end;

class function TBotChatText.StringContainsWord(const AText, AWord: AnsiString; const ACaseSensitive: Boolean): Integer;
var
  LLength: Integer;
  LIndex: Integer;
  LPosition: Integer;
  LCharIndex: Integer;
  LLeft: AnsiChar;
  LRight: AnsiChar;
  LNext: AnsiChar;
begin
  LLength := Length(AText) - Length(AWord);
  LPosition := 0;
  LIndex := 0;
  while LIndex <= LLength do
  begin
    // if not at the start of the string skip to the start of the next word
    if LIndex > 0 then
    begin
      while (CharAt(AText, LPosition) <> #0) and not (CharAt(AText, LPosition) in [' ', '.', ',', '!']) do
        Inc(LPosition);
      if CharAt(AText, LPosition) = #0 then
        Break;
      Inc(LPosition);
    end;
    LCharIndex := 0;
    while LCharIndex < Length(AWord) do
    begin
      LLeft := CharAt(AText, LPosition + LCharIndex);
      LRight := AWord[LCharIndex + 1];
      if not ACaseSensitive then
      begin
        LLeft := UpperAscii(LLeft);
        LRight := UpperAscii(LRight);
      end;
      if LLeft <> LRight then
        Break;
      Inc(LCharIndex);
    end;
    if LCharIndex = Length(AWord) then
    begin
      // if the first string has an end of word
      LNext := CharAt(AText, LPosition + LCharIndex);
      if LNext in [#0, ' ', '.', ',', '!'] then
        Exit(LPosition);
    end;
    Inc(LIndex);
    Inc(LPosition);
  end;
  Result := -1;
end;

class function TBotChatText.ReplaceWords(const AText, ASynonym, AReplacement: AnsiString): AnsiString;
var
  LString: Integer;
  LReplacementPosition: Integer;
  LRelative: Integer;
begin
  Result := AText;
  LString := StringContainsWord(Result, ASynonym, False);
  while LString >= 0 do
  begin
    // the synonym is not replaced if it is part of the replacement already in the string (abbreviations)
    LReplacementPosition := StringContainsWord(Result, AReplacement, False);
    while LReplacementPosition >= 0 do
    begin
      if (LReplacementPosition <= LString) and (LString < LReplacementPosition + Length(AReplacement)) then
        Break;
      LRelative := StringContainsWord(Copy(Result, LReplacementPosition + 2, MaxInt), AReplacement, False);
      if LRelative < 0 then
        LReplacementPosition := -1
      else
        LReplacementPosition := LReplacementPosition + 1 + LRelative;
    end;
    if LReplacementPosition < 0 then
      Result := Copy(Result, 1, LString) + AReplacement + Copy(Result, LString + Length(ASynonym) + 1, MaxInt);
    LRelative := StringContainsWord(Copy(Result, LString + Length(AReplacement) + 1, MaxInt), ASynonym, False);
    if LRelative < 0 then
      LString := -1
    else
      LString := LString + Length(AReplacement) + LRelative;
  end;
end;

end.
