{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the secret codes of Greed                               }
{                                                                              }
{  TGreedCheatCodes on a level in memory with the stand-ins of the rest of the  }
{  game (TLibraryLevelRunner). The parity with the original raven.pas is the    }
{  golden test of DelphiDoom.Tests.Greed.LevelRules                             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Greed.CheatCodes;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Greed.Types, DelphiDoom.Greed.Actor.Types,
  DelphiDoom.Greed.LinkedPool, DelphiDoom.Greed.Game.Constants, DelphiDoom.Greed.CheatCodes,
  DelphiDoom.Tests.Greed.LevelRunner;

type
  [TestFixture]
  [Category('greed')]
  TTestGreedCheatCodes = class(TObject)
  private
    FRunner: TLibraryLevelRunner;
    procedure TypeCode(const AText: string);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeSollevareSeUnaDipendenzaManca;
    [Test]
    procedure DovrebbeTenereLeUltimeDiciannoveLettere;
    [Test]
    procedure DovrebbeTrovareIlCodiceSenzaGuardareLeMaiuscole;
    [Test]
    procedure DovrebbeUccidereTuttoConBelfast;
    [Test]
    procedure DovrebbeAccendereESpegnereIlGodMode;
    [Test]
    [TestCase('Channel7', 'channel7,Rob Lays Eggs')]
    [TestCase('LizardMan', 'lizardman,Jeremy Lays Eggs')]
    [TestCase('Dominatrix', 'dominatrix,On your knees worm!')]
    [TestCase('Cyborg', 'cyborg,Psyborgs Rule!')]
    procedure DovrebbeDireSoloUnaFrase(const ACode, AMessage: string);
    [Test]
    procedure DovrebbeRidareLaSaluteConRaven;
    [Test]
    procedure DovrebbeMostrareTuttaLaMappaConOmni;
    [Test]
    procedure DovrebbeRiempireLeMunizioniConKmfdm;
    [Test]
    procedure DovrebbeCompletareGliObiettiviConBeavis;
    [Test]
    procedure DovrebbeIngrandireGliSpriteConGulliver;
    [Test]
    procedure DovrebbeRiempireLInventarioConGimme;
    [Test]
    procedure DovrebbeCambiareLaVistaDelNemicoConTaco;
    [Test]
    procedure DovrebbeCambiareEpisodio;
    [Test]
    procedure DovrebbeIgnorareGliAltriEpisodiNellaDemo;
    [Test]
    [TestCase('Diecimila', 'score10000,10000')]
    [TestCase('Ventimila', 'score20000,20000')]
    [TestCase('Cinquantamila', 'score50000,50000')]
    procedure DovrebbeDarePunti(const ACode: string; AScore: Integer);
    [Test]
    procedure DovrebbeAndareAllaMappaDelProprioEpisodio;
    [Test]
    procedure DovrebbeLasciareIlCodiceDiUnAltroEpisodio;
    [Test]
    procedure DovrebbeAndareAlleUltimeMappeDaOgniEpisodio;
    [Test]
    procedure DovrebbeDareUnArmaConBlammo;
    [Test]
    procedure DovrebbeScegliereLoSlotDueAncheSenzaCodiceIntero;
    [Test]
    procedure DovrebbeNonFareNullaConPocheLettere;
  end;

implementation

{ TTestGreedCheatCodes }

procedure TTestGreedCheatCodes.Setup;
begin
  FRunner := TLibraryLevelRunner.Create;
  FRunner.LoadEmpty;
end;

procedure TTestGreedCheatCodes.TearDown;
begin
  FRunner.Free;
end;

procedure TTestGreedCheatCodes.TypeCode(const AText: string);
var
  LIndex: Integer;
begin
  FRunner.Game.Calls.Clear;
  FRunner.Game.Messages.Clear;
  for LIndex := 1 to Length(AText) do
    FRunner.Cheats.AddCharacter(AText[LIndex]);
  FRunner.Cheats.SpecialCode;
end;

procedure TTestGreedCheatCodes.DovrebbeSollevareSeUnaDipendenzaManca;
begin
  Assert.WillRaise(
    procedure
    begin
      TGreedCheatCodes.Create(nil, FRunner.Game, FRunner.Game, FRunner.Game, FRunner.Game).Free;
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TGreedCheatCodes.Create(FRunner.State, nil, FRunner.Game, FRunner.Game, FRunner.Game).Free;
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TGreedCheatCodes.Create(FRunner.State, FRunner.Game, nil, FRunner.Game, FRunner.Game).Free;
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TGreedCheatCodes.Create(FRunner.State, FRunner.Game, FRunner.Game, nil, FRunner.Game).Free;
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TGreedCheatCodes.Create(FRunner.State, FRunner.Game, FRunner.Game, FRunner.Game, nil).Free;
    end, EArgumentNilException);
end;

procedure TTestGreedCheatCodes.DovrebbeTenereLeUltimeDiciannoveLettere;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 24 do
    FRunner.Cheats.AddCharacter(Char(Ord('a') + LIndex));
  Assert.AreEqual('ghijklmnopqrstuvwxy', FRunner.State.SecretBuf);
  FRunner.Cheats.AddCharacter(' ');
  FRunner.Cheats.AddCharacter('-');
  Assert.AreEqual('ghijklmnopqrstuvwxy', FRunner.State.SecretBuf, 'only letters and digits');
  FRunner.Cheats.AddCharacter('7');
  FRunner.Cheats.AddCharacter('Z');
  Assert.AreEqual('ijklmnopqrstuvwxy7Z', FRunner.State.SecretBuf);
end;

procedure TTestGreedCheatCodes.DovrebbeTrovareIlCodiceSenzaGuardareLeMaiuscole;
begin
  FRunner.State.SecretBuf := 'xxRaVeNyy';
  Assert.IsFalse(FRunner.Cheats.CheckSecret('omni'));
  Assert.AreEqual('xxRaVeNyy', FRunner.State.SecretBuf);
  Assert.IsTrue(FRunner.Cheats.CheckSecret('RAVEN'));
  Assert.AreEqual('', FRunner.State.SecretBuf, 'a code that is found empties the letters');
  Assert.IsFalse(FRunner.Cheats.CheckSecret('raven'));
end;

procedure TTestGreedCheatCodes.DovrebbeUccidereTuttoConBelfast;
var
  LGone, LCorpse, LItem: Integer;
begin
  // the stand-in of KillSprite takes the odd kinds out of the list and leaves the others as corpses
  LGone := FRunner.AddSprite(GREED_S_MONSTER1, 20, 20);
  FRunner.Sprites.Item(LGone)^.HitPoints := 50;
  LItem := FRunner.PutItem(GREED_SM_MEDPAK1, GREED_S_MEDPAK1, 22, 20);
  LCorpse := FRunner.AddSprite(GREED_S_MONSTER1_NS, 24, 20);
  FRunner.Sprites.Item(LCorpse)^.HitPoints := 80;
  FRunner.World.SetValue(gpMapSprites, 20 * GREED_MAP_SIZE + 24, 99);
  TypeCode('belfast');
  Assert.AreEqual(2, FRunner.Game.CountOf('KillSprite'));
  Assert.IsTrue(FRunner.Game.Has(Format('KillSprite %d %d %d %d', [GREED_S_MONSTER1,
    20 * GREED_FRACTILEUNIT + 32 * GREED_FRACUNIT, 20 * GREED_FRACTILEUNIT + 32 * GREED_FRACUNIT, GREED_S_BULLET3])));
  Assert.AreEqual(2, FRunner.State.Player.BodyCount);
  Assert.AreEqual(2, FRunner.Sprites.Count, 'the item and the corpse');
  Assert.AreEqual(LItem, FRunner.Sprites.First);
  Assert.AreEqual(0, FRunner.Sprites.Item(LCorpse)^.HitPoints);
  Assert.AreEqual(0, FRunner.MapSprite(24, 20), 'the tile of a killed sprite is free');
  Assert.AreEqual(GREED_SM_MEDPAK1, FRunner.MapSprite(22, 20), 'what has no hit points stays');
  Assert.AreEqual('DeathKiss', FRunner.Game.Messages[0]);
  Assert.AreEqual('', FRunner.State.SecretBuf);
end;

procedure TTestGreedCheatCodes.DovrebbeAccendereESpegnereIlGodMode;
begin
  TypeCode('god');
  Assert.IsTrue(FRunner.State.GodMode);
  Assert.AreEqual('GodMode On', FRunner.Game.Messages[0]);
  TypeCode('ALLAHMODE');
  Assert.IsFalse(FRunner.State.GodMode);
  Assert.AreEqual('GodMode Off', FRunner.Game.Messages[0]);
end;

procedure TTestGreedCheatCodes.DovrebbeDireSoloUnaFrase(const ACode, AMessage: string);
begin
  TypeCode(ACode);
  Assert.AreEqual(1, FRunner.Game.Messages.Count);
  Assert.AreEqual(AMessage, FRunner.Game.Messages[0]);
  Assert.AreEqual('', FRunner.State.SecretBuf);
  TypeCode('mooman');
  Assert.AreEqual('Brady is better than you, and that ain''t saying much!', FRunner.Game.Messages[0]);
end;

procedure TTestGreedCheatCodes.DovrebbeRidareLaSaluteConRaven;
begin
  FRunner.State.Player.Angst := 3;
  FRunner.State.Player.Shield := 4;
  TypeCode('raven');
  Assert.AreEqual(FRunner.State.Player.MaxAngst, FRunner.State.Player.Angst);
  Assert.AreEqual(FRunner.State.Player.MaxShield, FRunner.State.Player.Shield);
  Assert.AreEqual('Ambrosia', FRunner.Game.Messages[0]);
end;

procedure TTestGreedCheatCodes.DovrebbeMostrareTuttaLaMappaConOmni;
begin
  FRunner.World.SetValue(gpNorthWall, 100, 12);
  FRunner.World.SetValue(gpWestWall, 200, 1);
  TypeCode('omni');
  Assert.AreEqual(GREED_WALL_COLOR, Integer(FRunner.State.Player.NorthMap[100]));
  Assert.AreEqual(0, Integer(FRunner.State.Player.NorthMap[200]));
  Assert.AreEqual(GREED_WALL_COLOR, Integer(FRunner.State.Player.WestMap[200]));
  Assert.AreEqual(0, Integer(FRunner.State.Player.WestMap[100]));
  Assert.AreEqual('Omniscience', FRunner.Game.Messages[0]);
end;

procedure TTestGreedCheatCodes.DovrebbeRiempireLeMunizioniConKmfdm;
begin
  TypeCode('kmfdm');
  Assert.AreEqual(999, FRunner.State.Player.Ammo[0]);
  Assert.AreEqual(999, FRunner.State.Player.Ammo[1]);
  Assert.AreEqual(999, FRunner.State.Player.Ammo[2]);
  Assert.AreEqual(-1, FRunner.Game.OldShots, 'the ammunition is drawn again');
  Assert.AreEqual('Backpack of Holding', FRunner.Game.Messages[0]);
end;

procedure TTestGreedCheatCodes.DovrebbeCompletareGliObiettiviConBeavis;
begin
  FRunner.State.PCount[0] := 2;
  FRunner.State.PCount[1] := 1;
  FRunner.State.SCount[6] := 3;
  FRunner.State.Player.LevelScore := 5000;
  TypeCode('beavis');
  Assert.AreEqual(100, FRunner.State.Player.LevelScore);
  Assert.AreEqual(2, FRunner.State.Player.Primaries[0]);
  Assert.AreEqual(1, FRunner.State.Player.Primaries[1]);
  Assert.AreEqual(3, FRunner.State.Player.Secondaries[6]);
  Assert.AreEqual(0, FRunner.State.Player.Secondaries[0]);
  Assert.AreEqual('Time Warp', FRunner.Game.Messages[0]);
end;

procedure TTestGreedCheatCodes.DovrebbeIngrandireGliSpriteConGulliver;
var
  LSprite: Integer;
begin
  LSprite := FRunner.AddSprite(GREED_S_MONSTER1, 20, 20);
  FRunner.Sprites.Item(LSprite)^.Scale := 1;
  TypeCode('gulliver');
  Assert.AreEqual(2, FRunner.Sprites.Item(LSprite)^.Scale);
  Assert.IsTrue(FRunner.State.MidgetMode);
  Assert.AreEqual('Midget Mode On', FRunner.Game.Messages[0]);
  TypeCode('gulliver');
  Assert.AreEqual(1, FRunner.Sprites.Item(LSprite)^.Scale);
  Assert.IsFalse(FRunner.State.MidgetMode);
  Assert.AreEqual('Midget Mode Off', FRunner.Game.Messages[0]);
end;

procedure TTestGreedCheatCodes.DovrebbeRiempireLInventarioConGimme;
begin
  TypeCode('gimme');
  Assert.AreEqual(20, FRunner.State.Player.Inventory[0]);
  Assert.AreEqual(20, FRunner.State.Player.Inventory[1]);
  Assert.AreEqual(15, FRunner.State.Player.Inventory[2]);
  Assert.AreEqual(10, FRunner.State.Player.Inventory[8]);
  Assert.AreEqual(10, FRunner.State.Player.Inventory[12]);
  Assert.AreEqual('Bag of Holding', FRunner.Game.Messages[0]);

  // the demo does not have the last four items
  FRunner.State.Player.Inventory[9] := 0;
  FRunner.State.Player.Inventory[12] := 0;
  FRunner.State.Demo := True;
  TypeCode('gimme');
  Assert.AreEqual(10, FRunner.State.Player.Inventory[8]);
  Assert.AreEqual(0, FRunner.State.Player.Inventory[9]);
  Assert.AreEqual(0, FRunner.State.Player.Inventory[12]);
end;

procedure TTestGreedCheatCodes.DovrebbeCambiareLaVistaDelNemicoConTaco;
begin
  TypeCode('taco');
  Assert.AreEqual(1, FRunner.State.EnemyViewMode);
  TypeCode('taco');
  Assert.AreEqual(0, FRunner.State.EnemyViewMode);
  Assert.AreEqual('Enemy view toggled', FRunner.Game.Messages[0]);
end;

procedure TTestGreedCheatCodes.DovrebbeCambiareEpisodio;
begin
  TypeCode('game2');
  Assert.IsFalse(FRunner.State.Game1);
  Assert.IsTrue(FRunner.State.Game2);
  Assert.IsFalse(FRunner.State.Game3);
  Assert.AreEqual(2, FRunner.Game.GameEpisode);
  Assert.AreEqual('"newmap 8 2"', FRunner.Game.Calls.CommaText, 'the first map of the episode, alone');
  TypeCode('game3');
  Assert.IsTrue(FRunner.State.Game3);
  Assert.IsFalse(FRunner.State.Game2);
  Assert.AreEqual(3, FRunner.Game.GameEpisode);
  Assert.IsTrue(FRunner.Game.Has('newmap 16 2'));
  TypeCode('game1');
  Assert.IsTrue(FRunner.State.Game1);
  Assert.IsFalse(FRunner.State.Game3);
  Assert.AreEqual(1, FRunner.Game.GameEpisode);
  Assert.IsTrue(FRunner.Game.Has('newmap 0 2'));
end;

procedure TTestGreedCheatCodes.DovrebbeIgnorareGliAltriEpisodiNellaDemo;
begin
  FRunner.State.Demo := True;
  TypeCode('game2');
  Assert.IsTrue(FRunner.State.Game1);
  Assert.IsFalse(FRunner.State.Game2);
  Assert.AreEqual(0, FRunner.Game.Calls.Count);
  // as the original: the letters are emptied anyway
  Assert.AreEqual('', FRunner.State.SecretBuf);
end;

procedure TTestGreedCheatCodes.DovrebbeDarePunti(const ACode: string; AScore: Integer);
begin
  TypeCode(ACode);
  Assert.AreEqual(Format('"addscore %d"', [AScore]), FRunner.Game.Calls.CommaText);
  Assert.AreEqual(AScore, FRunner.State.Player.Score);
end;

procedure TTestGreedCheatCodes.DovrebbeAndareAllaMappaDelProprioEpisodio;
begin
  // the first episode has the maps go01 .. go07
  TypeCode('go05');
  Assert.AreEqual('"newmap 4 2",INT_TimerHook', FRunner.Game.Calls.CommaText);
  Assert.AreEqual('', FRunner.State.SecretBuf);

  FRunner.State.Game1 := False;
  FRunner.State.Game3 := True;
  TypeCode('GO22');
  Assert.IsTrue(FRunner.Game.Has('newmap 21 2'));

  // the demo has only the first three
  FRunner.State.Demo := True;
  TypeCode('go03');
  Assert.IsTrue(FRunner.Game.Has('newmap 2 2'));
  TypeCode('go23');
  Assert.AreEqual(0, FRunner.Game.CountOf('newmap'));
end;

procedure TTestGreedCheatCodes.DovrebbeLasciareIlCodiceDiUnAltroEpisodio;
begin
  FRunner.State.Game1 := False;
  FRunner.State.Game2 := True;
  TypeCode('go05');
  Assert.AreEqual(0, FRunner.Game.CountOf('newmap'));
  // as the original: the timer hook is asked for again whenever the letters have "go" in them
  Assert.AreEqual('INT_TimerHook', FRunner.Game.Calls.CommaText);
  Assert.AreEqual('go05', FRunner.State.SecretBuf, 'the letters stay');

  // typed after it, a code of the episode is found
  TypeCode('go09');
  Assert.IsTrue(FRunner.Game.Has('newmap 8 2'));
  Assert.AreEqual('', FRunner.State.SecretBuf);
end;

procedure TTestGreedCheatCodes.DovrebbeAndareAlleUltimeMappeDaOgniEpisodio;
begin
  TypeCode('go23');
  Assert.IsTrue(FRunner.Game.Has('newmap 22 2'));
  FRunner.State.Game1 := False;
  FRunner.State.Game2 := True;
  TypeCode('go32');
  Assert.IsTrue(FRunner.Game.Has('newmap 31 2'));
  TypeCode('go33');
  Assert.AreEqual(0, FRunner.Game.CountOf('newmap'), 'there is no map 33');
end;

procedure TTestGreedCheatCodes.DovrebbeDareUnArmaConBlammo;
begin
  FRunner.State.WeapMode := 2;
  TypeCode('blammo4');
  Assert.AreEqual(16, FRunner.State.Player.Weapons[2]);
  Assert.AreEqual(2, FRunner.State.Player.CurrentWeapon);
  Assert.AreEqual(0, FRunner.State.WeapMode);
  Assert.AreEqual('"loadweapon 16"', FRunner.Game.Calls.CommaText);
  TypeCode('blammo1');
  Assert.AreEqual(2, FRunner.State.Player.Weapons[2]);
  TypeCode('blammo6');
  Assert.AreEqual(18, FRunner.State.Player.Weapons[2]);
end;

procedure TTestGreedCheatCodes.DovrebbeScegliereLoSlotDueAncheSenzaCodiceIntero;
begin
  // no weapon in the slot 2: nothing
  TypeCode('blx');
  Assert.AreEqual(0, FRunner.Game.Calls.Count);
  Assert.AreEqual(0, FRunner.State.Player.CurrentWeapon);
  Assert.AreEqual('blx', FRunner.State.SecretBuf);

  // as the original: with a weapon there, any letters with "bl" in them select it
  FRunner.State.Player.Weapons[2] := 4;
  FRunner.Cheats.SpecialCode;
  Assert.AreEqual(2, FRunner.State.Player.CurrentWeapon);
  Assert.IsTrue(FRunner.Game.Has('loadweapon 4'));
  Assert.AreEqual('blx', FRunner.State.SecretBuf);
end;

procedure TTestGreedCheatCodes.DovrebbeNonFareNullaConPocheLettere;
begin
  FRunner.State.Player.Weapons[2] := 4;
  TypeCode('bl');
  Assert.AreEqual(0, FRunner.Game.Calls.Count);
  Assert.AreEqual('bl', FRunner.State.SecretBuf);
  FRunner.State.SecretBuf := '';
  TypeCode('zzzzqqqq');
  Assert.AreEqual(0, FRunner.Game.Calls.Count);
  Assert.AreEqual(0, FRunner.Game.Messages.Count);
  Assert.AreEqual('zzzzqqqq', FRunner.State.SecretBuf, 'letters that are no code wait for the next ones');
end;

end.
