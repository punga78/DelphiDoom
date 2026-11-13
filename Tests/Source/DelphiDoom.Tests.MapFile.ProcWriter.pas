{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the map file library - writing .proc files             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.MapFile.ProcWriter;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.MapFile.Proc.Intf, DelphiDoom.MapFile.Proc.ProcFile;

type
  [TestFixture]
  [Category('MapFile')]
  TTestProcFileWriter = class
  strict private
    FReader: IProcFileReader;
    FWriter: IProcFileWriter;
    function RoundTrip(const AText: AnsiString): AnsiString;
    function LinesOf(const AFile: TProcFile): TArray<string>;
    function FileWithSurface(const AVertexCount, AIndexCount: Integer): TProcFile;
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure DovrebbeRiscrivereIdenticoUnFileInFormatoDmap;
    [Test]
    procedure DovrebbeRiscrivereIdenticoUnFileInAltroOrdineNelloOrdineDiDmap;
    [Test]
    procedure DovrebbeRileggereCioCheHaScritto;
    [Test]
    procedure DovrebbeScrivereGliInteriSenzaDecimali;
    [Test]
    procedure DovrebbeScrivereUnNumeroVicinoAUnIntero;
    [Test]
    procedure DovrebbeScrivereIDecimaliConIlFormatoF;
    [Test]
    procedure DovrebbeScrivereTreVerticiPerRiga;
    [Test]
    procedure DovrebbeScrivereDiciottoIndiciPerRiga;
    [Test]
    procedure DovrebbeScrivereCinqueVerticiDiOmbraPerRiga;
    [Test]
    procedure DovrebbeNonScrivereLeSezioniChePortaleENodiSeMancano;
    [Test]
    procedure DovrebbeScrivereUnFileVuotoConSoloLIdentificatore;
    [Test]
    procedure DovrebbeScrivereNelFileSystemConLEstensioneProc;
    [Test]
    procedure DovrebbeDareFalsoSenzaFileSystem;
    [Test]
    procedure DovrebbeScrivereLeSuperficiNellOrdineDelModello;
  end;

implementation

uses
  DelphiDoom.Geometry.Vec3, DelphiDoom.MapFile.Proc.Types, DelphiDoom.MapFile.Proc.Model,
  DelphiDoom.MapFile.Proc.Surface, DelphiDoom.MapFile.Proc.ShadowModel, DelphiDoom.MapFile.Proc.Factory,
  DelphiDoom.Tests.IdLib.Fakes, DelphiDoom.Tests.MapFile.ProcSample;

{ TTestProcFileWriter }

procedure TTestProcFileWriter.Setup;
begin
  FReader := TProcFileFactory.CreateReader(TIdLibMemoryFileSystem.Create);
  FWriter := TProcFileFactory.CreateWriter(TIdLibMemoryFileSystem.Create);
end;

function TTestProcFileWriter.RoundTrip(const AText: AnsiString): AnsiString;
var
  LFile: TProcFile;
begin
  LFile := FReader.ParseText(AText, 'x.proc');
  try
    Result := FWriter.ToText(LFile);
  finally
    LFile.Free;
  end;
end;

procedure TTestProcFileWriter.DovrebbeRiscrivereIdenticoUnFileInFormatoDmap;
begin
  Assert.AreEqual(string(TProcSample.Full), string(RoundTrip(TProcSample.Full)));
end;

procedure TTestProcFileWriter.DovrebbeRiscrivereIdenticoUnFileInAltroOrdineNelloOrdineDiDmap;
begin
  // the order of the sections is the one of dmap (models, portals, nodes, shadow models)
  Assert.AreEqual(string(TProcSample.Full), string(RoundTrip(TProcSample.Shuffled)));
end;

procedure TTestProcFileWriter.DovrebbeRileggereCioCheHaScritto;
var
  LFirst, LSecond: TProcFile;
begin
  LFirst := FReader.ParseText(TProcSample.Full, 'x');
  try
    LSecond := FReader.ParseText(FWriter.ToText(LFirst), 'y');
    try
      Assert.AreEqual(LFirst.Models[0].Surfaces[1].Vertices[0].S, LSecond.Models[0].Surfaces[1].Vertices[0].S);
      Assert.AreEqual(LFirst.Nodes[0].Plane.D, LSecond.Nodes[0].Plane.D);
      Assert.AreEqual(LFirst.Portals[0].NumPoints, LSecond.Portals[0].NumPoints);
      Assert.AreEqual(LFirst.ShadowModels[0].ShadowCapPlaneBits, LSecond.ShadowModels[0].ShadowCapPlaneBits);
    finally
      LSecond.Free;
    end;
  finally
    LFirst.Free;
  end;
end;

procedure TTestProcFileWriter.DovrebbeScrivereGliInteriSenzaDecimali;
var
  LText: string;
begin
  LText := string(RoundTrip(TProcSample.Full));
  Assert.IsTrue(Pos('( 64 64 0 1 1 0 0 1 ) ', LText) > 0);
  Assert.AreEqual(0, Pos('64.0', LText));
end;

procedure TTestProcFileWriter.DovrebbeScrivereUnNumeroVicinoAUnIntero;
var
  LFile: TProcFile;
  LText: string;
begin
  // within 0.001 of an integer: written as that integer (dmap WriteFloat)
  LFile := FReader.ParseText('mapProcFile003'#10'nodes { 1 ( 1 0 0 0.0004 ) 0 0 }'#10, 'x');
  try
    LText := string(FWriter.ToText(LFile));
    Assert.IsTrue(Pos('( 1 0 0 0 ) 0 0', LText) > 0, LText);
  finally
    LFile.Free;
  end;
end;

procedure TTestProcFileWriter.DovrebbeScrivereIDecimaliConIlFormatoF;
var
  LFile: TProcFile;
  LText: string;
begin
  LFile := FReader.ParseText('mapProcFile003'#10'nodes { 1 ( 0.5 0.1 -0.0078125 100.002 ) 0 0 }'#10, 'x');
  try
    LText := string(FWriter.ToText(LFile));
    // %f of WriteFloatString: ten decimals, trailing zeros taken off; 0.1f is 0.1000000015
    Assert.IsTrue(Pos('( 0.5 0.1000000015 -0.0078125 100.0019989014 ) 0 0', LText) > 0, LText);
  finally
    LFile.Free;
  end;
end;

function TTestProcFileWriter.LinesOf(const AFile: TProcFile): TArray<string>;
begin
  Result := string(FWriter.ToText(AFile)).Split([#10]);
end;

function TTestProcFileWriter.FileWithSurface(const AVertexCount, AIndexCount: Integer): TProcFile;
var
  LSurface: TProcSurface;
  LVertices: TArray<TProcVertex>;
  LIndexes: TArray<Integer>;
  LIndex: Integer;
begin
  Result := TProcFile.Create;
  Result.Models.Add(TProcModel.Create('m'));
  LSurface := TProcSurface.Create;
  LSurface.Material := 'mat';
  SetLength(LVertices, AVertexCount);
  for LIndex := 0 to AVertexCount - 1 do
    LVertices[LIndex].Position := TGeoVec3.Make(LIndex, 0, 0);
  SetLength(LIndexes, AIndexCount);
  for LIndex := 0 to AIndexCount - 1 do
    LIndexes[LIndex] := LIndex mod 10;
  LSurface.Vertices := LVertices;
  LSurface.Indexes := LIndexes;
  Result.Models[0].AddSurface(LSurface);
end;

procedure TTestProcFileWriter.DovrebbeScrivereTreVerticiPerRiga;
var
  LFile: TProcFile;
  LLines: TArray<string>;
begin
  LFile := FileWithSurface(7, 0);
  try
    LLines := LinesOf(LFile);
    // 0 id, 1 empty, 2 model, 3 empty, 4 surface header, 5..7 the vertices, 8 and 9 the braces
    Assert.AreEqual(3, Length(LLines[5].Split([') ('])));
    Assert.AreEqual(3, Length(LLines[6].Split([') ('])));
    Assert.AreEqual(1, Length(LLines[7].Split([') ('])));
    Assert.AreEqual('}', LLines[8]);
  finally
    LFile.Free;
  end;
end;

procedure TTestProcFileWriter.DovrebbeScrivereDiciottoIndiciPerRiga;
var
  LFile: TProcFile;
  LLines: TArray<string>;
begin
  LFile := FileWithSurface(1, 20);
  try
    LLines := LinesOf(LFile);
    // header lines 0..4, the vertex on 5, the indexes on 6 and 7
    Assert.AreEqual('0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 ', LLines[6]);
    Assert.AreEqual('8 9 ', LLines[7]);
  finally
    LFile.Free;
  end;
end;

procedure TTestProcFileWriter.DovrebbeScrivereCinqueVerticiDiOmbraPerRiga;
var
  LFile: TProcFile;
  LShadow: TProcShadowModel;
  LVertices: TArray<TGeoVec3>;
  LLines: TArray<string>;
  LIndex: Integer;
begin
  LFile := TProcFile.Create;
  try
    LShadow := TProcShadowModel.Create('_prelight_a');
    SetLength(LVertices, 6);
    for LIndex := 0 to 5 do
      LVertices[LIndex] := TGeoVec3.Make(LIndex, 1, 2);
    LShadow.Vertices := LVertices;
    LFile.ShadowModels.Add(LShadow);
    LLines := LinesOf(LFile);
    // 0 id, 1 empty, 2 shadowModel, 3 empty, 4 the counts, 5 and 6 the vertices, 7 the closing brace
    Assert.AreEqual('( 0 1 2 ) ( 1 1 2 ) ( 2 1 2 ) ( 3 1 2 ) ( 4 1 2 ) ', LLines[5]);
    Assert.AreEqual('( 5 1 2 ) ', LLines[6]);
    Assert.AreEqual('}', LLines[7]);
  finally
    LFile.Free;
  end;
end;

procedure TTestProcFileWriter.DovrebbeNonScrivereLeSezioniChePortaleENodiSeMancano;
var
  LFile: TProcFile;
  LText: string;
begin
  LFile := FileWithSurface(0, 0);
  try
    LText := string(FWriter.ToText(LFile));
    Assert.AreEqual(0, Pos('interAreaPortals', LText));
    Assert.AreEqual(0, Pos('nodes', LText));
    Assert.IsTrue(Pos('model {', LText) > 0);
  finally
    LFile.Free;
  end;
end;

procedure TTestProcFileWriter.DovrebbeScrivereUnFileVuotoConSoloLIdentificatore;
var
  LFile: TProcFile;
begin
  LFile := TProcFile.Create;
  try
    Assert.AreEqual('mapProcFile003'#10#10, string(FWriter.ToText(LFile)));
  finally
    LFile.Free;
  end;
end;

procedure TTestProcFileWriter.DovrebbeScrivereNelFileSystemConLEstensioneProc;
var
  LFileSystem: TIdLibMemoryFileSystem;
  LFile: TProcFile;
begin
  LFileSystem := TIdLibMemoryFileSystem.Create;
  FWriter := TProcFileFactory.CreateWriter(LFileSystem);
  LFile := TProcFile.Create;
  try
    Assert.IsTrue(FWriter.Write(LFile, 'maps/game/mars.map'));
    Assert.AreEqual('mapProcFile003'#10#10, string(LFileSystem.GetFile('maps/game/mars.proc')));
  finally
    LFile.Free;
  end;
end;

procedure TTestProcFileWriter.DovrebbeDareFalsoSenzaFileSystem;
var
  LFile: TProcFile;
begin
  FWriter := TProcFileFactory.CreateWriter(nil);
  LFile := TProcFile.Create;
  try
    Assert.IsFalse(FWriter.Write(LFile, 'x'));
  finally
    LFile.Free;
  end;
end;

procedure TTestProcFileWriter.DovrebbeScrivereLeSuperficiNellOrdineDelModello;
var
  LFile: TProcFile;
  LText: string;
begin
  LFile := FileWithSurface(0, 0);
  try
    LFile.Models[0].AddSurface(TProcSurface.Create);
    LFile.Models[0].Surfaces[1].Material := 'second';
    LText := string(FWriter.ToText(LFile));
    Assert.IsTrue(Pos('/* surface 0 */ { "mat"', LText) < Pos('/* surface 1 */ { "second"', LText));
    Assert.IsTrue(Pos('/* numSurfaces = */ 2', LText) > 0);
  finally
    LFile.Free;
  end;
end;

end.

