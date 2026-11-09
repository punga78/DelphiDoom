{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the 3D models library - the corrections of I3D models  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Models.I3dCorrections;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Models.Types, DelphiDoom.Models.I3d.Types, DelphiDoom.Models.I3d.Intf;

type
  /// <summary>
  ///   The text of the corrections and what they do to a model (the old ApplyCorrection is in the golden file of
  ///   the reader, with the corrected lines)
  /// </summary>
  [TestFixture]
  [Category('models')]
  TTestModelsI3dCorrections = class(TObject)
  strict private
    FReader: II3dCorrectionReader;
    FParser: II3dParser;
    function Correction(const AFace, AVertex: Integer): TI3dCorrection;
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure DovrebbeLeggereLeCorrezioniDaTesto;
    [Test]
    procedure DovrebbeSaltareLeParoleChePrecedonoLaPrimaFaccia;
    [Test]
    procedure DovrebbeIgnorareICommentiELeMaiuscole;
    [Test]
    procedure DovrebbeLeggereNumeriEsadecimaliETroncareIlColore;
    [Test]
    procedure DovrebbeSollevareUnErroreSeUnaCorrezioneEIncompleta;
    [Test]
    procedure DovrebbeSollevareUnErroreSeUnaChiaveEDiversa;
    [Test]
    procedure DovrebbeSollevareUnErroreSeUnNumeroNonEUnNumero;
    [Test]
    procedure DovrebbeDareUnaListaVuotaPerUnTestoSenzaCorrezioni;
    [Test]
    procedure DovrebbeCorreggereUnVerticeDiUnaFaccia;
    [Test]
    procedure DovrebbeIgnorareLeCorrezioniFuoriDalModello;
    [Test]
    procedure DovrebbeLasciareIlColoreSeLaFacciaNonHaMateriale;
    [Test]
    procedure DovrebbeMisurareDiNuovoLeGommeDopoLeCorrezioni;
  end;

implementation

uses
  DelphiDoom.Models.I3d.Factory, DelphiDoom.Tests.Models.I3dFileBuilder;

{ TTestModelsI3dCorrections }

procedure TTestModelsI3dCorrections.Setup;
begin
  FReader := TI3dFactory.CreateCorrectionReader;
  FParser := TI3dFactory.CreateParser;
end;

function TTestModelsI3dCorrections.Correction(const AFace, AVertex: Integer): TI3dCorrection;
begin
  Result := Default(TI3dCorrection);
  Result.Face := AFace;
  Result.Vertex := AVertex;
  Result.Visible := True;
  Result.X := 11;
  Result.Y := 22;
  Result.Z := 33;
  Result.TextureX := 44;
  Result.TextureY := 55;
  Result.Color := 66;
end;

procedure TTestModelsI3dCorrections.DovrebbeLeggereLeCorrezioniDaTesto;
var
  LList: TArray<TI3dCorrection>;
begin
  LList := FReader.Parse('face 3 vertex 1 visible 0 x 10 y -20 z 30 tx 40 ty -50 color 7' + sLineBreak +
    'face 4 vertex 0 visible 1 x 1 y 2 z 3 tx 4 ty 5 color 6');
  Assert.AreEqual(2, Length(LList));
  Assert.AreEqual(3, LList[0].Face);
  Assert.AreEqual(1, LList[0].Vertex);
  Assert.IsFalse(LList[0].Visible);
  Assert.AreEqual(10, LList[0].X);
  Assert.AreEqual(-20, LList[0].Y);
  Assert.AreEqual(30, LList[0].Z);
  Assert.AreEqual(40, LList[0].TextureX);
  Assert.AreEqual(-50, LList[0].TextureY);
  Assert.AreEqual(7, Integer(LList[0].Color));
  Assert.AreEqual(4, LList[1].Face);
  Assert.IsTrue(LList[1].Visible);
end;

procedure TTestModelsI3dCorrections.DovrebbeSaltareLeParoleChePrecedonoLaPrimaFaccia;
var
  LList: TArray<TI3dCorrection>;
begin
  LList := FReader.Parse('these words are skipped 12 face 1 vertex 0 visible 1 x 0 y 0 z 0 tx 0 ty 0 color 0');
  Assert.AreEqual(1, Length(LList));
  Assert.AreEqual(1, LList[0].Face);
end;

procedure TTestModelsI3dCorrections.DovrebbeIgnorareICommentiELeMaiuscole;
var
  LList: TArray<TI3dCorrection>;
begin
  LList := FReader.Parse('// face 9 vertex 9' + sLineBreak +
    'FACE 2 Vertex 1 VISIBLE 1 X 5 y 6 Z 7 tx 8 TY 9 COLOR 10 // end of line' + sLineBreak);
  Assert.AreEqual(1, Length(LList));
  Assert.AreEqual(2, LList[0].Face);
  Assert.AreEqual(10, Integer(LList[0].Color));
end;

procedure TTestModelsI3dCorrections.DovrebbeLeggereNumeriEsadecimaliETroncareIlColore;
var
  LList: TArray<TI3dCorrection>;
begin
  LList := FReader.Parse('face $10 vertex 0x2 visible 2 x 0 y 0 z 0 tx 0 ty 0 color 263');
  Assert.AreEqual(16, LList[0].Face);
  Assert.AreEqual(2, LList[0].Vertex);
  Assert.IsTrue(LList[0].Visible, 'any number but 0 is visible');
  Assert.AreEqual(7, Integer(LList[0].Color), '263 is 7 as a byte');
end;

procedure TTestModelsI3dCorrections.DovrebbeSollevareUnErroreSeUnaCorrezioneEIncompleta;
begin
  Assert.WillRaise(procedure begin FReader.Parse('face 1 vertex 0 visible 1 x 1'); end, EModelsException);
  Assert.WillRaise(procedure begin FReader.Parse('face'); end, EModelsException);
end;

procedure TTestModelsI3dCorrections.DovrebbeSollevareUnErroreSeUnaChiaveEDiversa;
begin
  Assert.WillRaise(procedure begin
    FReader.Parse('face 1 vertex 0 visible 1 x 1 y 2 z 3 ty 4 tx 5 color 6');
  end, EModelsException);
end;

procedure TTestModelsI3dCorrections.DovrebbeSollevareUnErroreSeUnNumeroNonEUnNumero;
begin
  Assert.WillRaise(procedure begin
    FReader.Parse('face one vertex 0 visible 1 x 1 y 2 z 3 tx 4 ty 5 color 6');
  end, EModelsException);
end;

procedure TTestModelsI3dCorrections.DovrebbeDareUnaListaVuotaPerUnTestoSenzaCorrezioni;
begin
  Assert.AreEqual(0, Length(FReader.Parse('')));
  Assert.AreEqual(0, Length(FReader.Parse('nothing here')));
end;

procedure TTestModelsI3dCorrections.DovrebbeCorreggereUnVerticeDiUnaFaccia;
var
  LModel: II3dModel;
  LFace: TI3dFace;
  LOther: TI3dFace;
begin
  LModel := FParser.Parse(TI3dFileBuilder.SmallModel);
  LOther := LModel.GetFaces[1];
  LModel.ApplyCorrections([Correction(0, 1)]);
  LFace := LModel.GetFaces[0];
  Assert.AreEqual(11, LFace.Vertices[1].X);
  Assert.AreEqual(22, LFace.Vertices[1].Y);
  Assert.AreEqual(33, LFace.Vertices[1].Z);
  Assert.AreEqual(44, LFace.Vertices[1].TextureX);
  Assert.AreEqual(55, LFace.Vertices[1].TextureY);
  Assert.AreEqual(66, Integer(LFace.Color));
  // the other vertexes and faces are not touched; the color is the one of the face, not of the material
  Assert.AreEqual(0, LFace.Vertices[0].X);
  Assert.AreEqual(LOther.Vertices[0].X, LModel.GetFaces[1].Vertices[0].X);
  Assert.AreEqual(12, Integer(LModel.Materials[0].Color));
end;

procedure TTestModelsI3dCorrections.DovrebbeIgnorareLeCorrezioniFuoriDalModello;
var
  LModel: II3dModel;
  LBefore, LAfter: TI3dFace;
begin
  LModel := FParser.Parse(TI3dFileBuilder.SmallModel);
  LBefore := LModel.GetFaces[0];
  LModel.ApplyCorrections([Correction(-1, 0), Correction(4, 0), Correction(0, 3), Correction(0, -1)]);
  LAfter := LModel.GetFaces[0];
  Assert.AreEqual(LBefore.Vertices[0].X, LAfter.Vertices[0].X);
  Assert.AreEqual(Integer(LBefore.Color), Integer(LAfter.Color));
  Assert.IsTrue(LAfter.Visible);
end;

procedure TTestModelsI3dCorrections.DovrebbeLasciareIlColoreSeLaFacciaNonHaMateriale;
var
  LBuilder: TI3dFileBuilder;
  LModel: II3dModel;
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
  LModel.ApplyCorrections([Correction(0, 0)]);
  Assert.AreEqual(11, LModel.GetFaces[0].Vertices[0].X);
  Assert.AreEqual(0, Integer(LModel.GetFaces[0].Color));
end;

procedure TTestModelsI3dCorrections.DovrebbeMisurareDiNuovoLeGommeDopoLeCorrezioni;
var
  LModel: II3dModel;
  LCorrection: TI3dCorrection;
begin
  LModel := FParser.Parse(TI3dFileBuilder.CarModel);
  Assert.AreEqual(600000, LModel.Tires[0].Perimeter);
  // a vertex of the first tire moves up
  LCorrection := Correction(0, 0);
  LCorrection.Y := 1000000;
  LModel.ApplyCorrections([LCorrection]);
  // the lowest vertex is now the first of the second face of the tire (-260000)
  Assert.AreEqual(1260000, LModel.Tires[0].Perimeter);
  Assert.AreEqual(600000, LModel.Tires[1].Perimeter);
end;

end.

