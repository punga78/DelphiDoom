{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the sequence of phased lights                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Thinkers.LightSequence;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Tests.Thinkers.Fakes;

type
  [TestFixture]
  [Category('thinkers')]
  TTestThinkersLightSequence = class(TObject)
  private
    FWorld: TFakeLightWorld;
    FSpawner: TFakePhaseSpawner;
    FSpawnerRef: IInterface;
    FA, FB, FC: TFakeLightSector;
    procedure BuildRow(AMiddleLevel: Integer);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeFareUnaFaseperOgniSettoreDellaFilaNellOrdine;
    [Test]
    procedure DovrebbeDistribuireGliIndiciSuSessantaquattroPassi;
    [Test]
    procedure DovrebbeUsareIlLivelloDelPrecedenteSeIlSettoreEAZero;
    [Test]
    procedure DovrebbeMoltiplicareIPassiPerIlFattore;
    [Test]
    procedure DovrebbeFareUnaFaseSolaPerUnSettoreIsolato;
    [Test]
    procedure DovrebbeUsareISpecialDelGioco;
  end;

implementation

uses
  DelphiDoom.Thinkers.Light.Types, DelphiDoom.Thinkers.Light.Games, DelphiDoom.Thinkers.Light.Sequence;

const
  DOOM_MASK = 31;

{ TTestThinkersLightSequence }

procedure TTestThinkersLightSequence.Setup;
begin
  FWorld := TFakeLightWorld.Create;
  FSpawner := TFakePhaseSpawner.Create(DOOM_MASK);
  FSpawnerRef := FSpawner;
end;

procedure TTestThinkersLightSequence.TearDown;
begin
  FSpawner := nil;
  FSpawnerRef := nil;
  FreeAndNil(FWorld);
end;

// A - B - C in a row: the specials of Doom are 22 (start), 23 and 24
procedure TTestThinkersLightSequence.BuildRow(AMiddleLevel: Integer);
begin
  FA := FWorld.Add(160, 22);
  FB := FWorld.Add(AMiddleLevel, 23);
  FC := FWorld.Add(96, 24);
  FA.SetNeighbors([FB]);
  FB.SetNeighbors([FA, FC]);
  FC.SetNeighbors([FB]);
end;

procedure TTestThinkersLightSequence.DovrebbeFareUnaFaseperOgniSettoreDellaFilaNellOrdine;
begin
  BuildRow(128);
  TLightSequence.Spawn(FA, 1, TLightGames.SequenceProfile(TLightGame.Doom), FSpawner);
  Assert.AreEqual(3, FSpawner.Calls.Count);
  Assert.IsTrue(FSpawner.Calls[0].Sector = FA, 'first');
  Assert.IsTrue(FSpawner.Calls[1].Sector = FB, 'second');
  Assert.IsTrue(FSpawner.Calls[2].Sector = FC, 'third');
end;

procedure TTestThinkersLightSequence.DovrebbeDistribuireGliIndiciSuSessantaquattroPassi;
begin
  BuildRow(128);
  TLightSequence.Spawn(FA, 1, TLightGames.SequenceProfile(TLightGame.Doom), FSpawner);
  // 64 / 3 in fixed point, taken as an integer: 0, 21, 42
  Assert.AreEqual(0, FSpawner.Calls[0].Index);
  Assert.AreEqual(21, FSpawner.Calls[1].Index);
  Assert.AreEqual(42, FSpawner.Calls[2].Index);
end;

procedure TTestThinkersLightSequence.DovrebbeUsareIlLivelloDelPrecedenteSeIlSettoreEAZero;
begin
  BuildRow(0);
  TLightSequence.Spawn(FA, 1, TLightGames.SequenceProfile(TLightGame.Doom), FSpawner);
  Assert.AreEqual(160, FSpawner.Calls[0].Base);
  Assert.AreEqual(160, FSpawner.Calls[1].Base, 'the sector with 0 takes the base of the one before');
  Assert.AreEqual(96, FSpawner.Calls[2].Base);
end;

procedure TTestThinkersLightSequence.DovrebbeMoltiplicareIPassiPerIlFattore;
begin
  BuildRow(128);
  TLightSequence.Spawn(FA, 2, TLightGames.SequenceProfile(TLightGame.Doom), FSpawner);
  // 64 / 6 = 10.66 per sector
  Assert.AreEqual(0, FSpawner.Calls[0].Index);
  Assert.AreEqual(10, FSpawner.Calls[1].Index);
  Assert.AreEqual(21, FSpawner.Calls[2].Index);
end;

procedure TTestThinkersLightSequence.DovrebbeFareUnaFaseSolaPerUnSettoreIsolato;
var
  LAlone: TFakeLightSector;
begin
  LAlone := FWorld.Add(100, 22);
  LAlone.SetNeighbors([]);
  TLightSequence.Spawn(LAlone, 1, TLightGames.SequenceProfile(TLightGame.Doom), FSpawner);
  Assert.AreEqual(1, FSpawner.Calls.Count);
  Assert.AreEqual(0, FSpawner.Calls[0].Index);
  Assert.AreEqual(100, FSpawner.Calls[0].Base);
end;

procedure TTestThinkersLightSequence.DovrebbeUsareISpecialDelGioco;
var
  LSpawner: TFakePhaseSpawner;
  LHolder: IInterface;
  LA, LB: TFakeLightSector;
begin
  // Heretic: 52 starts, 53 and 54 follow; the whole special is the mask
  LSpawner := TFakePhaseSpawner.Create($FFFF);
  LHolder := LSpawner;
  LA := FWorld.Add(160, 52);
  LB := FWorld.Add(120, 53);
  LA.SetNeighbors([LB]);
  LB.SetNeighbors([LA]);
  TLightSequence.Spawn(LA, 1, TLightGames.SequenceProfile(TLightGame.Heretic), LSpawner);
  Assert.AreEqual(2, LSpawner.Calls.Count);
  Assert.IsTrue(LSpawner.Calls[1].Sector = LB);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestThinkersLightSequence);

end.
