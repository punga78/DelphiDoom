{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TGreedGame, the parts of the game of Greed together     }
{                                                                              }
{  The game is made on stand-ins (DelphiDoom.Tests.Greed.GameFakes): a room     }
{  built in memory, an archive without data, commands pressed by the test       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Greed.Game;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Greed.Types, DelphiDoom.Greed.Game,
  DelphiDoom.Tests.Greed.GameFakes;

type
  [TestFixture]
  [Category('greed')]
  TTestGreedGame = class(TObject)
  strict private
    FSetup: TFakeGameSetup;
    procedure Start;
    function TileY: Integer;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeSollevareConDipendenzeNulle;
    [Test]
    procedure DovrebbeMettereIlGiocatoreSulPuntoDiPartenza;
    [Test]
    procedure DovrebbeCaricareLaMappaConMusicaEBriefing;
    [Test]
    procedure DovrebbeLeggereIComandiSoloSuiTicDispari;
    [Test]
    procedure DovrebbeCamminareVersoNordConIlComando;
    [Test]
    procedure DovrebbeFermarsiControUnMuro;
    [Test]
    procedure DovrebbeFareDodiciTimeUpdatePerGiroEDisegnareUnaVista;
    [Test]
    procedure DovrebbeDareAllaVistaLArmaDelGiocatore;
    [Test]
    procedure DovrebbeSparareDentroLaVista;
    [Test]
    procedure DovrebbeScegliereUnOggettoQuandoLaBarraEDisegnata;
    [Test]
    procedure NonDovrebbeScegliereOggettiSenzaLaBarra;
    [Test]
    procedure DovrebbePosareUnaMinaConUsaOggetto;
    [Test]
    procedure DovrebbeLanciareLaGranataNelGiro;
    [Test]
    procedure DovrebbeFinireConIlMenu;
    [Test]
    procedure DovrebbeContinuareSeIlMenuNonEsce;
    [Test]
    procedure NonDovrebbeFareNullaAGiocoFinito;
    [Test]
    procedure DovrebbePassareAllaMappaSuccessiva;
    [Test]
    procedure DovrebbeFinireDopoLUltimaMappaDellaDemo;
    [Test]
    procedure DovrebbeRicominciareLaMappaDopoLaMorte;
    [Test]
    procedure DovrebbeAnimareIPavimenti;
    [Test]
    procedure DovrebbeFerireSulPavimentoCheFaMale;
    [Test]
    procedure DovrebbeRaccogliereLaCassaDiMunizioni;
    [Test]
    procedure DovrebbeAprireLaPortaUrtandola;
    [Test]
    procedure DovrebbeFarNascereIlMostroDellaMappa;
    [Test]
    procedure DovrebbeUccidereIlMostroSparando;
    [Test]
    procedure DovrebbeEseguireUnCodiceSegreto;
    [Test]
    procedure DovrebbeCambiareCanzone;
    [Test]
    procedure DovrebbeEseguireLoScriptDellaMappa;
    [Test]
    procedure DovrebbeDimezzareLoSguardoInBassaRisoluzione;
    [Test]
    procedure DovrebbeDareLaPosizioneDelGiocatoreAiSuoni;
  end;

implementation

uses
  DelphiDoom.Greed.Actor.Types, DelphiDoom.Greed.LinkedPool, DelphiDoom.Greed.World.Intf,
  DelphiDoom.Greed.Game.Constants, DelphiDoom.Greed.PlayerControl.Intf, DelphiDoom.Greed.PlayerControl,
  DelphiDoom.Greed.CommandState, DelphiDoom.Greed.Inventory;

const
  HALF_TILE = 32 * GREED_FRACUNIT;
  FLOOR_DAMAGE = 1 shl 7;

{ TTestGreedGame }

procedure TTestGreedGame.Setup;
begin
  FSetup := TFakeGameSetup.Create;
end;

procedure TTestGreedGame.TearDown;
begin
  FreeAndNil(FSetup);
end;

procedure TTestGreedGame.Start;
begin
  FSetup.CreateGame;
  FSetup.Game.NewGame(0, 0, 2);
end;

function TTestGreedGame.TileY: Integer;
begin
  Result := FSetup.Game.State.Player.Y div GREED_FRACTILEUNIT;
end;

procedure TTestGreedGame.DovrebbeSollevareConDipendenzeNulle;
var
  LRaised: Boolean;
begin
  LRaised := False;
  try
    TGreedGame.Create(nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil).Free;
  except
    on EArgumentNilException do
      LRaised := True;
  end;
  Assert.IsTrue(LRaised);
  LRaised := False;
  try
    TGreedGame.Create(FSetup.Archive, FSetup.Maps, FSetup.Renderer, TGreedCommandState.Create(FSetup.Commands),
      FSetup.Sound, FSetup.Sound, FSetup.Random, TFakeSaveGames.Create, FSetup.Clock, FSetup.View, nil).Free;
  except
    on EArgumentNilException do
      LRaised := True;
  end;
  Assert.IsTrue(LRaised, 'the messages');
end;

procedure TTestGreedGame.DovrebbeMettereIlGiocatoreSulPuntoDiPartenza;
begin
  Start;
  Assert.AreEqual(FAKE_START_X * GREED_FRACTILEUNIT + HALF_TILE, FSetup.Game.State.Player.X);
  Assert.AreEqual(FAKE_START_Y * GREED_FRACTILEUNIT + HALF_TILE, FSetup.Game.State.Player.Y);
  Assert.AreEqual(FAKE_START_Y * GREED_MAP_SIZE + FAKE_START_X, FSetup.Game.State.Player.MapSpot);
  Assert.AreEqual(0, FSetup.Game.State.TimeCount);
  Assert.AreEqual(0, FSetup.Game.Map);
  Assert.IsFalse(FSetup.Game.Dead);
  Assert.IsFalse(FSetup.Game.QuitGame);
  Assert.AreEqual(GREED_GAME_VIEW_HEIGHT, FSetup.Game.State.Player.ScrollMax);
  Assert.AreEqual(0, Integer(FSetup.Game.World.GetValue(gpMapSprites, FSetup.Game.State.Player.MapSpot)),
    'the start is not a thing of the map');
end;

procedure TTestGreedGame.DovrebbeCaricareLaMappaConMusicaEBriefing;
begin
  Start;
  Assert.AreEqual(1, FSetup.Maps.Loads);
  Assert.AreEqual(1, FSetup.Sound.Songs.Count, 'the song of the map');
  Assert.AreEqual(1, FSetup.View.CountOf('MissionBriefing 0'));
  Assert.AreEqual(1, FSetup.View.CountOf('StartWait'));
  Assert.AreEqual(1, FSetup.View.CountOf('EndWait'));
  Assert.IsTrue(FSetup.View.CountOf('ResetDisplay') >= 1);
  Assert.AreEqual((1 + GREED_GAME_AMBIENT_LIGHT) * GREED_FRACUNIT, FSetup.Renderer.LastBlackZ,
    'newlights: the light of the settings');
  Assert.IsTrue(FSetup.Renderer.Backdrops >= 1, 'the sky of the script');
end;

procedure TTestGreedGame.DovrebbeLeggereIComandiSoloSuiTicDispari;
begin
  Start;
  FSetup.Game.Tic;
  Assert.AreEqual(1, FSetup.Game.State.TimeCount);
  Assert.AreEqual(1, FSetup.Commands.Readings);
  FSetup.Game.Tic;
  Assert.AreEqual(1, FSetup.Commands.Readings, 'the tic 2 does not read');
  FSetup.Game.Tic;
  Assert.AreEqual(2, FSetup.Commands.Readings);
end;

procedure TTestGreedGame.DovrebbeCamminareVersoNordConIlComando;
var
  LY: Integer;
begin
  Start;
  LY := FSetup.Game.State.Player.Y;
  FSetup.Commands.Pressed := [gcNorth];
  FSetup.Play(20);
  Assert.IsTrue(FSetup.Game.State.Player.Y < LY, 'north is towards the row 0');
  Assert.AreEqual(FAKE_START_X * GREED_FRACTILEUNIT + HALF_TILE, FSetup.Game.State.Player.X);
end;

procedure TTestGreedGame.DovrebbeFermarsiControUnMuro;
begin
  // a wall on the north side of the tile of the start
  FSetup.Maps.Put(gpNorthWall, FAKE_START_X, FAKE_START_Y, 1);
  Start;
  FSetup.Commands.Pressed := [gcNorth];
  FSetup.Play(150);
  Assert.AreEqual(FAKE_START_Y, TileY, 'the wall stops the player');
end;

procedure TTestGreedGame.DovrebbeFareDodiciTimeUpdatePerGiroEDisegnareUnaVista;
var
  LUpdates: Integer;
begin
  Start;
  LUpdates := FSetup.Sound.Updates;
  FSetup.Play(1);
  // UpdateSound is called once by every TimeUpdate: 2 before the view, 4 inside, 4 in UpdateView, 2 after
  Assert.AreEqual(12, FSetup.Sound.Updates - LUpdates);
  Assert.AreEqual(1, FSetup.Renderer.Views);
  Assert.AreEqual(1, FSetup.View.Overlays);
  Assert.AreEqual(1, FSetup.Game.State.Frames);
end;

procedure TTestGreedGame.DovrebbeDareAllaVistaLArmaDelGiocatore;
begin
  Start;
  FSetup.Play(1);
  Assert.IsTrue(FSetup.View.LastOverlay.WeaponVisible);
  Assert.AreEqual(FSetup.Game.WeaponX, FSetup.View.LastOverlay.WeaponX);
  Assert.AreEqual(FSetup.Game.WeaponY, FSetup.View.LastOverlay.WeaponY);
  Assert.AreEqual(2, FSetup.View.LastOverlay.TimeCount);
  FSetup.Game.State.Player.Angst := 0;
  FSetup.Play(1);
  Assert.IsFalse(FSetup.View.LastOverlay.WeaponVisible, 'a dead player holds nothing');
end;

procedure TTestGreedGame.DovrebbeSparareDentroLaVista;
var
  LSprites, LSounds: Integer;
begin
  Start;
  FSetup.Play(1);
  LSprites := FSetup.Game.State.Sprites.Count;
  LSounds := FSetup.Sound.Sounds.Count;
  FSetup.Commands.Pressed := [gcFire];
  FSetup.Play(3);
  Assert.IsTrue(FSetup.Game.State.Sprites.Count > LSprites, 'the shot is a sprite');
  Assert.IsTrue(FSetup.Sound.Sounds.Count > LSounds, 'the shot is heard');
end;

procedure TTestGreedGame.DovrebbeScegliereUnOggettoQuandoLaBarraEDisegnata;
begin
  Start;
  Assert.AreEqual(GREED_INVENTORY_NONE, FSetup.Game.Inventory.Cursor);
  FSetup.Play(1);
  // a new player has grenades (2), proximity mines (4), time bombs (5) and instawalls (7)
  Assert.AreEqual(2, FSetup.Game.Inventory.Cursor);
end;

procedure TTestGreedGame.NonDovrebbeScegliereOggettiSenzaLaBarra;
begin
  Start;
  FSetup.Game.StatusBar := False;
  FSetup.Play(1);
  Assert.AreEqual(GREED_INVENTORY_NONE, FSetup.Game.Inventory.Cursor);
end;

procedure TTestGreedGame.DovrebbePosareUnaMinaConUsaOggetto;
begin
  Start;
  FSetup.Play(1);
  FSetup.Game.Inventory.Cursor := 4;
  FSetup.Commands.Pressed := [gcUseItem];
  FSetup.Play(2);
  Assert.AreEqual(1, FSetup.Game.State.Player.Inventory[4]);
  Assert.AreEqual(1, FSetup.SpritesOfKind(GREED_S_PROXMINE));
  Assert.IsTrue(FSetup.View.Messages.IndexOf('Dropped Proximity Mine') >= 0);
  Assert.IsTrue(FSetup.View.CountOf('RefreshInventory') >= 1);
end;

procedure TTestGreedGame.DovrebbeLanciareLaGranataNelGiro;
begin
  Start;
  FSetup.Play(1);
  Assert.AreEqual(2, FSetup.Game.Inventory.Cursor);
  FSetup.Commands.Pressed := [gcUseItem];
  FSetup.Play(1);
  FSetup.Commands.Pressed := [];
  FSetup.Play(1);
  Assert.AreEqual(3, FSetup.Game.State.Player.Inventory[2]);
  Assert.IsFalse(FSetup.Game.Inventory.FireGrenade);
  Assert.AreEqual(1, FSetup.Sound.CountOf(GREED_SN_GRENADE));
end;

procedure TTestGreedGame.DovrebbeFinireConIlMenu;
begin
  Start;
  FSetup.View.QuitFromMenu := True;
  FSetup.Commands.Pressed := [gcMenu];
  FSetup.Play(2);
  Assert.AreEqual(1, FSetup.View.CountOf('ShowMenu'));
  Assert.IsTrue(FSetup.Game.QuitGame);
end;

procedure TTestGreedGame.DovrebbeContinuareSeIlMenuNonEsce;
var
  LTime: Integer;
begin
  Start;
  FSetup.Commands.Pressed := [gcMenu];
  FSetup.Play(1);
  LTime := FSetup.Game.State.TimeCount;
  Assert.AreEqual(1, FSetup.View.CountOf('ShowMenu'));
  Assert.IsFalse(FSetup.Game.QuitGame);
  Assert.IsFalse(FSetup.Game.State.ActivateMenu);
  Assert.AreEqual(LTime + GREED_KBDELAY, FSetup.Game.State.KeyboardDelay, 'the keys rest after the menu');
end;

procedure TTestGreedGame.NonDovrebbeFareNullaAGiocoFinito;
var
  LTime, LViews: Integer;
begin
  Start;
  FSetup.Game.State.QuitGame := True;
  LTime := FSetup.Game.State.TimeCount;
  LViews := FSetup.Renderer.Views;
  FSetup.Play(3);
  Assert.AreEqual(LTime, FSetup.Game.State.TimeCount);
  Assert.AreEqual(LViews, FSetup.Renderer.Views);
end;

procedure TTestGreedGame.DovrebbePassareAllaMappaSuccessiva;
begin
  Start;
  FSetup.Play(5);
  FSetup.Game.State.ExitLevel := True;
  FSetup.Play(1);
  Assert.AreEqual(1, FSetup.Game.Map);
  Assert.AreEqual(2, FSetup.Maps.Loads);
  Assert.AreEqual(1, FSetup.Maps.LastMap);
  Assert.AreEqual(1, FSetup.View.CountOf('FadeOutLevel'));
  Assert.IsFalse(FSetup.Game.State.ExitLevel);
  Assert.IsFalse(FSetup.Game.QuitGame);
  Assert.AreEqual(1, FSetup.View.CountOf('MissionBriefing 1'));
end;

procedure TTestGreedGame.DovrebbeFinireDopoLUltimaMappaDellaDemo;
begin
  FSetup.CreateGame;
  FSetup.Game.SetEdition(True, 1);
  FSetup.Game.NewGame(2, 0, 2);
  FSetup.Play(1);
  FSetup.Game.State.ExitLevel := True;
  FSetup.Play(1);
  Assert.IsTrue(FSetup.Game.QuitGame, 'the demo ends after its third map');
  Assert.AreEqual(3, FSetup.Game.Map);
end;

procedure TTestGreedGame.DovrebbeRicominciareLaMappaDopoLaMorte;
begin
  Start;
  FSetup.Commands.Pressed := [gcNorth];
  FSetup.Play(30);
  FSetup.Game.State.Player.Angst := 0;
  Assert.IsTrue(FSetup.Game.Dead);
  FSetup.Commands.Pressed := [gcRestart];
  FSetup.Play(2);
  Assert.IsFalse(FSetup.Game.Dead);
  Assert.AreEqual(FSetup.Game.State.Player.MaxAngst, FSetup.Game.State.Player.Angst);
  Assert.AreEqual(2, FSetup.Maps.Loads, 'the map is loaded again');
  Assert.IsFalse(FSetup.Game.State.DeadRestart);
  Assert.AreEqual(FAKE_START_Y, TileY, 'back on the start');
end;

procedure TTestGreedGame.DovrebbeAnimareIPavimenti;
begin
  Start;
  FSetup.Play(1);
  // wallanimcount 1: every picture shows the one before it
  Assert.AreEqual(59, FSetup.Renderer.FlatTranslations[57]);
  Assert.AreEqual(57, FSetup.Renderer.FlatTranslations[58]);
  FSetup.Play(1);
  Assert.AreEqual(59, FSetup.Renderer.FlatTranslations[57], 'the next step is 12 tics later');
  FSetup.Play(6);
  Assert.AreEqual(57, FSetup.Renderer.FlatTranslations[57], 'wallanimcount 2: its own picture');
  Assert.AreEqual(219, FSetup.Renderer.FlatTranslations[219]);
end;

procedure TTestGreedGame.DovrebbeFerireSulPavimentoCheFaMale;
var
  LShield: Integer;
begin
  FSetup.Maps.Put(gpFloorFlags, FAKE_START_X, FAKE_START_Y, FLOOR_DAMAGE);
  Start;
  LShield := FSetup.Game.State.Player.Shield;
  FSetup.Play(8);
  Assert.IsTrue(FSetup.Game.State.Player.Shield < LShield, 'the floor hurts every 12 tics');
  Assert.IsTrue(FSetup.Game.State.HurtBorder);
end;

procedure TTestGreedGame.DovrebbeRaccogliereLaCassaDiMunizioni;
begin
  FSetup.Maps.Put(gpMapSprites, FAKE_START_X, FAKE_START_Y - 2, GREED_S_AMMOBOX);
  Start;
  Assert.AreEqual(1, FSetup.SpritesOfKind(GREED_S_AMMOBOX));
  FSetup.Commands.Pressed := [gcNorth];
  FSetup.Play(60);
  Assert.AreEqual(0, FSetup.SpritesOfKind(GREED_S_AMMOBOX), 'the box is taken');
  Assert.IsTrue(FSetup.Game.State.Player.Ammo[0] + FSetup.Game.State.Player.Ammo[1] +
    FSetup.Game.State.Player.Ammo[2] > 300);
  Assert.IsTrue(FSetup.View.Messages.Count > 0);
end;

procedure TTestGreedGame.DovrebbeAprireLaPortaUrtandola;
var
  LDoor: TGreedDoor;
begin
  FSetup.Maps.Put(gpMapSprites, FAKE_START_X, FAKE_START_Y - 1, GREED_S_HDOOR1);
  Start;
  Assert.AreEqual(1, FSetup.Game.World.DoorCount);
  FSetup.Commands.Pressed := [gcNorth];
  FSetup.Play(40);
  LDoor := FSetup.Game.World.GetDoor(0);
  Assert.IsTrue(LDoor.Opening or LDoor.Open, 'the door was bumped');
  Assert.IsTrue(FSetup.Sound.CountOf(GREED_SN_DOOR) >= 1, 'TimeUpdate plays the sound of the door');
  Assert.IsFalse(FSetup.Game.State.DoorSound);
end;

procedure TTestGreedGame.DovrebbeFarNascereIlMostroDellaMappa;
begin
  FSetup.Maps.Put(gpMapSprites, FAKE_START_X, FAKE_START_Y - 4, GREED_S_MONSTER1);
  Start;
  Assert.AreEqual(1, FSetup.SpritesOfKind(GREED_S_MONSTER1));
  Assert.IsTrue(FSetup.Renderer.MonsterLoads >= 1, 'its pictures are asked of the renderer');
end;

procedure TTestGreedGame.DovrebbeUccidereIlMostroSparando;
var
  LIndex, LTurn: Integer;
  LSprite: PGreedSprite;
  LDead: Boolean;
begin
  FSetup.Maps.Put(gpMapSprites, FAKE_START_X, FAKE_START_Y - 3, GREED_S_MONSTER1);
  Start;
  FSetup.Game.State.GodMode := True;
  FSetup.Commands.Pressed := [gcFire];
  LDead := False;
  for LTurn := 1 to 600 do
  begin
    FSetup.Play(1);
    LIndex := FSetup.Game.State.Sprites.First;
    while LIndex <> GREED_POOL_NIL do
    begin
      LSprite := PGreedSprite(FSetup.Game.State.Sprites.Item(LIndex));
      if (LSprite^.Kind = GREED_S_MONSTER1) and (LSprite^.HitPoints = 0) then
        LDead := True;
      LIndex := FSetup.Game.State.Sprites.Next(LIndex);
    end;
    if LDead then
      Break;
  end;
  Assert.IsTrue(LDead, 'the monster in front of the player dies under its fire');
  Assert.AreEqual(1, FSetup.Game.State.Player.BodyCount);
end;

procedure TTestGreedGame.DovrebbeEseguireUnCodiceSegreto;
begin
  Start;
  FSetup.Commands.Typed := 'GOD';
  FSetup.Play(12);
  Assert.IsTrue(FSetup.Game.State.GodMode, 'the code typed a character a reading');
end;

procedure TTestGreedGame.DovrebbeCambiareCanzone;
begin
  Start;
  FSetup.Commands.Pressed := [gcNewSong];
  FSetup.Play(1);
  Assert.AreEqual(2, FSetup.Sound.Songs.Count);
  Assert.AreEqual(1, FSetup.Game.State.SongNum);
  Assert.IsFalse(FSetup.Game.State.NewSong);
end;

procedure TTestGreedGame.DovrebbeEseguireLoScriptDellaMappa;
begin
  // the script of a map is the lump of the map, counted from "SUX" instead of from "map"
  FSetup.Archive.Scripts.Add(0, 'LEVELSCORE 1234'#13#10'END'#13#10);
  Start;
  Assert.AreEqual(1234, FSetup.Game.State.Player.LevelScore, 'the script of the map 0 was read');
end;

procedure TTestGreedGame.DovrebbeDimezzareLoSguardoInBassaRisoluzione;
begin
  FSetup.CreateGame;
  FSetup.Game.LowResolution := True;
  Assert.AreEqual(GREED_MAXSCROLL1 div 2, FSetup.Game.Parts.Control.MaxScroll);
  FSetup.Game.LowResolution := False;
  Assert.AreEqual(GREED_MAXSCROLL1, FSetup.Game.Parts.Control.MaxScroll);
  Assert.IsFalse(FSetup.Game.LowResolution);
end;

procedure TTestGreedGame.DovrebbeDareLaPosizioneDelGiocatoreAiSuoni;
begin
  Start;
  Assert.AreEqual(FSetup.Game.State.Player.X, FSetup.Game.Listener.GetX);
  Assert.AreEqual(FSetup.Game.State.Player.Y, FSetup.Game.Listener.GetY);
  Assert.AreEqual(FSetup.Game.State.Player.Angle, FSetup.Game.Listener.GetAngle);
end;

end.
