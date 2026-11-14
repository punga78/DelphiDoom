{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the map file library - the areas of a .proc file, with }
{  the parity of the real PointInArea and BoundsInAreas (proc_area.golden.txt) }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.MapFile.ProcAreaLocator;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.MapFile.Proc.ProcFile,
  DelphiDoom.MapFile.Proc.Intf;

type
  [TestFixture]
  [Category('MapFile')]
  TTestProcAreaLocator = class
  strict private
    FFile: TProcFile;
    FLocator: IProcAreaLocator;
    FSeed: Cardinal;
    function DataFolder: string;
    procedure LoadNodes;
    function NextRandom: Cardinal;
    procedure AddNode(const AA, AB, AC, AD: Single; const APositive, ANegative: Integer);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    /// <summary>
    ///   proc_area.golden.txt is what the real PointInArea and BoundsInAreas print for the tree
    ///   of proc_nodes.txt: 343 points and 300 boxes (a generator xorshift32 with a fixed seed)
    /// </summary>
    [Test]
    procedure DovrebbeDareLeStesseRisposteDelVeroRenderWorld;
    [Test]
    procedure DovrebbeDareMenoUnoSenzaNodi;
    [Test]
    procedure DovrebbeDareMenoUnoNelSolido;
    [Test]
    procedure DovrebbeDareLAreaDelleFoglieNegative;
    [Test]
    procedure DovrebbeNonContareDueVolteUnaArea;
    [Test]
    procedure DovrebbeFermarsiAlMassimoDelleAree;
    [Test]
    procedure DovrebbeDareZeroAreeSenzaNodi;
    [Test]
    procedure DovrebbeFarCrescereLArray;
    [Test]
    procedure DovrebbeRifiutareUnFiglioCheNonEUnNodo;
    [Test]
    procedure DovrebbeRifiutareUnAreaFuoriDalNumero;
    [Test]
    procedure DovrebbeRifiutareUnCicloDiNodi;
    [Test]
    procedure DovrebbeCrearePerMezzoDellaFactory;
  end;

implementation

uses
  System.IOUtils, DelphiDoom.Geometry.Vec3, DelphiDoom.Geometry.Bounds, DelphiDoom.Geometry.Plane,
  DelphiDoom.MapFile.Proc.Types, DelphiDoom.MapFile.Proc.Factory;

{ TTestProcAreaLocator }

procedure TTestProcAreaLocator.Setup;
begin
  FFile := TProcFile.Create;
  FLocator := TProcFileFactory.CreateAreaLocator(FFile);
  FSeed := 12345;
end;

procedure TTestProcAreaLocator.TearDown;
begin
  FLocator := nil;
  FFile.Free;
end;

function TTestProcAreaLocator.DataFolder: string;
begin
  Result := ExpandFileName(ExtractFilePath(ParamStr(0)) + '..\..\..\..\Tests\Data\MapFile\');
end;

function TTestProcAreaLocator.NextRandom: Cardinal;
begin
  FSeed := FSeed xor (FSeed shl 13);
  FSeed := FSeed xor (FSeed shr 17);
  FSeed := FSeed xor (FSeed shl 5);
  Result := FSeed;
end;

procedure TTestProcAreaLocator.AddNode(const AA, AB, AC, AD: Single; const APositive, ANegative: Integer);
var
  LNode: TProcNode;
begin
  LNode.Plane := TGeoPlane.Make(AA, AB, AC, AD);
  LNode.PositiveChild := APositive;
  LNode.NegativeChild := ANegative;
  FFile.Nodes.Add(LNode);
end;

procedure TTestProcAreaLocator.LoadNodes;
var
  LLines: TStringList;
  LLine: string;
  LParts: TArray<string>;
  LFormat: TFormatSettings;
begin
  LFormat := TFormatSettings.Invariant;
  LLines := TStringList.Create;
  try
    Assert.IsTrue(TFile.Exists(DataFolder + 'proc_nodes.txt'), 'proc_nodes.txt not found in ' + DataFolder);
    LLines.LoadFromFile(DataFolder + 'proc_nodes.txt');
    for LLine in LLines do
    begin
      if (Trim(LLine) = '') or LLine.StartsWith('#') then
        Continue;
      LParts := Trim(LLine).Split([' ']);
      if LParts[0] = 'areas' then
        FFile.NumAreas := StrToInt(LParts[1])
      else
        AddNode(StrToFloat(LParts[0], LFormat), StrToFloat(LParts[1], LFormat), StrToFloat(LParts[2], LFormat),
          StrToFloat(LParts[3], LFormat), StrToInt(LParts[4]), StrToInt(LParts[5]));
    end;
  finally
    LLines.Free;
  end;
end;

procedure TTestProcAreaLocator.DovrebbeDareLeStesseRisposteDelVeroRenderWorld;
const
  VALUES: array[0..6] of Single = (-70, -30, 0.05, 10, 45, 100, 130);
var
  LGolden: TStringList;
  LActual: TStringList;
  LI, LJ, LK, LIndex, LMaxAreas, LCount: Integer;
  LCenterX, LCenterY, LCenterZ, LHalfX, LHalfY, LHalfZ: Integer;
  LAreas: TArray<Integer>;
  LLine: string;
begin
  LoadNodes;
  LGolden := TStringList.Create;
  LActual := TStringList.Create;
  try
    Assert.IsTrue(TFile.Exists(DataFolder + 'proc_area.golden.txt'), 'proc_area.golden.txt not found');
    LGolden.LoadFromFile(DataFolder + 'proc_area.golden.txt');
    LIndex := 0;
    for LI := 0 to 6 do
      for LJ := 0 to 6 do
        for LK := 0 to 6 do
        begin
          LActual.Add(Format('P %d %d', [LIndex, FLocator.PointInArea(TGeoVec3.Make(VALUES[LI], VALUES[LJ], VALUES[LK]))]));
          Inc(LIndex);
        end;
    for LIndex := 0 to 299 do
    begin
      // the order of the calls of the driver: cx, cy, cz, then hx, hy, hz
      LCenterX := Integer(NextRandom mod 241) - 120;
      LCenterY := Integer(NextRandom mod 241) - 120;
      LCenterZ := Integer(NextRandom mod 241) - 120;
      LHalfX := 1 + Integer(NextRandom mod 60);
      LHalfY := 1 + Integer(NextRandom mod 60);
      LHalfZ := 1 + Integer(NextRandom mod 60);
      LMaxAreas := 1 + (LIndex mod 5) * 2;
      SetLength(LAreas, 16);
      LCount := FLocator.BoundsInAreas(TGeoBounds.Make(
        TGeoVec3.Make(LCenterX - LHalfX, LCenterY - LHalfY, LCenterZ - LHalfZ),
        TGeoVec3.Make(LCenterX + LHalfX, LCenterY + LHalfY, LCenterZ + LHalfZ)), LAreas, LMaxAreas);
      LLine := Format('B %d %d %d', [LIndex, LMaxAreas, LCount]);
      for LK := 0 to LCount - 1 do
        LLine := LLine + ' ' + IntToStr(LAreas[LK]);
      LActual.Add(LLine);
    end;
    Assert.AreEqual<Integer>(643, LGolden.Count, 'lines of the golden file');
    Assert.AreEqual<Integer>(LGolden.Count, LActual.Count);
    for LIndex := 0 to LGolden.Count - 1 do
      Assert.AreEqual(LGolden[LIndex], LActual[LIndex], 'line ' + IntToStr(LIndex + 1));
  finally
    LActual.Free;
    LGolden.Free;
  end;
end;

procedure TTestProcAreaLocator.DovrebbeDareMenoUnoSenzaNodi;
begin
  Assert.AreEqual<Integer>(-1, FLocator.PointInArea(TGeoVec3.Origin));
end;

procedure TTestProcAreaLocator.DovrebbeDareMenoUnoNelSolido;
begin
  FFile.NumAreas := 1;
  AddNode(1, 0, 0, 0, 0, -1);
  Assert.AreEqual<Integer>(-1, FLocator.PointInArea(TGeoVec3.Make(5, 0, 0)));
  Assert.AreEqual<Integer>(0, FLocator.PointInArea(TGeoVec3.Make(-5, 0, 0)));
  // a point on the plane is at its back
  Assert.AreEqual<Integer>(0, FLocator.PointInArea(TGeoVec3.Make(0, 0, 0)));
end;

procedure TTestProcAreaLocator.DovrebbeDareLAreaDelleFoglieNegative;
begin
  FFile.NumAreas := 3;
  AddNode(1, 0, 0, 0, -3, 1);
  AddNode(0, 1, 0, 0, -2, -1);
  Assert.AreEqual<Integer>(2, FLocator.PointInArea(TGeoVec3.Make(1, 0, 0)));
  Assert.AreEqual<Integer>(1, FLocator.PointInArea(TGeoVec3.Make(-1, 1, 0)));
  Assert.AreEqual<Integer>(0, FLocator.PointInArea(TGeoVec3.Make(-1, -1, 0)));
end;

procedure TTestProcAreaLocator.DovrebbeNonContareDueVolteUnaArea;
var
  LAreas: TArray<Integer>;
begin
  FFile.NumAreas := 2;
  AddNode(1, 0, 0, 0, -1, -1);
  SetLength(LAreas, 4);
  Assert.AreEqual<Integer>(1, FLocator.BoundsInAreas(TGeoBounds.Make(TGeoVec3.Make(-1, 0, 0),
    TGeoVec3.Make(1, 1, 1)), LAreas, 4));
  Assert.AreEqual<Integer>(0, LAreas[0]);
end;

procedure TTestProcAreaLocator.DovrebbeFermarsiAlMassimoDelleAree;
var
  LAreas: TArray<Integer>;
begin
  FFile.NumAreas := 2;
  AddNode(1, 0, 0, 0, -1, -2);
  SetLength(LAreas, 4);
  Assert.AreEqual<Integer>(1, FLocator.BoundsInAreas(TGeoBounds.Make(TGeoVec3.Make(-5, 0, 0),
    TGeoVec3.Make(5, 1, 1)), LAreas, 1));
  // the back is visited first
  Assert.AreEqual<Integer>(1, LAreas[0]);
  Assert.AreEqual<Integer>(2, FLocator.BoundsInAreas(TGeoBounds.Make(TGeoVec3.Make(-5, 0, 0),
    TGeoVec3.Make(5, 1, 1)), LAreas, 4));
  Assert.AreEqual<Integer>(0, LAreas[1]);
end;

procedure TTestProcAreaLocator.DovrebbeDareZeroAreeSenzaNodi;
var
  LAreas: TArray<Integer>;
begin
  Assert.AreEqual<Integer>(0, FLocator.BoundsInAreas(TGeoBounds.Make(TGeoVec3.Origin, TGeoVec3.Make(1, 1, 1)), LAreas, 4));
end;

procedure TTestProcAreaLocator.DovrebbeFarCrescereLArray;
var
  LAreas: TArray<Integer>;
begin
  FFile.NumAreas := 1;
  AddNode(1, 0, 0, 0, -1, -1);
  Assert.AreEqual<Integer>(1, FLocator.BoundsInAreas(TGeoBounds.Make(TGeoVec3.Make(2, 0, 0),
    TGeoVec3.Make(3, 1, 1)), LAreas, 3));
  Assert.AreEqual<Integer>(3, Length(LAreas));
end;

procedure TTestProcAreaLocator.DovrebbeRifiutareUnFiglioCheNonEUnNodo;
var
  LRaised: Boolean;
begin
  FFile.NumAreas := 1;
  AddNode(1, 0, 0, 0, 7, -1);
  LRaised := False;
  try
    FLocator.PointInArea(TGeoVec3.Make(5, 0, 0));
  except
    on E: EProcFileException do
      LRaised := True;
  end;
  Assert.IsTrue(LRaised);
end;

procedure TTestProcAreaLocator.DovrebbeRifiutareUnAreaFuoriDalNumero;
var
  LRaised: Boolean;
  LAreas: TArray<Integer>;
begin
  FFile.NumAreas := 1;
  AddNode(1, 0, 0, 0, -5, -1);
  LRaised := False;
  try
    FLocator.PointInArea(TGeoVec3.Make(5, 0, 0));
  except
    on E: EProcFileException do
      LRaised := E.Message.Contains('out of range');
  end;
  Assert.IsTrue(LRaised, 'point');
  LRaised := False;
  try
    FLocator.BoundsInAreas(TGeoBounds.Make(TGeoVec3.Make(5, 0, 0), TGeoVec3.Make(6, 1, 1)), LAreas, 2);
  except
    on E: EProcFileException do
      LRaised := True;
  end;
  Assert.IsTrue(LRaised, 'bounds');
end;

procedure TTestProcAreaLocator.DovrebbeRifiutareUnCicloDiNodi;
var
  LRaised: Boolean;
  LAreas: TArray<Integer>;
begin
  FFile.NumAreas := 1;
  AddNode(1, 0, 0, 0, 1, 1);
  // node 1 leads to itself
  AddNode(0, 1, 0, 0, 1, 1);
  LRaised := False;
  try
    FLocator.PointInArea(TGeoVec3.Make(1, 0, 0));
  except
    on E: EProcFileException do
      LRaised := True;
  end;
  Assert.IsTrue(LRaised, 'point');
  LRaised := False;
  try
    FLocator.BoundsInAreas(TGeoBounds.Make(TGeoVec3.Make(-1, 0, 0), TGeoVec3.Make(1, 1, 1)), LAreas, 2);
  except
    on E: EProcFileException do
      LRaised := True;
  end;
  Assert.IsTrue(LRaised, 'bounds');
end;

procedure TTestProcAreaLocator.DovrebbeCrearePerMezzoDellaFactory;
begin
  Assert.IsNotNull(TProcFileFactory.CreateAreaLocator(FFile));
end;

end.
