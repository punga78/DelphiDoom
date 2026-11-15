{******************************************************************************}
{                                                                              }
{  DelphiDoom: net library - info strings of Quake III (\key\value\key\value)  }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): q_shared.c      }
{  (Info_ValueForKey, Info_NextPair, Info_RemoveKey, Info_Validate,            }
{  Info_SetValueForKey and the _Big variants).                                 }
{  Copyright (C) 1999-2005 id Software, Inc.                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Net.Q3.InfoString;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Logging.Intf, DelphiDoom.Net.Q3.Types;

type
  /// <summary>
  ///   Info strings: the text of the form <c>\name\Player\rate\25000</c> that carries the user and server
  ///   settings of Quake III. Text is 8 bit (<c>AnsiString</c>) and, as in C, ends at the first NUL. The
  ///   normal variants hold 1024 characters, the Big ones (system info) 8192; the limits are the original
  ///   ones. Searches by key ignore case, removal compares exactly. Everything the original prints with
  ///   <c>Com_Printf</c> goes to the optional <c>ILog</c>, an oversize string (<c>Com_Error</c>) is an
  ///   <c>EQ3InfoStringException</c>. The key and value buffers of the original have the size of the string
  ///   limit, so they never overflow after the length check: nothing is truncated here
  /// </summary>
  TQ3InfoString = class
  strict private
    class function Limit(ABig: Boolean): Integer; static;
    class function IndexOfChar(const AText: AnsiString; AChar: AnsiChar): Integer; static;
    class function HasChar(const AText: AnsiString; AChar: AnsiChar): Boolean; static;
    class function CutAtNul(const AText: AnsiString): AnsiString; static;
    class procedure CheckLength(const AText: AnsiString; ABig: Boolean; const AName: string); static;
    class function SameKey(const AFirst, ASecond: AnsiString): Boolean; static;
    class function IsClean(const AKey, AValue: AnsiString; const ALog: ILog): Boolean; static;
    class procedure Report(const ALog: ILog; const AText: string); static;
  public
    /// <summary>
    ///   Info_ValueForKey: the value of a key (case-insensitive), or an empty string. A missing key or a
    ///   string that ends in the middle of a pair gives an empty string. A string of 8192 characters or more
    ///   is an <c>EQ3InfoStringException</c>
    /// </summary>
    class function ValueForKey(const AInfo, AKey: AnsiString): AnsiString; static;
    /// <summary>
    ///   Info_NextPair: reads the pair at <c>APosition</c> (1-based, a leading backslash is skipped) and moves
    ///   the position to the backslash that starts the next pair, or past the end. At the end of the string
    ///   the key is what was read of it and the value is empty
    /// </summary>
    class procedure NextPair(const AInfo: AnsiString; var APosition: Integer;
      out AKey, AValue: AnsiString); static;
    /// <summary>
    ///   Info_RemoveKey (and _Big): removes the pair of a key (exact comparison). A key with a backslash
    ///   removes nothing. The string must be under the limit, else <c>EQ3InfoStringException</c>
    /// </summary>
    class procedure RemoveKey(var AInfo: AnsiString; const AKey: AnsiString; ABig: Boolean = False); static;
    /// <summary>Info_Validate: false if the string has a double quote or a semicolon</summary>
    class function Validate(const AInfo: AnsiString): Boolean; static;
    /// <summary>
    ///   Info_SetValueForKey (and _Big): changes or adds a pair; an empty value removes the key. The normal
    ///   variant puts the new pair first, the Big one last. False (and the message to the log) when a key or
    ///   value has a backslash, semicolon or double quote (string untouched), or the result would be over
    ///   the limit (the old pair of the key is already gone, as in the original)
    /// </summary>
    class function SetValueForKey(var AInfo: AnsiString; const AKey, AValue: AnsiString;
      ABig: Boolean = False; const ALog: ILog = nil): Boolean; static;
  end;

implementation

{ TQ3InfoString }

class function TQ3InfoString.Limit(ABig: Boolean): Integer;
begin
  if ABig then
    Result := Q3_BIG_INFO_STRING
  else
    Result := Q3_MAX_INFO_STRING;
end;

class function TQ3InfoString.IndexOfChar(const AText: AnsiString; AChar: AnsiChar): Integer;
var
  LIndex: Integer;
begin
  Result := 0;
  for LIndex := 1 to Length(AText) do
    if AText[LIndex] = AChar then
    begin
      Result := LIndex;
      Exit;
    end;
end;

class function TQ3InfoString.HasChar(const AText: AnsiString; AChar: AnsiChar): Boolean;
begin
  Result := IndexOfChar(AText, AChar) > 0;
end;

class function TQ3InfoString.CutAtNul(const AText: AnsiString): AnsiString;
var
  LIndex: Integer;
begin
  LIndex := IndexOfChar(AText, #0);
  if LIndex = 0 then
    Result := AText
  else
    Result := Copy(AText, 1, LIndex - 1);
end;

class procedure TQ3InfoString.CheckLength(const AText: AnsiString; ABig: Boolean; const AName: string);
begin
  if Length(AText) >= Limit(ABig) then
    raise EQ3InfoStringException.CreateFmt(SQ3InfoStringOversize, [AName]);
end;

class function TQ3InfoString.SameKey(const AFirst, ASecond: AnsiString): Boolean;
var
  LIndex: Integer;
  LFirst: AnsiChar;
  LSecond: AnsiChar;
begin
  Result := Length(AFirst) = Length(ASecond);
  if not Result then
    Exit;
  for LIndex := 1 to Length(AFirst) do
  begin
    LFirst := AFirst[LIndex];
    LSecond := ASecond[LIndex];
    if LFirst in ['a'..'z'] then
      LFirst := AnsiChar(Ord(LFirst) - 32);
    if LSecond in ['a'..'z'] then
      LSecond := AnsiChar(Ord(LSecond) - 32);
    if LFirst <> LSecond then
    begin
      Result := False;
      Exit;
    end;
  end;
end;

class procedure TQ3InfoString.Report(const ALog: ILog; const AText: string);
begin
  if Assigned(ALog) then
    ALog.Info(AText);
end;

class function TQ3InfoString.IsClean(const AKey, AValue: AnsiString; const ALog: ILog): Boolean;
begin
  Result := False;
  if (HasChar(AKey, '\')) or (HasChar(AValue, '\')) then
    Report(ALog, SQ3InfoStringBackslash)
  else if (HasChar(AKey, ';')) or (HasChar(AValue, ';')) then
    Report(ALog, SQ3InfoStringSemicolon)
  else if (HasChar(AKey, '"')) or (HasChar(AValue, '"')) then
    Report(ALog, SQ3InfoStringQuote)
  else
    Result := True;
end;

class function TQ3InfoString.ValueForKey(const AInfo, AKey: AnsiString): AnsiString;
var
  LInfo: AnsiString;
  LPosition: Integer;
  LKey: AnsiString;
begin
  Result := '';
  LInfo := CutAtNul(AInfo);
  CheckLength(LInfo, True, 'Info_ValueForKey');
  LPosition := 1;
  if (LInfo <> '') and (LInfo[1] = '\') then
    Inc(LPosition);
  while True do
  begin
    LKey := '';
    while LPosition <= Length(LInfo) do
    begin
      if LInfo[LPosition] = '\' then
        Break;
      LKey := LKey + LInfo[LPosition];
      Inc(LPosition);
    end;
    if LPosition > Length(LInfo) then
    begin
      Result := '';
      Exit;
    end;
    Inc(LPosition);
    Result := '';
    while (LPosition <= Length(LInfo)) and (LInfo[LPosition] <> '\') do
    begin
      Result := Result + LInfo[LPosition];
      Inc(LPosition);
    end;
    if SameKey(AKey, LKey) then
      Exit;
    if LPosition > Length(LInfo) then
      Break;
    Inc(LPosition);
  end;
  Result := '';
end;

class procedure TQ3InfoString.NextPair(const AInfo: AnsiString; var APosition: Integer;
  out AKey, AValue: AnsiString);
begin
  AKey := '';
  AValue := '';
  if (APosition >= 1) and (APosition <= Length(AInfo)) and (AInfo[APosition] = '\') then
    Inc(APosition);
  while True do
  begin
    if (APosition < 1) or (APosition > Length(AInfo)) then
      Exit;
    if AInfo[APosition] = '\' then
      Break;
    AKey := AKey + AInfo[APosition];
    Inc(APosition);
  end;
  Inc(APosition);
  while (APosition <= Length(AInfo)) and (AInfo[APosition] <> '\') do
  begin
    AValue := AValue + AInfo[APosition];
    Inc(APosition);
  end;
end;

class procedure TQ3InfoString.RemoveKey(var AInfo: AnsiString; const AKey: AnsiString; ABig: Boolean);
var
  LInfo: AnsiString;
  LPosition: Integer;
  LStart: Integer;
  LName: AnsiString;
begin
  LInfo := CutAtNul(AInfo);
  if ABig then
    CheckLength(LInfo, True, 'Info_RemoveKey_Big')
  else
    CheckLength(LInfo, False, 'Info_RemoveKey');
  if HasChar(AKey, '\') then
    Exit;
  LPosition := 1;
  while True do
  begin
    LStart := LPosition;
    if (LPosition <= Length(LInfo)) and (LInfo[LPosition] = '\') then
      Inc(LPosition);
    LName := '';
    while True do
    begin
      if LPosition > Length(LInfo) then
        Exit;
      if LInfo[LPosition] = '\' then
        Break;
      LName := LName + LInfo[LPosition];
      Inc(LPosition);
    end;
    Inc(LPosition);
    while (LPosition <= Length(LInfo)) and (LInfo[LPosition] <> '\') do
      Inc(LPosition);
    if LName = AKey then
    begin
      AInfo := Copy(LInfo, 1, LStart - 1) + Copy(LInfo, LPosition, MaxInt);
      Exit;
    end;
    if LPosition > Length(LInfo) then
      Exit;
  end;
end;

class function TQ3InfoString.Validate(const AInfo: AnsiString): Boolean;
var
  LInfo: AnsiString;
begin
  LInfo := CutAtNul(AInfo);
  Result := (not HasChar(LInfo, '"')) and (not HasChar(LInfo, ';'));
end;

class function TQ3InfoString.SetValueForKey(var AInfo: AnsiString; const AKey, AValue: AnsiString;
  ABig: Boolean; const ALog: ILog): Boolean;
var
  LKey: AnsiString;
  LValue: AnsiString;
  LNew: AnsiString;
begin
  Result := False;
  AInfo := CutAtNul(AInfo);
  LKey := CutAtNul(AKey);
  LValue := CutAtNul(AValue);
  CheckLength(AInfo, ABig, 'Info_SetValueForKey');
  if not IsClean(LKey, LValue, ALog) then
    Exit;
  RemoveKey(AInfo, LKey, ABig);
  Result := True;
  if LValue = '' then
    Exit;
  LNew := '\' + LKey + '\' + LValue;
  if Length(LNew) >= Limit(ABig) then
  begin
    // Com_sprintf prints the overflow and truncates to the buffer
    Report(ALog, Format(SQ3InfoStringSprintfOverflow, [Length(LNew), Limit(ABig)]));
    LNew := Copy(LNew, 1, Limit(ABig) - 1);
  end;
  if Length(LNew) + Length(AInfo) > Limit(ABig) then
  begin
    if ABig then
      Report(ALog, SQ3InfoStringBigExceeded)
    else
      Report(ALog, SQ3InfoStringExceeded);
    Result := False;
    Exit;
  end;
  if ABig then
    AInfo := AInfo + LNew
  else
    AInfo := LNew + AInfo;
end;

end.
