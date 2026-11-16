{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the OpenGL scene - the shared texture palette          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.OpenGl.SharedPalette;

interface

uses
  DUnitX.TestFramework,
  DelphiDoom.GlScene.SharedPalette;

type
  [TestFixture]
  [Category('opengl')]
  TTestOpenGlSharedPalette = class(TObject)
  strict private
    FColors: array[0..767] of Byte;
    FColormap: array[0..255] of Byte;
    FTable: array[0..GL_SHARED_PALETTE_BYTES - 1] of Byte;
    FExpected: array[0..GL_SHARED_PALETTE_BYTES - 1] of Byte;
    // the text of the shared palette branch of gld_SetPalette of gl_render.pas before TGlSceneSharedPalette
    procedure OldBuild(AUseColormap: Boolean; ATransparentIndex: Integer);
    procedure CheckSameAsOld(AUseColormap: Boolean; ATransparentIndex: Integer);
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure DovrebbeDareLaStessaTabellaDelVecchioSenzaColormap;
    [Test]
    procedure DovrebbeDareLaStessaTabellaDelVecchioConLaColormapFissa;
    [Test]
    procedure DovrebbeDareLaStessaTabellaDelVecchioPerOgniIndiceTrasparente;
    [Test]
    procedure DovrebbeRendereOpacheTutteLeVociTranneLaTrasparente;
    [Test]
    procedure DovrebbeRendereTrasparenteNeroLaVoceIndicata;
    [Test]
    procedure DovrebbeLasciareTutteOpacheSeLIndiceTrasparenteEFuoriDallaTabella;
    [Test]
    procedure DovrebbeScegliereIlColoreConLaColormap;
  end;

implementation

uses
  System.SysUtils;

{ TTestOpenGlSharedPalette }

procedure TTestOpenGlSharedPalette.Setup;
var
  LIndex: Integer;
begin
  RandSeed := 248;
  for LIndex := 0 to High(FColors) do
    FColors[LIndex] := Random(256);
  for LIndex := 0 to High(FColormap) do
    FColormap[LIndex] := Random(256);
end;

procedure TTestOpenGlSharedPalette.OldBuild(AUseColormap: Boolean; ATransparentIndex: Integer);
var
  plpal: PByteArray;
  fixedcolormap: PByteArray;
  pal: array[0..1023] of Byte;
  i: Integer;
  col, pcol: Integer;
begin
  plpal := @FColors[0];
  if AUseColormap then
    fixedcolormap := @FColormap[0]
  else
    fixedcolormap := nil;
  FillChar(pal, SizeOf(pal), 0);
  if fixedcolormap <> nil then
  begin
    for i := 0 to 255 do
    begin
      col := 3 * fixedcolormap[i];
      pcol := i * 4;
      pal[pcol] := plpal[col];
      pal[pcol + 1] := plpal[col + 1];
      pal[pcol + 2] := plpal[col + 2];
      pal[pcol + 3] := 255;
    end;
  end
  else
  begin
    for i := 0 to 255 do
    begin
      col := 3 * i;
      pcol := col + i;
      pal[pcol] := plpal[col];
      pal[pcol + 1] := plpal[col + 1];
      pal[pcol + 2] := plpal[col + 2];
      pal[pcol + 3] := 255;
    end;
  end;

  pcol := ATransparentIndex * 4;
  pal[pcol] := 0;
  pal[pcol + 1] := 0;
  pal[pcol + 2] := 0;
  pal[pcol + 3] := 0;
  Move(pal, FExpected, SizeOf(pal));
end;

procedure TTestOpenGlSharedPalette.CheckSameAsOld(AUseColormap: Boolean; ATransparentIndex: Integer);
var
  LColormap: PByte;
  LIndex: Integer;
begin
  OldBuild(AUseColormap, ATransparentIndex);
  if AUseColormap then
    LColormap := @FColormap[0]
  else
    LColormap := nil;
  FillChar(FTable, SizeOf(FTable), $AA);
  TGlSceneSharedPalette.Build(@FColors[0], LColormap, ATransparentIndex, @FTable[0]);
  for LIndex := 0 to High(FTable) do
    Assert.AreEqual(FExpected[LIndex], FTable[LIndex], 'byte ' + IntToStr(LIndex));
end;

procedure TTestOpenGlSharedPalette.DovrebbeDareLaStessaTabellaDelVecchioSenzaColormap;
begin
  CheckSameAsOld(False, 255);
end;

procedure TTestOpenGlSharedPalette.DovrebbeDareLaStessaTabellaDelVecchioConLaColormapFissa;
begin
  CheckSameAsOld(True, 0);
end;

procedure TTestOpenGlSharedPalette.DovrebbeDareLaStessaTabellaDelVecchioPerOgniIndiceTrasparente;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 255 do
  begin
    CheckSameAsOld(False, LIndex);
    CheckSameAsOld(True, LIndex);
  end;
end;

procedure TTestOpenGlSharedPalette.DovrebbeRendereOpacheTutteLeVociTranneLaTrasparente;
var
  LIndex: Integer;
begin
  TGlSceneSharedPalette.Build(@FColors[0], nil, 17, @FTable[0]);
  for LIndex := 0 to 255 do
    if LIndex <> 17 then
      Assert.AreEqual<Byte>(255, FTable[LIndex * 4 + 3], 'entry ' + IntToStr(LIndex));
end;

procedure TTestOpenGlSharedPalette.DovrebbeRendereTrasparenteNeroLaVoceIndicata;
begin
  TGlSceneSharedPalette.Build(@FColors[0], nil, 17, @FTable[0]);
  Assert.AreEqual<Byte>(0, FTable[17 * 4]);
  Assert.AreEqual<Byte>(0, FTable[17 * 4 + 1]);
  Assert.AreEqual<Byte>(0, FTable[17 * 4 + 2]);
  Assert.AreEqual<Byte>(0, FTable[17 * 4 + 3]);
end;

procedure TTestOpenGlSharedPalette.DovrebbeLasciareTutteOpacheSeLIndiceTrasparenteEFuoriDallaTabella;
var
  LIndex: Integer;
begin
  TGlSceneSharedPalette.Build(@FColors[0], nil, 256, @FTable[0]);
  for LIndex := 0 to 255 do
    Assert.AreEqual<Byte>(255, FTable[LIndex * 4 + 3]);
  TGlSceneSharedPalette.Build(@FColors[0], nil, -1, @FTable[0]);
  for LIndex := 0 to 255 do
    Assert.AreEqual<Byte>(255, FTable[LIndex * 4 + 3]);
end;

procedure TTestOpenGlSharedPalette.DovrebbeScegliereIlColoreConLaColormap;
begin
  FColormap[5] := 9;
  TGlSceneSharedPalette.Build(@FColors[0], @FColormap[0], 0, @FTable[0]);
  Assert.AreEqual<Byte>(FColors[27], FTable[5 * 4]);
  Assert.AreEqual<Byte>(FColors[28], FTable[5 * 4 + 1]);
  Assert.AreEqual<Byte>(FColors[29], FTable[5 * 4 + 2]);
end;

end.
