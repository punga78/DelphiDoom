{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TGreedSpriteLogic, TGreedSpriteMovement,                }
{  TGreedSpriteScan and TGreedTargetAngles                                      }
{                                                                              }
{  The oracle of the parity is sprites.pas of xGreed, not modified, compiled    }
{  by the harness Tools\Verifica\175-sprites: its hashes, tic by tic, are in    }
{  Tests\Data\Greed\sprites.golden.txt                                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Greed.SpriteLogic;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, DUnitX.TestFramework, DelphiDoom.Greed.Types,
  DelphiDoom.Greed.Actor.Types, DelphiDoom.Greed.World.Intf, DelphiDoom.Tests.Greed.SpriteScenarios,
  DelphiDoom.Tests.Greed.SpriteRunner;

type
  [TestFixture]
  [Category('greed')]
  TTestGreedSpriteLogic = class(TObject)
  private
    FRunner: TLibrarySpriteRunner;
    function Center(ATile: Integer): Integer;
    function Spot(ATileX, ATileY: Integer): Integer;
    function NewSprite(AKind, AIntelligence, ATileX, ATileY: Integer): TGreedSprite;
    function NewMonster(AKind, ATileX, ATileY: Integer; AActive: Boolean): TGreedSprite;
    function NewBullet(AKind, ATileX, ATileY, AAngle: Integer): TGreedSprite;
    function Sprite(AIndex: Integer): PGreedSprite;
    function CountKind(AKind: Integer): Integer;
    function AddDoor(ATileX, ATileY: Integer; AOrientation: TGreedDoorOrientation): Integer;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeSollevareSeUnaDipendenzaManca;
    [Test]
    procedure DovrebbeSvegliareIlMostroCheVedeIlGiocatore;
    [Test]
    procedure DovrebbeLasciareDormireIlMostroLontano;
    [Test]
    procedure DovrebbeDareLaVoceDelMostroCheSiSveglia;
    [Test]
    procedure DovrebbeFermareIlProiettileControIlMuro;
    [Test]
    procedure DovrebbeFerireIlGiocatoreColpito;
    [Test]
    procedure DovrebbeUccidereIlMostroSenzaPiuPuntiVita;
    [Test]
    procedure DovrebbeSvegliareIlCloneColpitoMentreDorme;
    [Test]
    procedure DovrebbeFarEsplodereLaMinaATempo;
    [Test]
    procedure DovrebbeFarEsplodereLaMinaVicinaAlGiocatore;
    [Test]
    procedure DovrebbeTogliereIlMuroIstantaneo;
    [Test]
    procedure DovrebbeFarSparareIlMostroCheVedeIlGiocatore;
    [Test]
    procedure DovrebbeNonVedereAttraversoUnMuro;
    [Test]
    procedure DovrebbeAprireLaPortaCheIlMostroUrta;
    [Test]
    procedure DovrebbeLasciarePassareLaSondaDalleParte;
    [Test]
    procedure DovrebbeScrivereLeCaselleDeiMostriVivi;
    [Test]
    procedure DovrebbeTogliereLuceAlleCaselleDegliSpriteCaldi;
    [Test]
    procedure DovrebbeMirareInAltoEInBasso;
    [Test]
    procedure DovrebbeEsplodereAncheSeNonNasceNessunoSprite;
    [Test]
    procedure DovrebbeFermareLaScansioneAllaFineDellaMappa;
    [Test]
    procedure DovrebbeFarCadereCioCheStaPerAria;
    [Test]
    procedure DovrebbeDareLaTabellaDegliAngoliDelCodiceOriginale;
    [Test]
    procedure DovrebbeDareLeStesseImpronteDelCodiceOriginale;
  end;

implementation

uses
  DelphiDoom.Greed.LinkedPool, DelphiDoom.Greed.Random, DelphiDoom.Greed.Game.Intf, DelphiDoom.Greed.Game.State,
  DelphiDoom.Greed.Game.Constants, DelphiDoom.Greed.SpriteLogic.Intf, DelphiDoom.Greed.SpriteLogic,
  DelphiDoom.Greed.SpriteMovement, DelphiDoom.Greed.SpriteScan, DelphiDoom.Greed.TargetAngles,
  DelphiDoom.Greed.World, DelphiDoom.Tests.Greed.RealData;

const
  FRACUNIT = GREED_FRACUNIT;
  TILE = GREED_FRACTILEUNIT;

{ TTestGreedSpriteLogic }

procedure TTestGreedSpriteLogic.Setup;
begin
  FRunner := TLibrarySpriteRunner.Create;
  FRunner.LoadEmpty;
end;

procedure TTestGreedSpriteLogic.TearDown;
begin
  FRunner.Free;
end;

function TTestGreedSpriteLogic.Center(ATile: Integer): Integer;
begin
  Result := ATile * TILE + 32 * FRACUNIT;
end;

function TTestGreedSpriteLogic.Spot(ATileX, ATileY: Integer): Integer;
begin
  Result := ATileY * GREED_MAP_SIZE + ATileX;
end;

function TTestGreedSpriteLogic.NewSprite(AKind, AIntelligence, ATileX, ATileY: Integer): TGreedSprite;
begin
  Result := Default(TGreedSprite);
  Result.Kind := AKind;
  Result.Intelligence := AIntelligence;
  Result.X := Center(ATileX);
  Result.Y := Center(ATileY);
  Result.MoveSpeed := FRACUNIT;
  Result.Active := True;
  Result.StartSpot := -1;
end;

function TTestGreedSpriteLogic.NewMonster(AKind, ATileX, ATileY: Integer; AActive: Boolean): TGreedSprite;
begin
  Result := NewSprite(AKind, 10, ATileX, ATileY);
  Result.Active := AActive;
  Result.HitPoints := 100;
  Result.Height := 60 * FRACUNIT;
  Result.MoveSize := 20 * FRACUNIT;
  Result.Bullet := GREED_S_MONSTERBULLET1;
  Result.StartPic := 200;
  Result.BasePic := 200;
  // nothing to do for a long time: each test sets the clock of what it wants to see
  Result.MoveTime := 1000;
  Result.ModeTime := 1000;
  Result.ActionTime := 1000;
  Result.ScanTime := 1000;
  Result.FireTime := 1000;
end;

function TTestGreedSpriteLogic.NewBullet(AKind, ATileX, ATileY, AAngle: Integer): TGreedSprite;
begin
  Result := NewSprite(AKind, 0, ATileX, ATileY);
  Result.Angle := AAngle;
  Result.Z := 30 * FRACUNIT;
  Result.MoveSpeed := 300;
  Result.MoveSize := 2 * FRACUNIT;
  Result.Damage := 20;
  Result.SpawnId := 255;
end;

function TTestGreedSpriteLogic.Sprite(AIndex: Integer): PGreedSprite;
begin
  Result := PGreedSprite(FRunner.Sprites.Item(AIndex));
end;

function TTestGreedSpriteLogic.CountKind(AKind: Integer): Integer;
var
  LIndex: Integer;
begin
  Result := 0;
  LIndex := FRunner.Sprites.First;
  while LIndex <> GREED_POOL_NIL do
  begin
    if Sprite(LIndex)^.Kind = AKind then
      Inc(Result);
    LIndex := FRunner.Sprites.Next(LIndex);
  end;
end;

function TTestGreedSpriteLogic.AddDoor(ATileX, ATileY: Integer; AOrientation: TGreedDoorOrientation): Integer;
var
  LDoor: TGreedDoor;
begin
  Result := FRunner.World.AddDoor(ATileX, ATileY);
  LDoor := FRunner.World.GetDoor(Result);
  LDoor.Orientation := AOrientation;
  LDoor.Bumpable := True;
  FRunner.World.SetDoor(Result, LDoor);
end;

procedure TTestGreedSpriteLogic.DovrebbeSollevareSeUnaDipendenzaManca;
var
  LState: TGreedGameState;
  LGame: TFakeSpriteGame;
  LKeep: IInterface;
  LRandom: IGreedRandom;
begin
  LState := FRunner.State;
  LGame := FRunner.Game;
  LKeep := LGame;
  LRandom := FRunner.Random;
  Assert.WillRaise(
    procedure
    begin
      TGreedSpriteLogic.Create(nil, LGame, LRandom, LGame, LGame, LGame, LGame);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TGreedSpriteLogic.Create(LState, nil, LRandom, LGame, LGame, LGame, LGame);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TGreedSpriteLogic.Create(LState, LGame, nil, LGame, LGame, LGame, LGame);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TGreedSpriteLogic.Create(LState, LGame, LRandom, nil, LGame, LGame, LGame);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TGreedSpriteLogic.Create(LState, LGame, LRandom, LGame, nil, LGame, LGame);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TGreedSpriteLogic.Create(LState, LGame, LRandom, LGame, LGame, nil, LGame);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TGreedSpriteLogic.Create(LState, LGame, LRandom, LGame, LGame, LGame, nil);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TGreedSpriteMovement.Create(nil, LGame);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TGreedSpriteMovement.Create(LState, nil);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TGreedSpriteScan.Create(nil, LRandom);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TGreedSpriteScan.Create(LState, nil);
    end, EArgumentNilException);
end;

procedure TTestGreedSpriteLogic.DovrebbeSvegliareIlMostroCheVedeIlGiocatore;
var
  LNear, LChained: Integer;
begin
  // the player is on the tile (10, 10): the first monster is 2 tiles away, the second 6 (too far for the player,
  // close enough to the first)
  LNear := FRunner.Add(NewMonster(GREED_S_MONSTER1, 12, 10, False));
  LChained := FRunner.Add(NewMonster(GREED_S_MONSTER1, 16, 12, False));
  FRunner.Logic.MoveSprites;
  Assert.IsTrue(Sprite(LNear)^.Active, 'the monster near the player');
  Assert.IsTrue(Sprite(LChained)^.Active, 'the monster near the first one');
  Assert.AreEqual(40, Sprite(LChained)^.ActionTime, 'the chained one waits 40 tics');
  // the voice of the chained one, twice as the original
  Assert.AreEqual(2, FRunner.Game.SoundCount);
  Assert.AreEqual(GREED_SN_MON1_WAKE, FRunner.Game.LastSound);
  Assert.AreEqual(1, Integer(FRunner.World.GetValue(gpMapSprites, Spot(12, 10))), 'the tile of a living monster');
  Assert.AreEqual(GREED_POOL_NIL, FRunner.State.MSprite, 'nobody is thinking after the tic');
end;

procedure TTestGreedSpriteLogic.DovrebbeLasciareDormireIlMostroLontano;
var
  LFar, LStill: Integer;
  LSprite: TGreedSprite;
begin
  LFar := FRunner.Add(NewMonster(GREED_S_MONSTER2, 30, 30, False));
  // a sprite that cannot move is not woken, even close to the player
  LSprite := NewMonster(GREED_S_MONSTER2, 11, 10, False);
  LSprite.MoveSpeed := 0;
  LStill := FRunner.Add(LSprite);
  FRunner.Logic.MoveSprites;
  Assert.IsFalse(Sprite(LFar)^.Active);
  Assert.IsFalse(Sprite(LStill)^.Active);
  Assert.AreEqual(0, FRunner.Game.SoundCount);
end;

procedure TTestGreedSpriteLogic.DovrebbeDareLaVoceDelMostroCheSiSveglia;
var
  LMonster, LOther: Integer;
begin
  LMonster := FRunner.Add(NewMonster(GREED_S_MONSTER11, 20, 20, True));
  LOther := FRunner.Add(NewSprite(GREED_S_PROXMINE, 6, 22, 22));
  FRunner.Logic.ActivationSound(LOther);
  Assert.AreEqual(0, FRunner.Game.SoundCount, 'only the monsters have a voice');
  FRunner.Logic.ActivationSound(LMonster);
  Assert.AreEqual(1, FRunner.Game.SoundCount);
  Assert.AreEqual(GREED_SN_MON11_WAKE, FRunner.Game.LastSound);
end;

procedure TTestGreedSpriteLogic.DovrebbeFermareIlProiettileControIlMuro;
var
  LPuff: PGreedSprite;
begin
  FRunner.World.SetValue(gpWestWall, Spot(24, 20), 1);
  FRunner.Add(NewBullet(GREED_S_BULLET1, 22, 20, 0));
  FRunner.Logic.MoveSprites;
  // the bullet is gone and the puff is where it stopped, just before the wall
  Assert.AreEqual(1, FRunner.Sprites.Count);
  LPuff := Sprite(FRunner.Sprites.First);
  Assert.AreEqual(GREED_S_WALLPUFF, LPuff^.Kind);
  Assert.IsTrue((LPuff^.X < 24 * TILE) and (LPuff^.X >= 24 * TILE - 4 * FRACUNIT), 'before the wall');
  Assert.AreEqual(Center(20), LPuff^.Y);
end;

procedure TTestGreedSpriteLogic.DovrebbeFerireIlGiocatoreColpito;
begin
  FRunner.Add(NewBullet(GREED_S_MONSTERBULLET1, 8, 10, 0));
  FRunner.Logic.MoveSprites;
  Assert.AreEqual(20, FRunner.Game.HurtTotal);
  Assert.AreEqual(80, FRunner.State.Player.Angst);
  Assert.IsFalse(FRunner.State.PlayerHit, 'the hit was used');
  Assert.AreEqual(0, CountKind(GREED_S_MONSTERBULLET1), 'the bullet is gone');
end;

procedure TTestGreedSpriteLogic.DovrebbeUccidereIlMostroSenzaPiuPuntiVita;
var
  LMonster, LBullet: TGreedSprite;
begin
  LMonster := NewMonster(GREED_S_MONSTER1, 24, 20, False);
  LMonster.HitPoints := 10;
  LMonster.Score := 500;
  LMonster.MoveSpeed := 0;
  FRunner.Add(LMonster);
  FRunner.World.SetValue(gpMapSprites, Spot(24, 20), 1);
  LBullet := NewBullet(GREED_S_BULLET1, 22, 20, 0);
  LBullet.Damage := 50;
  // a shot of the player
  LBullet.SpawnId := FRunner.State.PlayerNum;
  FRunner.Add(LBullet);
  FRunner.Logic.MoveSprites;
  Assert.AreEqual(1, FRunner.Game.KillCount);
  Assert.AreEqual(1, FRunner.State.Player.BodyCount);
  Assert.AreEqual(0, CountKind(GREED_S_MONSTER1), 'the stand-in of KillSprite removes it');
  Assert.AreEqual(6, CountKind(GREED_S_BLOODSPLAT), 'the blood of a monster of flesh');
  Assert.AreEqual(0, Integer(FRunner.World.GetValue(gpMapSprites, Spot(24, 20))), 'its tile is free');
end;

procedure TTestGreedSpriteLogic.DovrebbeSvegliareIlCloneColpitoMentreDorme;
var
  LClone: TGreedSprite;
  LIndex: Integer;
begin
  LClone := NewSprite(GREED_S_CLONE, 7, 34, 30);
  LClone.Active := False;
  LClone.HitPoints := 100;
  LClone.Height := 60 * FRACUNIT;
  LClone.MoveSize := 16 * FRACUNIT;
  LClone.StartPic := 300;
  LClone.BasePic := 300;
  LIndex := FRunner.Add(LClone);
  FRunner.World.SetValue(gpMapSprites, Spot(34, 30), GREED_SM_CLONE);
  FRunner.Add(NewBullet(GREED_S_BULLET1, 32, 30, 0));
  FRunner.State.TimeCount := 50;
  FRunner.Logic.MoveSprites;
  Assert.IsTrue(Sprite(LIndex)^.Active);
  Assert.AreEqual(80, Sprite(LIndex)^.HitPoints);
  Assert.AreEqual(332, Sprite(LIndex)^.BasePic, 'the picture of pain');
  Assert.AreEqual(58, Sprite(LIndex)^.ModeTime);
  // pushed back by the shot, to the east
  Assert.IsTrue(Sprite(LIndex)^.X > Center(34));
  Assert.AreEqual(0, FRunner.Game.KillCount);
end;

procedure TTestGreedSpriteLogic.DovrebbeFarEsplodereLaMinaATempo;
var
  LMine: TGreedSprite;
begin
  LMine := NewSprite(GREED_S_TIMEMINE, 6, 30, 30);
  LMine.ActionTime := 20;
  FRunner.Add(LMine);
  FRunner.State.TimeCount := 20;
  FRunner.Logic.MoveSprites;
  Assert.AreEqual(1, CountKind(GREED_S_TIMEMINE), 'not yet');
  FRunner.State.TimeCount := 21;
  FRunner.Logic.MoveSprites;
  Assert.AreEqual(0, CountKind(GREED_S_TIMEMINE));
  Assert.AreEqual(21, FRunner.Game.SpawnCount, '20 bullets and the explosion');
  Assert.AreEqual(1, CountKind(GREED_S_EXPLODE));
  Assert.AreEqual(GREED_SN_EXPLODE1, FRunner.Game.LastSound);
end;

procedure TTestGreedSpriteLogic.DovrebbeFarEsplodereLaMinaVicinaAlGiocatore;
var
  LFar: Integer;
begin
  LFar := FRunner.Add(NewSprite(GREED_S_PROXMINE, 6, 40, 40));
  FRunner.Add(NewSprite(GREED_S_PROXMINE, 6, 11, 11));
  FRunner.State.TimeCount := 5;
  FRunner.Logic.MoveSprites;
  Assert.AreEqual(1, CountKind(GREED_S_PROXMINE), 'the one near the player blew up');
  Assert.AreEqual(GREED_S_PROXMINE, Sprite(LFar)^.Kind);
  // the one that waits turns a little at each tic
  Assert.IsTrue((Sprite(LFar)^.Angle = 8) or (Sprite(LFar)^.Angle = 1016));
  Assert.AreEqual(1, CountKind(GREED_S_EXPLODE));
end;

procedure TTestGreedSpriteLogic.DovrebbeTogliereIlMuroIstantaneo;
begin
  FRunner.Add(NewSprite(GREED_S_INSTAWALL, 6, 20, 20));
  FRunner.World.SetValue(gpMapSprites, Spot(20, 20), 64);
  FRunner.State.TimeCount := 1;
  FRunner.Logic.MoveSprites;
  Assert.AreEqual(0, FRunner.Sprites.Count);
  Assert.AreEqual(0, Integer(FRunner.World.GetValue(gpMapSprites, Spot(20, 20))));
end;

procedure TTestGreedSpriteLogic.DovrebbeFarSparareIlMostroCheVedeIlGiocatore;
var
  LMonster: TGreedSprite;
  LIndex: Integer;
begin
  // on the row of the player, 5 tiles to the east
  LMonster := NewMonster(GREED_S_MONSTER1, 15, 10, True);
  LMonster.ScanTime := 0;
  LMonster.FireTime := 0;
  LIndex := FRunner.Add(LMonster);
  FRunner.State.TimeCount := 100;
  FRunner.Logic.MoveSprites;
  Assert.AreEqual(1, FRunner.Game.SpawnCount, 'one bullet');
  Assert.AreEqual(512, Sprite(LIndex)^.Angle, 'it turned to the west');
  Assert.AreEqual(6, Sprite(LIndex)^.MoveMode, 'the frame of the shot');
  Assert.AreEqual(232, Sprite(LIndex)^.BasePic);
  Assert.AreEqual(140, Sprite(LIndex)^.FireTime);
  Assert.AreEqual(130, Sprite(LIndex)^.ScanTime);
  Assert.AreEqual(FRunner.State.Player.X, FRunner.State.TargX);
end;

procedure TTestGreedSpriteLogic.DovrebbeNonVedereAttraversoUnMuro;
var
  LMonster: TGreedSprite;
  LIndex, LTargetX, LTargetY: Integer;
begin
  FRunner.World.SetValue(gpWestWall, Spot(13, 10), 1);
  LMonster := NewMonster(GREED_S_MONSTER1, 15, 10, True);
  LMonster.ScanTime := 0;
  LMonster.FireTime := 0;
  LIndex := FRunner.Add(LMonster);
  FRunner.State.TimeCount := 100;
  FRunner.Logic.MoveSprites;
  Assert.AreEqual(0, FRunner.Game.SpawnCount);
  Assert.AreEqual(130, Sprite(LIndex)^.ScanTime, 'it looks again later');
  // a wall that lets the bullets pass does not hide the player
  FRunner.World.SetValue(gpWestFlags, Spot(13, 10), 1 shl 6);
  LTargetX := -1;
  LTargetY := -1;
  Assert.AreEqual(2, FRunner.Logic.Scan.ScanX(Sprite(LIndex), 10, 15, 10, 10, 10, LTargetX, LTargetY));
  Assert.AreEqual(9, LTargetX, 'the tile beyond the one of the player, as the original');
  Assert.AreEqual(-1, LTargetY, 'the row is not written');
end;

procedure TTestGreedSpriteLogic.DovrebbeAprireLaPortaCheIlMostroUrta;
var
  LMonster: TGreedSprite;
  LIndex, LDoorIndex: Integer;
  LDoor: TGreedDoor;
begin
  LDoorIndex := AddDoor(24, 20, gdoVertical);
  LMonster := NewMonster(GREED_S_MONSTER1, 23, 20, True);
  // its side is already over the line of the door
  LMonster.X := 23 * TILE + 50 * FRACUNIT;
  LMonster.ActionTime := 0;
  LIndex := FRunner.Add(LMonster);
  FRunner.State.TimeCount := 100;
  FRunner.Logic.MoveSprites;
  LDoor := FRunner.World.GetDoor(LDoorIndex);
  Assert.IsTrue(LDoor.Opening);
  Assert.IsFalse(LDoor.Closing);
  Assert.AreEqual(20, LDoor.Timer);
  Assert.AreEqual(1, FRunner.Game.SoundCount, 'the door sounds once');
  Assert.AreEqual(GREED_SN_DOOR, FRunner.Game.LastSound);
  Assert.AreEqual(23 * TILE + 50 * FRACUNIT, Sprite(LIndex)^.X, 'the monster did not pass');
  Assert.AreEqual(128, Sprite(LIndex)^.Angle, 'and turned by 45 degrees');
end;

procedure TTestGreedSpriteLogic.DovrebbeLasciarePassareLaSondaDalleParte;
var
  LDoorIndex: Integer;
  LMonster: TGreedSprite;
begin
  LDoorIndex := AddDoor(24, 20, gdoVertical);
  LMonster := NewMonster(GREED_S_MONSTER1, 23, 20, True);
  FRunner.State.Probe := LMonster;
  Assert.IsTrue(FRunner.Logic.Movement.TryDoor(@FRunner.State.Probe, 24 * TILE, Center(20)), 'the probe');
  Assert.IsFalse(FRunner.World.GetDoor(LDoorIndex).Opening, 'the probe opens nothing');
  Assert.IsFalse(FRunner.Logic.Movement.TryDoor(@LMonster, 24 * TILE, Center(20)), 'a sprite');
  Assert.IsTrue(FRunner.World.GetDoor(LDoorIndex).Opening);
end;

procedure TTestGreedSpriteLogic.DovrebbeScrivereLeCaselleDeiMostriVivi;
var
  LSprite: TGreedSprite;
begin
  FRunner.World.SetValue(gpMapSprites, Spot(5, 5), 1);
  FRunner.World.SetValue(gpMapSprites, Spot(6, 5), GREED_SM_CLONE);
  FRunner.Add(NewMonster(GREED_S_MONSTER3, 30, 30, False));
  LSprite := NewMonster(GREED_S_MONSTER3, 31, 30, False);
  LSprite.HitPoints := 0;
  FRunner.Add(LSprite);
  LSprite := NewMonster(GREED_S_MONSTER3, 32, 30, False);
  LSprite.DeathEvent := 4;
  FRunner.Add(LSprite);
  FRunner.Add(NewSprite(GREED_S_PROXMINE, 255, 33, 30));
  FRunner.Logic.RecreateMapSprites;
  Assert.AreEqual(0, Integer(FRunner.World.GetValue(gpMapSprites, Spot(5, 5))), 'nobody is there any more');
  Assert.AreEqual(GREED_SM_CLONE, Integer(FRunner.World.GetValue(gpMapSprites, Spot(6, 5))), 'not a monster');
  Assert.AreEqual(1, Integer(FRunner.World.GetValue(gpMapSprites, Spot(30, 30))));
  Assert.AreEqual(0, Integer(FRunner.World.GetValue(gpMapSprites, Spot(31, 30))), 'dead');
  Assert.AreEqual(0, Integer(FRunner.World.GetValue(gpMapSprites, Spot(32, 30))), 'its death runs an event');
  Assert.AreEqual(0, Integer(FRunner.World.GetValue(gpMapSprites, Spot(33, 30))), 'a mine');
end;

procedure TTestGreedSpriteLogic.DovrebbeTogliereLuceAlleCaselleDegliSpriteCaldi;
var
  LSprite: TGreedSprite;
  LHot: Integer;
  LLights: TGreedTileLights;
begin
  LSprite := NewSprite(160, 255, 20, 20);
  LSprite.MoveSpeed := 0;
  LSprite.Heat := 100;
  FRunner.Add(LSprite);
  // a sleeping one that is very hot: the eight tiles around too, and it cools down
  LSprite := NewSprite(160, 1, 40, 40);
  LSprite.Active := False;
  LSprite.MoveSpeed := 0;
  LSprite.Heat := 400;
  LHot := FRunner.Add(LSprite);
  FRunner.Logic.MoveSprites;
  Assert.AreEqual(-100, FRunner.Logic.RealLight^[Spot(20, 20)]);
  Assert.AreEqual(0, FRunner.Logic.RealLight^[Spot(21, 20)]);
  Assert.AreEqual(-300, FRunner.Logic.RealLight^[Spot(40, 40)]);
  Assert.AreEqual(-200, FRunner.Logic.RealLight^[Spot(41, 41)]);
  Assert.AreEqual(-200, FRunner.Logic.RealLight^[Spot(39, 40)]);
  Assert.AreEqual(336, Sprite(LHot)^.Heat);
  // the lights of somebody else (the renderer)
  FillChar(LLights, SizeOf(LLights), 0);
  FRunner.Logic.RealLight := @LLights;
  FRunner.Logic.MoveSprites;
  Assert.AreEqual(-100, LLights[Spot(20, 20)]);
  Assert.AreEqual(-100, FRunner.Logic.RealLight^[Spot(20, 20)]);
  FRunner.Logic.RealLight := nil;
  Assert.AreEqual(-100, FRunner.Logic.RealLight^[Spot(20, 20)], 'its own lights again, as they were');
end;

procedure TTestGreedSpriteLogic.DovrebbeMirareInAltoEInBasso;
var
  LSprite: TGreedSprite;
  LUp, LDown: Integer;
begin
  LSprite := NewMonster(GREED_S_MONSTER1, 10, 10, True);
  // the target is 2 tiles to the east (32 steps of 4 units) and 180 units higher than the muzzle (45 steps)
  LUp := FRunner.Logic.Scan.GetFireAngle(@LSprite, 40 * FRACUNIT, 12, 10, Center(12), Center(10), 200 * FRACUNIT);
  Assert.AreEqual(TGreedTargetAngles.Angle(32, 45), LUp);
  Assert.IsTrue(LUp > 0);
  LSprite.Z := 300 * FRACUNIT;
  LDown := FRunner.Logic.Scan.GetFireAngle(@LSprite, 40 * FRACUNIT, 12, 10, Center(12), Center(10), 0);
  Assert.AreEqual(-TGreedTargetAngles.Angle(32, 80), LDown);
  // too far for the table
  Assert.AreEqual(0, FRunner.Logic.Scan.GetFireAngle(@LSprite, 40 * FRACUNIT, 40, 10, Center(40), Center(10), 0));
  // at the same height
  LSprite.Z := 0;
  Assert.AreEqual(0, FRunner.Logic.Scan.GetFireAngle(@LSprite, 40 * FRACUNIT, 12, 10, Center(12), Center(10),
    20 * FRACUNIT));
end;

procedure TTestGreedSpriteLogic.DovrebbeEsplodereAncheSeNonNasceNessunoSprite;
begin
  FRunner.World.SetValue(gpWestWall, Spot(24, 20), 1);
  FRunner.Add(NewBullet(GREED_S_GRENADE, 23, 20, 0));
  FRunner.Game.RefuseSpawns := True;
  FRunner.Logic.MoveSprites;
  // the puff, 12 + 8 + 8 pieces and the explosion were asked for; the original would write through nil
  Assert.AreEqual(30, FRunner.Game.SpawnCount);
  Assert.AreEqual(0, FRunner.Sprites.Count);
end;

procedure TTestGreedSpriteLogic.DovrebbeFermareLaScansioneAllaFineDellaMappa;
var
  LSprite: TGreedSprite;
  LTargetX, LTargetY: Integer;
begin
  // no walls at all: the scan to the south of the original has no limit
  LSprite := NewMonster(GREED_S_MONSTER1, 10, 10, True);
  LTargetX := 0;
  LTargetY := 0;
  Assert.AreEqual(0, FRunner.Logic.Scan.ScanY(@LSprite, 5, 20, 20, 40, 40, LTargetX, LTargetY));
  Assert.AreEqual(0, FRunner.Logic.Scan.ScanAngle(@LSprite, 5, 20, 20, 40, 40, LTargetX, LTargetY));
  Assert.AreEqual(2, FRunner.Logic.Scan.ScanY(@LSprite, 5, 20, 20, 20, 60, LTargetX, LTargetY), 'far to the south');
  Assert.AreEqual(61, LTargetY);
end;

procedure TTestGreedSpriteLogic.DovrebbeFarCadereCioCheStaPerAria;
var
  LFallen, LSleeping: Integer;
  LSprite: TGreedSprite;
begin
  LSprite := NewSprite(GREED_S_BLOODSPLAT, 128, 30, 30);
  LSprite.Z := 5 * FRACUNIT;
  LFallen := FRunner.Add(LSprite);
  LSprite := NewMonster(GREED_S_MONSTER1, 40, 40, False);
  LSprite.Z := 40 * FRACUNIT;
  LSprite.ZAdjust := 3 * FRACUNIT;
  LSleeping := FRunner.Add(LSprite);
  FRunner.Logic.MoveSprites;
  Assert.AreEqual(3 * FRACUNIT, Sprite(LFallen)^.Z, 'two units a tic');
  Assert.AreEqual(24 * FRACUNIT, Sprite(LSleeping)^.Z, 'sixteen units a tic');
  Assert.AreEqual(5 * FRACUNIT, Sprite(LFallen)^.OldZ);
  Assert.AreEqual(3 * FRACUNIT, Sprite(LFallen)^.NewZ);
  FRunner.Logic.MoveSprites;
  FRunner.Logic.MoveSprites;
  Assert.AreEqual(FRACUNIT, Sprite(LFallen)^.Z, 'it stops when it is not more than a unit above the floor');
  Assert.AreEqual(3 * FRACUNIT, Sprite(LSleeping)^.Z, 'at its height above the floor');
end;

procedure TTestGreedSpriteLogic.DovrebbeDareLaTabellaDegliAngoliDelCodiceOriginale;
var
  LGolden: TStringList;
  LTrace: TSpriteTrace;
  LDistance, LHeight: Integer;
  LExpected: string;
begin
  LGolden := TStringList.Create;
  LTrace := TSpriteTrace.Create;
  try
    LGolden.LoadFromFile(TGreedRealData.GoldenPath('sprites.golden.txt'));
    LExpected := '';
    for LDistance := 0 to LGolden.Count - 1 do
      if LGolden[LDistance].StartsWith('A ') then
        LExpected := LGolden[LDistance].Substring(2);
    Assert.AreNotEqual('', LExpected, 'the line A of the golden file');
    LTrace.Reset(nil);
    for LDistance := 0 to GREED_TARGET_ANGLE_SIZE - 1 do
      for LHeight := 0 to GREED_TARGET_ANGLE_SIZE - 1 do
        LTrace.Add(TGreedTargetAngles.Angle(LDistance, LHeight), '');
    Assert.AreEqual(LExpected, IntToHex(LTrace.Hash, 8));
    Assert.AreEqual(0, TGreedTargetAngles.Angle(10, 0), 'level');
  finally
    LTrace.Free;
    LGolden.Free;
  end;
end;

procedure TTestGreedSpriteLogic.DovrebbeDareLeStesseImpronteDelCodiceOriginale;
var
  LGolden: TStringList;
  LHashes: TList<Cardinal>;
  LParts: TArray<string>;
  LLine, LScenario, LTics, LTic, LScenarios, LTotalTics, LSkipped: Integer;
begin
  LGolden := TStringList.Create;
  LHashes := TList<Cardinal>.Create;
  try
    LGolden.LoadFromFile(TGreedRealData.GoldenPath('sprites.golden.txt'));
    LScenarios := 0;
    LTotalTics := 0;
    LSkipped := 0;
    LLine := 0;
    while LLine < LGolden.Count do
    begin
      if LGolden[LLine].StartsWith('X ') then
        Inc(LSkipped);
      if not LGolden[LLine].StartsWith('S ') then
      begin
        Inc(LLine);
        Continue;
      end;
      LParts := LGolden[LLine].Split([' ']);
      LScenario := StrToInt(LParts[1]);
      LTics := StrToInt(LParts[2]);
      LHashes.Clear;
      FRunner.Run(BuildSpriteScenario(LScenario), LHashes);
      Assert.AreEqual(LTics, LHashes.Count, Format('scenario %d: the number of tics', [LScenario]));
      for LTic := 0 to LTics - 1 do
        if LGolden[LLine + 1 + LTic] <> IntToHex(LHashes[LTic], 8) then
          Assert.Fail(Format('scenario %d: the tic %d differs from the original (%s, here %s)',
            [LScenario, LTic, LGolden[LLine + 1 + LTic], IntToHex(LHashes[LTic], 8)]));
      Inc(LScenarios);
      LTotalTics := LTotalTics + LTics;
      LLine := LLine + 1 + LTics;
    end;
    Assert.AreEqual(SPRITE_SCENARIO_COUNT, LScenarios + LSkipped, 'every scenario is in the golden file');
    Assert.IsTrue(LTotalTics > 10000, 'the tics that were compared');
  finally
    LHashes.Free;
    LGolden.Free;
  end;
end;

end.
