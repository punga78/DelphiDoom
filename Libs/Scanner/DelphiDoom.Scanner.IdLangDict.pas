{******************************************************************************}
{                                                                              }
{  DelphiDoom: scanner library - TIdLangDict, the string table of idTech 4     }
{                                                                              }
{  Port of idLib (id Software, Doom 3, GPL v3): idlib\LangDict.h, LangDict.cpp.}
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Scanner.IdLangDict;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.IdLib.Core.Intf, DelphiDoom.Scanner.IdDict;

type
  /// <summary>
  ///   A table of strings by id (idLangDict): keys like <c>#str_00123</c>, values of text. It reads
  ///   and writes the language files of Doom 3 (<c>{ "#str_00001" "text" ... }</c>). The log (messages
  ///   and the warning of an unknown id) and the file system come from the constructor.
  ///   <para>The hash index of the original (a hash of the number in the key) is a scan from the
  ///   newest pair, which gives the same answer: of two pairs with the same key the later one wins.
  ///   <c>Save</c> raises EIdLibException if the file cannot be written (the original dereferences nil).
  ///   <c>GetString</c> returns the text of the string; the key of an unknown id is returned as it came.</para>
  /// </summary>
  TIdLangDict = class
  strict private
    FEntries: TArray<TIdKeyValue>;
    FBaseId: Integer;
    FLog: IIdLibLog;
    FFileSystem: IIdLibFileSystem;
    function ExcludeString(const AText: AnsiString): Boolean;
    function GetNextId: Integer;
    procedure Append(const AKey, AValue: AnsiString);
  public
    constructor Create(const ALog: IIdLibLog = nil; const AFileSystem: IIdLibFileSystem = nil);
    procedure Clear;
    /// <summary>
    ///   Reads a language file (idLangDict::Load): false if it cannot be read or is empty (the caller
    ///   resets the language); <c>AClear</c> clears the table first
    /// </summary>
    function Load(const AFileName: AnsiString; const AClear: Boolean = True): Boolean;
    /// <summary>Writes the table as a language file</summary>
    procedure Save(const AFileName: AnsiString);
    /// <summary>
    ///   The key of the string, adding it with a new key (<c>#str_%08i</c>) if it is not in the table;
    ///   strings that are not worth translating are returned as they are (idLangDict::AddString)
    /// </summary>
    function AddString(const AText: AnsiString): AnsiString;
    /// <summary>The text of the string id; other texts come back unchanged, an unknown id gives a warning</summary>
    function GetString(const AText: AnsiString): AnsiString;
    /// <summary>Adds the pair as passed (no key is generated and nothing is checked)</summary>
    procedure AddKeyVal(const AKey, AValue: AnsiString);
    function GetNumKeyVals: Integer;
    /// <summary>The pair at the index (false out of range)</summary>
    function TryGetKeyVal(const AIndex: Integer; out AKeyValue: TIdKeyValue): Boolean;
    /// <summary>The first id AddString gives out (idLangDict::SetBaseID)</summary>
    property BaseId: Integer read FBaseId write FBaseId;
  end;

implementation

uses
  DelphiDoom.IdLib.Core.Exceptions, DelphiDoom.IdLib.Text.Types, DelphiDoom.IdLib.Text.Token,
  DelphiDoom.IdLib.Text.Lexer, DelphiDoom.IdLib.Text.Strings, DelphiDoom.IdLib.Text.Str,
  DelphiDoom.Scanner.IdCNumbers;

const
  STRTABLE_ID: AnsiString = '#str_';
  STRTABLE_ID_LENGTH = 5;

{ TIdLangDict }

constructor TIdLangDict.Create(const ALog: IIdLibLog; const AFileSystem: IIdLibFileSystem);
begin
  inherited Create;
  FLog := ALog;
  FFileSystem := AFileSystem;
end;

procedure TIdLangDict.Clear;
begin
  FEntries := nil;
end;

procedure TIdLangDict.Append(const AKey, AValue: AnsiString);
begin
  SetLength(FEntries, System.Length(FEntries) + 1);
  FEntries[High(FEntries)].Key := AKey;
  FEntries[High(FEntries)].Value := AValue;
end;

function TIdLangDict.Load(const AFileName: AnsiString; const AClear: Boolean): Boolean;
var
  LSource: TIdLexer;
  LFile: TIdLibFileData;
  LText: AnsiString;
  LToken, LToken2: TIdToken;
  LLength: Integer;
begin
  if AClear then
    Clear;
  if (not Assigned(FFileSystem)) or (not FFileSystem.TryReadFile(AFileName, False, LFile)) or
    (System.Length(LFile.Data) <= 0) then
    // let whoever called us deal with the failure (so sys_lang can be reset)
    Exit(False);
  SetString(LText, PAnsiChar(@LFile.Data[0]), System.Length(LFile.Data));
  // strlen of the buffer: the text ends at the first NUL
  LLength := TIdStrings.Length(LText);
  LSource := TIdLexer.Create(LEXFL_NOFATALERRORS or LEXFL_NOSTRINGCONCAT or LEXFL_ALLOWMULTICHARLITERALS or
    LEXFL_ALLOWBACKSLASHSTRINGCONCAT, FLog, FFileSystem);
  try
    LSource.LoadMemory(LText, LLength, AFileName);
    if not LSource.IsLoaded then
      Exit(False);
    LToken := TIdToken.Create;
    LToken2 := TIdToken.Create;
    LSource.ExpectTokenString('{');
    while LSource.ReadToken(LToken) do
    begin
      if LToken.IsText('}') then
        Break;
      if LSource.ReadToken(LToken2) then
      begin
        if LToken2.IsText('}') then
          Break;
        Append(LToken.Text, LToken2.Text);
      end;
    end;
  finally
    LSource.Free;
  end;
  if Assigned(FLog) then
    FLog.Printf(Format('%d strings read from %s'#10, [System.Length(FEntries), string(AFileName)]));
  Result := True;
end;

procedure TIdLangDict.Save(const AFileName: AnsiString);
var
  LText: AnsiString;
  LIndex, LChar: Integer;
  LValue: AnsiString;
  LBytes: TBytes;
begin
  LText := '// string table'#10'// english'#10'//'#10#10'{'#10;
  for LIndex := 0 to High(FEntries) do
  begin
    LText := LText + #9'"' + Copy(FEntries[LIndex].Key, 1, TIdStrings.Length(FEntries[LIndex].Key)) + '"'#9'"';
    LValue := FEntries[LIndex].Value;
    for LChar := 1 to TIdStrings.Length(LValue) do
    begin
      if LValue[LChar] = #9 then
        LText := LText + '\t'
      else if (LValue[LChar] = #10) or (LValue[LChar] = #13) then
        LText := LText + '\n'
      else
        LText := LText + LValue[LChar];
    end;
    LText := LText + '"'#10;
  end;
  LText := LText + #10'}'#10;
  SetLength(LBytes, System.Length(LText));
  if System.Length(LText) > 0 then
    Move(LText[1], LBytes[0], System.Length(LText));
  if (not Assigned(FFileSystem)) or (not FFileSystem.WriteFile(AFileName, LBytes)) then
    raise EIdLibException.Create('idLangDict::Save: cannot write ' + string(AFileName));
end;

function TIdLangDict.GetString(const AText: AnsiString): AnsiString;
var
  LIndex: Integer;
begin
  if (AText = '') or (AText[1] = #0) then
    Exit('');
  if TIdStrings.Cmpn(AText, STRTABLE_ID, STRTABLE_ID_LENGTH) <> 0 then
    Exit(AText);
  // the hash chain lists the newest pair first
  for LIndex := High(FEntries) downto 0 do
    if TIdStrings.Cmp(FEntries[LIndex].Key, AText) = 0 then
      Exit(FEntries[LIndex].Value);
  if Assigned(FLog) then
    FLog.Warning(Format('Unknown string id %s', [string(AText)]));
  Result := AText;
end;

function TIdLangDict.AddString(const AText: AnsiString): AnsiString;
var
  LIndex, LId: Integer;
begin
  if ExcludeString(AText) then
    Exit(AText);
  for LIndex := 0 to High(FEntries) do
    if TIdStrings.Cmp(FEntries[LIndex].Value, AText) = 0 then
      Exit(FEntries[LIndex].Key);
  LId := GetNextId;
  Append(AnsiString(Format('#str_%.8d', [LId])), AText);
  Result := FEntries[High(FEntries)].Key;
end;

procedure TIdLangDict.AddKeyVal(const AKey, AValue: AnsiString);
begin
  Append(AKey, AValue);
end;

function TIdLangDict.GetNumKeyVals: Integer;
begin
  Result := System.Length(FEntries);
end;

function TIdLangDict.TryGetKeyVal(const AIndex: Integer; out AKeyValue: TIdKeyValue): Boolean;
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

function TIdLangDict.ExcludeString(const AText: AnsiString): Boolean;
var
  LLength, LIndex: Integer;
begin
  LLength := TIdStrings.Length(AText);
  if LLength <= 1 then
    Exit(True);
  if TIdStrings.Cmpn(AText, STRTABLE_ID, STRTABLE_ID_LENGTH) = 0 then
    Exit(True);
  if TIdStrings.Icmpn(AText, 'gui::', 5) = 0 then
    Exit(True);
  if AText[1] = '$' then
    Exit(True);
  for LIndex := 1 to LLength do
    if TIdStrings.CharIsAlpha(Ord(AText[LIndex])) then
      Exit(False);
  Result := True;
end;

function TIdLangDict.GetNextId: Integer;
var
  LIndex, LTest: Integer;
  LWork: TIdStr;
begin
  Result := FBaseId;
  if System.Length(FEntries) = 0 then
    Exit;
  for LIndex := 0 to High(FEntries) do
  begin
    LWork := TIdStr.Create(FEntries[LIndex].Key);
    LWork.StripLeading(STRTABLE_ID);
    LTest := TIdCNumbers.Atoi(LWork.Text);
    if LTest > Result then
      Result := LTest;
  end;
  Inc(Result);
end;

end.
