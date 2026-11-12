{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the xcom geoscape library - the ruleset and the surface }
{  sets of the game (real data of TFTD)                                         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (the library itself is derived from OpenXcom, GPL v3 or later)               }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomGeoscape.GameRules;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Tests.Shared.Skip, DelphiDoom.Tests.XcomGeoscape.World;

type
  [TestFixture]
  [Category('XcomGeoscape')]
  TTestXcomGameRules = class
  strict private
    FWorld: TXcomGeoWorld;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeLeggereIlRegolamentoDelModPrincipale;
    [Test]
    procedure DovrebbeDareIlGloboDiTftd;
    [Test]
    procedure DovrebbeCostruireILeTexturesDelGlobo;
    [Test]
    procedure DovrebbeCostruireIMarcatoriDalleExtraSprites;
    [Test]
    procedure DovrebbeDareNilPerUnInsiemeSconosciuto;
  end;

implementation

uses
  DelphiDoom.XcomSurface.SurfaceSet;

procedure TTestXcomGameRules.Setup;
begin
  FWorld := TXcomGeoWorld.Create;
end;

procedure TTestXcomGameRules.TearDown;
begin
  FWorld.Free;
end;

procedure TTestXcomGameRules.DovrebbeLeggereIlRegolamentoDelModPrincipale;
begin
  if not FWorld.HasData then
    TTestSkip.Ignore('the data of the game is not on this machine');
  Assert.IsTrue(FWorld.Rules.Ruleset.Facilities.Count > 0);
  Assert.IsTrue(FWorld.Rules.Ruleset.Regions.Count > 0);
end;

procedure TTestXcomGameRules.DovrebbeDareIlGloboDiTftd;
begin
  if not FWorld.HasData then
    TTestSkip.Ignore('the data of the game is not on this machine');
  Assert.AreEqual(733, FWorld.Rules.Ruleset.Globe.Polygons.Count);
  Assert.AreEqual(19, FWorld.Rules.Ruleset.Globe.Polylines.Count);
end;

procedure TTestXcomGameRules.DovrebbeCostruireILeTexturesDelGlobo;
var
  LSet: TXcomSurfaceSet;
begin
  if not FWorld.HasData then
    TTestSkip.Ignore('the data of the game is not on this machine');
  LSet := FWorld.Rules.GetSurfaceSet('TEXTURE.DAT');
  Assert.IsNotNull(LSet);
  Assert.AreEqual(32, LSet.Width);
  Assert.IsTrue(LSet.TotalFrames mod 3 = 0);
end;

procedure TTestXcomGameRules.DovrebbeCostruireIMarcatoriDalleExtraSprites;
var
  LSet: TXcomSurfaceSet;
begin
  if not FWorld.HasData then
    TTestSkip.Ignore('the data of the game is not on this machine');
  LSet := FWorld.Rules.GetSurfaceSet('GlobeMarkers');
  Assert.IsNotNull(LSet);
  // globe_tftd.png is 27 x 3 pixels cut in squares of 3: nine markers
  Assert.AreEqual(9, LSet.TotalFrames);
  Assert.AreEqual(3, LSet.Width);
end;

procedure TTestXcomGameRules.DovrebbeDareNilPerUnInsiemeSconosciuto;
begin
  if not FWorld.HasData then
    TTestSkip.Ignore('the data of the game is not on this machine');
  Assert.IsNull(FWorld.Rules.GetSurfaceSet('NON_ESISTE.PCK'));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXcomGameRules);

end.
