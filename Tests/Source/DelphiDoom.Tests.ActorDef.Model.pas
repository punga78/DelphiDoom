{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the ActorDef library - the model of the definitions    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.ActorDef.Model;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, DUnitX.TestFramework,
  DelphiDoom.Logging.Intf, DelphiDoom.Logging.Recorder, DelphiDoom.ActorDef.Types,
  DelphiDoom.ActorDef.Intf;

type
  /// <summary>
  ///   The engine of the tests: a few actors, short lists of flags, and what the sinks
  ///   receive kept in lists. It does not replay anything: it answers from memory
  /// </summary>
  TFakeEngine = class(TInterfacedObject, IActorDefFlagCatalog, IActorDefNameCatalog,
    IActorDefActorCatalog, IActorDefDefinitionSink, IActorDefThinkerSink, IActorDefScriptSink,
    IActorDefTextPreprocessor)
  private
    FActorList: TList<TActorDefActor>;
  public
    Weapons: TList<TActorDefWeapon>;
    Thinkers: TList<TActorDefThinker>;
    Scripts: TStringList;
    Aliases: TStringList;
    Preprocessed: Integer;
    OnThinker: TProc<TActorDefThinker>;
    constructor Create;
    destructor Destroy; override;
    function Actors: TList<TActorDefActor>;
    function Flags(ACategory: TActorDefFlagCategory): TArray<string>;
    function WeaponType(const AName: string): Integer;
    function AmmoType(const AName: string): Integer;
    function PlayerClass(const AName: string): Integer;
    function RenderStyleToken(const AName: string): string;
    function GenderName(const AName: string): string;
    function Find(const AName: string; out AIndex: Integer; out AActor: TActorDefActor): Boolean;
    function NameOf(AIndex: Integer): string;
    function AddAlias(const AName, AOtherName: string): Boolean;
    procedure SubmitActor(const AActor: TActorDefActor);
    procedure SubmitWeapon(const AWeapon: TActorDefWeapon);
    procedure SubmitThinker(const AThinker: TActorDefThinker);
    procedure AddSourceScript(const AName, ASource: string; AType: TActorDefScriptType);
    procedure AddExternalScript(const AName, AFileName: string; AType: TActorDefScriptType);
    procedure AddCompiledScript(const AName, AFileName: string);
    procedure ParseDehFile(const AFileName: string);
    procedure ParseAllDehFiles(const AFileName: string);
    function Process(const AText: string): string;
  end;

  [TestFixture]
  [Category('actordef')]
  TTestActorDefModel = class(TObject)
  private
    FEngine: TFakeEngine;
    FEngineRef: IActorDefActorCatalog;
    FRecorder: TLogRecorder;
    FRecorderSink: ILogSink;
    FLog: ILog;
    FParser: IActorDefParser;
    procedure CreateParser(AGame: TActorDefGame; const APreprocessor: IActorDefTextPreprocessor = nil);
    procedure Parse(const AText: string);
    function Warnings: string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestAnActorHasItsNameItsNumberAndItsProperties;
    [Test]
    procedure TestFlagsAreAddedAndTakenOffAsWordsOfTheList;
    [Test]
    procedure TestTheLabelsMakeTheStatesAndLoopAndStopSayWhereTheyGo;
    [Test]
    procedure TestAnActorInheritsTheValuesOfTheCatalogAndReplacesItsNumber;
    [Test]
    procedure TestAGotoToALabelOfTheActorIsAlreadyAState;
    [Test]
    procedure TestAGotoToAnUnknownLabelStaysAsText;
    [Test]
    procedure TestAWeaponHasItsAmmoItsFlagsAndItsStates;
    [Test]
    procedure TestTheLastStateThatDoesNotEndGoesToItself;
    [Test]
    procedure TestAThinkerGoesToTheThinkerSink;
    [Test]
    procedure TestTheScriptsAndThePatchesGoToTheScriptSink;
    [Test]
    procedure TestAThinkerCanBeParsedWhileAnotherTextIsBeingParsed;
    [Test]
    procedure TestThePreprocessorPreparesTheTextOnce;
    [Test]
    procedure TestWithoutALogTheWarningsAreDropped;
    [Test]
    procedure TestTheStatesOfAWeaponDoNotKeepTheGotoOfTheActorBefore;
    [Test]
    procedure TestMoreThan1024StatesAreCutWithAWarning;
    [Test]
    procedure TestHexenKeywordsSetTheBitsOfTheFlags2;
    [Test]
    procedure TestHereticWeaponsHaveALevel;
    [Test]
    procedure TestOnlyStrifeHasASecondName;
    [Test]
    procedure TestTheNameOfAThinkerIsCutAt255Characters;
  end;

implementation

uses
  DelphiDoom.Logging.Types, DelphiDoom.Logging.Factory, DelphiDoom.ActorDef.Profiles,
  DelphiDoom.ActorDef.Factory;

{ TFakeEngine }

constructor TFakeEngine.Create;
var
  LBase: TActorDefActor;
begin
  inherited Create;
  FActorList := TList<TActorDefActor>.Create;
  Weapons := TList<TActorDefWeapon>.Create;
  Thinkers := TList<TActorDefThinker>.Create;
  Scripts := TStringList.Create;
  Aliases := TStringList.Create;
  // the first actor of the engine: an imp
  LBase := Default(TActorDefActor);
  LBase.Name := 'Imp';
  LBase.DoomedNum := 3001;
  LBase.SpawnHealth := 60;
  LBase.Speed := 8;
  LBase.Radius := 20;
  LBase.Height := 56;
  LBase.Flags := 'MF_SOLID MF_SHOOTABLE ';
  LBase.SpawnState := ACTORDEF_ORIGINAL_STATE_MARKER + 442;
  LBase.SeeState := ACTORDEF_ORIGINAL_STATE_MARKER + 444;
  LBase.PainState := ACTORDEF_ORIGINAL_STATE_MARKER;
  LBase.MeleeState := ACTORDEF_ORIGINAL_STATE_MARKER;
  LBase.MissileState := ACTORDEF_ORIGINAL_STATE_MARKER;
  LBase.DeathState := ACTORDEF_ORIGINAL_STATE_MARKER;
  LBase.XDeathState := ACTORDEF_ORIGINAL_STATE_MARKER;
  LBase.RaiseState := ACTORDEF_ORIGINAL_STATE_MARKER;
  LBase.HealState := ACTORDEF_ORIGINAL_STATE_MARKER;
  LBase.CrashState := ACTORDEF_ORIGINAL_STATE_MARKER;
  LBase.CrushState := ACTORDEF_ORIGINAL_STATE_MARKER;
  LBase.InteractState := ACTORDEF_ORIGINAL_STATE_MARKER;
  LBase.PushFactor := 0.25;
  LBase.Scale := 1.0;
  LBase.Gravity := 1.0;
  FActorList.Add(LBase);
end;

destructor TFakeEngine.Destroy;
begin
  Aliases.Free;
  Scripts.Free;
  Thinkers.Free;
  Weapons.Free;
  FActorList.Free;
  inherited Destroy;
end;

function TFakeEngine.Actors: TList<TActorDefActor>;
begin
  Result := FActorList;
end;

function TFakeEngine.Flags(ACategory: TActorDefFlagCategory): TArray<string>;
begin
  case ACategory of
    TActorDefFlagCategory.Flags:
      Result := TArray<string>.Create('MF_SPECIAL', 'MF_SOLID', 'MF_SHOOTABLE', 'MF_NOGRAVITY', 'MF_MISSILE');
    TActorDefFlagCategory.Flags2:
      Result := TArray<string>.Create('MF2_LOGRAV', 'MF2_FLY');
    TActorDefFlagCategory.FlagsEx:
      Result := TArray<string>.Create('MF_EX_TRANSPARENT', 'MF_EX_FLOATBOB');
    TActorDefFlagCategory.Flags2Ex:
      Result := TArray<string>.Create('MF2_EX_PUSHABLE');
    TActorDefFlagCategory.Weapon:
      Result := TArray<string>.Create('NOTHRUST', 'SILENT');
  else
    Result := nil;
  end;
end;

function TFakeEngine.WeaponType(const AName: string): Integer;
begin
  if SameText(AName, 'WP_PISTOL') then
    Result := 1
  else
    Result := -1;
end;

function TFakeEngine.AmmoType(const AName: string): Integer;
begin
  if SameText(AName, 'AM_CLIP') then
    Result := 0
  else
    Result := -1;
end;

function TFakeEngine.PlayerClass(const AName: string): Integer;
begin
  Result := -1;
end;

function TFakeEngine.RenderStyleToken(const AName: string): string;
begin
  Result := UpperCase(AName);
end;

function TFakeEngine.GenderName(const AName: string): string;
begin
  Result := UpperCase(AName);
end;

function TFakeEngine.Find(const AName: string; out AIndex: Integer; out AActor: TActorDefActor): Boolean;
var
  LIndex: Integer;
begin
  for LIndex := FActorList.Count - 1 downto 0 do
    if SameText(FActorList[LIndex].Name, AName) then
    begin
      AIndex := LIndex;
      AActor := FActorList[LIndex];
      Exit(True);
    end;
  AIndex := -1;
  Result := False;
end;

function TFakeEngine.NameOf(AIndex: Integer): string;
begin
  Result := FActorList[AIndex].Name;
end;

function TFakeEngine.AddAlias(const AName, AOtherName: string): Boolean;
begin
  Aliases.Add(AName + '=' + AOtherName);
  Result := True;
end;

procedure TFakeEngine.SubmitActor(const AActor: TActorDefActor);
begin
  FActorList.Add(AActor);
end;

procedure TFakeEngine.SubmitWeapon(const AWeapon: TActorDefWeapon);
begin
  Weapons.Add(AWeapon);
end;

procedure TFakeEngine.SubmitThinker(const AThinker: TActorDefThinker);
begin
  Thinkers.Add(AThinker);
  if Assigned(OnThinker) then
    OnThinker(AThinker);
end;

procedure TFakeEngine.AddSourceScript(const AName, ASource: string; AType: TActorDefScriptType);
begin
  Scripts.Add('source ' + AName + ' ' + IntToStr(Ord(AType)) + ' ' + ASource.Replace(#13#10, '/'));
end;

procedure TFakeEngine.AddExternalScript(const AName, AFileName: string; AType: TActorDefScriptType);
begin
  Scripts.Add('external ' + AName + ' ' + AFileName + ' ' + IntToStr(Ord(AType)));
end;

procedure TFakeEngine.AddCompiledScript(const AName, AFileName: string);
begin
  Scripts.Add('compiled ' + AName + ' ' + AFileName);
end;

procedure TFakeEngine.ParseDehFile(const AFileName: string);
begin
  Scripts.Add('deh ' + AFileName);
end;

procedure TFakeEngine.ParseAllDehFiles(const AFileName: string);
begin
  Scripts.Add('dehall ' + AFileName);
end;

function TFakeEngine.Process(const AText: string): string;
begin
  Inc(Preprocessed);
  Result := AText.Replace('@@', '');
end;

{ TTestActorDefModel }

procedure TTestActorDefModel.Setup;
begin
  FEngine := TFakeEngine.Create;
  FEngineRef := FEngine;
  FRecorder := TLogRecorder.Create;
  FRecorderSink := FRecorder;
  FLog := TLogFactory.CreateLog(TArray<ILogSink>.Create(FRecorderSink), nil);
  CreateParser(TActorDefGame.Doom);
end;

procedure TTestActorDefModel.TearDown;
begin
  FParser := nil;
  FLog := nil;
  FRecorderSink := nil;
  FEngine.OnThinker := nil;
  FEngineRef := nil;
end;

procedure TTestActorDefModel.CreateParser(AGame: TActorDefGame; const APreprocessor: IActorDefTextPreprocessor);
begin
  FParser := TActorDefFactory.CreateParser(TActorDefProfiles.ForGame(AGame), FLog, FEngine, FEngine,
    FEngine, FEngine, FEngine, FEngine, APreprocessor);
end;

procedure TTestActorDefModel.Parse(const AText: string);
begin
  FParser.Parse(AText.Replace(#10, #13#10));
end;

function TTestActorDefModel.Warnings: string;
begin
  Result := FRecorder.TextOf(TLogChannel.Output);
end;

procedure TTestActorDefModel.TestAnActorHasItsNameItsNumberAndItsProperties;
var
  LActor: TActorDefActor;
begin
  Parse('ACTOR Thing 2001'#10'{'#10'  Health 150'#10'  Radius 20'#10'  Height 56'#10'  Speed 12'#10 +
    '  Scale 2'#10'  SeeSound "see/sound"'#10'  Obituary "text"'#10'  Alpha 0.5'#10'}'#10);
  Assert.AreEqual(2, FEngine.Actors.Count);
  LActor := FEngine.Actors[1];
  Assert.AreEqual('Thing', LActor.Name);
  Assert.AreEqual(2001, LActor.DoomedNum);
  Assert.AreEqual(150, LActor.SpawnHealth);
  Assert.AreEqual(20, LActor.Radius);
  Assert.AreEqual(56, LActor.Height);
  Assert.AreEqual(12, LActor.Speed);
  Assert.IsTrue(LActor.Scale = 2.0);
  Assert.AreEqual('see/sound', LActor.SeeSound);
  Assert.AreEqual('text', LActor.Obituary);
  Assert.AreEqual(32768, LActor.Alpha);
  Assert.AreEqual(-1, LActor.ReplacesId);
  Assert.AreEqual(-1, LActor.SpawnState);
end;

procedure TTestActorDefModel.TestFlagsAreAddedAndTakenOffAsWordsOfTheList;
var
  LActor: TActorDefActor;
begin
  Parse('ACTOR Flaggy 2002'#10'{'#10'  +SOLID'#10'  +MF_SHOOTABLE'#10'  NOGRAVITY'#10'  -MF_SOLID'#10 +
    '  +FLOATBOB'#10'  +PUSHABLE'#10'}'#10);
  LActor := FEngine.Actors[1];
  // the old rule: -MF_SOLID does not take off a SOLID that was added without prefix
  Assert.AreEqual('SOLID SHOOTABLE NOGRAVITY ', LActor.Flags);
  Assert.AreEqual('FLOATBOB ', LActor.FlagsEx);
  Assert.AreEqual('PUSHABLE ', LActor.Flags2Ex);
  Assert.AreEqual('0', LActor.Flags3Ex, 'an empty list is 0');
end;

procedure TTestActorDefModel.TestTheLabelsMakeTheStatesAndLoopAndStopSayWhereTheyGo;
var
  LActor: TActorDefActor;
begin
  Parse('ACTOR States1 2003'#10'{'#10'  States'#10'  {'#10'  Spawn:'#10'    TROO AB 10 A_Look'#10 +
    '    Loop'#10'  Death:'#10'    TROO C 5 BRIGHT'#10'    TROO D 5 A_Scream'#10'    Stop'#10'  }'#10'}'#10);
  LActor := FEngine.Actors[1];
  Assert.AreEqual(4, Length(LActor.States));
  Assert.AreEqual(0, LActor.SpawnState);
  Assert.AreEqual(2, LActor.DeathState);
  Assert.AreEqual(Cardinal(ACTORDEF_ST_SPAWN or ACTORDEF_ST_DEATH), LActor.StatesDefined);
  Assert.AreEqual('TROO', LActor.States[0].Sprite);
  Assert.AreEqual(1, LActor.States[1].Frame);
  Assert.AreEqual(10, LActor.States[0].Tics);
  Assert.AreEqual('A_Look', LActor.States[1].Action);
  Assert.AreEqual(1, LActor.States[0].NextState);
  Assert.AreEqual(0, LActor.States[1].NextState, 'Loop goes back to the first state of the label');
  Assert.IsTrue(LActor.States[2].Bright);
  Assert.AreEqual('A_Null', LActor.States[2].Action);
  Assert.AreEqual(-1, LActor.States[3].NextState, 'Stop');
end;

procedure TTestActorDefModel.TestAnActorInheritsTheValuesOfTheCatalogAndReplacesItsNumber;
var
  LChild: TActorDefActor;
  LReplacing: TActorDefActor;
begin
  Parse('ACTOR Child : Imp 2004'#10'{'#10'  Health 5'#10'}'#10'ACTOR Better replaces Imp'#10'{'#10 +
    '  Speed 20'#10'}'#10);
  LChild := FEngine.Actors[1];
  Assert.AreEqual('Imp', LChild.InheritsFrom);
  Assert.AreEqual(2004, LChild.DoomedNum);
  Assert.AreEqual(5, LChild.SpawnHealth, 'the actor says it');
  Assert.AreEqual(8, LChild.Speed, 'it comes from the imp');
  Assert.AreEqual('MF_SOLID MF_SHOOTABLE ', LChild.Flags);
  Assert.AreEqual(ACTORDEF_ORIGINAL_STATE_MARKER + 442, LChild.SpawnState);
  Assert.AreEqual(Cardinal(ACTORDEF_ST_SPAWN or ACTORDEF_ST_SEE), LChild.StatesDefined,
    'the null state is not a label');
  LReplacing := FEngine.Actors[2];
  Assert.AreEqual(3001, LReplacing.DoomedNum);
  Assert.AreEqual(0, LReplacing.ReplacesId);
  Assert.AreEqual(20, LReplacing.Speed);
end;

procedure TTestActorDefModel.TestAGotoToALabelOfTheActorIsAlreadyAState;
var
  LActor: TActorDefActor;
begin
  Parse('ACTOR Goto1 2005'#10'{'#10'  States'#10'  {'#10'  Spawn:'#10'    TROO A 5'#10'    TROO B 5'#10 +
    '  See:'#10'    TROO C 5'#10'    Goto Spawn+1'#10'  Death:'#10'    TROO D 5'#10'    Goto See'#10'  }'#10'}'#10);
  LActor := FEngine.Actors[1];
  Assert.IsTrue(LActor.States[2].HasGoto);
  Assert.AreEqual(1, LActor.States[2].NextState);
  Assert.IsTrue(LActor.States[3].HasGoto);
  Assert.AreEqual(2, LActor.States[3].NextState);
  Assert.IsFalse(LActor.States[3].GotoNeedsCalc);
end;

procedure TTestActorDefModel.TestAGotoToAnUnknownLabelStaysAsText;
var
  LActor: TActorDefActor;
begin
  Parse('ACTOR Goto2 2006'#10'{'#10'  States'#10'  {'#10'  Spawn:'#10'    TROO A 5'#10 +
    '    Goto Other::Death + 2'#10'  }'#10'}'#10);
  LActor := FEngine.Actors[1];
  Assert.IsTrue(LActor.States[0].GotoNeedsCalc);
  Assert.AreEqual('OTHER::DEATH + 2', LActor.States[0].GotoText);
  Assert.IsFalse(LActor.States[0].HasGoto);
end;

procedure TTestActorDefModel.TestAWeaponHasItsAmmoItsFlagsAndItsStates;
var
  LWeapon: TActorDefWeapon;
begin
  Parse('WEAPON WP_PISTOL'#10'{'#10'  Ammo AM_CLIP'#10'  AmmoPerShot 3'#10'  +MF_SOLID'#10'  States'#10'  {'#10 +
    '  Ready:'#10'    PISG A 1 A_WeaponReady'#10'    Loop'#10'  Attack:'#10'    PISG B 4'#10 +
    '    Goto Ready'#10'  }'#10'}'#10);
  Assert.AreEqual(1, FEngine.Weapons.Count);
  LWeapon := FEngine.Weapons[0];
  Assert.AreEqual(1, LWeapon.WeaponNo);
  Assert.AreEqual(0, LWeapon.Ammo);
  Assert.AreEqual(3, LWeapon.AmmoPerShot);
  Assert.AreEqual('MF_SOLID ', LWeapon.Flags, 'the old code looks in the flags of the actors');
  Assert.AreEqual(0, LWeapon.ReadyState);
  Assert.AreEqual(1, LWeapon.AttackState);
  Assert.AreEqual(-1, LWeapon.UpState);
  Assert.AreEqual(Cardinal(ACTORDEF_WT_READY or ACTORDEF_WT_ATTACK), LWeapon.StatesDefined);
  Assert.AreEqual(0, LWeapon.States[1].NextState);
  Assert.IsTrue(LWeapon.States[1].HasGoto);
end;

procedure TTestActorDefModel.TestTheLastStateThatDoesNotEndGoesToItself;
var
  LActor: TActorDefActor;
begin
  Parse('ACTOR NoEnd 2007'#10'{'#10'  States'#10'  {'#10'  Spawn:'#10'    TROO A 5'#10'    TROO B 5'#10'  }'#10'}'#10);
  LActor := FEngine.Actors[1];
  Assert.AreEqual(1, LActor.States[1].NextState);
end;

procedure TTestActorDefModel.TestAThinkerGoesToTheThinkerSink;
begin
  Parse('THINKER Ticker 3 SCRIPT MyScript REPEAT 4 TIMES INTERVAL 7'#10);
  Assert.AreEqual(1, FEngine.Thinkers.Count);
  Assert.AreEqual('Ticker', FEngine.Thinkers[0].Name);
  Assert.AreEqual('MyScript', FEngine.Thinkers[0].Script);
  Assert.AreEqual(3, FEngine.Thinkers[0].Dn);
  Assert.AreEqual(4, FEngine.Thinkers[0].RepeatCount);
  Assert.AreEqual(7, FEngine.Thinkers[0].Interval);
end;

procedure TTestActorDefModel.TestTheScriptsAndThePatchesGoToTheScriptSink;
begin
  Parse('SCRIPT Hello'#10'x := 1;'#10'ENDSCRIPT'#10'GLOBAL SCRIPT Big'#10'y := 2;'#10'ENDSCRIPT'#10 +
    'EXTERNAL SCRIPT Ext ext.pas'#10'COMPILED SCRIPT Comp comp.bin'#10'DEH_PARSE a.deh b.deh'#10 +
    'DEH_PARSE_ALL *.bex'#10);
  Assert.AreEqual(7, FEngine.Scripts.Count);
  Assert.AreEqual('source Hello 0 x := 1;', FEngine.Scripts[0]);
  Assert.AreEqual('source Big 1 y := 2;', FEngine.Scripts[1]);
  Assert.AreEqual('external Ext ext.pas 0', FEngine.Scripts[2]);
  Assert.AreEqual('compiled Comp comp.bin', FEngine.Scripts[3]);
  Assert.AreEqual('deh a.deh', FEngine.Scripts[4]);
  Assert.AreEqual('deh b.deh', FEngine.Scripts[5]);
  Assert.AreEqual('dehall *.bex', FEngine.Scripts[6]);
end;

procedure TTestActorDefModel.TestAThinkerCanBeParsedWhileAnotherTextIsBeingParsed;
begin
  // the engine writes a thinker as an actor and parses it at once
  FEngine.OnThinker :=
    procedure(AThinker: TActorDefThinker)
    begin
      FParser.Parse('ACTOR ' + AThinker.Name + ' ' + IntToStr(AThinker.Dn) + #13#10'{'#13#10'}'#13#10);
    end;
  Parse('THINKER T1 11 SCRIPT S1'#10'ACTORALIAS a b'#10'ACTOR Last 12'#10'{'#10'}'#10);
  Assert.AreEqual(3, FEngine.Actors.Count);
  Assert.AreEqual('T1', FEngine.Actors[1].Name);
  Assert.AreEqual(11, FEngine.Actors[1].DoomedNum);
  Assert.AreEqual('Last', FEngine.Actors[2].Name);
end;

procedure TTestActorDefModel.TestThePreprocessorPreparesTheTextOnce;
begin
  CreateParser(TActorDefGame.Doom, FEngine);
  Parse('ACTOR Pre@@pared 2008'#10'{'#10'}'#10);
  Assert.AreEqual(1, FEngine.Preprocessed);
  Assert.AreEqual('Prepared', FEngine.Actors[1].Name);
end;

procedure TTestActorDefModel.TestWithoutALogTheWarningsAreDropped;
begin
  FParser := TActorDefFactory.CreateParser(TActorDefProfiles.ForGame(TActorDefGame.Doom), nil, FEngine,
    FEngine, FEngine, FEngine, FEngine, FEngine, nil);
  Parse('ACTOR NoLog 2009'#10'{'#10'  Bogus 4'#10'  States'#10'  {'#10'  Spawn:'#10'    TROO A 1'#10 +
    '    Goto Nowhere'#10'  }'#10'}'#10'THINKER Orphan'#10);
  Assert.AreEqual(2, FEngine.Actors.Count);
  Assert.AreEqual('', Warnings);
end;

procedure TTestActorDefModel.TestTheStatesOfAWeaponDoNotKeepTheGotoOfTheActorBefore;
begin
  // the old parser did not clear its states for a weapon: a state that was never written by
  // the weapon kept the unresolved goto of the actor that came before
  Parse('ACTOR Stale 2010'#10'{'#10'  States'#10'  {'#10'  Spawn:'#10'    TROO A 1'#10'    Goto Elsewhere'#10 +
    '  }'#10'}'#10'WEAPON 7'#10'{'#10'  States'#10'  {'#10'  Ready:'#10'    PISG A 1'#10'    Stop'#10'  }'#10'}'#10);
  Assert.AreEqual(1, FEngine.Weapons.Count);
  Assert.IsFalse(FEngine.Weapons[0].States[0].GotoNeedsCalc);
  Assert.AreEqual(-1, FEngine.Weapons[0].States[0].NextState);
end;

procedure TTestActorDefModel.TestMoreThan1024StatesAreCutWithAWarning;
var
  LText: string;
  LIndex: Integer;
begin
  LText := 'ACTOR Many 2011'#10'{'#10'  States'#10'  {'#10'  Spawn:'#10;
  for LIndex := 1 to 43 do
    LText := LText + '    TROO ABCDEFGHIJKLMNOPQRSTUVWXYZ 1'#10;
  Parse(LText + '    Loop'#10'  }'#10'}'#10);
  Assert.AreEqual(ACTORDEF_MAX_STATES, Length(FEngine.Actors[1].States));
  Assert.IsTrue(Warnings.Contains('Object has more than 1024 states'));
end;

procedure TTestActorDefModel.TestHexenKeywordsSetTheBitsOfTheFlags2;
begin
  CreateParser(TActorDefGame.Hexen);
  Parse('ACTOR HexMonster 2012'#10'{'#10'  MONSTER'#10'}'#10'ACTOR HexMissile 2013'#10'{'#10'  PROJECTILE'#10'}'#10);
  Assert.AreEqual('MF2_PUSHWALL MF2_MCROSS ', FEngine.Actors[1].Flags2);
  Assert.AreEqual('0', FEngine.Actors[1].Flags5Ex);
  Assert.AreEqual('MF2_IMPACT MF2_PCROSS ', FEngine.Actors[2].Flags2);
  CreateParser(TActorDefGame.Doom);
  Parse('ACTOR DoomMonster 2014'#10'{'#10'  MONSTER'#10'}'#10);
  Assert.AreEqual('MF5_EX_PUSHWALL MF5_EX_MCROSS ', FEngine.Actors[3].Flags5Ex);
  Assert.AreEqual('', FEngine.Actors[3].Flags2);
end;

procedure TTestActorDefModel.TestHereticWeaponsHaveALevel;
begin
  CreateParser(TActorDefGame.Heretic);
  Parse('WEAPON 2'#10'{'#10'  Level 2'#10'}'#10'WEAPON 3'#10'{'#10'}'#10);
  Assert.AreEqual(2, FEngine.Weapons[0].Level);
  Assert.AreEqual(1, FEngine.Weapons[1].Level, 'the default level of Heretic');
  CreateParser(TActorDefGame.Doom);
  Parse('WEAPON 4'#10'{'#10'  Level 2'#10'}'#10);
  Assert.AreEqual(0, FEngine.Weapons[2].Level);
  Assert.IsTrue(Warnings.Contains('Unknown token "Level"'));
end;

procedure TTestActorDefModel.TestOnlyStrifeHasASecondName;
begin
  CreateParser(TActorDefGame.Strife);
  Parse('ACTOR Rebel 2015'#10'{'#10'  Name "Rebel Fighter"'#10'}'#10);
  Assert.AreEqual('Rebel Fighter', FEngine.Actors[1].Name2);
  CreateParser(TActorDefGame.Doom);
  Parse('ACTOR Doomer 2016'#10'{'#10'  Name "Doom Fighter"'#10'}'#10);
  Assert.AreEqual('', FEngine.Actors[2].Name2);
  Assert.IsTrue(Warnings.Contains('Unknown token "Name"'));
end;

procedure TTestActorDefModel.TestTheNameOfAThinkerIsCutAt255Characters;
begin
  Parse('THINKER ' + StringOfChar('N', 300) + ' 1 SCRIPT ' + StringOfChar('S', 400) + #10);
  Assert.AreEqual(255, Length(FEngine.Thinkers[0].Name));
  Assert.AreEqual(255, Length(FEngine.Thinkers[0].Script));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestActorDefModel);

end.
