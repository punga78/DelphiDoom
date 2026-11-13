{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the 3D models library - the MD3 reader and instances   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Models.StaticMd3;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.Models.Static.Md3.Intf;

type
  [TestFixture]
  [Category('Models')]
  TTestStaticMd3 = class
  strict private
    function Read(const AData: TBytes): IMd3Model;
    function Fails(const AData: TBytes; const AFragment: string): Boolean;
  public
    [Test]
    procedure DovrebbeLeggereLeFrameLeTagELaSuperficie;
    [Test]
    procedure DovrebbeMinuscolareIlNomeEToglierneIlSuffisso;
    [Test]
    procedure DovrebbeDareLePosizioniDelPrimoFotogrammaPerUnSessantaquattresimo;
    [Test]
    procedure DovrebbeDareLeBoundsDelPrimoFotogramma;
    [Test]
    procedure DovrebbeIstanziareUnFotogrammaQualsiasi;
    [Test]
    procedure DovrebbeInterpolareFraDueFotogrammi;
    [Test]
    procedure DovrebbeUsareIlPrimoShaderComeMateriale;
    [Test]
    procedure DovrebbeCaricareIlPrimoFotogrammaComeModelloStatico;
    [Test]
    procedure DovrebbeRifiutareUnaVersioneDiversa;
    [Test]
    procedure DovrebbeNonControllareLIdentificatore;
    [Test]
    procedure DovrebbeRifiutareUnModelloSenzaFotogrammi;
    [Test]
    procedure DovrebbeRifiutareTroppiVertexInUnaSuperficie;
    [Test]
    procedure DovrebbeRifiutareUnFileTroncato;
    [Test]
    procedure DovrebbeRifiutareUnFotogrammaCheNonEsiste;
    [Test]
    procedure DovrebbeRifiutareUnIndiceDiTriangoloFuoriIntervallo;
    [Test]
    procedure DovrebbeLeggereLeTagDiOgniFotogramma;
  end;

implementation

uses
  System.Classes,
  DelphiDoom.Geometry.Bounds,
  DelphiDoom.Models.Static.Types,
  DelphiDoom.Models.Static.Intf,
  DelphiDoom.Models.Static.Factory,
  DelphiDoom.Models.Static.Md3.Types;

procedure PutInt(const AStream: TBytesStream; const AValue: Integer);
begin
  AStream.WriteBuffer(AValue, 4);
end;

procedure PutShort(const AStream: TBytesStream; const AValue: SmallInt);
begin
  AStream.WriteBuffer(AValue, 2);
end;

procedure PutFloat(const AStream: TBytesStream; const AValue: Single);
begin
  AStream.WriteBuffer(AValue, 4);
end;

procedure PutName(const AStream: TBytesStream; const AName: AnsiString; const ASize: Integer);
var
  LBytes: TBytes;
begin
  SetLength(LBytes, ASize);
  if Length(AName) > 0 then
    Move(AName[1], LBytes[0], Length(AName));
  AStream.WriteBuffer(LBytes[0], ASize);
end;

/// <summary>
///   A model of two frames, one tag per frame and one surface: the triangle (0, 1, 2) with
///   the vertexes (64,0,0), (0,64,0), (0,0,64) in the frame 0 and the double in the frame 1
/// </summary>
function BuildMd3(const AVersion: Integer = 15; const AFrames: Integer = 2; const AVerts: Integer = 3;
  const ATriangleIndex: Integer = 2): TBytes;
var
  LStream: TBytesStream;
  LFrame, LVert, LIndex: Integer;
  LValues: array[0..2] of SmallInt;
begin
  LStream := TBytesStream.Create;
  try
    // header
    PutInt(LStream, $33504449);
    PutInt(LStream, AVersion);
    PutName(LStream, 'models/test/cube.md3', MD3_MAX_PATH);
    PutInt(LStream, 0);
    PutInt(LStream, AFrames);
    PutInt(LStream, 1);
    PutInt(LStream, 1);
    PutInt(LStream, 0);
    PutInt(LStream, 108);
    PutInt(LStream, 108 + AFrames * 56);
    PutInt(LStream, 108 + AFrames * 56 + AFrames * 112);
    PutInt(LStream, 108 + AFrames * 56 + AFrames * 112 + 108 + 68 + 12 + AVerts * 8 + AVerts * AFrames * 8);
    // frames
    for LFrame := 0 to AFrames - 1 do
    begin
      PutFloat(LStream, -1 * (LFrame + 1)); PutFloat(LStream, -2 * (LFrame + 1)); PutFloat(LStream, -3 * (LFrame + 1));
      PutFloat(LStream, 1 * (LFrame + 1)); PutFloat(LStream, 2 * (LFrame + 1)); PutFloat(LStream, 3 * (LFrame + 1));
      PutFloat(LStream, 0); PutFloat(LStream, 0); PutFloat(LStream, 0);
      PutFloat(LStream, 5);
      PutName(LStream, AnsiString('frame' + IntToStr(LFrame)), 16);
    end;
    // tags: one per frame
    for LFrame := 0 to AFrames - 1 do
    begin
      PutName(LStream, 'tag_weapon', MD3_MAX_PATH);
      PutFloat(LStream, 10 + LFrame); PutFloat(LStream, 20); PutFloat(LStream, 30);
      for LIndex := 0 to 8 do
        PutFloat(LStream, Ord(LIndex mod 4 = 0));
    end;
    // surface
    PutInt(LStream, $33504449);
    PutName(LStream, 'Body_1', MD3_MAX_PATH);
    PutInt(LStream, 0);
    PutInt(LStream, AFrames);
    PutInt(LStream, 1);
    PutInt(LStream, AVerts);
    PutInt(LStream, 1);
    PutInt(LStream, 108 + 68);
    PutInt(LStream, 108);
    PutInt(LStream, 108 + 68 + 12);
    PutInt(LStream, 108 + 68 + 12 + AVerts * 8);
    PutInt(LStream, 108 + 68 + 12 + AVerts * 8 + AVerts * AFrames * 8);
    PutName(LStream, 'models/Test/Skin', MD3_MAX_PATH);
    PutInt(LStream, 0);
    PutInt(LStream, 0);
    PutInt(LStream, 1);
    PutInt(LStream, ATriangleIndex);
    for LVert := 0 to AVerts - 1 do
    begin
      PutFloat(LStream, LVert * 0.25);
      PutFloat(LStream, 1 - LVert * 0.25);
    end;
    for LFrame := 0 to AFrames - 1 do
      for LVert := 0 to AVerts - 1 do
      begin
        LValues[0] := 0;
        LValues[1] := 0;
        LValues[2] := 0;
        LValues[LVert mod 3] := 64 * (LFrame + 1);
        PutShort(LStream, LValues[0]);
        PutShort(LStream, LValues[1]);
        PutShort(LStream, LValues[2]);
        PutShort(LStream, 0);
      end;
    Result := Copy(LStream.Bytes, 0, LStream.Size);
  finally
    LStream.Free;
  end;
end;

{ TTestStaticMd3 }

function TTestStaticMd3.Read(const AData: TBytes): IMd3Model;
begin
  Result := TStaticModelFactory.CreateMd3Reader.Read(AData, 'cube.md3');
end;

function TTestStaticMd3.Fails(const AData: TBytes; const AFragment: string): Boolean;
begin
  Result := False;
  try
    Read(AData);
  except
    on E: EStaticModelException do
      Result := E.Message.Contains(AFragment);
  end;
end;

procedure TTestStaticMd3.DovrebbeLeggereLeFrameLeTagELaSuperficie;
var
  LModel: IMd3Model;
begin
  LModel := Read(BuildMd3);
  Assert.AreEqual('cube.md3', LModel.Name);
  Assert.AreEqual(2, LModel.NumFrames);
  Assert.AreEqual(1, LModel.NumTags);
  Assert.AreEqual(1, LModel.NumSurfaces);
  Assert.AreEqual('frame1', string(LModel.Frames[1].Name));
  Assert.AreEqual<Single>(5, LModel.Frames[0].Radius);
  Assert.AreEqual(3, LModel.Surfaces[0].NumVerts);
  Assert.AreEqual<Integer>(3, Length(LModel.Surfaces[0].Triangles));
  Assert.AreEqual<Single>(0.25, LModel.Surfaces[0].St[1].X);
  Assert.AreEqual<Single>(0.75, LModel.Surfaces[0].St[1].Y);
end;

procedure TTestStaticMd3.DovrebbeMinuscolareIlNomeEToglierneIlSuffisso;
begin
  Assert.AreEqual('body', string(Read(BuildMd3).Surfaces[0].Name), '"Body_1" is lowercased and loses "_1"');
end;

procedure TTestStaticMd3.DovrebbeDareLePosizioniDelPrimoFotogrammaPerUnSessantaquattresimo;
var
  LModel: IStaticModel;
begin
  LModel := Read(BuildMd3).Instantiate(0, 0, 0);
  Assert.AreEqual<Single>(1, LModel.Surfaces[0].Triangles.Verts[0].Xyz.X);
  Assert.AreEqual<Single>(1, LModel.Surfaces[0].Triangles.Verts[1].Xyz.Y);
  Assert.AreEqual<Single>(1, LModel.Surfaces[0].Triangles.Verts[2].Xyz.Z);
  Assert.AreEqual<Single>(0, LModel.Surfaces[0].Triangles.Verts[2].Xyz.X);
  Assert.AreEqual<Single>(0.5, LModel.Surfaces[0].Triangles.Verts[2].St.X);
  Assert.AreEqual(3, LModel.Surfaces[0].Triangles.NumIndexes);
  Assert.AreEqual<Integer>(2, LModel.Surfaces[0].Triangles.Indexes[2]);
end;

procedure TTestStaticMd3.DovrebbeDareLeBoundsDelPrimoFotogramma;
var
  LBounds: TGeoBounds;
begin
  LBounds := Read(BuildMd3).Bounds;
  Assert.AreEqual<Single>(-1, LBounds.Mins.X);
  Assert.AreEqual<Single>(3, LBounds.Maxs.Z);
end;

procedure TTestStaticMd3.DovrebbeIstanziareUnFotogrammaQualsiasi;
var
  LModel: IStaticModel;
begin
  LModel := Read(BuildMd3).Instantiate(1, 0, 0);
  Assert.AreEqual<Single>(2, LModel.Surfaces[0].Triangles.Verts[0].Xyz.X);
  Assert.AreEqual<Single>(2, LModel.Bounds.Maxs.X, 'the box of the vertexes of the frame');
end;

procedure TTestStaticMd3.DovrebbeInterpolareFraDueFotogrammi;
var
  LModel: IStaticModel;
begin
  // old frame 0 (1.0) with weight 0.25 and frame 1 (2.0) with weight 0.75
  LModel := Read(BuildMd3).Instantiate(1, 0, 0.25);
  Assert.AreEqual(1.75, LModel.Surfaces[0].Triangles.Verts[0].Xyz.X, 1e-6);
  Assert.AreEqual<Single>(0, LModel.Surfaces[0].Triangles.Verts[0].Xyz.Y);
end;

procedure TTestStaticMd3.DovrebbeUsareIlPrimoShaderComeMateriale;
begin
  Assert.AreEqual('models/Test/Skin', string(Read(BuildMd3).Instantiate(0, 0, 0).Surfaces[0].MaterialName));
end;

procedure TTestStaticMd3.DovrebbeCaricareIlPrimoFotogrammaComeModelloStatico;
var
  LModel: IStaticModel;
begin
  LModel := TStaticModelFactory.CreateLoaderFor('models/a.MD3', TStaticLoadOptions.Default).Load(BuildMd3, 'a.md3');
  Assert.AreEqual(1, LModel.NumSurfaces);
  Assert.AreEqual<Single>(1, LModel.Surfaces[0].Triangles.Verts[0].Xyz.X);
end;

procedure TTestStaticMd3.DovrebbeRifiutareUnaVersioneDiversa;
begin
  Assert.IsTrue(Fails(BuildMd3(14), 'wrong version (14 should be 15)'));
end;

procedure TTestStaticMd3.DovrebbeNonControllareLIdentificatore;
var
  LData: TBytes;
begin
  LData := BuildMd3;
  LData[0] := 0;
  Assert.AreEqual(2, Read(LData).NumFrames);
end;

procedure TTestStaticMd3.DovrebbeRifiutareUnModelloSenzaFotogrammi;
begin
  Assert.IsTrue(Fails(BuildMd3(15, 0), 'no frames'));
end;

procedure TTestStaticMd3.DovrebbeRifiutareTroppiVertexInUnaSuperficie;
begin
  Assert.IsTrue(Fails(BuildMd3(15, 2, 1001), 'more than 1000 verts'));
end;

procedure TTestStaticMd3.DovrebbeRifiutareUnFileTroncato;
var
  LData: TBytes;
begin
  LData := BuildMd3;
  SetLength(LData, 300);
  Assert.IsTrue(Fails(LData, 'out of the file'));
  Assert.IsTrue(Fails(TBytes.Create(1, 2, 3), 'truncated'));
end;

procedure TTestStaticMd3.DovrebbeRifiutareUnFotogrammaCheNonEsiste;
var
  LModel: IMd3Model;
  LRaised: Boolean;
begin
  LModel := Read(BuildMd3);
  LRaised := False;
  try
    LModel.Instantiate(2, 0, 0);
  except
    on EStaticModelException do
      LRaised := True;
  end;
  Assert.IsTrue(LRaised);
  LRaised := False;
  try
    LModel.Instantiate(0, 5, 0.5);
  except
    on EStaticModelException do
      LRaised := True;
  end;
  Assert.IsTrue(LRaised);
end;

procedure TTestStaticMd3.DovrebbeRifiutareUnIndiceDiTriangoloFuoriIntervallo;
var
  LRaised: Boolean;
begin
  LRaised := False;
  try
    Read(BuildMd3(15, 2, 3, 9)).Instantiate(0, 0, 0);
  except
    on EStaticModelException do
      LRaised := True;
  end;
  Assert.IsTrue(LRaised);
end;

procedure TTestStaticMd3.DovrebbeLeggereLeTagDiOgniFotogramma;
var
  LModel: IMd3Model;
begin
  LModel := Read(BuildMd3);
  Assert.AreEqual('tag_weapon', string(LModel.Tags[1, 0].Name));
  Assert.AreEqual<Single>(10, LModel.Tags[0, 0].Origin.X);
  Assert.AreEqual<Single>(11, LModel.Tags[1, 0].Origin.X);
  Assert.AreEqual<Single>(1, LModel.Tags[0, 0].Axis[0].X);
  Assert.AreEqual<Single>(0, LModel.Tags[0, 0].Axis[0].Y);
  Assert.AreEqual<Single>(1, LModel.Tags[0, 0].Axis[1].Y);
  Assert.AreEqual<Single>(1, LModel.Tags[0, 0].Axis[2].Z);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestStaticMd3);

end.
