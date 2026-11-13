{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the 3D models library - parity of the static models    }
{  with the C++ of Doom 3                                                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Models.StaticParity;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  DUnitX.TestFramework;

type
  /// <summary>
  ///   The models of Tests\Data\Models\static read by the Pascal classes against
  ///   static.golden.txt, the output of the real Model_lwo.cpp, Model_ase.cpp, the conversion
  ///   functions of Model.cpp and R_MergeTriangles (see the README of the folder). A line of the
  ///   golden file is "case key | values"; a float is "#" and its 32 bits in hexadecimal.
  /// </summary>
  [TestFixture]
  [Category('Models')]
  TTestStaticParity = class
  strict private
    FGolden: TDictionary<string, string>;
    function Floats(const AKey: string): TArray<Single>;
    function Text(const AKey: string): string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [TestCase('cubo lwo', 'cube.lwo,cube.lwo,1,0')]
    [TestCase('cubo lwo fast', 'cube.lwo.fast,cube.lwo,1,1')]
    [TestCase('cubo lwo smussato', 'cube_smooth.lwo,cube_smooth.lwo,1,0')]
    [TestCase('cubo lwo con colori', 'cube_colors.lwo,cube_colors.lwo,1,0')]
    [TestCase('saldatura lwo', 'weld.lwo,weld.lwo,1,0')]
    [TestCase('saldatura lwo fast', 'weld.lwo.fast,weld.lwo,1,1')]
    [TestCase('superfici unite lwo', 'merge.lwo,merge.lwo,1,0')]
    [TestCase('superfici separate lwo', 'merge.lwo.nomerge,merge.lwo,0,0')]
    [TestCase('gruppi di smussatura lwo', 'groups.lwo,groups.lwo,1,0')]
    [TestCase('cubo ase', 'cube.ase,cube.ase,1,0')]
    [TestCase('cubo ase fast', 'cube.ase.fast,cube.ase,1,1')]
    [TestCase('cubo ase con normali', 'cube_normals.ase,cube_normals.ase,1,0')]
    [TestCase('due oggetti ase', 'two_objects.ase,two_objects.ase,1,0')]
    [TestCase('due oggetti ase separati', 'two_objects.ase.nomerge,two_objects.ase,0,0')]
    [TestCase('colori ase', 'colors.ase,colors.ase,1,0')]
    procedure DovrebbeDareLeStesseRisposteDelCpp(const ACase, AFile: string; const AMerge, AFast: Integer);
  end;

implementation

uses
  System.IOUtils,
  DelphiDoom.Models.Static.Types,
  DelphiDoom.Models.Static.Triangles,
  DelphiDoom.Models.Static.Intf,
  DelphiDoom.Models.Static.Factory,
  DelphiDoom.Tests.Models.Md5Golden,
  DelphiDoom.Tests.Models.StaticBuilders;

{ TTestStaticParity }

procedure TTestStaticParity.Setup;
var
  LLines: TStringList;
  LLine: string;
  LPosition: Integer;
begin
  FGolden := TDictionary<string, string>.Create;
  LLines := TStringList.Create;
  try
    LLines.Text := TEncoding.ASCII.GetString(StaticDataFile('static.golden.txt'));
    for LLine in LLines do
    begin
      LPosition := Pos(' | ', LLine);
      if LPosition > 0 then
        FGolden.AddOrSetValue(Copy(LLine, 1, LPosition - 1), Copy(LLine, LPosition + 3, MaxInt));
    end;
  finally
    LLines.Free;
  end;
end;

procedure TTestStaticParity.TearDown;
begin
  FGolden.Free;
end;

function TTestStaticParity.Text(const AKey: string): string;
begin
  if not FGolden.TryGetValue(AKey, Result) then
    Assert.Fail('missing golden key: ' + AKey);
end;

function TTestStaticParity.Floats(const AKey: string): TArray<Single>;
var
  LParts: TArray<string>;
  LIndex, LCount: Integer;
  LBits: Cardinal;
begin
  LParts := Text(AKey).Split([' ']);
  SetLength(Result, Length(LParts));
  LCount := 0;
  for LIndex := 0 to High(LParts) do
    if (Length(LParts[LIndex]) > 1) and (LParts[LIndex][1] = '#') then
    begin
      LBits := StrToUInt('$' + Copy(LParts[LIndex], 2, MaxInt));
      Result[LCount] := PSingle(@LBits)^;
      Inc(LCount);
    end;
  SetLength(Result, LCount);
end;

procedure TTestStaticParity.DovrebbeDareLeStesseRisposteDelCpp(const ACase, AFile: string;
  const AMerge, AFast: Integer);
var
  LOptions: TStaticLoadOptions;
  LLoader: IStaticModelLoader;
  LModel: IStaticModel;
  LSurface: TStaticSurface;
  LIndex, LVertex, LItem: Integer;
  LKey, LIndexes: string;
  LValues: TArray<Single>;
  LParts: TArray<string>;
  LActual: TArray<Single>;
  LBounds: TArray<Single>;
begin
  LOptions := TStaticLoadOptions.Default;
  LOptions.MergeSurfaces := AMerge <> 0;
  LOptions.FastLoad := AFast <> 0;
  LLoader := TStaticModelFactory.CreateLoaderFor(AFile, LOptions);
  LModel := LLoader.Load(StaticDataFile(AFile), AFile);

  Assert.AreEqual(StrToInt(Text(ACase + ' surfaces')), LModel.NumSurfaces, ACase + ': surfaces');
  for LIndex := 0 to LModel.NumSurfaces - 1 do
  begin
    LSurface := LModel.Surfaces[LIndex];
    LKey := Format('%s s%d', [ACase, LIndex]);
    LParts := Text(LKey + ' info').Split([' ']);
    Assert.AreEqual(StrToInt(LParts[0]), LSurface.Id, LKey + ': id');
    Assert.AreEqual(LParts[1], string(LSurface.MaterialName), LKey + ': material');
    LParts := Text(LKey + ' counts').Split([' ']);
    Assert.AreEqual(StrToInt(LParts[0]), LSurface.Triangles.NumVerts, LKey + ': vertexes');
    Assert.AreEqual(StrToInt(LParts[1]), LSurface.Triangles.NumIndexes, LKey + ': indexes');
    Assert.AreEqual(StrToInt(LParts[2]) <> 0, LSurface.Triangles.GenerateNormals, LKey + ': generateNormals');
    LIndexes := '';
    for LItem := 0 to LSurface.Triangles.NumIndexes - 1 do
      LIndexes := LIndexes + ' ' + IntToStr(LSurface.Triangles.Indexes[LItem]);
    Assert.AreEqual(Text(LKey + ' indexes'), Trim(LIndexes), LKey + ': index list');
    for LVertex := 0 to LSurface.Triangles.NumVerts - 1 do
    begin
      LValues := Floats(Format('%s v%d', [LKey, LVertex]));
      LActual := [LSurface.Triangles.Verts[LVertex].Xyz.X, LSurface.Triangles.Verts[LVertex].Xyz.Y,
        LSurface.Triangles.Verts[LVertex].Xyz.Z, LSurface.Triangles.Verts[LVertex].St.X,
        LSurface.Triangles.Verts[LVertex].St.Y, LSurface.Triangles.Verts[LVertex].Normal.X,
        LSurface.Triangles.Verts[LVertex].Normal.Y, LSurface.Triangles.Verts[LVertex].Normal.Z];
      for LItem := 0 to High(LActual) do
        Assert.IsTrue(TMd5Golden.Close(LValues[LItem], LActual[LItem]),
          Format('%s v%d[%d]: expected %s got %s', [LKey, LVertex, LItem, TMd5Golden.Describe(LValues[LItem]),
            TMd5Golden.Describe(LActual[LItem])]));
      LParts := Text(Format('%s v%d', [LKey, LVertex])).Split([' ']);
      LParts := Copy(LParts, Length(LParts) - 4, 4);
      Assert.AreEqual(Format('%s %s %s %s', [LParts[0], LParts[1], LParts[2], LParts[3]]),
        Format('%d %d %d %d', [LSurface.Triangles.Verts[LVertex].Color.R, LSurface.Triangles.Verts[LVertex].Color.G,
          LSurface.Triangles.Verts[LVertex].Color.B, LSurface.Triangles.Verts[LVertex].Color.A]),
        Format('%s v%d: colour', [LKey, LVertex]));
    end;
    LBounds := Floats(LKey + ' bounds');
    Assert.AreEqual<Single>(LBounds[0], LSurface.Triangles.CalcBounds.Mins.X);
    Assert.AreEqual<Single>(LBounds[1], LSurface.Triangles.CalcBounds.Mins.Y);
    Assert.AreEqual<Single>(LBounds[2], LSurface.Triangles.CalcBounds.Mins.Z);
    Assert.AreEqual<Single>(LBounds[3], LSurface.Triangles.CalcBounds.Maxs.X);
    Assert.AreEqual<Single>(LBounds[4], LSurface.Triangles.CalcBounds.Maxs.Y);
    Assert.AreEqual<Single>(LBounds[5], LSurface.Triangles.CalcBounds.Maxs.Z);
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestStaticParity);

end.
