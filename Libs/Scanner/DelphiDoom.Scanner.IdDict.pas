{******************************************************************************}
{                                                                              }
{  DelphiDoom: scanner library - TIdDict, the key/value dictionary of idTech 4 }
{                                                                              }
{  Port of idLib (id Software, Doom 3, GPL v3): idlib\Dict.h, Dict.cpp.        }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Scanner.IdDict;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.IdLib.Core.Intf, DelphiDoom.IdLib.Math.Vec2, DelphiDoom.IdLib.Math.Vec3,
  DelphiDoom.IdLib.Math.Vec4, DelphiDoom.IdLib.Math.Random, DelphiDoom.Scanner.IdParser.Intf, DelphiDoom.Scanner.IdCNumbers;

type
  /// <summary>idKeyValue: a key and its value (8-bit text)</summary>
  TIdKeyValue = record
    Key: AnsiString;
    Value: AnsiString;
  end;

  /// <summary>
  ///   A dictionary of text keys and values (idDict). Keys are compared without regard to case (ASCII,
  ///   <c>idStr::Icmp</c>); the key keeps the case of its first <c>SetValue</c>; the order is the
  ///   order of insertion and a delete keeps it. An empty key is ignored by <c>SetValue</c>.
  ///   <para>Differences: the shared string pools (globalKeys/globalValues, <c>Init</c>, <c>Shutdown</c>,
  ///   the memory statistics and the console commands) are not ported: each dictionary owns its strings;
  ///   the lookup is a linear scan (the hash index of the original gives the same answers);
  ///   <c>GetKeyVal</c> returns the record by value; the file functions work on bytes
  ///   (<c>WriteToBytes</c>, <c>ReadFromBytes</c>) instead of an idFile; angles and matrices (idAngles, idMat3)
  ///   are not ported. The numbers are read as the C library does (<c>atoi</c>, <c>atof</c>,
  ///   <c>sscanf("%f")</c>): the text up to the first character that is not part of the number.</para>
  /// </summary>
  TIdDict = class
  strict private
    FEntries: TArray<TIdKeyValue>;
    FLog: IIdLibLog;
    procedure Append(const AKey, AValue: AnsiString);
  public
    /// <summary>The log gets the warning for an empty key (<c>common->DWarning</c>) and <c>Print</c></summary>
    constructor Create(const ALog: IIdLibLog = nil);
    /// <summary>idDict::operator=: clears this dictionary and copies the other</summary>
    procedure Assign(const AOther: TIdDict);
    /// <summary>Copies all key/value pairs of the other, leaving the others in place</summary>
    procedure Copy(const AOther: TIdDict);
    /// <summary>Clears this dictionary and takes the pairs of the other, which is left empty</summary>
    procedure TransferKeyValues(const AOther: TIdDict);
    /// <summary>
    ///   Parses <c>{ "key" "value" ... }</c> from a parser. False if a key was already defined (a warning;
    ///   the later value wins). Problems of the syntax are errors of the parser.
    /// </summary>
    function Parse(const ASource: IIdTokenSource): Boolean;
    /// <summary>Copies the pairs of the other dictionary whose key is not here</summary>
    procedure SetDefaults(const ADefaults: TIdDict);
    procedure Clear;
    procedure Print;
    procedure SetValue(const AKey, AValue: AnsiString);
    procedure SetFloat(const AKey: AnsiString; const AValue: Single);
    procedure SetInt(const AKey: AnsiString; const AValue: Integer);
    procedure SetBool(const AKey: AnsiString; const AValue: Boolean);
    procedure SetVector(const AKey: AnsiString; const AValue: TIdVec3);
    procedure SetVec2(const AKey: AnsiString; const AValue: TIdVec2);
    procedure SetVec4(const AKey: AnsiString; const AValue: TIdVec4);
    /// <summary>The value, or the default when the key is missing</summary>
    function GetString(const AKey: AnsiString; const ADefault: AnsiString = ''): AnsiString; overload;
    function GetString(const AKey, ADefault: AnsiString; out AValue: AnsiString): Boolean; overload;
    function GetFloat(const AKey: AnsiString; const ADefault: AnsiString = '0'): Single; overload;
    function GetFloat(const AKey, ADefault: AnsiString; out AValue: Single): Boolean; overload;
    function GetInt(const AKey: AnsiString; const ADefault: AnsiString = '0'): Integer; overload;
    function GetInt(const AKey, ADefault: AnsiString; out AValue: Integer): Boolean; overload;
    function GetBool(const AKey: AnsiString; const ADefault: AnsiString = '0'): Boolean; overload;
    function GetBool(const AKey, ADefault: AnsiString; out AValue: Boolean): Boolean; overload;
    /// <summary>An empty default means "0 0 0"; a text that does not hold three numbers leaves the others at 0</summary>
    function GetVector(const AKey: AnsiString; const ADefault: AnsiString = ''): TIdVec3; overload;
    function GetVector(const AKey, ADefault: AnsiString; out AValue: TIdVec3): Boolean; overload;
    function GetVec2(const AKey: AnsiString; const ADefault: AnsiString = ''): TIdVec2; overload;
    function GetVec2(const AKey, ADefault: AnsiString; out AValue: TIdVec2): Boolean; overload;
    function GetVec4(const AKey: AnsiString; const ADefault: AnsiString = ''): TIdVec4; overload;
    function GetVec4(const AKey, ADefault: AnsiString; out AValue: TIdVec4): Boolean; overload;
    function GetNumKeyVals: Integer;
    /// <summary>The pair at the index; a key and value of #0 text when out of range (the original returns NULL)</summary>
    function TryGetKeyVal(const AIndex: Integer; out AKeyValue: TIdKeyValue): Boolean;
    /// <summary>The index of the key, -1 if it does not exist (idDict::FindKeyIndex; an empty key gives 0 as the original)</summary>
    function FindKeyIndex(const AKey: AnsiString): Integer;
    /// <summary>Like FindKeyIndex but false if it does not exist and a warning for an empty key (idDict::FindKey)</summary>
    function FindKey(const AKey: AnsiString; out AKeyValue: TIdKeyValue): Boolean;
    procedure Delete(const AKey: AnsiString);
    /// <summary>
    ///   The index of the next pair whose key starts with the prefix (without regard to case), after
    ///   <c>ALastMatch</c> (-1: from the start); -1 if none
    /// </summary>
    function MatchPrefix(const APrefix: AnsiString; const ALastMatch: Integer = -1): Integer;
    /// <summary>The value of one of the pairs with the key prefix, chosen at random ('' if none; at most 2048 pairs)</summary>
    function RandomPrefix(const APrefix: AnsiString; var ARandom: TIdRandom): AnsiString;
    /// <summary>The checksum of the content: CRC-32 of the keys and values sorted by key (idDict::Checksum)</summary>
    function Checksum: Integer;
    /// <summary>idDict::WriteToFileHandle: the count (32-bit, little endian), then the NUL-terminated key and value of each pair</summary>
    function WriteToBytes: TBytes;
    /// <summary>idDict::ReadFromFileHandle: clears the dictionary and reads from the position</summary>
    procedure ReadFromBytes(const AData: TBytes; var APosition: Integer);
  end;

implementation

uses
  System.Generics.Collections, System.Generics.Defaults, DelphiDoom.IdLib.Core.Exceptions,
  DelphiDoom.IdLib.Text.Types, DelphiDoom.IdLib.Text.Token, DelphiDoom.IdLib.Text.Strings,
  DelphiDoom.MathCore.Crc32;

const
  MAX_STRING_CHARS = 1024;
  MAX_RANDOM_KEYS = 2048;

{ TIdDict }

constructor TIdDict.Create(const ALog: IIdLibLog);
begin
  inherited Create;
  FLog := ALog;
end;

procedure TIdDict.Append(const AKey, AValue: AnsiString);
begin
  SetLength(FEntries, System.Length(FEntries) + 1);
  FEntries[High(FEntries)].Key := AKey;
  FEntries[High(FEntries)].Value := AValue;
end;

procedure TIdDict.Assign(const AOther: TIdDict);
begin
  // check for assignment to self
  if AOther = Self then
    Exit;
  FEntries := System.Copy(AOther.FEntries);
end;

procedure TIdDict.Copy(const AOther: TIdDict);
var
  LIndex, LFound: Integer;
  LOther: TArray<TIdKeyValue>;
begin
  // check for assignment to self
  if AOther = Self then
    Exit;
  LOther := AOther.FEntries;
  for LIndex := 0 to High(LOther) do
  begin
    LFound := FindKeyIndex(LOther[LIndex].Key);
    if LFound <> -1 then
      FEntries[LFound].Value := LOther[LIndex].Value
    else
      Append(LOther[LIndex].Key, LOther[LIndex].Value);
  end;
end;

procedure TIdDict.TransferKeyValues(const AOther: TIdDict);
begin
  if AOther = Self then
    Exit;
  FEntries := AOther.FEntries;
  AOther.FEntries := nil;
end;

function TIdDict.Parse(const ASource: IIdTokenSource): Boolean;
var
  LToken, LToken2: TIdToken;
  LErrors: Boolean;
  LKeyValue: TIdKeyValue;
begin
  LErrors := False;
  LToken := TIdToken.Create;
  LToken2 := TIdToken.Create;
  ASource.ExpectTokenString('{');
  ASource.ReadToken(LToken);
  while (LToken.TokenType <> TT_PUNCTUATION) or not LToken.IsText('}') do
  begin
    if LToken.TokenType <> TT_STRING then
      ASource.Error(Format('Expected quoted string, but found ''%s''', [string(LToken.Text)]));
    if not ASource.ReadToken(LToken2) then
      ASource.Error('Unexpected end of file');
    if FindKey(LToken.Text, LKeyValue) then
    begin
      ASource.Warning(Format('''%s'' already defined', [string(LToken.Text)]));
      LErrors := True;
    end;
    SetValue(LToken.Text, LToken2.Text);
    if not ASource.ReadToken(LToken) then
      ASource.Error('Unexpected end of file');
  end;
  Result := not LErrors;
end;

procedure TIdDict.SetDefaults(const ADefaults: TIdDict);
var
  LIndex: Integer;
  LKeyValue: TIdKeyValue;
  LDefaults: TArray<TIdKeyValue>;
begin
  LDefaults := ADefaults.FEntries;
  for LIndex := 0 to High(LDefaults) do
    if not FindKey(LDefaults[LIndex].Key, LKeyValue) then
      Append(LDefaults[LIndex].Key, LDefaults[LIndex].Value);
end;

procedure TIdDict.Clear;
begin
  FEntries := nil;
end;

procedure TIdDict.Print;
var
  LIndex: Integer;
begin
  if not Assigned(FLog) then
    Exit;
  for LIndex := 0 to High(FEntries) do
    FLog.Printf(Format('%s = %s'#10, [string(FEntries[LIndex].Key), string(FEntries[LIndex].Value)]));
end;

procedure TIdDict.SetValue(const AKey, AValue: AnsiString);
var
  LIndex: Integer;
begin
  if AKey = '' then
    Exit;
  LIndex := FindKeyIndex(AKey);
  if LIndex <> -1 then
    FEntries[LIndex].Value := AValue
  else
    Append(AKey, AValue);
end;

procedure TIdDict.SetFloat(const AKey: AnsiString; const AValue: Single);
begin
  SetValue(AKey, TIdStrings.FormatFixed(AValue, 6));
end;

procedure TIdDict.SetInt(const AKey: AnsiString; const AValue: Integer);
begin
  SetValue(AKey, AnsiString(IntToStr(AValue)));
end;

procedure TIdDict.SetBool(const AKey: AnsiString; const AValue: Boolean);
begin
  SetValue(AKey, AnsiString(IntToStr(Ord(AValue))));
end;

procedure TIdDict.SetVector(const AKey: AnsiString; const AValue: TIdVec3);
begin
  SetValue(AKey, AValue.ToString);
end;

procedure TIdDict.SetVec2(const AKey: AnsiString; const AValue: TIdVec2);
begin
  SetValue(AKey, AValue.ToString);
end;

procedure TIdDict.SetVec4(const AKey: AnsiString; const AValue: TIdVec4);
begin
  SetValue(AKey, AValue.ToString);
end;

function TIdDict.GetString(const AKey, ADefault: AnsiString; out AValue: AnsiString): Boolean;
var
  LKeyValue: TIdKeyValue;
begin
  if FindKey(AKey, LKeyValue) then
  begin
    AValue := LKeyValue.Value;
    Exit(True);
  end;
  AValue := ADefault;
  Result := False;
end;

function TIdDict.GetString(const AKey: AnsiString; const ADefault: AnsiString): AnsiString;
begin
  GetString(AKey, ADefault, Result);
end;

function TIdDict.GetFloat(const AKey: AnsiString; const ADefault: AnsiString): Single;
begin
  Result := TIdCNumbers.Atof(GetString(AKey, ADefault));
end;

function TIdDict.GetFloat(const AKey, ADefault: AnsiString; out AValue: Single): Boolean;
var
  LText: AnsiString;
begin
  Result := GetString(AKey, ADefault, LText);
  AValue := TIdCNumbers.Atof(LText);
end;

function TIdDict.GetInt(const AKey: AnsiString; const ADefault: AnsiString): Integer;
begin
  Result := TIdCNumbers.Atoi(GetString(AKey, ADefault));
end;

function TIdDict.GetInt(const AKey, ADefault: AnsiString; out AValue: Integer): Boolean;
var
  LText: AnsiString;
begin
  Result := GetString(AKey, ADefault, LText);
  AValue := TIdCNumbers.Atoi(LText);
end;

function TIdDict.GetBool(const AKey: AnsiString; const ADefault: AnsiString): Boolean;
begin
  Result := TIdCNumbers.Atoi(GetString(AKey, ADefault)) <> 0;
end;

function TIdDict.GetBool(const AKey, ADefault: AnsiString; out AValue: Boolean): Boolean;
var
  LText: AnsiString;
begin
  Result := GetString(AKey, ADefault, LText);
  AValue := TIdCNumbers.Atoi(LText) <> 0;
end;

function TIdDict.GetVector(const AKey, ADefault: AnsiString; out AValue: TIdVec3): Boolean;
var
  LText, LDefault: AnsiString;
  LValues: array[0..2] of Single;
begin
  LDefault := ADefault;
  if LDefault = '' then
    LDefault := '0 0 0';
  Result := GetString(AKey, LDefault, LText);
  LValues[0] := 0;
  LValues[1] := 0;
  LValues[2] := 0;
  TIdCNumbers.ScanFloats(LText, LValues);
  AValue.X := LValues[0];
  AValue.Y := LValues[1];
  AValue.Z := LValues[2];
end;

function TIdDict.GetVector(const AKey: AnsiString; const ADefault: AnsiString): TIdVec3;
begin
  GetVector(AKey, ADefault, Result);
end;

function TIdDict.GetVec2(const AKey, ADefault: AnsiString; out AValue: TIdVec2): Boolean;
var
  LText, LDefault: AnsiString;
  LValues: array[0..1] of Single;
begin
  LDefault := ADefault;
  if LDefault = '' then
    LDefault := '0 0';
  Result := GetString(AKey, LDefault, LText);
  LValues[0] := 0;
  LValues[1] := 0;
  TIdCNumbers.ScanFloats(LText, LValues);
  AValue.X := LValues[0];
  AValue.Y := LValues[1];
end;

function TIdDict.GetVec2(const AKey: AnsiString; const ADefault: AnsiString): TIdVec2;
begin
  GetVec2(AKey, ADefault, Result);
end;

function TIdDict.GetVec4(const AKey, ADefault: AnsiString; out AValue: TIdVec4): Boolean;
var
  LText, LDefault: AnsiString;
  LValues: array[0..3] of Single;
  LIndex: Integer;
begin
  LDefault := ADefault;
  if LDefault = '' then
    LDefault := '0 0 0 0';
  Result := GetString(AKey, LDefault, LText);
  for LIndex := 0 to 3 do
    LValues[LIndex] := 0;
  TIdCNumbers.ScanFloats(LText, LValues);
  AValue.X := LValues[0];
  AValue.Y := LValues[1];
  AValue.Z := LValues[2];
  AValue.W := LValues[3];
end;

function TIdDict.GetVec4(const AKey: AnsiString; const ADefault: AnsiString): TIdVec4;
begin
  GetVec4(AKey, ADefault, Result);
end;

function TIdDict.GetNumKeyVals: Integer;
begin
  Result := System.Length(FEntries);
end;

function TIdDict.TryGetKeyVal(const AIndex: Integer; out AKeyValue: TIdKeyValue): Boolean;
begin
  if (AIndex >= 0) and (AIndex < System.Length(FEntries)) then
  begin
    AKeyValue := FEntries[AIndex];
    Exit(True);
  end;
  AKeyValue.Key := '';
  AKeyValue.Value := '';
  Result := False;
end;

function TIdDict.FindKey(const AKey: AnsiString; out AKeyValue: TIdKeyValue): Boolean;
var
  LIndex: Integer;
begin
  AKeyValue.Key := '';
  AKeyValue.Value := '';
  if AKey = '' then
  begin
    if Assigned(FLog) then
      FLog.Warning('idDict::FindKey: empty key');
    Exit(False);
  end;
  LIndex := FindKeyIndex(AKey);
  if LIndex = -1 then
    Exit(False);
  AKeyValue := FEntries[LIndex];
  Result := True;
end;

function TIdDict.FindKeyIndex(const AKey: AnsiString): Integer;
var
  LIndex: Integer;
begin
  if AKey = '' then
  begin
    if Assigned(FLog) then
      FLog.Warning('idDict::FindKeyIndex: empty key');
    // the original returns NULL, that is 0, here
    Exit(0);
  end;
  for LIndex := 0 to High(FEntries) do
    if TIdStrings.Icmp(FEntries[LIndex].Key, AKey) = 0 then
      Exit(LIndex);
  Result := -1;
end;

procedure TIdDict.Delete(const AKey: AnsiString);
var
  LIndex, LMove: Integer;
begin
  for LIndex := 0 to High(FEntries) do
    if TIdStrings.Icmp(FEntries[LIndex].Key, AKey) = 0 then
    begin
      for LMove := LIndex to High(FEntries) - 1 do
        FEntries[LMove] := FEntries[LMove + 1];
      SetLength(FEntries, System.Length(FEntries) - 1);
      Exit;
    end;
end;

function TIdDict.MatchPrefix(const APrefix: AnsiString; const ALastMatch: Integer): Integer;
var
  LIndex, LStart, LLength: Integer;
begin
  LLength := TIdStrings.Length(APrefix);
  LStart := -1;
  if ALastMatch >= 0 then
  begin
    LStart := ALastMatch;
    if LStart < 1 then
      LStart := 0;
  end;
  for LIndex := LStart + 1 to High(FEntries) do
    if TIdStrings.Icmpn(FEntries[LIndex].Key, APrefix, LLength) = 0 then
      Exit(LIndex);
  Result := -1;
end;

function TIdDict.RandomPrefix(const APrefix: AnsiString; var ARandom: TIdRandom): AnsiString;
var
  LList: TArray<AnsiString>;
  LCount, LKeyIndex, LPick: Integer;
begin
  SetLength(LList, 1);
  LList[0] := '';
  LCount := 0;
  LKeyIndex := MatchPrefix(APrefix);
  while (LKeyIndex <> -1) and (LCount < MAX_RANDOM_KEYS) do
  begin
    if LCount + 1 > High(LList) then
      SetLength(LList, LCount + 2);
    LList[LCount] := FEntries[LKeyIndex].Value;
    Inc(LCount);
    LKeyIndex := MatchPrefix(APrefix, LKeyIndex);
  end;
  LPick := ARandom.RandomInt(LCount);
  if LCount = 0 then
    Exit('');
  Result := LList[LPick];
end;

function TIdDict.Checksum: Integer;
var
  LSorted: TArray<TIdKeyValue>;
  LBuffer: AnsiString;
  LIndex: Integer;
begin
  LSorted := System.Copy(FEntries);
  TArray.Sort<TIdKeyValue>(LSorted, TComparer<TIdKeyValue>.Construct(
    function(const ALeft, ARight: TIdKeyValue): Integer
    begin
      Result := TIdStrings.Cmp(ALeft.Key, ARight.Key);
    end));
  LBuffer := '';
  for LIndex := 0 to High(LSorted) do
    LBuffer := LBuffer + System.Copy(LSorted[LIndex].Key, 1, TIdStrings.Length(LSorted[LIndex].Key)) +
      System.Copy(LSorted[LIndex].Value, 1, TIdStrings.Length(LSorted[LIndex].Value));
  if LBuffer = '' then
    Result := Integer(TCrc32.Calculate(LBuffer, 0))
  else
    Result := Integer(TCrc32.Calculate(LBuffer[1], System.Length(LBuffer)));
end;

function TIdDict.WriteToBytes: TBytes;
var
  LCount, LIndex, LPosition: Integer;

  procedure WriteText(const AText: AnsiString);
  var
    LLength: Integer;
  begin
    LLength := TIdStrings.Length(AText);
    if LLength >= MAX_STRING_CHARS - 1 then
      raise EIdLibException.Create('idDict::WriteToFileHandle: bad string');
    if LLength > 0 then
      Move(AText[1], Result[LPosition], LLength);
    Result[LPosition + LLength] := 0;
    Inc(LPosition, LLength + 1);
  end;

  function TextSize(const AText: AnsiString): Integer;
  begin
    Result := TIdStrings.Length(AText) + 1;
  end;

begin
  LCount := System.Length(FEntries);
  LPosition := 4;
  for LIndex := 0 to LCount - 1 do
    Inc(LPosition, TextSize(FEntries[LIndex].Key) + TextSize(FEntries[LIndex].Value));
  SetLength(Result, LPosition);
  Result[0] := Byte(LCount);
  Result[1] := Byte(LCount shr 8);
  Result[2] := Byte(LCount shr 16);
  Result[3] := Byte(LCount shr 24);
  LPosition := 4;
  for LIndex := 0 to LCount - 1 do
  begin
    WriteText(FEntries[LIndex].Key);
    WriteText(FEntries[LIndex].Value);
  end;
end;

procedure TIdDict.ReadFromBytes(const AData: TBytes; var APosition: Integer);
var
  LCount, LIndex: Integer;
  LKey, LValue: AnsiString;

  function ReadText: AnsiString;
  var
    LLength: Integer;
  begin
    LLength := 0;
    Result := '';
    while True do
    begin
      if APosition >= System.Length(AData) then
        raise EIdLibException.Create('idDict::ReadFromFileHandle: unexpected end of data');
      if AData[APosition] = 0 then
      begin
        Inc(APosition);
        Break;
      end;
      Result := Result + AnsiChar(AData[APosition]);
      Inc(APosition);
      Inc(LLength);
      if LLength >= MAX_STRING_CHARS then
        raise EIdLibException.Create('idDict::ReadFromFileHandle: bad string');
    end;
  end;

begin
  Clear;
  if APosition + 4 > System.Length(AData) then
    raise EIdLibException.Create('idDict::ReadFromFileHandle: unexpected end of data');
  LCount := Integer(Cardinal(AData[APosition]) or (Cardinal(AData[APosition + 1]) shl 8) or
    (Cardinal(AData[APosition + 2]) shl 16) or (Cardinal(AData[APosition + 3]) shl 24));
  Inc(APosition, 4);
  for LIndex := 0 to LCount - 1 do
  begin
    LKey := ReadText;
    LValue := ReadText;
    SetValue(LKey, LValue);
  end;
end;

end.
