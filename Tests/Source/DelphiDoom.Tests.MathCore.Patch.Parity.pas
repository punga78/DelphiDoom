{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the math core library - patches of Quake III Arena:    }
{  parity with the real tr_curve.c                                             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.MathCore.Patch.Parity;

{$Q-}
{$R-}

interface

uses
  System.Classes, System.Generics.Collections, DUnitX.TestFramework;

type
  /// <summary>
  ///   Parity with the real R_SubdividePatchToGrid, R_GridInsertColumn and R_GridInsertRow of
  ///   Quake III Arena (Tests\Data\MathCore\patch.golden.txt, written by Tools\Verifica\117
  ///   with the lines of tr_curve.c compiled by gcc). The patches are the ones of
  ///   Tools\Verifica\117\gridgen.c, rebuilt here with the same generators; the answer of
  ///   every case is its size, the error tables, bounds, origin, radius, an FNV-1a hash of all
  ///   the vertices and three of them, all as the bits of the floats: the comparison is exact.
  /// </summary>
  [TestFixture]
  [Category('mathcore')]
  TTestPatchParity = class(TObject)
  private
    FGolden: TDictionary<string, string>;
    FActual: TDictionary<string, string>;
    procedure CheckCases(const APrefixes: array of string);
  public
    [SetupFixture]
    procedure SetupFixture;
    [TearDownFixture]
    procedure TearDownFixture;
    [Test]
    procedure LePatchPianeEQuelleDegenerateDovrebberoDareLeStesseRispostePerIlC;
    [Test]
    procedure LeCurveDovrebberoDareLaStessaGrigliaPerIlC;
    [Test]
    procedure LeSuperficiChiuseDovrebberoDareLeStesseNormaliPerIlC;
    [Test]
    procedure IlLimiteDellaGrigliaDovrebbeDareLeStesseRispostePerIlC;
    [Test]
    procedure LePatchCasualiDovrebberoDareLeStesseRispostePerIlC;
    [Test]
    procedure ColonneERigheInseriteDovrebberoDareLeStesseRispostePerIlC;
    [Test]
    procedure IlNumeroDeiCasiDovrebbeEssereQuelloDelGolden;
  end;

implementation

uses
  System.SysUtils, System.IOUtils, DelphiDoom.IdLib.Math.Vec3,
  DelphiDoom.MathCore.Patch.Factory, DelphiDoom.MathCore.Patch.Intf,
  DelphiDoom.MathCore.Patch.Types;

type
  TScenarioRunner = class
  strict private
    FSeed: Cardinal;
    FPoints: TArray<TPatchVertex>;
    FOutput: TDictionary<string, string>;
    function NextRandom: Cardinal;
    procedure SetVertex(const AIndex, AColumn, ARow, AWidth, AHeight: Integer;
      const AX, AY, AZ: Single);
    procedure MakeBulge(const AWidth, AHeight: Integer; const AA, AB: Single);
    procedure MakeRandom(const AWidth, AHeight, ARange: Integer);
    procedure Record_(const AName: string; const AGrid: IPatchGrid);
    function Subdivide(const AName: string; const AWidth, AHeight: Integer;
      const ASubdivisions: Single): IPatchGrid;
  public
    constructor Create(const AOutput: TDictionary<string, string>);
    procedure Run;
  end;

function Bits(const AValue: Single): Cardinal;
begin
  Result := PCardinal(@AValue)^;
end;

function Hex(const AValue: Cardinal): string;
begin
  Result := LowerCase(IntToHex(AValue, 8));
end;

function FnvByte(const AHash, AByte: Cardinal): Cardinal;
begin
  Result := (AHash xor (AByte and 255)) * 16777619;
end;

function FnvFloat(AHash: Cardinal; const AValue: Single): Cardinal;
var
  LBits: Cardinal;
begin
  LBits := Bits(AValue);
  AHash := FnvByte(AHash, LBits);
  AHash := FnvByte(AHash, LBits shr 8);
  AHash := FnvByte(AHash, LBits shr 16);
  Result := FnvByte(AHash, LBits shr 24);
end;

function VertexLine(const ATag: string; const AIndex: Integer; const AVertex: TPatchVertex): string;
begin
  Result := Format('%s %d %s %s %s %s %s %s %s %s %s %s %s%s%s%s', [ATag, AIndex,
    Hex(Bits(AVertex.Position.X)), Hex(Bits(AVertex.Position.Y)), Hex(Bits(AVertex.Position.Z)),
    Hex(Bits(AVertex.TexCoord.X)), Hex(Bits(AVertex.TexCoord.Y)),
    Hex(Bits(AVertex.Lightmap.X)), Hex(Bits(AVertex.Lightmap.Y)),
    Hex(Bits(AVertex.Normal.X)), Hex(Bits(AVertex.Normal.Y)), Hex(Bits(AVertex.Normal.Z)),
    LowerCase(IntToHex(AVertex.Color[0], 2)), LowerCase(IntToHex(AVertex.Color[1], 2)),
    LowerCase(IntToHex(AVertex.Color[2], 2)), LowerCase(IntToHex(AVertex.Color[3], 2))]);
end;

{ TScenarioRunner }

constructor TScenarioRunner.Create(const AOutput: TDictionary<string, string>);
begin
  inherited Create;
  FOutput := AOutput;
  SetLength(FPoints, MAX_PATCH_SIZE * MAX_PATCH_SIZE);
end;

function TScenarioRunner.NextRandom: Cardinal;
begin
  FSeed := FSeed xor (FSeed shl 13);
  FSeed := FSeed xor (FSeed shr 17);
  FSeed := FSeed xor (FSeed shl 5);
  Result := FSeed;
end;

procedure TScenarioRunner.SetVertex(const AIndex, AColumn, ARow, AWidth, AHeight: Integer;
  const AX, AY, AZ: Single);
var
  LVertex: TPatchVertex;
  LValue: Single;
begin
  LVertex.Position.SetValues(AX, AY, AZ);
  LValue := Single(AColumn) / Single(AWidth - 1);
  LVertex.TexCoord.X := LValue;
  LValue := Single(ARow) / Single(AHeight - 1);
  LVertex.TexCoord.Y := LValue;
  LValue := LVertex.TexCoord.X * 0.5;
  LVertex.Lightmap.X := LValue;
  LValue := LVertex.TexCoord.Y * 0.5;
  LVertex.Lightmap.Y := LValue;
  LVertex.Normal.Zero;
  LVertex.Color[0] := Byte((AColumn * 37 + ARow * 91) and 255);
  LVertex.Color[1] := Byte((AColumn * 11 + ARow * 53 + 7) and 255);
  LVertex.Color[2] := Byte(255 - ((AColumn * 29 + ARow * 13) and 255));
  LVertex.Color[3] := Byte(((AColumn + ARow) * 17) and 255);
  FPoints[AIndex] := LVertex;
end;

procedure TScenarioRunner.MakeBulge(const AWidth, AHeight: Integer; const AA, AB: Single);
var
  LI, LJ: Integer;
  LFirst, LSecond, LZ: Single;
begin
  for LJ := 0 to AHeight - 1 do
    for LI := 0 to AWidth - 1 do
    begin
      LFirst := 0;
      LSecond := 0;
      if LI mod 2 = 1 then
        LFirst := AA;
      if LJ mod 2 = 1 then
        LSecond := AB;
      LZ := LFirst + LSecond;
      SetVertex(LJ * AWidth + LI, LI, LJ, AWidth, AHeight, LI * 64, LJ * 64, LZ);
    end;
end;

procedure TScenarioRunner.MakeRandom(const AWidth, AHeight, ARange: Integer);
var
  LI, LJ: Integer;
  LX, LY, LZ, LBaseX, LBaseY: Single;
begin
  for LJ := 0 to AHeight - 1 do
    for LI := 0 to AWidth - 1 do
    begin
      LX := (Integer(NextRandom mod 2049) - 1024) / 8.0;
      LY := (Integer(NextRandom mod 2049) - 1024) / 8.0;
      LZ := (Integer(NextRandom mod Cardinal(ARange * 2 + 1)) - ARange) / 8.0;
      LBaseX := LI * 64;
      LBaseY := LJ * 64;
      LBaseX := LBaseX + LX;
      LBaseY := LBaseY + LY;
      SetVertex(LJ * AWidth + LI, LI, LJ, AWidth, AHeight, LBaseX, LBaseY, LZ);
    end;
end;

procedure TScenarioRunner.Record_(const AName: string; const AGrid: IPatchGrid);
var
  LText: TStringList;
  LCount, LIndex: Integer;
  LHash: Cardinal;
  LVertex: TPatchVertex;
  LLine: string;
begin
  LText := TStringList.Create;
  try
    if AGrid = nil then
      LText.Add('case ' + AName + ' null')
    else
    begin
      LCount := AGrid.Width * AGrid.Height;
      LHash := 2166136261;
      for LIndex := 0 to LCount - 1 do
      begin
        LVertex := AGrid.Vertices[LIndex];
        LHash := FnvFloat(LHash, LVertex.Position.X);
        LHash := FnvFloat(LHash, LVertex.Position.Y);
        LHash := FnvFloat(LHash, LVertex.Position.Z);
        LHash := FnvFloat(LHash, LVertex.TexCoord.X);
        LHash := FnvFloat(LHash, LVertex.TexCoord.Y);
        LHash := FnvFloat(LHash, LVertex.Lightmap.X);
        LHash := FnvFloat(LHash, LVertex.Lightmap.Y);
        LHash := FnvFloat(LHash, LVertex.Normal.X);
        LHash := FnvFloat(LHash, LVertex.Normal.Y);
        LHash := FnvFloat(LHash, LVertex.Normal.Z);
        LHash := FnvByte(LHash, LVertex.Color[0]);
        LHash := FnvByte(LHash, LVertex.Color[1]);
        LHash := FnvByte(LHash, LVertex.Color[2]);
        LHash := FnvByte(LHash, LVertex.Color[3]);
      end;
      LText.Add(Format('case %s %d %d %s', [AName, AGrid.Width, AGrid.Height, Hex(LHash)]));
      LLine := 'we';
      for LIndex := 0 to AGrid.Width - 1 do
        LLine := LLine + ' ' + Hex(Bits(AGrid.WidthLodError[LIndex]));
      LText.Add(LLine);
      LLine := 'he';
      for LIndex := 0 to AGrid.Height - 1 do
        LLine := LLine + ' ' + Hex(Bits(AGrid.HeightLodError[LIndex]));
      LText.Add(LLine);
      LText.Add(Format('bounds %s %s %s %s %s %s', [Hex(Bits(AGrid.BoundsMin.X)),
        Hex(Bits(AGrid.BoundsMin.Y)), Hex(Bits(AGrid.BoundsMin.Z)), Hex(Bits(AGrid.BoundsMax.X)),
        Hex(Bits(AGrid.BoundsMax.Y)), Hex(Bits(AGrid.BoundsMax.Z))]));
      LText.Add(Format('origin %s %s %s radius %s lod %s %s %s %s', [Hex(Bits(AGrid.LocalOrigin.X)),
        Hex(Bits(AGrid.LocalOrigin.Y)), Hex(Bits(AGrid.LocalOrigin.Z)), Hex(Bits(AGrid.MeshRadius)),
        Hex(Bits(AGrid.LodOrigin.X)), Hex(Bits(AGrid.LodOrigin.Y)), Hex(Bits(AGrid.LodOrigin.Z)),
        Hex(Bits(AGrid.LodRadius))]));
      LText.Add(VertexLine('first', 0, AGrid.Vertices[0]));
      LText.Add(VertexLine('mid', LCount div 2, AGrid.Vertices[LCount div 2]));
      LText.Add(VertexLine('last', LCount - 1, AGrid.Vertices[LCount - 1]));
    end;
    FOutput.AddOrSetValue(AName, Trim(LText.Text));
  finally
    LText.Free;
  end;
end;

function TScenarioRunner.Subdivide(const AName: string; const AWidth, AHeight: Integer;
  const ASubdivisions: Single): IPatchGrid;
begin
  Result := TPatchFactory.CreateSubdivider(ASubdivisions).SubdividePatchToGrid(AWidth, AHeight,
    FPoints);
  Record_(AName, Result);
end;

procedure TScenarioRunner.Run;
const
  SUBDIVISIONS: array[0..4] of Single = (1, 2, 4, 8, 16);
  SIZES: array[0..5] of Integer = (3, 5, 7, 9, 11, 17);
  RING: array[0..4, 0..1] of Single = ((64, 0), (64, 64), (-64, 64), (-64, -64), (64, 0));
var
  LGrid, LGrid2: IPatchGrid;
  LEditor: IPatchGridEditor;
  LCase, LWidth, LHeight, LI, LJ, LRange, LOldWidth, LOldHeight: Integer;
  LName: string;
begin
  MakeBulge(3, 3, 0, 0);
  Subdivide('flat3x3', 3, 3, 4);

  MakeBulge(3, 3, 96, 48);
  Subdivide('arc3x3_s4', 3, 3, 4);
  Subdivide('arc3x3_s1', 3, 3, 1);
  Subdivide('arc3x3_s16', 3, 3, 16);
  Subdivide('arc3x3_s0', 3, 3, 0);

  MakeBulge(3, 5, 128, -96);
  Subdivide('w3h5', 3, 5, 2);
  MakeBulge(5, 3, 128, -96);
  Subdivide('w5h3', 5, 3, 2);
  MakeBulge(9, 9, 300, 200);
  Subdivide('w9h9', 9, 9, 1);
  MakeBulge(3, 3, 6000, 6000);
  Subdivide('huge3x3', 3, 3, 0.25);

  MakeBulge(5, 3, 0, 90);
  Subdivide('flatrows', 5, 3, 4);
  MakeBulge(3, 5, 90, 0);
  Subdivide('flatcols', 3, 5, 4);

  LWidth := 5;
  LHeight := 3;
  for LJ := 0 to LHeight - 1 do
    for LI := 0 to LWidth - 1 do
      SetVertex(LJ * LWidth + LI, LI, LJ, LWidth, LHeight, RING[LI, 0], RING[LI, 1], LJ * 64);
  Subdivide('wrapwidth', LWidth, LHeight, 4);
  LWidth := 3;
  LHeight := 5;
  for LJ := 0 to LHeight - 1 do
    for LI := 0 to LWidth - 1 do
      SetVertex(LJ * LWidth + LI, LI, LJ, LWidth, LHeight, RING[LJ, 0], RING[LJ, 1], LI * 64);
  Subdivide('wrapheight', LWidth, LHeight, 4);

  for LI := 0 to 8 do
    SetVertex(LI, LI mod 3, LI div 3, 3, 3, 10, 20, 30);
  Subdivide('point3x3', 3, 3, 4);

  for LJ := 0 to 2 do
    for LI := 0 to 2 do
      SetVertex(LJ * 3 + LI, LI, LJ, 3, 3, LI * 64, 0, 0);
  Subdivide('line3x3', 3, 3, 4);

  FSeed := $2545F491;
  MakeRandom(31, 31, 4000);
  Subdivide('limit31', 31, 31, 1);
  MakeRandom(31, 3, 4000);
  Subdivide('limit32x3', 31, 3, 1);

  FSeed := $12345678;
  for LCase := 0 to 23 do
  begin
    LWidth := SIZES[NextRandom mod 6];
    LHeight := SIZES[NextRandom mod 6];
    if LWidth > 11 then
      LWidth := 11;
    LRange := 200 + Integer(NextRandom mod 600);
    MakeRandom(LWidth, LHeight, LRange);
    LName := Format('random%.2d_%dx%d', [LCase, LWidth, LHeight]);
    Subdivide(LName, LWidth, LHeight, SUBDIVISIONS[NextRandom mod 5]);
  end;

  LEditor := TPatchFactory.CreateGridEditor;
  MakeBulge(3, 3, 96, 48);
  LGrid := Subdivide('arc_for_insert', 3, 3, 4);
  LGrid2 := LEditor.InsertColumn(LGrid, 2, 1, TIdVec3.Create(70.5, 31.25, 12.0), 0.5);
  Record_('insertcol_2_1', LGrid2);
  LGrid2 := LEditor.InsertRow(LGrid2, 1, 2, TIdVec3.Create(-8.0, 4.5, 9.0), 0.25);
  Record_('insertrow_1_2', LGrid2);
  LGrid2 := LEditor.InsertColumn(LGrid2, 3, 3, TIdVec3.Create(1.0, 2.0, 3.0), 0.125);
  Record_('insertcol_3_3', LGrid2);

  MakeRandom(31, 31, 4000);
  LGrid := Subdivide('limit31_b', 31, 31, 1);
  LOldWidth := LGrid.Width;
  LOldHeight := LGrid.Height;
  LGrid2 := LEditor.InsertColumn(LGrid, 2, 1, TIdVec3.Create(0, 0, 0), 1);
  if LOldWidth >= MAX_GRID_SIZE then
    Record_('insertcol_full', LGrid2)
  else
    Record_('insertcol_notfull', LGrid2);
  LGrid := TPatchFactory.CreateSubdivider(1).SubdividePatchToGrid(31, 31, FPoints);
  LGrid2 := LEditor.InsertRow(LGrid, 2, 1, TIdVec3.Create(0, 0, 0), 1);
  if LOldHeight >= MAX_GRID_SIZE then
    Record_('insertrow_full', LGrid2)
  else
    Record_('insertrow_notfull', LGrid2);
end;

{ TTestPatchParity }

procedure TTestPatchParity.SetupFixture;
var
  LLines: TStringList;
  LRunner: TScenarioRunner;
  LLine, LName, LBlock: string;
  LParts: TArray<string>;
begin
  FGolden := TDictionary<string, string>.Create;
  FActual := TDictionary<string, string>.Create;
  LLines := TStringList.Create;
  try
    LLines.LoadFromFile(TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)),
      '..\..\Tests\Data\MathCore\patch.golden.txt')));
    LName := '';
    LBlock := '';
    for LLine in LLines do
    begin
      if LLine.StartsWith('case ') then
      begin
        if LName <> '' then
          FGolden.AddOrSetValue(LName, Trim(LBlock));
        LParts := LLine.Split([' ']);
        LName := LParts[1];
        LBlock := LLine;
      end
      else if LLine.StartsWith('limit31 width') then
        Continue
      else if LName <> '' then
        LBlock := LBlock + sLineBreak + LLine;
    end;
    if LName <> '' then
      FGolden.AddOrSetValue(LName, Trim(LBlock));
  finally
    LLines.Free;
  end;
  LRunner := TScenarioRunner.Create(FActual);
  try
    LRunner.Run;
  finally
    LRunner.Free;
  end;
end;

procedure TTestPatchParity.TearDownFixture;
begin
  FGolden.Free;
  FActual.Free;
end;

procedure TTestPatchParity.CheckCases(const APrefixes: array of string);
var
  LName, LPrefix, LActual: string;
  LChecked: Integer;
  LMatches: Boolean;
begin
  LChecked := 0;
  for LName in FGolden.Keys do
  begin
    LMatches := False;
    for LPrefix in APrefixes do
      if LName.StartsWith(LPrefix) then
        LMatches := True;
    if not LMatches then
      Continue;
    Inc(LChecked);
    Assert.IsTrue(FActual.TryGetValue(LName, LActual), 'caso non prodotto: ' + LName);
    Assert.AreEqual(FGolden[LName], LActual, 'caso ' + LName);
  end;
  Assert.IsTrue(LChecked > 0, 'nessun caso con questo prefisso');
end;

procedure TTestPatchParity.LePatchPianeEQuelleDegenerateDovrebberoDareLeStesseRispostePerIlC;
begin
  CheckCases(['flat', 'point3x3', 'line3x3']);
end;

procedure TTestPatchParity.LeCurveDovrebberoDareLaStessaGrigliaPerIlC;
begin
  CheckCases(['arc3x3', 'w3h5', 'w5h3', 'w9h9', 'huge3x3']);
end;

procedure TTestPatchParity.LeSuperficiChiuseDovrebberoDareLeStesseNormaliPerIlC;
begin
  CheckCases(['wrapwidth', 'wrapheight']);
end;

procedure TTestPatchParity.IlLimiteDellaGrigliaDovrebbeDareLeStesseRispostePerIlC;
begin
  CheckCases(['limit3', 'insertcol_full', 'insertrow_full']);
end;

procedure TTestPatchParity.LePatchCasualiDovrebberoDareLeStesseRispostePerIlC;
begin
  CheckCases(['random']);
end;

procedure TTestPatchParity.ColonneERigheInseriteDovrebberoDareLeStesseRispostePerIlC;
begin
  CheckCases(['insertcol_2_1', 'insertrow_1_2', 'insertcol_3_3']);
end;

procedure TTestPatchParity.IlNumeroDeiCasiDovrebbeEssereQuelloDelGolden;
begin
  Assert.AreEqual<Integer>(FGolden.Count, FActual.Count - 2 {arc_for_insert, limit31_b});
end;

initialization
  TDUnitX.RegisterTestFixture(TTestPatchParity);

end.
