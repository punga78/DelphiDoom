{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the OpenGL call recorder - the text of a call          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.OpenGl.Encoder;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.OpenGl.Recorder.Encoder, DelphiDoom.OpenGl.Recorder.Types;

type
  [TestFixture]
  [Category('opengl')]
  TTestOpenGlEncoder = class(TObject)
  strict private
    FEncoder: TGlCallEncoder;
    function BlockText(const AData; const ASize: Integer): string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeScrivereIFloatConIloroBit;
    [Test]
    procedure DovrebbeScrivereIDoubleConIloroBit;
    [Test]
    procedure DovrebbeScrivereGliEnumInEsadecimale;
    [Test]
    procedure DovrebbeScrivereGliInteriInDecimaleAncheNegativi;
    [Test]
    procedure DovrebbeScrivereUnaChiamataSenzaArgomenti;
    [Test]
    procedure DovrebbeScrivereNilPerUnPuntatoreNil;
    [Test]
    procedure DovrebbeScrivereSoloPtrPerUnPuntatoreDiUscita;
    [Test]
    procedure DovrebbeNonScrivereMaiLIndirizzo;
    [Test]
    procedure DovrebbeFareLImpronteDelVettoreDiColor4fv;
    [Test]
    procedure DovrebbeScrivereNilPerUnVettoreNil;
    [Test]
    procedure DovrebbeFareLImpronteDiTexCoord2fvVertex3fvEMatrici;
    [Test]
    procedure DovrebbeLeggereQuattroFloatPerIlColoreDellaNebbia;
    [Test]
    procedure DovrebbeLeggereUnFloatPerLaDensitaDellaNebbia;
    [Test]
    procedure DovrebbeLeggerePerIlModoDiTexGenUnFloatEPerIPianiQuattro;
    [Test]
    procedure DovrebbeFareLImpronteDeiNomiDelleTextureDaCancellare;
    [Test]
    procedure DovrebbeFareLImpronteDeiPixelDiTexImage2D;
    [Test]
    procedure DovrebbeIgnorareIlPaddingDelleRighe;
    [Test]
    procedure DovrebbeSeguireLAllineamentoDiPixelStorei;
    [Test]
    procedure DovrebbeTenereLAllineamentoTraUnaChiamataEUnAltra;
    [Test]
    procedure DovrebbeScrivereSoloPtrSeLaLunghezzaDellaRigaNonEZero;
    [Test]
    procedure DovrebbeTornareAFareLImpronteSeLaLunghezzaDellaRigaTornaAZero;
    [Test]
    procedure DovrebbeScrivereSoloPtrPerUnTipoImpacchettato;
    [Test]
    procedure DovrebbeScrivereNilPerPixelNil;
    [Test]
    procedure DovrebbeLeggereLaPosizioneGiustaInTexSubImage2D;
    [Test]
    procedure DovrebbeFareLImpronteDeiPixelDiTexImage3D;
    [Test]
    procedure DovrebbeFareLImpronteDeiPixelDiGluBuild2DMipmaps;
    [Test]
    procedure DovrebbeFareLImpronteDellaPaletteDiColorTable;
    [Test]
    procedure DovrebbeAggiungereGliArrayACuiPuntaDrawArrays;
    [Test]
    procedure DovrebbeNonAggiungereNullaSeGliArrayNonSonoAbilitati;
    [Test]
    procedure DovrebbeSegnareSconosciutoUnArrayAbilitatoSenzaPuntatore;
    [Test]
    procedure DovrebbeNonFallireSeGliArgomentiSonoMenoDelPrevisto;
    [Test]
    procedure DovrebbeAvereUnaRegolaPerOgniFunzioneConIlContenuto;
  end;

implementation

uses
  DelphiDoom.OpenGl.Recorder.Fnv;

const
  GL_TEXTURE_2D = $0DE1;
  GL_RGBA = $1908;
  GL_RGB = $1907;
  GL_UNSIGNED_BYTE = $1401;
  GL_FLOAT = $1406;

{ TTestOpenGlEncoder }

procedure TTestOpenGlEncoder.Setup;
begin
  FEncoder := TGlCallEncoder.Create;
end;

procedure TTestOpenGlEncoder.TearDown;
begin
  FEncoder.Free;
end;

function TTestOpenGlEncoder.BlockText(const AData; const ASize: Integer): string;
begin
  Result := 'h:' + TGlFnv.ToHex(TGlFnv.UpdateBuffer(TGlFnv.Start, @AData, ASize)) + '/' + IntToStr(ASize);
end;

procedure TTestOpenGlEncoder.DovrebbeScrivereIFloatConIloroBit;
begin
  Assert.AreEqual('glVertex3f(#3F800000,#40000000,#C0400000)',
    FEncoder.Encode('glVertex3f', [TGlValue.FromSingle(1.0), TGlValue.FromSingle(2.0), TGlValue.FromSingle(-3.0)]));
end;

procedure TTestOpenGlEncoder.DovrebbeScrivereIDoubleConIloroBit;
begin
  Assert.AreEqual('gluPerspective(#3FF0000000000000)',
    FEncoder.Encode('gluPerspective', [TGlValue.FromDouble(1.0)]));
end;

procedure TTestOpenGlEncoder.DovrebbeScrivereGliEnumInEsadecimale;
begin
  Assert.AreEqual('glEnable($0DE1)', FEncoder.Encode('glEnable', [TGlValue.FromEnum(GL_TEXTURE_2D)]));
  Assert.AreEqual('glBegin($0007)', FEncoder.Encode('glBegin', [TGlValue.FromEnum(7)]));
end;

procedure TTestOpenGlEncoder.DovrebbeScrivereGliInteriInDecimaleAncheNegativi;
begin
  Assert.AreEqual('glViewport(0,-5,640,480)',
    FEncoder.Encode('glViewport', [TGlValue.FromInteger(0), TGlValue.FromInteger(-5), TGlValue.FromInteger(640),
      TGlValue.FromInteger(480)]));
end;

procedure TTestOpenGlEncoder.DovrebbeScrivereUnaChiamataSenzaArgomenti;
begin
  Assert.AreEqual('glEnd()', FEncoder.Encode('glEnd', []));
end;

procedure TTestOpenGlEncoder.DovrebbeScrivereNilPerUnPuntatoreNil;
begin
  Assert.AreEqual('glGetString($1F00)', FEncoder.Encode('glGetString', [TGlValue.FromEnum($1F00)]));
  Assert.AreEqual('glGetIntegerv($0BA2,nil)', FEncoder.Encode('glGetIntegerv',
    [TGlValue.FromEnum($0BA2), TGlValue.FromPointer(nil)]));
end;

procedure TTestOpenGlEncoder.DovrebbeScrivereSoloPtrPerUnPuntatoreDiUscita;
var
  LValue: Integer;
begin
  Assert.AreEqual('glGetIntegerv($0BA2,ptr)', FEncoder.Encode('glGetIntegerv',
    [TGlValue.FromEnum($0BA2), TGlValue.FromPointer(@LValue)]));
end;

procedure TTestOpenGlEncoder.DovrebbeNonScrivereMaiLIndirizzo;
var
  LFirst: Integer;
  LSecond: Integer;
begin
  Assert.AreEqual(
    FEncoder.Encode('glGenTextures', [TGlValue.FromInteger(1), TGlValue.FromPointer(@LFirst)]),
    FEncoder.Encode('glGenTextures', [TGlValue.FromInteger(1), TGlValue.FromPointer(@LSecond)]));
end;

procedure TTestOpenGlEncoder.DovrebbeFareLImpronteDelVettoreDiColor4fv;
var
  LColor: array[0..3] of Single;
begin
  LColor[0] := 1;
  LColor[1] := 0.5;
  LColor[2] := 0.25;
  LColor[3] := 1;
  Assert.AreEqual('glColor4fv(' + BlockText(LColor, 16) + ')',
    FEncoder.Encode('glColor4fv', [TGlValue.FromPointer(@LColor[0])]));
end;

procedure TTestOpenGlEncoder.DovrebbeScrivereNilPerUnVettoreNil;
begin
  Assert.AreEqual('glColor4fv(nil)', FEncoder.Encode('glColor4fv', [TGlValue.FromPointer(nil)]));
end;

procedure TTestOpenGlEncoder.DovrebbeFareLImpronteDiTexCoord2fvVertex3fvEMatrici;
var
  LTwo: array[0..1] of Single;
  LThree: array[0..2] of Single;
  LMatrixF: array[0..15] of Single;
  LMatrixD: array[0..15] of Double;
begin
  FillChar(LTwo, SizeOf(LTwo), 1);
  FillChar(LThree, SizeOf(LThree), 2);
  FillChar(LMatrixF, SizeOf(LMatrixF), 3);
  FillChar(LMatrixD, SizeOf(LMatrixD), 4);
  Assert.AreEqual('glTexCoord2fv(' + BlockText(LTwo, 8) + ')',
    FEncoder.Encode('glTexCoord2fv', [TGlValue.FromPointer(@LTwo[0])]));
  Assert.AreEqual('glVertex3fv(' + BlockText(LThree, 12) + ')',
    FEncoder.Encode('glVertex3fv', [TGlValue.FromPointer(@LThree[0])]));
  Assert.AreEqual('glMultMatrixf(' + BlockText(LMatrixF, 64) + ')',
    FEncoder.Encode('glMultMatrixf', [TGlValue.FromPointer(@LMatrixF[0])]));
  Assert.AreEqual('glMultMatrixd(' + BlockText(LMatrixD, 128) + ')',
    FEncoder.Encode('glMultMatrixd', [TGlValue.FromPointer(@LMatrixD[0])]));
end;

procedure TTestOpenGlEncoder.DovrebbeLeggereQuattroFloatPerIlColoreDellaNebbia;
var
  LColor: array[0..3] of Single;
begin
  FillChar(LColor, SizeOf(LColor), 5);
  Assert.AreEqual('glFogfv($0B66,' + BlockText(LColor, 16) + ')',
    FEncoder.Encode('glFogfv', [TGlValue.FromEnum($0B66), TGlValue.FromPointer(@LColor[0])]));
end;

procedure TTestOpenGlEncoder.DovrebbeLeggereUnFloatPerLaDensitaDellaNebbia;
var
  LDensity: Single;
begin
  LDensity := 0.5;
  Assert.AreEqual('glFogfv($0B62,' + BlockText(LDensity, 4) + ')',
    FEncoder.Encode('glFogfv', [TGlValue.FromEnum($0B62), TGlValue.FromPointer(@LDensity)]));
end;

procedure TTestOpenGlEncoder.DovrebbeLeggerePerIlModoDiTexGenUnFloatEPerIPianiQuattro;
var
  LPlane: array[0..3] of Single;
begin
  FillChar(LPlane, SizeOf(LPlane), 6);
  Assert.AreEqual('glTexGenfv($2000,$2500,' + BlockText(LPlane, 4) + ')',
    FEncoder.Encode('glTexGenfv', [TGlValue.FromEnum($2000), TGlValue.FromEnum($2500),
      TGlValue.FromPointer(@LPlane[0])]));
  Assert.AreEqual('glTexGenfv($2000,$2501,' + BlockText(LPlane, 16) + ')',
    FEncoder.Encode('glTexGenfv', [TGlValue.FromEnum($2000), TGlValue.FromEnum($2501),
      TGlValue.FromPointer(@LPlane[0])]));
end;

procedure TTestOpenGlEncoder.DovrebbeFareLImpronteDeiNomiDelleTextureDaCancellare;
var
  LNames: array[0..2] of Cardinal;
begin
  LNames[0] := 7;
  LNames[1] := 8;
  LNames[2] := 9;
  Assert.AreEqual('glDeleteTextures(3,' + BlockText(LNames, 12) + ')',
    FEncoder.Encode('glDeleteTextures', [TGlValue.FromInteger(3), TGlValue.FromPointer(@LNames[0])]));
end;

procedure TTestOpenGlEncoder.DovrebbeFareLImpronteDeiPixelDiTexImage2D;
var
  LPixels: array[0..15] of Byte;
  LIndex: Integer;
begin
  for LIndex := 0 to 15 do
    LPixels[LIndex] := LIndex;
  Assert.AreEqual('glTexImage2D($0DE1,0,6408,2,2,0,$1908,$1401,' + BlockText(LPixels, 16) + ')',
    FEncoder.Encode('glTexImage2D', [TGlValue.FromEnum(GL_TEXTURE_2D), TGlValue.FromInteger(0),
      TGlValue.FromInteger(6408), TGlValue.FromInteger(2), TGlValue.FromInteger(2), TGlValue.FromInteger(0),
      TGlValue.FromEnum(GL_RGBA), TGlValue.FromEnum(GL_UNSIGNED_BYTE), TGlValue.FromPointer(@LPixels[0])]));
end;

procedure TTestOpenGlEncoder.DovrebbeIgnorareIlPaddingDelleRighe;
var
  LZero: array[0..23] of Byte;
  LFull: array[0..23] of Byte;
  LIndex: Integer;
  function Encode(var APixels: array of Byte): string;
  begin
    Result := FEncoder.Encode('glTexImage2D', [TGlValue.FromEnum(GL_TEXTURE_2D), TGlValue.FromInteger(0),
      TGlValue.FromInteger(3), TGlValue.FromInteger(3), TGlValue.FromInteger(2), TGlValue.FromInteger(0),
      TGlValue.FromEnum(GL_RGB), TGlValue.FromEnum(GL_UNSIGNED_BYTE), TGlValue.FromPointer(@APixels[0])]);
  end;
begin
  // 3x2 RGB con allineamento 4: righe di 9 byte, la seconda comincia a 12; i byte 9..11 e 21..23 sono padding
  for LIndex := 0 to 23 do
  begin
    LZero[LIndex] := LIndex;
    LFull[LIndex] := LIndex;
  end;
  for LIndex := 9 to 11 do
  begin
    LZero[LIndex] := 0;
    LFull[LIndex] := $FF;
  end;
  LZero[21] := 0;
  LFull[21] := $FF;
  Assert.AreEqual(Encode(LZero), Encode(LFull));
  Assert.IsTrue(Encode(LZero).EndsWith('/18)'));
end;

procedure TTestOpenGlEncoder.DovrebbeSeguireLAllineamentoDiPixelStorei;
var
  LPixels: array[0..17] of Byte;
  LIndex: Integer;
begin
  for LIndex := 0 to 17 do
    LPixels[LIndex] := LIndex + 1;
  FEncoder.Encode('glPixelStorei', [TGlValue.FromEnum(GLR_UNPACK_ALIGNMENT), TGlValue.FromInteger(1)]);
  // con allineamento 1 le righe sono contigue: l'impronta e quella dei 18 byte
  Assert.AreEqual('glTexImage2D($0DE1,0,3,3,2,0,$1907,$1401,' + BlockText(LPixels, 18) + ')',
    FEncoder.Encode('glTexImage2D', [TGlValue.FromEnum(GL_TEXTURE_2D), TGlValue.FromInteger(0),
      TGlValue.FromInteger(3), TGlValue.FromInteger(3), TGlValue.FromInteger(2), TGlValue.FromInteger(0),
      TGlValue.FromEnum(GL_RGB), TGlValue.FromEnum(GL_UNSIGNED_BYTE), TGlValue.FromPointer(@LPixels[0])]));
end;

procedure TTestOpenGlEncoder.DovrebbeTenereLAllineamentoTraUnaChiamataEUnAltra;
var
  LPixels: array[0..23] of Byte;
  LFirst: string;
  LSecond: string;
begin
  FillChar(LPixels, SizeOf(LPixels), 9);
  FEncoder.Encode('glPixelStorei', [TGlValue.FromEnum(GLR_UNPACK_ALIGNMENT), TGlValue.FromInteger(1)]);
  LFirst := FEncoder.Encode('glTexImage2D', [TGlValue.FromEnum(GL_TEXTURE_2D), TGlValue.FromInteger(0),
    TGlValue.FromInteger(3), TGlValue.FromInteger(3), TGlValue.FromInteger(2), TGlValue.FromInteger(0),
    TGlValue.FromEnum(GL_RGB), TGlValue.FromEnum(GL_UNSIGNED_BYTE), TGlValue.FromPointer(@LPixels[0])]);
  LSecond := FEncoder.Encode('glTexImage2D', [TGlValue.FromEnum(GL_TEXTURE_2D), TGlValue.FromInteger(0),
    TGlValue.FromInteger(3), TGlValue.FromInteger(3), TGlValue.FromInteger(2), TGlValue.FromInteger(0),
    TGlValue.FromEnum(GL_RGB), TGlValue.FromEnum(GL_UNSIGNED_BYTE), TGlValue.FromPointer(@LPixels[0])]);
  Assert.AreEqual(LFirst, LSecond);
end;

procedure TTestOpenGlEncoder.DovrebbeScrivereSoloPtrSeLaLunghezzaDellaRigaNonEZero;
var
  LPixels: array[0..15] of Byte;
begin
  FillChar(LPixels, SizeOf(LPixels), 1);
  FEncoder.Encode('glPixelStorei', [TGlValue.FromEnum(GLR_UNPACK_ROW_LENGTH), TGlValue.FromInteger(8)]);
  Assert.AreEqual('glTexImage2D($0DE1,0,6408,2,2,0,$1908,$1401,ptr)',
    FEncoder.Encode('glTexImage2D', [TGlValue.FromEnum(GL_TEXTURE_2D), TGlValue.FromInteger(0),
      TGlValue.FromInteger(6408), TGlValue.FromInteger(2), TGlValue.FromInteger(2), TGlValue.FromInteger(0),
      TGlValue.FromEnum(GL_RGBA), TGlValue.FromEnum(GL_UNSIGNED_BYTE), TGlValue.FromPointer(@LPixels[0])]));
end;

procedure TTestOpenGlEncoder.DovrebbeTornareAFareLImpronteSeLaLunghezzaDellaRigaTornaAZero;
var
  LPixels: array[0..15] of Byte;
begin
  FillChar(LPixels, SizeOf(LPixels), 1);
  FEncoder.Encode('glPixelStorei', [TGlValue.FromEnum(GLR_UNPACK_ROW_LENGTH), TGlValue.FromInteger(8)]);
  FEncoder.Encode('glPixelStorei', [TGlValue.FromEnum(GLR_UNPACK_ROW_LENGTH), TGlValue.FromInteger(0)]);
  Assert.IsTrue(FEncoder.Encode('glTexImage2D', [TGlValue.FromEnum(GL_TEXTURE_2D), TGlValue.FromInteger(0),
    TGlValue.FromInteger(6408), TGlValue.FromInteger(2), TGlValue.FromInteger(2), TGlValue.FromInteger(0),
    TGlValue.FromEnum(GL_RGBA), TGlValue.FromEnum(GL_UNSIGNED_BYTE), TGlValue.FromPointer(@LPixels[0])])
    .Contains('h:'));
end;

procedure TTestOpenGlEncoder.DovrebbeScrivereSoloPtrPerUnTipoImpacchettato;
var
  LPixels: array[0..15] of Byte;
begin
  Assert.AreEqual('glTexImage2D($0DE1,0,6408,2,2,0,$1908,$8033,ptr)',
    FEncoder.Encode('glTexImage2D', [TGlValue.FromEnum(GL_TEXTURE_2D), TGlValue.FromInteger(0),
      TGlValue.FromInteger(6408), TGlValue.FromInteger(2), TGlValue.FromInteger(2), TGlValue.FromInteger(0),
      TGlValue.FromEnum(GL_RGBA), TGlValue.FromEnum($8033), TGlValue.FromPointer(@LPixels[0])]));
end;

procedure TTestOpenGlEncoder.DovrebbeScrivereNilPerPixelNil;
begin
  Assert.AreEqual('glTexImage2D($0DE1,0,6408,2,2,0,$1908,$1401,nil)',
    FEncoder.Encode('glTexImage2D', [TGlValue.FromEnum(GL_TEXTURE_2D), TGlValue.FromInteger(0),
      TGlValue.FromInteger(6408), TGlValue.FromInteger(2), TGlValue.FromInteger(2), TGlValue.FromInteger(0),
      TGlValue.FromEnum(GL_RGBA), TGlValue.FromEnum(GL_UNSIGNED_BYTE), TGlValue.FromPointer(nil)]));
end;

procedure TTestOpenGlEncoder.DovrebbeLeggereLaPosizioneGiustaInTexSubImage2D;
var
  LPixels: array[0..7] of Byte;
begin
  FillChar(LPixels, SizeOf(LPixels), 7);
  // glTexSubImage2D(target, level, xoffset, yoffset, width, height, format, type, pixels): 2x1 RGBA = 8 byte
  Assert.AreEqual('glTexSubImage2D($0DE1,0,4,5,2,1,$1908,$1401,' + BlockText(LPixels, 8) + ')',
    FEncoder.Encode('glTexSubImage2D', [TGlValue.FromEnum(GL_TEXTURE_2D), TGlValue.FromInteger(0),
      TGlValue.FromInteger(4), TGlValue.FromInteger(5), TGlValue.FromInteger(2), TGlValue.FromInteger(1),
      TGlValue.FromEnum(GL_RGBA), TGlValue.FromEnum(GL_UNSIGNED_BYTE), TGlValue.FromPointer(@LPixels[0])]));
end;

procedure TTestOpenGlEncoder.DovrebbeFareLImpronteDeiPixelDiTexImage3D;
var
  LPixels: array[0..31] of Byte;
begin
  FillChar(LPixels, SizeOf(LPixels), 8);
  // 2x2x2 RGBA = 32 byte
  Assert.AreEqual('glTexImage3D($806F,0,6408,2,2,2,0,$1908,$1401,' + BlockText(LPixels, 32) + ')',
    FEncoder.Encode('glTexImage3D', [TGlValue.FromEnum($806F), TGlValue.FromInteger(0), TGlValue.FromInteger(6408),
      TGlValue.FromInteger(2), TGlValue.FromInteger(2), TGlValue.FromInteger(2), TGlValue.FromInteger(0),
      TGlValue.FromEnum(GL_RGBA), TGlValue.FromEnum(GL_UNSIGNED_BYTE), TGlValue.FromPointer(@LPixels[0])]));
end;

procedure TTestOpenGlEncoder.DovrebbeFareLImpronteDeiPixelDiGluBuild2DMipmaps;
var
  LPixels: array[0..15] of Byte;
begin
  FillChar(LPixels, SizeOf(LPixels), 3);
  Assert.AreEqual('gluBuild2DMipmaps($0DE1,4,2,2,$1908,$1401,' + BlockText(LPixels, 16) + ')',
    FEncoder.Encode('gluBuild2DMipmaps', [TGlValue.FromEnum(GL_TEXTURE_2D), TGlValue.FromInteger(4),
      TGlValue.FromInteger(2), TGlValue.FromInteger(2), TGlValue.FromEnum(GL_RGBA),
      TGlValue.FromEnum(GL_UNSIGNED_BYTE), TGlValue.FromPointer(@LPixels[0])]));
end;

procedure TTestOpenGlEncoder.DovrebbeFareLImpronteDellaPaletteDiColorTable;
var
  LPalette: array[0..767] of Byte;
begin
  FillChar(LPalette, SizeOf(LPalette), 2);
  // 256 voci RGB a 8 bit = 768 byte
  Assert.AreEqual('glColorTableEXT($0DE1,$1907,256,$1907,$1401,' + BlockText(LPalette, 768) + ')',
    FEncoder.Encode('glColorTableEXT', [TGlValue.FromEnum(GL_TEXTURE_2D), TGlValue.FromEnum(6407),
      TGlValue.FromInteger(256), TGlValue.FromEnum(GL_RGB), TGlValue.FromEnum(GL_UNSIGNED_BYTE),
      TGlValue.FromPointer(@LPalette[0])]));
end;

procedure TTestOpenGlEncoder.DovrebbeAggiungereGliArrayACuiPuntaDrawArrays;
var
  LVertices: array[0..8] of Single;
  LCoordinates: array[0..5] of Single;
  LIndex: Integer;
begin
  for LIndex := 0 to 8 do
    LVertices[LIndex] := LIndex;
  for LIndex := 0 to 5 do
    LCoordinates[LIndex] := LIndex * 0.5;
  FEncoder.Encode('glEnableClientState', [TGlValue.FromEnum(GLR_VERTEX_ARRAY)]);
  FEncoder.Encode('glEnableClientState', [TGlValue.FromEnum(GLR_TEXTURE_COORD_ARRAY)]);
  FEncoder.Encode('glVertexPointer', [TGlValue.FromInteger(3), TGlValue.FromEnum(GL_FLOAT), TGlValue.FromInteger(0),
    TGlValue.FromPointer(@LVertices[0])]);
  FEncoder.Encode('glTexCoordPointer', [TGlValue.FromInteger(2), TGlValue.FromEnum(GL_FLOAT),
    TGlValue.FromInteger(0), TGlValue.FromPointer(@LCoordinates[0])]);
  Assert.AreEqual('glDrawArrays($0009,0,3,vertex=' + BlockText(LVertices, 36) + ',texcoord='
    + BlockText(LCoordinates, 24) + ')',
    FEncoder.Encode('glDrawArrays', [TGlValue.FromEnum(9), TGlValue.FromInteger(0), TGlValue.FromInteger(3)]));
end;

procedure TTestOpenGlEncoder.DovrebbeNonAggiungereNullaSeGliArrayNonSonoAbilitati;
var
  LVertices: array[0..8] of Single;
begin
  FillChar(LVertices, SizeOf(LVertices), 1);
  FEncoder.Encode('glVertexPointer', [TGlValue.FromInteger(3), TGlValue.FromEnum(GL_FLOAT), TGlValue.FromInteger(0),
    TGlValue.FromPointer(@LVertices[0])]);
  Assert.AreEqual('glDrawArrays($0009,0,3)',
    FEncoder.Encode('glDrawArrays', [TGlValue.FromEnum(9), TGlValue.FromInteger(0), TGlValue.FromInteger(3)]));
end;

procedure TTestOpenGlEncoder.DovrebbeSegnareSconosciutoUnArrayAbilitatoSenzaPuntatore;
begin
  FEncoder.Encode('glEnableClientState', [TGlValue.FromEnum(GLR_VERTEX_ARRAY)]);
  Assert.AreEqual('glDrawArrays($0009,0,3,vertex=unknown)',
    FEncoder.Encode('glDrawArrays', [TGlValue.FromEnum(9), TGlValue.FromInteger(0), TGlValue.FromInteger(3)]));
end;

procedure TTestOpenGlEncoder.DovrebbeNonFallireSeGliArgomentiSonoMenoDelPrevisto;
begin
  Assert.AreEqual('glTexImage2D($0DE1,0)',
    FEncoder.Encode('glTexImage2D', [TGlValue.FromEnum(GL_TEXTURE_2D), TGlValue.FromInteger(0)]));
  Assert.AreEqual('glDrawArrays()', FEncoder.Encode('glDrawArrays', []));
end;

procedure TTestOpenGlEncoder.DovrebbeAvereUnaRegolaPerOgniFunzioneConIlContenuto;
var
  LNames: TArray<string>;
begin
  LNames := FEncoder.RuleNames;
  Assert.AreEqual(20, Length(LNames));
  Assert.IsTrue(string.Join(',', LNames).Contains('glTexImage2D'));
  Assert.IsTrue(string.Join(',', LNames).Contains('glDrawArrays'));
end;

end.
