{******************************************************************************}
{                                                                              }
{  DelphiDoom: a new ironman game of OpenXcom asks where to save as soon as    }
{  the geoscape is in front (GeoscapeState::init), on the game the program     }
{  composes, with the real data of TFTD                                        }
{                                                                              }
{  This program is free software; you can redistribute it and/or modify it     }
{  under the terms of the GNU General Public License, version 3 or later.      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomTour.Ironman;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Tests.Xcom.Skip, DelphiDoom.Tests.XcomTour.World;

type
  /// <summary>The tests do nothing when the data of the game is not there</summary>
  [TestFixture]
  [Category('xcom-tour')]
  TTestXcomTourIronman = class(TObject)
  strict private
    FWorld: TXcomTourWorld;
    /// <summary>
    ///   From the start of the program to the name of the first base of a new game, with or without the Ironman
    ///   button of the difficulty screen; False without the data of the game
    /// </summary>
    function NewGame(AIronman: Boolean): Boolean;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure UnaPartitaIronmanDovrebbeChiedereDoveSalvareDopoIlNomeDellaPrimaBase;
    [Test]
    procedure UnaPartitaIronmanDovrebbeChiedereDiNuovoSeSiAnnulla;
    [Test]
    procedure UnaPartitaIronmanSalvataNonDovrebbeChiederePiu;
    [Test]
    procedure UnaPartitaNormaleNonDovrebbeChiedereDoveSalvare;
  end;

implementation

const
  // the pixels of the 640 x 400 window: New Game of the main menu, the Ironman and OK buttons of the difficulty
  // screen, a point of the globe, the Cancel button of the list of the saved games, its first row
  NEW_GAME_X = 220;
  NEW_GAME_Y = 200;
  IRONMAN_X = 238;
  IRONMAN_Y = 296;
  OK_X = 238;
  OK_Y = 344;
  SITE_X = 250;
  SITE_Y = 200;
  CANCEL_X = 440;
  CANCEL_Y = 360;
  NEW_SLOT_X = 100;
  NEW_SLOT_Y = 92;
  // SDLK_RETURN
  KEY_RETURN = 13;
  SAVE_LIST = 'TXcomListSaveState';
  GEOSCAPE = 'TXcomGeoscapeState';

procedure TTestXcomTourIronman.Setup;
begin
  FWorld := TXcomTourWorld.Create;
end;

procedure TTestXcomTourIronman.TearDown;
begin
  FWorld.Free;
end;

function TTestXcomTourIronman.NewGame(AIronman: Boolean): Boolean;
begin
  Result := FWorld.HasData;
  if not Result then
    TXcomTestSkip.Ignore('the data of the game is not on this machine');
  // the start screen, then the main menu
  FWorld.Wait(5000);
  FWorld.Click(NEW_GAME_X, NEW_GAME_Y);
  if AIronman then
    FWorld.Click(IRONMAN_X, IRONMAN_Y);
  FWorld.Click(OK_X, OK_Y);
  FWorld.Wait(1000);
  FWorld.Click(SITE_X, SITE_Y);
  FWorld.TypeText('ab');
  FWorld.Key(KEY_RETURN);
  FWorld.Wait(500);
end;

procedure TTestXcomTourIronman.UnaPartitaIronmanDovrebbeChiedereDoveSalvareDopoIlNomeDellaPrimaBase;
begin
  if not NewGame(True) then
    Exit;
  Assert.IsTrue(FWorld.Save.Ironman, 'il pulsante Ironman della scelta della difficolta''');
  Assert.AreEqual('', FWorld.Save.Name, 'la partita non ha ancora un nome');
  Assert.AreEqual(SAVE_LIST, FWorld.Top, 'la lista dei salvataggi sopra il geoscape');
end;

procedure TTestXcomTourIronman.UnaPartitaIronmanDovrebbeChiedereDiNuovoSeSiAnnulla;
begin
  if not NewGame(True) then
    Exit;
  Assert.AreEqual(SAVE_LIST, FWorld.Top);
  FWorld.Click(CANCEL_X, CANCEL_Y);
  FWorld.Wait(500);
  // GeoscapeState::init runs again and the game still has no name
  Assert.AreEqual(SAVE_LIST, FWorld.Top, 'senza un nome la lista torna');
end;

procedure TTestXcomTourIronman.UnaPartitaIronmanSalvataNonDovrebbeChiederePiu;
begin
  if not NewGame(True) then
    Exit;
  Assert.AreEqual(SAVE_LIST, FWorld.Top);
  FWorld.Click(NEW_SLOT_X, NEW_SLOT_Y);
  FWorld.TypeText('iron');
  FWorld.Key(KEY_RETURN);
  FWorld.Wait(1500);
  Assert.AreEqual('iron', FWorld.Save.Name);
  Assert.AreEqual(GEOSCAPE, FWorld.Top, 'dopo il salvataggio resta il geoscape');
end;

procedure TTestXcomTourIronman.UnaPartitaNormaleNonDovrebbeChiedereDoveSalvare;
begin
  if not NewGame(False) then
    Exit;
  Assert.IsFalse(FWorld.Save.Ironman);
  Assert.AreEqual(GEOSCAPE, FWorld.Top);
end;

end.
