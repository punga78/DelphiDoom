{******************************************************************************}
{                                                                              }
{  DelphiDoom: idLib text - the static string functions of idStr               }
{                                                                              }
{  Port of idLib (id Software, Doom 3, GPL v3): the static methods of idStr    }
{  (idlib\Str.h, Str.cpp), plus the helpers they use. Copyright (C) 1999-2011  }
{  id Software LLC, a ZeniMax Media company.                                   }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.IdLib.Text.Strings;

{$Q-}
{$R-}

interface

type
  /// <summary>
  ///   The static functions of idStr on 8-bit strings (AnsiString). They behave like the C ones:
  ///   a string ends at its length (or at the first #0), a character is a signed byte (as the
  ///   <c>char</c> of the original compiler: bytes above 127 sort before the ASCII letters),
  ///   comparisons return -1, 0 or 1, and case folding is ASCII only unless noted.
  /// </summary>
  TIdStrings = class
  public
    /// <summary>idStr::Length: the length up to the first #0</summary>
    class function Length(const AText: AnsiString): Integer; static;
    /// <summary>The signed byte at a 0-based index, 0 past the end (the NUL terminator of C)</summary>
    class function CharAt(const AText: AnsiString; const AIndex: Integer): Integer; static;

    /// <summary>idStr::Cmp (case sensitive)</summary>
    class function Cmp(const AText1, AText2: AnsiString): Integer; static;
    /// <summary>idStr::Cmpn: only the first <c>ACount</c> characters</summary>
    class function Cmpn(const AText1, AText2: AnsiString; const ACount: Integer): Integer; static;
    /// <summary>idStr::Icmp (ASCII case insensitive)</summary>
    class function Icmp(const AText1, AText2: AnsiString): Integer; static;
    class function Icmpn(const AText1, AText2: AnsiString; const ACount: Integer): Integer; static;
    /// <summary>idStr::IcmpNoColor: ignores the ^c colour escapes</summary>
    class function IcmpNoColor(const AText1, AText2: AnsiString): Integer; static;
    /// <summary>idStr::IcmpPath: backslash equals slash and the folders come first</summary>
    class function IcmpPath(const AText1, AText2: AnsiString): Integer; static;
    class function IcmpnPath(const AText1, AText2: AnsiString; const ACount: Integer): Integer; static;

    /// <summary>idStr::FindChar: the index of the character or -1 (AEnd = -1: to the end)</summary>
    class function FindChar(const AText: AnsiString; const AChar: AnsiChar; const AStart: Integer = 0;
      const AEnd: Integer = -1): Integer; static;
    /// <summary>idStr::FindText</summary>
    class function FindText(const AText, ASubText: AnsiString; const ACaseSensitive: Boolean = True;
      const AStart: Integer = 0; const AEnd: Integer = -1): Integer; static;
    /// <summary>idStr::Filter: wildcards *, ?, [abc] and [a-z], doubled [[ and ]] for the brackets</summary>
    class function Filter(const AFilter, AName: AnsiString; const ACaseSensitive: Boolean): Boolean; static;

    /// <summary>idStr::IsNumeric: optional minus, digits, at most one dot (an empty string is numeric)</summary>
    class function IsNumeric(const AText: AnsiString): Boolean; static;
    /// <summary>idStr::IsColor: the string starts with ^ followed by a character that is not a space</summary>
    class function IsColor(const AText: AnsiString; const AIndex: Integer = 0): Boolean; static;
    class function HasLower(const AText: AnsiString): Boolean; static;
    class function HasUpper(const AText: AnsiString): Boolean; static;
    class function LengthWithoutColors(const AText: AnsiString): Integer; static;
    class function RemoveColors(const AText: AnsiString): AnsiString; static;
    /// <summary>idStr::ToLower(char*): also folds the Latin-1 capitals 0xC0..0xDF as the original</summary>
    class function ToLower(const AText: AnsiString): AnsiString; overload; static;
    class function ToUpper(const AText: AnsiString): AnsiString; overload; static;
    /// <summary>idStr::ToLower(char): A..Z only</summary>
    class function ToLower(const AChar: AnsiChar): AnsiChar; overload; static;
    class function ToUpper(const AChar: AnsiChar): AnsiChar; overload; static;

    /// <summary>idStr::Hash: sum of signed character times (index + 119)</summary>
    class function Hash(const AText: AnsiString): Integer; overload; static;
    class function Hash(const AText: AnsiString; const ALength: Integer): Integer; overload; static;
    /// <summary>idStr::IHash: the same on the lower case characters</summary>
    class function IHash(const AText: AnsiString): Integer; overload; static;
    class function IHash(const AText: AnsiString; const ALength: Integer): Integer; overload; static;
    /// <summary>idStr::FileNameHash: lower case, backslash as slash, stops at the first dot, masked to 1023</summary>
    class function FileNameHash(const AText: AnsiString): Integer; static;

    class function CharIsPrintable(const AChar: Integer): Boolean; static;
    class function CharIsLower(const AChar: Integer): Boolean; static;
    class function CharIsUpper(const AChar: Integer): Boolean; static;
    class function CharIsAlpha(const AChar: Integer): Boolean; static;
    class function CharIsNumeric(const AChar: Integer): Boolean; static;
    class function CharIsNewLine(const AChar: AnsiChar): Boolean; static;
    class function CharIsTab(const AChar: AnsiChar): Boolean; static;
    class function ColorIndex(const AChar: Integer): Integer; static;

    /// <summary>idStr::StripMediaName: lower case, slashes, stops at the first dot</summary>
    class function StripMediaName(const AName: AnsiString): AnsiString; static;
    /// <summary>idStr::CheckExtension: does the name end with the extension (case insensitive)</summary>
    class function CheckExtension(const AName, AExtension: AnsiString): Boolean; static;
    /// <summary>
    ///   idStr::FloatArrayToString: the floats with <c>APrecision</c> decimals, trailing zeros and
    ///   dot removed, separated by spaces
    /// </summary>
    class function FloatArrayToString(const AValues: array of Single; const APrecision: Integer): AnsiString; static;
    /// <summary>
    ///   The "%.Nf" of the C library for a float: the exact binary value rounded to N decimals with ties
    ///   to even (0.5 gives "0", 2.5 gives "2") and a minus sign for any negative value, also when the
    ///   result is zero. Exact for N up to 9; outside that, the RTL formatting is used.
    /// </summary>
    class function FormatFixed(const AValue: Single; const APrecision: Integer): AnsiString; static;
    /// <summary>The text idStr(float) gives: "%f" without trailing zeros and dot</summary>
    class function FloatToText(const AValue: Single): AnsiString; static;
    /// <summary>The text operator+(idStr, float) appends: plain "%f"</summary>
    class function FloatToPlainText(const AValue: Single): AnsiString; static;
    /// <summary>idStr::FormatNumber: thousands separated by commas, padded to 11 characters</summary>
    class function FormatNumber(const ANumber: Integer): AnsiString; static;
  end;

const
  /// <summary>C_COLOR_ESCAPE of idStr</summary>
  ID_COLOR_ESCAPE = '^';
  /// <summary>FILE_HASH_SIZE of idStr</summary>
  ID_FILE_HASH_SIZE = 1024;

implementation

uses
  System.SysUtils;

function IntSign(const ADifference: Integer): Integer; inline;
begin
  // (INTSIGNBITNOTSET( d ) << 1 ) - 1
  if ADifference >= 0 then
    Result := 1
  else
    Result := -1;
end;

{ TIdStrings }

class function TIdStrings.CharAt(const AText: AnsiString; const AIndex: Integer): Integer;
begin
  if (AIndex < 0) or (AIndex >= System.Length(AText)) then
    Result := 0
  else
    Result := ShortInt(Byte(AText[AIndex + 1]));
end;

class function TIdStrings.Length(const AText: AnsiString): Integer;
begin
  Result := 0;
  while (Result < System.Length(AText)) and (AText[Result + 1] <> #0) do
    Inc(Result);
end;

class function TIdStrings.Cmp(const AText1, AText2: AnsiString): Integer;
var
  LIndex, LChar1, LChar2, LDifference: Integer;
begin
  LIndex := 0;
  repeat
    LChar1 := CharAt(AText1, LIndex);
    LChar2 := CharAt(AText2, LIndex);
    Inc(LIndex);
    LDifference := LChar1 - LChar2;
    if LDifference <> 0 then
      Exit(IntSign(LDifference));
  until LChar1 = 0;
  Result := 0;
end;

class function TIdStrings.Cmpn(const AText1, AText2: AnsiString; const ACount: Integer): Integer;
var
  LIndex, LChar1, LChar2, LDifference, LCount: Integer;
begin
  LIndex := 0;
  LCount := ACount;
  repeat
    LChar1 := CharAt(AText1, LIndex);
    LChar2 := CharAt(AText2, LIndex);
    Inc(LIndex);
    Dec(LCount);
    if LCount < 0 then
      Exit(0);
    LDifference := LChar1 - LChar2;
    if LDifference <> 0 then
      Exit(IntSign(LDifference));
  until LChar1 = 0;
  Result := 0;
end;

class function TIdStrings.Icmp(const AText1, AText2: AnsiString): Integer;
var
  LIndex, LChar1, LChar2, LDifference: Integer;
begin
  LIndex := 0;
  repeat
    LChar1 := CharAt(AText1, LIndex);
    LChar2 := CharAt(AText2, LIndex);
    Inc(LIndex);
    LDifference := LChar1 - LChar2;
    while LDifference <> 0 do
    begin
      if (LChar1 <= Ord('Z')) and (LChar1 >= Ord('A')) then
      begin
        Inc(LDifference, Ord('a') - Ord('A'));
        if LDifference = 0 then
          Break;
      end;
      if (LChar2 <= Ord('Z')) and (LChar2 >= Ord('A')) then
      begin
        Dec(LDifference, Ord('a') - Ord('A'));
        if LDifference = 0 then
          Break;
      end;
      Exit(IntSign(LDifference));
    end;
  until LChar1 = 0;
  Result := 0;
end;

class function TIdStrings.Icmpn(const AText1, AText2: AnsiString; const ACount: Integer): Integer;
var
  LIndex, LChar1, LChar2, LDifference, LCount: Integer;
begin
  LIndex := 0;
  LCount := ACount;
  repeat
    LChar1 := CharAt(AText1, LIndex);
    LChar2 := CharAt(AText2, LIndex);
    Inc(LIndex);
    Dec(LCount);
    if LCount < 0 then
      Exit(0);
    LDifference := LChar1 - LChar2;
    while LDifference <> 0 do
    begin
      if (LChar1 <= Ord('Z')) and (LChar1 >= Ord('A')) then
      begin
        Inc(LDifference, Ord('a') - Ord('A'));
        if LDifference = 0 then
          Break;
      end;
      if (LChar2 <= Ord('Z')) and (LChar2 >= Ord('A')) then
      begin
        Dec(LDifference, Ord('a') - Ord('A'));
        if LDifference = 0 then
          Break;
      end;
      Exit(IntSign(LDifference));
    end;
  until LChar1 = 0;
  Result := 0;
end;

class function TIdStrings.IcmpNoColor(const AText1, AText2: AnsiString): Integer;
var
  LIndex1, LIndex2, LChar1, LChar2, LDifference: Integer;
begin
  LIndex1 := 0;
  LIndex2 := 0;
  repeat
    while IsColor(AText1, LIndex1) do
      Inc(LIndex1, 2);
    while IsColor(AText2, LIndex2) do
      Inc(LIndex2, 2);
    LChar1 := CharAt(AText1, LIndex1);
    LChar2 := CharAt(AText2, LIndex2);
    Inc(LIndex1);
    Inc(LIndex2);
    LDifference := LChar1 - LChar2;
    while LDifference <> 0 do
    begin
      if (LChar1 <= Ord('Z')) and (LChar1 >= Ord('A')) then
      begin
        Inc(LDifference, Ord('a') - Ord('A'));
        if LDifference = 0 then
          Break;
      end;
      if (LChar2 <= Ord('Z')) and (LChar2 >= Ord('A')) then
      begin
        Dec(LDifference, Ord('a') - Ord('A'));
        if LDifference = 0 then
          Break;
      end;
      Exit(IntSign(LDifference));
    end;
  until LChar1 = 0;
  Result := 0;
end;

class function TIdStrings.IcmpPath(const AText1, AText2: AnsiString): Integer;
begin
  Result := IcmpnPath(AText1, AText2, High(Integer));
end;

class function TIdStrings.IcmpnPath(const AText1, AText2: AnsiString; const ACount: Integer): Integer;
var
  LIndex1, LIndex2, LChar1, LChar2, LDifference, LCount: Integer;
begin
  // IcmpPath is IcmpnPath with an unlimited count: the original code is the same except for the count
  LIndex1 := 0;
  LIndex2 := 0;
  LCount := ACount;
  repeat
    LChar1 := CharAt(AText1, LIndex1);
    LChar2 := CharAt(AText2, LIndex2);
    Inc(LIndex1);
    Inc(LIndex2);
    if ACount <> High(Integer) then
    begin
      Dec(LCount);
      if LCount < 0 then
        Exit(0);
    end;
    LDifference := LChar1 - LChar2;
    while LDifference <> 0 do
    begin
      if (LChar1 <= Ord('Z')) and (LChar1 >= Ord('A')) then
      begin
        Inc(LDifference, Ord('a') - Ord('A'));
        if LDifference = 0 then
          Break;
      end;
      if LChar1 = Ord('\') then
      begin
        Inc(LDifference, Ord('/') - Ord('\'));
        if LDifference = 0 then
          Break;
      end;
      if (LChar2 <= Ord('Z')) and (LChar2 >= Ord('A')) then
      begin
        Dec(LDifference, Ord('a') - Ord('A'));
        if LDifference = 0 then
          Break;
      end;
      if LChar2 = Ord('\') then
      begin
        Dec(LDifference, Ord('/') - Ord('\'));
        if LDifference = 0 then
          Break;
      end;
      // make sure folders come first
      while LChar1 <> 0 do
      begin
        if (LChar1 = Ord('/')) or (LChar1 = Ord('\')) then
          Break;
        LChar1 := CharAt(AText1, LIndex1);
        Inc(LIndex1);
      end;
      while LChar2 <> 0 do
      begin
        if (LChar2 = Ord('/')) or (LChar2 = Ord('\')) then
          Break;
        LChar2 := CharAt(AText2, LIndex2);
        Inc(LIndex2);
      end;
      if (LChar1 <> 0) and (LChar2 = 0) then
        Exit(-1)
      else if (LChar1 = 0) and (LChar2 <> 0) then
        Exit(1);
      // same folder depth so use the regular compare
      Exit(IntSign(LDifference));
    end;
  until LChar1 = 0;
  Result := 0;
end;

class function TIdStrings.FindChar(const AText: AnsiString; const AChar: AnsiChar; const AStart, AEnd: Integer): Integer;
var
  LIndex, LEnd: Integer;
begin
  LEnd := AEnd;
  if LEnd = -1 then
    LEnd := Length(AText) - 1;
  for LIndex := AStart to LEnd do
    if CharAt(AText, LIndex) = ShortInt(Byte(AChar)) then
      Exit(LIndex);
  Result := -1;
end;

class function TIdStrings.FindText(const AText, ASubText: AnsiString; const ACaseSensitive: Boolean;
  const AStart, AEnd: Integer): Integer;
var
  LLast, LIndex, LOffset, LEnd, LSubLength: Integer;
  LMatch: Boolean;
begin
  LEnd := AEnd;
  if LEnd = -1 then
    LEnd := Length(AText);
  LSubLength := Length(ASubText);
  LLast := LEnd - LSubLength;
  for LIndex := AStart to LLast do
  begin
    LMatch := True;
    for LOffset := 0 to LSubLength - 1 do
    begin
      if ACaseSensitive then
      begin
        if CharAt(AText, LIndex + LOffset) <> CharAt(ASubText, LOffset) then
        begin
          LMatch := False;
          Break;
        end;
      end
      else if ToUpper(AnsiChar(Byte(CharAt(AText, LIndex + LOffset)))) <>
        ToUpper(AnsiChar(Byte(CharAt(ASubText, LOffset)))) then
      begin
        LMatch := False;
        Break;
      end;
    end;
    if LMatch then
      Exit(LIndex);
  end;
  Result := -1;
end;

class function TIdStrings.Filter(const AFilter, AName: AnsiString; const ACaseSensitive: Boolean): Boolean;
var
  LF, LN: Integer; // positions in the filter and in the name
  LBuffer: AnsiString;
  LFound: Boolean;
  LIndex: Integer;

  function UpperAt(const AText: AnsiString; const APosition: Integer): Integer;
  begin
    Result := CharAt(AText, APosition);
    if (Result >= Ord('a')) and (Result <= Ord('z')) then
      Dec(Result, Ord('a') - Ord('A'));
  end;

  function Same(const AFilterPosition, ANamePosition: Integer): Boolean;
  begin
    if ACaseSensitive then
      Result := CharAt(AFilter, AFilterPosition) = CharAt(AName, ANamePosition)
    else
      Result := UpperAt(AFilter, AFilterPosition) = UpperAt(AName, ANamePosition);
  end;

begin
  LF := 0;
  LN := 0;
  while CharAt(AFilter, LF) <> 0 do
  begin
    if CharAt(AFilter, LF) = Ord('*') then
    begin
      Inc(LF);
      LBuffer := '';
      while CharAt(AFilter, LF) <> 0 do
      begin
        if (CharAt(AFilter, LF) = Ord('*')) or (CharAt(AFilter, LF) = Ord('?')) or
          ((CharAt(AFilter, LF) = Ord('[')) and (CharAt(AFilter, LF + 1) <> Ord('['))) then
          Break;
        LBuffer := LBuffer + AnsiChar(Byte(CharAt(AFilter, LF)));
        if CharAt(AFilter, LF) = Ord('[') then
          Inc(LF);
        Inc(LF);
      end;
      if System.Length(LBuffer) > 0 then
      begin
        LIndex := FindText(Copy(AName, LN + 1, MaxInt), LBuffer, ACaseSensitive);
        if LIndex = -1 then
          Exit(False);
        Inc(LN, LIndex + System.Length(LBuffer));
      end;
    end
    else if CharAt(AFilter, LF) = Ord('?') then
    begin
      Inc(LF);
      Inc(LN);
    end
    else if CharAt(AFilter, LF) = Ord('[') then
    begin
      if CharAt(AFilter, LF + 1) = Ord('[') then
      begin
        if CharAt(AName, LN) <> Ord('[') then
          Exit(False);
        Inc(LF, 2);
        Inc(LN);
      end
      else
      begin
        Inc(LF);
        LFound := False;
        while (CharAt(AFilter, LF) <> 0) and not LFound do
        begin
          if (CharAt(AFilter, LF) = Ord(']')) and (CharAt(AFilter, LF + 1) <> Ord(']')) then
            Break;
          if (CharAt(AFilter, LF + 1) = Ord('-')) and (CharAt(AFilter, LF + 2) <> 0) and
            ((CharAt(AFilter, LF + 2) <> Ord(']')) or (CharAt(AFilter, LF + 3) = Ord(']'))) then
          begin
            if ACaseSensitive then
            begin
              if (CharAt(AName, LN) >= CharAt(AFilter, LF)) and (CharAt(AName, LN) <= CharAt(AFilter, LF + 2)) then
                LFound := True;
            end
            else if (UpperAt(AName, LN) >= UpperAt(AFilter, LF)) and (UpperAt(AName, LN) <= UpperAt(AFilter, LF + 2)) then
              LFound := True;
            Inc(LF, 3);
          end
          else
          begin
            if Same(LF, LN) then
              LFound := True;
            Inc(LF);
          end;
        end;
        if not LFound then
          Exit(False);
        while CharAt(AFilter, LF) <> 0 do
        begin
          if (CharAt(AFilter, LF) = Ord(']')) and (CharAt(AFilter, LF + 1) <> Ord(']')) then
            Break;
          Inc(LF);
        end;
        Inc(LF);
        Inc(LN);
      end;
    end
    else
    begin
      if not Same(LF, LN) then
        Exit(False);
      Inc(LF);
      Inc(LN);
    end;
  end;
  Result := True;
end;

class function TIdStrings.IsNumeric(const AText: AnsiString): Boolean;
var
  LIndex: Integer;
  LDot: Boolean;
  LChar: Integer;
begin
  LIndex := 0;
  if CharAt(AText, 0) = Ord('-') then
    Inc(LIndex);
  LDot := False;
  while CharAt(AText, LIndex) <> 0 do
  begin
    LChar := CharAt(AText, LIndex);
    if not ((LChar >= Ord('0')) and (LChar <= Ord('9'))) then
    begin
      if (LChar = Ord('.')) and not LDot then
      begin
        LDot := True;
        Inc(LIndex);
        Continue;
      end;
      Exit(False);
    end;
    Inc(LIndex);
  end;
  Result := True;
end;

class function TIdStrings.IsColor(const AText: AnsiString; const AIndex: Integer): Boolean;
begin
  Result := (CharAt(AText, AIndex) = Ord(ID_COLOR_ESCAPE)) and (CharAt(AText, AIndex + 1) <> 0) and
    (CharAt(AText, AIndex + 1) <> Ord(' '));
end;

class function TIdStrings.HasLower(const AText: AnsiString): Boolean;
var
  LIndex: Integer;
begin
  for LIndex := 1 to System.Length(AText) do
    if CharIsLower(ShortInt(Byte(AText[LIndex]))) then
      Exit(True);
  Result := False;
end;

class function TIdStrings.HasUpper(const AText: AnsiString): Boolean;
var
  LIndex: Integer;
begin
  for LIndex := 1 to System.Length(AText) do
    if CharIsUpper(ShortInt(Byte(AText[LIndex]))) then
      Exit(True);
  Result := False;
end;

class function TIdStrings.LengthWithoutColors(const AText: AnsiString): Integer;
var
  LIndex: Integer;
begin
  Result := 0;
  LIndex := 0;
  while CharAt(AText, LIndex) <> 0 do
  begin
    if IsColor(AText, LIndex) then
    begin
      Inc(LIndex, 2);
      Continue;
    end;
    Inc(LIndex);
    Inc(Result);
  end;
end;

class function TIdStrings.RemoveColors(const AText: AnsiString): AnsiString;
var
  LIndex: Integer;
begin
  Result := '';
  LIndex := 0;
  while CharAt(AText, LIndex) <> 0 do
  begin
    if IsColor(AText, LIndex) then
      Inc(LIndex)
    else
      Result := Result + AText[LIndex + 1];
    Inc(LIndex);
  end;
end;

class function TIdStrings.ToLower(const AText: AnsiString): AnsiString;
var
  LIndex: Integer;
begin
  Result := AText;
  for LIndex := 1 to System.Length(Result) do
    if CharIsUpper(ShortInt(Byte(Result[LIndex]))) then
      Result[LIndex] := AnsiChar(Byte(Result[LIndex]) + (Ord('a') - Ord('A')));
end;

class function TIdStrings.ToUpper(const AText: AnsiString): AnsiString;
var
  LIndex: Integer;
begin
  Result := AText;
  for LIndex := 1 to System.Length(Result) do
    if CharIsLower(ShortInt(Byte(Result[LIndex]))) then
      Result[LIndex] := AnsiChar(Byte(Result[LIndex]) - (Ord('a') - Ord('A')));
end;

class function TIdStrings.ToLower(const AChar: AnsiChar): AnsiChar;
begin
  if (AChar <= 'Z') and (AChar >= 'A') then
    Result := AnsiChar(Byte(AChar) + (Ord('a') - Ord('A')))
  else
    Result := AChar;
end;

class function TIdStrings.ToUpper(const AChar: AnsiChar): AnsiChar;
begin
  if (AChar >= 'a') and (AChar <= 'z') then
    Result := AnsiChar(Byte(AChar) - (Ord('a') - Ord('A')))
  else
    Result := AChar;
end;

class function TIdStrings.Hash(const AText: AnsiString): Integer;
begin
  Result := Hash(AText, Length(AText));
end;

class function TIdStrings.Hash(const AText: AnsiString; const ALength: Integer): Integer;
var
  LIndex: Integer;
begin
  Result := 0;
  for LIndex := 0 to ALength - 1 do
    Result := Result + CharAt(AText, LIndex) * (LIndex + 119);
end;

class function TIdStrings.IHash(const AText: AnsiString): Integer;
begin
  Result := IHash(AText, Length(AText));
end;

class function TIdStrings.IHash(const AText: AnsiString; const ALength: Integer): Integer;
var
  LIndex: Integer;
begin
  Result := 0;
  for LIndex := 0 to ALength - 1 do
    Result := Result + ShortInt(Byte(ToLower(AnsiChar(Byte(CharAt(AText, LIndex)))))) * (LIndex + 119);
end;

class function TIdStrings.FileNameHash(const AText: AnsiString): Integer;
var
  LIndex, LLetter: Integer;
begin
  Result := 0;
  LIndex := 0;
  while CharAt(AText, LIndex) <> 0 do
  begin
    LLetter := ShortInt(Byte(ToLower(AnsiChar(Byte(CharAt(AText, LIndex))))));
    if LLetter = Ord('.') then
      Break;
    if LLetter = Ord('\') then
      LLetter := Ord('/');
    Result := Result + LLetter * (LIndex + 119);
    Inc(LIndex);
  end;
  Result := Result and (ID_FILE_HASH_SIZE - 1);
end;

class function TIdStrings.CharIsPrintable(const AChar: Integer): Boolean;
begin
  Result := ((AChar >= $20) and (AChar <= $7E)) or ((AChar >= $A1) and (AChar <= $FF));
end;

class function TIdStrings.CharIsLower(const AChar: Integer): Boolean;
begin
  Result := ((AChar >= Ord('a')) and (AChar <= Ord('z'))) or ((AChar >= $E0) and (AChar <= $FF));
end;

class function TIdStrings.CharIsUpper(const AChar: Integer): Boolean;
begin
  Result := ((AChar <= Ord('Z')) and (AChar >= Ord('A'))) or ((AChar >= $C0) and (AChar <= $DF));
end;

class function TIdStrings.CharIsAlpha(const AChar: Integer): Boolean;
begin
  Result := ((AChar >= Ord('a')) and (AChar <= Ord('z'))) or ((AChar >= Ord('A')) and (AChar <= Ord('Z'))) or
    ((AChar >= $C0) and (AChar <= $FF));
end;

class function TIdStrings.CharIsNumeric(const AChar: Integer): Boolean;
begin
  Result := (AChar <= Ord('9')) and (AChar >= Ord('0'));
end;

class function TIdStrings.CharIsNewLine(const AChar: AnsiChar): Boolean;
begin
  Result := (AChar = #10) or (AChar = #13) or (AChar = #11);
end;

class function TIdStrings.CharIsTab(const AChar: AnsiChar): Boolean;
begin
  Result := AChar = #9;
end;

class function TIdStrings.ColorIndex(const AChar: Integer): Integer;
begin
  Result := AChar and 15;
end;

class function TIdStrings.StripMediaName(const AName: AnsiString): AnsiString;
var
  LIndex: Integer;
  LChar: AnsiChar;
begin
  Result := '';
  for LIndex := 1 to System.Length(AName) do
  begin
    LChar := AName[LIndex];
    if LChar = '.' then
      Break;
    if LChar = '\' then
      Result := Result + '/'
    else
      Result := Result + ToLower(LChar);
  end;
end;

class function TIdStrings.CheckExtension(const AName, AExtension: AnsiString): Boolean;
var
  LIndex1, LIndex2, LChar1, LChar2, LDifference: Integer;
begin
  LIndex1 := Length(AName) - 1;
  LIndex2 := Length(AExtension) - 1;
  repeat
    LChar1 := CharAt(AName, LIndex1);
    LChar2 := CharAt(AExtension, LIndex2);
    Dec(LIndex1);
    Dec(LIndex2);
    LDifference := LChar1 - LChar2;
    while LDifference <> 0 do
    begin
      if (LChar1 <= Ord('Z')) and (LChar1 >= Ord('A')) then
      begin
        Inc(LDifference, Ord('a') - Ord('A'));
        if LDifference = 0 then
          Break;
      end;
      if (LChar2 <= Ord('Z')) and (LChar2 >= Ord('A')) then
      begin
        Dec(LDifference, Ord('a') - Ord('A'));
        if LDifference = 0 then
          Break;
      end;
      Exit(False);
    end;
  until not ((LIndex1 > 0) and (LIndex2 > 0));
  Result := LIndex1 >= 0;
end;

function TrimFloatText(const AText: AnsiString): AnsiString;
var
  LLength: Integer;
begin
  Result := AText;
  LLength := Length(Result);
  while (LLength > 0) and (Result[LLength] = '0') do
    Dec(LLength);
  while (LLength > 0) and (Result[LLength] = '.') do
    Dec(LLength);
  SetLength(Result, LLength);
end;

class function TIdStrings.FormatFixed(const AValue: Single; const APrecision: Integer): AnsiString;
var
  LScaled: Double;
  LRounded: Int64;
  LDigits: string;
  LPower: Double;
  LIndex: Integer;
begin
  if (APrecision < 0) or (APrecision > 9) or (AValue <> AValue) or (Abs(AValue) > 3.4E38) then
  begin
    // outside the range where the scaled value is exact: the RTL formatting (rounds ties away from zero)
    Exit(AnsiString(Format('%.*f', [APrecision, Double(AValue)], TFormatSettings.Invariant)));
  end;
  LPower := 1;
  for LIndex := 1 to APrecision do
    LPower := LPower * 10;
  // a Single has 24 significant bits and 10^n = 5^n * 2^n: the product is exact in a Double up to n = 12
  LScaled := Abs(Double(AValue)) * LPower;
  if LScaled >= 9.0E18 then
    Exit(AnsiString(Format('%.*f', [APrecision, Double(AValue)], TFormatSettings.Invariant)));
  // printf rounds the exact binary value, ties to even (Round of the RTL rounds half to even too)
  LRounded := Round(LScaled);
  LDigits := IntToStr(LRounded);
  if APrecision > 0 then
  begin
    while System.Length(LDigits) <= APrecision do
      LDigits := '0' + LDigits;
    Insert('.', LDigits, System.Length(LDigits) - APrecision + 1);
  end;
  // printf writes the minus sign of negative numbers also when they round to zero
  if (PCardinal(@AValue)^ and $80000000) <> 0 then
    LDigits := '-' + LDigits;
  Result := AnsiString(LDigits);
end;

class function TIdStrings.FloatToPlainText(const AValue: Single): AnsiString;
begin
  Result := FormatFixed(AValue, 6);
end;

class function TIdStrings.FloatToText(const AValue: Single): AnsiString;
begin
  Result := TrimFloatText(FloatToPlainText(AValue));
end;

class function TIdStrings.FloatArrayToString(const AValues: array of Single; const APrecision: Integer): AnsiString;
var
  LIndex: Integer;
  LPart: AnsiString;
begin
  Result := '';
  for LIndex := 0 to High(AValues) do
  begin
    LPart := FormatFixed(AValues[LIndex], APrecision);
    if APrecision > 0 then
      LPart := TrimFloatText(LPart);
    if LIndex > 0 then
      Result := Result + ' ';
    Result := Result + LPart;
  end;
end;

class function TIdStrings.FormatNumber(const ANumber: Integer): AnsiString;
const
  GRANULARITY: array[0..2] of Integer = (1000000000, 1000000, 1000);
var
  LCounts: array[0..2] of Integer;
  LNumber, LIndex, LPad: Integer;
  LHit, LFound: Boolean;
begin
  FillChar(LCounts, SizeOf(LCounts), 0);
  LNumber := ANumber;
  repeat
    LHit := False;
    for LIndex := 0 to 2 do
      if LNumber >= GRANULARITY[LIndex] then
      begin
        Inc(LCounts[LIndex]);
        Dec(LNumber, GRANULARITY[LIndex]);
        LHit := True;
        Break;
      end;
  until not LHit;
  Result := '';
  LFound := False;
  for LIndex := 0 to 2 do
  begin
    if LCounts[LIndex] <> 0 then
    begin
      if not LFound then
        Result := Result + AnsiString(IntToStr(LCounts[LIndex])) + ','
      else
        Result := Result + AnsiString(Format('%.3d', [LCounts[LIndex]])) + ',';
      LFound := True;
    end
    else if LFound then
      Result := Result + AnsiString(Format('%.3d', [LCounts[LIndex]])) + ',';
  end;
  if LFound then
    Result := Result + AnsiString(Format('%.3d', [LNumber]))
  else
    Result := Result + AnsiString(IntToStr(LNumber));
  for LPad := 1 to 11 - System.Length(Result) do
    Result := ' ' + Result;
end;

end.
