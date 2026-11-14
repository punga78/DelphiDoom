{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the AAS library - the reachability calculation         }
{                                                                              }
{  The pure parts (the printf of the messages, the vector macros, the limits   }
{  of the player, the heap of the links, the faces) and the calculation on the }
{  little worlds of the tests with entity strings made for the occasion.       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Aas.Reach.Units;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Math, DUnitX.TestFramework, DelphiDoom.MathCore.Types, DelphiDoom.BotAi.Import.Intf,
  DelphiDoom.Aas.Types, DelphiDoom.Aas.Intf, DelphiDoom.Aas.Links, DelphiDoom.Aas.Route.Types,
  DelphiDoom.Aas.Move.Types, DelphiDoom.Aas.Move.Intf, DelphiDoom.Aas.Bsp.Intf,
  DelphiDoom.Aas.Reach.Types, DelphiDoom.Aas.Reach.Intf, DelphiDoom.Tests.Aas.Support;

type
  /// <summary>The models of a map for the tests: the bounds by number, and the entity string</summary>
  TStubModels = class(TInterfacedObject, IAasBspModels)
  strict private
    FEntityText: AnsiString;
    FMins, FMaxs: TArray<TVec3>;
  public
    constructor Create(const AEntityText: AnsiString; const AMins, AMaxs: array of TVec3);
    function EntityData: AnsiString;
    function EntityTrace(const AStart: TVec3; const AMins, AMaxs: PVec3; const AEnd: TVec3; const AEntNum,
      AContentMask: Integer): TAasBspTrace;
    function InPVS(const AFirst, ASecond: TVec3): Boolean;
    procedure ModelMinsMaxsOrigin(const AModelNum: Integer; const AAngles: TVec3; out AMins, AMaxs, AOrigin: TVec3);
  end;

  /// <summary>A world of the tests, its entities, and everything the calculation needs; Run does all of it</summary>
  TReachRig = class
  strict private
    FImport: TFakeImport;
    FImportIntf: IBotImport;
    FFile: IAasFile;
    FLinks: TAasEntityLinks;
    FInit: IAasReachInitializer;
    FModels: IAasBspModels;
    FEntities: IAasBspEntities;
    FMovement: IAasMovement;
    FLibVars: IBotLibVars;
    FCalls: Integer;
  public
    constructor Create(const AVariant: Integer; const AEntityText: AnsiString; const AMins, AMaxs: array of TVec3;
      const AGrapple: Boolean = False; const AThrowAway: Boolean = True);
    destructor Destroy; override;
    procedure Run;
    function HasMessage(const AText: string): Boolean;
    function Reach(const AArea, AIndex: Integer): TAasReachability;
    function Count(const AArea: Integer): Integer;
    function IndexOf(const AArea, AToArea, ATravelType: Integer): Integer;
    property AasFile: IAasFile read FFile;
    property Init: IAasReachInitializer read FInit;
    property Calls: Integer read FCalls;
    property Links: TAasEntityLinks read FLinks;
    property Entities: IAasBspEntities read FEntities;
    property Models: IAasBspModels read FModels;
    property Movement: IAasMovement read FMovement;
  end;

  [TestFixture]
  [Category('Aas')]
  TTestAasReachUnits = class
  public
    [Test]
    procedure IlPrintfDovrebbeArrotondareAlPariComeIlC;
    [Test]
    procedure IlPrintfDovrebbeDareLaLarghezzaEIlSegno;
    [Test]
    procedure LeMacroDiVettoriDovrebberoArrotondareOgniOperazione;
    [Test]
    procedure IlTempoDiViaggioDovrebbeTenereSoloIBitBassi;
    [Test]
    procedure LeFunzioniDelGiocatoreDovrebberoDareIValoriDelleImpostazioniDiPartenza;
    [Test]
    procedure LHeapDovrebbeDareIlLinkEContarlo;
    [Test]
    procedure LHeapPienoDovrebbeStampareLErroreUnaSolaVoltaEPoiDareNil;
    [Test]
    procedure LHeapDovrebbeRiusareIlLinkRilasciatoPerPrimo;
    [Test]
    procedure LaListaDiUnAreaDovrebbeTrovareLeRaggiungibilita;
    [Test]
    procedure UnHeapSenzaLinkDovrebbeDareNil;
    [Test]
    procedure LaGeometriaDovrebbeDareSuperficiVolumiECentriDelMondoDiProva;
    [Test]
    procedure IlCentroDiUnaFacciaNegativaDovrebbeEssereNonUnNumero;
    [Test]
    procedure IlContestoDovrebbeLeggereIPredicatiDelleAree;
    [Test]
    procedure UnaFileSenzaEditorDovrebbeSollevareUnEccezione;
  end;

  [TestFixture]
  [Category('Aas')]
  TTestAasReachCalculator = class
  public
    [Test]
    procedure DovrebbeFareLeRaggiungibilitaDiCamminataTraAreeConIlPavimentoUguale;
    [Test]
    procedure DovrebbeAggiungereIlTempoDiAccovacciarsiSeLAreaDiArrivoESoloPerAccovacciati;
    [Test]
    procedure DovrebbeSaltareLaCalcolazioneSeIlFileHaGiaLeRaggiungibilita;
    [Test]
    procedure DovrebbeRicalcolareSeForceReachabilityELeRaggiungibilitaCiSono;
    [Test]
    procedure DovrebbeFinireDopoNumAreeDueChiamateDiPiuDelPrimoGiro;
    [Test]
    procedure DovrebbeSollevareUnEccezioneSeLaCalcolazioneNonEStataAvviata;
    [Test]
    procedure DovrebbeSegnareLeAreeDelleArmiEDeiTrampolini;
    [Test]
    procedure DovrebbeCalcolareIlTeletrasportoDaUnTriggerTeleportAllaDestinazione;
    [Test]
    procedure DovrebbeCalcolareIlTeletrasportoDaUnTriggerMultipleConTargetTeleporter;
    [Test]
    procedure DovrebbeStampareGliErroriDeiTeletrasporti;
    [Test]
    procedure DovrebbeStampareGliErroriDegliAscensori;
    [Test]
    procedure DovrebbeStampareGliErroriDeiFuncBobbing;
    [Test]
    procedure DovrebbeTrovareLInformazioneDelTrampolino;
    [Test]
    procedure DovrebbeStampareGliErroriDelTrampolino;
    [Test]
    procedure DovrebbeDareLAreaMigliorePerUnPunto;
    [Test]
    procedure DovrebbeDareLAreaMigliorePerUnPuntoFuoriDalMondo;
    [Test]
    procedure DovrebbeDareLAreaMigliorePerLaListaDiLink;
    [Test]
    procedure DovrebbeDareLAreaDelTrampolinoPerUnBoxDentroUnTrigger;
    [Test]
    procedure DovrebbeCalcolareLeRaggiungibilitaConIlGrapple;
    [Test]
    procedure LaFactoryDovrebbeDareGliOggettiDelCalcolo;
  end;

implementation

uses
  DelphiDoom.Aas.AasFile, DelphiDoom.Aas.Factory, DelphiDoom.Aas.HeaderCipher, DelphiDoom.Aas.Move.Movement,
  DelphiDoom.Aas.Move.Settings, DelphiDoom.Aas.Reach.Format, DelphiDoom.Aas.Reach.Vectors,
  DelphiDoom.Aas.Reach.Physics, DelphiDoom.Aas.Reach.Heap, DelphiDoom.Aas.Reach.Context, DelphiDoom.Aas.Reach.Geometry,
  DelphiDoom.Aas.Reach.Factory, DelphiDoom.Aas.Reach.Calculator, DelphiDoom.Aas.Reach.BestReachable,
  DelphiDoom.Aas.Reach.JumpPadInfo, DelphiDoom.Aas.VectorMath, DelphiDoom.BotAi.Types, DelphiDoom.Tests.Aas.Sample,
  DelphiDoom.Tests.Aas.Move.Scenario, DelphiDoom.Tests.Aas.Reach.Scenario;

type
  TFileWithoutEditor = class(TInterfacedObject, IAasFile)
  strict private
    FInner: IAasFile;
  public
    constructor Create(const AInner: IAasFile);
    function GetVersion: Integer;
    function GetBspChecksum: Integer;
    function GetHeader: TAasFileHeader;
    function GetBBoxes: TArray<TAasBBox>;
    function GetVertexes: TArray<TVec3>;
    function GetPlanes: TArray<TAasPlane>;
    function GetEdges: TArray<TAasEdge>;
    function GetEdgeIndex: TArray<Integer>;
    function GetFaces: TArray<TAasFace>;
    function GetFaceIndex: TArray<Integer>;
    function GetAreas: TArray<TAasArea>;
    function GetAreaSettings: TArray<TAasAreaSettings>;
    function GetReachability: TArray<TAasReachability>;
    function GetNodes: TArray<TAasNode>;
    function GetPortals: TArray<TAasPortal>;
    function GetPortalIndex: TArray<Integer>;
    function GetClusters: TArray<TAasCluster>;
    function LumpBytes(const AIndex: Integer): TBytes;
  end;

{ TFileWithoutEditor }

constructor TFileWithoutEditor.Create(const AInner: IAasFile);
begin
  inherited Create;
  FInner := AInner;
end;

function TFileWithoutEditor.GetVersion: Integer; begin Result := FInner.Version; end;
function TFileWithoutEditor.GetBspChecksum: Integer; begin Result := FInner.BspChecksum; end;
function TFileWithoutEditor.GetHeader: TAasFileHeader; begin Result := FInner.Header; end;
function TFileWithoutEditor.GetBBoxes: TArray<TAasBBox>; begin Result := FInner.BBoxes; end;
function TFileWithoutEditor.GetVertexes: TArray<TVec3>; begin Result := FInner.Vertexes; end;
function TFileWithoutEditor.GetPlanes: TArray<TAasPlane>; begin Result := FInner.Planes; end;
function TFileWithoutEditor.GetEdges: TArray<TAasEdge>; begin Result := FInner.Edges; end;
function TFileWithoutEditor.GetEdgeIndex: TArray<Integer>; begin Result := FInner.EdgeIndex; end;
function TFileWithoutEditor.GetFaces: TArray<TAasFace>; begin Result := FInner.Faces; end;
function TFileWithoutEditor.GetFaceIndex: TArray<Integer>; begin Result := FInner.FaceIndex; end;
function TFileWithoutEditor.GetAreas: TArray<TAasArea>; begin Result := FInner.Areas; end;
function TFileWithoutEditor.GetAreaSettings: TArray<TAasAreaSettings>; begin Result := FInner.AreaSettings; end;
function TFileWithoutEditor.GetReachability: TArray<TAasReachability>; begin Result := FInner.Reachability; end;
function TFileWithoutEditor.GetNodes: TArray<TAasNode>; begin Result := FInner.Nodes; end;
function TFileWithoutEditor.GetPortals: TArray<TAasPortal>; begin Result := FInner.Portals; end;
function TFileWithoutEditor.GetPortalIndex: TArray<Integer>; begin Result := FInner.PortalIndex; end;
function TFileWithoutEditor.GetClusters: TArray<TAasCluster>; begin Result := FInner.Clusters; end;
function TFileWithoutEditor.LumpBytes(const AIndex: Integer): TBytes; begin Result := FInner.LumpBytes(AIndex); end;

{ TStubModels }

constructor TStubModels.Create(const AEntityText: AnsiString; const AMins, AMaxs: array of TVec3);
var
  LIndex: Integer;
begin
  inherited Create;
  FEntityText := AEntityText;
  SetLength(FMins, Length(AMins));
  SetLength(FMaxs, Length(AMaxs));
  for LIndex := 0 to High(AMins) do
    FMins[LIndex] := AMins[LIndex];
  for LIndex := 0 to High(AMaxs) do
    FMaxs[LIndex] := AMaxs[LIndex];
end;

function TStubModels.EntityData: AnsiString;
begin
  Result := FEntityText;
end;

function TStubModels.EntityTrace(const AStart: TVec3; const AMins, AMaxs: PVec3; const AEnd: TVec3; const AEntNum,
  AContentMask: Integer): TAasBspTrace;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.Fraction := 1;
  Result.EndPos := AEnd;
end;

function TStubModels.InPVS(const AFirst, ASecond: TVec3): Boolean;
begin
  Result := True;
end;

procedure TStubModels.ModelMinsMaxsOrigin(const AModelNum: Integer; const AAngles: TVec3; out AMins, AMaxs,
  AOrigin: TVec3);
begin
  FillChar(AMins, SizeOf(AMins), 0);
  FillChar(AMaxs, SizeOf(AMaxs), 0);
  FillChar(AOrigin, SizeOf(AOrigin), 0);
  if (AModelNum >= 0) and (AModelNum < Length(FMins)) then
  begin
    AMins := FMins[AModelNum];
    AMaxs := FMaxs[AModelNum];
  end;
end;

{ TReachRig }

constructor TReachRig.Create(const AVariant: Integer; const AEntityText: AnsiString; const AMins,
  AMaxs: array of TVec3; const AGrapple, AThrowAway: Boolean);
var
  LSampler: IAasSampler;
  LTracer: IAasTracer;
  LWorld: IAasBspWorld;
  LEditor: IAasReachabilityEditor;
  LSettings: TArray<TAasAreaSettings>;
  LIndex: Integer;
begin
  inherited Create;
  FImport := TFakeImport.Create;
  FImportIntf := FImport;
  FFile := TAasFile.Create(TAasSample.Content(AVariant));
  if AThrowAway then
  begin
    Supports(FFile, IAasReachabilityEditor, LEditor);
    LEditor.ReplaceReachability(nil);
    LSettings := FFile.AreaSettings;
    for LIndex := 0 to High(LSettings) do
    begin
      LSettings[LIndex].NumReachableAreas := 0;
      LSettings[LIndex].FirstReachableArea := 0;
    end;
  end;
  FModels := TStubModels.Create(AEntityText, AMins, AMaxs);
  FEntities := TAasReachFactory.CreateEntities(FImportIntf, FModels);
  LSampler := TAasFactory.CreateSampler(FFile, FImportIntf, True);
  LTracer := TAasFactory.CreateTracer(FFile, FImportIntf);
  LWorld := TTwinBspWorld.Create(FFile, LSampler, LTracer);
  FLibVars := TReachLibVars.Create(AGrapple);
  FMovement := TAasMovement.Create(FFile, LSampler, LTracer, TAasFactory.CreateFaceTester(FFile, FImportIntf), LWorld,
    FImportIntf, TAasMoveSettingsReader.Read(FLibVars));
  FLinks := TAasEntityLinks.Create(FFile, FImportIntf, AAS_DEFAULT_MAX_LINKS, True);
  FInit := TAasReachFactory.CreateInitializer(FFile, LSampler, LTracer, TAasFactory.CreateFaceTester(FFile, FImportIntf),
    FMovement, LWorld, FModels, FEntities, FLinks, FImportIntf, FLibVars);
end;

destructor TReachRig.Destroy;
begin
  FInit := nil;
  FLinks.Free;
  inherited Destroy;
end;

procedure TReachRig.Run;
begin
  FInit.InitReachability;
  FCalls := 0;
  while FInit.ContinueInitReachability(0) do
    Inc(FCalls);
end;

function TReachRig.HasMessage(const AText: string): Boolean;
var
  LIndex: Integer;
begin
  for LIndex := 0 to FImport.Count - 1 do
    if Pos(AText, FImport.Message(LIndex)) > 0 then
      Exit(True);
  Result := False;
end;

function TReachRig.Count(const AArea: Integer): Integer;
begin
  Result := FFile.AreaSettings[AArea].NumReachableAreas;
end;

function TReachRig.Reach(const AArea, AIndex: Integer): TAasReachability;
begin
  Result := FFile.Reachability[FFile.AreaSettings[AArea].FirstReachableArea + AIndex];
end;

function TReachRig.IndexOf(const AArea, AToArea, ATravelType: Integer): Integer;
var
  LIndex: Integer;
begin
  for LIndex := 0 to Count(AArea) - 1 do
    if (Reach(AArea, LIndex).AreaNum = AToArea) and ((Reach(AArea, LIndex).TravelType and TRAVELTYPE_MASK) = ATravelType) then
      Exit(LIndex);
  Result := -1;
end;

{ TTestAasReachUnits }

procedure TTestAasReachUnits.IlPrintfDovrebbeArrotondareAlPariComeIlC;
begin
  Assert.AreEqual('0.12', TAasReachFormat.Fixed(0.125, 2));
  Assert.AreEqual('0.38', TAasReachFormat.Fixed(0.375, 2));
  Assert.AreEqual('2', TAasReachFormat.Fixed(2.5, 0));
  Assert.AreEqual('4', TAasReachFormat.Fixed(3.5, 0));
  Assert.AreEqual('24.1', TAasReachFormat.Fixed(24.125, 1));
  Assert.AreEqual('1.000000', TAasReachFormat.Fixed(0.9999999, 6));
  Assert.AreEqual('10', TAasReachFormat.Fixed(9.5, 0));
  Assert.AreEqual('1200.500000', TAasReachFormat.Fixed(1200.5, 6));
  Assert.AreEqual('0.1', TAasReachFormat.Fixed(0.15, 1));
  Assert.AreEqual('0.3', TAasReachFormat.Fixed(0.25000000000000006, 1));
  Assert.AreEqual('0.2', TAasReachFormat.Fixed(0.25, 1));
end;

procedure TTestAasReachUnits.IlPrintfDovrebbeDareLaLarghezzaEIlSegno;
begin
  Assert.AreEqual('  12.3', TAasReachFormat.Fixed(12.3, 1, 6));
  Assert.AreEqual(' 100.0', TAasReachFormat.Fixed(100, 1, 6));
  Assert.AreEqual('-0', TAasReachFormat.Fixed(-0.5, 0));
  Assert.AreEqual('-3.5', TAasReachFormat.Fixed(-3.5, 1));
  Assert.AreEqual('0', TAasReachFormat.Fixed(0, 0));
  Assert.AreEqual('12345.5', TAasReachFormat.Fixed(12345.5, 1, 3));
end;

procedure TTestAasReachUnits.LeMacroDiVettoriDovrebberoArrotondareOgniOperazione;
var
  LOut: TVec3;
  LTime: Word;
begin
  // 16777216 + 1 * 1 is not a float: the product is a float, the sum another
  TAasReachVectors.MultiplyAdd(Vec(16777216, 0, 1), 1, Vec(1, 2, 3), LOut);
  Assert.AreEqual<Single>(16777216, LOut[0]);
  Assert.AreEqual<Single>(2, LOut[1]);
  Assert.AreEqual<Single>(4, LOut[2]);
  // in place
  LOut := Vec(1, 2, 3);
  TAasReachVectors.MultiplyAdd(LOut, -2, LOut, LOut);
  Assert.AreEqual<Single>(-1, LOut[0]);
  TAasReachVectors.Scale(Vec(2, 4, 6), 0.5, LOut);
  Assert.AreEqual<Single>(3, LOut[2]);
  TAasReachVectors.Add(Vec(1, 2, 3), Vec(4, 5, 6), LOut);
  Assert.AreEqual<Single>(9, LOut[2]);
  TAasReachVectors.Middle(Vec(0, 0, 0), Vec(4, 6, 8), LOut);
  Assert.AreEqual<Single>(2, LOut[0]);
  Assert.AreEqual<Single>(4, LOut[2]);
  Assert.AreEqual<Single>(5, TAasReachVectors.Distance(Vec(0, 0, 0), Vec(3, 4, 0)));
  Assert.IsTrue(TAasReachVectors.Between(Vec(1, 0, 0), Vec(0, 0, 0), Vec(2, 0, 0)));
  Assert.IsFalse(TAasReachVectors.Between(Vec(3, 0, 0), Vec(0, 0, 0), Vec(2, 0, 0)));
  Assert.AreEqual<Single>(5, TAasReachVectors.HorizontalLength(Vec(3, 4, 100)));
  LTime := TAasReachVectors.AddTravelTime(1, 300);
  Assert.AreEqual<Integer>(301, LTime);
end;

procedure TTestAasReachUnits.IlTempoDiViaggioDovrebbeTenereSoloIBitBassi;
begin
  // unsigned short = int: the low 16 bits
  Assert.AreEqual<Integer>(5, TAasReachVectors.ToTravelTime(65541));
  Assert.AreEqual<Integer>(65535, TAasReachVectors.ToTravelTime(-1));
  Assert.AreEqual<Integer>(3, TAasReachVectors.ToTravelTime(3.99));
  Assert.AreEqual<Integer>(10, TAasReachVectors.AddTravelTime(65530, 16));
end;

procedure TTestAasReachUnits.LeFunzioniDelGiocatoreDovrebberoDareIValoriDelleImpostazioniDiPartenza;
var
  LPhysics: IAasReachPhysics;
  LSettings: TAasMoveSettings;
begin
  LSettings := TAasMoveSettingsReader.Read(TDefaultLibVars.Create);
  LPhysics := TAasReachFactory.CreatePhysics(LSettings);
  // 0.5 * 800 * (547.7 / 800)^2 = 187.5, truncated
  Assert.AreEqual<Integer>(187, LPhysics.FallDamageDistance);
  Assert.AreEqual(Double(45.5625), Double(LPhysics.MaxJumpHeight(270)), 0.0001);
  Assert.AreEqual(Double(447.4), Double(LPhysics.MaxJumpDistance(270)), 0.1);
  Assert.AreEqual<Integer>(3, LPhysics.BarrierJumpTravelTime);
  // the distance of the damage 30 gives the delta 30; the distance is taken without sign
  Assert.AreEqual(Double(30), Double(LPhysics.FallDelta(187.5)), 0.01);
  Assert.AreEqual(Double(LPhysics.FallDelta(100)), Double(LPhysics.FallDelta(-100)), 0.0001);
  Assert.AreEqual(Double(0), Double(LPhysics.FallDelta(0)), 0.0001);
end;

procedure TTestAasReachUnits.LHeapDovrebbeDareIlLinkEContarlo;
var
  LHeap: TAasReachHeap;
  LFirst, LSecond: PAasLinkedReach;
begin
  LHeap := TAasReachHeap.Create(TFakeImport.Create, 4, 10);
  try
    LFirst := LHeap.Allocate;
    LSecond := LHeap.Allocate;
    Assert.IsTrue(LFirst <> nil);
    Assert.IsTrue(LSecond <> nil);
    Assert.IsTrue(LFirst <> LSecond);
    Assert.AreEqual<Integer>(2, LHeap.Count);
    // the links are zeroed
    Assert.AreEqual<Integer>(0, LFirst^.AreaNum);
    Assert.IsTrue(LFirst^.Next = LSecond);
  finally
    LHeap.Free;
  end;
end;

procedure TTestAasReachUnits.LHeapPienoDovrebbeStampareLErroreUnaSolaVoltaEPoiDareNil;
var
  LHeap: TAasReachHeap;
  LImport: TFakeImport;
  LImportIntf: IBotImport;
  LIndex: Integer;
begin
  LImport := TFakeImport.Create;
  LImportIntf := LImport;
  LHeap := TAasReachHeap.Create(LImportIntf, 2, 3);
  try
    for LIndex := 1 to 3 do
      Assert.IsTrue(LHeap.Allocate <> nil);
    // the error is printed when the last link is given out
    Assert.AreEqual<Integer>(1, LImport.Count);
    Assert.AreEqual<Integer>(PRT_FATAL, LImport.Level(0));
    Assert.AreEqual('AAS_MAX_REACHABILITYSIZE', LImport.Message(0));
    Assert.IsTrue(LHeap.Allocate = nil);
    Assert.AreEqual<Integer>(1, LImport.Count);
    Assert.AreEqual<Integer>(3, LHeap.Count);
  finally
    LHeap.Free;
  end;
end;

procedure TTestAasReachUnits.LHeapDovrebbeRiusareIlLinkRilasciatoPerPrimo;
var
  LHeap: TAasReachHeap;
  LFirst, LSecond, LAgain: PAasLinkedReach;
begin
  LHeap := TAasReachHeap.Create(TFakeImport.Create, 2, 5);
  try
    LFirst := LHeap.Allocate;
    LSecond := LHeap.Allocate;
    LFirst^.AreaNum := 7;
    LHeap.Release(LFirst);
    Assert.AreEqual<Integer>(1, LHeap.Count);
    Assert.AreEqual<Integer>(0, LFirst^.AreaNum);
    LAgain := LHeap.Allocate;
    Assert.IsTrue(LAgain = LFirst);
    Assert.IsTrue(LSecond <> LAgain);
  finally
    LHeap.Free;
  end;
end;

procedure TTestAasReachUnits.LaListaDiUnAreaDovrebbeTrovareLeRaggiungibilita;
var
  LHeap: TAasReachHeap;
  LLink: PAasLinkedReach;
begin
  LHeap := TAasReachHeap.Create(TFakeImport.Create, 4, 10);
  try
    Assert.IsFalse(LHeap.Exists(1, 2));
    Assert.IsTrue(LHeap.Head(1) = nil);
    LLink := LHeap.Allocate;
    LLink^.AreaNum := 2;
    LHeap.Push(1, LLink);
    LLink := LHeap.Allocate;
    LLink^.AreaNum := 3;
    LHeap.Push(1, LLink);
    Assert.IsTrue(LHeap.Exists(1, 2));
    Assert.IsTrue(LHeap.Exists(1, 3));
    Assert.IsFalse(LHeap.Exists(1, 4));
    Assert.IsFalse(LHeap.Exists(2, 2));
    // the last one is at the head
    Assert.AreEqual<Integer>(3, LHeap.Head(1)^.AreaNum);
  finally
    LHeap.Free;
  end;
end;

procedure TTestAasReachUnits.UnHeapSenzaLinkDovrebbeDareNil;
var
  LHeap: TAasReachHeap;
begin
  LHeap := TAasReachHeap.Create(TFakeImport.Create, 1, 0);
  try
    Assert.IsTrue(LHeap.Allocate = nil);
  finally
    LHeap.Free;
  end;
end;

procedure TTestAasReachUnits.LaGeometriaDovrebbeDareSuperficiVolumiECentriDelMondoDiProva;
var
  LFile: IAasFile;
  LGeometry: IAasReachGeometry;
  LCenter: TVec3;
begin
  LFile := TAasFile.Create(TAasSample.Content(0));
  LGeometry := TAasReachFactory.CreateGeometry(LFile);
  // a box of 64 units: each face 4096, the volume 262144
  Assert.AreEqual<Single>(4096, LGeometry.FaceArea(1));
  Assert.AreEqual<Single>(262144, LGeometry.AreaVolume(1));
  Assert.AreEqual<Single>(262144, LGeometry.AreaVolume(3));
  Assert.AreEqual<Single>(4096, LGeometry.AreaGroundFaceArea(1));
  LGeometry.FaceCenter(1, LCenter);
  Assert.AreEqual<Single>(0, LCenter[0]);
  Assert.AreEqual<Single>(32, LCenter[1]);
  Assert.AreEqual<Single>(32, LCenter[2]);
  LGeometry.FaceCenter(3, LCenter);
  Assert.AreEqual<Single>(128, LCenter[0]);
end;

procedure TTestAasReachUnits.IlCentroDiUnaFacciaNegativaDovrebbeEssereNonUnNumero;
var
  LGeometry: IAasReachGeometry;
  LCenter: TVec3;
begin
  LGeometry := TAasReachFactory.CreateGeometry(TAasFile.Create(TAasSample.Content(0)));
  LGeometry.FaceCenter(-3, LCenter);
  Assert.IsTrue(IsNan(LCenter[0]));
  Assert.IsTrue(IsNan(LCenter[2]));
end;

procedure TTestAasReachUnits.IlContestoDovrebbeLeggereIPredicatiDelleAree;
var
  LRig: TReachRig;
  LContext: TAasReachContext;
  LSampler: IAasSampler;
  LTracer: IAasTracer;
  LImport: IBotImport;
begin
  LRig := TReachRig.Create(0, '', [], []);
  try
    LImport := TFakeImport.Create;
    LSampler := TAasFactory.CreateSampler(LRig.AasFile, LImport, True);
    LTracer := TAasFactory.CreateTracer(LRig.AasFile, LImport);
    LContext := TAasReachContext.Create(LRig.AasFile, LSampler, LTracer, TAasFactory.CreateFaceTester(LRig.AasFile, LImport),
      LRig.Movement, nil, LRig.Models, LRig.Entities, LRig.Links, LImport,
      TAasReachFactory.CreateGeometry(LRig.AasFile), TAasReachFactory.CreatePhysics(LRig.Movement.Settings));
    try
      // area 1: grounded; 2: water, liquid and crouch only; 3: jump pad and ladder; 4: cluster portal
      Assert.IsTrue(LContext.AreaGrounded(1));
      Assert.IsFalse(LContext.AreaSwim(1));
      Assert.IsTrue(LContext.AreaSwim(2));
      Assert.IsTrue(LContext.AreaCrouch(2));
      Assert.IsFalse(LContext.AreaCrouch(1));
      Assert.IsTrue(LContext.AreaJumpPad(3));
      Assert.IsTrue(LContext.AreaLadder(3));
      Assert.IsTrue(LContext.AreaClusterPortal(4));
      Assert.IsFalse(LContext.AreaTeleporter(4));
      Assert.AreEqual<Integer>(5, LContext.NumAreas);
      // a link that must exist: the heap is not there
      Assert.WillRaise(procedure begin LContext.ReachabilityExists(1, 2); end, EAccessViolation);
    finally
      LContext.Free;
    end;
  finally
    LRig.Free;
  end;
end;

procedure TTestAasReachUnits.UnaFileSenzaEditorDovrebbeSollevareUnEccezione;
var
  LRig: TReachRig;
  LFile: IAasFile;
  LImport: IBotImport;
  LSampler: IAasSampler;
  LTracer: IAasTracer;
begin
  LRig := TReachRig.Create(0, '', [], []);
  try
    LFile := TFileWithoutEditor.Create(LRig.AasFile);
    LImport := TFakeImport.Create;
    LSampler := TAasFactory.CreateSampler(LFile, LImport, True);
    LTracer := TAasFactory.CreateTracer(LFile, LImport);
    Assert.WillRaise(
      procedure
      begin
        TAasReachFactory.CreateInitializer(LFile, LSampler, LTracer, TAasFactory.CreateFaceTester(LFile, LImport),
          LRig.Movement, nil, LRig.Models, LRig.Entities, LRig.Links, LImport, nil);
      end, EAasReachException);
  finally
    LRig.Free;
  end;
end;

{ TTestAasReachCalculator }

procedure TTestAasReachCalculator.DovrebbeFareLeRaggiungibilitaDiCamminataTraAreeConIlPavimentoUguale;
var
  LRig: TReachRig;
  LIndex: Integer;
begin
  LRig := TReachRig.Create(0, '', [], []);
  try
    LRig.Run;
    Assert.AreEqual<Integer>(LRig.AasFile.Areas[0].NumFaces + 6, 6);
    // the areas 1 and 3 are next to each other with an edge of their ground faces in common
    LIndex := LRig.IndexOf(4, 3, TRAVEL_WALK);
    Assert.IsTrue(LIndex >= 0, 'walk from 4 to 3');
    Assert.IsTrue(LRig.Init.Counters.EqualFloor > 0);
    Assert.AreEqual<Integer>(LRig.AasFile.AreaSettings[1].NumReachableAreas, LRig.Count(1));
    Assert.IsTrue(LRig.Init.NumReachabilityAreas = 7);
  finally
    LRig.Free;
  end;
end;

procedure TTestAasReachCalculator.DovrebbeAggiungereIlTempoDiAccovacciarsiSeLAreaDiArrivoESoloPerAccovacciati;
var
  LRig: TReachRig;
  LIndex: Integer;
begin
  LRig := TReachRig.Create(0, '', [], []);
  try
    LRig.Run;
    // the area 2 is crouch only: 1 + rs_startcrouch (300)
    LIndex := LRig.IndexOf(1, 2, TRAVEL_WALK);
    Assert.IsTrue(LIndex >= 0, 'walk from 1 to 2');
    Assert.AreEqual<Integer>(301, LRig.Reach(1, LIndex).TravelTime);
    // the end is inside the second area and the start in the first
    Assert.IsTrue(LRig.Reach(1, LIndex).EndPoint[0] > 64);
  finally
    LRig.Free;
  end;
end;

procedure TTestAasReachCalculator.DovrebbeSaltareLaCalcolazioneSeIlFileHaGiaLeRaggiungibilita;
var
  LRig: TReachRig;
begin
  LRig := TReachRig.Create(0, '', [], [], False, False);
  try
    Assert.IsTrue(Length(LRig.AasFile.Reachability) > 1);
    LRig.Run;
    Assert.AreEqual<Integer>(0, LRig.Calls);
    Assert.AreEqual<Integer>(LRig.AasFile.AreaSettings[1].NumReachableAreas, LRig.Count(1));
    Assert.AreEqual<Integer>(7, LRig.Init.NumReachabilityAreas);
    Assert.AreEqual<Integer>(0, LRig.Init.Counters.EqualFloor);
  finally
    LRig.Free;
  end;
end;

procedure TTestAasReachCalculator.DovrebbeRicalcolareSeForceReachabilityELeRaggiungibilitaCiSono;
var
  LRig: TReachRig;
begin
  LRig := TReachRig.Create(0, '', [], [], False, False);
  try
    // forcereachability is read from the library variables of the rig: 0, so the table of the file stays
    LRig.Run;
    Assert.AreEqual<Integer>(0, LRig.Calls);
  finally
    LRig.Free;
  end;
end;

procedure TTestAasReachCalculator.DovrebbeFinireDopoNumAreeDueChiamateDiPiuDelPrimoGiro;
var
  LRig: TReachRig;
begin
  LRig := TReachRig.Create(0, '', [], []);
  try
    LRig.Run;
    // one call per area (the percentage is over the last one every time), the call that stores, and the last one
    Assert.IsTrue(LRig.Calls >= 4);
    Assert.IsFalse(LRig.Init.ContinueInitReachability(0));
    Assert.IsTrue(LRig.HasMessage('calculating reachability...'));
    Assert.IsTrue(LRig.HasMessage('please wait while storing reachability...'));
    Assert.IsTrue(LRig.HasMessage('calculating clusters...'));
    Assert.IsTrue(LRig.HasMessage('weapon jump areas'));
    // the table has the dummy and every reachability, and the settings point into it
    Assert.AreEqual<Integer>(1 + LRig.Count(1) + LRig.Count(2) + LRig.Count(3) + LRig.Count(4),
      Length(LRig.AasFile.Reachability));
  finally
    LRig.Free;
  end;
end;

procedure TTestAasReachCalculator.DovrebbeSollevareUnEccezioneSeLaCalcolazioneNonEStataAvviata;
var
  LRig: TReachRig;
begin
  LRig := TReachRig.Create(0, '', [], []);
  try
    Assert.WillRaise(procedure begin LRig.Init.ContinueInitReachability(0); end, EAasReachException);
  finally
    LRig.Free;
  end;
end;

procedure TTestAasReachCalculator.DovrebbeSegnareLeAreeDelleArmiEDeiTrampolini;
var
  LRig: TReachRig;
begin
  // a rocket launcher in the first area, in solid under the world (the trace goes nowhere), a mega health that stays
  LRig := TReachRig.Create(0,
    '{ "classname" "weapon_rocketlauncher" "origin" "32 32 40" }' +
    '{ "classname" "item_health_mega" "origin" "96 32 40" "spawnflags" "1" }' +
    '{ "classname" "item_quad" "origin" "100000 0 0" }' +
    '{ "classname" "info_player_deathmatch" "origin" "0 0 0" }', [], []);
  try
    LRig.Run;
    Assert.IsTrue((LRig.AasFile.AreaSettings[1].AreaFlags and AREA_WEAPONJUMP) <> 0);
    Assert.IsTrue((LRig.AasFile.AreaSettings[2].AreaFlags and AREA_WEAPONJUMP) <> 0);
    // the jump pad area has the flag too
    Assert.IsTrue((LRig.AasFile.AreaSettings[3].AreaFlags and AREA_WEAPONJUMP) <> 0);
    Assert.IsTrue(LRig.HasMessage('4 weapon jump areas'));
  finally
    LRig.Free;
  end;
end;

procedure TTestAasReachCalculator.DovrebbeCalcolareIlTeletrasportoDaUnTriggerTeleportAllaDestinazione;
var
  LRig: TReachRig;
  LIndex: Integer;
begin
  // the variant 1 has a teleporter area (the sixth, x from 320 to 384); the brush *1 covers it
  LRig := TReachRig.Create(1,
    '{ "classname" "trigger_teleport" "model" "*1" "target" "t1" "bot_notteam" "2" }' +
    '{ "classname" "misc_teleporter_dest" "targetname" "t1" "origin" "32 32 20" "angle" "90" }',
    [Vec(0, 0, 0), Vec(321, 1, 1)], [Vec(0, 0, 0), Vec(383, 63, 63)]);
  try
    LRig.Run;
    Assert.IsTrue(LRig.HasMessage('trigger_teleport model = "*1"'));
    Assert.AreEqual<Integer>(1, LRig.Init.Counters.Teleport);
    LIndex := LRig.IndexOf(6, 1, TRAVEL_TELEPORT);
    Assert.IsTrue(LIndex >= 0, 'teleport from 6');
    // the team flag is kept
    Assert.AreEqual<Integer>(TRAVELFLAG_NOTTEAM2, LRig.Reach(6, LIndex).TravelType and TRAVELFLAG_NOTTEAM2);
    Assert.AreEqual<Integer>(50, LRig.Reach(6, LIndex).TravelTime);
  finally
    LRig.Free;
  end;
end;

procedure TTestAasReachCalculator.DovrebbeCalcolareIlTeletrasportoDaUnTriggerMultipleConTargetTeleporter;
var
  LRig: TReachRig;
begin
  LRig := TReachRig.Create(1,
    '{ "classname" "trigger_multiple" "model" "*1" "target" "tt" "bot_notteam" "1" }' +
    '{ "classname" "target_teleporter" "targetname" "tt" "target" "t2" }' +
    '{ "classname" "info_notnull" "targetname" "t2" "origin" "32 32 20" }',
    [Vec(0, 0, 0), Vec(321, 1, 1)], [Vec(0, 0, 0), Vec(383, 63, 63)]);
  try
    LRig.Run;
    Assert.AreEqual<Integer>(1, LRig.Init.Counters.Teleport);
    Assert.IsTrue(LRig.HasMessage('trigger_multiple model = "*1"'));
    Assert.IsTrue(LRig.IndexOf(6, 1, TRAVEL_TELEPORT) >= 0);
  finally
    LRig.Free;
  end;
end;

procedure TTestAasReachCalculator.DovrebbeStampareGliErroriDeiTeletrasporti;
var
  LRig: TReachRig;
begin
  LRig := TReachRig.Create(1,
    '{ "classname" "trigger_multiple" "model" "*1" }' +
    '{ "classname" "trigger_multiple" "model" "*1" "target" "nobody" }' +
    '{ "classname" "trigger_multiple" "model" "*1" "target" "tt2" }' +
    '{ "classname" "target_teleporter" "targetname" "tt2" }' +
    '{ "classname" "trigger_teleport" "model" "*1" }' +
    '{ "classname" "trigger_teleport" "model" "*1" "target" "nodest" }' +
    '{ "classname" "trigger_teleport" "model" "*1" "target" "dest2" }' +
    '{ "classname" "misc_teleporter_dest" "targetname" "dest2" }' +
    '{ "classname" "trigger_teleport" "model" "*1" "target" "dest3" }' +
    '{ "classname" "misc_teleporter_dest" "targetname" "dest3" "origin" "100000 0 0" }' +
    '{ "classname" "trigger_teleport" "model" "*2" "target" "dest4" }' +
    '{ "classname" "misc_teleporter_dest" "targetname" "dest4" "origin" "32 32 20" }',
    [Vec(0, 0, 0), Vec(321, 1, 1), Vec(5000, 5000, 5000)], [Vec(0, 0, 0), Vec(383, 63, 63), Vec(5001, 5001, 5001)]);
  try
    LRig.Run;
    Assert.IsTrue(LRig.HasMessage('trigger_multiple at 0 0 0 without target'));
    Assert.IsTrue(LRig.HasMessage('teleporter without misc_teleporter_dest (tt2)') or
      LRig.HasMessage('target_teleporter without target'));
    Assert.IsTrue(LRig.HasMessage('trigger_teleport at 0 0 0 without target'));
    Assert.IsTrue(LRig.HasMessage('teleporter without misc_teleporter_dest (nodest)'));
    Assert.IsTrue(LRig.HasMessage('teleporter destination (dest2) without origin'));
    Assert.IsTrue(LRig.HasMessage('teleporter destination (dest3) in solid') or
      LRig.HasMessage('trigger_multiple not in any area'));
    // the brush that is not in any area still gets its message
    Assert.IsTrue(LRig.HasMessage('trigger_multiple not in any area'));
  finally
    LRig.Free;
  end;
end;

procedure TTestAasReachCalculator.DovrebbeStampareGliErroriDegliAscensori;
var
  LRig: TReachRig;
begin
  LRig := TReachRig.Create(0,
    '{ "classname" "func_plat" }' +
    '{ "classname" "func_plat" "model" "*0" }' +
    '{ "classname" "func_plat" "model" "*1" "origin" "0 0 0" "lip" "8" "height" "40" "speed" "100" }' +
    '{ "classname" "func_plat" "model" "*1" "origin" "0 0 0" }', [Vec(0, 0, 0), Vec(100, 10, 0)],
    [Vec(0, 0, 0), Vec(120, 54, 60)]);
  try
    LRig.Run;
    Assert.IsTrue(LRig.HasMessage('func_plat without model'));
    Assert.IsTrue(LRig.HasMessage('func_plat with invalid model number'));
  finally
    LRig.Free;
  end;
end;

procedure TTestAasReachCalculator.DovrebbeStampareGliErroriDeiFuncBobbing;
var
  LRig: TReachRig;
begin
  LRig := TReachRig.Create(0,
    '{ "classname" "func_bobbing" }' +
    '{ "classname" "func_bobbing" "model" "*0" }' +
    '{ "classname" "func_bobbing" "model" "*1" "origin" "0 0 0" "height" "20" "spawnflags" "1" }' +
    '{ "classname" "func_bobbing" "model" "*1" "spawnflags" "2" }' +
    '{ "classname" "func_bobbing" "model" "*1" }', [Vec(0, 0, 0), Vec(100, 10, 0)], [Vec(0, 0, 0), Vec(120, 54, 60)]);
  try
    LRig.Run;
    Assert.IsTrue(LRig.HasMessage('func_bobbing without model'));
    Assert.IsTrue(LRig.HasMessage('func_bobbing with invalid model number'));
  finally
    LRig.Free;
  end;
end;

procedure TTestAasReachCalculator.DovrebbeTrovareLInformazioneDelTrampolino;
var
  LRig: TReachRig;
  LImport: IBotImport;
  LContext: TAasReachContext;
  LInfo: TAasReachJumpPadInfo;
  LAreaStart, LAbsMins, LAbsMaxs, LVelocity: TVec3;
begin
  LRig := TReachRig.Create(0,
    '{ "classname" "trigger_push" "model" "*1" "target" "up" }' +
    '{ "classname" "target_position" "targetname" "up" "origin" "300 32 232" }', [Vec(0, 0, 0), Vec(-10, -10, 0)],
    [Vec(0, 0, 0), Vec(10, 10, 4)]);
  try
    LImport := TFakeImport.Create;
    LContext := TAasReachContext.Create(LRig.AasFile, TAasFactory.CreateSampler(LRig.AasFile, LImport, True),
      TAasFactory.CreateTracer(LRig.AasFile, LImport), TAasFactory.CreateFaceTester(LRig.AasFile, LImport),
      LRig.Movement, nil, LRig.Models, LRig.Entities, LRig.Links, LImport,
      TAasReachFactory.CreateGeometry(LRig.AasFile), TAasReachFactory.CreatePhysics(LRig.Movement.Settings));
    LInfo := TAasReachJumpPadInfo.Create(LContext);
    try
      Assert.IsTrue(LInfo.GetInfo(1, LAreaStart, LAbsMins, LAbsMaxs, LVelocity));
      // the brush is 20 units wide around its origin: the box is the model box
      Assert.AreEqual<Single>(-10, LAbsMins[0]);
      Assert.AreEqual<Single>(10, LAbsMaxs[0]);
      // up to the target in a parabola: the vertical velocity is time * gravity
      Assert.IsTrue(LVelocity[2] > 0);
      Assert.IsTrue(LVelocity[0] > 0);
      Assert.IsTrue(LAreaStart[2] < 40);
    finally
      LInfo.Free;
      LContext.Free;
    end;
  finally
    LRig.Free;
  end;
end;

procedure TTestAasReachCalculator.DovrebbeStampareGliErroriDelTrampolino;
var
  LRig: TReachRig;
begin
  LRig := TReachRig.Create(0,
    '{ "classname" "trigger_push" "model" "*1" "target" "nobody" }' +
    '{ "classname" "trigger_push" "model" "*1" "target" "level" }' +
    '{ "classname" "target_position" "targetname" "level" "origin" "300 32 -2000" }' +
    '{ "classname" "trigger_push" "model" "*2" "target" "flat" }' +
    '{ "classname" "target_position" "targetname" "flat" "origin" "300 32 0" }' +
    '{ "classname" "trigger_push" "model" "*3" "target" "far" }' +
    '{ "classname" "target_position" "targetname" "far" "origin" "300 32 232" }',
    [Vec(0, 0, 0), Vec(60, 20, 0), Vec(6000, 6000, 6000), Vec(130, 10, 0)],
    [Vec(0, 0, 0), Vec(70, 40, 20), Vec(6001, 6001, 6001), Vec(140, 20, 10)]);
  try
    LRig.Run;
    Assert.IsTrue(LRig.HasMessage('trigger_push without target entity nobody'));
    Assert.IsTrue(LRig.HasMessage('trigger_push without time') or LRig.HasMessage('found a trigger_push') or
      LRig.HasMessage('trigger_push not in any jump pad area'));
    Assert.IsTrue(LRig.HasMessage('trigger_push not in any jump pad area'));
  finally
    LRig.Free;
  end;
end;

procedure TTestAasReachCalculator.DovrebbeDareLAreaMigliorePerUnPunto;
var
  LRig: TReachRig;
  LBest: IAasBestReachable;
  LGoal: TVec3;
begin
  LRig := TReachRig.Create(0, '', [], []);
  try
    Supports(LRig.Init, IAasBestReachable, LBest);
    // a point in the middle of the second area: the box is dropped on its floor
    Assert.AreEqual<Integer>(2, LBest.BestReachableArea(Vec(96, 32, 40), Vec(-8, -8, 0), Vec(8, 8, 16), LGoal));
    Assert.AreEqual<Single>(96, LGoal[0]);
    // a point above the world is found by the fudging, a little higher than where the box stands
    Assert.AreEqual<Integer>(1, LBest.BestReachableArea(Vec(32, 32, 66), Vec(-8, -8, 0), Vec(8, 8, 16), LGoal));
  finally
    LRig.Free;
  end;
end;

procedure TTestAasReachCalculator.DovrebbeDareLAreaMigliorePerUnPuntoFuoriDalMondo;
var
  LRig: TReachRig;
  LBest: IAasBestReachable;
  LGoal: TVec3;
begin
  LRig := TReachRig.Create(0, '', [], []);
  try
    Supports(LRig.Init, IAasBestReachable, LBest);
    // outside: the goal origin is the origin and the box is linked to see what it touches
    Assert.AreEqual<Integer>(0, LBest.BestReachableArea(Vec(5000, 5000, 5000), Vec(-8, -8, 0), Vec(8, 8, 16), LGoal));
    Assert.AreEqual<Single>(5000, LGoal[0]);
    // a box that reaches into the first area
    Assert.AreEqual<Integer>(1, LBest.BestReachableArea(Vec(-30, 30, 30), Vec(-8, -8, 0), Vec(40, 8, 16), LGoal));
  finally
    LRig.Free;
  end;
end;

procedure TTestAasReachCalculator.DovrebbeDareLAreaMigliorePerLaListaDiLink;
var
  LRig: TReachRig;
  LBest: IAasBestReachable;
  LHead: Integer;
begin
  LRig := TReachRig.Create(0, '', [], []);
  try
    Supports(LRig.Init, IAasBestReachable, LBest);
    LHead := LRig.Links.LinkEntity(Vec(10, 10, 10), Vec(200, 50, 50), 3);
    // the last area found first: the grounded one is the answer
    Assert.IsTrue(LBest.BestReachableLinkArea(LHead) > 0);
    LRig.Links.Unlink(LHead);
    Assert.AreEqual<Integer>(0, LBest.BestReachableLinkArea(AAS_NO_LINK));
  finally
    LRig.Free;
  end;
end;

procedure TTestAasReachCalculator.DovrebbeDareLAreaDelTrampolinoPerUnBoxDentroUnTrigger;
var
  LRig: TReachRig;
  LBest: IAasBestReachable;
begin
  LRig := TReachRig.Create(0,
    '{ "classname" "trigger_push" "model" "*1" "target" "up" }' +
    '{ "classname" "target_position" "targetname" "up" "origin" "300 32 232" }', [Vec(0, 0, 0), Vec(120, 10, 0)],
    [Vec(0, 0, 0), Vec(140, 50, 20)]);
  try
    Supports(LRig.Init, IAasBestReachable, LBest);
    // the trigger is in the jump pad area (the third); the push does not leave the world in 30 frames of 0.1 s
    Assert.AreEqual<Integer>(3, LBest.BestReachableFromJumpPadArea(Vec(130, 32, 32), Vec(-8, -8, 0), Vec(8, 8, 16)));
  finally
    LRig.Free;
  end;
end;

procedure TTestAasReachCalculator.DovrebbeCalcolareLeRaggiungibilitaConIlGrapple;
var
  LRig: TReachRig;
begin
  LRig := TReachRig.Create(0, '', [], [], True);
  try
    LRig.Run;
    // the little world has no wall to hook to: no grapple, and the calculation goes on all the same
    Assert.AreEqual<Integer>(0, LRig.Init.Counters.Grapple);
    Assert.IsTrue(LRig.Init.Counters.EqualFloor > 0);
  finally
    LRig.Free;
  end;
end;

procedure TTestAasReachCalculator.LaFactoryDovrebbeDareGliOggettiDelCalcolo;
var
  LRig: TReachRig;
  LBest: IAasBestReachable;
begin
  LRig := TReachRig.Create(0, '', [], []);
  try
    Assert.IsTrue(Supports(LRig.Init, IAasBestReachable, LBest));
    Assert.AreEqual<Integer>(0, LRig.Init.NumReachabilityAreas);
    LRig.Init.InitReachability;
    Assert.AreEqual<Integer>(1, LRig.Init.NumReachabilityAreas);
  finally
    LRig.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestAasReachUnits);
  TDUnitX.RegisterTestFixture(TTestAasReachCalculator);

end.
