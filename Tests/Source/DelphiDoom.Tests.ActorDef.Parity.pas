{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the ActorDef library - parity with the old parser      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.ActorDef.Parity;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, DUnitX.TestFramework,
  DelphiDoom.Logging.Intf, DelphiDoom.Logging.Recorder, DelphiDoom.ActorDef.Types,
  DelphiDoom.ActorDef.Intf;

type
  /// <summary>The songs of the maps that the engine of Hexen would take from SNDINFO (the ones that it has)</summary>
  TMusicListener = class(TInterfacedObject, IActorDefSoundInfoListener)
  private
    FNumMusic: Integer;
  public
    Songs: TStringList;
    constructor Create(ANumMusic: Integer);
    destructor Destroy; override;
    procedure SongForMap(AMapId: Integer; const ASongName: string);
    procedure AliasDeclared(const AName, AValue: string);
  end;

  /// <summary>
  ///   Tests\Data\ActorDef\<game> has the texts of ACTORDEF (*.in.txt) and of SNDINFO (*.snd.txt) that
  ///   the old parser of sc_actordef.pas read, in a harness that compiled the old unit with the
  ///   engine of each game. For each text there are the transcript of the old parser
  ///   (*.golden.txt: the warnings, the patches that it gave to the DEH subsystem, the
  ///   thinkers, the scripts, the aliases of the sounds) and what it asked the tables of the
  ///   engine (*.engine.txt: the actors that it inherited from, the numbers of the weapons ...).
  ///   The library has to write the same transcript with the same questions, in the four games
  /// </summary>
  [TestFixture]
  [Category('actordef')]
  TTestActorDefParity = class(TObject)
  private
    function DataDir(const AGame: string): string;
    function Transcript(const AGame, ACase: string; out AMismatch: string): string;
    function FirstDifference(const AExpected, AActual: string): string;
    function CheckCase(const AGame, ACase: string): string;
    function CheckMutants(const AGame: string): string;
  public
    [Test]
    [TestCase('aliases', 'aliases')]
    [TestCase('bad_numbers', 'bad_numbers')]
    [TestCase('basic', 'basic')]
    [TestCase('deh_parse', 'deh_parse')]
    [TestCase('doomednum', 'doomednum')]
    [TestCase('empty', 'empty')]
    [TestCase('eof_actor', 'eof_actor')]
    [TestCase('eof_actor_num', 'eof_actor_num')]
    [TestCase('eof_global', 'eof_global')]
    [TestCase('eof_inherit', 'eof_inherit')]
    [TestCase('eof_props', 'eof_props')]
    [TestCase('eof_script', 'eof_script')]
    [TestCase('eof_script2', 'eof_script2')]
    [TestCase('eof_states', 'eof_states')]
    [TestCase('eof_states2', 'eof_states2')]
    [TestCase('eof_states3', 'eof_states3')]
    [TestCase('eof_thinker', 'eof_thinker')]
    [TestCase('eof_thinker2', 'eof_thinker2')]
    [TestCase('eof_thinker3', 'eof_thinker3')]
    [TestCase('eof_weapon', 'eof_weapon')]
    [TestCase('flags', 'flags')]
    [TestCase('flags_case', 'flags_case')]
    [TestCase('flags_inherit', 'flags_inherit')]
    [TestCase('frames_case', 'frames_case')]
    [TestCase('inherit', 'inherit')]
    [TestCase('keywords', 'keywords')]
    [TestCase('missile_speed', 'missile_speed')]
    [TestCase('multi', 'multi')]
    [TestCase('no_states', 'no_states')]
    [TestCase('props_all', 'props_all')]
    [TestCase('props_normalize', 'props_normalize')]
    [TestCase('replaces', 'replaces')]
    [TestCase('scripts', 'scripts')]
    [TestCase('sndinfo_aliases', 'sndinfo_aliases')]
    [TestCase('sndinfo_only', 'sndinfo_only')]
    [TestCase('sounds', 'sounds')]
    [TestCase('states_alias', 'states_alias')]
    [TestCase('states_extra', 'states_extra')]
    [TestCase('states_goto', 'states_goto')]
    [TestCase('states_goto2', 'states_goto2')]
    [TestCase('states_labels', 'states_labels')]
    [TestCase('states_loop_wait', 'states_loop_wait')]
    [TestCase('states_syntax', 'states_syntax')]
    [TestCase('thinker', 'thinker')]
    [TestCase('thinker_dup', 'thinker_dup')]
    [TestCase('too_many_states', 'too_many_states')]
    [TestCase('unknown_tokens', 'unknown_tokens')]
    [TestCase('weapon', 'weapon')]
    [TestCase('weapon_extra', 'weapon_extra')]
    [TestCase('weapon_flags', 'weapon_flags')]
    [TestCase('weapon_goto', 'weapon_goto')]
    [TestCase('weapon_names', 'weapon_names')]
    [TestCase('strife_name', 'strife_name')]
    [TestCase('flags2_games', 'flags2_games')]
    [TestCase('scripts2', 'scripts2')]
    [TestCase('numbers_edge', 'numbers_edge')]
    [TestCase('redefine', 'redefine')]
    [TestCase('formatting', 'formatting')]
    [TestCase('quotes', 'quotes')]
    [TestCase('weapon_nonsense', 'weapon_nonsense')]
    [TestCase('weapon_noflags', 'weapon_noflags')]
    procedure TestSameResultAsTheOldParser(const ACase: string);
    [Test]
    procedure TestMutantsOfDoom;
    [Test]
    procedure TestMutantsOfHeretic;
    [Test]
    procedure TestMutantsOfHexen;
    [Test]
    procedure TestMutantsOfStrife;
  end;

implementation

uses
  DelphiDoom.Logging.Types, DelphiDoom.Logging.Factory, DelphiDoom.ActorDef.Profiles,
  DelphiDoom.ActorDef.Factory, DelphiDoom.Tests.ActorDef.Replay;

const
  GAMES: array[0..3] of string = ('Doom', 'Heretic', 'Hexen', 'Strife');

{ TMusicListener }

constructor TMusicListener.Create(ANumMusic: Integer);
begin
  inherited Create;
  FNumMusic := ANumMusic;
  Songs := TStringList.Create;
  Songs.Sorted := True;
  Songs.Duplicates := dupIgnore;
end;

destructor TMusicListener.Destroy;
begin
  Songs.Free;
  inherited Destroy;
end;

procedure TMusicListener.SongForMap(AMapId: Integer; const ASongName: string);
var
  LIndex: Integer;
begin
  // as the engine does: the map has to have a song, and the last name wins
  if (AMapId <= 0) or (AMapId >= FNumMusic) then
    Exit;
  LIndex := Songs.IndexOfName(Format('%.6d', [AMapId]));
  if LIndex >= 0 then
    Songs.Delete(LIndex);
  Songs.Add(Format('%.6d', [AMapId]) + '=' + ASongName);
end;

procedure TMusicListener.AliasDeclared(const AName, AValue: string);
begin
end;

{ TTestActorDefParity }

function TTestActorDefParity.DataDir(const AGame: string): string;
begin
  Result := TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)),
    '..\..\Tests\Data\ActorDef\' + AGame));
end;

function TTestActorDefParity.Transcript(const AGame, ACase: string; out AMismatch: string): string;
var
  LDir: string;
  LGame: TActorDefGame;
  LProfile: TActorDefProfile;
  LRecorder: TLogRecorder;
  LRecorderSink: ILogSink;
  LLog: ILog;
  LEngine: TReplayEngine;
  LFlags: IActorDefFlagCatalog;
  LNames: IActorDefNameCatalog;
  LActors: IActorDefActorCatalog;
  LStates: IActorDefStateCatalog;
  LEvents: TEventRecorder;
  LThinkers: IActorDefThinkerSink;
  LScripts: IActorDefScriptSink;
  LConsumer: IActorDefDehConsumer;
  LAliases: IActorDefSoundAliasTable;
  LSink: IActorDefDefinitionSink;
  LParser: IActorDefParser;
  LLine: string;
  LMusic: TMusicListener;
  LMusicRef: IActorDefSoundInfoListener;
  LIndex: Integer;
begin
  AMismatch := '';
  LDir := DataDir(AGame);
  TActorDefProfiles.TryFromName(AGame, LGame);
  LProfile := TActorDefProfiles.ForGame(LGame);
  LRecorder := TLogRecorder.Create;
  LRecorderSink := LRecorder;
  LLog := TLogFactory.CreateLog(TArray<ILogSink>.Create(LRecorderSink), nil);
  LEngine := TReplayEngine.Create(TPath.Combine(LDir, 'vocab.txt'),
    TPath.Combine(LDir, ACase + '.engine.txt'));
  LFlags := LEngine;
  LNames := LEngine;
  LActors := LEngine;
  LStates := LEngine;
  LEvents := TEventRecorder.Create(LLog);
  LThinkers := LEvents;
  LScripts := LEvents;
  LConsumer := LEvents;
  LAliases := TActorDefFactory.CreateSoundAliases(LLog);
  LMusic := TMusicListener.Create(LEngine.NumMusic);
  LMusicRef := LMusic;

  try
    if TFile.Exists(TPath.Combine(LDir, ACase + '.snd.txt')) then
    begin
      TActorDefFactory.ParseSoundInfo(LProfile,
        TReplayText.ToLump(TReplayText.ReadAnsi(TPath.Combine(LDir, ACase + '.snd.txt'))),
        LAliases, LMusicRef);
      LLog.Info('@ ALIASES ' + IntToStr(Length(LAliases.Lines)) + #13#10);
      for LLine in LAliases.Lines do
        LLog.Info('@ ALIASENTRY ' + TReplayText.Encode(LLine) + #13#10);
      for LIndex := 0 to LMusic.Songs.Count - 1 do
        LLog.Info('@ MUSIC ' + IntToStr(StrToInt(LMusic.Songs.Names[LIndex])) + '|' +
          TReplayText.Encode(LMusic.Songs.ValueFromIndex[LIndex]) + #13#10);
    end;
    LSink := TActorDefFactory.CreateDehSink(LProfile, LActors, LStates, LAliases, LConsumer, LLog);
    LParser := TActorDefFactory.CreateParser(LProfile, LLog, LFlags, LNames, LActors, LSink,
      LThinkers, LScripts, nil);
    LParser.Parse(TReplayText.ToLump(TReplayText.ReadAnsi(TPath.Combine(LDir, ACase + '.in.txt'))));
    AMismatch := LEngine.Remaining;
  except
    on E: EReplayMismatch do
      AMismatch := E.Message;
  end;
  Result := TReplayText.ToLf(LRecorder.TextOf(TLogChannel.Output));
end;

function TTestActorDefParity.FirstDifference(const AExpected, AActual: string): string;
var
  LExpected: TArray<string>;
  LActual: TArray<string>;
  LIndex: Integer;
begin
  LExpected := AExpected.Split([#10]);
  LActual := AActual.Split([#10]);
  for LIndex := 0 to Length(LExpected) - 1 do
  begin
    if LIndex >= Length(LActual) then
      Exit('line ' + IntToStr(LIndex + 1) + ': expected "' + LExpected[LIndex] + '", the text ends');
    if LExpected[LIndex] <> LActual[LIndex] then
      Exit('line ' + IntToStr(LIndex + 1) + ': expected "' + LExpected[LIndex] + '", got "' +
        LActual[LIndex] + '"');
  end;
  if Length(LActual) > Length(LExpected) then
    Exit('extra line ' + IntToStr(Length(LExpected) + 1) + ': "' + LActual[Length(LExpected)] + '"');
  Result := '';
end;

function TTestActorDefParity.CheckCase(const AGame, ACase: string): string;
var
  LGolden: string;
  LActual: string;
  LMismatch: string;
  LDifference: string;
begin
  Result := '';
  if not TFile.Exists(TPath.Combine(DataDir(AGame), ACase + '.in.txt')) then
    Exit;
  LGolden := TReplayText.ReadAnsi(TPath.Combine(DataDir(AGame), ACase + '.golden.txt'));
  LActual := Transcript(AGame, ACase, LMismatch);
  LDifference := FirstDifference(LGolden, LActual);
  if LMismatch <> '' then
    Result := AGame + ': ' + LMismatch + '. ';
  if LDifference <> '' then
    Result := Result + AGame + ': ' + LDifference + '. ';
end;

procedure TTestActorDefParity.TestSameResultAsTheOldParser(const ACase: string);
var
  LGame: string;
  LProblems: string;
begin
  LProblems := '';
  for LGame in GAMES do
    LProblems := LProblems + CheckCase(LGame, ACase);
  Assert.AreEqual('', LProblems, ACase);
end;

function TTestActorDefParity.CheckMutants(const AGame: string): string;
var
  LFile: string;
  LCase: string;
  LCount: Integer;
begin
  Result := '';
  LCount := 0;
  for LFile in TDirectory.GetFiles(DataDir(AGame), 'fuzz_*.in.txt') do
  begin
    LCase := TPath.GetFileName(LFile);
    LCase := Copy(LCase, 1, Length(LCase) - Length('.in.txt'));
    Result := Result + CheckCase(AGame, LCase).Replace('. ', ' [' + LCase + ']. ');
    Inc(LCount);
  end;
  Assert.IsTrue(LCount > 0, 'there are no mutants of ' + AGame);
end;

procedure TTestActorDefParity.TestMutantsOfDoom;
begin
  Assert.AreEqual('', CheckMutants('Doom'));
end;

procedure TTestActorDefParity.TestMutantsOfHeretic;
begin
  Assert.AreEqual('', CheckMutants('Heretic'));
end;

procedure TTestActorDefParity.TestMutantsOfHexen;
begin
  Assert.AreEqual('', CheckMutants('Hexen'));
end;

procedure TTestActorDefParity.TestMutantsOfStrife;
begin
  Assert.AreEqual('', CheckMutants('Strife'));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestActorDefParity);

end.
