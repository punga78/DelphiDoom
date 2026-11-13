{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TGeoDrawVert (idDrawVert)                              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Geometry.DrawVert;

{$Q-}
{$R-}

interface

uses
  DUnitX.TestFramework;

type
  /// <summary>
  ///   The draw vertex: hand worked values and parity with the real idDrawVert of Doom 3
  ///   (Tests\Data\Geometry\surface.golden.txt, lines dv_*)
  /// </summary>
  [TestFixture]
  [Category('geometry')]
  TTestGeometryDrawVert = class(TObject)
  public
    [Test]
    procedure DovrebbeAvereLeStesseDimensioniDelCpp;
    [Test]
    procedure ClearDovrebbeAzzerareTuttiICampi;
    [Test]
    procedure GliIndiciDovrebberoDareLeCinqueCoordinate;
    [Test]
    procedure IlColoreDovrebbeEssereLittleEndian;
    [Test]
    procedure LerpDovrebbeInterpolarePosizioneETextureSenzaToccareIlResto;
    [Test]
    procedure LerpAllDovrebbeInterpolareTuttiICampiETroncareIlColore;
    [Test]
    procedure NormalizeDovrebbeDareUnaBaseOrtogonale;
    [Test]
    procedure LerpDovrebbeDareLeStesseRispostePerIlCpp;
    [Test]
    procedure LerpAllDovrebbeDareLeStesseRispostePerIlCpp;
    [Test]
    procedure NormalizeDovrebbeDareLeStesseRispostePerIlCpp;
    [Test]
    procedure IlColoreEGliIndiciDovrebberoDareLeStesseRispostePerIlCpp;
  end;

implementation

uses
  System.SysUtils, System.Classes, DelphiDoom.IdLib.Math.Vec2, DelphiDoom.Geometry.Vec3,
  DelphiDoom.Geometry.DrawVert, DelphiDoom.Tests.Geometry.Golden;

function MakeVert(AX, AY, AZ, AU, AV: Single): TGeoDrawVert;
begin
  Result.Clear;
  Result.Xyz := TGeoVec3.Make(AX, AY, AZ);
  Result.St := TIdVec2.Create(AU, AV);
end;

procedure TTestGeometryDrawVert.DovrebbeAvereLeStesseDimensioniDelCpp;
begin
  Assert.AreEqual(60, SizeOf(TGeoDrawVert));
end;

procedure TTestGeometryDrawVert.ClearDovrebbeAzzerareTuttiICampi;
var
  LVertex: TGeoDrawVert;
begin
  LVertex := MakeVert(1, 2, 3, 4, 5);
  LVertex.Normal := TGeoVec3.Make(1, 1, 1);
  LVertex.SetColor($01020304);
  LVertex.Clear;
  Assert.AreEqual<Single>(0, LVertex.Xyz.Y);
  Assert.AreEqual<Single>(0, LVertex.St.X);
  Assert.AreEqual<Single>(0, LVertex.Normal.Z);
  Assert.AreEqual<Cardinal>(0, LVertex.GetColor);
end;

procedure TTestGeometryDrawVert.GliIndiciDovrebberoDareLeCinqueCoordinate;
var
  LVertex: TGeoDrawVert;
  LIndex: Integer;
begin
  LVertex := MakeVert(1, 2, 3, 4, 5);
  for LIndex := 0 to 4 do
    Assert.AreEqual<Single>(LIndex + 1, LVertex[LIndex]);
  LVertex[3] := 9;
  LVertex[0] := 8;
  Assert.AreEqual<Single>(9, LVertex.St.X);
  Assert.AreEqual<Single>(8, LVertex.Xyz.X);
end;

procedure TTestGeometryDrawVert.IlColoreDovrebbeEssereLittleEndian;
var
  LVertex: TGeoDrawVert;
begin
  LVertex.Clear;
  LVertex.SetColor($44332211);
  Assert.AreEqual(Integer($11), Integer(LVertex.Color[0]));
  Assert.AreEqual(Integer($44), Integer(LVertex.Color[3]));
  Assert.AreEqual<Cardinal>($44332211, LVertex.GetColor);
end;

procedure TTestGeometryDrawVert.LerpDovrebbeInterpolarePosizioneETextureSenzaToccareIlResto;
var
  LFirst, LSecond, LResult: TGeoDrawVert;
begin
  LFirst := MakeVert(0, 0, 0, 0, 0);
  LSecond := MakeVert(2, 4, 6, 1, 1);
  LSecond.Normal := TGeoVec3.Make(1, 0, 0);
  LResult.Clear;
  LResult.Lerp(LFirst, LSecond, 0.5);
  Assert.AreEqual<Single>(1, LResult.Xyz.X);
  Assert.AreEqual<Single>(3, LResult.Xyz.Z);
  Assert.AreEqual<Single>(0.5, LResult.St.Y);
  Assert.AreEqual<Single>(0, LResult.Normal.X);
end;

procedure TTestGeometryDrawVert.LerpAllDovrebbeInterpolareTuttiICampiETroncareIlColore;
var
  LFirst, LSecond, LResult: TGeoDrawVert;
begin
  LFirst := MakeVert(0, 0, 0, 0, 0);
  LSecond := MakeVert(2, 0, 0, 0, 0);
  LSecond.Normal := TGeoVec3.Make(1, 0, 0);
  LSecond.Tangents[1] := TGeoVec3.Make(0, 4, 0);
  LFirst.Color[0] := 10;
  LSecond.Color[0] := 21;
  LResult.Clear;
  LResult.LerpAll(LFirst, LSecond, 0.5);
  Assert.AreEqual<Single>(0.5, LResult.Normal.X);
  Assert.AreEqual<Single>(2, LResult.Tangents[1].Y);
  // 10 + 0.5 * 11 = 15.5, truncated
  Assert.AreEqual(15, Integer(LResult.Color[0]));
end;

procedure TTestGeometryDrawVert.NormalizeDovrebbeDareUnaBaseOrtogonale;
var
  LVertex: TGeoDrawVert;
begin
  LVertex.Clear;
  LVertex.Normal := TGeoVec3.Make(0, 0, 5);
  LVertex.Tangents[0] := TGeoVec3.Make(3, 0, 1);
  LVertex.Normalize;
  AssertNear(1, LVertex.Normal.Z, 1E-5);
  AssertNear(0, LVertex.Normal.Dot(LVertex.Tangents[0]), 1E-5);
  AssertNear(0, LVertex.Normal.Dot(LVertex.Tangents[1]), 1E-5);
  AssertNear(0, LVertex.Tangents[0].Dot(LVertex.Tangents[1]), 1E-5);
  AssertNear(1, LVertex.Tangents[1].Length, 1E-5);
end;

procedure TTestGeometryDrawVert.LerpDovrebbeDareLeStesseRispostePerIlCpp;
var
  LLines: TStringList;
  LLine: string;
  LReader: TGeoGoldenReader;
  LFirst, LSecond, LResult: TGeoDrawVert;
  LFraction: Single;
  LWriter: TGeoGoldenWriter;
begin
  LLines := TGeoGolden.Load('surface.golden.txt', ['dv_lerp']);
  try
    Assert.IsTrue(LLines.Count > 0);
    for LLine in LLines do
    begin
      LReader := TGeoGoldenReader.Open(LLine);
      LFirst := LReader.DrawVert;
      LSecond := LReader.DrawVert;
      LFraction := LReader.Float;
      LResult.Clear;
      LResult.Lerp(LFirst, LSecond, LFraction);
      LWriter := TGeoGoldenWriter.Create;
      try
        LWriter.DrawVert(LResult);
        TGeoGolden.CompareOutput(LLine, LWriter.Text);
      finally
        LWriter.Free;
      end;
    end;
  finally
    LLines.Free;
  end;
end;

procedure TTestGeometryDrawVert.LerpAllDovrebbeDareLeStesseRispostePerIlCpp;
var
  LLines: TStringList;
  LLine: string;
  LReader: TGeoGoldenReader;
  LFirst, LSecond, LResult: TGeoDrawVert;
  LFraction: Single;
  LWriter: TGeoGoldenWriter;
begin
  LLines := TGeoGolden.Load('surface.golden.txt', ['dv_lerpall']);
  try
    Assert.IsTrue(LLines.Count > 0);
    for LLine in LLines do
    begin
      LReader := TGeoGoldenReader.Open(LLine);
      LFirst := LReader.DrawVert;
      LSecond := LReader.DrawVert;
      LFraction := LReader.Float;
      LResult.Clear;
      LResult.LerpAll(LFirst, LSecond, LFraction);
      LWriter := TGeoGoldenWriter.Create;
      try
        LWriter.DrawVert(LResult);
        TGeoGolden.CompareOutput(LLine, LWriter.Text);
      finally
        LWriter.Free;
      end;
    end;
  finally
    LLines.Free;
  end;
end;

procedure TTestGeometryDrawVert.NormalizeDovrebbeDareLeStesseRispostePerIlCpp;
var
  LLines: TStringList;
  LLine: string;
  LReader: TGeoGoldenReader;
  LVertex: TGeoDrawVert;
  LWriter: TGeoGoldenWriter;
begin
  LLines := TGeoGolden.Load('surface.golden.txt', ['dv_normalize']);
  try
    Assert.IsTrue(LLines.Count > 0);
    for LLine in LLines do
    begin
      LReader := TGeoGoldenReader.Open(LLine);
      LVertex := LReader.DrawVert;
      LVertex.Normalize;
      LWriter := TGeoGoldenWriter.Create;
      try
        LWriter.DrawVert(LVertex);
        TGeoGolden.CompareOutput(LLine, LWriter.Text);
      finally
        LWriter.Free;
      end;
    end;
  finally
    LLines.Free;
  end;
end;

procedure TTestGeometryDrawVert.IlColoreEGliIndiciDovrebberoDareLeStesseRispostePerIlCpp;
var
  LLines: TStringList;
  LLine: string;
  LReader: TGeoGoldenReader;
  LVertex: TGeoDrawVert;
  LWriter: TGeoGoldenWriter;
  LColor: Cardinal;
  LIndex: Integer;
begin
  LLines := TGeoGolden.Load('surface.golden.txt', ['dv_color', 'dv_index']);
  try
    Assert.IsTrue(LLines.Count > 0);
    for LLine in LLines do
    begin
      LReader := TGeoGoldenReader.Open(LLine);
      LWriter := TGeoGoldenWriter.Create;
      try
        if LLine.StartsWith('dv_color') then
        begin
          LColor := LReader.UInt;
          LVertex.Clear;
          LVertex.SetColor(LColor);
          for LIndex := 0 to 3 do
            LWriter.Int(LVertex.Color[LIndex]);
          LWriter.UInt(LVertex.GetColor);
        end
        else
        begin
          LVertex := LReader.DrawVert;
          LIndex := LReader.Int;
          LWriter.Float(LVertex[LIndex]);
        end;
        TGeoGolden.CompareOutput(LLine, LWriter.Text, 0, 0);
      finally
        LWriter.Free;
      end;
    end;
  finally
    LLines.Free;
  end;
end;

end.
