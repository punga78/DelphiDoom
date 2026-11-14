{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of TGreedLightOverflow and of the switch of the game  }
{  for the defect of the original with the light written outside the map        }
{  (TGreedGame.OriginalLightOverflow): one test for each behavior               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Greed.LightOverflow;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Greed.Types, DelphiDoom.Greed.Actor.Types,
  DelphiDoom.Greed.World.Intf, DelphiDoom.Greed.SpriteLogic.Intf, DelphiDoom.Greed.GameRenderer.Intf,
  DelphiDoom.Greed.LightOverflow, DelphiDoom.Greed.Game, DelphiDoom.Tests.Greed.GameFakes;

type
  /// <summary>Remembers the last write after the tile lights</summary>
  TFakeRenderMemory = class(TInterfacedObject, IGreedRenderMemory)
  public
    Calls: Integer;
    LastOffset: Integer;
    LastAmount: Integer;
    procedure SubtractAfterTileLights(AOffset, AAmount: Integer);
  end;

  [TestFixture]
  [Category('greed')]
  TTestGreedLightOverflow = class(TObject)
  strict private
    FSetup: TFakeGameSetup;
    FMemory: TFakeRenderMemory;
    FMemoryIntf: IGreedRenderMemory;
    FOverflow: IGreedLightOverflow;
    procedure Start;
    /// a sprite hotter than 256 that does not move, on the tile (ATileX, ATileY)
    procedure PutHotSprite(ATileX, ATileY: Integer);
    /// the player shoots once and the shot is left to end
    procedure FireOnce;
    function SoundsOfTurns(ATurns: Integer): Integer;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeRifiutareMondoEControlloNil;
    [Test]
    procedure PrimaDellaMappaDovrebbeCambiareQuattroByteDiMapflags;
    [Test]
    procedure TroppoPrimaDellaMappaNonDovrebbeScrivere;
    [Test]
    procedure SubitoDopoLaMappaDovrebbeFarPartireIlColpoSoloSeIlGiocatoreHaGiaSparato;
    [Test]
    procedure DopoActionflagDovrebbeScrivereNelleVariabiliDelRenderer;
    [Test]
    procedure SenzaLeVariabiliDelRendererNonDovrebbeFareNulla;
    [Test]
    procedure DiNormaLaLuceFuoriDallaMappaDovrebbeEsserePersa;
    [Test]
    procedure ConIlDifettoDellOriginaleLArmaDovrebbeSparareDaSola;
    [Test]
    procedure ConIlDifettoUnoSpriteSullaPrimaRigaDovrebbeCambiareMapflags;
    [Test]
    procedure LInterruttoreDovrebbeAccendersiESpegnersi;
  end;

implementation

uses
  DelphiDoom.Greed.PlayerControl.Intf;

const
  HOT = 600;

{ TFakeRenderMemory }

procedure TFakeRenderMemory.SubtractAfterTileLights(AOffset, AAmount: Integer);
begin
  Inc(Calls);
  LastOffset := AOffset;
  LastAmount := AAmount;
end;

{ TTestGreedLightOverflow }

procedure TTestGreedLightOverflow.Setup;
begin
  FSetup := TFakeGameSetup.Create;
  FMemory := TFakeRenderMemory.Create;
  FMemoryIntf := FMemory;
end;

procedure TTestGreedLightOverflow.TearDown;
begin
  FOverflow := nil;
  FMemoryIntf := nil;
  FreeAndNil(FSetup);
end;

procedure TTestGreedLightOverflow.Start;
begin
  FSetup.CreateGame;
  FSetup.Game.NewGame(0, 0, 2);
  FOverflow := TGreedLightOverflow.Create(FSetup.Game.World, FSetup.Game.Parts.Control, FMemoryIntf);
end;

procedure TTestGreedLightOverflow.PutHotSprite(ATileX, ATileY: Integer);
var
  LIndex: Integer;
  LSprite: PGreedSprite;
begin
  LIndex := FSetup.Game.State.Sprites.Add;
  LSprite := PGreedSprite(FSetup.Game.State.Sprites.Item(LIndex));
  LSprite^.X := ATileX * GREED_FRACTILEUNIT + 32 * GREED_FRACUNIT;
  LSprite^.Y := ATileY * GREED_FRACTILEUNIT + 32 * GREED_FRACUNIT;
  LSprite^.Active := True;
  LSprite^.MoveSpeed := 0;
  LSprite^.Heat := HOT;
end;

procedure TTestGreedLightOverflow.FireOnce;
begin
  FSetup.Commands.Pressed := [gcFire];
  FSetup.Play(3);
  FSetup.Commands.Pressed := [];
  Assert.IsTrue(FSetup.Game.Parts.Control.ActionHookSet, 'the player has not fired');
  FSetup.Play(120);
end;

function TTestGreedLightOverflow.SoundsOfTurns(ATurns: Integer): Integer;
var
  LBefore: Integer;
begin
  LBefore := FSetup.Sound.Sounds.Count;
  FSetup.Play(ATurns);
  Result := FSetup.Sound.Sounds.Count - LBefore;
end;

procedure TTestGreedLightOverflow.DovrebbeRifiutareMondoEControlloNil;
begin
  Start;
  Assert.WillRaise(
    procedure
    begin
      TGreedLightOverflow.Create(nil, FSetup.Game.Parts.Control, FMemoryIntf);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TGreedLightOverflow.Create(FSetup.Game.World, nil, FMemoryIntf);
    end, EArgumentNilException);
end;

procedure TTestGreedLightOverflow.PrimaDellaMappaDovrebbeCambiareQuattroByteDiMapflags;
var
  LWorld: IGreedWorld;
begin
  Start;
  LWorld := FSetup.Game.World;
  // reallight[-2] is the integer of the bytes 4088..4091 of mapflags: 0x00000100 - 0x12C = 0xFFFFFFD4
  LWorld.SetMapFlags(GREED_MAP_TILES - 8, 0);
  LWorld.SetMapFlags(GREED_MAP_TILES - 7, 1);
  LWorld.SetMapFlags(GREED_MAP_TILES - 6, 0);
  LWorld.SetMapFlags(GREED_MAP_TILES - 5, 0);
  LWorld.SetMapFlags(GREED_MAP_TILES - 4, 77);
  FOverflow.LightOutsideTheMap(-2, 300);
  Assert.AreEqual($D4, Integer(LWorld.GetMapFlags(GREED_MAP_TILES - 8)));
  Assert.AreEqual($FF, Integer(LWorld.GetMapFlags(GREED_MAP_TILES - 7)));
  Assert.AreEqual($FF, Integer(LWorld.GetMapFlags(GREED_MAP_TILES - 6)));
  Assert.AreEqual($FF, Integer(LWorld.GetMapFlags(GREED_MAP_TILES - 5)));
  Assert.AreEqual(77, Integer(LWorld.GetMapFlags(GREED_MAP_TILES - 4)), 'the integer after is not touched');
  Assert.AreEqual(0, FMemory.Calls);
end;

procedure TTestGreedLightOverflow.TroppoPrimaDellaMappaNonDovrebbeScrivere;
begin
  Start;
  // 1025 integers before reallight is before mapflags too
  FOverflow.LightOutsideTheMap(-1025, 300);
  Assert.AreEqual(0, Integer(FSetup.Game.World.GetMapFlags(0)));
  Assert.AreEqual(0, FMemory.Calls);
end;

procedure TTestGreedLightOverflow.SubitoDopoLaMappaDovrebbeFarPartireIlColpoSoloSeIlGiocatoreHaGiaSparato;
begin
  Start;
  // actionhook is nil until the first shot: the original stops there, here nothing happens
  FOverflow.LightOutsideTheMap(GREED_MAP_TILES, 300);
  Assert.IsFalse(FSetup.Game.Parts.Control.FirePending);
  FireOnce;
  Assert.IsFalse(FSetup.Game.Parts.Control.FirePending);
  FOverflow.LightOutsideTheMap(GREED_MAP_TILES, 300);
  Assert.IsTrue(FSetup.Game.Parts.Control.FirePending, 'actionflag is not 0: the hook runs at the next view');
  Assert.AreEqual(0, FMemory.Calls);
end;

procedure TTestGreedLightOverflow.DopoActionflagDovrebbeScrivereNelleVariabiliDelRenderer;
begin
  Start;
  FOverflow.LightOutsideTheMap(GREED_MAP_TILES + 11, 250);
  Assert.AreEqual(1, FMemory.Calls);
  Assert.AreEqual(11, FMemory.LastOffset, 'frameon is 11 integers after actionflag');
  Assert.AreEqual(250, FMemory.LastAmount);
  Assert.IsFalse(FSetup.Game.Parts.Control.FirePending);
end;

procedure TTestGreedLightOverflow.SenzaLeVariabiliDelRendererNonDovrebbeFareNulla;
var
  LOverflow: IGreedLightOverflow;
begin
  Start;
  LOverflow := TGreedLightOverflow.Create(FSetup.Game.World, FSetup.Game.Parts.Control, nil);
  LOverflow.LightOutsideTheMap(GREED_MAP_TILES + 3, 250);
  Assert.AreEqual(0, FMemory.Calls);
end;

procedure TTestGreedLightOverflow.DiNormaLaLuceFuoriDallaMappaDovrebbeEsserePersa;
begin
  Start;
  Assert.IsFalse(FSetup.Game.OriginalLightOverflow, 'the defect is off by default');
  FireOnce;
  // a very hot sprite on the last row, first column: one of its nine tiles is reallight[4096]
  PutHotSprite(0, GREED_MAP_SIZE - 1);
  Assert.AreEqual(0, SoundsOfTurns(40), 'nobody shoots');
  Assert.IsFalse(FSetup.Game.Parts.Control.FirePending);
end;

procedure TTestGreedLightOverflow.ConIlDifettoDellOriginaleLArmaDovrebbeSparareDaSola;
begin
  Start;
  FSetup.Game.OriginalLightOverflow := True;
  FireOnce;
  Assert.AreEqual(0, SoundsOfTurns(40), 'without the hot sprite nobody shoots');
  PutHotSprite(0, GREED_MAP_SIZE - 1);
  Assert.IsTrue(SoundsOfTurns(40) > 0, 'the weapon of the player fires without the command');
end;

procedure TTestGreedLightOverflow.ConIlDifettoUnoSpriteSullaPrimaRigaDovrebbeCambiareMapflags;
var
  LIndex, LChanged: Integer;
begin
  Start;
  FSetup.Game.OriginalLightOverflow := True;
  PutHotSprite(5, 0);
  FSetup.Play(10);
  // the tiles 4..6 of the row before the first are reallight[-60 .. -58]: mapflags[3856 .. 3867]
  LChanged := 0;
  for LIndex := GREED_MAP_TILES - 60 * 4 to GREED_MAP_TILES - 57 * 4 - 1 do
    if FSetup.Game.World.GetMapFlags(LIndex) <> 0 then
      Inc(LChanged);
  Assert.IsTrue(LChanged > 0, 'the flags of the last rows of the map are written over');
end;

procedure TTestGreedLightOverflow.LInterruttoreDovrebbeAccendersiESpegnersi;
begin
  Start;
  FSetup.Game.OriginalLightOverflow := True;
  Assert.IsTrue(FSetup.Game.OriginalLightOverflow);
  FSetup.Game.OriginalLightOverflow := False;
  Assert.IsFalse(FSetup.Game.OriginalLightOverflow);
  PutHotSprite(5, 0);
  FSetup.Play(10);
  Assert.AreEqual(0, Integer(FSetup.Game.World.GetMapFlags(GREED_MAP_TILES - 59 * 4)));
end;

end.
