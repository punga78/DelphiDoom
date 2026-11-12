{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the greed library - the state of the game          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Greed.GameState;

interface

uses
  DUnitX.TestFramework, DelphiDoom.Greed.Actor.Types, DelphiDoom.Greed.LinkedPool, DelphiDoom.Greed.World.Intf,
  DelphiDoom.Greed.Game.State;

type
  [TestFixture]
  [Category('greed')]
  TTestGreedGameState = class
  strict private
    FWorld: IGreedWorld;
    FSprites: TGreedLinkedPool<TGreedSprite>;
    FElevators: TGreedLinkedPool<TGreedElevator>;
    FState: TGreedGameState;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbePartireConIValoriInizialiDellOriginale;
    [Test]
    procedure DovrebbeCopiareLaTabellaDelleArmi;
    [Test]
    procedure DovrebbeRipristinareLaCaricaDelleArmi;
    [Test]
    procedure DovrebbeRifiutareUnMondoNil;
    [Test]
    procedure DovrebbeRifiutareUnPoolNil;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Greed.World, DelphiDoom.Greed.Game.Tables;

procedure TTestGreedGameState.Setup;
begin
  FWorld := TGreedWorld.Create;
  FSprites := TGreedLinkedPool<TGreedSprite>.Create(8, 'sprites');
  FElevators := TGreedLinkedPool<TGreedElevator>.Create(4, 'elevators');
  FState := TGreedGameState.Create(FWorld, FSprites, FElevators);
end;

procedure TTestGreedGameState.TearDown;
begin
  FState.Free;
  FElevators.Free;
  FSprites.Free;
  FWorld := nil;
end;

procedure TTestGreedGameState.DovrebbePartireConIValoriInizialiDellOriginale;
begin
  Assert.IsTrue(FState.AutoTarget);
  Assert.IsTrue(FState.HeadBobOn);
  Assert.IsTrue(FState.WeapBobOn);
  Assert.AreEqual(8, FState.PlayerTurnSpeed);
  Assert.AreEqual(2, FState.TurnUnit);
  Assert.IsTrue(FState.Game1);
  Assert.IsFalse(FState.NetMode);
  Assert.AreEqual(1, FState.NumPlayers);
  Assert.AreEqual(GREED_POOL_NIL, FState.MSprite);
  Assert.AreEqual(GREED_POOL_NIL, FState.BonusItem.Sprite);
  Assert.AreEqual(0, FState.TimeCount);
  Assert.IsTrue(FState.World = FWorld);
  Assert.IsTrue(FState.Sprites = FSprites);
  Assert.IsTrue(FState.Elevators = FElevators);
end;

procedure TTestGreedGameState.DovrebbeCopiareLaTabellaDelleArmi;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 18 do
  begin
    Assert.AreEqual(TGreedGameTables.Weapons[LIndex].ChargeRate, FState.Weapons[LIndex].ChargeRate);
    Assert.AreEqual(TGreedGameTables.Weapons[LIndex].AmmoRate, FState.Weapons[LIndex].AmmoRate);
  end;
end;

procedure TTestGreedGameState.DovrebbeRipristinareLaCaricaDelleArmi;
begin
  FState.Weapons[3].Charge := 77;
  FState.ResetWeapons;
  Assert.AreEqual(0, FState.Weapons[3].Charge);
end;

procedure TTestGreedGameState.DovrebbeRifiutareUnMondoNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TGreedGameState.Create(nil, FSprites, FElevators).Free;
    end, EArgumentNilException);
end;

procedure TTestGreedGameState.DovrebbeRifiutareUnPoolNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TGreedGameState.Create(FWorld, nil, FElevators).Free;
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TGreedGameState.Create(FWorld, FSprites, nil).Free;
    end, EArgumentNilException);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestGreedGameState);

end.
