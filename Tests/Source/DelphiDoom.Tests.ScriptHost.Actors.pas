{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the actor functions of PS_GAME                         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.ScriptHost.Actors;

interface

uses
  System.Generics.Collections,
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.ScriptHost.Actors.Intf,
  DelphiDoom.ScriptHost.Actors.KeyList,
  DelphiDoom.ScriptHost.Intf,
  DelphiDoom.ScriptHost.Types,
  DelphiDoom.Tests.ScriptHost.Fakes;

type
  /// <summary>One actor of the fake level</summary>
  TFakeActor = class(TObject)
  public
    Key: Cardinal;
    Numbers: array[TScriptActorField] of Integer;
    Texts: array[TScriptActorText] of string;
    Relations: array[TScriptActorRelation] of Cardinal;
    Params: TDictionary<string, Integer>;
    Flags: TList<Cardinal>;
    PlayerNumber: Integer;
    constructor Create(const AKey: Cardinal);
    destructor Destroy; override;
  end;

  /// <summary>Some actors, a current one (the key 0) and a log of what the library asked</summary>
  TFakeActorSource = class(TInterfacedObject, IScriptActorSource)
  strict private
    function Find(const AKey: Cardinal): TFakeActor;
  public
    Actors: TObjectDictionary<Cardinal, TFakeActor>;
    Current: Cardinal;
    /// <summary>The keys that Collect adds for each selection (they can have duplicates)</summary>
    Selections: array[TScriptActorSelection] of TArray<Cardinal>;
    SpawnedKey: Cardinal;
    SightAnswer: Boolean;
    /// <summary>What the source was asked to do, as text</summary>
    Calls: string;
    constructor Create;
    destructor Destroy; override;
    function Add(const AKey: Cardinal): TFakeActor;
    function KeyOf(const AKey: Cardinal): Cardinal;
    function GetNumber(const AKey: Cardinal; const AField: TScriptActorField;
      const ANotFound: Integer): Integer;
    function GetText(const AKey: Cardinal; const AField: TScriptActorText): string;
    function RelatedKey(const AKey: Cardinal; const ARelation: TScriptActorRelation): Cardinal;
    function CustomParam(const AKey: Cardinal; const AName: string): Integer;
    function CheckFlag(const AKey: Cardinal; const AFlag: Cardinal): Boolean;
    function Distance(const AKey1, AKey2: Cardinal; const AWithZ: Boolean): Integer;
    function PlayerNumber(const AKey: Cardinal): Integer;
    function MobjTypeCount: Integer;
    function MobjTypeFromName(const AName: string): Integer;
    function MobjTypeFromEditorNumber(const ANumber: Integer): Integer;
    function CheckSight(const AKey1, AKey2: Cardinal): Boolean;
    procedure Collect(const ASelection: TScriptActorSelection; const AArgument: Integer;
      const AKeys: TScriptActorKeyList);
    function Exists(const AKey: Cardinal): Boolean;
    procedure SetNumber(const AKey: Cardinal; const AField: TScriptActorField; const AValue: Integer);
    procedure SetText(const AKey: Cardinal; const AField: TScriptActorText; const AValue: string);
    procedure SetRelated(const AKey: Cardinal; const ARelation: TScriptActorRelation;
      const ATargetKey: Cardinal);
    procedure SetPosition(const AKey: Cardinal; const AX, AY, AZ: Integer);
    procedure SetCustomParam(const AKey: Cardinal; const AName: string; const AValue: Integer);
    procedure SetDefaultDropItem(const AKey: Cardinal);
    procedure SetFlag(const AKey: Cardinal; const AFlag: Cardinal; const AOn: Boolean);
    function StateCount: Integer;
    procedure SetState(const AKey: Cardinal; const AState: Integer);
    procedure PlayActorSound(const AKey: Cardinal; const AName: string);
    procedure PlayGlobalSound(const AName: string);
    function Spawn(const AX, AY, AZ: Integer; const AType: Integer): Cardinal;
    procedure Remove(const AKey: Cardinal);
  end;

  TFakeActorContext = class(TInterfacedObject, IScriptActorContext)
  public
    Key: Cardinal;
    constructor Create;
    function CurrentKey: Cardinal;
  end;

  [TestFixture]
  [Category('scripthost')]
  TTestScriptHostActors = class(TObject)
  strict private
    FSource: TFakeActorSource;
    FSourceRef: IScriptActorSource;
    FContext: TFakeActorContext;
    FContextRef: IScriptActorContext;
    FActors: IScriptActors;
    FTables: TList<IScriptFunctionTable>;
    // the objects that were described stay alive while the test calls their functions
    FKept: TList<IScriptActors>;
    function DescribeFor(const AGame: TScriptGame): TFakeFunctionTable;
    function FunctionOf(const ATable: TFakeFunctionTable; const AName: string): Integer;
    function RunScript(const AText: string; const AFields: Integer; out AValues: TArray<string>): Boolean;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeDescrivereLeFunzioniDegliAttoriDiDoomSenzaIlSecondoNome;
    [Test]
    procedure DovrebbeDescrivereIlSecondoNomeSoloInStrife;
    [Test]
    procedure DovrebbeDescrivereGliAttoriNellOrdineDelGolden;
    [Test]
    procedure DovrebbeUsareLoStessoOggettoPerOgniLettura;
    [Test]
    procedure DovrebbeRiusareGliOggettiSeLeFunzioniSonoRichiesteDueVolte;
    [Test]
    procedure DovrebbeDareLAttoreDelContestoOIlNumeroNonValido;
    [Test]
    procedure DovrebbeDareLaChiaveDiUnAttoreEQuellaDelContestoPerLaChiaveZero;
    [Test]
    procedure DovrebbeDareLaChiaveNonValidaPerUnAttoreCheNonCe;
    [Test]
    procedure DovrebbeLeggereIValoriDiUnAttore;
    [Test]
    procedure DovrebbeDareIValoriDiUnAttoreCheNonCe;
    [Test]
    procedure DovrebbeScrivereIValoriDiUnAttore;
    [Test]
    procedure DovrebbeLeggereOgniNumeroDaiGetterRegistrati;
    [Test]
    procedure DovrebbeScrivereOgniNumeroDaiSetterRegistrati;
    [Test]
    procedure DovrebbeConservareIlDifettoDellIndiceDiTessituraZCheScriveQuelloXY;
    [Test]
    procedure DovrebbeLeggereIlSuonoDiRipComeQuelloDiMischia;
    [Test]
    procedure DovrebbeLeggereEScrivereITestiELeRelazioniDaiRegistrati;
    [Test]
    procedure DovrebbeLeggereIlNomeSoloSeLAttoreCe;
    [Test]
    procedure DovrebbeLeggereEScrivereLeRelazioni;
    [Test]
    procedure DovrebbeLeggereEScrivereIParametriPersonalizzati;
    [Test]
    procedure DovrebbeControllareImpostareEToglierIFlag;
    [Test]
    procedure DovrebbeDareLaDistanzaOZeroSeUnAttoreNonCe;
    [Test]
    procedure DovrebbeDareIlGiocatoreDiUnAttoreOIlNumeroNonValido;
    [Test]
    procedure DovrebbeDareLAttoreDiUnGiocatore;
    [Test]
    procedure DovrebbeImpostareLoStatoSoloSeEntroIConfini;
    [Test]
    procedure DovrebbeDireSeUnAttoreEValido;
    [Test]
    procedure DovrebbeSuonareDaUnAttoreOSenzaOrigine;
    [Test]
    procedure DovrebbeGenerareUnAttoreSoloPerUnTipoValido;
    [Test]
    procedure DovrebbeGenerareUnAttoreDalNumeroDiEditorEDalNome;
    [Test]
    procedure DovrebbeRimuovereUnAttore;
    [Test]
    procedure DovrebbeDareLeConversioniDaNomeENumeroDiEditorSenzaControllo;
    [Test]
    procedure DovrebbeDareFalsoPerLaVistaSeUnDeiDueAttoriNonCeSenzaChiederloAlMotore;
    [Test]
    procedure DovrebbeChiederealMotoreLaVistaFraDueAttori;
    [Test]
    procedure DovrebbeDareLeListeDiAttoriSenzaDoppioni;
    [Test]
    procedure DovrebbeChiedereAlMotoreLaSelezioneGiusta;
    [Test]
    procedure DovrebbeDareErroreSeLaSorgenteIlContestoOIGiocatoriSonoNil;
    [Test]
    procedure DovrebbeChiamareLeFunzioniDaUnoScriptVero;
    [Test]
    procedure DovrebbeUsareIlContestoDaUnoScriptVeroPiuVolte;
  end;

  [TestFixture]
  [Category('scripthost')]
  TTestScriptHostActorKeyList = class(TObject)
  strict private
    FList: TScriptActorKeyList;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeAggiungereUnaChiaveUnaVolta;
    [Test]
    procedure DovrebbePortareInTestaLaChiaveCercata;
    [Test]
    procedure DovrebbeLasciareInTestaLaPrimaChiaveCercata;
    [Test]
    procedure DovrebbeDareLaChiaveNonValidaFuoriDallaLista;
    [Test]
    procedure DovrebbeIgnorareLaScritturaFuoriDallaLista;
    [Test]
    procedure DovrebbeTogliereUnaChiaveLasciandoLUltimaAlSuoPosto;
    [Test]
    procedure DovrebbeDareFalsoSeTogliereUnaChiaveCheNonCe;
    [Test]
    procedure DovrebbeAmmettereDoppioniSeRichiesto;
    [Test]
    procedure DovrebbeTogliereTutteLeCopieDiUnaChiaveConDoppioni;
    [Test]
    procedure DovrebbeTogliereIDoppioniSpegnendoLaProprieta;
    [Test]
    procedure DovrebbeSvuotareLaLista;
    [Test]
    procedure DovrebbeCrescereOltreLaCapacitaIniziale;
  end;

implementation

uses
  ps_defs,
  ps_utils,
  ps_keywords,
  ps_compiler,
  ps_runtime,
  DelphiDoom.ScriptHost.Factory,
  DelphiDoom.ScriptHost.FunctionList,
  DelphiDoom.ScriptHost.Players.Intf,
  DelphiDoom.ScriptHost.World.Intf,
  DelphiDoom.Tests.ScriptHost.Players;

type
  /// <summary>Passes on to a real list what a script can compile (the function that gives a class of the scripts is left out)</summary>
  TActorsWithoutClassResults = class(TInterfacedObject, IScriptFunctionTable)
  strict private
    FList: IScriptFunctionTable;
  public
    constructor Create(const AList: IScriptFunctionTable);
    procedure Add(const ADeclaration: string; const ACode: Pointer);
    procedure AddWithCustomResult(const ADeclaration, AResultType, AExportDeclaration: string;
      const ACode: Pointer);
    procedure AddMethod(const ADeclaration: string; const AInstance: TObject; const ACode: Pointer);
    procedure AddMethodWithCustomResult(const ADeclaration, AResultType, AExportDeclaration: string;
      const AInstance: TObject; const ACode: Pointer);
  end;

var
  GUsedList: TScriptFunctionList;

function OnUsesActorList(Sender: TPSPascalCompiler; const Name: TbtString): Boolean;
begin
  Result := string(Name) = 'SYSTEM';
  if Result then
  begin
    Sender.AddTypeS('fixed_t', 'Integer');
    Sender.AddTypeS('angle_t', 'LongWord');
    Sender.AddTypeS('TActorArray', 'array of LongWord');
    GUsedList.RegisterCompiler(Sender);
  end;
end;

{ TActorsWithoutClassResults }

constructor TActorsWithoutClassResults.Create(const AList: IScriptFunctionTable);
begin
  inherited Create;
  FList := AList;
end;

procedure TActorsWithoutClassResults.Add(const ADeclaration: string; const ACode: Pointer);
begin
  FList.Add(ADeclaration, ACode);
end;

procedure TActorsWithoutClassResults.AddWithCustomResult(const ADeclaration, AResultType,
  AExportDeclaration: string; const ACode: Pointer);
begin
end;

procedure TActorsWithoutClassResults.AddMethod(const ADeclaration: string; const AInstance: TObject;
  const ACode: Pointer);
begin
  FList.AddMethod(ADeclaration, AInstance, ACode);
end;

procedure TActorsWithoutClassResults.AddMethodWithCustomResult(const ADeclaration, AResultType,
  AExportDeclaration: string; const AInstance: TObject; const ACode: Pointer);
begin
end;

{ TFakeActor }

constructor TFakeActor.Create(const AKey: Cardinal);
begin
  inherited Create;
  Key := AKey;
  Params := TDictionary<string, Integer>.Create;
  Flags := TList<Cardinal>.Create;
  PlayerNumber := -1;
  Relations[acrTarget] := SCRIPT_INVALID_ID;
  Relations[acrTracer] := SCRIPT_INVALID_ID;
  Relations[acrMaster] := SCRIPT_INVALID_ID;
end;

destructor TFakeActor.Destroy;
begin
  Flags.Free;
  Params.Free;
  inherited Destroy;
end;

{ TFakeActorSource }

constructor TFakeActorSource.Create;
begin
  inherited Create;
  Actors := TObjectDictionary<Cardinal, TFakeActor>.Create([doOwnsValues]);
  Current := SCRIPT_INVALID_ID;
  SightAnswer := True;
  SpawnedKey := 900;
end;

destructor TFakeActorSource.Destroy;
begin
  Actors.Free;
  inherited Destroy;
end;

function TFakeActorSource.Add(const AKey: Cardinal): TFakeActor;
begin
  Result := TFakeActor.Create(AKey);
  Actors.Add(AKey, Result);
end;

function TFakeActorSource.Find(const AKey: Cardinal): TFakeActor;
var
  LKey: Cardinal;
begin
  LKey := AKey;
  if LKey = 0 then
    LKey := Current;
  if not Actors.TryGetValue(LKey, Result) then
    Result := nil;
end;

function TFakeActorSource.KeyOf(const AKey: Cardinal): Cardinal;
var
  LActor: TFakeActor;
begin
  LActor := Find(AKey);
  if Assigned(LActor) then
    Result := LActor.Key
  else
    Result := SCRIPT_INVALID_ID;
end;

function TFakeActorSource.GetNumber(const AKey: Cardinal; const AField: TScriptActorField;
  const ANotFound: Integer): Integer;
var
  LActor: TFakeActor;
begin
  LActor := Find(AKey);
  if Assigned(LActor) then
    Result := LActor.Numbers[AField]
  else
    Result := ANotFound;
end;

function TFakeActorSource.GetText(const AKey: Cardinal; const AField: TScriptActorText): string;
var
  LActor: TFakeActor;
begin
  LActor := Find(AKey);
  if Assigned(LActor) then
    Result := LActor.Texts[AField]
  else
    Result := '';
end;

function TFakeActorSource.RelatedKey(const AKey: Cardinal; const ARelation: TScriptActorRelation): Cardinal;
var
  LActor: TFakeActor;
begin
  LActor := Find(AKey);
  if Assigned(LActor) then
    Result := LActor.Relations[ARelation]
  else
    Result := SCRIPT_INVALID_ID;
end;

function TFakeActorSource.CustomParam(const AKey: Cardinal; const AName: string): Integer;
var
  LActor: TFakeActor;
begin
  LActor := Find(AKey);
  if not Assigned(LActor) or not LActor.Params.TryGetValue(AName, Result) then
    Result := 0;
end;

function TFakeActorSource.CheckFlag(const AKey: Cardinal; const AFlag: Cardinal): Boolean;
var
  LActor: TFakeActor;
begin
  LActor := Find(AKey);
  Result := Assigned(LActor) and LActor.Flags.Contains(AFlag);
end;

function TFakeActorSource.Distance(const AKey1, AKey2: Cardinal; const AWithZ: Boolean): Integer;
var
  LFirst: TFakeActor;
  LSecond: TFakeActor;
begin
  LFirst := Find(AKey1);
  LSecond := Find(AKey2);
  if not Assigned(LFirst) or not Assigned(LSecond) then
  begin
    Result := 0;
    Exit;
  end;
  Result := Abs(LFirst.Numbers[acfX] - LSecond.Numbers[acfX]) +
    Abs(LFirst.Numbers[acfY] - LSecond.Numbers[acfY]);
  if AWithZ then
    Inc(Result, Abs(LFirst.Numbers[acfZ] - LSecond.Numbers[acfZ]));
end;

function TFakeActorSource.PlayerNumber(const AKey: Cardinal): Integer;
var
  LActor: TFakeActor;
begin
  LActor := Find(AKey);
  if Assigned(LActor) then
    Result := LActor.PlayerNumber
  else
    Result := -1;
end;

function TFakeActorSource.MobjTypeCount: Integer;
begin
  Result := 10;
end;

function TFakeActorSource.MobjTypeFromName(const AName: string): Integer;
begin
  if AName = 'IMP' then
    Result := 3
  else if AName = 'HUGE' then
    Result := 50
  else
    Result := -1;
end;

function TFakeActorSource.MobjTypeFromEditorNumber(const ANumber: Integer): Integer;
begin
  if ANumber = 3001 then
    Result := 4
  else
    Result := -1;
end;

function TFakeActorSource.CheckSight(const AKey1, AKey2: Cardinal): Boolean;
begin
  Calls := Calls + Format('S(%d,%d)', [AKey1, AKey2]);
  Result := SightAnswer;
end;

procedure TFakeActorSource.Collect(const ASelection: TScriptActorSelection; const AArgument: Integer;
  const AKeys: TScriptActorKeyList);
var
  LKey: Cardinal;
begin
  Calls := Calls + Format('C(%d,%d)', [Ord(ASelection), AArgument]);
  for LKey in Selections[ASelection] do
    AKeys.Add(LKey);
end;

function TFakeActorSource.Exists(const AKey: Cardinal): Boolean;
begin
  Result := Assigned(Find(AKey));
end;

procedure TFakeActorSource.SetNumber(const AKey: Cardinal; const AField: TScriptActorField;
  const AValue: Integer);
var
  LActor: TFakeActor;
begin
  // the engine writes none of the read only fields (the state has its own method)
  if AField in [acfSpawnHealth, acfSector, acfMobjType, acfEditorNumber, acfState] then
    Exit;
  LActor := Find(AKey);
  if Assigned(LActor) then
    LActor.Numbers[AField] := AValue;
end;

procedure TFakeActorSource.SetText(const AKey: Cardinal; const AField: TScriptActorText;
  const AValue: string);
var
  LActor: TFakeActor;
begin
  LActor := Find(AKey);
  if Assigned(LActor) then
    LActor.Texts[AField] := AValue;
end;

procedure TFakeActorSource.SetRelated(const AKey: Cardinal; const ARelation: TScriptActorRelation;
  const ATargetKey: Cardinal);
var
  LActor: TFakeActor;
begin
  LActor := Find(AKey);
  if Assigned(LActor) then
    LActor.Relations[ARelation] := KeyOf(ATargetKey);
end;

procedure TFakeActorSource.SetPosition(const AKey: Cardinal; const AX, AY, AZ: Integer);
var
  LActor: TFakeActor;
begin
  LActor := Find(AKey);
  if not Assigned(LActor) then
    Exit;
  LActor.Numbers[acfX] := AX;
  LActor.Numbers[acfY] := AY;
  LActor.Numbers[acfZ] := AZ;
end;

procedure TFakeActorSource.SetCustomParam(const AKey: Cardinal; const AName: string;
  const AValue: Integer);
var
  LActor: TFakeActor;
begin
  LActor := Find(AKey);
  if Assigned(LActor) then
    LActor.Params.AddOrSetValue(AName, AValue);
end;

procedure TFakeActorSource.SetDefaultDropItem(const AKey: Cardinal);
var
  LActor: TFakeActor;
begin
  LActor := Find(AKey);
  if Assigned(LActor) then
    LActor.Numbers[acfCustomDropItem] := -1;
end;

procedure TFakeActorSource.SetFlag(const AKey: Cardinal; const AFlag: Cardinal; const AOn: Boolean);
var
  LActor: TFakeActor;
begin
  LActor := Find(AKey);
  if not Assigned(LActor) then
    Exit;
  LActor.Flags.Remove(AFlag);
  if AOn then
    LActor.Flags.Add(AFlag);
end;

function TFakeActorSource.StateCount: Integer;
begin
  Result := 20;
end;

procedure TFakeActorSource.SetState(const AKey: Cardinal; const AState: Integer);
var
  LActor: TFakeActor;
begin
  LActor := Find(AKey);
  if Assigned(LActor) then
    LActor.Numbers[acfState] := AState;
end;

procedure TFakeActorSource.PlayActorSound(const AKey: Cardinal; const AName: string);
begin
  Calls := Calls + Format('A(%d,%s)', [AKey, AName]);
end;

procedure TFakeActorSource.PlayGlobalSound(const AName: string);
begin
  Calls := Calls + Format('G(%s)', [AName]);
end;

function TFakeActorSource.Spawn(const AX, AY, AZ: Integer; const AType: Integer): Cardinal;
begin
  Calls := Calls + Format('N(%d,%d,%d,%d)', [AX, AY, AZ, AType]);
  Inc(SpawnedKey);
  Result := SpawnedKey;
  Add(Result).Numbers[acfMobjType] := AType;
end;

procedure TFakeActorSource.Remove(const AKey: Cardinal);
var
  LActor: TFakeActor;
begin
  LActor := Find(AKey);
  if Assigned(LActor) then
    Actors.Remove(LActor.Key);
  Calls := Calls + Format('R(%d)', [AKey]);
end;

{ TFakeActorContext }

constructor TFakeActorContext.Create;
begin
  inherited Create;
  Key := SCRIPT_INVALID_ID;
end;

function TFakeActorContext.CurrentKey: Cardinal;
begin
  Result := Key;
end;

{ TTestScriptHostActors }

procedure TTestScriptHostActors.Setup;
var
  LActor: TFakeActor;
begin
  FSource := TFakeActorSource.Create;
  FSourceRef := FSource;
  FContext := TFakeActorContext.Create;
  FContextRef := FContext;
  // 100 is the player, 101 an imp, 102 a rocket
  LActor := FSource.Add(100);
  LActor.PlayerNumber := 1;
  LActor.Numbers[acfX] := 1000;
  LActor.Numbers[acfY] := 2000;
  LActor.Numbers[acfZ] := 30;
  LActor.Numbers[acfHealth] := 100;
  LActor.Numbers[acfMobjType] := 0;
  LActor.Numbers[acfEditorNumber] := 1;
  LActor.Texts[actName] := 'PLAYER';
  LActor.Texts[actMeleeSound] := 'dsmelee';
  LActor.Texts[actSeeSound] := 'dssee';
  LActor := FSource.Add(101);
  LActor.Numbers[acfX] := 4000;
  LActor.Numbers[acfY] := 5000;
  LActor.Numbers[acfZ] := 60;
  LActor.Numbers[acfHealth] := 60;
  LActor.Numbers[acfMobjType] := 3;
  LActor.Numbers[acfEditorNumber] := 3001;
  LActor.Numbers[acfState] := 7;
  LActor.Texts[actName] := 'IMP';
  LActor := FSource.Add(102);
  LActor.Numbers[acfX] := 1000;
  LActor.Numbers[acfY] := 2000;
  LActor.Numbers[acfZ] := 90;
  FSource.Current := 101;
  FContext.Key := 101;
  FActors := TScriptHostFactory.CreateActors(FSourceRef, FContextRef,
    TScriptHostFactory.CreatePlayers(TFakePlayerSource.Create, sgDoom), sgDoom);
  FTables := TList<IScriptFunctionTable>.Create;
  FKept := TList<IScriptActors>.Create;
end;

procedure TTestScriptHostActors.TearDown;
begin
  FKept.Free;
  FTables.Free;
  FActors := nil;
  FContextRef := nil;
  FContext := nil;
  FSourceRef := nil;
  FSource := nil;
end;

function TTestScriptHostActors.DescribeFor(const AGame: TScriptGame): TFakeFunctionTable;
var
  LRef: IScriptFunctionTable;
  LActors: IScriptActors;
begin
  Result := TFakeFunctionTable.Create;
  LRef := Result;
  FTables.Add(LRef);
  LActors := TScriptHostFactory.CreateActors(FSourceRef, FContextRef,
    TScriptHostFactory.CreatePlayers(TFakePlayerSource.Create, AGame), AGame);
  FKept.Add(LActors);
  LActors.Describe(LRef);
end;

function TTestScriptHostActors.FunctionOf(const ATable: TFakeFunctionTable; const AName: string): Integer;
var
  LIndex: Integer;
begin
  for LIndex := 0 to ATable.Declarations.Count - 1 do
    if ATable.Declarations[LIndex].Contains(' ' + AName + '(') or
       ATable.Declarations[LIndex].Contains(' ' + AName + ':') or
       ATable.Declarations[LIndex].EndsWith(' ' + AName + ';') then
      Exit(LIndex);
  Result := -1;
end;

procedure TTestScriptHostActors.DovrebbeDescrivereLeFunzioniDegliAttoriDiDoomSenzaIlSecondoNome;
var
  LTable: TFakeFunctionTable;
begin
  LTable := DescribeFor(sgDoom);
  Assert.AreEqual(114, LTable.Declarations.Count);
  Assert.AreEqual(-1, FunctionOf(LTable, 'GetActorName2'));
  Assert.IsTrue(FunctionOf(LTable, 'GetActorName') > 0);
end;

procedure TTestScriptHostActors.DovrebbeDescrivereIlSecondoNomeSoloInStrife;
var
  LTable: TFakeFunctionTable;
begin
  LTable := DescribeFor(sgStrife);
  Assert.AreEqual(115, LTable.Declarations.Count);
  Assert.IsTrue(FunctionOf(LTable, 'GetActorName2') > FunctionOf(LTable, 'GetActorName'));
  Assert.AreEqual(114, DescribeFor(sgHeretic).Declarations.Count);
  Assert.AreEqual(114, DescribeFor(sgHexen).Declarations.Count);
end;

procedure TTestScriptHostActors.DovrebbeDescrivereGliAttoriNellOrdineDelGolden;
var
  LGolden: TArray<string>;
  LTable: TFakeFunctionTable;
  LIndex: Integer;
begin
  LGolden := GoldenDeclarations('PS_GAME');
  if Length(LGolden) = 0 then
  begin
    Assert.Pass('golden della registrazione non trovato');
    Exit;
  end;
  LTable := DescribeFor(sgDoom);
  // the actors are the first functions of PS_GAME: the golden has the text as the old code wrote it
  for LIndex := 0 to LTable.Declarations.Count - 1 do
    Assert.AreEqual(LGolden[LIndex], LTable.ExportDeclarations[LIndex]);
  Assert.AreEqual('function GetActorMeleeSound(const key: LongWord): string;',
    LTable.ExportDeclarations[LTable.Declarations.Count - 1]);
  Assert.AreEqual('!TActor', LTable.ResultTypes[1]);
  Assert.AreEqual('procedure TActor(const key: LongWord);', LTable.Declarations[1]);
end;

procedure TTestScriptHostActors.DovrebbeUsareLoStessoOggettoPerOgniLettura;
var
  LTable: TFakeFunctionTable;
begin
  LTable := DescribeFor(sgDoom);
  // the class answers Actor, TActor and the methods; a field has one object for the reading
  Assert.AreSame(LTable.Instances[0], LTable.Instances[1]);
  Assert.AreNotSame(LTable.Instances[0], LTable.Instances[FunctionOf(LTable, 'GetActorX')]);
  Assert.AreNotSame(LTable.Instances[FunctionOf(LTable, 'GetActorX')],
    LTable.Instances[FunctionOf(LTable, 'SetActorX')]);
  Assert.AreNotSame(LTable.Instances[FunctionOf(LTable, 'GetActorX')],
    LTable.Instances[FunctionOf(LTable, 'GetActorY')]);
  // the two functions that write the same field are one object (weave index Z writes the XY field)
  Assert.AreSame(LTable.Instances[FunctionOf(LTable, 'SetActorWeaveIndexXY')],
    LTable.Instances[FunctionOf(LTable, 'SetActorWeaveIndexZ')]);
end;

procedure TTestScriptHostActors.DovrebbeRiusareGliOggettiSeLeFunzioniSonoRichiesteDueVolte;
var
  LFirst: TFakeFunctionTable;
  LSecond: TFakeFunctionTable;
  LSecondRef: IScriptFunctionTable;
  LActors: IScriptActors;
begin
  LActors := TScriptHostFactory.CreateActors(FSourceRef, FContextRef,
    TScriptHostFactory.CreatePlayers(TFakePlayerSource.Create, sgDoom), sgDoom);
  LFirst := TFakeFunctionTable.Create;
  FTables.Add(LFirst);
  LSecond := TFakeFunctionTable.Create;
  LSecondRef := LSecond;
  FTables.Add(LSecondRef);
  LActors.Describe(LFirst);
  LActors.Describe(LSecondRef);
  Assert.AreEqual(LFirst.Declarations.Count, LSecond.Declarations.Count);
  Assert.AreSame(LFirst.Instances[FunctionOf(LFirst, 'GetActorX')],
    LSecond.Instances[FunctionOf(LSecond, 'GetActorX')]);
end;

procedure TTestScriptHostActors.DovrebbeDareLAttoreDelContestoOIlNumeroNonValido;
begin
  Assert.AreEqual(Cardinal(101), FActors.Actor);
  FContext.Key := SCRIPT_INVALID_ID;
  Assert.AreEqual(Cardinal(SCRIPT_INVALID_ID), FActors.Actor);
end;

procedure TTestScriptHostActors.DovrebbeDareLaChiaveDiUnAttoreEQuellaDelContestoPerLaChiaveZero;
begin
  Assert.AreEqual(Cardinal(100), FActors.TActor(100));
  Assert.AreEqual(Cardinal(101), FActors.TActor(0));
  FSource.Current := SCRIPT_INVALID_ID;
  Assert.AreEqual(Cardinal(SCRIPT_INVALID_ID), FActors.TActor(0));
end;

procedure TTestScriptHostActors.DovrebbeDareLaChiaveNonValidaPerUnAttoreCheNonCe;
begin
  Assert.AreEqual(Cardinal(SCRIPT_INVALID_ID), FActors.TActor(555));
  Assert.AreEqual(Cardinal(SCRIPT_INVALID_ID), FActors.TActor(SCRIPT_INVALID_ID));
end;

procedure TTestScriptHostActors.DovrebbeLeggereIValoriDiUnAttore;
begin
  Assert.AreEqual(1000, FActors.GetNumber(100, acfX));
  Assert.AreEqual(2000, FActors.GetNumber(100, acfY));
  Assert.AreEqual(4000, FActors.GetNumber(0, acfX));
  Assert.AreEqual(3, FActors.GetNumber(101, acfMobjType));
  Assert.AreEqual(7, FActors.GetNumber(101, acfState));
end;

procedure TTestScriptHostActors.DovrebbeDareIValoriDiUnAttoreCheNonCe;
var
  LField: TScriptActorField;
begin
  for LField := Low(TScriptActorField) to High(TScriptActorField) do
    if LField in [acfMobjType, acfEditorNumber, acfState] then
      Assert.AreEqual(SCRIPT_INVALID_ID, FActors.GetNumber(555, LField), 'invalid')
    else
      Assert.AreEqual(0, FActors.GetNumber(555, LField), 'zero');
end;

procedure TTestScriptHostActors.DovrebbeScrivereIValoriDiUnAttore;
begin
  FActors.SetNumber(100, acfMomX, 77);
  FActors.SetNumber(0, acfMomY, 88);
  FActors.SetNumber(555, acfMomZ, 99);
  Assert.AreEqual(77, FSource.Actors[100].Numbers[acfMomX]);
  Assert.AreEqual(88, FSource.Actors[101].Numbers[acfMomY]);
  Assert.IsFalse(FSource.Actors.ContainsKey(555));
  FActors.SetActorPosition(102, 1, 2, 3);
  Assert.AreEqual(2, FSource.Actors[102].Numbers[acfY]);
  FActors.SetActorPosition(555, 1, 2, 3);
end;

const
  // the registered numbers: the name of the function without Get or Set and the field it reads and writes
  // (SetActorWeaveIndexZ writes the XY index, a defect of the old code that is kept)
  ACTOR_NUMBER_NAMES: array[0..30] of string = (
    'X', 'Y', 'Z', 'MOMX', 'MOMY', 'MOMZ', 'FloorZ', 'CeilingZ', 'Speed', 'Angle', 'Health', 'Mass',
    'Height', 'CustomDropItem', 'PushFactor', 'Scale', 'Gravity', 'Special', 'Arg1', 'Arg2', 'Arg3',
    'Arg4', 'Arg5', 'WeaveIndexXY', 'Friction', 'PainChance', 'SpriteDX', 'SpriteDY',
    'InfightingGroup', 'ProjectileGroup', 'SplashGroup');
  ACTOR_NUMBER_FIELDS: array[0..30] of TScriptActorField = (
    acfX, acfY, acfZ, acfMomX, acfMomY, acfMomZ, acfFloorZ, acfCeilingZ, acfSpeed, acfAngle,
    acfHealth, acfMass, acfHeight, acfCustomDropItem, acfPushFactor, acfScale, acfGravity,
    acfSpecial, acfArg1, acfArg2, acfArg3, acfArg4, acfArg5, acfWeaveIndexXY, acfFriction,
    acfPainChance, acfSpriteDX, acfSpriteDY, acfInfightingGroup, acfProjectileGroup,
    acfSplashGroup);

procedure TTestScriptHostActors.DovrebbeLeggereOgniNumeroDaiGetterRegistrati;
var
  LTable: TFakeFunctionTable;
  LIndex: Integer;
  LFunction: Integer;
  LGet: function(const AKey: Cardinal): Integer of object;

  procedure Bind(const AName: string);
  begin
    LFunction := FunctionOf(LTable, AName);
    Assert.IsTrue(LFunction >= 0, AName);
    TMethod(LGet).Data := LTable.Instances[LFunction];
    TMethod(LGet).Code := LTable.Codes[LFunction];
  end;

begin
  LTable := DescribeFor(sgDoom);
  for LIndex := 0 to High(ACTOR_NUMBER_NAMES) do
  begin
    FSource.Actors[100].Numbers[ACTOR_NUMBER_FIELDS[LIndex]] := 1000 + LIndex;
    Bind('GetActor' + ACTOR_NUMBER_NAMES[LIndex]);
    Assert.AreEqual(1000 + LIndex, LGet(100), ACTOR_NUMBER_NAMES[LIndex]);
  end;
  // the numbers that scripts can read and not write
  FSource.Actors[100].Numbers[acfSpawnHealth] := 11;
  FSource.Actors[100].Numbers[acfSector] := 12;
  FSource.Actors[100].Numbers[acfMobjType] := 13;
  FSource.Actors[100].Numbers[acfEditorNumber] := 14;
  FSource.Actors[100].Numbers[acfState] := 15;
  FSource.Actors[100].Numbers[acfWeaveIndexZ] := 16;
  Bind('GetActorSpawnHealth');
  Assert.AreEqual(11, LGet(100));
  Bind('GetActorSector');
  Assert.AreEqual(12, LGet(100));
  Bind('GetActorMobjType');
  Assert.AreEqual(13, LGet(100));
  Bind('GetActorEditorNumber');
  Assert.AreEqual(14, LGet(100));
  Bind('GetActorState');
  Assert.AreEqual(15, LGet(100));
  Bind('GetActorWeaveIndexZ');
  Assert.AreEqual(16, LGet(100));
end;

procedure TTestScriptHostActors.DovrebbeScrivereOgniNumeroDaiSetterRegistrati;
var
  LTable: TFakeFunctionTable;
  LIndex: Integer;
  LFunction: Integer;
  LPut: procedure(const AKey: Cardinal; const AValue: Integer) of object;

  procedure Bind(const AName: string);
  begin
    LFunction := FunctionOf(LTable, AName);
    Assert.IsTrue(LFunction >= 0, AName);
    TMethod(LPut).Data := LTable.Instances[LFunction];
    TMethod(LPut).Code := LTable.Codes[LFunction];
  end;

begin
  LTable := DescribeFor(sgDoom);
  for LIndex := 0 to High(ACTOR_NUMBER_NAMES) do
  begin
    Bind('SetActor' + ACTOR_NUMBER_NAMES[LIndex]);
    LPut(100, 2000 + LIndex);
    Assert.AreEqual(2000 + LIndex, FSource.Actors[100].Numbers[ACTOR_NUMBER_FIELDS[LIndex]],
      ACTOR_NUMBER_NAMES[LIndex]);
  end;
  // the state has its own method, which checks the number of the state (the fake writes no read only field)
  Bind('SetActorState');
  LPut(100, 9);
  Assert.AreEqual(9, FSource.Actors[100].Numbers[acfState]);
  LPut(100, 500);
  Assert.AreEqual(9, FSource.Actors[100].Numbers[acfState]);
  // the Z weave index writes the XY one
  Bind('SetActorWeaveIndexZ');
  LPut(100, 77);
  Assert.AreEqual(77, FSource.Actors[100].Numbers[acfWeaveIndexXY]);
end;

procedure TTestScriptHostActors.DovrebbeConservareIlDifettoDellIndiceDiTessituraZCheScriveQuelloXY;
var
  LTable: TFakeFunctionTable;
  LBinding: TObject;
  LPut: procedure(const AKey: Cardinal; const AValue: Integer) of object;
begin
  LTable := DescribeFor(sgDoom);
  // the old SetActorWeaveIndexZ wrote WeaveIndexXY: the function of the Z index is the object of the XY field
  LBinding := LTable.Instances[FunctionOf(LTable, 'SetActorWeaveIndexZ')];
  TMethod(LPut).Data := LBinding;
  TMethod(LPut).Code := LTable.Codes[FunctionOf(LTable, 'SetActorWeaveIndexZ')];
  LPut(100, 42);
  Assert.AreEqual(42, FSource.Actors[100].Numbers[acfWeaveIndexXY]);
  Assert.AreEqual(0, FSource.Actors[100].Numbers[acfWeaveIndexZ]);
end;

procedure TTestScriptHostActors.DovrebbeLeggereIlSuonoDiRipComeQuelloDiMischia;
var
  LTable: TFakeFunctionTable;
  LGet: function(const AKey: Cardinal): string of object;
  LIndex: Integer;
begin
  LTable := DescribeFor(sgDoom);
  LIndex := FunctionOf(LTable, 'GetActorRipSound');
  TMethod(LGet).Data := LTable.Instances[LIndex];
  TMethod(LGet).Code := LTable.Codes[LIndex];
  // the old GetActorRipSound read the melee sound of the actor
  Assert.AreEqual('dsmelee', LGet(100));
  Assert.AreEqual('', LGet(555));
end;

const
  ACTOR_TEXT_NAMES: array[0..11] of string = (
    'Translation', 'BloodColor', 'Name', 'SeeSound', 'AttackSound', 'PainSound', 'DeathSound',
    'ActiveSound', 'CustomSound1', 'CustomSound2', 'CustomSound3', 'MeleeSound');
  ACTOR_TEXT_FIELDS: array[0..11] of TScriptActorText = (
    actTranslation, actBloodColor, actName, actSeeSound, actAttackSound, actPainSound,
    actDeathSound, actActiveSound, actCustomSound1, actCustomSound2, actCustomSound3,
    actMeleeSound);
  ACTOR_RELATION_NAMES: array[0..2] of string = ('Target', 'Tracer', 'Master');
  ACTOR_RELATION_FIELDS: array[0..2] of TScriptActorRelation = (acrTarget, acrTracer, acrMaster);

procedure TTestScriptHostActors.DovrebbeLeggereEScrivereITestiELeRelazioniDaiRegistrati;
var
  LTable: TFakeFunctionTable;
  LIndex: Integer;
  LFunction: Integer;
  LGetText: function(const AKey: Cardinal): string of object;
  LPutText: procedure(const AKey: Cardinal; const AValue: string) of object;
  LGetKey: function(const AKey: Cardinal): Cardinal of object;
  LPutKey: procedure(const AKey: Cardinal; const ATargetKey: Cardinal) of object;

  function Bind(const AName: string; out ACode: TMethod): Boolean;
  begin
    LFunction := FunctionOf(LTable, AName);
    Result := LFunction >= 0;
    if not Result then
      Exit;
    ACode.Data := LTable.Instances[LFunction];
    ACode.Code := LTable.Codes[LFunction];
  end;

begin
  LTable := DescribeFor(sgDoom);
  for LIndex := 0 to High(ACTOR_TEXT_NAMES) do
  begin
    FSource.Actors[100].Texts[ACTOR_TEXT_FIELDS[LIndex]] := 'text' + System.SysUtils.IntToStr(LIndex);
    Assert.IsTrue(Bind('GetActor' + ACTOR_TEXT_NAMES[LIndex], TMethod(LGetText)), ACTOR_TEXT_NAMES[LIndex]);
    Assert.AreEqual('text' + System.SysUtils.IntToStr(LIndex), LGetText(100), ACTOR_TEXT_NAMES[LIndex]);
  end;
  // the sound of the rip is the sound of the melee (kept), the second name does not exist in Doom
  Assert.IsTrue(Bind('GetActorRipSound', TMethod(LGetText)));
  Assert.AreEqual('text11', LGetText(100));
  Assert.IsFalse(Bind('GetActorName2', TMethod(LGetText)));
  // the two texts that scripts can write
  Assert.IsTrue(Bind('SetActorTranslation', TMethod(LPutText)));
  LPutText(100, 'ICE');
  Assert.AreEqual('ICE', FSource.Actors[100].Texts[actTranslation]);
  Assert.IsTrue(Bind('SetActorBloodColor', TMethod(LPutText)));
  LPutText(100, 'BLUE');
  Assert.AreEqual('BLUE', FSource.Actors[100].Texts[actBloodColor]);
  // the actors that an actor points to
  for LIndex := 0 to High(ACTOR_RELATION_NAMES) do
  begin
    Assert.IsTrue(Bind('SetActor' + ACTOR_RELATION_NAMES[LIndex], TMethod(LPutKey)), ACTOR_RELATION_NAMES[LIndex]);
    LPutKey(100, 102 - LIndex);
    Assert.IsTrue(Bind('GetActor' + ACTOR_RELATION_NAMES[LIndex], TMethod(LGetKey)), ACTOR_RELATION_NAMES[LIndex]);
    Assert.AreEqual(Cardinal(102 - LIndex), LGetKey(100), ACTOR_RELATION_NAMES[LIndex]);
    Assert.AreEqual(Cardinal(102 - LIndex), FSource.Actors[100].Relations[ACTOR_RELATION_FIELDS[LIndex]],
      ACTOR_RELATION_NAMES[LIndex]);
  end;
end;

procedure TTestScriptHostActors.DovrebbeLeggereIlNomeSoloSeLAttoreCe;
begin
  Assert.AreEqual('PLAYER', FActors.GetText(100, actName));
  Assert.AreEqual('IMP', FActors.GetText(0, actName));
  Assert.AreEqual('', FActors.GetText(555, actName));
  FActors.SetText(100, actTranslation, 'ICE');
  Assert.AreEqual('ICE', FSource.Actors[100].Texts[actTranslation]);
  FActors.SetText(555, actTranslation, 'ICE');
end;

procedure TTestScriptHostActors.DovrebbeLeggereEScrivereLeRelazioni;
begin
  Assert.AreEqual(Cardinal(SCRIPT_INVALID_ID), FActors.GetRelation(101, acrTarget));
  FActors.SetRelation(101, acrTarget, 100);
  FActors.SetRelation(101, acrMaster, 0);
  FActors.SetRelation(101, acrTracer, 555);
  Assert.AreEqual(Cardinal(100), FActors.GetRelation(101, acrTarget));
  Assert.AreEqual(Cardinal(101), FActors.GetRelation(101, acrMaster));
  Assert.AreEqual(Cardinal(SCRIPT_INVALID_ID), FActors.GetRelation(101, acrTracer));
  Assert.AreEqual(Cardinal(SCRIPT_INVALID_ID), FActors.GetRelation(555, acrTarget));
end;

procedure TTestScriptHostActors.DovrebbeLeggereEScrivereIParametriPersonalizzati;
begin
  Assert.AreEqual(0, FActors.GetActorCustomParam(100, 'ammo'));
  FActors.SetActorCustomParam(100, 'ammo', 12);
  Assert.AreEqual(12, FActors.GetActorCustomParam(100, 'ammo'));
  Assert.AreEqual(0, FActors.GetActorCustomParam(555, 'ammo'));
  FActors.SetActorDefaultDropItem(100);
  Assert.AreEqual(-1, FSource.Actors[100].Numbers[acfCustomDropItem]);
end;

procedure TTestScriptHostActors.DovrebbeControllareImpostareEToglierIFlag;
begin
  Assert.IsFalse(FActors.CheckActorFlag(100, 5));
  FActors.SetActorFlag(100, 5);
  Assert.IsTrue(FActors.CheckActorFlag(100, 5));
  FActors.UnSetActorFlag(100, 5);
  Assert.IsFalse(FActors.CheckActorFlag(100, 5));
  Assert.IsFalse(FActors.CheckActorFlag(555, 5));
end;

procedure TTestScriptHostActors.DovrebbeDareLaDistanzaOZeroSeUnAttoreNonCe;
begin
  Assert.AreEqual(6000, FActors.GetActorDistanceXY(100, 101));
  Assert.AreEqual(6030, FActors.GetActorDistanceXYZ(100, 101));
  Assert.AreEqual(0, FActors.GetActorDistanceXY(100, 555));
  Assert.AreEqual(0, FActors.GetActorDistanceXYZ(555, 100));
end;

procedure TTestScriptHostActors.DovrebbeDareIlGiocatoreDiUnAttoreOIlNumeroNonValido;
begin
  Assert.AreEqual(1, FActors.GetActorPlayer(100));
  Assert.AreEqual(SCRIPT_INVALID_ID, FActors.GetActorPlayer(101));
  Assert.AreEqual(SCRIPT_INVALID_ID, FActors.GetActorPlayer(555));
end;

procedure TTestScriptHostActors.DovrebbeDareLAttoreDiUnGiocatore;
var
  LTable: TFakeFunctionTable;
  LIndex: Integer;
  LGet: function(const APlayer: Integer): Cardinal of object;
begin
  LTable := DescribeFor(sgDoom);
  LIndex := FunctionOf(LTable, 'GetPlayerActor');
  Assert.IsTrue(LIndex > 0);
  TMethod(LGet).Data := LTable.Instances[LIndex];
  TMethod(LGet).Code := LTable.Codes[LIndex];
  Assert.AreEqual(Cardinal(501), LGet(1));
  Assert.AreEqual(Cardinal(SCRIPT_INVALID_ID), LGet(2));
end;

procedure TTestScriptHostActors.DovrebbeImpostareLoStatoSoloSeEntroIConfini;
begin
  FActors.SetActorState(100, 5);
  Assert.AreEqual(5, FSource.Actors[100].Numbers[acfState]);
  FActors.SetActorState(100, -1);
  FActors.SetActorState(100, 20);
  Assert.AreEqual(5, FSource.Actors[100].Numbers[acfState]);
  FActors.SetActorState(100, 19);
  Assert.AreEqual(19, FSource.Actors[100].Numbers[acfState]);
end;

procedure TTestScriptHostActors.DovrebbeDireSeUnAttoreEValido;
begin
  Assert.IsTrue(FActors.IsValidActor(100));
  Assert.IsTrue(FActors.IsValidActor(0));
  Assert.IsFalse(FActors.IsValidActor(555));
  Assert.IsFalse(FActors.IsValidActor(SCRIPT_INVALID_ID));
end;

procedure TTestScriptHostActors.DovrebbeSuonareDaUnAttoreOSenzaOrigine;
begin
  FActors.ActorPlaySound(100, 'dspistol');
  FActors.PlaySound('dsshotgn');
  Assert.AreEqual('A(100,dspistol)G(dsshotgn)', FSource.Calls);
end;

procedure TTestScriptHostActors.DovrebbeGenerareUnAttoreSoloPerUnTipoValido;
var
  LKey: Cardinal;
begin
  Assert.AreEqual(Cardinal(SCRIPT_INVALID_ID), FActors.SpawnActorType(1, 2, 3, -1));
  Assert.AreEqual(Cardinal(SCRIPT_INVALID_ID), FActors.SpawnActorType(1, 2, 3, 10));
  Assert.AreEqual('', FSource.Calls);
  LKey := FActors.SpawnActorType(1, 2, 3, 9);
  Assert.AreEqual(Cardinal(901), LKey);
  Assert.AreEqual('N(1,2,3,9)', FSource.Calls);
  Assert.IsTrue(FActors.IsValidActor(LKey));
end;

procedure TTestScriptHostActors.DovrebbeGenerareUnAttoreDalNumeroDiEditorEDalNome;
begin
  Assert.AreEqual(Cardinal(901), FActors.SpawnActorEditorNumber(1, 2, 3, 3001));
  Assert.AreEqual(Cardinal(902), FActors.SpawnActorName(4, 5, 6, 'IMP'));
  // a number of editor or a name that is no type, or a type outside of the list, give no actor
  Assert.AreEqual(Cardinal(SCRIPT_INVALID_ID), FActors.SpawnActorEditorNumber(1, 2, 3, 1));
  Assert.AreEqual(Cardinal(SCRIPT_INVALID_ID), FActors.SpawnActorName(1, 2, 3, 'NOBODY'));
  Assert.AreEqual(Cardinal(SCRIPT_INVALID_ID), FActors.SpawnActorName(1, 2, 3, 'HUGE'));
  Assert.AreEqual('N(1,2,3,4)N(4,5,6,3)', FSource.Calls);
end;

procedure TTestScriptHostActors.DovrebbeRimuovereUnAttore;
begin
  FActors.RemoveActor(102);
  Assert.IsFalse(FActors.IsValidActor(102));
  FActors.RemoveActor(555);
  Assert.AreEqual('R(102)R(555)', FSource.Calls);
end;

procedure TTestScriptHostActors.DovrebbeDareLeConversioniDaNomeENumeroDiEditorSenzaControllo;
begin
  Assert.AreEqual(3, FActors.ActorTypeFromName('IMP'));
  Assert.AreEqual(-1, FActors.ActorTypeFromName('NOBODY'));
  Assert.AreEqual(50, FActors.ActorTypeFromName('HUGE'));
  Assert.AreEqual(4, FActors.ActorTypeFromEditorNumber(3001));
  Assert.AreEqual(-1, FActors.ActorTypeFromEditorNumber(1));
end;

procedure TTestScriptHostActors.DovrebbeDareFalsoPerLaVistaSeUnDeiDueAttoriNonCeSenzaChiederloAlMotore;
begin
  // the old code checked the first actor twice and the engine crashed with a second one that is not there
  Assert.IsFalse(FActors.CheckActorSight(100, 555));
  Assert.IsFalse(FActors.CheckActorSight(555, 100));
  Assert.IsFalse(FActors.CheckActorSight(SCRIPT_INVALID_ID, SCRIPT_INVALID_ID));
  Assert.AreEqual('', FSource.Calls);
end;

procedure TTestScriptHostActors.DovrebbeChiederealMotoreLaVistaFraDueAttori;
begin
  Assert.IsTrue(FActors.CheckActorSight(100, 101));
  FSource.SightAnswer := False;
  Assert.IsFalse(FActors.CheckActorSight(0, 100));
  Assert.AreEqual('S(100,101)S(0,100)', FSource.Calls);
end;

procedure TTestScriptHostActors.DovrebbeDareLeListeDiAttoriSenzaDoppioni;
var
  LKeys: TArray<Cardinal>;
begin
  FSource.Selections[acsAll] := [100, 101, 102, 101, 100];
  LKeys := FActors.AllActors;
  // looking for a key that is already there moves it to the front (the order scripts have always got)
  Assert.AreEqual(3, Integer(Length(LKeys)));
  Assert.AreEqual(Cardinal(100), LKeys[0]);
  Assert.AreEqual(Cardinal(101), LKeys[1]);
  Assert.AreEqual(Cardinal(102), LKeys[2]);
  FSource.Selections[acsMissiles] := [];
  Assert.AreEqual(0, Integer(Length(FActors.AllMissiles)));
end;

procedure TTestScriptHostActors.DovrebbeChiedereAlMotoreLaSelezioneGiusta;
begin
  FActors.AllActors;
  FActors.AllMonstersAlive;
  FActors.AllMonstersDead;
  FActors.AllMonsters;
  FActors.AllMissiles;
  FActors.AllAtSector(4);
  FActors.AllAtSectorTag(5);
  FActors.AllEditorNumber(3001);
  FActors.AllType(3);
  Assert.AreEqual('C(0,0)C(1,0)C(2,0)C(3,0)C(4,0)C(6,4)C(7,5)C(5,3001)C(8,3)', FSource.Calls);
end;

procedure TTestScriptHostActors.DovrebbeDareErroreSeLaSorgenteIlContestoOIGiocatoriSonoNil;
var
  LPlayers: IScriptPlayers;
begin
  LPlayers := TScriptHostFactory.CreatePlayers(TFakePlayerSource.Create, sgDoom);
  Assert.WillRaise(
    procedure
    begin
      TScriptHostFactory.CreateActors(nil, FContextRef, LPlayers, sgDoom);
    end,
    EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TScriptHostFactory.CreateActors(FSourceRef, nil, LPlayers, sgDoom);
    end,
    EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TScriptHostFactory.CreateActors(FSourceRef, FContextRef, nil, sgDoom);
    end,
    EArgumentNilException);
end;

function TTestScriptHostActors.RunScript(const AText: string; const AFields: Integer;
  out AValues: TArray<string>): Boolean;
var
  LList: TScriptFunctionList;
  LListRef: IScriptFunctionTable;
  LTable: IScriptFunctionTable;
  LCompiler: TPSPascalCompiler;
  LExec: TPSExec;
  LBytes: TbtString;
  LIndex: Integer;
  LVariable: PIFVariant;
begin
  LList := TScriptFunctionList.Create('PS_GAME');
  LListRef := LList;
  LTable := TActorsWithoutClassResults.Create(LListRef);
  FActors.Describe(LTable);
  LCompiler := TPSPascalCompiler.Create(PRTabArray(@DefaultLookupTable), DEFAULT_KEYWORD_COUNT);
  LExec := TPSExec.Create;
  try
    GUsedList := LList;
    LCompiler.OnUses := OnUsesActorList;
    Result := LCompiler.Compile(TbtString(AText));
    if not Result then
      Exit;
    LCompiler.GetOutput(LBytes);
    LList.RegisterExecutor(LExec);
    Result := LExec.LoadData(LBytes) and LExec.RunScript;
    SetLength(AValues, AFields);
    for LIndex := 0 to AFields - 1 do
    begin
      LVariable := LExec.GetVarNo(LIndex);
      case LVariable.FType.BaseType of
        btString, btUnicodeString:
          AValues[LIndex] := string(PSGetString(@PPSVariantData(LVariable).Data, LVariable.FType));
      else
        AValues[LIndex] := System.SysUtils.IntToStr(PSGetInt(@PPSVariantData(LVariable).Data, LVariable.FType));
      end;
    end;
  finally
    LExec.Free;
    LCompiler.Free;
    LListRef := nil;
    LTable := nil;
    LList.Free;
  end;
end;

procedure TTestScriptHostActors.DovrebbeChiamareLeFunzioniDaUnoScriptVero;
const
  SCRIPT_TEXT =
    'var me, x, h, tg, dist, pl, rip: Integer; nm: string; sp: LongWord; f: Boolean;'#13#10 +
    'begin'#13#10 +
    '  me := Actor;'#13#10 +
    '  x := GetActorX(0);'#13#10 +
    '  SetActorX(100, 1234);'#13#10 +
    '  SetActorHealth(0, 55);'#13#10 +
    '  h := GetActorHealth(101);'#13#10 +
    '  SetActorTarget(101, 100);'#13#10 +
    '  tg := GetActorTarget(101);'#13#10 +
    '  dist := GetActorDistanceXY(100, 101);'#13#10 +
    '  pl := GetActorPlayer(100);'#13#10 +
    '  nm := GetActorName(100);'#13#10 +
    '  rip := Length(GetActorRipSound(100));'#13#10 +
    '  SetActorFlag(100, 9);'#13#10 +
    '  f := CheckActorFlag(100, 9);'#13#10 +
    '  SetActorState(101, 12);'#13#10 +
    '  SetActorState(101, 99);'#13#10 +
    '  SetActorState(101, -3);'#13#10 +
    '  sp := SpawnActorType(1, 2, 3, 4);'#13#10 +
    '  RemoveActor(102);'#13#10 +
    '  ActorPlaySound(100, ''x'');'#13#10 +
    'end.';
var
  LValues: TArray<string>;
begin
  Assert.IsTrue(RunScript(SCRIPT_TEXT, 10, LValues), 'compile, load and run');
  Assert.AreEqual('101', LValues[0]);
  Assert.AreEqual('4000', LValues[1]);
  Assert.AreEqual('55', LValues[2]);
  Assert.AreEqual('100', LValues[3]);
  Assert.AreEqual('5766', LValues[4]);
  Assert.AreEqual('1', LValues[5]);
  Assert.AreEqual(1234, FSource.Actors[100].Numbers[acfX]);
  Assert.AreEqual(55, FSource.Actors[101].Numbers[acfHealth]);
  Assert.AreEqual(12, FSource.Actors[101].Numbers[acfState]);
  Assert.IsTrue(FSource.Actors[100].Flags.Contains(9));
  Assert.IsFalse(FSource.Actors.ContainsKey(102));
  Assert.AreEqual('N(1,2,3,4)R(102)A(100,x)', FSource.Calls);
end;

procedure TTestScriptHostActors.DovrebbeUsareIlContestoDaUnoScriptVeroPiuVolte;
const
  SCRIPT_TEXT =
    'var me, mine, other: Integer;'#13#10 +
    'begin'#13#10 +
    '  me := Actor;'#13#10 +
    '  mine := GetActorX(0);'#13#10 +
    '  other := GetActorX(100);'#13#10 +
    'end.';
var
  LValues: TArray<string>;
begin
  // the implicit actor is the one of the context each time the script runs: first the imp
  Assert.IsTrue(RunScript(SCRIPT_TEXT, 3, LValues));
  Assert.AreEqual('101', LValues[0]);
  Assert.AreEqual('4000', LValues[1]);
  Assert.AreEqual('1000', LValues[2]);
  // then the player (the context and the key 0 move together, as the engine does)
  FContext.Key := 100;
  FSource.Current := 100;
  Assert.IsTrue(RunScript(SCRIPT_TEXT, 3, LValues));
  Assert.AreEqual('100', LValues[0]);
  Assert.AreEqual('1000', LValues[1]);
  // and with no actor
  FContext.Key := SCRIPT_INVALID_ID;
  FSource.Current := SCRIPT_INVALID_ID;
  Assert.IsTrue(RunScript(SCRIPT_TEXT, 3, LValues));
  Assert.AreEqual('2147483647', LValues[0]);
  Assert.AreEqual('0', LValues[1]);
  Assert.AreEqual('1000', LValues[2]);
end;

{ TTestScriptHostActorKeyList }

procedure TTestScriptHostActorKeyList.Setup;
begin
  FList := TScriptActorKeyList.Create;
end;

procedure TTestScriptHostActorKeyList.TearDown;
begin
  FList.Free;
end;

procedure TTestScriptHostActorKeyList.DovrebbeAggiungereUnaChiaveUnaVolta;
begin
  FList.Add(5);
  FList.Add(6);
  FList.Add(5);
  Assert.AreEqual(2, FList.Count);
  Assert.IsTrue(FList.Exists(6));
  Assert.IsFalse(FList.Exists(7));
end;

procedure TTestScriptHostActorKeyList.DovrebbePortareInTestaLaChiaveCercata;
begin
  FList.Add(1);
  FList.Add(2);
  FList.Add(3);
  FList.Add(4);
  Assert.IsTrue(FList.Exists(3));
  // a swap with the first key, not a rotation
  Assert.AreEqual(Cardinal(3), FList[0]);
  Assert.AreEqual(Cardinal(2), FList[1]);
  Assert.AreEqual(Cardinal(1), FList[2]);
  Assert.AreEqual(Cardinal(4), FList[3]);
  // adding a key that is there looks for it: the same swap
  FList.Add(4);
  Assert.AreEqual(Cardinal(4), FList[0]);
  Assert.AreEqual(Cardinal(3), FList[3]);
end;

procedure TTestScriptHostActorKeyList.DovrebbeLasciareInTestaLaPrimaChiaveCercata;
begin
  FList.Add(1);
  FList.Add(2);
  Assert.IsTrue(FList.Exists(1));
  Assert.AreEqual(Cardinal(1), FList[0]);
  Assert.AreEqual(Cardinal(2), FList[1]);
end;

procedure TTestScriptHostActorKeyList.DovrebbeDareLaChiaveNonValidaFuoriDallaLista;
begin
  FList.Add(1);
  Assert.AreEqual(Cardinal(SCRIPT_INVALID_ID), FList[-1]);
  Assert.AreEqual(Cardinal(SCRIPT_INVALID_ID), FList[1]);
  Assert.AreEqual(Cardinal(1), FList[0]);
end;

procedure TTestScriptHostActorKeyList.DovrebbeIgnorareLaScritturaFuoriDallaLista;
begin
  FList.Add(1);
  FList[0] := 9;
  FList[3] := 10;
  FList[-1] := 11;
  Assert.AreEqual(1, FList.Count);
  Assert.AreEqual(Cardinal(9), FList[0]);
end;

procedure TTestScriptHostActorKeyList.DovrebbeTogliereUnaChiaveLasciandoLUltimaAlSuoPosto;
begin
  FList.Add(1);
  FList.Add(2);
  FList.Add(3);
  Assert.IsTrue(FList.Delete(1));
  Assert.AreEqual(2, FList.Count);
  Assert.AreEqual(Cardinal(3), FList[0]);
  Assert.AreEqual(Cardinal(2), FList[1]);
end;

procedure TTestScriptHostActorKeyList.DovrebbeDareFalsoSeTogliereUnaChiaveCheNonCe;
begin
  Assert.IsFalse(FList.Delete(1));
  FList.Add(2);
  Assert.IsFalse(FList.Delete(1));
  Assert.AreEqual(1, FList.Count);
  FList.AllowDuplicates := True;
  Assert.IsFalse(FList.Delete(1));
end;

procedure TTestScriptHostActorKeyList.DovrebbeAmmettereDoppioniSeRichiesto;
begin
  FList.AllowDuplicates := True;
  FList.Add(1);
  FList.Add(1);
  FList.Add(2);
  Assert.AreEqual(3, FList.Count);
  Assert.IsTrue(FList.AllowDuplicates);
end;

procedure TTestScriptHostActorKeyList.DovrebbeTogliereTutteLeCopieDiUnaChiaveConDoppioni;
begin
  FList.AllowDuplicates := True;
  FList.Add(1);
  FList.Add(2);
  FList.Add(1);
  FList.Add(3);
  Assert.IsTrue(FList.Delete(1));
  Assert.AreEqual(2, FList.Count);
  Assert.AreEqual(Cardinal(2), FList[0]);
  Assert.AreEqual(Cardinal(3), FList[1]);
end;

procedure TTestScriptHostActorKeyList.DovrebbeTogliereIDoppioniSpegnendoLaProprieta;
begin
  // the old setter emptied the list (its loop ran over a count that it had just set to zero)
  FList.AllowDuplicates := True;
  FList.Add(1);
  FList.Add(2);
  FList.Add(1);
  FList.AllowDuplicates := False;
  Assert.AreEqual(2, FList.Count);
  Assert.AreEqual(Cardinal(1), FList[0]);
  Assert.AreEqual(Cardinal(2), FList[1]);
end;

procedure TTestScriptHostActorKeyList.DovrebbeSvuotareLaLista;
begin
  FList.Add(1);
  FList.Clear;
  Assert.AreEqual(0, FList.Count);
  Assert.AreEqual(0, Integer(Length(FList.ToArray)));
  FList.Add(1);
  Assert.AreEqual(1, FList.Count);
end;

procedure TTestScriptHostActorKeyList.DovrebbeCrescereOltreLaCapacitaIniziale;
var
  LIndex: Integer;
  LKeys: TArray<Cardinal>;
begin
  for LIndex := 1 to 500 do
    FList.Add(LIndex);
  Assert.AreEqual(500, FList.Count);
  LKeys := FList.ToArray;
  Assert.AreEqual(500, Integer(Length(LKeys)));
  Assert.AreEqual(Cardinal(1), LKeys[0]);
  Assert.AreEqual(Cardinal(500), LKeys[499]);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestScriptHostActors);
  TDUnitX.RegisterTestFixture(TTestScriptHostActorKeyList);

end.
