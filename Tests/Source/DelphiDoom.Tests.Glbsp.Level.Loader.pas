{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the level loader of the glbsp port                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Glbsp.Level.Loader;

interface

uses
  System.Classes,
  System.IOUtils,
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.Glbsp.Level.Data,
  DelphiDoom.Glbsp.Level.Loader,
  DelphiDoom.Glbsp.Level.Raw,
  DelphiDoom.Glbsp.Level.Types,
  DelphiDoom.Glbsp.Wad.Document,
  DelphiDoom.Glbsp.Wad.Types;

type
  [TestFixture]
  [Category('glbsp')]
  TTestGlbspLevelLoader = class(TObject)
  private
    FWad: TGlbspWad;
    FData: TGlbspLevelData;
    FLoader: TGlbspLevelLoader;
    FInput: TBytesStream;
    procedure LoadSample;
    function LoadTiny(const AExtraLumps: array of string): Boolean;
    function BuildWad(const ANames: array of string;
      const ADatas: array of TBytes): TBytesStream;
    function RecordBytes(const ARecord; const ASize: Integer): TBytes;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestLeggeIlLivelloDiProva;
    [Test]
    procedure TestIConteggiDeiRiferimentiSonoCoerenti;
    [Test]
    procedure TestLeggeINodiEsistenti;
    [Test]
    procedure TestIlLivelloDiProvaHaGiaINodi;
    [Test]
    procedure TestSenzaVerticiSollevaEccezione;
    [Test]
    procedure TestLineaDiLunghezzaZeroESettoreCondiviso;
    [Test]
    procedure TestSidedefMancanteEOnSpecial;
    [Test]
    procedure TestSenzaThingSiAvvisaSenzaErrore;
    [Test]
    procedure TestIndiceDiVerticeInesistenteSollevaEccezione;
  end;

implementation

function MapSamplePath: string;
begin
  Result := TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)),
    '..\..\Tests\Data\glbsp_map01.wad'));
end;

{ TTestGlbspLevelLoader }

procedure TTestGlbspLevelLoader.Setup;
begin
  FWad := TGlbspWad.Create;
  FData := TGlbspLevelData.Create;
  FLoader := TGlbspLevelLoader.Create(FWad, FData);
end;

procedure TTestGlbspLevelLoader.TearDown;
begin
  FLoader.Free;
  FData.Free;
  FWad.Free;
  FInput.Free;
end;

function TTestGlbspLevelLoader.RecordBytes(const ARecord; const ASize: Integer): TBytes;
begin
  SetLength(Result, ASize);
  Move(ARecord, Result[0], ASize);
end;

function TTestGlbspLevelLoader.BuildWad(const ANames: array of string;
  const ADatas: array of TBytes): TBytesStream;
var
  LHeader: TRawWadHeader;
  LEntry: TRawWadEntry;
  LIndex: Integer;
  LCharIndex: Integer;
  LPositions: array of Integer;
begin
  Result := TBytesStream.Create;
  LHeader.MagicType := 'PWAD';
  LHeader.NumEntries := Length(ANames);
  LHeader.DirStart := 0;
  Result.WriteBuffer(LHeader, SizeOf(LHeader));
  SetLength(LPositions, Length(ANames));
  for LIndex := 0 to High(ANames) do
  begin
    LPositions[LIndex] := Result.Position;
    if Length(ADatas[LIndex]) > 0 then
      Result.WriteBuffer(ADatas[LIndex][0], Length(ADatas[LIndex]));
  end;
  LHeader.DirStart := Result.Position;
  for LIndex := 0 to High(ANames) do
  begin
    FillChar(LEntry, SizeOf(LEntry), 0);
    LEntry.Start := LPositions[LIndex];
    LEntry.Length := Length(ADatas[LIndex]);
    for LCharIndex := 1 to Length(ANames[LIndex]) do
      LEntry.Name[LCharIndex - 1] := AnsiChar(ANames[LIndex][LCharIndex]);
    Result.WriteBuffer(LEntry, SizeOf(LEntry));
  end;
  Result.Position := 0;
  Result.WriteBuffer(LHeader, SizeOf(LHeader));
  Result.Position := 0;
end;

procedure TTestGlbspLevelLoader.LoadSample;
var
  LFile: TFileStream;
begin
  FInput := TBytesStream.Create;
  LFile := TFileStream.Create(MapSamplePath, fmOpenRead or fmShareDenyNone);
  try
    FInput.CopyFrom(LFile, 0);
  finally
    LFile.Free;
  end;
  FWad.ReadFromStream(FInput, True, False);
  FWad.FindNextLevel;
end;

// A level of two vertices, one sector, one sidedef and one linedef from the
// first to the second vertex. The vertices coincide when the first lump of
// AExtraLumps is 'ZEROLEN'; 'NOTHINGS' leaves out the THINGS lump
function TTestGlbspLevelLoader.LoadTiny(const AExtraLumps: array of string): Boolean;
var
  LVertices: array[0..1] of TRawVertex;
  LSector: TRawSector;
  LSide: TRawSidedef;
  LLine: TRawLinedef;
  LThing: TRawThing;
  LZero: Boolean;
  LNoThings: Boolean;
  LIndex: Integer;
  LNames: TArray<string>;
  LDatas: TArray<TBytes>;
begin
  LZero := False;
  LNoThings := False;
  for LIndex := 0 to High(AExtraLumps) do
  begin
    if AExtraLumps[LIndex] = 'ZEROLEN' then
      LZero := True;
    if AExtraLumps[LIndex] = 'NOTHINGS' then
      LNoThings := True;
  end;

  LVertices[0].X := 10;
  LVertices[0].Y := 20;
  LVertices[1].X := 10;
  LVertices[1].Y := 20;
  if not LZero then
    LVertices[1].X := 110;
  FillChar(LSector, SizeOf(LSector), 0);
  LSector.Tag := 950;
  FillChar(LSide, SizeOf(LSide), 0);
  LSide.Sector := 0;
  FillChar(LLine, SizeOf(LLine), 0);
  LLine.Start := 0;
  LLine.EndVertex := 1;
  LLine.LineType := 5;
  LLine.Sidedef1 := 0;
  LLine.Sidedef2 := $FFFF;
  FillChar(LThing, SizeOf(LThing), 0);
  LThing.ThingType := 1;

  LNames := TArray<string>.Create('MAP01', 'THINGS', 'LINEDEFS', 'SIDEDEFS', 'VERTEXES', 'SECTORS');
  LDatas := TArray<TBytes>.Create(nil, RecordBytes(LThing, SizeOf(LThing)),
    RecordBytes(LLine, SizeOf(LLine)), RecordBytes(LSide, SizeOf(LSide)),
    RecordBytes(LVertices, SizeOf(LVertices)), RecordBytes(LSector, SizeOf(LSector)));
  if LNoThings then
    LDatas[1] := nil;

  FInput := BuildWad(LNames, LDatas);
  FWad.ReadFromStream(FInput, True, False);
  Result := FWad.FindNextLevel;
end;

procedure TTestGlbspLevelLoader.TestLeggeIlLivelloDiProva;
begin
  if not TFile.Exists(MapSamplePath) then
  begin
    Assert.Pass('Tests\Data\glbsp_map01.wad not found');
    Exit;
  end;
  LoadSample;

  FLoader.GetVertices;
  FLoader.GetSectors;
  FLoader.GetSidedefs;
  FLoader.GetLinedefs;
  FLoader.GetThings;

  Assert.AreEqual(1189, FData.Vertices.Count);
  Assert.AreEqual(1189, FData.NumNormalVert);
  Assert.AreEqual(0, FData.NumGlVert);
  Assert.AreEqual(211, FData.Sectors.Count);
  Assert.AreEqual(2041, FData.Sidedefs.Count);
  Assert.AreEqual(1274, FData.Linedefs.Count);
  Assert.AreEqual(200, FData.Things.Count);
  Assert.AreEqual(1188, FData.LookupVertex(1188).Index);
  Assert.AreEqual(-1, FData.LookupSector(0).WarnedFacing);
end;

procedure TTestGlbspLevelLoader.TestIConteggiDeiRiferimentiSonoCoerenti;
var
  LVertex: TGlbspVertex;
  LSide: TGlbspSidedef;
  LSector: TGlbspSector;
  LLine: TGlbspLinedef;
  LVertexRefs: Integer;
  LSideRefs: Integer;
  LSectorRefs: Integer;
  LExpectedSideRefs: Integer;
begin
  if not TFile.Exists(MapSamplePath) then
  begin
    Assert.Pass('Tests\Data\glbsp_map01.wad not found');
    Exit;
  end;
  LoadSample;
  FLoader.GetVertices;
  FLoader.GetSectors;
  FLoader.GetSidedefs;
  FLoader.GetLinedefs;

  LVertexRefs := 0;
  for LVertex in FData.Vertices do
    Inc(LVertexRefs, LVertex.RefCount);
  LSideRefs := 0;
  for LSide in FData.Sidedefs do
    Inc(LSideRefs, LSide.RefCount);
  LSectorRefs := 0;
  for LSector in FData.Sectors do
    Inc(LSectorRefs, LSector.RefCount);
  LExpectedSideRefs := 0;
  for LLine in FData.Linedefs do
  begin
    if Assigned(LLine.Right) then
      Inc(LExpectedSideRefs);
    if Assigned(LLine.Left) then
      Inc(LExpectedSideRefs);
  end;

  // Each linedef uses two vertices, each sidedef points to one sector
  Assert.AreEqual(2 * FData.Linedefs.Count, LVertexRefs);
  Assert.AreEqual(LExpectedSideRefs, LSideRefs);
  Assert.AreEqual(FData.Sidedefs.Count, LSectorRefs);
end;

procedure TTestGlbspLevelLoader.TestLeggeINodiEsistenti;
var
  LNode: TGlbspNode;
  LLinked: Integer;
begin
  if not TFile.Exists(MapSamplePath) then
  begin
    Assert.Pass('Tests\Data\glbsp_map01.wad not found');
    Exit;
  end;
  LoadSample;

  FLoader.GetStaleNodes;

  // 19516 bytes / 28 bytes per node
  Assert.AreEqual(697, FData.StaleNodes.Count);
  LLinked := 0;
  for LNode in FData.StaleNodes do
  begin
    if Assigned(LNode.R.Node) then
      Inc(LLinked);
    if Assigned(LNode.L.Node) then
      Inc(LLinked);
  end;
  // Every node but the root is the child of another node
  Assert.AreEqual(FData.StaleNodes.Count - 1, LLinked);
end;

procedure TTestGlbspLevelLoader.TestIlLivelloDiProvaHaGiaINodi;
begin
  if not TFile.Exists(MapSamplePath) then
  begin
    Assert.Pass('Tests\Data\glbsp_map01.wad not found');
    Exit;
  end;
  LoadSample;

  Assert.IsTrue(FLoader.CheckForNormalNodes);
end;

procedure TTestGlbspLevelLoader.TestSenzaVerticiSollevaEccezione;
begin
  FInput := BuildWad(['MAP01', 'THINGS', 'LINEDEFS', 'SIDEDEFS', 'SECTORS'],
    [nil, nil, nil, nil, nil]);
  FWad.ReadFromStream(FInput, True, False);
  FWad.FindNextLevel;

  Assert.WillRaise(
    procedure
    begin
      FLoader.GetVertices;
    end, EGlbspLevelException);
  Assert.IsFalse(FLoader.CheckForNormalNodes);
end;

procedure TTestGlbspLevelLoader.TestLineaDiLunghezzaZeroESettoreCondiviso;
var
  LLine: TGlbspLinedef;
begin
  Assert.IsTrue(LoadTiny(['ZEROLEN']));
  FLoader.GetVertices;
  FLoader.GetSectors;
  FLoader.GetSidedefs;
  FLoader.GetLinedefs;

  LLine := FData.LookupLinedef(0);

  Assert.IsTrue(LLine.ZeroLength);
  Assert.IsFalse(LLine.IsPrecious);
  Assert.IsFalse(LLine.SelfRef);
  Assert.IsTrue(FData.LookupSector(0).Coalesce);
  Assert.AreEqual(2, FData.LookupVertex(0).RefCount + FData.LookupVertex(1).RefCount);
end;

procedure TTestGlbspLevelLoader.TestSidedefMancanteEOnSpecial;
var
  LLine: TGlbspLinedef;
begin
  Assert.IsTrue(LoadTiny([]));
  FLoader.GetVertices;
  FLoader.GetSectors;
  FLoader.GetSidedefs;
  FLoader.GetLinedefs;

  LLine := FData.LookupLinedef(0);

  Assert.IsFalse(LLine.ZeroLength);
  Assert.IsNotNull(LLine.Right);
  Assert.IsNull(LLine.Left);
  Assert.AreEqual(1, LLine.Right.OnSpecial);
  Assert.AreEqual(1, LLine.Right.RefCount);
  Assert.AreEqual(1, FData.LookupSector(0).RefCount);
end;

procedure TTestGlbspLevelLoader.TestSenzaThingSiAvvisaSenzaErrore;
begin
  Assert.IsTrue(LoadTiny(['NOTHINGS']));

  FLoader.GetThings;

  Assert.AreEqual(0, FData.Things.Count);
  Assert.AreEqual(1, FWad.Warnings.Count);
  Assert.Contains(FWad.Warnings[0], 'Couldn''t find any Things!');
end;

procedure TTestGlbspLevelLoader.TestIndiceDiVerticeInesistenteSollevaEccezione;
var
begin
  Assert.IsTrue(LoadTiny([]));
  FLoader.GetVertices;
  FLoader.GetSectors;
  FLoader.GetSidedefs;
  // The linedef points to the vertex 1: keep only one vertex
  FData.Vertices.Delete(1);

  Assert.WillRaise(
    procedure
    begin
      FLoader.GetLinedefs;
    end, EGlbspLevelException);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestGlbspLevelLoader);

end.
