{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the OpenGL scene - the light of a sector               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.OpenGl.SceneLight;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.GlScene.Types,
  DelphiDoom.GlScene.Light;

type
  [TestFixture]
  [Category('opengl')]
  TTestOpenGlSceneLight = class(TObject)
  strict private
    FTable: TGlSceneLightTable;
    // the text of gld_CalcLightLevel of gl_render.pas before Libs\GlScene
    function OldCalcLightLevel(const AGamma: Byte; lightlevel: Integer): Single;
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure DovrebbeDareIlValoreDelVecchioPerOgniGammaELivello;
    [Test]
    [TestCase('sotto zero', '-1,0')]
    [TestCase('molto sotto zero', '-100000,0')]
    [TestCase('zero', '0,0')]
    [TestCase('in mezzo', '128,128')]
    [TestCase('ultimo', '255,255')]
    [TestCase('oltre', '256,255')]
    [TestCase('con la luce in piu', '1183,255')]
    procedure DovrebbePortareIlLivelloTraZeroE255(const ALight, AExpectedColumn: Integer);
    [Test]
    procedure DovrebbeUsareLaRigaDellaGamma;
  end;

implementation

{ TTestOpenGlSceneLight }

function gl_i_min(const a, b: Integer): Integer;
begin
  if a > b then
    Result := b
  else
    Result := a;
end;

function gl_i_max(const a, b: Integer): Integer;
begin
  if a > b then
    Result := a
  else
    Result := b;
end;

function TTestOpenGlSceneLight.OldCalcLightLevel(const AGamma: Byte; lightlevel: Integer): Single;
begin
  Result := FTable[AGamma][gl_i_max(gl_i_min((lightlevel), 255), 0)];
end;

procedure TTestOpenGlSceneLight.Setup;
var
  LGamma: Integer;
  LLight: Integer;
begin
  // every entry is different from the others
  for LGamma := 0 to GLSCENE_GAMMA_COUNT - 1 do
    for LLight := 0 to 255 do
      FTable[LGamma][LLight] := (LGamma * 256 + LLight) / 1280;
end;

procedure TTestOpenGlSceneLight.DovrebbeDareIlValoreDelVecchioPerOgniGammaELivello;
var
  LGamma: Integer;
  LLight: Integer;
  LOld: Single;
  LNew: Single;
begin
  for LGamma := 0 to GLSCENE_GAMMA_COUNT - 1 do
    for LLight := -600 to 900 do
    begin
      LOld := OldCalcLightLevel(LGamma, LLight);
      LNew := TGlSceneLight.Level(@FTable, LGamma, LLight);
      if PCardinal(@LOld)^ <> PCardinal(@LNew)^ then
        Assert.Fail(Format('gamma %d light %d: %g, old %g', [LGamma, LLight, LNew, LOld]));
    end;
  Assert.Pass;
end;

procedure TTestOpenGlSceneLight.DovrebbePortareIlLivelloTraZeroE255(const ALight, AExpectedColumn: Integer);
begin
  Assert.AreEqual(FTable[2][AExpectedColumn], TGlSceneLight.Level(@FTable, 2, ALight));
end;

procedure TTestOpenGlSceneLight.DovrebbeUsareLaRigaDellaGamma;
begin
  Assert.AreEqual(FTable[0][10], TGlSceneLight.Level(@FTable, 0, 10));
  Assert.AreEqual(FTable[4][10], TGlSceneLight.Level(@FTable, 4, 10));
  Assert.AreNotEqual(TGlSceneLight.Level(@FTable, 0, 10), TGlSceneLight.Level(@FTable, 4, 10));
end;

end.
