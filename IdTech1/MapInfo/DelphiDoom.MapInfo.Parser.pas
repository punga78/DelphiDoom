{******************************************************************************}
{                                                                              }
{  DelphiDoom: UMAPINFO library - the parser                                  }
{  Copyright (C) 2004-2023 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapInfo.Parser;

interface

uses
  DelphiDoom.Logging.Intf, DelphiDoom.Scanner.Scanner, DelphiDoom.MapInfo.Types,
  DelphiDoom.MapInfo.Intf;

type
  /// <summary>
  ///   The parser of UMAPINFO (the old U_ParseStandardProperty and ParseMapEntry). The game
  ///   decides through its services what is a valid map, which music exists, which actors
  ///   a bossaction knows and which bossaction lines it takes
  /// </summary>
  TMapInfoParser = class(TInterfacedObject, IMapInfoParser)
  private
    FServices: TMapInfoServices;
    FLog: ILog;
    function ParseMultiString(AScanner: TScriptScanner): string;
    function ParseLumpName(AScanner: TScriptScanner; var ABuffer: string): Boolean;
    function ParseEpisode(AScanner: TScriptScanner; const AEntry: TMapInfoEntry): Boolean;
    function ParseBossAction(AScanner: TScriptScanner; var AEntry: TMapInfoEntry): Boolean;
    function ParseStandardProperty(AScanner: TScriptScanner; var AEntry: TMapInfoEntry): Boolean;
    function ParseMapEntry(AScanner: TScriptScanner; var AEntry: TMapInfoEntry): Boolean;
  public
    /// <param name="AServices">Every service but the episodes has to be there</param>
    /// <param name="ALog">May be nil</param>
    constructor Create(const AServices: TMapInfoServices; const ALog: ILog);
    function Parse(const AText: string): TArray<TMapInfoEntry>;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Scanner.Strings, DelphiDoom.MapInfo.TextPreparer;

const
  SMustBeServed = 'TMapInfoParser needs the services of the game';

{ TMapInfoParser }

constructor TMapInfoParser.Create(const AServices: TMapInfoServices; const ALog: ILog);
begin
  inherited Create;
  if not (Assigned(AServices.Validator) and Assigned(AServices.Lumps) and
    Assigned(AServices.Music) and Assigned(AServices.Actors) and Assigned(AServices.BossRule)) then
    raise EArgumentNilException.Create(SMustBeServed);
  FServices := AServices;
  FLog := ALog;
end;

function TMapInfoParser.ParseMultiString(AScanner: TScriptScanner): string;
var
  LIndex: Integer;
begin
  AScanner.MustGetString;
  if not AScanner.QuotedToken then
  begin
    if TScannerStrings.UpperAscii(AScanner.AsString) = 'CLEAR' then
      // this was explicitly deleted to override the default
      Exit('-');
    AScanner.Warn('UMAPINO.U_ParseMultiString(): Either ''clear'' or string constant expected');
    Exit('');
  end;
  Result := AScanner.AsString;

  while AScanner.GetString do
  begin
    if not AScanner.QuotedToken then
    begin
      AScanner.UnGet;
      Break;
    end;
    Result := Result + #13#10 + AScanner.AsString;
  end;

  // a C style "\n" is a line break
  for LIndex := 2 to Length(Result) do
    if Result[LIndex] = 'n' then
      if Result[LIndex - 1] = '\' then
      begin
        Result[LIndex - 1] := #13;
        Result[LIndex] := #10;
      end;
end;

function TMapInfoParser.ParseLumpName(AScanner: TScriptScanner; var ABuffer: string): Boolean;
begin
  if not AScanner.GetString then
    Exit(False);

  if Length(AScanner.AsString) > MAPINFO_LUMP_NAME_LENGTH then
  begin
    AScanner.Warn('UMAPINO.ParseLumpName(): String ''%s'' is too long. Maximum size is 8 characters.',
      [AScanner.AsString]);
    // not a parse error
    Exit(True);
  end;

  ABuffer := TScannerStrings.UpperAscii(AScanner.AsString);
  Result := True;
end;

function TMapInfoParser.ParseEpisode(AScanner: TScriptScanner; const AEntry: TMapInfoEntry): Boolean;
var
  LLumpName: string;
  LAltText: string;
  LKey: Char;
begin
  Result := True;
  if not AScanner.MustGetString then
    Exit;
  if not AScanner.QuotedToken then
  begin
    if TScannerStrings.UpperAscii(AScanner.AsString) = 'CLEAR' then
      FServices.Episodes.ClearEpisodes
    else
      AScanner.Warn('UMAPINFO.U_ParseStandardProperty(): Either ''clear'' or string constant expected after ''episode'' keyword');
    Exit;
  end;

  AScanner.UnGet;
  LLumpName := '';
  LAltText := '';
  LKey := #0;
  ParseLumpName(AScanner, LLumpName);
  if AScanner.MustGetString then
  begin
    if AScanner.QuotedToken then
    begin
      LAltText := AScanner.AsString;
      if AScanner.MustGetString then
      begin
        if AScanner.QuotedToken and (AScanner.AsString <> '') then
          LKey := AScanner.AsString[1]
        else
          AScanner.UnGet;
      end;
    end
    else
      AScanner.UnGet;
  end;
  FServices.Episodes.AddEpisode(AEntry.MapName, LLumpName, LAltText, LKey);
end;

function TMapInfoParser.ParseBossAction(AScanner: TScriptScanner; var AEntry: TMapInfoEntry): Boolean;
var
  LType: Integer;
  LSpecial: Integer;
  LTag: Integer;
  LAction: TMapInfoBossAction;
begin
  Result := True;
  if not AScanner.MustGetString then
    Exit;
  if TScannerStrings.UpperAscii(AScanner.AsString) = 'CLEAR' then
  begin
    // the level is free of boss actions
    AEntry.BossActions := nil;
    AEntry.BossActionsCleared := True;
    Exit;
  end;

  LType := FServices.Actors.ActorTypeFor(TScannerStrings.UpperAscii(AScanner.AsString));
  if LType < 0 then
  begin
    AScanner.Warn('UMAPINO.U_ParseStandardProperty(): bossaction: unknown thing type ''%s''',
      [AScanner.AsString]);
    Exit(False);
  end;
  AScanner.MustGetInteger;
  LSpecial := AScanner.AsInteger;
  AScanner.MustGetInteger;
  LTag := AScanner.AsInteger;
  // the game decides which lines it takes (no 0-tag specials, unless a level exit)
  if FServices.BossRule.IsAccepted(LSpecial, LTag) then
  begin
    LAction.ActorType := LType;
    LAction.Special := LSpecial;
    LAction.Tag := LTag;
    AEntry.BossActionsCleared := False;
    SetLength(AEntry.BossActions, Length(AEntry.BossActions) + 1);
    AEntry.BossActions[High(AEntry.BossActions)] := LAction;
  end;
end;

function TMapInfoParser.ParseStandardProperty(AScanner: TScriptScanner;
  var AEntry: TMapInfoEntry): Boolean;
var
  LName: string;
  LText: string;
begin
  if not AScanner.GetString then
    Exit(False);

  LName := TScannerStrings.UpperAscii(AScanner.AsString);
  if LName = '_ENDBLOCK' then
    Exit(False);

  if not AScanner.GetString then
    Exit(False);

  if AScanner.AsString <> '=' then
  begin
    AScanner.Warn('UMAPINO.U_ParseStandardProperty(): ''='' expected but ''%s'' found.',
      [AScanner.AsString]);
    Exit(False);
  end;

  Result := True;

  if LName = 'LEVELNAME' then
  begin
    if AScanner.MustGetString then
      AEntry.LevelName := Copy(AScanner.AsString, 1, MAPINFO_TITLE_LENGTH);
  end
  else if LName = 'LABEL' then
  begin
    if AScanner.MustGetString then
    begin
      if AScanner.QuotedToken then
        AEntry.MapLabel := Copy(AScanner.AsString, 1, MAPINFO_TITLE_LENGTH)
      else if TScannerStrings.UpperAscii(AScanner.AsString) = 'CLEAR' then
        AEntry.MapLabel := '-'
      else
        AScanner.Warn('UMAPINFO.U_ParseStandardProperty(): Either ''clear'' or string constant expected after ''label'' keyword');
    end;
  end
  else if (LName = 'EPISODE') and Assigned(FServices.Episodes) then
    ParseEpisode(AScanner, AEntry)
  else if LName = 'NEXT' then
  begin
    Result := ParseLumpName(AScanner, AEntry.NextMap);
    if not FServices.Validator.IsValidMapName(AEntry.NextMap) then
    begin
      AScanner.Warn('UMAPINFO.U_ParseStandardProperty(): Invalid map name ''%s''', [AEntry.NextMap]);
      Result := False;
    end;
  end
  else if LName = 'NEXTSECRET' then
  begin
    Result := ParseLumpName(AScanner, AEntry.NextSecret);
    if not FServices.Validator.IsValidMapName(AEntry.NextSecret) then
    begin
      AScanner.Warn('UMAPINFO.U_ParseStandardProperty(): Invalid map name ''%s''', [AEntry.NextSecret]);
      Result := False;
    end;
  end
  else if LName = 'LEVELPIC' then
    Result := ParseLumpName(AScanner, AEntry.LevelPic)
  else if (LName = 'SKYTEXTURE') or (LName = 'SKYTEXTURE1') then
    Result := ParseLumpName(AScanner, AEntry.SkyTexture)
  else if LName = 'SKYTEXTURE2' then
    Result := ParseLumpName(AScanner, AEntry.SkyTexture2)
  else if LName = 'MUSIC' then
  begin
    Result := ParseLumpName(AScanner, AEntry.Music);
    if Result then
    begin
      if FServices.Lumps.LumpExists(AEntry.Music) then
        AEntry.MusicNumber := FServices.Music.MusicNumberFor(AEntry.Music)
      else
      begin
        AEntry.Music := '';
        AEntry.MusicNumber := 0;
      end;
    end;
  end
  else if LName = 'ENDPIC' then
    Result := ParseLumpName(AScanner, AEntry.EndPic)
  else if LName = 'ENDCAST' then
  begin
    if AScanner.MustGetBoolean then
    begin
      if AScanner.AsBoolean then
        AEntry.EndPic := '$CAST'
      else
        AEntry.EndPic := '-';
    end;
  end
  else if LName = 'ENDBUNNY' then
  begin
    if AScanner.MustGetBoolean then
    begin
      if AScanner.AsBoolean then
        AEntry.EndPic := '$BUNNY'
      else
        AEntry.EndPic := '-';
    end;
  end
  else if LName = 'ENDGAME' then
  begin
    if AScanner.MustGetBoolean then
    begin
      if AScanner.AsBoolean then
        AEntry.EndPic := '!'
      else
        AEntry.EndPic := '-';
    end;
  end
  else if LName = 'EXITPIC' then
    Result := ParseLumpName(AScanner, AEntry.ExitPic)
  else if LName = 'ENTERPIC' then
    Result := ParseLumpName(AScanner, AEntry.EnterPic)
  else if LName = 'LIGHTNING' then
  begin
    if AScanner.MustGetBoolean then
      AEntry.Lightning := AScanner.AsBoolean;
  end
  else if LName = 'NOJUMP' then
  begin
    if AScanner.MustGetBoolean then
      AEntry.NoJump := AScanner.AsBoolean;
  end
  else if LName = 'NOCROUCH' then
  begin
    if AScanner.MustGetBoolean then
      AEntry.NoCrouch := AScanner.AsBoolean;
  end
  else if LName = 'NOINTERMISSION' then
  begin
    if AScanner.MustGetBoolean then
      AEntry.NoIntermission := AScanner.AsBoolean;
  end
  else if LName = 'PARTIME' then
  begin
    if AScanner.MustGetInteger then
      AEntry.ParTime := MAPINFO_TICRATE * AScanner.AsInteger;
  end
  else if LName = 'INTERTEXT' then
  begin
    LText := ParseMultiString(AScanner);
    if LText = '' then
      Exit(False);
    AEntry.InterText := LText;
  end
  else if LName = 'INTERTEXTSECRET' then
  begin
    LText := ParseMultiString(AScanner);
    if LText = '' then
      Exit(False);
    AEntry.InterTextSecret := LText;
  end
  else if LName = 'INTERBACKDROP' then
    Result := ParseLumpName(AScanner, AEntry.InterBackdrop)
  else if LName = 'INTERMUSIC' then
  begin
    Result := ParseLumpName(AScanner, AEntry.InterMusic);
    if Result then
    begin
      if FServices.Lumps.LumpExists(AEntry.InterMusic) then
        AEntry.InterMusicNumber := FServices.Music.MusicNumberFor(AEntry.InterMusic)
      else
      begin
        AEntry.InterMusic := '';
        AEntry.InterMusicNumber := 0;
      end;
    end;
  end
  else if LName = 'BOSSACTION' then
    Result := ParseBossAction(AScanner, AEntry)
  else
    // no known property: all the values after the = sign are skipped
    AScanner.GetStringEOLUnchanged;
end;

function TMapInfoParser.ParseMapEntry(AScanner: TScriptScanner; var AEntry: TMapInfoEntry): Boolean;
begin
  AEntry.MapName := '';

  AScanner.GetString;
  if AScanner.AsString = '_ENDBLOCK' then
    AScanner.GetString;

  if AScanner.Finished then
    Exit(False);
  AScanner.UnGet;

  if not AScanner.MustGetStringName('map') then
    Exit(False);

  if AScanner.MustGetString then
    if not FServices.Validator.IsValidMapName(AScanner.AsString) then
    begin
      AScanner.Warn('UMAPINFO.ParseMapEntry(): Invalid map name ''%s''', [AScanner.AsString]);
      Exit(False);
    end;

  AEntry.MapName := Copy(TScannerStrings.UpperAscii(AScanner.AsString), 1, MAPINFO_LUMP_NAME_LENGTH);
  if AScanner.MustGetString then
    if AScanner.MatchString('_BEGINBLOCK') then
      while not AScanner.MatchString('_ENDBLOCK') and not AScanner.Finished do
        ParseStandardProperty(AScanner, AEntry);

  Result := True;
end;

function TMapInfoParser.Parse(const AText: string): TArray<TMapInfoEntry>;
var
  LScanner: TScriptScanner;
  LParsed: TMapInfoEntry;
begin
  Result := nil;
  LScanner := TScriptScanner.Create(TMapInfoTextPreparer.Prepare(AText), FLog);
  try
    while not LScanner.Finished do
    begin
      LParsed := Default(TMapInfoEntry);
      if not ParseMapEntry(LScanner, LParsed) then
      begin
        if LScanner.Finished then
          Break;
        LScanner.Warn('UMAPINFO.U_DoParseMapInfoLump(): Skipping entry: ''%s''', [LScanner.AsString]);
        Continue;
      end;
      SetLength(Result, Length(Result) + 1);
      Result[High(Result)] := LParsed;
    end;
  finally
    LScanner.Free;
  end;
end;

end.
