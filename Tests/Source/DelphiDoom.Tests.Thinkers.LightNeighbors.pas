{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the light of the sectors around a sector               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Thinkers.LightNeighbors;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Tests.Thinkers.Fakes;

type
  [TestFixture]
  [Category('thinkers')]
  TTestThinkersLightNeighbors = class(TObject)
  private
    FWorld: TFakeLightWorld;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeDareIlLivelloPiuBassoDeiVicini;
    [Test]
    procedure DovrebbeDareIlMassimoSeNessunVicinoEPiuBasso;
    [Test]
    procedure DovrebbeIgnorareLeLineeSenzaSettoreDallAltraParte;
    [Test]
    procedure DovrebbeDareIlMassimoSenzaVicini;
    [Test]
    procedure DovrebbeDareIlLivelloDelSettoreSeNonHaVicini;
    [Test]
    procedure DovrebbeDareIlPiuBassoDeiViciniAncheSeIlSettoreEPiuAlto;
    [Test]
    procedure DovrebbeDareIlLivelloDelSettoreSeHaSoloLineeLibere;
    [Test]
    procedure DovrebbeConservareIlDifettoDelPiuAltoCheNonTrovaMaiUnLivelloPiuAlto;
    [Test]
    procedure DovrebbeDareUnLivelloNegativoDelVicinoNelPiuAlto;
    [Test]
    procedure DovrebbeDareIlLivelloDelSettoreNelPiuAltoSenzaVicini;
    [Test]
    procedure DovrebbeDareIlPiuAltoDeiVicini;
    [Test]
    procedure DovrebbeDareIlLivelloGivenSeNessunVicinoELPiuAlto;
    [Test]
    procedure DovrebbeIgnorareLeLineeSenzaSettoreNelPiuAlto;
  end;

implementation

uses
  DelphiDoom.Thinkers.Light.Neighbors;

{ TTestThinkersLightNeighbors }

procedure TTestThinkersLightNeighbors.Setup;
begin
  FWorld := TFakeLightWorld.Create;
end;

procedure TTestThinkersLightNeighbors.TearDown;
begin
  FreeAndNil(FWorld);
end;

procedure TTestThinkersLightNeighbors.DovrebbeDareIlLivelloPiuBassoDeiVicini;
var
  LSector: TFakeLightSector;
begin
  LSector := FWorld.AddWithNeighbors(160, [96, 64, 120]);
  Assert.AreEqual(64, TLightNeighbors.Lowest(LSector, 200));
end;

procedure TTestThinkersLightNeighbors.DovrebbeDareIlMassimoSeNessunVicinoEPiuBasso;
var
  LSector: TFakeLightSector;
begin
  LSector := FWorld.AddWithNeighbors(160, [96, 64, 120]);
  Assert.AreEqual(50, TLightNeighbors.Lowest(LSector, 50));
end;

procedure TTestThinkersLightNeighbors.DovrebbeIgnorareLeLineeSenzaSettoreDallAltraParte;
var
  LSector: TFakeLightSector;
begin
  LSector := FWorld.AddWithNeighbors(160, [NO_NEIGHBOR, 96, NO_NEIGHBOR]);
  Assert.AreEqual(96, TLightNeighbors.Lowest(LSector, 200));
end;

procedure TTestThinkersLightNeighbors.DovrebbeDareIlMassimoSenzaVicini;
var
  LSector: TFakeLightSector;
begin
  LSector := FWorld.AddWithNeighbors(160, []);
  Assert.AreEqual(77, TLightNeighbors.Lowest(LSector, 77));
end;

procedure TTestThinkersLightNeighbors.DovrebbeDareIlLivelloDelSettoreSeNonHaVicini;
var
  LSector: TFakeLightSector;
begin
  LSector := FWorld.AddWithNeighbors(160, []);
  Assert.AreEqual(160, TLightNeighbors.LowestOrOwn(LSector));
end;

procedure TTestThinkersLightNeighbors.DovrebbeDareIlPiuBassoDeiViciniAncheSeIlSettoreEPiuAlto;
var
  LSector: TFakeLightSector;
begin
  LSector := FWorld.AddWithNeighbors(40, [96, 200]);
  Assert.AreEqual(96, TLightNeighbors.LowestOrOwn(LSector));
end;

procedure TTestThinkersLightNeighbors.DovrebbeDareIlLivelloDelSettoreSeHaSoloLineeLibere;
var
  LSector: TFakeLightSector;
begin
  LSector := FWorld.AddWithNeighbors(144, [NO_NEIGHBOR, NO_NEIGHBOR]);
  Assert.AreEqual(144, TLightNeighbors.LowestOrOwn(LSector));
end;

procedure TTestThinkersLightNeighbors.DovrebbeConservareIlDifettoDelPiuAltoCheNonTrovaMaiUnLivelloPiuAlto;
var
  LSector: TFakeLightSector;
begin
  // the old function compared with "less than": the highest neighbor is never found
  LSector := FWorld.AddWithNeighbors(100, [250, 255, 90]);
  Assert.AreEqual(100, TLightNeighbors.HighestOrOwn(LSector));
end;

procedure TTestThinkersLightNeighbors.DovrebbeDareUnLivelloNegativoDelVicinoNelPiuAlto;
var
  LSector: TFakeLightSector;
begin
  // a level below -1 is "less than" the start value of the old search
  LSector := FWorld.AddWithNeighbors(100, [-5, 30]);
  Assert.AreEqual(-5, TLightNeighbors.HighestOrOwn(LSector));
end;

procedure TTestThinkersLightNeighbors.DovrebbeDareIlLivelloDelSettoreNelPiuAltoSenzaVicini;
var
  LSector: TFakeLightSector;
begin
  LSector := FWorld.AddWithNeighbors(123, [NO_NEIGHBOR]);
  Assert.AreEqual(123, TLightNeighbors.HighestOrOwn(LSector));
end;

procedure TTestThinkersLightNeighbors.DovrebbeDareIlPiuAltoDeiVicini;
var
  LSector: TFakeLightSector;
begin
  LSector := FWorld.AddWithNeighbors(100, [64, 200, 150]);
  Assert.AreEqual(200, TLightNeighbors.HighestAbove(LSector, 0));
end;

procedure TTestThinkersLightNeighbors.DovrebbeDareIlLivelloGivenSeNessunVicinoELPiuAlto;
var
  LSector: TFakeLightSector;
begin
  LSector := FWorld.AddWithNeighbors(100, [64, 20]);
  Assert.AreEqual(90, TLightNeighbors.HighestAbove(LSector, 90));
end;

procedure TTestThinkersLightNeighbors.DovrebbeIgnorareLeLineeSenzaSettoreNelPiuAlto;
var
  LSector: TFakeLightSector;
begin
  LSector := FWorld.AddWithNeighbors(100, [NO_NEIGHBOR, 33, NO_NEIGHBOR]);
  Assert.AreEqual(33, TLightNeighbors.HighestAbove(LSector, 0));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestThinkersLightNeighbors);

end.
