{******************************************************************************}
{                                                                              }
{  DelphiDoom: the window of the dogfight of the geoscape of OpenXcom (modes,  }
{  icon, weapons, view of the UFO), on the game the program composes           }
{                                                                              }
{  This program is free software; you can redistribute it and/or modify it     }
{  under the terms of the GNU General Public License, version 3 or later.      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomTour.Dogfight;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Tests.Shared.Skip, DelphiDoom.XcomSave.Craft, DelphiDoom.Tests.XcomTour.World;

type
  /// <summary>
  ///   The saved game of Tests\Data\XcomSave\variants whose craft is over a UFO: the window of the dogfight opens
  ///   by itself in the middle of the globe. The tests are ignored when the data of the game is not there
  /// </summary>
  [TestFixture]
  [Category('xcom-tour')]
  TTestXcomTourDogfight = class(TObject)
  strict private
    FWorld: TXcomTourWorld;
    function Ready: Boolean;
    function Dogfights: Integer;
    function FightingCraft: TXcomCraft;
    /// <summary>The pixels of the place of the window of the dogfight that differ between two pictures</summary>
    function WindowDifference(const ALeft, ARight: TBytes): Integer;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeAprireLaFinestraDelCombattimento;
    [Test]
    procedure DovrebbeRidurreAIconaIlCombattimentoERiaprirlo;
    [Test]
    procedure DovrebbeChiudereIlCombattimentoColDisimpegno;
    [Test]
    procedure DovrebbeMostrareLUfoEDTornareAlCombattimento;
    [Test]
    procedure DovrebbeNonSparareConUnArmaSpenta;
  end;

implementation

uses
  DelphiDoom.XcomEngine.Types, DelphiDoom.XcomGeoscape.GeoscapeState;

const
  GEOSCAPE = 'TXcomGeoscapeState';
  /// <summary>The window of the only dogfight (160 x 96 at 80,52 of the 320 x 200 screen) in the pixels of the window</summary>
  WINDOW_LEFT = 160;
  WINDOW_TOP = 104;
  WINDOW_RIGHT = 480;
  WINDOW_BOTTOM = 296;
  STANDOFF_X = 362;
  CAUTIOUS_X = 436;
  MODE_TOP_Y = 126;
  MODE_BOTTOM_Y = 158;
  DISENGAGE_Y = 190;
  UFO_Y = 224;
  MINIMIZE_X = 172;
  MINIMIZE_Y = 116;
  ICON_X = 42;
  ICON_Y = 30;
  WEAPON_1_X = 182;
  WEAPON_2_X = 302;
  WEAPON_Y = 224;

procedure TTestXcomTourDogfight.Setup;
begin
  FWorld := TXcomTourWorld.Create;
end;

procedure TTestXcomTourDogfight.TearDown;
begin
  FWorld.Free;
end;

function TTestXcomTourDogfight.Ready: Boolean;
begin
  Result := FWorld.HasData and FWorld.LoadVariant('save02_dogfight');
  if not Result then
  begin
    TTestSkip.Ignore('i dati di TFTD o il salvataggio non ci sono');
    Exit;
  end;
  // the craft is over the UFO: the window opens by itself and grows to its size
  FWorld.Wait(4000);
end;

function TTestXcomTourDogfight.Dogfights: Integer;
begin
  Result := (FWorld.Game.TopState as TXcomGeoscapeState).DogfightCount;
end;

function TTestXcomTourDogfight.FightingCraft: TXcomCraft;
var
  LCraft: TXcomCraft;
begin
  for LCraft in FWorld.FirstBase.Crafts do
    if LCraft.InDogfight then
      Exit(LCraft);
  Assert.Fail('nessun velivolo e'' in combattimento');
  Result := nil;
end;

function TTestXcomTourDogfight.WindowDifference(const ALeft, ARight: TBytes): Integer;
var
  LX, LY: Integer;
begin
  Result := 0;
  for LY := WINDOW_TOP to WINDOW_BOTTOM - 1 do
    for LX := WINDOW_LEFT to WINDOW_RIGHT - 1 do
      if ALeft[LY * 640 + LX] <> ARight[LY * 640 + LX] then
        Inc(Result);
end;

procedure TTestXcomTourDogfight.DovrebbeAprireLaFinestraDelCombattimento;
begin
  if not Ready then
    Exit;
  Assert.AreEqual(GEOSCAPE, FWorld.Top, 'il combattimento e'' dentro il geoscape');
  Assert.AreEqual(1, Dogfights);
  Assert.AreEqual('STR_OUT', FightingCraft.Status);
end;

procedure TTestXcomTourDogfight.DovrebbeRidurreAIconaIlCombattimentoERiaprirlo;
var
  LOpen, LMinimized, LRestored: TBytes;
  LMinute: Integer;
begin
  if not Ready then
    Exit;
  // the window becomes an icon only when the craft stands off
  FWorld.Click(STANDOFF_X, MODE_TOP_Y);
  FWorld.Wait(3000);
  LOpen := FWorld.Picture;
  FWorld.Click(MINIMIZE_X, MINIMIZE_Y);
  LMinimized := FWorld.Picture;
  Assert.AreEqual(1, Dogfights, 'il combattimento continua');
  Assert.IsTrue(WindowDifference(LOpen, LMinimized) > 10000,
    Format('la finestra sparisce (%d pixel)', [WindowDifference(LOpen, LMinimized)]));
  // with every dogfight as an icon the time of the geoscape goes on
  LMinute := FWorld.Save.Time.Minute;
  FWorld.Click(608, 237);
  FWorld.Wait(3000);
  Assert.AreNotEqual(LMinute, FWorld.Save.Time.Minute, 'il tempo scorre col combattimento a icona');
  FWorld.Click(544, 237);
  FWorld.Click(ICON_X, ICON_Y);
  LRestored := FWorld.Picture;
  Assert.IsTrue(WindowDifference(LMinimized, LRestored) > 10000,
    Format('l''icona riapre la finestra (%d pixel)', [WindowDifference(LMinimized, LRestored)]));
end;

procedure TTestXcomTourDogfight.DovrebbeChiudereIlCombattimentoColDisimpegno;
var
  LCraft: TXcomCraft;
  LUfos: Integer;
begin
  if not Ready then
    Exit;
  LCraft := FightingCraft;
  LUfos := FWorld.Save.Ufos.Count;
  FWorld.Click(CAUTIOUS_X, DISENGAGE_Y);
  FWorld.Wait(8000);
  Assert.AreEqual(0, Dogfights, 'il disimpegno chiude la finestra');
  Assert.IsFalse(LCraft.InDogfight);
  Assert.AreEqual(LUfos, FWorld.Save.Ufos.Count, 'l''UFO resta dov''e''');
  Assert.IsFalse(LCraft.IsDestroyed);
end;

procedure TTestXcomTourDogfight.DovrebbeMostrareLUfoEDTornareAlCombattimento;
var
  LFight, LPreview, LBack: TBytes;
begin
  if not Ready then
    Exit;
  FWorld.Click(STANDOFF_X, MODE_TOP_Y);
  FWorld.Wait(1000);
  LFight := FWorld.Picture;
  FWorld.Click(CAUTIOUS_X, UFO_Y);
  LPreview := FWorld.Picture;
  Assert.IsTrue(WindowDifference(LFight, LPreview) > 5000,
    Format('la finestra mostra l''UFO (%d pixel)', [WindowDifference(LFight, LPreview)]));
  // a click on the picture goes back to the fight
  FWorld.Click(300, 200);
  LBack := FWorld.Picture;
  Assert.IsTrue(WindowDifference(LPreview, LBack) > 5000,
    Format('un clic torna al combattimento (%d pixel)', [WindowDifference(LPreview, LBack)]));
  Assert.AreEqual(1, Dogfights);
end;

procedure TTestXcomTourDogfight.DovrebbeNonSparareConUnArmaSpenta;
var
  LCraft: TXcomCraft;
  LFirst, LSecond: Integer;
begin
  if not Ready then
    Exit;
  LCraft := FightingCraft;
  Assert.IsNotNull(LCraft.Weapons[0]);
  Assert.IsNotNull(LCraft.Weapons[1]);
  LFirst := LCraft.Weapons[0].Ammo;
  LSecond := LCraft.Weapons[1].Ammo;
  // the first weapon off, then the attack
  FWorld.Click(WEAPON_1_X, WEAPON_Y);
  FWorld.Click(CAUTIOUS_X, MODE_BOTTOM_Y);
  FWorld.Wait(8000);
  Assert.AreEqual(LFirst, LCraft.Weapons[0].Ammo, 'l''arma spenta non spara');
  Assert.IsTrue(LCraft.Weapons[1].Ammo < LSecond, 'l''altra si''');
  // on again: it fires
  if Dogfights = 1 then
  begin
    FWorld.Click(WEAPON_1_X, WEAPON_Y);
    FWorld.Click(WEAPON_2_X, WEAPON_Y);
    LSecond := LCraft.Weapons[1].Ammo;
    FWorld.Wait(8000);
    Assert.IsTrue(LCraft.Weapons[0].Ammo < LFirst, 'riaccesa, la prima spara');
    Assert.AreEqual(LSecond, LCraft.Weapons[1].Ammo, 'e la seconda, spenta, no');
  end;
end;

end.
