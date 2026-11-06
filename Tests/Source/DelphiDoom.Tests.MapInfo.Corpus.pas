{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the UMAPINFO library - the corpus of texts            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.MapInfo.Corpus;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, DelphiDoom.MapInfo.Types,
  DelphiDoom.MapInfo.Intf;

type
  TMapInfoGame = (Doom, Heretic, Strife);

  /// <summary>
  ///   Tests\Data\MapInfo\cases.txt: the texts that were given to the old parser to make the
  ///   golden files. A line "@@@ name" starts a case. "@@ lump NAME" and "@@ pak NAME" start
  ///   the text of a lump or of an entry of a PAK file; "@@ run default|normal NAME" reads
  ///   the lumps. A case with no run reads the lumps of UMAPINFO. The dump has the format
  ///   that the harness of the old code wrote
  /// </summary>
  TMapInfoCorpus = class
  private
    FLines: TStringList;
  public
    constructor Create(const ACasesFileName: string);
    destructor Destroy; override;
    /// <summary>Runs every case the way the game of that profile reads it and dumps the result</summary>
    function Dump(AGame: TMapInfoGame): TStringList;
    /// <summary>Lines of a file, whatever its line breaks are (the caller frees the list)</summary>
    class function LoadLines(const AFileName: string): TStringList; static;
    /// <summary>The services of a game profile, with the given fakes</summary>
    class function ServicesOf(AGame: TMapInfoGame; const AEpisodes: IMapEpisodeSink): TMapInfoServices; static;
  end;

implementation

uses
  System.IOUtils, System.Math, DelphiDoom.Logging.Intf, DelphiDoom.MapInfo.Factory,
  DelphiDoom.Tests.MapInfo.Fakes;

{ TMapInfoCorpus }

class function TMapInfoCorpus.LoadLines(const AFileName: string): TStringList;
var
  LBytes: TBytes;
  LIndex: Integer;
  LLine: string;
begin
  Result := TStringList.Create;
  LBytes := TFile.ReadAllBytes(AFileName);
  LLine := '';
  for LIndex := 0 to High(LBytes) do
    if LBytes[LIndex] = 10 then
    begin
      if (LLine <> '') and (LLine[Length(LLine)] = #13) then
        Delete(LLine, Length(LLine), 1);
      Result.Add(LLine);
      LLine := '';
    end
    else
      LLine := LLine + Char(LBytes[LIndex]);
  if LLine <> '' then
    Result.Add(LLine);
end;

constructor TMapInfoCorpus.Create(const ACasesFileName: string);
begin
  inherited Create;
  FLines := LoadLines(ACasesFileName);
end;

destructor TMapInfoCorpus.Destroy;
begin
  FLines.Free;
  inherited Destroy;
end;

class function TMapInfoCorpus.ServicesOf(AGame: TMapInfoGame;
  const AEpisodes: IMapEpisodeSink): TMapInfoServices;
var
  LGame: TFakeGame;
begin
  LGame := TFakeGame.Create;
  // the five interfaces of the fake are held by the record
  Result.Validator := LGame;
  Result.Lumps := LGame;
  Result.Music := LGame;
  Result.Actors := LGame;
  case AGame of
    TMapInfoGame.Doom:
      Result.BossRule := TMapInfoFactory.CreateTaggedBossActionRule(TArray<Integer>.Create(11, 51, 52, 124));
    TMapInfoGame.Heretic:
      Result.BossRule := TMapInfoFactory.CreateTaggedBossActionRule(TArray<Integer>.Create(11, 51, 52, 105));
    TMapInfoGame.Strife:
      Result.BossRule := TMapInfoFactory.CreateOpenBossActionRule;
  end;
  if AGame = TMapInfoGame.Strife then
    Result.Episodes := nil
  else
    Result.Episodes := AEpisodes;
end;

function Quote(const AText: string): string;
var
  LIndex: Integer;
  LChar: Char;
begin
  Result := '';
  for LIndex := 1 to Length(AText) do
  begin
    LChar := AText[LIndex];
    if LChar = '\' then
      Result := Result + '\\'
    else if LChar = #13 then
      Result := Result + '\r'
    else if LChar = #10 then
      Result := Result + '\n'
    else if (Ord(LChar) < 32) or (Ord(LChar) > 126) then
      Result := Result + '\x' + IntToHex(Ord(LChar), 2)
    else
      Result := Result + LChar;
  end;
end;

/// <summary>
///   What the old code kept of a text of the intertexts: a record of 1024 characters that lost the
///   last one and was cut at 1022 (stringtoubigstring). The library keeps the whole text
/// </summary>
function OldInterText(const AText: string): string;
var
  LLength: Integer;
begin
  LLength := Min(Length(AText) - 1, 1022);
  if LLength < 0 then
    LLength := 0;
  Result := Copy(AText, 1, LLength);
end;

procedure DumpEntry(AOutput: TStringList; const APrefix: string; AIndex: Integer;
  const AEntry: TMapInfoEntry);
var
  LIndex: Integer;
  LCount: Integer;
begin
  AOutput.Add(APrefix + '[' + IntToStr(AIndex) + ']');
  AOutput.Add('  mapname=' + Quote(AEntry.MapName));
  AOutput.Add('  levelname=' + Quote(AEntry.LevelName));
  AOutput.Add('  mlabel=' + Quote(AEntry.MapLabel));
  AOutput.Add('  intertext=' + Quote(OldInterText(AEntry.InterText)));
  AOutput.Add('  intertextsecret=' + Quote(OldInterText(AEntry.InterTextSecret)));
  AOutput.Add('  levelpic=' + Quote(AEntry.LevelPic));
  AOutput.Add('  nextmap=' + Quote(AEntry.NextMap));
  AOutput.Add('  nextsecret=' + Quote(AEntry.NextSecret));
  AOutput.Add('  music=' + Quote(AEntry.Music));
  AOutput.Add('  musicnum=' + IntToStr(AEntry.MusicNumber));
  AOutput.Add('  skytexture=' + Quote(AEntry.SkyTexture));
  AOutput.Add('  skytexture2=' + Quote(AEntry.SkyTexture2));
  AOutput.Add('  endpic=' + Quote(AEntry.EndPic));
  AOutput.Add('  exitpic=' + Quote(AEntry.ExitPic));
  AOutput.Add('  enterpic=' + Quote(AEntry.EnterPic));
  AOutput.Add('  interbackdrop=' + Quote(AEntry.InterBackdrop));
  AOutput.Add('  intermusic=' + Quote(AEntry.InterMusic));
  AOutput.Add('  intermusicnum=' + IntToStr(AEntry.InterMusicNumber));
  AOutput.Add('  partime=' + IntToStr(AEntry.ParTime));
  AOutput.Add('  nointermission=' + IntToStr(Ord(AEntry.NoIntermission)));
  AOutput.Add('  lightning=' + IntToStr(Ord(AEntry.Lightning)));
  AOutput.Add('  nojump=' + IntToStr(Ord(AEntry.NoJump)));
  AOutput.Add('  nocrouch=' + IntToStr(Ord(AEntry.NoCrouch)));
  if AEntry.BossActionsCleared then
    LCount := -1
  else
    LCount := Length(AEntry.BossActions);
  AOutput.Add('  numbossactions=' + IntToStr(LCount));
  for LIndex := 0 to Length(AEntry.BossActions) - 1 do
    AOutput.Add('  bossaction ' + IntToStr(LIndex) + '=' + IntToStr(AEntry.BossActions[LIndex].ActorType) +
      ',' + IntToStr(AEntry.BossActions[LIndex].Special) + ',' + IntToStr(AEntry.BossActions[LIndex].Tag));
end;

type
  /// <summary>One case of the corpus: its own fakes, catalog and loader</summary>
  TCaseRun = class
  private
    FSource: TFakeTextSource;
    FSourceIntf: IMapInfoTextSource;
    FEpisodes: TFakeEpisodes;
    FEpisodesIntf: IMapEpisodeSink;
    FLog: TFakeLog;
    FLogIntf: ILog;
    FCatalog: IMapInfoCatalog;
    FLoader: IMapInfoLoader;
    FHasRun: Boolean;
  public
    constructor Create(AGame: TMapInfoGame);
    procedure AddText(const AKind, AName, AText: string);
    procedure Run(AIsDefault: Boolean; const ALumpName: string);
    procedure Finish(AOutput: TStringList; const ACaseName: string);
  end;

{ TCaseRun }

constructor TCaseRun.Create(AGame: TMapInfoGame);
var
  LServices: TMapInfoServices;
begin
  inherited Create;
  FSource := TFakeTextSource.Create;
  FSourceIntf := FSource;
  FEpisodes := TFakeEpisodes.Create;
  FEpisodesIntf := FEpisodes;
  FLog := TFakeLog.Create;
  FLogIntf := FLog;
  LServices := TMapInfoCorpus.ServicesOf(AGame, FEpisodesIntf);
  FCatalog := TMapInfoFactory.CreateCatalog(LServices.Music);
  FLoader := TMapInfoFactory.CreateLoader(FSourceIntf, nil,
    TMapInfoFactory.CreateParser(LServices, FLogIntf), FCatalog);
end;

procedure TCaseRun.AddText(const AKind, AName, AText: string);
begin
  if AKind = 'lump' then
    FSource.AddLump(AName, AText)
  else
    FSource.AddPak(AName, AText);
end;

procedure TCaseRun.Run(AIsDefault: Boolean; const ALumpName: string);
begin
  FHasRun := True;
  FLoader.Load(ALumpName, AIsDefault);
end;

procedure TCaseRun.Finish(AOutput: TStringList; const ACaseName: string);
var
  LIndex: Integer;
begin
  if not FHasRun then
    FLoader.Load('UMAPINFO', False);
  AOutput.Add('=== ' + ACaseName);
  AOutput.Add('warnings=' + Quote(FLog.Warnings));
  AOutput.Add('episodes=' + Quote(FEpisodes.Log));
  AOutput.Add('default.count=' + IntToStr(FCatalog.DefaultCount));
  for LIndex := 0 to FCatalog.DefaultCount - 1 do
    DumpEntry(AOutput, 'default', LIndex, FCatalog.GetDefault(LIndex));
  AOutput.Add('maps.count=' + IntToStr(FCatalog.MapCount));
  for LIndex := 0 to FCatalog.MapCount - 1 do
    DumpEntry(AOutput, 'map', LIndex, FCatalog.GetMap(LIndex));
end;

{ TMapInfoCorpus (dump) }

function TMapInfoCorpus.Dump(AGame: TMapInfoGame): TStringList;
var
  LIndex: Integer;
  LLine: string;
  LParts: TArray<string>;
  LRun: TCaseRun;
  LCaseName: string;
  LBlockKind: string;
  LBlockName: string;
  LBody: string;
  LHasBlock: Boolean;
  LList: TStringList;

  procedure FlushBlock;
  begin
    if LHasBlock then
      LRun.AddText(LBlockKind, LBlockName, LBody);
    LHasBlock := False;
    LBody := '';
  end;

  procedure FinishCase;
  begin
    FlushBlock;
    if Assigned(LRun) then
    begin
      LRun.Finish(LList, LCaseName);
      FreeAndNil(LRun);
    end;
  end;

begin
  LList := TStringList.Create;
  LRun := nil;
  LHasBlock := False;
  LBody := '';
  try
    for LIndex := 0 to FLines.Count - 1 do
    begin
      LLine := FLines[LIndex];
      if Copy(LLine, 1, 4) = '@@@ ' then
      begin
        FinishCase;
        LCaseName := Copy(LLine, 5, MaxInt);
        LRun := TCaseRun.Create(AGame);
      end
      else if Copy(LLine, 1, 3) = '@@ ' then
      begin
        FlushBlock;
        LParts := Copy(LLine, 4, MaxInt).Split([' ']);
        LBlockKind := LParts[0];
        if (LBlockKind = 'lump') or (LBlockKind = 'pak') then
        begin
          LBlockName := LParts[1];
          LHasBlock := True;
        end
        else if LBlockKind = 'run' then
          LRun.Run(LParts[1] = 'default', LParts[2]);
      end
      else if LHasBlock then
        LBody := LBody + LLine + #13#10;
    end;
    FinishCase;
  except
    LRun.Free;
    LList.Free;
    raise;
  end;
  Result := LList;
end;

end.
