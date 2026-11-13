{******************************************************************************}
{                                                                              }
{  DelphiDoom: WAD library - file system of id Tech 4: the addon.conf          }
{                                                                              }
{  Port of idFileSystemLocal::ParseAddonDef of framework\FileSystem.cpp (id    }
{  Software, GPL v3). Copyright (C) 1999-2011 id Software LLC, a ZeniMax       }
{  Media company.                                                              }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software). This unit is derived     }
{  from it and is therefore available under the GNU General Public License,    }
{  version 3, with the additional terms of the Doom 3 Source Code License      }
{  (see Reference\doom3\README.txt and Libs\IdLib\README.md); the repository   }
{  as a whole is GPL v2 or later.                                              }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Wad.Fs.AddonParser;

interface

uses
  System.SysUtils, DelphiDoom.IdLib.Core.Intf, DelphiDoom.Wad.Fs.Types;

type
  /// <summary>
  ///   Reads the <c>addonDef { "checksum" ... }</c> and the <c>mapDef "path" { "key" "value" ... }</c> entries of an
  ///   addon.conf. Problems are warnings to the log, as the lexer of the original writes them, and the
  ///   call gives False (the original returns NULL).
  /// </summary>
  TGameAddonParser = class sealed
  strict private
    class procedure SetPair(var AMapDef: TGameAddonMapDef; const AKey, AValue: string); static;
  public
    /// <summary>
    ///   The two <c>sscanf</c> of the original (<c>"0x%x"</c>, then <c>"%x"</c>): white space, a sign, an optional
    ///   "0x" and hexadecimal digits up to the first other character; the value wraps at 32 bits
    /// </summary>
    class function ParseChecksum(const AText: AnsiString; out AValue: Cardinal): Boolean; static;
    /// <summary>
    ///   ParseAddonDef: the text may end after the addonDef (an addon.conf with no mapDef is valid). The log
    ///   may be nil. A checksum is "0x" and hexadecimal digits, or hexadecimal digits alone, as the two
    ///   <c>sscanf</c> of the original accept.
    /// </summary>
    class function Parse(const AText: AnsiString; out AInfo: TGameAddonInfo; const ALog: IIdLibLog = nil): Boolean; static;
  end;

implementation

uses
  DelphiDoom.IdLib.Text.Types, DelphiDoom.IdLib.Text.Token, DelphiDoom.IdLib.Text.Lexer;

const
  // DECL_LEXER_FLAGS of the declaration manager: the lexer flags the original reads the addon.conf with
  LEXER_FLAGS = LEXFL_NOSTRINGCONCAT or LEXFL_NOSTRINGESCAPECHARS or LEXFL_ALLOWPATHNAMES or
    LEXFL_ALLOWMULTICHARLITERALS or LEXFL_ALLOWBACKSLASHSTRINGCONCAT or LEXFL_NOFATALERRORS;
  SConfName = '<addon.conf>';

{ TGameAddonParser }

class function TGameAddonParser.ParseChecksum(const AText: AnsiString; out AValue: Cardinal): Boolean;
var
  LIndex: Integer;
  LDigits: Int64;
  LCount: Integer;
  LChar: AnsiChar;
  LNegative: Boolean;
begin
  AValue := 0;
  LIndex := 1;
  // sscanf skips the white space before a number
  while (LIndex <= Length(AText)) and (AText[LIndex] in [#9, #10, #13, ' ']) do
    Inc(LIndex);
  LNegative := (LIndex <= Length(AText)) and (AText[LIndex] = '-');
  if (LIndex <= Length(AText)) and (AText[LIndex] in ['-', '+']) then
    Inc(LIndex);
  LDigits := 0;
  LCount := 0;
  // the prefix "0x"; without a digit after it the "0" is the number (what the %x of the C library reads)
  if (LIndex + 1 <= Length(AText)) and (AText[LIndex] = '0') and (AText[LIndex + 1] in ['x', 'X']) then
  begin
    Inc(LIndex, 2);
    LCount := 1;
  end;
  while LIndex <= Length(AText) do
  begin
    LChar := AText[LIndex];
    case LChar of
      '0'..'9':
        LDigits := (LDigits shl 4) or (Ord(LChar) - Ord('0'));
      'a'..'f':
        LDigits := (LDigits shl 4) or (Ord(LChar) - Ord('a') + 10);
      'A'..'F':
        LDigits := (LDigits shl 4) or (Ord(LChar) - Ord('A') + 10);
    else
      Break;
    end;
    // the value wraps at 32 bits as the int of sscanf does
    LDigits := LDigits and $FFFFFFFF;
    Inc(LCount);
    Inc(LIndex);
  end;
  Result := LCount > 0;
  if Result then
  begin
    // a minus sign negates the value, which wraps at 32 bits
    if LNegative then
      LDigits := (-LDigits) and $FFFFFFFF;
    AValue := Cardinal(LDigits);
  end;
end;

class procedure TGameAddonParser.SetPair(var AMapDef: TGameAddonMapDef; const AKey, AValue: string);
var
  LIndex: Integer;
begin
  // idDict::Set: a key that exists keeps its place and takes the new value
  for LIndex := 0 to High(AMapDef.Keys) do
    if SameText(AMapDef.Keys[LIndex], AKey) then
    begin
      AMapDef.Values[LIndex] := AValue;
      Exit;
    end;
  SetLength(AMapDef.Keys, Length(AMapDef.Keys) + 1);
  SetLength(AMapDef.Values, Length(AMapDef.Values) + 1);
  AMapDef.Keys[High(AMapDef.Keys)] := AKey;
  AMapDef.Values[High(AMapDef.Values)] := AValue;
end;

class function TGameAddonParser.Parse(const AText: AnsiString; out AInfo: TGameAddonInfo;
  const ALog: IIdLibLog): Boolean;
var
  LLexer: TIdLexer;
  LToken, LValue: TIdToken;
  LChecksum: Cardinal;
  LMapDef: TGameAddonMapDef;
  LAlreadyDefined: Boolean;
  LIndex: Integer;
begin
  AInfo := Default(TGameAddonInfo);
  Result := False;
  LLexer := TIdLexer.Create(LEXER_FLAGS, ALog);
  try
    LLexer.LoadMemory(AText, Length(AText), SConfName);
    if not LLexer.SkipUntilString('addonDef') then
    begin
      LLexer.Warning('ParseAddonDef: no addonDef', []);
      Exit;
    end;
    if not LLexer.ReadToken(LToken) then
    begin
      LLexer.Warning('Expected {', []);
      Exit;
    end;
    // the checksums of the paks it depends on
    while True do
    begin
      if not LLexer.ReadToken(LToken) then
        Exit;
      if LToken.IsText('}') then
        Break;
      if LToken.TokenType <> TT_STRING then
      begin
        LLexer.Warning('Expected quoted string, but found ''%s''', [string(LToken.Text)]);
        Exit;
      end;
      if not ParseChecksum(LToken.Text, LChecksum) then
      begin
        LLexer.Warning('Could not parse checksum ''%s''', [string(LToken.Text)]);
        Exit;
      end;
      SetLength(AInfo.Depends, Length(AInfo.Depends) + 1);
      AInfo.Depends[High(AInfo.Depends)] := LChecksum;
    end;
    // any number of mapDef entries
    while True do
    begin
      if not LLexer.SkipUntilString('mapDef') then
        Exit(True);
      if not LLexer.ReadToken(LToken) then
      begin
        LLexer.Warning('Expected map path', []);
        AInfo.MapDefs := nil;
        Exit;
      end;
      LMapDef := Default(TGameAddonMapDef);
      SetPair(LMapDef, 'path', string(LToken.Text));
      if not LLexer.ReadToken(LToken) then
      begin
        LLexer.Warning('Expected {', []);
        AInfo.MapDefs := nil;
        Exit;
      end;
      while True do
      begin
        if not LLexer.ReadToken(LToken) then
          Break;
        if LToken.IsText('}') then
          Break;
        if LToken.TokenType <> TT_STRING then
        begin
          LLexer.Warning('Expected quoted string, but found ''%s''', [string(LToken.Text)]);
          AInfo.MapDefs := nil;
          Exit;
        end;
        if not LLexer.ReadToken(LValue) then
        begin
          LLexer.Warning('Unexpected end of file', []);
          AInfo.MapDefs := nil;
          Exit;
        end;
        LAlreadyDefined := False;
        for LIndex := 0 to High(LMapDef.Keys) do
          if SameText(LMapDef.Keys[LIndex], string(LToken.Text)) then
            LAlreadyDefined := True;
        if LAlreadyDefined then
          LLexer.Warning('''%s'' already defined', [string(LToken.Text)]);
        SetPair(LMapDef, string(LToken.Text), string(LValue.Text));
      end;
      SetLength(AInfo.MapDefs, Length(AInfo.MapDefs) + 1);
      AInfo.MapDefs[High(AInfo.MapDefs)] := LMapDef;
    end;
  finally
    LLexer.Free;
  end;
end;

end.
