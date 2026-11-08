{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the phased light                                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Thinkers.LightPhase;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Tests.Thinkers.Fakes;

type
  [TestFixture]
  [Category('thinkers')]
  TTestThinkersLightPhase = class(TObject)
  private
    FWorld: TFakeLightWorld;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeLeggereLaTabellaConIlGiroDeiSessantaquattro;
    [Test]
    procedure DovrebbePrendereLIndiceDalLivelloDelSettoreConMenoUno;
    [Test]
    procedure DovrebbePrendereLIndiceDato;
    [Test]
    procedure DovrebbeLimitareLaBaseA255;
    [Test]
    procedure DovrebbePortareIlSettoreAlPrimoLivello;
    [Test]
    procedure DovrebbeTogliereDalloSpecialSoloIBitDellaFase;
    [Test]
    procedure DovrebbeTornareAZeroDopoIlSessantatreesimoPasso;
    [Test]
    procedure DovrebbeDareGliStessiLivelliDelVecchioCodice;
  end;

implementation

uses
  DelphiDoom.Thinkers.Light.Types, DelphiDoom.Thinkers.Light.Games, DelphiDoom.Thinkers.Light.Phase,
  DelphiDoom.Tests.Thinkers.OldLights;

{ TTestThinkersLightPhase }

procedure TTestThinkersLightPhase.Setup;
begin
  FWorld := TFakeLightWorld.Create;
end;

procedure TTestThinkersLightPhase.TearDown;
begin
  FreeAndNil(FWorld);
end;

procedure TTestThinkersLightPhase.DovrebbeLeggereLaTabellaConIlGiroDeiSessantaquattro;
begin
  Assert.AreEqual(128, TLightPhase.TableValue(0));
  Assert.AreEqual(0, TLightPhase.TableValue(11));
  Assert.AreEqual(128, TLightPhase.TableValue(63));
  Assert.AreEqual(128, TLightPhase.TableValue(64));
end;

procedure TTestThinkersLightPhase.DovrebbePrendereLIndiceDalLivelloDelSettoreConMenoUno;
var
  LSector: TFakeLightSector;
  LIndex, LBase: Integer;
begin
  LSector := FWorld.Add(70);
  TLightPhase.Initialize(LSector, 100, -1, TLightGames.SequenceProfile(TLightGame.Doom), LIndex, LBase);
  Assert.AreEqual(70 and 63, LIndex);
end;

procedure TTestThinkersLightPhase.DovrebbePrendereLIndiceDato;
var
  LSector: TFakeLightSector;
  LIndex, LBase: Integer;
begin
  LSector := FWorld.Add(70);
  TLightPhase.Initialize(LSector, 100, 66, TLightGames.SequenceProfile(TLightGame.Doom), LIndex, LBase);
  Assert.AreEqual(2, LIndex);
end;

procedure TTestThinkersLightPhase.DovrebbeLimitareLaBaseA255;
var
  LSector: TFakeLightSector;
  LIndex, LBase: Integer;
begin
  LSector := FWorld.Add(70);
  TLightPhase.Initialize(LSector, 300, 0, TLightGames.SequenceProfile(TLightGame.Doom), LIndex, LBase);
  Assert.AreEqual(300 and 255, LBase);
end;

procedure TTestThinkersLightPhase.DovrebbePortareIlSettoreAlPrimoLivello;
var
  LSector: TFakeLightSector;
  LIndex, LBase: Integer;
begin
  LSector := FWorld.Add(70);
  TLightPhase.Initialize(LSector, 100, 8, TLightGames.SequenceProfile(TLightGame.Doom), LIndex, LBase);
  Assert.AreEqual(100 + 16, Integer(LSector.Level));
end;

procedure TTestThinkersLightPhase.DovrebbeTogliereDalloSpecialSoloIBitDellaFase;
var
  LDoom, LHeretic: TFakeLightSector;
  LIndex, LBase: Integer;
begin
  LDoom := FWorld.Add(70, $1E7);
  TLightPhase.Initialize(LDoom, 100, 0, TLightGames.SequenceProfile(TLightGame.Doom), LIndex, LBase);
  Assert.AreEqual($1E0, LDoom.GetSpecial, 'Doom clears the low 5 bits');
  LHeretic := FWorld.Add(70, $1E7);
  TLightPhase.Initialize(LHeretic, 100, 0, TLightGames.SequenceProfile(TLightGame.Heretic), LIndex, LBase);
  Assert.AreEqual(0, LHeretic.GetSpecial, 'Heretic clears all');
end;

procedure TTestThinkersLightPhase.DovrebbeTornareAZeroDopoIlSessantatreesimoPasso;
var
  LLevel: SmallInt;
  LIndex: Integer;
begin
  LLevel := 0;
  LIndex := 63;
  TLightPhase.Tick(LIndex, 100, LLevel);
  Assert.AreEqual(0, LIndex);
  Assert.AreEqual(228, Integer(LLevel));
end;

procedure TTestThinkersLightPhase.DovrebbeDareGliStessiLivelliDelVecchioCodice;
var
  LStart, LTic, LNewIndex, LNewBase, LGiven: Integer;
  LOldSector, LNewSector: TFakeLightSector;
  LOld: TOldPhase;
begin
  for LStart := -1 to 20 do
  begin
    LOldSector := FWorld.Add(90 + LStart, 5 + 32);
    LNewSector := FWorld.Add(90 + LStart, 5 + 32);
    if LStart = -1 then
      LGiven := -1
    else
      LGiven := LStart * 3;
    OldSpawnPhase(LOld, LOldSector, 80 + LStart, LGiven, 31);
    TLightPhase.Initialize(LNewSector, 80 + LStart, LGiven, TLightGames.SequenceProfile(TLightGame.Doom),
      LNewIndex, LNewBase);
    Assert.AreEqual(Integer(LOldSector.Level), Integer(LNewSector.Level), 'first level');
    Assert.AreEqual(LOldSector.GetSpecial, LNewSector.GetSpecial, 'special');
    for LTic := 1 to 300 do
    begin
      OldTickPhase(LOld);
      TLightPhase.Tick(LNewIndex, LNewBase, LNewSector.Level);
      Assert.AreEqual(Integer(LOldSector.Level), Integer(LNewSector.Level), Format('level at tic %d', [LTic]));
    end;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestThinkersLightPhase);

end.
