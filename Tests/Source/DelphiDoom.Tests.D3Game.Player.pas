{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Doom 3 game library - the player (the state that    }
{  the rest of the library asks of idPlayer): spawn at the start, damage,       }
{  inventory                                                                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.D3Game.Player;

interface

uses
  DUnitX.TestFramework, DelphiDoom.Tests.D3Game.WorldRig;

type
  [TestFixture]
  [Category('D3Game')]
  TTestD3GamePlayer = class
  strict private
    FRig: TD3WorldRig;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure IlGiocatoreDovrebbeNascereNelPrimoInfoPlayerStart;
    [Test]
    procedure SenzaUnPuntoDiPartenzaDovrebbeDareErrore;
    [Test]
    procedure UnaClasseCheNonEUnGiocatoreDovrebbeDareErrore;
    [Test]
    procedure IlGiocatoreLocaleDovrebbeEssereLEntitaZero;
    [Test]
    procedure IlGiocatoreDovrebbePerdereSaluteConIlDanno;
    [Test]
    procedure UnOggettoDiInventarioDovrebbeSoddisfareIlRequisito;
    [Test]
    procedure UnOggettoConRemoveItemDovrebbeUscireDallInventario;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.D3Game.Entity, DelphiDoom.D3Game.Player, DelphiDoom.D3Game.Types;

procedure TTestD3GamePlayer.Setup;
begin
  FRig := TD3WorldRig.Create;
  FRig.World.AddDef('player_doommarine', ['spawnclass', 'idPlayer', 'health', '100']);
  FRig.World.AddDef('info_player_start', ['spawnclass', 'idRecorder']);
  FRig.World.AddDef('damage_hit', ['damage', '30']);
end;

procedure TTestD3GamePlayer.TearDown;
begin
  FRig.Free;
end;

procedure TTestD3GamePlayer.IlGiocatoreDovrebbeNascereNelPrimoInfoPlayerStart;
var
  LPlayer: TD3Entity;
begin
  FRig.Spawn(['classname', 'info_player_start', 'name', 'start1', 'origin', '10 20 30', 'angle', '90']);
  LPlayer := FRig.Game.SpawnPlayer(0);
  Assert.IsTrue(Assigned(LPlayer));
  Assert.AreEqual(0, LPlayer.EntityNumber);
  Assert.AreEqual('player1', string(LPlayer.GetName));
  Assert.AreEqual(100, LPlayer.Health);
  Assert.IsTrue(LPlayer.IsPlayer);
  // 4 + CM_BOX_EPSILON above the start
  Assert.AreEqual(10.0, Double(LPlayer.GetPhysics.GetOrigin.X), 0.0001);
  Assert.AreEqual(20.0, Double(LPlayer.GetPhysics.GetOrigin.Y), 0.0001);
  Assert.AreEqual(35.0, Double(LPlayer.GetPhysics.GetOrigin.Z), 0.0001);
  // the view looks along the angle of the start
  Assert.AreEqual(90.0, Double(TD3Player(LPlayer).ViewAngles.Yaw), 0.001);
end;

procedure TTestD3GamePlayer.SenzaUnPuntoDiPartenzaDovrebbeDareErrore;
begin
  Assert.WillRaise(
    procedure
    begin
      FRig.Game.SpawnPlayer(0);
    end, ED3GameException);
end;

procedure TTestD3GamePlayer.UnaClasseCheNonEUnGiocatoreDovrebbeDareErrore;
begin
  // a game whose player class is not a player
  FRig.Free;
  FRig := TD3WorldRig.Create;
  FRig.World.AddDef('player_doommarine', ['spawnclass', 'idRecorder']);
  FRig.World.AddDef('info_player_start', ['spawnclass', 'idRecorder']);
  FRig.Spawn(['classname', 'info_player_start', 'name', 'start1']);
  Assert.WillRaise(
    procedure
    begin
      FRig.Game.SpawnPlayer(0);
    end, ED3GameException);
end;

procedure TTestD3GamePlayer.IlGiocatoreLocaleDovrebbeEssereLEntitaZero;
var
  LPlayer: TD3Entity;
begin
  Assert.IsTrue(FRig.Game.GetLocalPlayer = nil);
  FRig.Spawn(['classname', 'info_player_start', 'name', 'start1']);
  LPlayer := FRig.Game.SpawnPlayer(0);
  Assert.IsTrue(FRig.Game.GetLocalPlayer = LPlayer);
end;

procedure TTestD3GamePlayer.IlGiocatoreDovrebbePerdereSaluteConIlDanno;
var
  LPlayer: TD3Entity;
begin
  FRig.Spawn(['classname', 'info_player_start', 'name', 'start1']);
  LPlayer := FRig.Game.SpawnPlayer(0);
  LPlayer.Damage('damage_hit', 1.0);
  Assert.AreEqual(70, LPlayer.Health);
end;

procedure TTestD3GamePlayer.UnOggettoDiInventarioDovrebbeSoddisfareIlRequisito;
var
  LPlayer: TD3Entity;
  LOther: TD3Entity;
begin
  FRig.Spawn(['classname', 'info_player_start', 'name', 'start1']);
  LPlayer := FRig.Game.SpawnPlayer(0);
  LOther := FRig.Spawn(['classname', 'info_player_start', 'name', 'other']);
  Assert.IsFalse(LPlayer.RequirementMet(LPlayer, 'key1', 0), 'no item');
  TD3Player(LPlayer).GiveInventoryItem('Key1');
  Assert.IsTrue(LPlayer.RequirementMet(LPlayer, 'key1', 0), 'the names ignore the case');
  Assert.IsTrue(LPlayer.RequirementMet(LPlayer, '', 0), 'no requirement');
  Assert.IsTrue(LPlayer.RequirementMet(LOther, 'key1', 0), 'only a player is asked for the item');
end;

procedure TTestD3GamePlayer.UnOggettoConRemoveItemDovrebbeUscireDallInventario;
var
  LPlayer: TD3Entity;
begin
  FRig.Spawn(['classname', 'info_player_start', 'name', 'start1']);
  LPlayer := FRig.Game.SpawnPlayer(0);
  TD3Player(LPlayer).GiveInventoryItem('key1');
  Assert.IsTrue(LPlayer.RequirementMet(LPlayer, 'key1', 1));
  Assert.IsFalse(LPlayer.FindInventoryItem('key1'));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestD3GamePlayer);

end.
