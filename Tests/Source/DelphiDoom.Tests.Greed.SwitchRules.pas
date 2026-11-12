{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the switches on the walls of Greed and of the use key   }
{                                                                              }
{  TGreedSwitchRules on a level in memory with the stand-ins of the rest of     }
{  the game (TLibraryLevelRunner). The parity with the original raven.pas is    }
{  the golden test of DelphiDoom.Tests.Greed.LevelRules                         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Greed.SwitchRules;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Greed.Types, DelphiDoom.Greed.Actor.Types,
  DelphiDoom.Greed.World.Intf, DelphiDoom.Greed.Game.Constants, DelphiDoom.Greed.SwitchRules,
  DelphiDoom.Tests.Greed.LevelRunner;

type
  [TestFixture]
  [Category('greed')]
  TTestGreedSwitchRules = class(TObject)
  private
    FRunner: TLibraryLevelRunner;
    function Center(ATile: Integer): Integer;
    function Spot(ATileX, ATileY: Integer): Integer;
    procedure Use(ATileX, ATileY, AAngle: Integer);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeSollevareSeUnaDipendenzaManca;
    [Test]
    [TestCase('Est', '0,2,1')]
    [TestCase('QuasiNord', '127,2,1')]
    [TestCase('Nord', '256,0,0')]
    [TestCase('InizioNord', '128,0,0')]
    [TestCase('Ovest', '512,2,0')]
    [TestCase('Sud', '768,0,64')]
    [TestCase('FineSud', '895,0,64')]
    [TestCase('DiNuovoEst', '896,2,1')]
    procedure DovrebbeVedereLInterruttoreNelMuroDiFronte(AAngle, APlane, AOffset: Integer);
    [Test]
    procedure DovrebbeNonVedereUnMuroQualsiasi;
    [Test]
    procedure DovrebbeVedereLInterruttorePremutoSoloSeDoppio;
    [Test]
    procedure DovrebbeAspettareIlTempoDellInterruttore;
    [Test]
    [TestCase('Primo', '127,128')]
    [TestCase('Secondo', '172,173')]
    [TestCase('Terzo', '75,76')]
    [TestCase('Quarto', '140,141')]
    [TestCase('Quinto', '234,235')]
    procedure DovrebbeCambiareLaFiguraDelMuro(AFrom, ATo: Integer);
    [Test]
    procedure DovrebbeTornareIndietroSoloSeDoppio;
    [Test]
    procedure DovrebbeSuonareAncheSenzaInterruttore;
    [Test]
    procedure DovrebbeEseguireLEventoDellInterruttore;
    [Test]
    procedure DovrebbeSaltareLEventoSeIlMuroNonEUnInterruttore;
    [Test]
    procedure DovrebbeEseguireLEventoSenzaGuardareIlMuroSeNonSiUsa;
    [Test]
    procedure DovrebbeScambiareGliAscensori;
    [Test]
    procedure DovrebbeLasciareLAscensoreAMetaStrada;
    [Test]
    procedure DovrebbeAvviareLAscensoreSegretoVicino;
    [Test]
    procedure DovrebbeAprireLaPortaVicina;
    [Test]
    procedure DovrebbeNonFareNullaFuoriDallaMappa;
  end;

implementation

{ TTestGreedSwitchRules }

procedure TTestGreedSwitchRules.Setup;
begin
  FRunner := TLibraryLevelRunner.Create;
  FRunner.LoadEmpty;
end;

procedure TTestGreedSwitchRules.TearDown;
begin
  FRunner.Free;
end;

function TTestGreedSwitchRules.Center(ATile: Integer): Integer;
begin
  Result := ATile * GREED_FRACTILEUNIT + 32 * GREED_FRACUNIT;
end;

function TTestGreedSwitchRules.Spot(ATileX, ATileY: Integer): Integer;
begin
  Result := ATileY * GREED_MAP_SIZE + ATileX;
end;

procedure TTestGreedSwitchRules.Use(ATileX, ATileY, AAngle: Integer);
begin
  FRunner.Game.Calls.Clear;
  FRunner.Switches.CheckHere(True, Center(ATileX), Center(ATileY), AAngle);
end;

procedure TTestGreedSwitchRules.DovrebbeSollevareSeUnaDipendenzaManca;
begin
  Assert.WillRaise(
    procedure
    begin
      TGreedSwitchRules.Create(nil, FRunner.Game, FRunner.Game, FRunner.Game).Free;
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TGreedSwitchRules.Create(FRunner.State, nil, FRunner.Game, FRunner.Game).Free;
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TGreedSwitchRules.Create(FRunner.State, FRunner.Game, nil, FRunner.Game).Free;
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TGreedSwitchRules.Create(FRunner.State, FRunner.Game, FRunner.Game, nil).Free;
    end, EArgumentNilException);
end;

procedure TTestGreedSwitchRules.DovrebbeVedereLInterruttoreNelMuroDiFronte(AAngle, APlane, AOffset: Integer);
begin
  Assert.IsFalse(FRunner.Switches.CheckForSwitch(12, 10, AAngle, False));
  FRunner.World.SetValue(TGreedPlane(APlane), Spot(12, 10) + AOffset, 127);
  Assert.IsTrue(FRunner.Switches.CheckForSwitch(12, 10, AAngle, False));
  // not from the other three sides
  Assert.IsFalse(FRunner.Switches.CheckForSwitch(12, 10, (AAngle + 256) and GREED_ANGLES, False));
  Assert.IsFalse(FRunner.Switches.CheckForSwitch(12, 10, (AAngle + 512) and GREED_ANGLES, False));
  Assert.IsFalse(FRunner.Switches.CheckForSwitch(12, 10, (AAngle + 768) and GREED_ANGLES, False));
end;

procedure TTestGreedSwitchRules.DovrebbeNonVedereUnMuroQualsiasi;
begin
  FRunner.World.SetValue(gpNorthWall, Spot(12, 10), 126);
  Assert.IsFalse(FRunner.Switches.CheckForSwitch(12, 10, 256, True));
  FRunner.World.SetValue(gpNorthWall, Spot(12, 10), 129);
  Assert.IsFalse(FRunner.Switches.CheckForSwitch(12, 10, 256, True));
end;

procedure TTestGreedSwitchRules.DovrebbeVedereLInterruttorePremutoSoloSeDoppio;
begin
  FRunner.World.SetValue(gpNorthWall, Spot(12, 10), 173);
  Assert.IsFalse(FRunner.Switches.CheckForSwitch(12, 10, 256, False));
  Assert.IsTrue(FRunner.Switches.CheckForSwitch(12, 10, 256, True));
end;

procedure TTestGreedSwitchRules.DovrebbeAspettareIlTempoDellInterruttore;
begin
  FRunner.World.SetValue(gpNorthWall, Spot(12, 10), 127);
  FRunner.State.SwitchTime := FRunner.State.TimeCount + 1;
  Assert.IsFalse(FRunner.Switches.CheckForSwitch(12, 10, 256, True));
  FRunner.State.SwitchTime := FRunner.State.TimeCount;
  Assert.IsTrue(FRunner.Switches.CheckForSwitch(12, 10, 256, True));
end;

procedure TTestGreedSwitchRules.DovrebbeCambiareLaFiguraDelMuro(AFrom, ATo: Integer);
begin
  FRunner.World.SetValue(gpWestWall, Spot(12, 10), Byte(AFrom));
  FRunner.Game.Calls.Clear;
  FRunner.Switches.SwitchWall(12, 10, 512, False);
  Assert.AreEqual(ATo, Integer(FRunner.World.GetValue(gpWestWall, Spot(12, 10))));
  Assert.IsTrue(FRunner.Game.Has(Format('SoundEffect %d 0 %d %d',
    [GREED_SN_WALLSWITCH, 12 * GREED_FRACTILEUNIT, 10 * GREED_FRACTILEUNIT])));
  FRunner.Switches.SwitchWall(12, 10, 512, True);
  Assert.AreEqual(AFrom, Integer(FRunner.World.GetValue(gpWestWall, Spot(12, 10))), 'and back');
end;

procedure TTestGreedSwitchRules.DovrebbeTornareIndietroSoloSeDoppio;
begin
  FRunner.World.SetValue(gpNorthWall, Spot(12, 11), 141);
  FRunner.Switches.SwitchWall(12, 10, 768, False);
  Assert.AreEqual(141, Integer(FRunner.World.GetValue(gpNorthWall, Spot(12, 11))));
  FRunner.Switches.SwitchWall(12, 10, 768, True);
  Assert.AreEqual(140, Integer(FRunner.World.GetValue(gpNorthWall, Spot(12, 11))));
end;

procedure TTestGreedSwitchRules.DovrebbeSuonareAncheSenzaInterruttore;
begin
  FRunner.World.SetValue(gpWestWall, Spot(13, 10), 9);
  FRunner.Game.Calls.Clear;
  FRunner.Switches.SwitchWall(12, 10, 0, True);
  Assert.AreEqual(9, Integer(FRunner.World.GetValue(gpWestWall, Spot(13, 10))));
  Assert.AreEqual(1, FRunner.Game.CountOf('SoundEffect'));
end;

procedure TTestGreedSwitchRules.DovrebbeEseguireLEventoDellInterruttore;
begin
  // switches[x][y]
  FRunner.State.Switches[12 * GREED_MAP_SIZE + 10] := 6;
  FRunner.World.SetValue(gpNorthWall, Spot(12, 10), 127);
  Use(12, 10, 256);
  Assert.AreEqual(128, Integer(FRunner.World.GetValue(gpNorthWall, Spot(12, 10))));
  Assert.IsTrue(FRunner.Game.Has('RunEvent 6 0'));
end;

procedure TTestGreedSwitchRules.DovrebbeSaltareLEventoSeIlMuroNonEUnInterruttore;
begin
  FRunner.State.Switches[12 * GREED_MAP_SIZE + 10] := 6;
  FRunner.World.SetValue(gpNorthWall, Spot(12, 10), 127);
  // it looks at another wall
  Use(12, 10, 0);
  Assert.AreEqual(127, Integer(FRunner.World.GetValue(gpNorthWall, Spot(12, 10))));
  Assert.AreEqual(0, FRunner.Game.CountOf('RunEvent'));
  Assert.AreEqual(0, FRunner.Game.CountOf('SoundEffect'));
end;

procedure TTestGreedSwitchRules.DovrebbeEseguireLEventoSenzaGuardareIlMuroSeNonSiUsa;
begin
  FRunner.State.Switches[12 * GREED_MAP_SIZE + 10] := 8;
  FRunner.Game.Calls.Clear;
  FRunner.Switches.CheckHere(False, Center(12), Center(10), 0);
  Assert.IsTrue(FRunner.Game.Has('RunEvent 8 0'));
  Assert.AreEqual(1, FRunner.Game.CountOf('SoundEffect'), 'the sound of SwitchWall');
end;

procedure TTestGreedSwitchRules.DovrebbeScambiareGliAscensori;
var
  LHigh, LLow: Integer;
begin
  FRunner.World.SetValue(gpMapSprites, Spot(12, 10), GREED_SM_SWAPSWITCH);
  FRunner.World.SetValue(gpNorthWall, Spot(12, 10), 127);
  LHigh := FRunner.AddElevator(getSwap, 20, 20, 0, 64, 64);
  LLow := FRunner.AddElevator(getSwap, 22, 20, 0, 64, 0);
  Use(12, 10, 256);
  Assert.IsTrue(FRunner.State.Elevators.Item(LHigh)^.Down);
  Assert.IsTrue(FRunner.State.Elevators.Item(LLow)^.Up);
  Assert.AreEqual(FRunner.State.TimeCount, FRunner.State.Elevators.Item(LHigh)^.Timer);
  Assert.AreEqual(FRunner.State.TimeCount + 210, FRunner.State.SwitchTime, 'three seconds before the next use');
  // as the original: the wall is switched once for each elevator from the first that moves (here twice: it is
  // back as it was)
  Assert.AreEqual(2, FRunner.Game.CountOf(Format('SoundEffect %d', [GREED_SN_WALLSWITCH])));
  Assert.AreEqual(127, Integer(FRunner.World.GetValue(gpNorthWall, Spot(12, 10))));

  // until then the switch does nothing
  FRunner.State.Elevators.Item(LHigh)^.Down := False;
  Use(12, 10, 256);
  Assert.IsFalse(FRunner.State.Elevators.Item(LHigh)^.Down);
end;

procedure TTestGreedSwitchRules.DovrebbeLasciareLAscensoreAMetaStrada;
var
  LElevator: Integer;
begin
  FRunner.World.SetValue(gpMapSprites, Spot(12, 10), GREED_SM_SWAPSWITCH);
  FRunner.World.SetValue(gpNorthWall, Spot(12, 10), 127);
  LElevator := FRunner.AddElevator(getSwap, 20, 20, 0, 64, 30);
  Use(12, 10, 256);
  Assert.IsFalse(FRunner.State.Elevators.Item(LElevator)^.Down);
  Assert.IsFalse(FRunner.State.Elevators.Item(LElevator)^.Up);
  Assert.AreEqual(127, Integer(FRunner.World.GetValue(gpNorthWall, Spot(12, 10))));
  Assert.AreEqual(0, FRunner.State.SwitchTime);
end;

procedure TTestGreedSwitchRules.DovrebbeAvviareLAscensoreSegretoVicino;
var
  LNear, LFar, LOther: Integer;
begin
  FRunner.World.SetValue(gpMapSprites, Spot(12, 10), GREED_SM_STRIGGER);
  LNear := FRunner.AddElevator(getSecret, 13, 11, 0, 64, 64);
  LFar := FRunner.AddElevator(getSecret, 14, 10, 0, 64, 64);
  LOther := FRunner.AddElevator(getNormal, 12, 11, 0, 64, 64);
  // the event of the switch of the tile of the elevator runs too (CheckHere calls itself there)
  FRunner.State.Switches[13 * GREED_MAP_SIZE + 11] := 3;
  Use(12, 10, 0);
  Assert.IsTrue(FRunner.State.Elevators.Item(LNear)^.Down);
  Assert.AreEqual(FRunner.State.TimeCount, FRunner.State.Elevators.Item(LNear)^.Timer);
  Assert.IsFalse(FRunner.State.Elevators.Item(LFar)^.Down, 'two tiles away is too far');
  Assert.IsFalse(FRunner.State.Elevators.Item(LOther)^.Down, 'only the secret ones');
  Assert.IsTrue(FRunner.Game.Has('RunEvent 3 0'));
end;

procedure TTestGreedSwitchRules.DovrebbeAprireLaPortaVicina;
var
  LDoor: TGreedDoor;
  LIndex: Integer;
begin
  LIndex := FRunner.World.AddDoor(12, 10);
  LDoor := FRunner.World.GetDoor(LIndex);
  LDoor.Bumpable := True;
  LDoor.Orientation := gdoHorizontal;
  FRunner.World.SetDoor(LIndex, LDoor);
  Use(12, 10, 256);
  Assert.IsTrue(FRunner.World.GetDoor(LIndex).Opening);
  Assert.IsTrue(FRunner.State.DoorSound, 'the door will be heard at the next TimeUpdate');
  Assert.AreEqual(12 * GREED_FRACTILEUNIT, FRunner.State.DoorX);
  Assert.AreEqual(10 * GREED_FRACTILEUNIT, FRunner.State.DoorY);
end;

procedure TTestGreedSwitchRules.DovrebbeNonFareNullaFuoriDallaMappa;
begin
  FRunner.Game.Calls.Clear;
  Assert.IsFalse(FRunner.Switches.CheckForSwitch(63, 63, 768, True));
  Assert.IsFalse(FRunner.Switches.CheckForSwitch(-4, 90, 0, True));
  FRunner.Switches.SwitchWall(63, 63, 768, True);
  FRunner.Switches.CheckHere(True, -3 * GREED_FRACTILEUNIT, 70 * GREED_FRACTILEUNIT, 0);
  Assert.AreEqual(1, FRunner.Game.Calls.Count, 'only the sound of SwitchWall');
end;

end.
