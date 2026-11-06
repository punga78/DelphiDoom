{******************************************************************************}
{                                                                              }
{  DelphiDoom: ActorDef library - the reading of a whole text                  }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.ActorDef.DocumentReader;

interface

uses
  System.SysUtils, DelphiDoom.Logging.Intf, DelphiDoom.Scanner.Scanner, DelphiDoom.ActorDef.Types,
  DelphiDoom.ActorDef.Intf, DelphiDoom.ActorDef.FlagReader, DelphiDoom.ActorDef.StateReader,
  DelphiDoom.ActorDef.ActorReader, DelphiDoom.ActorDef.WeaponReader;

type
  /// <summary>
  ///   Reads one text from the first word to the last: the things that it declares (ACTOR, WEAPON,
  ///   THINKER, ACTORALIAS, SCRIPT, GLOBAL, EXTERNAL, COMPILED, DEH_PARSE ...) go to the sinks
  ///   as each one ends. It keeps all the state of the reading, so another one can be going on
  ///   at the same time (a thinker is read as an actor)
  /// </summary>
  TActorDefDocumentReader = class
  private
    FScanner: TScriptScanner;
    FLog: ILog;
    FActors: IActorDefActorCatalog;
    FThinkers: IActorDefThinkerSink;
    FScripts: IActorDefScriptSink;
    FFlags: TActorDefFlagReader;
    FStates: TActorDefStateReader;
    FActorReader: TActorDefActorReader;
    FWeaponReader: TActorDefWeaponReader;
    procedure Warn(const AMessage: string);
    function FirstWordOf(const AText: string): string;
    procedure ReadThinker;
    procedure ReadInlineScript(AType: TActorDefScriptType);
    procedure ReadGlobal;
    procedure ReadCompiledScript;
    procedure ReadExternalScript(AType: TActorDefScriptType);
    procedure ReadActorAlias;
    procedure ReadDehParse(AAll: Boolean);
    procedure UnknownScriptToken;
    procedure SubmitPending;
  public
    constructor Create(const AText: string; const ALog: ILog; const AProfile: TActorDefProfile;
      const AFlags: IActorDefFlagCatalog; const ANames: IActorDefNameCatalog;
      const AActors: IActorDefActorCatalog; const ADefinitions: IActorDefDefinitionSink;
      const AThinkers: IActorDefThinkerSink; const AScripts: IActorDefScriptSink);
    destructor Destroy; override;
    procedure Run;
  end;

implementation

uses
  DelphiDoom.Scanner.Strings, DelphiDoom.ActorDef.Text;

{ TActorDefDocumentReader }

constructor TActorDefDocumentReader.Create(const AText: string; const ALog: ILog;
  const AProfile: TActorDefProfile; const AFlags: IActorDefFlagCatalog;
  const ANames: IActorDefNameCatalog; const AActors: IActorDefActorCatalog;
  const ADefinitions: IActorDefDefinitionSink; const AThinkers: IActorDefThinkerSink;
  const AScripts: IActorDefScriptSink);
begin
  inherited Create;
  FLog := ALog;
  FActors := AActors;
  FThinkers := AThinkers;
  FScripts := AScripts;
  FScanner := TScriptScanner.Create(AText, ALog);
  FFlags := TActorDefFlagReader.Create(FScanner, AFlags, AProfile, ALog);
  FStates := TActorDefStateReader.Create(FScanner, ALog);
  FActorReader := TActorDefActorReader.Create(FScanner, ALog, AProfile, FFlags, ANames, AActors,
    FStates, ADefinitions);
  FWeaponReader := TActorDefWeaponReader.Create(FScanner, ALog, AProfile, FFlags, ANames, FStates,
    ADefinitions);
end;

destructor TActorDefDocumentReader.Destroy;
begin
  FWeaponReader.Free;
  FActorReader.Free;
  FStates.Free;
  FFlags.Free;
  FScanner.Free;
  inherited Destroy;
end;

procedure TActorDefDocumentReader.Warn(const AMessage: string);
begin
  if Assigned(FLog) then
    FLog.Warning(AMessage);
end;

function TActorDefDocumentReader.FirstWordOf(const AText: string): string;
var
  LIndex: Integer;
begin
  // the first word, the separators being the tab, the space, ; and .
  for LIndex := 1 to Length(AText) do
    if CharInSet(AText[LIndex], [#9, ' ', ';', '.']) then
      Exit(TScannerStrings.Trim(Copy(AText, 1, LIndex - 1)));
  Result := AText;
end;

procedure TActorDefDocumentReader.UnknownScriptToken;
begin
  Warn(Format('SC_ActordefToDEH(): Unknown token "%s" found, "SCRIPT" expected'#13#10,
    [FScanner.AsString]));
end;

procedure TActorDefDocumentReader.SubmitPending;
begin
  FActorReader.Submit;
  FWeaponReader.Submit;
end;

procedure TActorDefDocumentReader.ReadThinker;
var
  LThinker: TActorDefThinker;
  LToken: string;
  LHasScript: Boolean;
  LHasRepeat: Boolean;
  LHasInterval: Boolean;
  LExpected: string;
begin
  FScanner.MustGetString;
  LThinker.Name := Copy(FScanner.AsString, 1, ACTORDEF_MAX_THINKER_TEXT);
  LThinker.Interval := 1;
  LThinker.Dn := -1;
  LThinker.RepeatCount := 0;
  LThinker.Script := '';

  FScanner.MustGetString;
  if not FScanner.NewLine then
  begin
    LThinker.Dn := TScannerStrings.ToInteger(FScanner.AsString);
    FScanner.MustGetString;
  end;

  LToken := TScannerStrings.UpperAscii(FScanner.AsString);
  LHasScript := False;
  LHasRepeat := False;
  LHasInterval := False;
  while ((LToken = 'SCRIPT') and not LHasScript) or ((LToken = 'REPEAT') and not LHasRepeat) or
    ((LToken = 'INTERVAL') and not LHasInterval) do
  begin
    if LToken = 'SCRIPT' then
    begin
      FScanner.MustGetString;
      LThinker.Script := Copy(FScanner.AsString, 1, ACTORDEF_MAX_THINKER_TEXT);
      LHasScript := True;
    end
    else if LToken = 'REPEAT' then
    begin
      FScanner.MustGetString;
      if FScanner.MatchString('FOREVER') then
        LThinker.RepeatCount := 0
      else
        LThinker.RepeatCount := TScannerStrings.ToInteger(FScanner.AsString);
      if FScanner.GetString then
      begin
        if LThinker.RepeatCount = 1 then
          LExpected := 'TIME'
        else
          LExpected := 'TIMES';
        if not FScanner.MatchString(LExpected) then
          FScanner.UnGet;
      end;
      LHasRepeat := True;
    end
    else if LToken = 'INTERVAL' then
    begin
      FScanner.MustGetInteger;
      LThinker.Interval := FScanner.AsInteger;
      LHasInterval := True;
    end;
    if FScanner.Finished then
      Break;
    FScanner.GetString;
    LToken := TScannerStrings.UpperAscii(FScanner.AsString);
  end;

  if LThinker.Script <> '' then
  begin
    if Assigned(FThinkers) then
      FThinkers.SubmitThinker(LThinker);
  end
  else
    Warn(Format('SC_ActordefToDEH(): "THINKER" %s does not have script'#13#10, [LThinker.Name]));
end;

procedure TActorDefDocumentReader.ReadInlineScript(AType: TActorDefScriptType);
var
  LName: string;
  LScript: string;
  LLine: string;
begin
  // inline script (source) inside the lump
  LScript := '';
  if FScanner.GetString then
  begin
    LName := FScanner.AsString;
    if LName <> '' then
    begin
      if LName[Length(LName)] = ';' then
        SetLength(LName, Length(LName) - 1);
      if Length(LName) > 0 then
      begin
        LLine := FScanner.GetStringEOLUnchanged;
        if LLine = '' then
          LLine := FScanner.GetStringEOLUnchanged;
        while (TScannerStrings.UpperAscii(FirstWordOf(LLine)) <> 'ENDSCRIPT') and
          not FScanner.Finished do
        begin
          if LScript = '' then
            LScript := LLine
          else
            LScript := LScript + #13#10 + LLine;
          LLine := FScanner.GetStringEOLUnchanged;
        end;
        if LScript <> '' then
          if Assigned(FScripts) then
            FScripts.AddSourceScript(LName, LScript, AType);
      end;
    end;
  end;
end;

procedure TActorDefDocumentReader.ReadExternalScript(AType: TActorDefScriptType);
var
  LName: string;
  LFile: string;
begin
  // external script (source) inside an external pak file
  FScanner.MustGetString;
  if TScannerStrings.UpperAscii(FScanner.AsString) = 'SCRIPT' then
  begin
    FScanner.MustGetString;
    LName := FScanner.AsString;
    FScanner.MustGetString;
    LFile := FScanner.AsString;
    if Assigned(FScripts) then
      FScripts.AddExternalScript(LName, LFile, AType);
  end
  else
    UnknownScriptToken;
end;

procedure TActorDefDocumentReader.ReadCompiledScript;
var
  LName: string;
  LFile: string;
begin
  // compiled script inside an external pak file
  FScanner.MustGetString;
  if TScannerStrings.UpperAscii(FScanner.AsString) = 'SCRIPT' then
  begin
    FScanner.MustGetString;
    LName := FScanner.AsString;
    FScanner.MustGetString;
    LFile := FScanner.AsString;
    if Assigned(FScripts) then
      FScripts.AddCompiledScript(LName, LFile);
  end
  else
    UnknownScriptToken;
end;

procedure TActorDefDocumentReader.ReadGlobal;
begin
  FScanner.MustGetString;
  if TScannerStrings.UpperAscii(FScanner.AsString) = 'SCRIPT' then
    ReadInlineScript(TActorDefScriptType.Global)
  else if FScanner.MatchString('EXTERNAL') then
    ReadExternalScript(TActorDefScriptType.Global)
  else
    UnknownScriptToken;
end;

procedure TActorDefDocumentReader.ReadActorAlias;
var
  LText: string;
  LInitial: string;
  LPosition: Integer;
  LIndex: Integer;
  LNames: TArray<string>;
  LTokens: TScriptScanner;
begin
  LText := FScanner.GetStringEOLWithQuotes;
  LInitial := LText;
  LPosition := Pos('//', LText);
  if LPosition > 0 then
    LText := Copy(LText, 1, LPosition - 1);

  for LIndex := 1 to Length(LText) do
    if LText[LIndex] = '=' then
      LText[LIndex] := ' ';

  LNames := nil;
  LTokens := TScriptScanner.Create(LText, FLog);
  try
    while LTokens.GetString do
    begin
      SetLength(LNames, Length(LNames) + 1);
      LNames[High(LNames)] := LTokens.AsString;
    end;
  finally
    LTokens.Free;
  end;

  if Length(LNames) < 2 then
    Warn(Format('DoParseActorAlias(): Invalid alias declaration "%s"'#13#10, [LInitial]))
  else
    for LIndex := 0 to Length(LNames) - 2 do
      if not FActors.AddAlias(LNames[LIndex], LNames[LIndex + 1]) then
        Warn(Format('DoParseActorAlias(): Can not match aliases "%s" and "%s"'#13#10,
          [LNames[LIndex], LNames[LIndex + 1]]));
end;

procedure TActorDefDocumentReader.ReadDehParse(AAll: Boolean);
var
  LFiles: TArray<string>;
  LFile: string;
begin
  LFiles := FScanner.GetTokensEOL;
  for LFile in LFiles do
    if Assigned(FScripts) then
      if AAll then
        FScripts.ParseAllDehFiles(LFile)
      else
        FScripts.ParseDehFile(LFile);
end;

procedure TActorDefDocumentReader.Run;
var
  LContinue: Boolean;
begin
  while FScanner.GetString do
  begin
    // THINKER keyword
    if FScanner.MatchString('THINKER') then
    begin
      ReadThinker;
      if FScanner.Finished then
        Break;
    end;

    if FScanner.MatchString('GLOBAL') then // global script
      ReadGlobal;

    // PascalScript extraction
    if FScanner.MatchString('SCRIPT') then
      ReadInlineScript(TActorDefScriptType.Normal)
    else if FScanner.MatchString('COMPILED') or FScanner.MatchString('PRECOMPILED') then
      ReadCompiledScript
    else if FScanner.MatchString('EXTERNAL') then
      ReadExternalScript(TActorDefScriptType.Normal);

    if FScanner.MatchString('ACTORALIAS') then
      ReadActorAlias
    else if FScanner.MatchString('DEH_PARSE') then
      ReadDehParse(False)
    else if FScanner.MatchString('DEH_PARSE_ALL') then
      ReadDehParse(True)
    else if FScanner.MatchString('WEAPON') then
    begin
      LContinue := FWeaponReader.Read;
      FWeaponReader.Submit;
      if not LContinue then
        Break;
    end
    else if FScanner.MatchString('ACTOR') then
    begin
      LContinue := FActorReader.Read;
      FActorReader.Submit;
      if not LContinue then
        Break;
    end;
  end;

  SubmitPending;
end;

end.
