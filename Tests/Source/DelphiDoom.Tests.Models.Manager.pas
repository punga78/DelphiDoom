{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the 3D models library - the model manager, the default }
{  model and the cleanup of the surfaces                                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Models.Manager;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.Models.Static.Types,
  DelphiDoom.Models.Static.Triangles,
  DelphiDoom.Models.Static.MaterialInfo.Intf,
  DelphiDoom.Models.Manager.Intf,
  DelphiDoom.Tests.Models.GoldenLines,
  DelphiDoom.Tests.Models.AnimSupport;

type
  /// <summary>
  ///   R_CleanupTriangles (without the silhouette edges) and the default cube against the real
  ///   functions of tr_trisurf.cpp and Model.cpp compiled with bcc32c (Tests\Data\Models\deform)
  /// </summary>
  [TestFixture]
  [Category('Deform')]
  TTestSurfaceFinisher = class
  strict private
    FGolden: TGoldenLines;
    procedure CheckTriangles(const AKey: string; const ATriangles: TStaticTriangles);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    [TestCase('striscia, normali', 'mirror,1,0')]
    [TestCase('striscia, senza normali', 'mirror,0,0')]
    [TestCase('striscia, non levigate', 'mirror,1,1')]
    [TestCase('cubo, normali', 'cube,1,0')]
    [TestCase('cubo, senza normali', 'cube,0,0')]
    [TestCase('cubo, non levigate', 'cube,1,1')]
    [TestCase('griglia, normali', 'grid,1,0')]
    [TestCase('griglia, senza normali', 'grid,0,0')]
    [TestCase('griglia, non levigate', 'grid,0,1')]
    procedure DovrebbePulireLeSuperficiComeIlCpp(const ACase: string; const ACreateNormals, AUnsmoothed: Integer);
    [Test]
    procedure DovrebbeDareIlCuboDelModelloDiDefault;
    [Test]
    procedure DovrebbeDareUnModelloVuoto;
    [Test]
    procedure DovrebbeInvertireITriangoli;
    [Test]
    procedure DovrebbeFinireUnModelloConIlRetroDelleSuperfici;
    [Test]
    procedure DovrebbeFinireUnModelloVeloceSenzaPulire;
    [Test]
    procedure DovrebbeRifiutareUnaSuperficieSenzaGeometria;
  end;

  /// <summary>TRenderModelManager with loaders that count their reads</summary>
  [TestFixture]
  [Category('Manager')]
  TTestRenderModelManager = class
  strict private
    FFiles: TFakeFiles;
    FFilesIntf: IInterface;
    FLog: TRecordingLog;
    FLogIntf: IInterface;
    FLoader: IRenderModelLoader;
    FManager: IRenderModelManager;
    FLoaderObject: TObject;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeCreareIModelliDiBase;
    [Test]
    procedure DovrebbeCaricareUnModelloUnaSolaVolta;
    [Test]
    procedure DovrebbeTrovareIlModelloSenzaDistinguereLeMaiuscole;
    [Test]
    procedure DovrebbeDareNilPerUnNomeVuoto;
    [Test]
    procedure DovrebbeDareIlModelloDiDefaultPerUnTipoSconosciuto;
    [Test]
    procedure DovrebbeNonAvvisareSeNonCeEstensione;
    [Test]
    procedure DovrebbeDareNilConCheckModelPerUnModelloDiDefault;
    [Test]
    procedure DovrebbeDareIlModelloDiDefaultPerUnFileCheNonSiLegge;
    [Test]
    procedure DovrebbeTrovareIlPiuRecenteConLoStessoNome;
    [Test]
    procedure DovrebbeRifiutareDiLiberareIModelliDiBase;
    [Test]
    procedure DovrebbeLiberareUnModello;
    [Test]
    procedure DovrebbeRicaricareSoloIModelliCambiati;
    [Test]
    procedure DovrebbeRicaricareTuttiConForceAll;
    [Test]
    procedure DovrebbePurgareIModelliNonUsatiDalLivello;
    [Test]
    procedure DovrebbeRicaricareUnModelloPurgatoMentreLoSiCerca;
    [Test]
    procedure DovrebbePurgareTuttoQuandoSiChiede;
    [Test]
    procedure DovrebbeSvuotareConShutdown;
  end;

  /// <summary>The manager with the loaders of the library on files in memory</summary>
  [TestFixture]
  [Category('Manager')]
  TTestStandardLoaders = class
  strict private
    FFiles: TFakeFiles;
    FFilesIntf: IInterface;
    FLog: TRecordingLog;
    FLogIntf: IInterface;
    FManager: IRenderModelManager;
    procedure Compose(const AMaterials: IStaticMaterialInfo);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeCaricareUnMaComeModelloStaticoFinito;
    [Test]
    procedure DovrebbeCaricareUnMd5MeshConIlSuoModello;
    [Test]
    procedure DovrebbeDareIlDefaultPerUnFileMaMalformato;
    [Test]
    procedure DovrebbeDareIlDefaultPerUnFileMd5Malformato;
    [Test]
    procedure DovrebbeDareIlDefaultPerUnFileMancante;
    [Test]
    procedure DovrebbeDareIlDefaultPerUnFormatoNonLetto;
    [Test]
    procedure DovrebbeDareIlDefaultPerUnMd3Malformato;
    [Test]
    procedure DovrebbeDareIlDefaultPerUnEstensioneRegistrataMaNonLetta;
    [Test]
    procedure DovrebbeFornireIModelliAUnaDefinizione;
    [Test]
    procedure DovrebbeLeggereUnaDefinizioneSuUnModelloCheVieneDalManager;
    [Test]
    procedure DovrebbeDirePerUnaDefinizioneSuUnModelloDiDefault;
  end;

implementation

uses
  DelphiDoom.IdLib.Math.Vec3,
  DelphiDoom.Models.Types,
  DelphiDoom.Models.Md5.Intf,
  DelphiDoom.Models.Static.Intf,
  DelphiDoom.Models.Static.Model,
  DelphiDoom.Models.Static.DefaultModel,
  DelphiDoom.Models.Static.SurfaceFinisher,
  DelphiDoom.Models.Static.ModelFinisher,
  DelphiDoom.Models.Anim.Intf,
  DelphiDoom.Models.Anim.Factory,
  DelphiDoom.Models.Manager.Model,
  DelphiDoom.Models.Manager.DefSource,
  DelphiDoom.Models.Manager.Factory,
  DelphiDoom.Tests.Models.Md5Golden;

type
  /// <summary>A loader that counts its reads and answers with an empty model</summary>
  TCountingLoader = class(TInterfacedObject, IRenderModelLoader)
  strict private
    FLoads: Integer;
    FTimeStamp: Int64;
    FDefaulted: Boolean;
  public
    function GetKind: TRenderModelKind;
    function Load(const AName: AnsiString): TRenderModelData;
    property Loads: Integer read FLoads;
    property TimeStamp: Int64 read FTimeStamp write FTimeStamp;
    property Defaulted: Boolean read FDefaulted write FDefaulted;
  end;

  /// <summary>Two sided and unsmoothed materials by name</summary>
  TFakeMaterials = class(TInterfacedObject, IStaticMaterialInfo)
  public
    function ShouldCreateBackSides(const AMaterialName: AnsiString): Boolean;
    function UseUnsmoothedTangents(const AMaterialName: AnsiString): Boolean;
  end;

function TCountingLoader.GetKind: TRenderModelKind;
begin
  Result := rmkStatic;
end;

function TCountingLoader.Load(const AName: AnsiString): TRenderModelData;
begin
  Inc(FLoads);
  Result := Default(TRenderModelData);
  Result.Static := TStaticDefaultModel.BuildEmpty(string(AName));
  Result.TimeStamp := FTimeStamp;
  Result.Defaulted := FDefaulted;
end;

function TFakeMaterials.ShouldCreateBackSides(const AMaterialName: AnsiString): Boolean;
begin
  Result := AMaterialName = 'two_sided';
end;

function TFakeMaterials.UseUnsmoothedTangents(const AMaterialName: AnsiString): Boolean;
begin
  Result := AMaterialName = 'unsmoothed';
end;

{ TTestSurfaceFinisher }

procedure TTestSurfaceFinisher.Setup;
begin
  FGolden := TGoldenLines.Create('deform\deform.golden.txt');
end;

procedure TTestSurfaceFinisher.TearDown;
begin
  FGolden.Free;
end;

procedure TTestSurfaceFinisher.CheckTriangles(const AKey: string; const ATriangles: TStaticTriangles);
var
  LExpected: TArray<Single>;
  LIndexes: TArray<Integer>;
  LIndex: Integer;

  procedure Near(const AWhat: string; const AExpectedValue, AActual: Single);
  begin
    Assert.IsTrue(TMd5Golden.Close(AExpectedValue, AActual), Format('%s %s: atteso %s, letto %s',
      [AKey, AWhat, TMd5Golden.Describe(AExpectedValue), TMd5Golden.Describe(AActual)]));
  end;

begin
  LIndexes := FGolden.Ints(AKey + ' idx');
  Assert.AreEqual<Integer>(Length(LIndexes), ATriangles.NumIndexes, AKey + ' indici');
  for LIndex := 0 to High(LIndexes) do
    Assert.AreEqual<Integer>(LIndexes[LIndex], ATriangles.Indexes[LIndex], AKey + ' indice');
  LExpected := FGolden.Floats(AKey + ' verts');
  Assert.AreEqual<Integer>(Length(LExpected), ATriangles.NumVerts * 14, AKey + ' vertexes');
  for LIndex := 0 to ATriangles.NumVerts - 1 do
  begin
    Near('x', LExpected[LIndex * 14], ATriangles.Verts[LIndex].Xyz.X);
    Near('y', LExpected[LIndex * 14 + 1], ATriangles.Verts[LIndex].Xyz.Y);
    Near('z', LExpected[LIndex * 14 + 2], ATriangles.Verts[LIndex].Xyz.Z);
    Near('s', LExpected[LIndex * 14 + 3], ATriangles.Verts[LIndex].St.X);
    Near('t', LExpected[LIndex * 14 + 4], ATriangles.Verts[LIndex].St.Y);
    Near('nx', LExpected[LIndex * 14 + 5], ATriangles.Verts[LIndex].Normal.X);
    Near('ny', LExpected[LIndex * 14 + 6], ATriangles.Verts[LIndex].Normal.Y);
    Near('nz', LExpected[LIndex * 14 + 7], ATriangles.Verts[LIndex].Normal.Z);
    Near('t0x', LExpected[LIndex * 14 + 8], ATriangles.Verts[LIndex].Tangents[0].X);
    Near('t0y', LExpected[LIndex * 14 + 9], ATriangles.Verts[LIndex].Tangents[0].Y);
    Near('t0z', LExpected[LIndex * 14 + 10], ATriangles.Verts[LIndex].Tangents[0].Z);
    Near('t1x', LExpected[LIndex * 14 + 11], ATriangles.Verts[LIndex].Tangents[1].X);
    Near('t1y', LExpected[LIndex * 14 + 12], ATriangles.Verts[LIndex].Tangents[1].Y);
    Near('t1z', LExpected[LIndex * 14 + 13], ATriangles.Verts[LIndex].Tangents[1].Z);
  end;
  LExpected := FGolden.Floats(AKey + ' bounds');
  Near('mins x', LExpected[0], ATriangles.CalcBounds.Mins.X);
  Near('mins z', LExpected[2], ATriangles.CalcBounds.Mins.Z);
  Near('maxs y', LExpected[4], ATriangles.CalcBounds.Maxs.Y);
end;

procedure TTestSurfaceFinisher.DovrebbePulireLeSuperficiComeIlCpp(const ACase: string;
  const ACreateNormals, AUnsmoothed: Integer);
var
  LValues: TArray<Single>;
  LSource: TStaticTriangles;
  LIndex: Integer;
  LKey: string;
begin
  LValues := FGolden.Floats(ACase + ' in verts');
  SetLength(LSource.Verts, Length(LValues) div 5);
  for LIndex := 0 to High(LSource.Verts) do
  begin
    LSource.Verts[LIndex].Clear;
    LSource.Verts[LIndex].Xyz := TIdVec3.Create(LValues[LIndex * 5], LValues[LIndex * 5 + 1], LValues[LIndex * 5 + 2]);
    LSource.Verts[LIndex].St.X := LValues[LIndex * 5 + 3];
    LSource.Verts[LIndex].St.Y := LValues[LIndex * 5 + 4];
  end;
  LSource.Indexes := FGolden.Ints(ACase + ' in idx');
  LKey := Format('%s cleanup %d %d', [ACase, ACreateNormals, AUnsmoothed]);
  CheckTriangles(LKey, TStaticSurfaceFinisher.Cleanup(LSource, ACreateNormals <> 0, AUnsmoothed <> 0));
end;

procedure TTestSurfaceFinisher.DovrebbeDareIlCuboDelModelloDiDefault;
var
  LModel: IStaticModel;
begin
  LModel := TStaticDefaultModel.Build('_DEFAULT');
  Assert.AreEqual('_DEFAULT', LModel.Name);
  Assert.AreEqual<Integer>(1, LModel.NumSurfaces);
  Assert.AreEqual('_default', string(LModel.Surfaces[0].MaterialName));
  Assert.IsTrue(LModel.Surfaces[0].Triangles.GenerateNormals);
  Assert.AreEqual<Integer>(FGolden.Ints('default')[0], LModel.TotalVerts);
  Assert.AreEqual<Integer>(FGolden.Ints('default')[1], LModel.TotalIndexes);
  CheckTriangles('default', LModel.Surfaces[0].Triangles);
end;

procedure TTestSurfaceFinisher.DovrebbeDareUnModelloVuoto;
var
  LModel: IStaticModel;
begin
  LModel := TStaticDefaultModel.BuildEmpty('_BEAM');
  Assert.AreEqual<Integer>(0, LModel.NumSurfaces);
  Assert.AreEqual<Integer>(0, LModel.TotalVerts);
end;

procedure TTestSurfaceFinisher.DovrebbeInvertireITriangoli;
var
  LSource, LReversed: TStaticTriangles;
begin
  LSource := TStaticDefaultModel.Build('x').Surfaces[0].Triangles;
  LReversed := TStaticSurfaceFinisher.Reverse(LSource);
  Assert.AreEqual<Integer>(LSource.Indexes[1], LReversed.Indexes[0]);
  Assert.AreEqual<Integer>(LSource.Indexes[0], LReversed.Indexes[1]);
  Assert.AreEqual<Integer>(LSource.Indexes[2], LReversed.Indexes[2]);
  Assert.AreEqual(-LSource.Verts[3].Normal.Z, LReversed.Verts[3].Normal.Z, 0.0);
end;

procedure TTestSurfaceFinisher.DovrebbeFinireUnModelloConIlRetroDelleSuperfici;
var
  LSource, LFinished: IStaticModel;
  LBuilder: TStaticModel;
begin
  LBuilder := TStaticModel.Create('m');
  LSource := LBuilder;
  LBuilder.AddSurface('two_sided');
  LBuilder.AddGeometry(0, TStaticDefaultModel.Build('x').Surfaces[0].Triangles);
  LBuilder.AddSurface('unsmoothed');
  LBuilder.AddGeometry(1, TStaticDefaultModel.Build('x').Surfaces[0].Triangles);
  LBuilder.Finish;
  LFinished := TStaticModelFinisher.Finish(LSource, TFakeMaterials.Create, False);
  Assert.AreEqual<Integer>(3, LFinished.NumSurfaces, 'la copia al rovescio e'' in coda');
  Assert.AreEqual('two_sided', string(LFinished.Surfaces[2].MaterialName));
  Assert.AreEqual<Integer>(2, LFinished.Surfaces[2].Id);
  Assert.AreEqual<Integer>(LFinished.Surfaces[0].Triangles.Indexes[1], LFinished.Surfaces[2].Triangles.Indexes[0]);
  Assert.AreEqual(1.0, LFinished.Surfaces[1].Triangles.Verts[0].Normal.Length, 0.01, 'tangenti non levigate');
  Assert.IsTrue(LFinished.Bounds.Maxs.X >= 8);
end;

procedure TTestSurfaceFinisher.DovrebbeFinireUnModelloVeloceSenzaPulire;
var
  LSource, LFinished: IStaticModel;
  LBuilder: TStaticModel;
  LTriangles: TStaticTriangles;
begin
  LTriangles := TStaticDefaultModel.Build('x').Surfaces[0].Triangles;
  LBuilder := TStaticModel.Create('m');
  LSource := LBuilder;
  LBuilder.AddSurface('two_sided');
  LBuilder.AddGeometry(0, LTriangles);
  LBuilder.Finish;
  LFinished := TStaticModelFinisher.Finish(LSource, nil, True);
  Assert.AreEqual<Integer>(1, LFinished.NumSurfaces, 'niente retro');
  Assert.AreEqual<Integer>(LTriangles.NumVerts, LFinished.TotalVerts);
end;

procedure TTestSurfaceFinisher.DovrebbeRifiutareUnaSuperficieSenzaGeometria;
var
  LBuilder: TStaticModel;
  LSource: IStaticModel;
begin
  LBuilder := TStaticModel.Create('m');
  LSource := LBuilder;
  LBuilder.AddSurface('x');
  LBuilder.Finish;
  Assert.WillRaise(
    procedure
    begin
      TStaticModelFinisher.Finish(LSource, nil, False);
    end, EStaticModelException);
end;

{ TTestRenderModelManager }

procedure TTestRenderModelManager.Setup;
var
  LTable: IRenderModelLoaderTable;
  LCounting: TCountingLoader;
begin
  FFiles := TFakeFiles.Create;
  FFilesIntf := FFiles;
  FLog := TRecordingLog.Create;
  FLogIntf := FLog;
  LCounting := TCountingLoader.Create;
  FLoaderObject := LCounting;
  FLoader := LCounting;
  FFiles.Put('a.ase', 'x');
  LTable := TRenderModelManagerFactory.CreateLoaderTable;
  LTable.Register('ase', FLoader);
  LTable.Register('.LWO', FLoader);
  FManager := TRenderModelManagerFactory.CreateManager(FFiles, LTable, FLog);
  FManager.Init;
end;

procedure TTestRenderModelManager.TearDown;
begin
  FManager := nil;
  FLoader := nil;
  FLogIntf := nil;
  FFilesIntf := nil;
end;

procedure TTestRenderModelManager.DovrebbeCreareIModelliDiBase;
begin
  Assert.AreEqual<Integer>(3, FManager.NumModels);
  Assert.AreEqual('_DEFAULT', string(FManager.GetModelAt(0).Name));
  Assert.AreEqual('_BEAM', string(FManager.GetModelAt(1).Name));
  Assert.AreEqual('_SPRITE', string(FManager.GetModelAt(2).Name));
  Assert.IsTrue(FManager.DefaultModel = FManager.GetModelAt(0));
  Assert.IsTrue(FManager.DefaultModel.IsDefaultModel);
  Assert.IsFalse(FManager.DefaultModel.IsReloadable);
  Assert.AreEqual<Integer>(Ord(rmkBeam), Ord(FManager.GetModelAt(1).Kind));
  Assert.AreEqual<Integer>(Ord(rmkSprite), Ord(FManager.GetModelAt(2).Kind));
  Assert.AreEqual<Integer>(1, FManager.DefaultModel.Static.NumSurfaces);
  Assert.AreEqual<Int64>(0, FManager.DefaultModel.TimeStamp);
  Assert.IsNull(FManager.DefaultModel.Md5);
  Assert.IsFalse(FManager.InsideLevelLoad);
end;

procedure TTestRenderModelManager.DovrebbeCaricareUnModelloUnaSolaVolta;
var
  LFirst, LSecond: IRenderModel;
begin
  LFirst := FManager.FindModel('a.ase');
  LSecond := FManager.FindModel('a.ase');
  Assert.IsTrue(LFirst = LSecond);
  Assert.AreEqual<Integer>(1, TCountingLoader(FLoaderObject).Loads);
  Assert.AreEqual<Integer>(4, FManager.NumModels);
  Assert.IsTrue(LFirst.IsReloadable);
  Assert.IsTrue(LFirst.IsLoaded);
  Assert.IsTrue(LFirst.LevelLoadReferenced);
  Assert.AreEqual<Integer>(Ord(rmkStatic), Ord(LFirst.Kind));
end;

procedure TTestRenderModelManager.DovrebbeTrovareIlModelloSenzaDistinguereLeMaiuscole;
begin
  Assert.IsTrue(FManager.FindModel('Models/A.ASE') = FManager.FindModel('models/a.ase'));
  Assert.AreEqual<Integer>(1, TCountingLoader(FLoaderObject).Loads);
  Assert.IsNotNull(FManager.FindModel('x.lwo'), 'la tabella ignora maiuscole e punto');
end;

procedure TTestRenderModelManager.DovrebbeDareNilPerUnNomeVuoto;
begin
  Assert.IsNull(FManager.FindModel(''));
  Assert.IsNull(FManager.CheckModel(''));
end;

procedure TTestRenderModelManager.DovrebbeDareIlModelloDiDefaultPerUnTipoSconosciuto;
var
  LModel: IRenderModel;
begin
  LModel := FManager.FindModel('thing.xyz');
  Assert.IsNotNull(LModel);
  Assert.IsTrue(LModel.IsDefaultModel);
  Assert.IsFalse(LModel.IsReloadable);
  Assert.AreEqual('thing.xyz', string(LModel.Name));
  Assert.AreEqual<Integer>(1, LModel.Static.NumSurfaces);
  Assert.AreEqual<Integer>(1, FLog.Count);
  Assert.IsTrue(Pos('unknown model type', FLog.Text) > 0);
  Assert.IsTrue(FManager.FindModel('THING.xyz') = LModel, 'e'' nella lista');
end;

procedure TTestRenderModelManager.DovrebbeNonAvvisareSeNonCeEstensione;
begin
  Assert.IsNotNull(FManager.FindModel('noextension'));
  Assert.AreEqual<Integer>(0, FLog.Count);
end;

procedure TTestRenderModelManager.DovrebbeDareNilConCheckModelPerUnModelloDiDefault;
begin
  Assert.IsNull(FManager.CheckModel('thing.xyz'));
  Assert.AreEqual<Integer>(3, FManager.NumModels, 'non e'' stato aggiunto');
  TCountingLoader(FLoaderObject).Defaulted := True;
  Assert.IsNull(FManager.CheckModel('b.ase'));
  Assert.AreEqual<Integer>(3, FManager.NumModels);
  TCountingLoader(FLoaderObject).Defaulted := False;
  Assert.IsNotNull(FManager.CheckModel('b.ase'));
end;

procedure TTestRenderModelManager.DovrebbeDareIlModelloDiDefaultPerUnFileCheNonSiLegge;
begin
  TCountingLoader(FLoaderObject).Defaulted := True;
  Assert.IsTrue(FManager.FindModel('b.ase').IsDefaultModel);
  Assert.AreEqual<Integer>(4, FManager.NumModels);
end;

procedure TTestRenderModelManager.DovrebbeTrovareIlPiuRecenteConLoStessoNome;
var
  LFirst, LSecond: IRenderModel;
begin
  LFirst := FManager.FindModel('a.ase');
  LSecond := TRenderModel.CreateFixed('A.ase', rmkStatic, nil, False);
  FManager.AddModel(LSecond);
  Assert.IsTrue(FManager.FindModel('a.ase') = LSecond, 'l''ultimo aggiunto per primo');
  FManager.RemoveModel(LSecond);
  Assert.IsTrue(FManager.FindModel('a.ase') = LFirst);
  FManager.RemoveModel(LSecond);
  Assert.AreEqual<Integer>(4, FManager.NumModels, 'togliere un modello che non c''e'' non fa nulla');
end;

procedure TTestRenderModelManager.DovrebbeRifiutareDiLiberareIModelliDiBase;
begin
  Assert.WillRaise(
    procedure
    begin
      FManager.FreeModel(FManager.GetModelAt(0));
    end, EModelsException);
  Assert.WillRaise(
    procedure
    begin
      FManager.FreeModel(FManager.GetModelAt(1));
    end, EModelsException);
  Assert.WillRaise(
    procedure
    begin
      FManager.FreeModel(FManager.GetModelAt(2));
    end, EModelsException);
  FManager.FreeModel(nil);
end;

procedure TTestRenderModelManager.DovrebbeLiberareUnModello;
var
  LModel: IRenderModel;
begin
  LModel := FManager.FindModel('a.ase');
  FManager.FreeModel(LModel);
  Assert.AreEqual<Integer>(3, FManager.NumModels);
  FManager.FindModel('a.ase');
  Assert.AreEqual<Integer>(2, TCountingLoader(FLoaderObject).Loads, 'caricato di nuovo');
end;

procedure TTestRenderModelManager.DovrebbeRicaricareSoloIModelliCambiati;
var
  LModel: IRenderModel;
begin
  TCountingLoader(FLoaderObject).TimeStamp := 100;
  LModel := FManager.FindModel('a.ase');
  FManager.FindModel('thing.xyz');
  // the file source answers with time stamp 0: nothing is newer
  FManager.ReloadModels(False);
  Assert.AreEqual<Integer>(1, TCountingLoader(FLoaderObject).Loads);
  Assert.AreEqual<Int64>(100, LModel.TimeStamp);
end;

procedure TTestRenderModelManager.DovrebbeRicaricareTuttiConForceAll;
begin
  FManager.FindModel('a.ase');
  FManager.FindModel('thing.xyz');
  FManager.ReloadModels(True);
  Assert.AreEqual<Integer>(2, TCountingLoader(FLoaderObject).Loads, 'solo quelli che si possono rileggere');
end;

procedure TTestRenderModelManager.DovrebbePurgareIModelliNonUsatiDalLivello;
var
  LKept, LDropped: IRenderModel;
  LCounts: TLevelLoadCounts;
begin
  LKept := FManager.FindModel('a.ase');
  LDropped := FManager.FindModel('b.lwo');
  FManager.BeginLevelLoad(False);
  Assert.IsTrue(FManager.InsideLevelLoad);
  Assert.IsFalse(LKept.LevelLoadReferenced);
  FManager.FindModel('a.ase');
  LCounts := FManager.EndLevelLoad;
  Assert.IsFalse(FManager.InsideLevelLoad);
  Assert.AreEqual<Integer>(1, LCounts.Purged);
  Assert.AreEqual<Integer>(4, LCounts.Kept, 'i tre di base e quello usato');
  Assert.AreEqual<Integer>(0, LCounts.Loaded);
  Assert.IsTrue(LKept.IsLoaded);
  Assert.IsFalse(LDropped.IsLoaded);
  Assert.IsNull(LDropped.Static);
  Assert.AreEqual<Int64>(0, LDropped.TimeStamp);
  Assert.IsTrue(FManager.DefaultModel.IsLoaded);
end;

procedure TTestRenderModelManager.DovrebbeRicaricareUnModelloPurgatoMentreLoSiCerca;
var
  LModel: IRenderModel;
begin
  LModel := FManager.FindModel('a.ase');
  LModel.PurgeModel;
  Assert.IsFalse(LModel.IsLoaded);
  Assert.IsTrue(FManager.FindModel('a.ase') = LModel);
  Assert.IsTrue(LModel.IsLoaded);
  Assert.AreEqual<Integer>(2, TCountingLoader(FLoaderObject).Loads);
end;

procedure TTestRenderModelManager.DovrebbePurgareTuttoQuandoSiChiede;
var
  LModel: IRenderModel;
  LCounts: TLevelLoadCounts;
begin
  LModel := FManager.FindModel('a.ase');
  FManager.BeginLevelLoad(True);
  Assert.IsFalse(LModel.IsLoaded);
  FManager.FindModel('a.ase');
  LCounts := FManager.EndLevelLoad;
  Assert.IsTrue(LModel.IsLoaded, 'ricaricato perche'' il livello lo usa');
  Assert.AreEqual<Integer>(0, LCounts.Loaded, 'FindModel lo ha gia'' ricaricato');
  FManager.BeginLevelLoad(True);
  LModel.LevelLoadReferenced := True;
  LCounts := FManager.EndLevelLoad;
  Assert.AreEqual<Integer>(1, LCounts.Loaded, 'EndLevelLoad carica cio'' che il livello ha toccato');
  Assert.IsTrue(LModel.IsLoaded);
end;

procedure TTestRenderModelManager.DovrebbeSvuotareConShutdown;
begin
  FManager.FindModel('a.ase');
  FManager.Shutdown;
  Assert.AreEqual<Integer>(0, FManager.NumModels);
  Assert.IsNull(FManager.DefaultModel);
end;

{ TTestStandardLoaders }

procedure TTestStandardLoaders.Setup;
begin
  FFiles := TFakeFiles.Create;
  FFilesIntf := FFiles;
  FLog := TRecordingLog.Create;
  FLogIntf := FLog;
  Compose(nil);
end;

procedure TTestStandardLoaders.Compose(const AMaterials: IStaticMaterialInfo);
begin
  FManager := TRenderModelManagerFactory.CreateManager(FFiles,
    TRenderModelManagerFactory.CreateStandardLoaders(FFiles, TStaticLoadOptions.Default, nil,
      AMaterials, FLog), FLog);
  FManager.Init;
end;

procedure TTestStandardLoaders.TearDown;
begin
  FManager := nil;
  FLogIntf := nil;
  FFilesIntf := nil;
end;

procedure TTestStandardLoaders.DovrebbeCaricareUnMaComeModelloStaticoFinito;
var
  LModel: IRenderModel;
  LTriangles: TStaticTriangles;
begin
  FFiles.Put('models/quad.ma', MaDataFile('quad.ma'));
  LModel := FManager.FindModel('models/quad.ma');
  Assert.IsFalse(LModel.IsDefaultModel, FLog.Text);
  Assert.IsTrue(LModel.IsReloadable);
  Assert.AreEqual<Integer>(1, LModel.Static.NumSurfaces);
  LTriangles := LModel.Static.Surfaces[0].Triangles;
  Assert.AreEqual<Integer>(5, LTriangles.NumVerts);
  Assert.AreEqual(1.0, LTriangles.Verts[0].Tangents[0].Length, 0.01, 'tangenti derivate dal manager');
  Assert.IsNull(LModel.Md5);
end;

procedure TTestStandardLoaders.DovrebbeCaricareUnMd5MeshConIlSuoModello;
var
  LModel: IRenderModel;
begin
  FFiles.Put('models/cube.md5mesh', CubeModelText);
  LModel := FManager.FindModel('models/cube.md5mesh');
  Assert.IsFalse(LModel.IsDefaultModel, FLog.Text);
  Assert.AreEqual<Integer>(Ord(rmkMd5), Ord(LModel.Kind));
  Assert.AreEqual<Integer>(2, LModel.Md5.NumJoints);
  Assert.IsNull(LModel.Static);
end;

procedure TTestStandardLoaders.DovrebbeDareIlDefaultPerUnFileMaMalformato;
var
  LModel: IRenderModel;
begin
  FFiles.Put('bad.ma', 'createNode mesh -n "m";' + #10 + 'connectAttr "nodot" "x.y";');
  LModel := FManager.FindModel('bad.ma');
  Assert.IsTrue(LModel.IsDefaultModel);
  Assert.IsTrue(LModel.IsReloadable, 'viene da un file');
  Assert.AreEqual<Integer>(1, LModel.Static.NumSurfaces);
  Assert.IsTrue(Pos('Invalid Connect Attribute', FLog.Text) > 0);
  Assert.IsTrue(Pos('Couldn''t load model', FLog.Text) > 0);
end;

procedure TTestStandardLoaders.DovrebbeDareIlDefaultPerUnFileMd5Malformato;
begin
  FFiles.Put('bad.md5mesh', 'MD5Version 10 numJoints x');
  Assert.IsTrue(FManager.FindModel('bad.md5mesh').IsDefaultModel);
  Assert.IsTrue(Pos('Couldn''t load model', FLog.Text) > 0);
end;

procedure TTestStandardLoaders.DovrebbeDareIlDefaultPerUnFileMancante;
begin
  Assert.IsTrue(FManager.FindModel('missing.lwo').IsDefaultModel);
  Assert.IsTrue(FManager.FindModel('missing.md5mesh').IsDefaultModel);
  Assert.AreEqual<Integer>(2, FLog.Count);
end;

procedure TTestStandardLoaders.DovrebbeDareIlDefaultPerUnFormatoNonLetto;
begin
  FFiles.Put('fx.prt', 'x');
  Assert.IsTrue(FManager.FindModel('fx.prt').IsDefaultModel);
  Assert.IsFalse(FManager.FindModel('fx.prt').IsReloadable);
end;

procedure TTestStandardLoaders.DovrebbeDareIlDefaultPerUnMd3Malformato;
begin
  // a file that is not an MD3 gives the default model, not an exception
  FFiles.Put('x.md3', 'IDP3');
  Assert.IsTrue(FManager.FindModel('x.md3').IsDefaultModel);
end;

procedure TTestStandardLoaders.DovrebbeDareIlDefaultPerUnEstensioneRegistrataMaNonLetta;
var
  LTable: IRenderModelLoaderTable;
begin
  LTable := TRenderModelManagerFactory.CreateStandardLoaders(FFiles, TStaticLoadOptions.Default, nil, nil, FLog);
  LTable.Register('dat', LTable.Find('ase'));
  FManager := TRenderModelManagerFactory.CreateManager(FFiles, LTable, FLog);
  FManager.Init;
  FFiles.Put('x.dat', 'data');
  Assert.IsTrue(FManager.FindModel('x.dat').IsDefaultModel);
  Assert.IsTrue(Pos('unknown type for model', FLog.Text) > 0);
end;

procedure TTestStandardLoaders.DovrebbeFornireIModelliAUnaDefinizione;
var
  LSource: IModelDefSource;
  LDefaulted: Boolean;
  LModel: IMd5Model;
  LDef: IModelDef;
begin
  FFiles.Put('cube.md5mesh', CubeModelText);
  LSource := TRenderModelManagerFactory.CreateModelDefSource(FManager, nil);
  LModel := LSource.FindMd5Model('cube.md5mesh', LDefaulted);
  Assert.IsNotNull(LModel);
  Assert.IsFalse(LDefaulted);
  Assert.IsNull(LSource.FindMd5Model('nowhere.md5mesh', LDefaulted));
  Assert.IsTrue(LDefaulted);
  Assert.IsNull(LSource.FindMd5Model('', LDefaulted));
  Assert.IsFalse(LDefaulted);
  Assert.IsNull(LSource.FindModelDef('x', LDefaulted));
  LSource := TRenderModelManagerFactory.CreateModelDefSource(FManager,
    function(const AName: AnsiString; out ADefaulted: Boolean): IModelDef
    begin
      ADefaulted := True;
      Result := nil;
    end);
  LDef := LSource.FindModelDef('x', LDefaulted);
  Assert.IsNull(LDef);
  Assert.IsTrue(LDefaulted);
end;

procedure TTestStandardLoaders.DovrebbeLeggereUnaDefinizioneSuUnModelloCheVieneDalManager;
var
  LAnims: IAnimManager;
  LParser: IModelDefParser;
  LDef: IModelDef;
begin
  FFiles.Put('cube.md5mesh', CubeModelText);
  FFiles.Put('cube.md5anim', CubeAnimText);
  LAnims := TAnimFactory.CreateManager(FFiles, FLog);
  LParser := TAnimFactory.CreateModelDefParser(TRenderModelManagerFactory.CreateModelDefSource(FManager, nil), LAnims,
    nil, FLog);
  LDef := LParser.Parse('m', 'm { mesh cube.md5mesh anim idle1 cube.md5anim }');
  Assert.IsFalse(LDef.Defaulted, FLog.Text);
  Assert.AreEqual<Integer>(2, LDef.NumJoints);
  Assert.AreEqual<Integer>(2, LDef.NumAnims);
end;

procedure TTestStandardLoaders.DovrebbeDirePerUnaDefinizioneSuUnModelloDiDefault;
var
  LAnims: IAnimManager;
  LParser: IModelDefParser;
begin
  LAnims := TAnimFactory.CreateManager(FFiles, FLog);
  LParser := TAnimFactory.CreateModelDefParser(TRenderModelManagerFactory.CreateModelDefSource(FManager, nil), LAnims,
    nil, FLog);
  Assert.IsTrue(LParser.Parse('m', 'm { mesh gone.md5mesh }').Defaulted);
  Assert.IsTrue(Pos('defaulted', FLog.Text) > 0);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestSurfaceFinisher);
  TDUnitX.RegisterTestFixture(TTestRenderModelManager);
  TDUnitX.RegisterTestFixture(TTestStandardLoaders);

end.
