{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the scenery and the particles of Speed Haste           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Speed.WorldActors;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.GameData.Intf, DelphiDoom.Speed.WorldActors;

type
  [TestFixture]
  [Category('speed')]
  TTestSpeedWorldActors = class(TObject)
  strict private
    FWad: IGameWadComposer;
    procedure AddPicture(const AName: string);
    function Count(const AText, ASub: string): Integer;
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure NonDovrebbeDescrivereNullaSenzaImmagini;
    [Test]
    procedure DovrebbeDescrivereSoloLeDecorazioniCheHannoUnaImmagine;
    [Test]
    procedure DovrebbeRendereSolideGliAlberiENonLeLuci;
    [Test]
    procedure DovrebbeUsareLaImmagineDelTipoTrentaquattroPerIlTipo2160;
    [Test]
    procedure DovrebbeDescrivereLeParticelleCheHannoUnaImmagine;
    [Test]
    procedure DovrebbeDareIlNomeDellAttoreDiOgniParticella;
    [Test]
    procedure DovrebbeRifiutareUnComponitoreNil;
  end;

implementation

uses
  DelphiDoom.GameData.Factory, DelphiDoom.Racing.Types;

{ TTestSpeedWorldActors }

procedure TTestSpeedWorldActors.Setup;
begin
  FWad := TGameDataFactory.CreateWadComposer;
end;

procedure TTestSpeedWorldActors.AddPicture(const AName: string);
begin
  FWad.AddLump(AName, TBytes.Create(1, 2, 3, 4));
end;

function TTestSpeedWorldActors.Count(const AText, ASub: string): Integer;
var
  LPosition: Integer;
begin
  Result := 0;
  LPosition := Pos(ASub, AText);
  while LPosition > 0 do
  begin
    Inc(Result);
    LPosition := Pos(ASub, AText, LPosition + Length(ASub));
  end;
end;

procedure TTestSpeedWorldActors.NonDovrebbeDescrivereNullaSenzaImmagini;
begin
  Assert.AreEqual('', TSpeedWorldActors.Scenery(FWad));
  Assert.AreEqual('', TSpeedWorldActors.Particles(FWad));
end;

procedure TTestSpeedWorldActors.DovrebbeDescrivereSoloLeDecorazioniCheHannoUnaImmagine;
var
  LText: string;
begin
  AddPicture('S020A0');
  AddPicture('S02DA0');
  LText := TSpeedWorldActors.Scenery(FWad);
  Assert.AreEqual(2, Count(LText, 'ACTOR SpeedScenery'));
  Assert.IsTrue(Pos('ACTOR SpeedScenery32 32', LText) > 0);
  Assert.IsTrue(Pos('ACTOR SpeedScenery45 45', LText) > 0);
  Assert.AreEqual(0, Pos('SpeedScenery33', LText));
end;

procedure TTestSpeedWorldActors.DovrebbeRendereSolideGliAlberiENonLeLuci;
var
  LText: string;
begin
  AddPicture('S020A0');
  AddPicture('S02DA0');
  LText := TSpeedWorldActors.Scenery(FWad);
  Assert.AreEqual(1, Count(LText, '+SOLID'));
  Assert.IsTrue(Pos('+SOLID', LText) < Pos('SpeedScenery45', LText));
end;

procedure TTestSpeedWorldActors.DovrebbeUsareLaImmagineDelTipoTrentaquattroPerIlTipo2160;
var
  LText: string;
begin
  AddPicture('S022A0');
  LText := TSpeedWorldActors.Scenery(FWad);
  Assert.AreEqual(2, Count(LText, 'S022 A -1'));
  Assert.IsTrue(Pos('SpeedScenery2160 2160', LText) > 0);
  Assert.IsTrue(Pos('Scale 1.5', LText) > 0);
end;

procedure TTestSpeedWorldActors.DovrebbeDescrivereLeParticelleCheHannoUnaImmagine;
var
  LText: string;
begin
  AddPicture('SPRKA0');
  AddPicture('GND1A0');
  LText := TSpeedWorldActors.Particles(FWad);
  Assert.AreEqual(2, Count(LText, 'ACTOR SpeedParticle'));
  Assert.IsTrue(Pos('ACTOR SpeedParticleSpark', LText) > 0);
  Assert.IsTrue(Pos('ACTOR SpeedParticleDirt', LText) > 0);
  Assert.AreEqual(0, Pos('SpeedParticleSmoke', LText));
  Assert.AreEqual(6, Count(LText, 'SPRK '));
end;

procedure TTestSpeedWorldActors.DovrebbeDareIlNomeDellAttoreDiOgniParticella;
var
  LKind: TRacingParticleKind;
  LNames: TArray<string>;
begin
  LNames := nil;
  for LKind := Low(TRacingParticleKind) to High(TRacingParticleKind) do
  begin
    SetLength(LNames, Length(LNames) + 1);
    LNames[High(LNames)] := TSpeedWorldActors.ParticleActorName(LKind);
    Assert.IsTrue(Pos(SPEED_PARTICLE_ACTOR_PREFIX, LNames[High(LNames)]) = 1);
  end;
  Assert.AreEqual('SpeedParticleSpark', LNames[0]);
  Assert.AreEqual('SpeedParticleSand', LNames[High(LNames)]);
end;

procedure TTestSpeedWorldActors.DovrebbeRifiutareUnComponitoreNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TSpeedWorldActors.Scenery(nil);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TSpeedWorldActors.Particles(nil);
    end, EArgumentNilException);
end;

end.
