{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the OpenGL call recorder - the client arrays           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.OpenGl.ClientArrays;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.OpenGl.Recorder.ClientArrays;

type
  [TestFixture]
  [Category('opengl')]
  TTestOpenGlClientArrays = class(TObject)
  strict private
    FArrays: TGlClientArrays;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeDareVuotoSeLArrayNonEAbilitato;
    [Test]
    procedure DovrebbeDareSconosciutoSeNonCEUnPuntatore;
    [Test]
    procedure DovrebbeDareSconosciutoSeIlTipoNonEUnoDiOpenGl;
    [Test]
    procedure DovrebbeFareLImpronteDeiSoliElementiDisegnati;
    [Test]
    procedure DovrebbeSaltareIlPaddingTraGliElementi;
    [Test]
    procedure DovrebbeUsareLaDimensioneDellElementoSeLoStrideEZero;
    [Test]
    procedure DovrebbePartireDalPrimoElementoIndicato;
    [Test]
    procedure DovrebbeTenereSeparatiVerticiECoordinateDiTexture;
    [Test]
    procedure DovrebbeSpegnereUnArrayConDisableClientState;
    [Test]
    procedure DovrebbeIgnorareUnaCapacitaNonSeguita;
    [Test]
    procedure DovrebbeDareSconosciutoSeIlConteggioENegativo;
  end;

implementation

uses
  DelphiDoom.OpenGl.Recorder.Fnv, DelphiDoom.OpenGl.Recorder.Types;

const
  GL_FLOAT = $1406;

{ TTestOpenGlClientArrays }

procedure TTestOpenGlClientArrays.Setup;
begin
  FArrays := TGlClientArrays.Create;
end;

procedure TTestOpenGlClientArrays.TearDown;
begin
  FArrays.Free;
end;

procedure TTestOpenGlClientArrays.DovrebbeDareVuotoSeLArrayNonEAbilitato;
var
  LData: array[0..5] of Single;
begin
  FArrays.SetPointer(cakVertex, 3, GL_FLOAT, 0, @LData[0]);
  Assert.AreEqual('', FArrays.Describe(cakVertex, 0, 2));
end;

procedure TTestOpenGlClientArrays.DovrebbeDareSconosciutoSeNonCEUnPuntatore;
begin
  FArrays.SetCapability(GLR_VERTEX_ARRAY, True);
  Assert.AreEqual('unknown', FArrays.Describe(cakVertex, 0, 2));
end;

procedure TTestOpenGlClientArrays.DovrebbeDareSconosciutoSeIlTipoNonEUnoDiOpenGl;
var
  LData: array[0..5] of Single;
begin
  FArrays.SetCapability(GLR_VERTEX_ARRAY, True);
  FArrays.SetPointer(cakVertex, 3, $8033, 0, @LData[0]);
  Assert.AreEqual('unknown', FArrays.Describe(cakVertex, 0, 2));
end;

procedure TTestOpenGlClientArrays.DovrebbeFareLImpronteDeiSoliElementiDisegnati;
var
  LData: array[0..8] of Single;
  LIndex: Integer;
  LExpected: string;
begin
  for LIndex := 0 to 8 do
    LData[LIndex] := LIndex;
  FArrays.SetCapability(GLR_VERTEX_ARRAY, True);
  FArrays.SetPointer(cakVertex, 3, GL_FLOAT, 0, @LData[0]);
  // due elementi di 12 byte: i primi sei Single
  LExpected := 'h:' + TGlFnv.ToHex(TGlFnv.UpdateBuffer(TGlFnv.Start, @LData[0], 24)) + '/24';
  Assert.AreEqual(LExpected, FArrays.Describe(cakVertex, 0, 2));
end;

procedure TTestOpenGlClientArrays.DovrebbeSaltareIlPaddingTraGliElementi;
var
  LFirst: array[0..7] of Single;
  LSecond: array[0..7] of Single;
  LIndex: Integer;
  LOne: string;
begin
  // due elementi con stride 16 e 3 float: il quarto float di ogni elemento e padding
  for LIndex := 0 to 7 do
  begin
    LFirst[LIndex] := LIndex;
    LSecond[LIndex] := LIndex;
  end;
  LFirst[3] := 111;
  LSecond[3] := 222;
  LFirst[7] := 333;
  LSecond[7] := 444;
  FArrays.SetCapability(GLR_VERTEX_ARRAY, True);
  FArrays.SetPointer(cakVertex, 3, GL_FLOAT, 16, @LFirst[0]);
  LOne := FArrays.Describe(cakVertex, 0, 2);
  FArrays.SetPointer(cakVertex, 3, GL_FLOAT, 16, @LSecond[0]);
  Assert.AreEqual(LOne, FArrays.Describe(cakVertex, 0, 2));
  Assert.IsTrue(LOne.EndsWith('/24'));
end;

procedure TTestOpenGlClientArrays.DovrebbeUsareLaDimensioneDellElementoSeLoStrideEZero;
var
  LData: array[0..5] of Single;
  LWithStride: string;
begin
  FillChar(LData, SizeOf(LData), 1);
  FArrays.SetCapability(GLR_VERTEX_ARRAY, True);
  FArrays.SetPointer(cakVertex, 3, GL_FLOAT, 0, @LData[0]);
  LWithStride := FArrays.Describe(cakVertex, 0, 2);
  FArrays.SetPointer(cakVertex, 3, GL_FLOAT, 12, @LData[0]);
  Assert.AreEqual(LWithStride, FArrays.Describe(cakVertex, 0, 2));
end;

procedure TTestOpenGlClientArrays.DovrebbePartireDalPrimoElementoIndicato;
var
  LData: array[0..8] of Single;
  LIndex: Integer;
  LExpected: string;
begin
  for LIndex := 0 to 8 do
    LData[LIndex] := LIndex;
  FArrays.SetCapability(GLR_VERTEX_ARRAY, True);
  FArrays.SetPointer(cakVertex, 3, GL_FLOAT, 0, @LData[0]);
  // l'ultimo elemento: gli ultimi tre Single
  LExpected := 'h:' + TGlFnv.ToHex(TGlFnv.UpdateBuffer(TGlFnv.Start, @LData[6], 12)) + '/12';
  Assert.AreEqual(LExpected, FArrays.Describe(cakVertex, 2, 1));
end;

procedure TTestOpenGlClientArrays.DovrebbeTenereSeparatiVerticiECoordinateDiTexture;
var
  LVertices: array[0..5] of Single;
  LCoordinates: array[0..3] of Single;
begin
  FillChar(LVertices, SizeOf(LVertices), 1);
  FillChar(LCoordinates, SizeOf(LCoordinates), 2);
  FArrays.SetCapability(GLR_VERTEX_ARRAY, True);
  FArrays.SetCapability(GLR_TEXTURE_COORD_ARRAY, True);
  FArrays.SetPointer(cakVertex, 3, GL_FLOAT, 0, @LVertices[0]);
  FArrays.SetPointer(cakTexCoord, 2, GL_FLOAT, 0, @LCoordinates[0]);
  Assert.IsTrue(FArrays.Describe(cakVertex, 0, 2).EndsWith('/24'));
  Assert.IsTrue(FArrays.Describe(cakTexCoord, 0, 2).EndsWith('/16'));
end;

procedure TTestOpenGlClientArrays.DovrebbeSpegnereUnArrayConDisableClientState;
var
  LData: array[0..5] of Single;
begin
  FillChar(LData, SizeOf(LData), 1);
  FArrays.SetPointer(cakVertex, 3, GL_FLOAT, 0, @LData[0]);
  FArrays.SetCapability(GLR_VERTEX_ARRAY, True);
  FArrays.SetCapability(GLR_VERTEX_ARRAY, False);
  Assert.AreEqual('', FArrays.Describe(cakVertex, 0, 2));
end;

procedure TTestOpenGlClientArrays.DovrebbeIgnorareUnaCapacitaNonSeguita;
var
  LData: array[0..5] of Single;
begin
  FillChar(LData, SizeOf(LData), 1);
  FArrays.SetPointer(cakVertex, 3, GL_FLOAT, 0, @LData[0]);
  FArrays.SetCapability($8076, True);  // GL_COLOR_ARRAY
  Assert.AreEqual('', FArrays.Describe(cakVertex, 0, 2));
end;

procedure TTestOpenGlClientArrays.DovrebbeDareSconosciutoSeIlConteggioENegativo;
var
  LData: array[0..5] of Single;
begin
  FillChar(LData, SizeOf(LData), 1);
  FArrays.SetPointer(cakVertex, 3, GL_FLOAT, 0, @LData[0]);
  FArrays.SetCapability(GLR_VERTEX_ARRAY, True);
  Assert.AreEqual('unknown', FArrays.Describe(cakVertex, 0, -1));
end;

end.
