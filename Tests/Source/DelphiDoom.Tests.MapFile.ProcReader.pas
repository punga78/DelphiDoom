{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the map file library - reading .proc files             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.MapFile.ProcReader;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.MapFile.Proc.ProcFile, DelphiDoom.MapFile.Proc.Intf;

type
  [TestFixture]
  [Category('MapFile')]
  TTestProcFileReader = class
  strict private
    FReader: IProcFileReader;
    function Parse(const AText: AnsiString): TProcFile;
    procedure ExpectError(const AText: AnsiString; const AMessagePart: string; const ALine: Integer = 0);
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure DovrebbeLeggereIModelliELeSuperfici;
    [Test]
    procedure DovrebbeLeggereIVerticiConPosizioneCoordinateENormale;
    [Test]
    procedure DovrebbeLeggereGliIndici;
    [Test]
    procedure DovrebbeLeggereLeCoordinateConLaVirgola;
    [Test]
    procedure DovrebbeLeggereIlModelloDellOmbra;
    [Test]
    procedure DovrebbeCalcolareIBoundsDelModelloDellOmbra;
    [Test]
    procedure DovrebbeLeggereIPortali;
    [Test]
    procedure DovrebbeLeggereINodi;
    [Test]
    procedure DovrebbeAccettareLeSezioniInQualsiasiOrdine;
    [Test]
    procedure DovrebbeDareUnFileVuotoPerIlSoloIdentificatore;
    [Test]
    procedure DovrebbeSegnalareLeSezioniPresenti;
    [Test]
    procedure DovrebbeTrovareIlModelloPerNomeSenzaMaiuscole;
    [Test]
    procedure DovrebbeRifiutareUnIdentificatoreSbagliato;
    [Test]
    procedure DovrebbeRifiutareUnTestoVuoto;
    [Test]
    procedure DovrebbeRifiutareUnaParolaSconosciuta;
    [Test]
    procedure DovrebbeRifiutareUnNumeroDiSuperficiNegativo;
    [Test]
    procedure DovrebbeRifiutareUnNumeroDiVerticiNegativo;
    [Test]
    procedure DovrebbeRifiutareUnContoEnorme;
    [Test]
    procedure DovrebbeRifiutareUnNumeroDiAreeNegativo;
    [Test]
    procedure DovrebbeRifiutareUnPortaleConUnaAreaFuoriIntervallo;
    [Test]
    procedure DovrebbeRifiutareUnNumeroDiNodiNegativo;
    [Test]
    procedure DovrebbeRifiutareUnaParentesiMancante;
    [Test]
    procedure DovrebbeRifiutareUnFileTroncato;
    [Test]
    procedure DovrebbeDireLaRigaDellErrore;
    [Test]
    procedure DovrebbeLeggereUnFileDalFileSystem;
    [Test]
    procedure DovrebbeSostituireLEstensioneDelNome;
    [Test]
    procedure DovrebbeDareNilSeIlFileNonEsiste;
  end;

implementation

uses
  DelphiDoom.Geometry.Vec3, DelphiDoom.Geometry.Bounds, DelphiDoom.MapFile.Proc.Types,
  DelphiDoom.MapFile.Proc.Model, DelphiDoom.MapFile.Proc.Surface, DelphiDoom.MapFile.Proc.ShadowModel,
  DelphiDoom.MapFile.Proc.Portal, DelphiDoom.MapFile.Proc.Factory, DelphiDoom.Tests.IdLib.Fakes,
  DelphiDoom.Tests.MapFile.ProcSample;

const
  HEAD = 'mapProcFile003'#10;

{ TTestProcFileReader }

procedure TTestProcFileReader.Setup;
begin
  FReader := TProcFileFactory.CreateReader(TIdLibMemoryFileSystem.Create);
end;

function TTestProcFileReader.Parse(const AText: AnsiString): TProcFile;
begin
  Result := FReader.ParseText(AText, 'test.proc');
end;

procedure TTestProcFileReader.ExpectError(const AText: AnsiString; const AMessagePart: string;
  const ALine: Integer);
var
  LFile: TProcFile;
  LRaised: Boolean;
begin
  LRaised := False;
  LFile := nil;
  try
    try
      LFile := Parse(AText);
    except
      on E: EProcFileException do
      begin
        LRaised := True;
        Assert.IsTrue(Pos(AMessagePart, E.Message) > 0, 'message: ' + E.Message);
        if ALine > 0 then
          Assert.AreEqual(ALine, E.Line);
      end;
    end;
  finally
    LFile.Free;
  end;
  Assert.IsTrue(LRaised, 'no error for: ' + string(AText));
end;

procedure TTestProcFileReader.DovrebbeLeggereIModelliELeSuperfici;
var
  LFile: TProcFile;
begin
  LFile := Parse(TProcSample.Full);
  try
    Assert.AreEqual(1, LFile.Models.Count);
    Assert.AreEqual('_area0', string(LFile.Models[0].Name));
    Assert.AreEqual(2, LFile.Models[0].NumSurfaces);
    Assert.AreEqual('textures/base/wall', string(LFile.Models[0].Surfaces[0].Material));
    Assert.AreEqual('textures/base/floor', string(LFile.Models[0].Surfaces[1].Material));
    Assert.AreEqual(4, LFile.Models[0].Surfaces[0].NumVertices);
    Assert.AreEqual(6, LFile.Models[0].Surfaces[0].NumIndexes);
    Assert.AreEqual(3, LFile.Models[0].Surfaces[1].NumVertices);
  finally
    LFile.Free;
  end;
end;

procedure TTestProcFileReader.DovrebbeLeggereIVerticiConPosizioneCoordinateENormale;
var
  LFile: TProcFile;
  LVertex: TProcVertex;
begin
  LFile := Parse(TProcSample.Full);
  try
    LVertex := LFile.Models[0].Surfaces[0].Vertices[2];
    Assert.AreEqual(64.0, Double(LVertex.Position.X), 0);
    Assert.AreEqual(64.0, Double(LVertex.Position.Y), 0);
    Assert.AreEqual(0.0, Double(LVertex.Position.Z), 0);
    Assert.AreEqual(1.0, Double(LVertex.S), 0);
    Assert.AreEqual(1.0, Double(LVertex.T), 0);
    Assert.AreEqual(0.0, Double(LVertex.Normal.X), 0);
    Assert.AreEqual(1.0, Double(LVertex.Normal.Z), 0);
  finally
    LFile.Free;
  end;
end;

procedure TTestProcFileReader.DovrebbeLeggereGliIndici;
var
  LFile: TProcFile;
begin
  LFile := Parse(TProcSample.Full);
  try
    Assert.AreEqual<TArray<Integer>>([0, 1, 2, 0, 2, 3], LFile.Models[0].Surfaces[0].Indexes);
  finally
    LFile.Free;
  end;
end;

procedure TTestProcFileReader.DovrebbeLeggereLeCoordinateConLaVirgola;
var
  LVertex: TProcVertex;
  LFile: TProcFile;
begin
  LFile := Parse(TProcSample.Full);
  try
    LVertex := LFile.Models[0].Surfaces[1].Vertices[0];
    Assert.AreEqual(0.5, Double(LVertex.Position.X), 0);
    Assert.AreEqual(0.25, Double(LVertex.Position.Y), 0);
    Assert.AreEqual(-1.0, Double(LVertex.Position.Z), 0);
    Assert.AreEqual(0.125, Double(LVertex.S), 0);
    Assert.AreEqual(2.5, Double(LVertex.T), 0);
    Assert.AreEqual(-1.0, Double(LVertex.Normal.Z), 0);
  finally
    LFile.Free;
  end;
end;

procedure TTestProcFileReader.DovrebbeLeggereIlModelloDellOmbra;
var
  LFile: TProcFile;
  LShadow: TProcShadowModel;
begin
  LFile := Parse(TProcSample.Full);
  try
    Assert.AreEqual(1, LFile.ShadowModels.Count);
    LShadow := LFile.ShadowModels[0];
    Assert.AreEqual('_prelight_light1', string(LShadow.Name));
    Assert.AreEqual(3, Length(LShadow.Vertices));
    Assert.AreEqual(3, LShadow.NumShadowIndexesNoCaps);
    Assert.AreEqual(3, LShadow.NumShadowIndexesNoFrontCaps);
    Assert.AreEqual(7, LShadow.ShadowCapPlaneBits);
    Assert.AreEqual<TArray<Integer>>([0, 1, 2], LShadow.Indexes);
    Assert.AreEqual(2.5, Double(LShadow.Vertices[2].Y), 0);
  finally
    LFile.Free;
  end;
end;

procedure TTestProcFileReader.DovrebbeCalcolareIBoundsDelModelloDellOmbra;
var
  LFile: TProcFile;
  LBounds: TGeoBounds;
begin
  LFile := Parse(TProcSample.Full);
  try
    LBounds := LFile.ShadowModels[0].Bounds;
    Assert.AreEqual(0.0, Double(LBounds.Mins.X), 0);
    Assert.AreEqual(1.0, Double(LBounds.Maxs.X), 0);
    Assert.AreEqual(2.5, Double(LBounds.Maxs.Y), 0);
  finally
    LFile.Free;
  end;
end;

procedure TTestProcFileReader.DovrebbeLeggereIPortali;
var
  LFile: TProcFile;
begin
  LFile := Parse(TProcSample.Full);
  try
    Assert.AreEqual(2, LFile.NumAreas);
    Assert.AreEqual(1, LFile.Portals.Count);
    Assert.AreEqual(4, LFile.Portals[0].NumPoints);
    Assert.AreEqual(0, LFile.Portals[0].PositiveArea);
    Assert.AreEqual(1, LFile.Portals[0].NegativeArea);
    Assert.AreEqual(64.0, Double(LFile.Portals[0].Points[2].Z), 0);
    Assert.AreEqual(64.0, Double(LFile.Portals[0].Points[1].Y), 0);
  finally
    LFile.Free;
  end;
end;

procedure TTestProcFileReader.DovrebbeLeggereINodi;
var
  LFile: TProcFile;
begin
  LFile := Parse(TProcSample.Full);
  try
    Assert.AreEqual(2, LFile.Nodes.Count);
    Assert.AreEqual(-32.5, Double(LFile.Nodes[0].Plane.D), 0);
    Assert.AreEqual(1.0, Double(LFile.Nodes[0].Plane.A), 0);
    Assert.AreEqual(1, LFile.Nodes[0].PositiveChild);
    Assert.AreEqual(-2, LFile.Nodes[0].NegativeChild);
    Assert.AreEqual(-1, LFile.Nodes[1].PositiveChild);
    Assert.AreEqual(0, LFile.Nodes[1].NegativeChild);
  finally
    LFile.Free;
  end;
end;

procedure TTestProcFileReader.DovrebbeAccettareLeSezioniInQualsiasiOrdine;
var
  LFile: TProcFile;
begin
  LFile := Parse(TProcSample.Shuffled);
  try
    Assert.AreEqual(1, LFile.Models.Count);
    Assert.AreEqual(1, LFile.ShadowModels.Count);
    Assert.AreEqual(1, LFile.Portals.Count);
    Assert.AreEqual(2, LFile.Nodes.Count);
  finally
    LFile.Free;
  end;
end;

procedure TTestProcFileReader.DovrebbeDareUnFileVuotoPerIlSoloIdentificatore;
var
  LFile: TProcFile;
begin
  LFile := Parse(HEAD);
  try
    Assert.AreEqual(0, LFile.Models.Count);
    Assert.AreEqual(0, LFile.ShadowModels.Count);
    Assert.AreEqual(0, LFile.Portals.Count);
    Assert.AreEqual(0, LFile.Nodes.Count);
    Assert.AreEqual(0, LFile.NumAreas);
  finally
    LFile.Free;
  end;
end;

procedure TTestProcFileReader.DovrebbeSegnalareLeSezioniPresenti;
var
  LFile: TProcFile;
begin
  LFile := Parse(HEAD);
  try
    Assert.IsFalse(LFile.HasPortalSection);
    Assert.IsFalse(LFile.HasNodeSection);
  finally
    LFile.Free;
  end;
  LFile := Parse(TProcSample.Full);
  try
    Assert.IsTrue(LFile.HasPortalSection);
    Assert.IsTrue(LFile.HasNodeSection);
  finally
    LFile.Free;
  end;
end;

procedure TTestProcFileReader.DovrebbeTrovareIlModelloPerNomeSenzaMaiuscole;
var
  LFile: TProcFile;
begin
  LFile := Parse(TProcSample.Full);
  try
    Assert.IsNotNull(LFile.FindModel('_AREA0'));
    Assert.IsNull(LFile.FindModel('_area1'));
    Assert.IsNotNull(LFile.FindShadowModel('_prelight_LIGHT1'));
    Assert.IsNull(LFile.FindShadowModel('x'));
  finally
    LFile.Free;
  end;
end;

procedure TTestProcFileReader.DovrebbeRifiutareUnIdentificatoreSbagliato;
begin
  ExpectError('mapProcFile002'#10, 'bad id ''mapProcFile002'' instead of ''mapProcFile003''');
end;

procedure TTestProcFileReader.DovrebbeRifiutareUnTestoVuoto;
begin
  ExpectError(#10, 'bad id');
end;

procedure TTestProcFileReader.DovrebbeRifiutareUnaParolaSconosciuta;
begin
  ExpectError(HEAD + 'portals { }'#10, 'bad token "portals"', 2);
end;

procedure TTestProcFileReader.DovrebbeRifiutareUnNumeroDiSuperficiNegativo;
begin
  ExpectError(HEAD + 'model { "_area0" -1 }'#10, 'bad numSurfaces');
end;

procedure TTestProcFileReader.DovrebbeRifiutareUnNumeroDiVerticiNegativo;
begin
  ExpectError(HEAD + 'model { "m" 1 { "mat" -3 0 } }'#10, 'bad numVerts');
end;

procedure TTestProcFileReader.DovrebbeRifiutareUnContoEnorme;
begin
  ExpectError(HEAD + 'model { "m" 1 { "mat" 2000000000 0 } }'#10, 'bad numVerts');
  ExpectError(HEAD + 'nodes { 2000000000 }'#10, 'bad numAreaNodes');
end;

procedure TTestProcFileReader.DovrebbeRifiutareUnNumeroDiAreeNegativo;
begin
  ExpectError(HEAD + 'interAreaPortals { -1 0 }'#10, 'bad numPortalAreas');
end;

procedure TTestProcFileReader.DovrebbeRifiutareUnPortaleConUnaAreaFuoriIntervallo;
begin
  ExpectError(HEAD + 'interAreaPortals { 2 1 3 0 5 ( 0 0 0 ) ( 0 1 0 ) ( 0 1 1 ) }'#10,
    'area 5 is not in 0..1');
end;

procedure TTestProcFileReader.DovrebbeRifiutareUnNumeroDiNodiNegativo;
begin
  ExpectError(HEAD + 'nodes { -2 }'#10, 'bad numAreaNodes');
end;

procedure TTestProcFileReader.DovrebbeRifiutareUnaParentesiMancante;
begin
  ExpectError(HEAD + 'nodes { 1 1 0 0 0 1 2 }'#10, 'expected');
end;

procedure TTestProcFileReader.DovrebbeRifiutareUnFileTroncato;
begin
  ExpectError(HEAD + 'model { "_area0" 1 { "m" 2 3 ( 0 0 0 0 0 0 0 1 ) ', 'couldn''t');
end;

procedure TTestProcFileReader.DovrebbeDireLaRigaDellErrore;
begin
  ExpectError(HEAD + #10#10'nodes { -2 }'#10, 'line 4', 4);
end;

procedure TTestProcFileReader.DovrebbeLeggereUnFileDalFileSystem;
var
  LFileSystem: TIdLibMemoryFileSystem;
  LFile: TProcFile;
begin
  LFileSystem := TIdLibMemoryFileSystem.Create;
  FReader := TProcFileFactory.CreateReader(LFileSystem);
  LFileSystem.SetFile('maps/game/mars.proc', TProcSample.Full);
  LFile := FReader.Parse('maps/game/mars.proc');
  try
    Assert.IsNotNull(LFile);
    Assert.AreEqual('maps/game/mars', string(LFile.Name));
    Assert.AreEqual(1, LFile.Models.Count);
  finally
    LFile.Free;
  end;
end;

procedure TTestProcFileReader.DovrebbeSostituireLEstensioneDelNome;
var
  LFileSystem: TIdLibMemoryFileSystem;
  LFile: TProcFile;
begin
  LFileSystem := TIdLibMemoryFileSystem.Create;
  FReader := TProcFileFactory.CreateReader(LFileSystem);
  LFileSystem.SetFile('maps/game/mars.proc', TProcSample.Full);
  LFile := FReader.Parse('maps/game/mars.map');
  try
    Assert.IsNotNull(LFile);
  finally
    LFile.Free;
  end;
  LFile := FReader.Parse('maps/game/mars');
  try
    Assert.IsNotNull(LFile);
  finally
    LFile.Free;
  end;
end;

procedure TTestProcFileReader.DovrebbeDareNilSeIlFileNonEsiste;
begin
  Assert.IsNull(FReader.Parse('maps/game/none'));
end;

end.
