{******************************************************************************}
{                                                                              }
{  DelphiDoom: the custom initial base of OpenXcom (option customInitialBase:   }
{  the player places the lift and the facilities of the starting base) on the   }
{  game the program composes, with the real data of TFTD                        }
{                                                                              }
{  This program is free software; you can redistribute it and/or modify it     }
{  under the terms of the GNU General Public License, version 3 or later.      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomTour.CustomBase;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Tests.Xcom.Skip, DelphiDoom.XcomBasescape.SelectStartFacilityState,
  DelphiDoom.Tests.XcomTour.World;

type
  /// <summary>The tests do nothing when the data of the game is not there</summary>
  [TestFixture]
  [Category('xcom-tour')]
  TTestXcomTourCustomBase = class(TObject)
  strict private
    FWorld: TXcomTourWorld;
    /// <summary>A new game with the option on, up to the name of the base; False without the data of the game</summary>
    function NewGame: Boolean;
    procedure ClickSquare(AX, AY: Integer);
    function List: TXcomSelectStartFacilityState;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeChiedereLAscensoreDopoIlNomeDellaPrimaBase;
    [Test]
    procedure DovrebbeElencareLeStruttureDellaBaseInizialeDopoLAscensore;
    [Test]
    procedure DovrebbePosareUnaStrutturaSenzaCostoETogliereLaDallElenco;
    [Test]
    procedure DovrebbeRifiutareUnaStrutturaStaccataDalleAltre;
    [Test]
    procedure DovrebbeRicominciareDallAscensoreConReset;
    [Test]
    procedure SenzaLOpzioneLaPrimaBaseHaGiaLeSueStrutture;
  end;

implementation

const
  // the grid of the base: squares of 32 pixels from (0, 8), in the pixels of the window (twice the picture)
  SQUARE = 32;
  GRID_TOP = 8;
  LIFT_X = 2;
  LIFT_Y = 2;
  FIRST_ROW_X = 440;
  FIRST_ROW_Y = 138;
  RESET_X = 512;
  RESET_Y = 368;

procedure TTestXcomTourCustomBase.Setup;
begin
  FWorld := TXcomTourWorld.Create;
end;

procedure TTestXcomTourCustomBase.TearDown;
begin
  FWorld.Free;
end;

function TTestXcomTourCustomBase.NewGame: Boolean;
begin
  Result := FWorld.HasData;
  if not Result then
    TXcomTestSkip.Ignore('the data of the game is not on this machine');
  FWorld.Game.Options.SetBool('customInitialBase', True);
  FWorld.StartNewGame;
end;

procedure TTestXcomTourCustomBase.ClickSquare(AX, AY: Integer);
begin
  FWorld.Click((AX * SQUARE + SQUARE div 2) * 2, (GRID_TOP + AY * SQUARE + SQUARE div 2) * 2);
end;

function TTestXcomTourCustomBase.List: TXcomSelectStartFacilityState;
begin
  Assert.AreEqual('TXcomSelectStartFacilityState', FWorld.Top);
  Result := TXcomSelectStartFacilityState(FWorld.Game.TopState);
end;

procedure TTestXcomTourCustomBase.DovrebbeChiedereLAscensoreDopoIlNomeDellaPrimaBase;
begin
  if not NewGame then
    Exit;
  Assert.AreEqual('TXcomPlaceLiftState', FWorld.Top);
  Assert.AreEqual(0, FWorld.FirstBase.Facilities.Count, 'la base nasce senza strutture');
  Assert.IsTrue(FWorld.FirstBase.Soldiers.Count > 0, 'ma con i suoi soldati');
end;

procedure TTestXcomTourCustomBase.DovrebbeElencareLeStruttureDellaBaseInizialeDopoLAscensore;
begin
  if not NewGame then
    Exit;
  ClickSquare(LIFT_X, LIFT_Y);
  Assert.AreEqual(1, FWorld.FirstBase.Facilities.Count, 'l''ascensore');
  Assert.IsTrue(List.Remaining > 3, 'le strutture della base iniziale delle regole, senza l''ascensore');
  Assert.AreEqual(List.Remaining, List.List.GetRows);
end;

procedure TTestXcomTourCustomBase.DovrebbePosareUnaStrutturaSenzaCostoETogliereLaDallElenco;
var
  LBefore: Integer;
  LFunds: Int64;
begin
  if not NewGame then
    Exit;
  ClickSquare(LIFT_X, LIFT_Y);
  LBefore := List.Remaining;
  LFunds := FWorld.Save.Funds;
  FWorld.Click(FIRST_ROW_X, FIRST_ROW_Y);
  Assert.AreEqual('TXcomPlaceStartFacilityState', FWorld.Top);
  ClickSquare(LIFT_X + 1, LIFT_Y);
  Assert.AreEqual(LBefore - 1, List.Remaining);
  Assert.AreEqual(2, FWorld.FirstBase.Facilities.Count);
  Assert.AreEqual(0, FWorld.FirstBase.Facilities.Last.BuildTime, 'la struttura e'' gia'' costruita');
  Assert.AreEqual(LFunds, FWorld.Save.Funds, 'e non costa nulla');
end;

procedure TTestXcomTourCustomBase.DovrebbeRifiutareUnaStrutturaStaccataDalleAltre;
begin
  if not NewGame then
    Exit;
  ClickSquare(LIFT_X, LIFT_Y);
  FWorld.Click(FIRST_ROW_X, FIRST_ROW_Y);
  ClickSquare(0, 5);
  Assert.AreEqual('TXcomErrorMessageState', FWorld.Top);
  Assert.AreEqual(1, FWorld.FirstBase.Facilities.Count);
end;

procedure TTestXcomTourCustomBase.DovrebbeRicominciareDallAscensoreConReset;
begin
  if not NewGame then
    Exit;
  ClickSquare(LIFT_X, LIFT_Y);
  FWorld.Click(FIRST_ROW_X, FIRST_ROW_Y);
  ClickSquare(LIFT_X + 1, LIFT_Y);
  Assert.AreEqual(2, FWorld.FirstBase.Facilities.Count);
  FWorld.Click(RESET_X, RESET_Y);
  Assert.AreEqual('TXcomPlaceLiftState', FWorld.Top);
  Assert.AreEqual(0, FWorld.FirstBase.Facilities.Count);
  ClickSquare(4, 4);
  Assert.IsTrue(List.Remaining > 3, 'l''elenco e'' di nuovo intero');
end;

procedure TTestXcomTourCustomBase.SenzaLOpzioneLaPrimaBaseHaGiaLeSueStrutture;
begin
  if not FWorld.HasData then
    TXcomTestSkip.Ignore('the data of the game is not on this machine');
  FWorld.StartNewGame;
  Assert.AreEqual('TXcomGeoscapeState', FWorld.Top);
  Assert.IsTrue(FWorld.FirstBase.Facilities.Count > 3);
end;

end.
