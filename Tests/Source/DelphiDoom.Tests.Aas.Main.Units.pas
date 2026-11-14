{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the AAS library - the links of the entities, the table  }
{  of the entities, the string indexes and the AAS system                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Aas.Main.Units;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, DUnitX.TestFramework, DelphiDoom.MathCore.Types,
  DelphiDoom.BotAi.Import.Intf, DelphiDoom.Aas.Types, DelphiDoom.Aas.Intf, DelphiDoom.Aas.Route.Types, DelphiDoom.Aas.Move.Types, DelphiDoom.Aas.Move.Intf,
  DelphiDoom.Aas.Bsp.Intf, DelphiDoom.Aas.Links, DelphiDoom.Aas.Main.Intf, DelphiDoom.Aas.Main.System, DelphiDoom.Aas.Main.Factory,
  DelphiDoom.Aas.Entity.Table, DelphiDoom.Aas.Entity.Types, DelphiDoom.Aas.Reach.Intf, DelphiDoom.Tests.Aas.Support;

type
  /// <summary>A world of three areas: area 1 where x is above 0, area 2 where x and y are below 0 and above</summary>
  [TestFixture]
  [Category('Aas')]
  TTestAasLinks = class
  strict private
    FImport: TFakeImport;
    FImportIntf: IBotImport;
    FFile: IAasFile;
    function Links(const AMaxLinks: Integer; const ADeveloper: Boolean = True): TAasEntityLinks;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeCollegareUnaScatolaATutteLeAreeCheTocca;
    [Test]
    procedure DovrebbeDareLaListaConLUltimaAreaTrovataPerPrima;
    [Test]
    procedure DovrebbeRendereLiberiITuttiIlinkDopoIlDistacco;
    [Test]
    procedure DovrebbeNonCollegareDueVolteLaStessaEntitaAllaStessaArea;
    [Test]
    procedure DovrebbeStaccareUnaEntitaDalMezzoDellaListaDiUnArea;
    [Test]
    procedure DovrebbeFermarsiQuandoIlHeapEPieno;
    [Test]
    procedure DovrebbeTacereSulHeapPienoSenzaModoSviluppatore;
    [Test]
    procedure DovrebbeAllargareLaScatolaConQuellaDelCliente;
    [Test]
    procedure DovrebbeRifiutareUnLinkFuoriDalHeap;
    [Test]
    procedure DovrebbeRifiutareUnAreaFuoriDalFile;
    [Test]
    procedure DovrebbeFareUnHeapVuotoConUnNumeroNegativo;
    [Test]
    procedure DovrebbeDareNessunLinkPerUnNodoFuoriDalFile;
  end;

  [TestFixture]
  [Category('Aas')]
  TTestAasStringIndexes = class
  strict private
    FImport: TFakeImport;
    FImportIntf: IBotImport;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeAvvisareSeGliIndiciNonSonoPronti;
    [Test]
    procedure DovrebbeDareIlNomeDelModelloEL_IndiceSenzaMaiuscole;
    [Test]
    procedure DovrebbeRifiutareUnIndiceFuoriIntervallo;
    [Test]
    procedure DovrebbeAvvisareSoloPerUnIndiceNonUsatoDiversoDaZero;
    [Test]
    procedure DovrebbeDareZeroPerUnModelloCheNonCe;
  end;

  [TestFixture]
  [Category('Aas')]
  TTestAasEntityTable = class
  strict private
    FImport: TFakeImport;
    FImportIntf: IBotImport;
    FFile: IAasFile;
    FLinks: TAasEntityLinks;
    FState: IAasFrameState;
    FStateObject: TObject;
    FTable: TAasEntityTable;
    FModels: IAasBspModels;
    function MakeState(const AOrigin: TVec3): TBotEntityState;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeRifiutareUnAggiornamentoSenzaFile;
    [Test]
    procedure DovrebbeCollegareLEntitaAlPrimoFotogramma;
    [Test]
    procedure DovrebbeRicollegareSoloSeQualcosaCambia;
    [Test]
    procedure DovrebbeSpostareLEntitaSeLOrigineCambia;
    [Test]
    procedure DovrebbeScollegareConUnoStatoNullo;
    [Test]
    procedure DovrebbeNonCollegareIlModelloDelMondo;
    [Test]
    procedure DovrebbePrendereLeDimensioniDelModelloBsp;
    [Test]
    procedure DovrebbeSeguireLeDimensioniDiUnaScatola;
    [Test]
    procedure DovrebbeRifiutareUnNumeroDiEntitaFuoriTabella;
    [Test]
    procedure DovrebbeDareLeInformazioniEIlTempoDiAggiornamento;
    [Test]
    procedure DovrebbeDareZeroConUnMessaggioSeNonEInizializzata;
    [Test]
    procedure DovrebbeDareZeroConUnMessaggioFuoriTabella;
    [Test]
    procedure DovrebbeInvalidareESciogliereLeEntitaNonAggiornate;
    [Test]
    procedure DovrebbeTrovareLaProssimaEntitaValida;
    [Test]
    procedure DovrebbeTrovareLEntitaPiuVicinaConIlModello;
    [Test]
    procedure DovrebbeTrovareLOrigineDiUnMover;
    [Test]
    procedure DovrebbeDareDatiBspDellaEntita;
    [Test]
    procedure DovrebbeDareLAreaMigliorePerLEntita;
    [Test]
    procedure DovrebbeRimettereAZeroIlegami;
    [Test]
    procedure DovrebbeDareTipoModelloEDimensioni;
  end;

  [TestFixture]
  [Category('Aas')]
  TTestAasSystemFactory = class
  public
    [Test]
    procedure DovrebbeInizializzareUnaMappaConLeClassiVere;
  end;

  [TestFixture]
  [Category('Aas')]
  TTestAasSystem = class
  strict private
    FImport: TFakeImport;
    FImportIntf: IBotImport;
    FSystem: TAasSystem;
    FSystemIntf: IInterface;
    FReader: IAasReader;
    FSteps: TObject;
    FLibVarsIntf: IBotLibVars;
    FVars: TObject;
    procedure MakeSystem(const AReachabilityRounds: Integer);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeLeggereIlNumeroDiEntitaDalleVariabili;
    [Test]
    procedure DovrebbeCaricareLaMappaEPartireDalleImpostazioni;
    [Test]
    procedure DovrebbeDareIlCodiceDiErroreSeIlFileNonSiCarica;
    [Test]
    procedure DovrebbeNonFareNullaSenzaNomeDiMappa;
    [Test]
    procedure DovrebbeFinireLInizializzazioneInPiuFotogrammi;
    [Test]
    procedure DovrebbeSegnareIlFileDaScrivereSeLeRaggiungibilitaSonoCalcolate;
    [Test]
    procedure DovrebbeProiettareUnPuntoSuUnaRetta;
    [Test]
    procedure DovrebbeChiudereTuttoNelloShutdown;
    [Test]
    procedure DovrebbeLiberareIlRoutingDellaMappaVecchia;
    [Test]
    procedure DovrebbeOttimizzareSeLeVariabiliLoChiedono;
  end;

implementation

uses
  DelphiDoom.BotAi.Types, DelphiDoom.Tests.Aas.Sample, DelphiDoom.Aas.AasFile, DelphiDoom.Aas.Main.StringIndexes;

function World: TAasFileData;
begin
  FillChar(Result, SizeOf(Result), 0);
  SetLength(Result.Planes, 3);
  Result.Planes[1].Normal := Vec(1, 0, 0);
  Result.Planes[1].Dist := 0;
  Result.Planes[1].PlaneType := 0;
  Result.Planes[2].Normal := Vec(0, 1, 0);
  Result.Planes[2].Dist := 0;
  Result.Planes[2].PlaneType := 1;
  SetLength(Result.Nodes, 3);
  // node 1: area 1 in front (x above 0), node 2 behind
  Result.Nodes[1].PlaneNum := 1;
  Result.Nodes[1].Children[0] := -1;
  Result.Nodes[1].Children[1] := 2;
  // node 2: area 2 in front (y above 0), area 3 behind
  Result.Nodes[2].PlaneNum := 2;
  Result.Nodes[2].Children[0] := -2;
  Result.Nodes[2].Children[1] := -3;
  SetLength(Result.Areas, 4);
  SetLength(Result.AreaSettings, 4);
end;

{ TTestAasLinks }

procedure TTestAasLinks.Setup;
begin
  FImport := TFakeImport.Create;
  FImportIntf := FImport;
  FFile := TAasFile.Create(World) as IAasFile;
end;

procedure TTestAasLinks.TearDown;
begin
  FFile := nil;
  FImportIntf := nil;
end;

function TTestAasLinks.Links(const AMaxLinks: Integer; const ADeveloper: Boolean): TAasEntityLinks;
begin
  Result := TAasEntityLinks.Create(FFile, FImportIntf, AMaxLinks, ADeveloper);
end;

procedure TTestAasLinks.DovrebbeCollegareUnaScatolaATutteLeAreeCheTocca;
var
  LLinks: TAasEntityLinks;
  LHead, LCount: Integer;
begin
  LLinks := Links(10);
  try
    LHead := LLinks.LinkEntity(Vec(-10, -10, 0), Vec(10, 10, 10), 7);
    LCount := 0;
    while LHead <> AAS_NO_LINK do
    begin
      Assert.AreEqual(7, LLinks.EntNum(LHead));
      Inc(LCount);
      LHead := LLinks.NextArea(LHead);
    end;
    Assert.AreEqual(3, LCount);
    Assert.AreEqual(7, LLinks.FreeCount);
  finally
    LLinks.Free;
  end;
end;

procedure TTestAasLinks.DovrebbeDareLaListaConLUltimaAreaTrovataPerPrima;
var
  LLinks: TAasEntityLinks;
  LHead: Integer;
begin
  LLinks := Links(10);
  try
    LHead := LLinks.LinkEntity(Vec(-10, -10, 0), Vec(10, 10, 10), 1);
    Assert.AreEqual(1, LLinks.AreaNum(LHead));
    LHead := LLinks.NextArea(LHead);
    Assert.AreEqual(2, LLinks.AreaNum(LHead));
    LHead := LLinks.NextArea(LHead);
    Assert.AreEqual(3, LLinks.AreaNum(LHead));
    Assert.AreEqual(AAS_NO_LINK, LLinks.NextArea(LHead));
  finally
    LLinks.Free;
  end;
end;

procedure TTestAasLinks.DovrebbeRendereLiberiITuttiIlinkDopoIlDistacco;
var
  LLinks: TAasEntityLinks;
  LHead: Integer;
begin
  LLinks := Links(10);
  try
    LHead := LLinks.LinkEntity(Vec(-10, -10, 0), Vec(10, 10, 10), 1);
    Assert.AreNotEqual(AAS_NO_LINK, LLinks.AreaHead(1));
    LLinks.Unlink(LHead);
    Assert.AreEqual(10, LLinks.FreeCount);
    Assert.AreEqual(AAS_NO_LINK, LLinks.AreaHead(1));
    Assert.AreEqual(AAS_NO_LINK, LLinks.AreaHead(2));
    Assert.AreEqual(AAS_NO_LINK, LLinks.AreaHead(3));
    // a second round on the same heap works
    LHead := LLinks.LinkEntity(Vec(1, 1, 0), Vec(2, 2, 10), 2);
    Assert.AreEqual(1, LLinks.AreaNum(LHead));
    Assert.AreEqual(AAS_NO_LINK, LLinks.NextArea(LHead));
  finally
    LLinks.Free;
  end;
end;

procedure TTestAasLinks.DovrebbeNonCollegareDueVolteLaStessaEntitaAllaStessaArea;
var
  LLinks: TAasEntityLinks;
  LFirst, LSecond: Integer;
begin
  LLinks := Links(10);
  try
    LFirst := LLinks.LinkEntity(Vec(1, 1, 0), Vec(2, 2, 10), 5);
    Assert.AreNotEqual(AAS_NO_LINK, LFirst);
    // the same entity again: already in area 1
    LSecond := LLinks.LinkEntity(Vec(1, 1, 0), Vec(2, 2, 10), 5);
    Assert.AreEqual(AAS_NO_LINK, LSecond);
    Assert.AreEqual(9, LLinks.FreeCount);
    // another entity is linked
    LSecond := LLinks.LinkEntity(Vec(1, 1, 0), Vec(2, 2, 10), 6);
    Assert.AreNotEqual(AAS_NO_LINK, LSecond);
    Assert.AreEqual(8, LLinks.FreeCount);
  finally
    LLinks.Free;
  end;
end;

procedure TTestAasLinks.DovrebbeStaccareUnaEntitaDalMezzoDellaListaDiUnArea;
var
  LLinks: TAasEntityLinks;
  LFirst, LSecond, LThird: Integer;
begin
  LLinks := Links(10);
  try
    LFirst := LLinks.LinkEntity(Vec(1, 1, 0), Vec(2, 2, 10), 1);
    LSecond := LLinks.LinkEntity(Vec(1, 1, 0), Vec(2, 2, 10), 2);
    LThird := LLinks.LinkEntity(Vec(1, 1, 0), Vec(2, 2, 10), 3);
    // the list of area 1: the last one first (3, 2, 1)
    Assert.AreEqual(LThird, LLinks.AreaHead(1));
    Assert.AreEqual(LSecond, LLinks.NextEnt(LThird));
    LLinks.Unlink(LSecond);
    Assert.AreEqual(LThird, LLinks.AreaHead(1));
    Assert.AreEqual(LFirst, LLinks.NextEnt(LThird));
    // the head
    LLinks.Unlink(LThird);
    Assert.AreEqual(LFirst, LLinks.AreaHead(1));
    LLinks.Unlink(LFirst);
    Assert.AreEqual(AAS_NO_LINK, LLinks.AreaHead(1));
    Assert.AreEqual(10, LLinks.FreeCount);
  finally
    LLinks.Free;
  end;
end;

procedure TTestAasLinks.DovrebbeFermarsiQuandoIlHeapEPieno;
var
  LLinks: TAasEntityLinks;
  LHead, LCount: Integer;
begin
  LLinks := Links(2);
  try
    LHead := LLinks.LinkEntity(Vec(-10, -10, 0), Vec(10, 10, 10), 1);
    LCount := 0;
    while LHead <> AAS_NO_LINK do
    begin
      Inc(LCount);
      LHead := LLinks.NextArea(LHead);
    end;
    Assert.AreEqual(2, LCount);
    Assert.AreEqual(0, LLinks.FreeCount);
    Assert.AreEqual(1, FImport.Count);
    Assert.AreEqual(PRT_FATAL, FImport.Level(0));
  finally
    LLinks.Free;
  end;
end;

procedure TTestAasLinks.DovrebbeTacereSulHeapPienoSenzaModoSviluppatore;
var
  LLinks: TAasEntityLinks;
begin
  LLinks := Links(1, False);
  try
    LLinks.LinkEntity(Vec(-10, -10, 0), Vec(10, 10, 10), 1);
    Assert.AreEqual(0, FImport.Count);
  finally
    LLinks.Free;
  end;
end;

procedure TTestAasLinks.DovrebbeAllargareLaScatolaConQuellaDelCliente;
var
  LLinks: TAasEntityLinks;
  LHead: Integer;
begin
  LLinks := Links(10);
  try
    // the box of a standing client is 15 units wide: a point at x = -10 reaches area 1 once enlarged by 15
    LHead := LLinks.LinkEntityClientBBox(Vec(-10, 5, 0), Vec(-10, 5, 0), 4, PRESENCE_NORMAL);
    Assert.AreNotEqual(AAS_NO_LINK, LHead);
    Assert.AreEqual(1, LLinks.AreaNum(LHead));
    // without the client box a point at x = -10, y = 5 is only in area 2
    LLinks.Unlink(LHead);
    LHead := LLinks.LinkEntity(Vec(-10, 5, 0), Vec(-10, 5, 0), 4);
    Assert.AreEqual(2, LLinks.AreaNum(LHead));
    Assert.AreEqual(AAS_NO_LINK, LLinks.NextArea(LHead));
  finally
    LLinks.Free;
  end;
end;

procedure TTestAasLinks.DovrebbeRifiutareUnLinkFuoriDalHeap;
var
  LLinks: TAasEntityLinks;
  LRaised: Boolean;
begin
  LLinks := Links(3);
  try
    LRaised := False;
    try
      LLinks.NextArea(99);
    except
      on EAasLinkException do
        LRaised := True;
    end;
    Assert.IsTrue(LRaised);
    LRaised := False;
    try
      LLinks.EntNum(-2);
    except
      on EAasLinkException do
        LRaised := True;
    end;
    Assert.IsTrue(LRaised);
  finally
    LLinks.Free;
  end;
end;

procedure TTestAasLinks.DovrebbeRifiutareUnAreaFuoriDalFile;
var
  LLinks: TAasEntityLinks;
  LRaised: Boolean;
begin
  LLinks := Links(3);
  try
    LRaised := False;
    try
      LLinks.AreaHead(40);
    except
      on EAasLinkException do
        LRaised := True;
    end;
    Assert.IsTrue(LRaised);
  finally
    LLinks.Free;
  end;
end;

procedure TTestAasLinks.DovrebbeFareUnHeapVuotoConUnNumeroNegativo;
var
  LLinks: TAasEntityLinks;
begin
  LLinks := Links(-5);
  try
    Assert.AreEqual(0, LLinks.FreeCount);
    Assert.AreEqual(AAS_NO_LINK, LLinks.LinkEntity(Vec(1, 1, 0), Vec(2, 2, 10), 1));
  finally
    LLinks.Free;
  end;
end;

procedure TTestAasLinks.DovrebbeDareNessunLinkPerUnNodoFuoriDalFile;
var
  LData: TAasFileData;
  LLinks: TAasEntityLinks;
begin
  LData := World;
  LData.Nodes[1].Children[0] := 9;
  FFile := TAasFile.Create(LData) as IAasFile;
  LLinks := Links(5);
  try
    Assert.AreEqual(AAS_NO_LINK, LLinks.LinkEntity(Vec(1, 1, 0), Vec(2, 2, 10), 1));
    Assert.AreEqual(PRT_ERROR, FImport.Level(0));
  finally
    LLinks.Free;
  end;
  // an area number outside the table
  LData := World;
  LData.Nodes[1].Children[0] := -40;
  FFile := TAasFile.Create(LData) as IAasFile;
  LLinks := Links(5);
  try
    Assert.AreEqual(AAS_NO_LINK, LLinks.LinkEntity(Vec(1, 1, 0), Vec(2, 2, 10), 1));
  finally
    LLinks.Free;
  end;
end;

{ TTestAasStringIndexes }

procedure TTestAasStringIndexes.Setup;
begin
  FImport := TFakeImport.Create;
  FImportIntf := FImport;
end;

procedure TTestAasStringIndexes.TearDown;
begin
  FImportIntf := nil;
end;

procedure TTestAasStringIndexes.DovrebbeAvvisareSeGliIndiciNonSonoPronti;
var
  LIndexes: TAasStringIndexes;
begin
  LIndexes := TAasStringIndexes.Create(FImportIntf);
  try
    Assert.AreEqual('', string(LIndexes.ModelFromIndex(3)));
    Assert.AreEqual(0, LIndexes.IndexFromModel('models/a.md3'));
    Assert.AreEqual(2, FImport.Count);
    Assert.IsFalse(LIndexes.IsSetup);
  finally
    LIndexes.Free;
  end;
end;

procedure TTestAasStringIndexes.DovrebbeDareIlNomeDelModelloEL_IndiceSenzaMaiuscole;
var
  LIndexes: TAasStringIndexes;
  LStrings: TArray<AnsiString>;
begin
  LIndexes := TAasStringIndexes.Create(FImportIntf);
  try
    SetLength(LStrings, AAS_CS_MODELS + 4);
    LStrings[AAS_CS_MODELS + 2] := 'Models/Weapons/Rocket.md3';
    LIndexes.Update(LStrings);
    Assert.IsTrue(LIndexes.IsSetup);
    Assert.AreEqual('Models/Weapons/Rocket.md3', string(LIndexes.ModelFromIndex(2)));
    Assert.AreEqual(2, LIndexes.IndexFromModel('models/weapons/rocket.MD3'));
  finally
    LIndexes.Free;
  end;
end;

procedure TTestAasStringIndexes.DovrebbeRifiutareUnIndiceFuoriIntervallo;
var
  LIndexes: TAasStringIndexes;
begin
  LIndexes := TAasStringIndexes.Create(FImportIntf);
  try
    LIndexes.Update(nil);
    Assert.AreEqual('', string(LIndexes.ModelFromIndex(-1)));
    Assert.AreEqual('', string(LIndexes.ModelFromIndex(AAS_MAX_MODELS)));
    Assert.AreEqual(2, FImport.Count);
    Assert.AreEqual(PRT_ERROR, FImport.Level(1));
  finally
    LIndexes.Free;
  end;
end;

procedure TTestAasStringIndexes.DovrebbeAvvisareSoloPerUnIndiceNonUsatoDiversoDaZero;
var
  LIndexes: TAasStringIndexes;
begin
  LIndexes := TAasStringIndexes.Create(FImportIntf);
  try
    LIndexes.Update(nil);
    Assert.AreEqual('', string(LIndexes.ModelFromIndex(0)));
    Assert.AreEqual(0, FImport.Count);
    Assert.AreEqual('', string(LIndexes.ModelFromIndex(5)));
    Assert.AreEqual(1, FImport.Count);
  finally
    LIndexes.Free;
  end;
end;

procedure TTestAasStringIndexes.DovrebbeDareZeroPerUnModelloCheNonCe;
var
  LIndexes: TAasStringIndexes;
begin
  LIndexes := TAasStringIndexes.Create(FImportIntf);
  try
    LIndexes.Update(nil);
    Assert.AreEqual(0, LIndexes.IndexFromModel('nothing'));
    Assert.AreEqual(0, FImport.Count);
  finally
    LIndexes.Free;
  end;
end;

{ Fakes of the system }

type
  TFakeState = class(TInterfacedObject, IAasFrameState)
  public
    LoadedFlag, InitializedFlag: Boolean;
    TimeValue: Single;
    Frames: Integer;
    function GetLoaded: Boolean;
    function GetInitialized: Boolean;
    function GetTime: Single;
    function GetNumFrames: Integer;
  end;

  TFakeModels = class(TInterfacedObject, IAasBspModels)
  public
    Text: AnsiString;
    Mins, Maxs: TVec3;
    LastModel: Integer;
    function EntityData: AnsiString;
    function EntityTrace(const AStart: TVec3; const AMins, AMaxs: PVec3; const AEnd: TVec3; const AEntNum,
      AContentMask: Integer): TAasBspTrace;
    function InPVS(const AFirst, ASecond: TVec3): Boolean;
    procedure ModelMinsMaxsOrigin(const AModelNum: Integer; const AAngles: TVec3; out AMins, AMaxs, AOrigin: TVec3);
  end;

  TFakeWorld = class(TInterfacedObject, IAasBspWorld)
  public
    function PointContents(const APoint: TVec3): Integer;
    function Trace(const AStart: TVec3; const AMins, AMaxs: PVec3; const AEnd: TVec3; const APassEnt,
      AContentMask: Integer): TAasBspTrace;
  end;

  TFakeSteps = class(TInterfacedObject, IAasInitSteps)
  public
    Calls: TStringList;
    Rounds: Integer;
    NeedsSave: Boolean;
    constructor Create(const ARounds: Integer; const ANeedsSave: Boolean);
    destructor Destroy; override;
    procedure InitSettings;
    procedure InitReachability;
    function ContinueInitReachability(const ATime: Single): Boolean;
    procedure InitClustering;
    procedure Optimize;
    procedure InitRouting;
    procedure InitAlternativeRouting;
    function SaveFile: Boolean;
    procedure FreeRouting;
  end;

  TFakeMap = class(TInterfacedObject, IAasMap)
  strict private
    FFile: IAasFile;
    FLinks: TAasEntityLinks;
    FSteps: IAasInitSteps;
  public
    constructor Create(const AFile: IAasFile; const ALinks: TAasEntityLinks; const ASteps: IAasInitSteps);
    destructor Destroy; override;
    function GetFile: IAasFile;
    function GetLinks: TAasEntityLinks;
    function GetSteps: IAasInitSteps;
  end;

  TFakeBuilder = class(TInterfacedObject, IAasMapBuilder)
  strict private
    FImport: IBotImport;
  public
    Steps: TFakeSteps;
    StepsIntf: IAasInitSteps;
    MaxLinks: Integer;
    constructor Create(const AImport: IBotImport; const ARounds: Integer; const ANeedsSave: Boolean);
    function Build(const AFile: IAasFile; const AMaxLinks: Integer; const AEntities: IAasBspEntities): IAasMap;
  end;

  TFakeReader = class(TInterfacedObject, IAasReader)
  public
    ErrorCode: Integer;
    LastName: AnsiString;
    function Load(const AFileName: AnsiString; out AFile: IAasFile): Integer;
    function ParseBytes(const AData: TBytes; const AName: AnsiString; const ABspChecksum: Integer): IAasFile;
  end;

  TFakeVars = class(TInterfacedObject, IBotLibVars)
  public
    Values: TDictionary<string, Single>;
    Checksum: AnsiString;
    constructor Create;
    destructor Destroy; override;
    function GetValue(const AName: AnsiString): Single;
    function GetValueOrCreate(const AName, ADefault: AnsiString): Single;
    function GetStringOrCreate(const AName, ADefault: AnsiString): AnsiString;
  end;

{ TFakeWorld }

function TFakeWorld.PointContents(const APoint: TVec3): Integer;
begin
  Result := 0;
end;

function TFakeWorld.Trace(const AStart: TVec3; const AMins, AMaxs: PVec3; const AEnd: TVec3; const APassEnt,
  AContentMask: Integer): TAasBspTrace;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.Fraction := 1;
  Result.EndPos := AEnd;
end;

{ TFakeState }

function TFakeState.GetLoaded: Boolean;
begin
  Result := LoadedFlag;
end;

function TFakeState.GetInitialized: Boolean;
begin
  Result := InitializedFlag;
end;

function TFakeState.GetTime: Single;
begin
  Result := TimeValue;
end;

function TFakeState.GetNumFrames: Integer;
begin
  Result := Frames;
end;

{ TFakeModels }

function TFakeModels.EntityData: AnsiString;
begin
  Result := Text;
end;

function TFakeModels.EntityTrace(const AStart: TVec3; const AMins, AMaxs: PVec3; const AEnd: TVec3; const AEntNum,
  AContentMask: Integer): TAasBspTrace;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.Fraction := 1;
end;

function TFakeModels.InPVS(const AFirst, ASecond: TVec3): Boolean;
begin
  Result := True;
end;

procedure TFakeModels.ModelMinsMaxsOrigin(const AModelNum: Integer; const AAngles: TVec3;
  out AMins, AMaxs, AOrigin: TVec3);
begin
  LastModel := AModelNum;
  AMins := Mins;
  AMaxs := Maxs;
  AOrigin := Vec(0, 0, 0);
end;

{ TFakeSteps }

constructor TFakeSteps.Create(const ARounds: Integer; const ANeedsSave: Boolean);
begin
  inherited Create;
  Calls := TStringList.Create;
  Rounds := ARounds;
  NeedsSave := ANeedsSave;
end;

destructor TFakeSteps.Destroy;
begin
  Calls.Free;
  inherited Destroy;
end;

procedure TFakeSteps.InitSettings;
begin
  Calls.Add('settings');
end;

procedure TFakeSteps.InitReachability;
begin
  Calls.Add('reach');
end;

function TFakeSteps.ContinueInitReachability(const ATime: Single): Boolean;
begin
  Calls.Add('continue');
  Result := Rounds > 0;
  if Result then
    Dec(Rounds);
end;

procedure TFakeSteps.InitClustering;
begin
  Calls.Add('cluster');
end;

procedure TFakeSteps.Optimize;
begin
  Calls.Add('optimize');
end;

procedure TFakeSteps.InitRouting;
begin
  Calls.Add('routing');
end;

procedure TFakeSteps.InitAlternativeRouting;
begin
  Calls.Add('alternative');
end;

function TFakeSteps.SaveFile: Boolean;
begin
  Result := NeedsSave;
end;

procedure TFakeSteps.FreeRouting;
begin
  Calls.Add('free');
end;

{ TFakeMap }

constructor TFakeMap.Create(const AFile: IAasFile; const ALinks: TAasEntityLinks; const ASteps: IAasInitSteps);
begin
  inherited Create;
  FFile := AFile;
  FLinks := ALinks;
  FSteps := ASteps;
end;

destructor TFakeMap.Destroy;
begin
  FLinks.Free;
  inherited Destroy;
end;

function TFakeMap.GetFile: IAasFile;
begin
  Result := FFile;
end;

function TFakeMap.GetLinks: TAasEntityLinks;
begin
  Result := FLinks;
end;

function TFakeMap.GetSteps: IAasInitSteps;
begin
  Result := FSteps;
end;

{ TFakeBuilder }

constructor TFakeBuilder.Create(const AImport: IBotImport; const ARounds: Integer; const ANeedsSave: Boolean);
begin
  inherited Create;
  FImport := AImport;
  Steps := TFakeSteps.Create(ARounds, ANeedsSave);
  StepsIntf := Steps;
end;

function TFakeBuilder.Build(const AFile: IAasFile; const AMaxLinks: Integer; const AEntities: IAasBspEntities): IAasMap;
begin
  MaxLinks := AMaxLinks;
  Result := TFakeMap.Create(AFile, TAasEntityLinks.Create(AFile, FImport, AMaxLinks, True), StepsIntf);
end;

{ TFakeReader }

function TFakeReader.Load(const AFileName: AnsiString; out AFile: IAasFile): Integer;
begin
  LastName := AFileName;
  AFile := nil;
  Result := ErrorCode;
  if Result = BLERR_NOERROR then
    AFile := TAasFile.Create(World) as IAasFile;
end;

function TFakeReader.ParseBytes(const AData: TBytes; const AName: AnsiString;
  const ABspChecksum: Integer): IAasFile;
begin
  Result := nil;
end;

{ TFakeVars }

constructor TFakeVars.Create;
begin
  inherited Create;
  Values := TDictionary<string, Single>.Create;
end;

destructor TFakeVars.Destroy;
begin
  Values.Free;
  inherited Destroy;
end;

function TFakeVars.GetValue(const AName: AnsiString): Single;
begin
  if not Values.TryGetValue(string(AName), Result) then
    Result := 0;
end;

function TFakeVars.GetValueOrCreate(const AName, ADefault: AnsiString): Single;
begin
  if not Values.TryGetValue(string(AName), Result) then
    Result := StrToFloat(string(ADefault), TFormatSettings.Invariant);
end;

function TFakeVars.GetStringOrCreate(const AName, ADefault: AnsiString): AnsiString;
begin
  if AName = 'sv_mapChecksum' then
    Result := Checksum
  else
    Result := ADefault;
end;

{ TTestAasEntityTable }

procedure TTestAasEntityTable.Setup;
var
  LState: TFakeState;
  LModels: TFakeModels;
begin
  FImport := TFakeImport.Create;
  FImportIntf := FImport;
  FFile := TAasFile.Create(World) as IAasFile;
  FLinks := TAasEntityLinks.Create(FFile, FImportIntf, 20, True);
  LState := TFakeState.Create;
  LState.LoadedFlag := True;
  LState.InitializedFlag := True;
  LState.Frames := 1;
  LState.TimeValue := 10;
  FState := LState;
  FStateObject := LState;
  LModels := TFakeModels.Create;
  LModels.Mins := Vec(-5, -5, -5);
  LModels.Maxs := Vec(5, 5, 5);
  FModels := LModels;
  FTable := TAasEntityTable.Create(FImportIntf, FState, FModels, 8,
    function(const AHead: Integer): Integer
    begin
      if AHead = AAS_NO_LINK then
        Result := 0
      else
        Result := FLinks.AreaNum(AHead);
    end);
  FTable.Links := FLinks;
end;

procedure TTestAasEntityTable.TearDown;
begin
  FTable.Free;
  FLinks.Free;
  FModels := nil;
  FState := nil;
  FFile := nil;
  FImportIntf := nil;
end;

function TTestAasEntityTable.MakeState(const AOrigin: TVec3): TBotEntityState;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.Origin := AOrigin;
  Result.Solid := AAS_SOLID_BBOX;
  Result.Mins := Vec(-1, -1, -1);
  Result.Maxs := Vec(1, 1, 1);
  Result.ModelIndex := 3;
  Result.EntityType := AAS_ET_PLAYER;
end;

procedure TTestAasEntityTable.DovrebbeRifiutareUnAggiornamentoSenzaFile;
var
  LState: TBotEntityState;
begin
  TFakeState(FStateObject).LoadedFlag := False;
  LState := MakeState(Vec(10, 10, 0));
  Assert.AreEqual(AAS_BLERR_NOAASFILE, FTable.UpdateEntity(1, @LState));
  Assert.AreEqual(1, FImport.Count);
end;

procedure TTestAasEntityTable.DovrebbeCollegareLEntitaAlPrimoFotogramma;
var
  LState: TBotEntityState;
begin
  LState := MakeState(Vec(10, 10, 0));
  Assert.AreEqual(BLERR_NOERROR, FTable.UpdateEntity(1, @LState));
  // the box of the client around the entity touches the three areas
  Assert.AreEqual(1, FTable.BestReachableEntityArea(1));
  Assert.AreEqual(17, FLinks.FreeCount);
end;

procedure TTestAasEntityTable.DovrebbeRicollegareSoloSeQualcosaCambia;
var
  LState: TBotEntityState;
  LAfter: Integer;
begin
  LState := MakeState(Vec(10, 10, 0));
  FTable.UpdateEntity(1, @LState);
  LAfter := FLinks.FreeCount;
  // not the first frame and nothing changed: nothing is linked again
  TFakeState(FStateObject).Frames := 5;
  FTable.UpdateEntity(1, @LState);
  Assert.AreEqual(LAfter, FLinks.FreeCount);
  Assert.AreEqual(Double(10), Double(FTable.EntityInfo(1).LocalTime), 0.0);
end;

procedure TTestAasEntityTable.DovrebbeSpostareLEntitaSeLOrigineCambia;
var
  LState: TBotEntityState;
begin
  TFakeState(FStateObject).Frames := 5;
  LState := MakeState(Vec(10, 10, 0));
  FTable.UpdateEntity(1, @LState);
  Assert.AreEqual(1, FTable.BestReachableEntityArea(1));
  LState.Origin := Vec(-40, 40, 0);
  FTable.UpdateEntity(1, @LState);
  Assert.AreEqual(2, FTable.BestReachableEntityArea(1));
  Assert.AreEqual(Double(-40), Double(FTable.EntityOrigin(1)[0]), 0.0);
  Assert.AreEqual(Double(10), Double(FTable.EntityInfo(1).LastVisOrigin[0]), 0.0);
end;

procedure TTestAasEntityTable.DovrebbeScollegareConUnoStatoNullo;
var
  LState: TBotEntityState;
begin
  LState := MakeState(Vec(10, 10, 0));
  FTable.UpdateEntity(1, @LState);
  Assert.AreEqual(BLERR_NOERROR, FTable.UpdateEntity(1, nil));
  Assert.AreEqual(20, FLinks.FreeCount);
  Assert.AreEqual(0, FTable.BestReachableEntityArea(1));
end;

procedure TTestAasEntityTable.DovrebbeNonCollegareIlModelloDelMondo;
var
  LState: TBotEntityState;
  LTable: TAasEntityTable;
begin
  LTable := TAasEntityTable.Create(FImportIntf, FState, FModels, AAS_ENTITYNUM_WORLD + 2,
    function(const AHead: Integer): Integer
    begin
      Result := AHead;
    end);
  try
    LTable.Links := FLinks;
    LState := MakeState(Vec(10, 10, 0));
    LTable.UpdateEntity(AAS_ENTITYNUM_WORLD, @LState);
    Assert.AreEqual(20, FLinks.FreeCount);
    Assert.AreEqual(AAS_NO_LINK, LTable.BestReachableEntityArea(AAS_ENTITYNUM_WORLD));
  finally
    LTable.Free;
  end;
end;

procedure TTestAasEntityTable.DovrebbePrendereLeDimensioniDelModelloBsp;
var
  LState: TBotEntityState;
  LMins, LMaxs: TVec3;
begin
  LState := MakeState(Vec(10, 10, 0));
  LState.Solid := AAS_SOLID_BSP;
  LState.ModelIndex := 7;
  LState.Angles := Vec(0, 90, 0);
  FTable.UpdateEntity(2, @LState);
  FTable.EntitySize(2, LMins, LMaxs);
  Assert.AreEqual(Double(-5), Double(LMins[0]), 0.0);
  Assert.AreEqual(Double(5), Double(LMaxs[2]), 0.0);
  Assert.AreEqual(7, TFakeModels(FModels as TObject).LastModel);
  Assert.AreEqual(Double(90), Double(FTable.EntityInfo(2).Angles[1]), 0.0);
end;

procedure TTestAasEntityTable.DovrebbeSeguireLeDimensioniDiUnaScatola;
var
  LState: TBotEntityState;
  LMins, LMaxs: TVec3;
begin
  TFakeState(FStateObject).Frames := 5;
  LState := MakeState(Vec(10, 10, 0));
  FTable.UpdateEntity(1, @LState);
  LState.Mins := Vec(-30, -30, -30);
  LState.Maxs := Vec(30, 30, 30);
  FTable.UpdateEntity(1, @LState);
  FTable.EntitySize(1, LMins, LMaxs);
  Assert.AreEqual(Double(-30), Double(LMins[1]), 0.0);
  Assert.AreEqual(Double(30), Double(LMaxs[0]), 0.0);
end;

procedure TTestAasEntityTable.DovrebbeRifiutareUnNumeroDiEntitaFuoriTabella;
var
  LState: TBotEntityState;
  LRaised: Boolean;
  LSolid, LModelNum: Integer;
begin
  LState := MakeState(Vec(10, 10, 0));
  LRaised := False;
  try
    FTable.UpdateEntity(8, @LState);
  except
    on EAasEntityException do
      LRaised := True;
  end;
  Assert.IsTrue(LRaised);
  LRaised := False;
  try
    FTable.EntityBspData(-1, LState.Origin, LState.Angles, LState.Mins, LState.Maxs, LSolid, LModelNum);
  except
    on EAasEntityException do
      LRaised := True;
  end;
  Assert.IsTrue(LRaised);
end;

procedure TTestAasEntityTable.DovrebbeDareLeInformazioniEIlTempoDiAggiornamento;
var
  LState: TBotEntityState;
  LInfo: TAasEntityInfo;
begin
  LState := MakeState(Vec(10, 10, 0));
  LState.Event := 4;
  LState.Weapon := 6;
  FTable.UpdateEntity(3, @LState);
  TFakeState(FStateObject).TimeValue := 10.5;
  FTable.UpdateEntity(3, @LState);
  LInfo := FTable.EntityInfo(3);
  Assert.IsTrue(LInfo.Valid);
  Assert.AreEqual(3, LInfo.Number);
  Assert.AreEqual(4, LInfo.Event);
  Assert.AreEqual(6, LInfo.Weapon);
  Assert.AreEqual(AAS_ET_PLAYER, FTable.EntityType(3));
  Assert.AreEqual(3, FTable.EntityModelNum(3));
  Assert.AreEqual(3, FTable.EntityModelIndex(3));
  // the second update after 0.5 seconds
  Assert.AreEqual(Double(0.5), Double(LInfo.UpdateTime), 0.0);
  Assert.AreEqual(8, FTable.Count);
end;

procedure TTestAasEntityTable.DovrebbeDareZeroConUnMessaggioSeNonEInizializzata;
var
  LMins, LMaxs: TVec3;
begin
  TFakeState(FStateObject).InitializedFlag := False;
  Assert.IsFalse(FTable.EntityInfo(1).Valid);
  Assert.AreEqual(0, FTable.EntityType(1));
  Assert.AreEqual(0, FTable.EntityModelNum(1));
  FTable.EntitySize(1, LMins, LMaxs);
  Assert.AreEqual(Double(0), Double(LMins[0]), 0.0);
  Assert.AreEqual(1, FImport.Count);
  Assert.AreEqual(PRT_FATAL, FImport.Level(0));
end;

procedure TTestAasEntityTable.DovrebbeDareZeroConUnMessaggioFuoriTabella;
var
  LMins, LMaxs: TVec3;
begin
  Assert.IsFalse(FTable.EntityInfo(99).Valid);
  Assert.AreEqual(Double(0), Double(FTable.EntityOrigin(-1)[0]), 0.0);
  Assert.AreEqual(0, FTable.EntityModelIndex(99));
  Assert.AreEqual(0, FTable.EntityType(99));
  Assert.AreEqual(0, FTable.EntityModelNum(99));
  FTable.EntitySize(99, LMins, LMaxs);
  Assert.AreEqual(6, FImport.Count);
end;

procedure TTestAasEntityTable.DovrebbeInvalidareESciogliereLeEntitaNonAggiornate;
var
  LState: TBotEntityState;
begin
  LState := MakeState(Vec(10, 10, 0));
  FTable.UpdateEntity(1, @LState);
  FTable.UpdateEntity(2, @LState);
  // a new frame: everything is invalid, then only entity 1 is updated again
  FTable.InvalidateEntities;
  Assert.IsFalse(FTable.EntityInfo(1).Valid);
  TFakeState(FStateObject).Frames := 5;
  FTable.UpdateEntity(1, @LState);
  FTable.UnlinkInvalidEntities;
  Assert.AreEqual(1, FTable.BestReachableEntityArea(1));
  Assert.AreEqual(0, FTable.BestReachableEntityArea(2));
  // the three links of entity 1 are left
  Assert.AreEqual(3, 20 - FLinks.FreeCount);
end;

procedure TTestAasEntityTable.DovrebbeTrovareLaProssimaEntitaValida;
var
  LState: TBotEntityState;
begin
  LState := MakeState(Vec(10, 10, 0));
  FTable.UpdateEntity(2, @LState);
  FTable.UpdateEntity(5, @LState);
  Assert.AreEqual(2, FTable.NextEntity(-7));
  Assert.AreEqual(5, FTable.NextEntity(2));
  Assert.AreEqual(0, FTable.NextEntity(5));
  TFakeState(FStateObject).LoadedFlag := False;
  Assert.AreEqual(0, FTable.NextEntity(0));
end;

procedure TTestAasEntityTable.DovrebbeTrovareLEntitaPiuVicinaConIlModello;
var
  LState: TBotEntityState;
begin
  LState := MakeState(Vec(100, 100, 0));
  FTable.UpdateEntity(1, @LState);
  LState.Origin := Vec(110, 105, 0);
  FTable.UpdateEntity(2, @LState);
  // entity 3 has another model
  LState.ModelIndex := 9;
  LState.Origin := Vec(101, 100, 0);
  FTable.UpdateEntity(3, @LState);
  Assert.AreEqual(1, FTable.NearestEntity(Vec(100, 100, 0), 3));
  Assert.AreEqual(2, FTable.NearestEntity(Vec(112, 105, 0), 3));
  // too far in x: 41 units
  Assert.AreEqual(0, FTable.NearestEntity(Vec(300, 100, 0), 3));
  Assert.AreEqual(3, FTable.NearestEntity(Vec(100, 100, 0), 9));
end;

procedure TTestAasEntityTable.DovrebbeTrovareLOrigineDiUnMover;
var
  LState: TBotEntityState;
  LOrigin: TVec3;
begin
  LState := MakeState(Vec(1, 2, 3));
  LState.EntityType := AAS_ET_MOVER;
  LState.ModelIndex := 11;
  FTable.UpdateEntity(4, @LState);
  Assert.IsTrue(FTable.OriginOfMoverWithModelNum(11, LOrigin));
  Assert.AreEqual(Double(3), Double(LOrigin[2]), 0.0);
  Assert.IsFalse(FTable.OriginOfMoverWithModelNum(12, LOrigin));
  Assert.AreEqual(Double(0), Double(LOrigin[0]), 0.0);
end;

procedure TTestAasEntityTable.DovrebbeDareDatiBspDellaEntita;
var
  LState: TBotEntityState;
  LOrigin, LAngles, LAbsMins, LAbsMaxs: TVec3;
  LSolid, LModelNum: Integer;
begin
  LState := MakeState(Vec(10, 20, 30));
  LState.Solid := AAS_SOLID_BBOX;
  LState.ModelIndex := 4;
  LState.Angles := Vec(1, 2, 3);
  FTable.UpdateEntity(1, @LState);
  FTable.EntityBspData(1, LOrigin, LAngles, LAbsMins, LAbsMaxs, LSolid, LModelNum);
  Assert.AreEqual(Double(20), Double(LOrigin[1]), 0.0);
  Assert.AreEqual(Double(2), Double(LAngles[1]), 0.0);
  Assert.AreEqual(Double(9), Double(LAbsMins[0]), 0.0);
  Assert.AreEqual(Double(31), Double(LAbsMaxs[2]), 0.0);
  Assert.AreEqual(AAS_SOLID_BBOX, LSolid);
  Assert.AreEqual(3, LModelNum);
end;

procedure TTestAasEntityTable.DovrebbeDareLAreaMigliorePerLEntita;
var
  LState: TBotEntityState;
begin
  LState := MakeState(Vec(-40, -40, 0));
  FTable.UpdateEntity(1, @LState);
  Assert.AreEqual(3, FTable.BestReachableEntityArea(1));
end;

procedure TTestAasEntityTable.DovrebbeRimettereAZeroIlegami;
var
  LState: TBotEntityState;
begin
  LState := MakeState(Vec(10, 10, 0));
  FTable.UpdateEntity(1, @LState);
  FTable.ResetEntityLinks;
  Assert.AreEqual(0, FTable.BestReachableEntityArea(1));
end;

procedure TTestAasEntityTable.DovrebbeDareTipoModelloEDimensioni;
var
  LState: TBotEntityState;
  LMins, LMaxs: TVec3;
begin
  LState := MakeState(Vec(10, 10, 0));
  FTable.UpdateEntity(1, @LState);
  FTable.EntitySize(1, LMins, LMaxs);
  Assert.AreEqual(Double(-1), Double(LMins[0]), 0.0);
  Assert.AreEqual(Double(1), Double(LMaxs[1]), 0.0);
end;

{ TTestAasSystemFactory }

procedure TTestAasSystemFactory.DovrebbeInizializzareUnaMappaConLeClassiVere;
var
  LImport: TFakeImport;
  LKeeper: IBotImport;
  LVars: TFakeVars;
  LVarsIntf: IBotLibVars;
  LModels: TFakeModels;
  LModelsIntf: IAasBspModels;
  LWorld: IAasBspWorld;
  LSystem: TAasSystem;
  LBest: IAasBestReachable;
  LFrame: Integer;
begin
  LImport := TFakeImport.Create;
  LKeeper := LImport;
  LVars := TFakeVars.Create;
  LVarsIntf := LVars;
  LVars.Checksum := AnsiString(IntToStr(SAMPLE_CHECKSUM));
  LVars.Values.Add('maxentities', 8);
  LVars.Values.Add('max_aaslinks', 50);
  LModels := TFakeModels.Create;
  LModels.Text := '{ "classname" "worldspawn" }';
  LModelsIntf := LModels;
  LWorld := TFakeWorld.Create;
  LSystem := TAasSystemFactory.CreateSystem(LKeeper, TFakeFiles.Create('maps/m.aas', TAasSample.Bytes(0)), LVarsIntf,
    LWorld, LModelsIntf, nil, nil, True);
  try
    Assert.AreEqual(BLERR_NOERROR, LSystem.Setup);
    Assert.AreEqual(0, LSystem.LoadMap('m'));
    Assert.IsTrue(LSystem.Loaded);
    for LFrame := 1 to 6 do
      LSystem.StartFrame(LFrame);
    Assert.IsTrue(LSystem.Initialized);
    Assert.IsTrue(Assigned(LSystem.Map));
    // the functions of the reachability calculation for the bots are there
    LBest := LSystem.BestReachable;
    Assert.IsTrue(Assigned(LBest));
    Assert.AreEqual(0, LBest.BestReachableLinkArea(AAS_NO_LINK));
  finally
    LSystem.Shutdown;
    LSystem.Free;
  end;
end;

{ TTestAasSystem }

procedure TTestAasSystem.Setup;
begin
  FImport := TFakeImport.Create;
  FImportIntf := FImport;
end;

procedure TTestAasSystem.TearDown;
begin
  FSystemIntf := nil;
  FSystem := nil;
  FReader := nil;
  FLibVarsIntf := nil;
  FImportIntf := nil;
end;

procedure TTestAasSystem.MakeSystem(const AReachabilityRounds: Integer);
var
  LBuilder: TFakeBuilder;
  LModels: TFakeModels;
  LVars: TFakeVars;
  LReader: TFakeReader;
begin
  LBuilder := TFakeBuilder.Create(FImportIntf, AReachabilityRounds, False);
  FSteps := LBuilder;
  LModels := TFakeModels.Create;
  LModels.Text := '{ "classname" "worldspawn" }';
  LVars := TFakeVars.Create;
  LVars.Values.Add('maxentities', 16);
  FVars := LVars;
  FLibVarsIntf := LVars;
  LReader := TFakeReader.Create;
  FReader := LReader;
  FSystem := TAasSystem.Create(FImportIntf, LVars, FReader, LModels, LBuilder,
    function(const AHead: Integer): Integer
    begin
      Result := 0;
    end, nil, True);
  FSystemIntf := FSystem;
end;

procedure TTestAasSystem.DovrebbeLeggereIlNumeroDiEntitaDalleVariabili;
begin
  MakeSystem(0);
  Assert.AreEqual(BLERR_NOERROR, FSystem.Setup);
  Assert.AreEqual(16, FSystem.MaxEntities);
  Assert.AreEqual(128, FSystem.MaxClients);
  Assert.AreEqual(16, FSystem.Entities.Count);
end;

procedure TTestAasSystem.DovrebbeCaricareLaMappaEPartireDalleImpostazioni;
var
  LBuilder: TFakeBuilder;
  LValue: AnsiString;
begin
  MakeSystem(0);
  FSystem.Setup;
  Assert.AreEqual(0, FSystem.LoadMap('q3dm1'));
  LBuilder := TFakeBuilder(FSteps);
  Assert.IsTrue(FSystem.Loaded);
  Assert.IsFalse(FSystem.Initialized);
  Assert.AreEqual('maps/q3dm1.aas', string(FSystem.FileName));
  Assert.AreEqual('maps/q3dm1.aas', string(TFakeReader(FReader as TObject).LastName));
  Assert.AreEqual(6144, LBuilder.MaxLinks);
  Assert.AreEqual('settings,reach,alternative', LBuilder.Steps.Calls.CommaText);
  // the entities of the BSP were read
  Assert.IsTrue(FSystem.BspEntities.ValueForKey(1, 'classname', LValue));
  Assert.AreEqual('worldspawn', string(LValue));
end;

procedure TTestAasSystem.DovrebbeDareIlCodiceDiErroreSeIlFileNonSiCarica;
begin
  MakeSystem(0);
  FSystem.Setup;
  TFakeReader(FReader as TObject).ErrorCode := BLERR_CANNOTOPENAASFILE;
  Assert.AreEqual(BLERR_CANNOTOPENAASFILE, FSystem.LoadMap('nothing'));
  Assert.IsFalse(FSystem.Loaded);
  Assert.IsFalse(Assigned(FSystem.Map));
end;

procedure TTestAasSystem.DovrebbeNonFareNullaSenzaNomeDiMappa;
begin
  MakeSystem(0);
  FSystem.Setup;
  Assert.AreEqual(0, FSystem.LoadMap(''));
  Assert.IsFalse(FSystem.Loaded);
  Assert.AreEqual('', string(TFakeReader(FReader as TObject).LastName));
end;

procedure TTestAasSystem.DovrebbeFinireLInizializzazioneInPiuFotogrammi;
var
  LBuilder: TFakeBuilder;
begin
  MakeSystem(2);
  FSystem.Setup;
  FSystem.LoadMap('q3dm1');
  LBuilder := TFakeBuilder(FSteps);
  FSystem.StartFrame(1);
  Assert.IsFalse(FSystem.Initialized);
  FSystem.StartFrame(2);
  Assert.IsFalse(FSystem.Initialized);
  FSystem.StartFrame(3);
  Assert.IsTrue(FSystem.Initialized);
  Assert.AreEqual(Double(3), Double(FSystem.Time), 0.0);
  Assert.AreEqual('settings,reach,alternative,continue,continue,continue,cluster,routing',
    LBuilder.Steps.Calls.CommaText);
  // initialized: no more steps
  FSystem.StartFrame(4);
  Assert.AreEqual(8, LBuilder.Steps.Calls.Count);
end;

procedure TTestAasSystem.DovrebbeSegnareIlFileDaScrivereSeLeRaggiungibilitaSonoCalcolate;
var
  LBuilder: TFakeBuilder;
begin
  MakeSystem(0);
  FSystem.Setup;
  FSystem.LoadMap('q3dm1');
  LBuilder := TFakeBuilder(FSteps);
  LBuilder.Steps.NeedsSave := True;
  FSystem.StartFrame(1);
  Assert.IsTrue(FSystem.Initialized);
  // the file cannot be written here: it is said
  Assert.IsTrue(LBuilder.Steps.Calls.IndexOf('cluster') >= 0);
  Assert.AreEqual(PRT_ERROR, FImport.Level(FImport.Count - 2));
end;

procedure TTestAasSystem.DovrebbeProiettareUnPuntoSuUnaRetta;
var
  LResult: TVec3;
begin
  LResult := TAasSystem.ProjectPointOntoVector(Vec(5, 7, 0), Vec(0, 0, 0), Vec(10, 0, 0));
  Assert.AreEqual(Double(5), Double(LResult[0]), 0.0);
  Assert.AreEqual(Double(0), Double(LResult[1]), 0.0);
end;

procedure TTestAasSystem.DovrebbeLiberareIlRoutingDellaMappaVecchia;
var
  LOld: TFakeSteps;
begin
  MakeSystem(0);
  FSystem.Setup;
  FSystem.LoadMap('a');
  LOld := TFakeBuilder(FSteps).Steps;
  FSystem.LoadMap('b');
  Assert.IsTrue(LOld.Calls.IndexOf('free') >= 0);
  Assert.AreEqual('maps/b.aas', string(FSystem.FileName));
end;

procedure TTestAasSystem.DovrebbeOttimizzareSeLeVariabiliLoChiedono;
var
  LBuilder: TFakeBuilder;
begin
  MakeSystem(0);
  TFakeVars(FVars).Values.Add('forcewrite', 1);
  TFakeVars(FVars).Values.Add('aasoptimize', 1);
  FSystem.Setup;
  FSystem.LoadMap('q3dm1');
  LBuilder := TFakeBuilder(FSteps);
  FSystem.StartFrame(1);
  Assert.IsTrue(LBuilder.Steps.Calls.IndexOf('optimize') > LBuilder.Steps.Calls.IndexOf('cluster'));
  Assert.IsTrue(LBuilder.Steps.Calls.IndexOf('routing') > LBuilder.Steps.Calls.IndexOf('optimize'));
end;

procedure TTestAasSystem.DovrebbeChiudereTuttoNelloShutdown;
begin
  MakeSystem(0);
  FSystem.Setup;
  FSystem.LoadMap('q3dm1');
  FSystem.Shutdown;
  Assert.IsFalse(FSystem.Loaded);
  Assert.IsFalse(FSystem.Initialized);
  Assert.IsFalse(Assigned(FSystem.Map));
  Assert.IsFalse(Assigned(FSystem.Entities));
  // StartFrame after the shutdown does not touch the entities
  Assert.AreEqual(BLERR_NOERROR, FSystem.StartFrame(5));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestAasLinks);
  TDUnitX.RegisterTestFixture(TTestAasStringIndexes);
  TDUnitX.RegisterTestFixture(TTestAasEntityTable);
  TDUnitX.RegisterTestFixture(TTestAasSystem);
  TDUnitX.RegisterTestFixture(TTestAasSystemFactory);

end.
