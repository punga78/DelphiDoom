{******************************************************************************}
{                                                                              }
{  DelphiDoom: MUSINFO library - the parser                                   }
{  Copyright (C) 2004-2023 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MusInfo.Parser;

interface

uses
  DelphiDoom.Logging.Intf, DelphiDoom.MusInfo.Types, DelphiDoom.MusInfo.Intf;

type
  /// <summary>
  ///   The text of the MUSINFO lump (the reading part of the old P_InitMusInfo): a map name
  ///   (ExMy or MAPxx) and, for each music of the map, an id and the name of the music
  /// </summary>
  /// <remarks>
  ///   Anything that is not a map name is taken as the id of a music, and the next word as its
  ///   name. A text that begins with something else than a map name, an empty name and a name
  ///   that is not a lump name end the reading of the text; an id out of range is skipped
  /// </remarks>
  TMusInfoParser = class(TInterfacedObject, IMusInfoParser)
  private
    FLog: ILog;
    class function IsDigit(AChar: Char): Boolean; static;
    class function IsMapName(const AUpperToken: string): Boolean; static;
    /// <summary>The old atoi with a default: decimal, hexadecimal with $, 0x, x, -0x or #</summary>
    class function ToInteger(const AText: string; ADefault: Integer): Integer; static;
  public
    /// <param name="ALog">May be nil</param>
    constructor Create(const ALog: ILog);
    function Parse(const AText: string): TArray<TMusInfoEntry>;
  end;

implementation

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.Scanner.Strings, DelphiDoom.Scanner.Scanner;

{ TMusInfoParser }

constructor TMusInfoParser.Create(const ALog: ILog);
begin
  inherited Create;
  FLog := ALog;
end;

class function TMusInfoParser.IsDigit(AChar: Char): Boolean;
begin
  Result := (AChar >= '0') and (AChar <= '9');
end;

class function TMusInfoParser.IsMapName(const AUpperToken: string): Boolean;
begin
  Result := False;
  if Length(AUpperToken) = 4 then
    Result := (AUpperToken[1] = 'E') and (AUpperToken[3] = 'M') and IsDigit(AUpperToken[2]) and
      IsDigit(AUpperToken[4])
  else if Length(AUpperToken) = 5 then
    Result := (Copy(AUpperToken, 1, 3) = 'MAP') and IsDigit(AUpperToken[4]) and
      IsDigit(AUpperToken[5]);
end;

class function TMusInfoParser.ToInteger(const AText: string; ADefault: Integer): Integer;
var
  LCode: Integer;
  LFallback: Integer;
begin
  Val(AText, Result, LCode);
  if LCode = 0 then
    Exit;

  LFallback := ADefault;
  LCode := -1;
  if Copy(AText, 1, 2) = '0x' then
    Val('$' + Copy(AText, 3, MaxInt), LFallback, LCode)
  else if Copy(AText, 1, 3) = '-0x' then
  begin
    Val('$' + Copy(AText, 4, MaxInt), LFallback, LCode);
    LFallback := -LFallback;
  end
  else if Copy(AText, 1, 1) = '#' then
    Val(Copy(AText, 2, MaxInt), LFallback, LCode);

  if LCode = 0 then
    Result := LFallback
  else
    Result := ADefault;
end;

function TMusInfoParser.Parse(const AText: string): TArray<TMusInfoEntry>;
var
  LScanner: TScriptScanner;
  LEntries: TList<TMusInfoEntry>;
  LEntry: TMusInfoEntry;
  LToken: string;
  LCurrentMap: string;
  LIdText: string;
  LMusicId: Integer;
  LMusicName: string;
begin
  LEntries := TList<TMusInfoEntry>.Create;
  LScanner := TScriptScanner.Create(AText, FLog);
  try
    LCurrentMap := '';
    while LScanner.GetString do
    begin
      LToken := TScannerStrings.UpperAscii(LScanner.AsString);
      if LToken = '' then
        Break;

      if IsMapName(LToken) then
        LCurrentMap := LToken
      else
      begin
        if LCurrentMap = '' then
        begin
          LScanner.Warn('P_InitMusInfo(): Map name expected but token "%s" found', [LToken]);
          Break;
        end;

        LIdText := LScanner.AsString;
        LMusicId := ToInteger(LIdText, -1);
        // when the name is missing the scanner keeps the id as its word, like it always did
        LScanner.MustGetString;
        LMusicName := LScanner.AsString;

        if (LMusicId >= 0) and (LMusicId <= MUSINFO_MAX_MUSIC_ID) then
        begin
          if LMusicName = '' then
            Break;
          if Length(LMusicName) > MUSINFO_NAME_LENGTH then
            LScanner.Warn('P_InitMusInfo(): Music name "%s" is too long, maximum size is %d characters',
              [LMusicName, MUSINFO_NAME_LENGTH])
          else
          begin
            LEntry.MapName := LCurrentMap;
            LEntry.MusicId := LMusicId;
            LEntry.MusicName := TScannerStrings.UpperAscii(LMusicName);
            LEntry.MusicNumber := -1;
            LEntries.Add(LEntry);
          end;
        end
        else
          LScanner.Warn('P_InitMusInfo(): Invalid music id "%s" found, expected number in range [%d, %d]',
            [LIdText, 0, MUSINFO_MAX_MUSIC_ID]);
      end;
    end;
    Result := LEntries.ToArray;
  finally
    LScanner.Free;
    LEntries.Free;
  end;
end;

end.
