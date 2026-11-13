{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the 3D models library - the reader of I3D files        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Models.I3dParser;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Models.Types, DelphiDoom.Models.I3d.Types,
  DelphiDoom.Models.I3d.Intf;

type
  /// <summary>
  ///   Parity with the old TI3DModelLoader (the golden file i3d.synthetic.golden.txt, written by the old code on
  ///   files made by TI3dFileBuilder) and the cases by hand: damaged files, faces without material, textures
  /// </summary>
  [TestFixture]
  [Category('models')]
  TTestModelsI3dParser = class(TObject)
  strict private
    FParser: II3dParser;
    function ReadGolden: TArray<string>;
    function ModelLines(const AName: string; const ABytes: TBytes): TArray<string>;
    procedure CheckLines(const AExpected: TArray<string>; var APosition: Integer;
      const AActual: TArray<string>);
    function DamagedAt(const ABytes: TBytes; const AOffset: Integer; const AValue: Integer): TBytes;
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure DovrebbeAvereLeDimensioniDeiRecordDelFormato;
    [Test]
    procedure DovrebbeDareLeStesseRigheDelVecchioCodiceSuiModelliSintetici;
    [Test]
    procedure DovrebbeUsareLaScalaDiDefaultSeIlFileHaZero;
    [Test]
    procedure DovrebbeTenereLaScalaEIlCentroDelFile;
    [Test]
    procedure DovrebbeNumerareLeTextureNellOrdineDeiMateriali;
    [Test]
    procedure DovrebbeLeggereUnaTexturaLargaDi256Pixel;
    [Test]
    procedure DovrebbeDareTexturaVuotaAUnMaterialSenzaPixel;
    [Test]
    procedure DovrebbeTrasformareLaTexturaInPixelRgbaDellaPalette;
    [Test]
    procedure DovrebbeTrovareUnMaterialDalNomeDellaTextura;
    [Test]
    procedure DovrebbeDareMenoUnoSeIlNomeDellaTexturaNonCe;
    [Test]
    procedure DovrebbeDareMenoUnoAUnaFaccciaSenzaMateriale;
    [Test]
    procedure DovrebbeDareMenoUnoAUnaNormaleAssente;
    [Test]
    procedure DovrebbeMisurareLeQuattroGommeDiUnaAuto;
    [Test]
    procedure DovrebbeNonMisurareLeGommeSenzaIlFlag;
    [Test]
    procedure DovrebbeSollevareUnErroreSeIlFileEBreve;
    [Test]
    procedure DovrebbeSollevareUnErroreSeLaMagiaESbagliata;
    [Test]
    procedure DovrebbeSollevareUnErroreSeLImmagineESuperioreAlFile;
    [Test]
    procedure DovrebbeSollevareUnErroreSeUnArrayEFuoriDallImmagine;
    [Test]
    procedure DovrebbeSollevareUnErroreSeUnaFacciaUsaUnVerticeCheNonCe;
    [Test]
    procedure DovrebbeSollevareUnErroreSeUnaFacciaUsaUnMaterialCheNonCe;
    [Test]
    procedure DovrebbeSollevareUnErroreSeLaCacheDelleFaccePassaLaFine;
    [Test]
    procedure DovrebbeSollevareUnErroreSeUnaTexturaNonEnelFile;
    [Test]
    procedure DovrebbeSollevareUnErroreSeSiChiedeUnMaterialOUnaTexturaFuoriLista;
    [Test]
    procedure DovrebbeDareLeStesseRigheLeggendoDueVolte;
  end;

implementation

uses
  System.Classes, System.IOUtils, DelphiDoom.Models.I3d.Factory, DelphiDoom.Tests.Models.I3dFileBuilder,
  DelphiDoom.Tests.Models.I3dDump;

{ TTestModelsI3dParser }

procedure TTestModelsI3dParser.Setup;
begin
  FParser := TI3dFactory.CreateParser;
end;

function TTestModelsI3dParser.ReadGolden: TArray<string>;
var
  LLines: TStringList;
begin
  LLines := TStringList.Create;
  try
    LLines.LoadFromFile(TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)),
      '..\..\Tests\Data\Models\i3d.synthetic.golden.txt')));
    Result := LLines.ToStringArray;
  finally
    LLines.Free;
  end;
end;

function TTestModelsI3dParser.ModelLines(const AName: string; const ABytes: TBytes): TArray<string>;
var
  LModel: II3dModel;
  LPlain, LCorrected: TArray<string>;
begin
  LModel := FParser.Parse(ABytes);
  LPlain := TI3dDump.Lines(AName, Length(ABytes), LModel);
  LModel.ApplyCorrections(TI3dDump.SampleCorrections(LModel.FaceCount));
  LCorrected := TI3dDump.Lines('corrected ' + AName, Length(ABytes), LModel);
  Result := LPlain + LCorrected;
end;

procedure TTestModelsI3dParser.CheckLines(const AExpected: TArray<string>; var APosition: Integer;
  const AActual: TArray<string>);
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(AActual) do
  begin
    Assert.AreEqual(AExpected[APosition], AActual[LIndex], 'line ' + IntToStr(APosition + 1));
    Inc(APosition);
  end;
end;

function TTestModelsI3dParser.DamagedAt(const ABytes: TBytes; const AOffset: Integer;
  const AValue: Integer): TBytes;
begin
  Result := Copy(ABytes);
  Move(AValue, Result[AOffset], 4);
end;

procedure TTestModelsI3dParser.DovrebbeAvereLeDimensioniDeiRecordDelFormato;
begin
  Assert.AreEqual(12, SizeOf(TI3dDiskVector));
  Assert.AreEqual(60, SizeOf(TI3dDiskObject));
  Assert.AreEqual(36, SizeOf(TI3dDiskVertex));
  Assert.AreEqual(28, SizeOf(TI3dDiskNormal));
  Assert.AreEqual(28, SizeOf(TI3dDiskMaterial));
  Assert.AreEqual(48, SizeOf(TI3dDiskFaceHeader));
  Assert.AreEqual(20, SizeOf(TI3dDiskFaceVertex));
  Assert.AreEqual(8, SizeOf(TI3dTextureName));
end;

procedure TTestModelsI3dParser.DovrebbeDareLeStesseRigheDelVecchioCodiceSuiModelliSintetici;
var
  LGolden: TArray<string>;
  LPosition: Integer;
begin
  LGolden := ReadGolden;
  LPosition := 0;
  CheckLines(LGolden, LPosition, ModelLines('synthetic.small', TI3dFileBuilder.SmallModel));
  CheckLines(LGolden, LPosition, ModelLines('synthetic.car', TI3dFileBuilder.CarModel));
  CheckLines(LGolden, LPosition, ModelLines('synthetic.plain', TI3dFileBuilder.PlainModel));
  Assert.AreEqual<Integer>(Length(LGolden), LPosition, 'number of lines');
end;

procedure TTestModelsI3dParser.DovrebbeUsareLaScalaDiDefaultSeIlFileHaZero;
var
  LModel: II3dModel;
begin
  LModel := FParser.Parse(TI3dFileBuilder.SmallModel);
  Assert.AreEqual(I3D_DEFAULT_SCALE, LModel.Header.ScaleX);
  Assert.AreEqual(I3D_DEFAULT_SCALE, LModel.Header.ScaleY);
  Assert.AreEqual(I3D_DEFAULT_SCALE, LModel.Header.ScaleZ);
  // only the axis with 0 changes
  LModel := FParser.Parse(TI3dFileBuilder.CarModel);
  Assert.AreEqual(I3D_DEFAULT_SCALE, LModel.Header.ScaleX);
  Assert.AreEqual(3000000, LModel.Header.ScaleY);
end;

procedure TTestModelsI3dParser.DovrebbeTenereLaScalaEIlCentroDelFile;
var
  LModel: II3dModel;
begin
  LModel := FParser.Parse(TI3dFileBuilder.PlainModel);
  Assert.AreEqual(2000000, LModel.Header.ScaleX);
  Assert.AreEqual(1000000, LModel.Header.ScaleY);
  Assert.AreEqual(500000, LModel.Header.ScaleZ);
  Assert.AreEqual(-50, LModel.Header.CenterX);
  Assert.AreEqual(60, LModel.Header.CenterY);
  Assert.AreEqual(-70, LModel.Header.CenterZ);
  Assert.AreEqual(70, LModel.FaceCount);
  Assert.AreEqual(2, LModel.MaterialCount);
end;

procedure TTestModelsI3dParser.DovrebbeNumerareLeTextureNellOrdineDeiMateriali;
var
  LModel: II3dModel;
begin
  LModel := FParser.Parse(TI3dFileBuilder.CarModel);
  Assert.AreEqual(2, LModel.TextureCount);
  Assert.AreEqual(-1, LModel.Materials[0].TextureIndex);
  Assert.AreEqual(0, LModel.Materials[1].TextureIndex);
  Assert.AreEqual(1, LModel.Materials[2].TextureIndex);
  Assert.AreEqual(-1, LModel.Materials[3].TextureIndex);
end;

procedure TTestModelsI3dParser.DovrebbeLeggereUnaTexturaLargaDi256Pixel;
var
  LModel: II3dModel;
begin
  LModel := FParser.Parse(TI3dFileBuilder.CarModel);
  Assert.AreEqual(64, LModel.Textures[0].Width);
  Assert.AreEqual(64, LModel.Textures[0].Height);
  Assert.AreEqual<Integer>(64 * 64, Length(LModel.Textures[0].Pixels));
  Assert.AreEqual(256, LModel.Textures[1].Width);
  Assert.AreEqual(64, LModel.Textures[1].Height);
  Assert.AreEqual<Integer>(256 * 64, Length(LModel.Textures[1].Pixels));
end;

procedure TTestModelsI3dParser.DovrebbeDareTexturaVuotaAUnMaterialSenzaPixel;
var
  LModel: II3dModel;
begin
  LModel := FParser.Parse(TI3dFileBuilder.PlainModel);
  Assert.AreEqual(0, LModel.TextureCount);
  Assert.AreEqual(-1, LModel.Materials[0].TextureIndex);
end;

procedure TTestModelsI3dParser.DovrebbeTrasformareLaTexturaInPixelRgbaDellaPalette;
var
  LModel: II3dModel;
  LPixels: TArray<Cardinal>;
begin
  LModel := FParser.Parse(TI3dFileBuilder.SmallModel);
  LPixels := LModel.TextureToRgba(0);
  Assert.AreEqual<Integer>(64 * 64, Length(LPixels));
  // the pixel 0 is the palette index 0 + the seed term; the alpha is always 255
  Assert.AreEqual(Cardinal($FF), LPixels[0] shr 24);
  Assert.AreEqual(Cardinal($FF), LPixels[4095] shr 24);
end;

procedure TTestModelsI3dParser.DovrebbeTrovareUnMaterialDalNomeDellaTextura;
var
  LModel: II3dModel;
begin
  LModel := FParser.Parse(TI3dFileBuilder.CarModel);
  Assert.AreEqual(1, LModel.FindMaterialByTextureName('LIVERY'));
  Assert.AreEqual(2, LModel.FindMaterialByTextureName('WIDE'));
end;

procedure TTestModelsI3dParser.DovrebbeDareMenoUnoSeIlNomeDellaTexturaNonCe;
var
  LModel: II3dModel;
begin
  LModel := FParser.Parse(TI3dFileBuilder.CarModel);
  Assert.AreEqual(-1, LModel.FindMaterialByTextureName('livery'), 'the case counts');
  Assert.AreEqual(-1, LModel.FindMaterialByTextureName('NONE'));
end;

procedure TTestModelsI3dParser.DovrebbeDareMenoUnoAUnaFaccciaSenzaMateriale;
var
  LBuilder: TI3dFileBuilder;
  LModel: II3dModel;
  LFaces: TArray<TI3dFace>;
begin
  LBuilder := TI3dFileBuilder.Create;
  try
    LBuilder.AddVertex(1, 2, 3);
    LBuilder.AddVertex(4, 5, 6);
    LBuilder.AddVertex(7, 8, 9);
    LBuilder.AddFace(-1, 0, [TI3dFileBuilder.Corner(0, -1, 0, 0), TI3dFileBuilder.Corner(1, -1, 0, 0),
      TI3dFileBuilder.Corner(2, -1, 0, 0)]);
    LModel := FParser.Parse(LBuilder.Build);
  finally
    LBuilder.Free;
  end;
  LFaces := LModel.GetFaces;
  Assert.AreEqual(-1, LFaces[0].MaterialIndex);
  Assert.AreEqual(0, Integer(LFaces[0].Color));
  Assert.IsTrue(LFaces[0].Visible);
  Assert.AreEqual(4, LFaces[0].Vertices[1].X);
  Assert.AreEqual(9, LFaces[0].Vertices[2].Z);
end;

procedure TTestModelsI3dParser.DovrebbeDareMenoUnoAUnaNormaleAssente;
var
  LModel: II3dModel;
  LFaces: TArray<TI3dFace>;
begin
  LModel := FParser.Parse(TI3dFileBuilder.SmallModel);
  LFaces := LModel.GetFaces;
  Assert.AreEqual(0, LFaces[0].Vertices[0].NormalIndex);
  Assert.AreEqual(1, LFaces[0].Vertices[2].NormalIndex);
  Assert.AreEqual(-1, LFaces[1].Vertices[0].NormalIndex);
end;

procedure TTestModelsI3dParser.DovrebbeMisurareLeQuattroGommeDiUnaAuto;
var
  LModel: II3dModel;
begin
  LModel := FParser.Parse(TI3dFileBuilder.CarModel);
  Assert.IsTrue(LModel.HasTires);
  Assert.AreEqual(-905000, LModel.Tires[0].CenterX);
  Assert.AreEqual(1515000, LModel.Tires[0].CenterZ);
  Assert.AreEqual(600000, LModel.Tires[0].Perimeter);
  Assert.AreEqual(895000, LModel.Tires[1].CenterX);
end;

procedure TTestModelsI3dParser.DovrebbeNonMisurareLeGommeSenzaIlFlag;
var
  LModel: II3dModel;
begin
  LModel := FParser.Parse(TI3dFileBuilder.PlainModel);
  Assert.IsFalse(LModel.HasTires);
  Assert.AreEqual(0, LModel.Tires[0].Perimeter);
  Assert.AreEqual(0, LModel.Tires[3].CenterX);
  // and a model with fewer than 64 faces does not have them either
  LModel := FParser.Parse(TI3dFileBuilder.SmallModel);
  Assert.AreEqual(0, LModel.Tires[2].Perimeter);
end;

procedure TTestModelsI3dParser.DovrebbeSollevareUnErroreSeIlFileEBreve;
begin
  Assert.WillRaise(procedure begin FParser.Parse(nil); end, EModelsException);
  Assert.WillRaise(procedure begin FParser.Parse(Copy(TI3dFileBuilder.SmallModel, 0, 40)); end,
    EModelsException);
end;

procedure TTestModelsI3dParser.DovrebbeSollevareUnErroreSeLaMagiaESbagliata;
begin
  Assert.WillRaise(procedure begin FParser.Parse(DamagedAt(TI3dFileBuilder.SmallModel, 0, $50414D49)); end,
    EModelsException);
end;

procedure TTestModelsI3dParser.DovrebbeSollevareUnErroreSeLImmagineESuperioreAlFile;
begin
  Assert.WillRaise(procedure begin FParser.Parse(DamagedAt(TI3dFileBuilder.SmallModel, 4, 999999)); end,
    EModelsException, 'image larger than the file');
  Assert.WillRaise(procedure begin FParser.Parse(DamagedAt(TI3dFileBuilder.SmallModel, 4, 10)); end,
    EModelsException, 'image smaller than the object');
  Assert.WillRaise(procedure begin FParser.Parse(DamagedAt(TI3dFileBuilder.SmallModel, 4, -5)); end,
    EModelsException, 'negative image');
end;

procedure TTestModelsI3dParser.DovrebbeSollevareUnErroreSeUnArrayEFuoriDallImmagine;
begin
  // the offsets of the object: vertexes (8 + 12), normals (+16), materials (+24), face cache (+20)
  Assert.WillRaise(procedure begin FParser.Parse(DamagedAt(TI3dFileBuilder.SmallModel, 8 + 12, 4000)); end,
    EModelsException, 'vertexes');
  Assert.WillRaise(procedure begin FParser.Parse(DamagedAt(TI3dFileBuilder.SmallModel, 8 + 16, 4000)); end,
    EModelsException, 'normals');
  Assert.WillRaise(procedure begin FParser.Parse(DamagedAt(TI3dFileBuilder.SmallModel, 8 + 24, 4000)); end,
    EModelsException, 'materials');
  Assert.WillRaise(procedure begin FParser.Parse(DamagedAt(TI3dFileBuilder.SmallModel, 8 + 20, 4000)); end,
    EModelsException, 'faces');
end;

procedure TTestModelsI3dParser.DovrebbeSollevareUnErroreSeUnaFacciaUsaUnVerticeCheNonCe;
var
  LBytes: TBytes;
  LCache: Integer;
begin
  LBytes := TI3dFileBuilder.SmallModel;
  Move(LBytes[8 + 20], LCache, 4);
  // the first vertex of the first face: after the header of 48 bytes
  Assert.WillRaise(procedure begin FParser.Parse(DamagedAt(LBytes, 8 + LCache + 48, 61)); end,
    EModelsException, 'not aligned');
  Assert.WillRaise(procedure begin FParser.Parse(DamagedAt(LBytes, 8 + LCache + 48, 60 + 36 * 5)); end,
    EModelsException, 'after the pool');
  Assert.WillRaise(procedure begin FParser.Parse(DamagedAt(LBytes, 8 + LCache + 48, 4)); end,
    EModelsException, 'before the pool');
  // a normal that does not exist
  Assert.WillRaise(procedure begin FParser.Parse(DamagedAt(LBytes, 8 + LCache + 48 + 4, 4)); end,
    EModelsException, 'normal');
end;

procedure TTestModelsI3dParser.DovrebbeSollevareUnErroreSeUnaFacciaUsaUnMaterialCheNonCe;
var
  LBytes: TBytes;
  LCache: Integer;
begin
  LBytes := TI3dFileBuilder.SmallModel;
  Move(LBytes[8 + 20], LCache, 4);
  Assert.WillRaise(procedure begin FParser.Parse(DamagedAt(LBytes, 8 + LCache + 8, 7)); end,
    EModelsException);
end;

procedure TTestModelsI3dParser.DovrebbeSollevareUnErroreSeLaCacheDelleFaccePassaLaFine;
var
  LBytes: TBytes;
  LCache: Integer;
  LSize: Integer;
begin
  LBytes := TI3dFileBuilder.SmallModel;
  Move(LBytes[4], LSize, 4);
  Move(LBytes[8 + 20], LCache, 4);
  // the faces start near the end of the image: the headers do not fit
  Assert.WillRaise(procedure begin FParser.Parse(DamagedAt(LBytes, 8 + 20, LSize - 10)); end, EModelsException);
  // a face that says it has too many vertexes
  LBytes[8 + LCache + 2] := $FF;
  LBytes[8 + LCache + 3] := $7F;
  Assert.WillRaise(procedure begin FParser.Parse(LBytes); end, EModelsException);
end;

procedure TTestModelsI3dParser.DovrebbeSollevareUnErroreSeUnaTexturaNonEnelFile;
var
  LBytes: TBytes;
begin
  LBytes := TI3dFileBuilder.SmallModel;
  SetLength(LBytes, Length(LBytes) - 1);
  Assert.WillRaise(procedure begin FParser.Parse(LBytes); end, EModelsException);
end;

procedure TTestModelsI3dParser.DovrebbeSollevareUnErroreSeSiChiedeUnMaterialOUnaTexturaFuoriLista;
var
  LModel: II3dModel;
begin
  LModel := FParser.Parse(TI3dFileBuilder.SmallModel);
  Assert.WillRaise(procedure begin LModel.Materials[2]; end, EModelsException);
  Assert.WillRaise(procedure begin LModel.Materials[-1]; end, EModelsException);
  Assert.WillRaise(procedure begin LModel.Textures[1]; end, EModelsException);
  Assert.WillRaise(procedure begin LModel.Tires[4]; end, EModelsException);
  Assert.WillRaise(procedure begin LModel.TextureToRgba(-1); end, EModelsException);
end;

procedure TTestModelsI3dParser.DovrebbeDareLeStesseRigheLeggendoDueVolte;
var
  LFirst, LSecond: TArray<string>;
  LIndex: Integer;
begin
  LFirst := ModelLines('a', TI3dFileBuilder.CarModel);
  LSecond := ModelLines('a', TI3dFileBuilder.CarModel);
  Assert.AreEqual(Length(LFirst), Length(LSecond));
  for LIndex := 0 to High(LFirst) do
    Assert.AreEqual(LFirst[LIndex], LSecond[LIndex]);
end;

end.
