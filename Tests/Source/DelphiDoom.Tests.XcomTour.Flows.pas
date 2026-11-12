{******************************************************************************}
{                                                                              }
{  DelphiDoom: the longer flows of the strategic game of OpenXcom (crafts      }
{  sent over the globe, dogfight, transfers between bases, events of the       }
{  month), on the game the program composes                                    }
{                                                                              }
{  This program is free software; you can redistribute it and/or modify it     }
{  under the terms of the GNU General Public License, version 3 or later.      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomTour.Flows;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Tests.Shared.Skip, DelphiDoom.Tests.XcomTour.World;

type
  /// <summary>
  ///   Flows of several screens, some from the saved games of Tests\Data\XcomSave\variants; the tests do nothing when
  ///   the data of the game is not there
  /// </summary>
  [TestFixture]
  [Category('xcom-tour')]
  TTestXcomTourFlows = class(TObject)
  strict private
    FWorld: TXcomTourWorld;
    function NewGame: Boolean;
    function Variant(const AName: string): Boolean;
    /// <summary>Lets the days pass until the state on top is of the class (closing the other popups with Esc)</summary>
    function RunUntil(const AClass: string; ASpeedY, ATurns: Integer): Boolean;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeMandareUnVelivoloAUnPuntoDelGlobo;
    [Test]
    procedure DovrebbeDisegnareLaRottaDiUnVelivoloInVolo;
    [Test]
    procedure DovrebbeSmantellareUnaStruttura;
    [Test]
    procedure DovrebbeRicevereGliAcquistiDopoTreGiorni;
    [Test]
    procedure DovrebbeCompletareUnaRicerca;
    [Test]
    procedure DovrebbeAccendereLeSerieDeiGrafici;
    [Test]
    procedure DovrebbeRuotareEIngrandireIlGlobo;
    [Test]
    procedure DovrebbeTrasferireTraDueBasi;
    [Test]
    procedure DovrebbeCombattereUnUfoNelDogfight;
    [Test]
    procedure DovrebbeMostrareIlDiarioDiUnSoldato;
    [Test]
    procedure DovrebbeMostrareIMortiNelMemoriale;
  end;

implementation

uses
  DelphiDoom.XcomEngine.Types;

const
  GEOSCAPE = 'TXcomGeoscapeState';
  BASESCAPE = 'TXcomBasescapeState';
  SPEED_30_MINUTES_Y = 265;
  SPEED_1_HOUR_Y = 293;

procedure TTestXcomTourFlows.Setup;
begin
  FWorld := TXcomTourWorld.Create;
end;

procedure TTestXcomTourFlows.TearDown;
begin
  FWorld.Free;
end;

function TTestXcomTourFlows.NewGame: Boolean;
begin
  Result := FWorld.HasData;
  if Result then
    FWorld.StartNewGame
  else
    TTestSkip.Ignore('i dati di TFTD non ci sono');
end;

function TTestXcomTourFlows.Variant(const AName: string): Boolean;
begin
  Result := FWorld.HasData and FWorld.LoadVariant(AName);
  if not Result then
    TTestSkip.Ignore('i dati di TFTD o il salvataggio non ci sono');
end;

function TTestXcomTourFlows.RunUntil(const AClass: string; ASpeedY, ATurns: Integer): Boolean;
var
  LTurn: Integer;
begin
  for LTurn := 1 to ATurns do
  begin
    // the button of the speed is in the right column for 1 Min, 30 Mins and 1 Day
    FWorld.Click(608, ASpeedY);
    FWorld.Wait(1500);
    if FWorld.Top = AClass then
      Exit(True);
    if FWorld.Top <> GEOSCAPE then
      FWorld.Key(XCOM_KEY_ESCAPE);
  end;
  Result := False;
end;

procedure TTestXcomTourFlows.DovrebbeMandareUnVelivoloAUnPuntoDelGlobo;
begin
  if not NewGame then
    Exit;
  FWorld.Click(TOUR_GEO_BUTTON_X, TOUR_INTERCEPT_Y);
  // the second craft of the list
  FWorld.Click(100, 180);
  Assert.AreEqual('TXcomSelectDestinationState', FWorld.Top);
  FWorld.Click(300, 150);
  Assert.AreEqual('TXcomConfirmDestinationState', FWorld.Top);
  FWorld.Key(XCOM_KEY_RETURN);
  Assert.AreEqual(GEOSCAPE, FWorld.Top);
  Assert.IsTrue(RunUntil('TXcomCraftPatrolState', SPEED_30_MINUTES_Y, 40), 'il velivolo arriva al punto');
  FWorld.Key(XCOM_KEY_ESCAPE);
  Assert.AreEqual(GEOSCAPE, FWorld.Top);
end;

procedure TTestXcomTourFlows.DovrebbeDisegnareLaRottaDiUnVelivoloInVolo;
var
  LWith, LWithout: TBytes;
  LIndex, LDifferent: Integer;
begin
  if not NewGame then
    Exit;
  FWorld.Click(TOUR_GEO_BUTTON_X, TOUR_INTERCEPT_Y);
  FWorld.Click(100, 180);
  FWorld.Click(300, 150);
  FWorld.Key(XCOM_KEY_RETURN);
  // the craft leaves the base: its path goes to the point that was chosen
  FWorld.Wait(1000);
  LWith := FWorld.Picture;
  FWorld.Globe.FlightPaths := False;
  FWorld.Globe.Redraw := True;
  FWorld.Wait(40);
  LWithout := FWorld.Picture;
  LDifferent := 0;
  // the globe is the left part of the 640 x 400 window (the clock at its right goes on)
  for LIndex := 0 to High(LWith) do
    if (LWith[LIndex] <> LWithout[LIndex]) and (LIndex mod 640 < 512) then
      Inc(LDifferent);
  Assert.IsTrue(LDifferent > 20, Format('la rotta e'' disegnata (%d pixel)', [LDifferent]));
  Assert.IsTrue(LDifferent < 2000, Format('solo la rotta cambia (%d pixel)', [LDifferent]));
end;

procedure TTestXcomTourFlows.DovrebbeSmantellareUnaStruttura;
var
  LFacilities: Integer;
begin
  if not NewGame then
    Exit;
  FWorld.Click(TOUR_GEO_BUTTON_X, TOUR_BASES_Y);
  LFacilities := FWorld.FirstBase.Facilities.Count;
  // the square at the end of the row of the base
  FWorld.Click(288, 240);
  Assert.AreEqual('TXcomDismantleFacilityState', FWorld.Top);
  FWorld.Key(XCOM_KEY_RETURN);
  Assert.AreEqual(LFacilities - 1, FWorld.FirstBase.Facilities.Count);
  Assert.AreEqual(BASESCAPE, FWorld.Top);
end;

procedure TTestXcomTourFlows.DovrebbeRicevereGliAcquistiDopoTreGiorni;
begin
  if not NewGame then
    Exit;
  FWorld.Click(TOUR_GEO_BUTTON_X, TOUR_BASES_Y);
  FWorld.Click(TOUR_BASE_BUTTON_X, TOUR_PURCHASE_Y);
  FWorld.Click(480, 132);
  FWorld.Click(160, 368);
  FWorld.Click(TOUR_BASE_BUTTON_X, 388);
  Assert.IsTrue(RunUntil('TXcomItemsArrivingState', SPEED_1_HOUR_Y, 40), 'gli scienziati arrivano');
  Assert.AreEqual(0, FWorld.FirstBase.Transfers.Count);
  FWorld.Key(XCOM_KEY_ESCAPE);
  Assert.AreEqual(GEOSCAPE, FWorld.Top);
end;

procedure TTestXcomTourFlows.DovrebbeCompletareUnaRicerca;
var
  LClick: Integer;
begin
  if not NewGame then
    Exit;
  FWorld.Click(TOUR_GEO_BUTTON_X, TOUR_BASES_Y);
  FWorld.Click(TOUR_BASE_BUTTON_X, TOUR_RESEARCH_Y);
  FWorld.Click(160, 368);
  FWorld.Click(300, 140);
  for LClick := 1 to 10 do
    FWorld.Click(402, 213);
  FWorld.Click(428, 306);
  Assert.AreEqual(0, FWorld.FirstBase.Scientists, 'tutti gli scienziati sul progetto');
  FWorld.Key(XCOM_KEY_ESCAPE);
  FWorld.Key(XCOM_KEY_ESCAPE);
  FWorld.Click(TOUR_BASE_BUTTON_X, 388);
  Assert.AreEqual(GEOSCAPE, FWorld.Top);
  Assert.IsTrue(RunUntil('TXcomResearchCompleteState', SPEED_1_HOUR_Y, 60), 'la ricerca finisce');
  Assert.AreEqual(0, FWorld.FirstBase.Research.Count);
  Assert.AreEqual(10, FWorld.FirstBase.Scientists);
end;

procedure TTestXcomTourFlows.DovrebbeAccendereLeSerieDeiGrafici;
var
  LRow: Integer;
  LColumn: Integer;
begin
  if not NewGame then
    Exit;
  FWorld.Click(TOUR_GEO_BUTTON_X, TOUR_GRAPHS_Y);
  // the six kinds of graph, and the series of each
  for LColumn := 0 to 5 do
  begin
    FWorld.Click(224 + LColumn * 64, 24);
    for LRow := 0 to 3 do
      FWorld.Click(40, 14 + LRow * 22);
  end;
  Assert.AreEqual('TXcomGraphsState', FWorld.Top);
  FWorld.Click(608, 24);
  Assert.AreEqual(GEOSCAPE, FWorld.Top, 'il pulsante del geoscape chiude i grafici');
end;

procedure TTestXcomTourFlows.DovrebbeRuotareEIngrandireIlGlobo;
var
  LZoom: Integer;
begin
  if not NewGame then
    Exit;
  LZoom := FWorld.GlobeZoom;
  FWorld.Click(612, 330);
  Assert.AreEqual(LZoom + 1, FWorld.GlobeZoom);
  FWorld.Click(612, 380);
  Assert.AreEqual(LZoom, FWorld.GlobeZoom);
  // the four arrows
  FWorld.Click(555, 336);
  FWorld.Click(555, 386);
  FWorld.Click(530, 362);
  FWorld.Click(578, 362);
  Assert.AreEqual(GEOSCAPE, FWorld.Top);
end;

procedure TTestXcomTourFlows.DovrebbeTrasferireTraDueBasi;
var
  LTransfers: Integer;
begin
  if not Variant('save02_twobases') then
    Exit;
  Assert.AreEqual(2, FWorld.Save.Bases.Count);
  LTransfers := FWorld.Save.Bases[1].Transfers.Count;
  FWorld.Click(TOUR_GEO_BUTTON_X, TOUR_BASES_Y);
  FWorld.Click(TOUR_BASE_BUTTON_X, TOUR_TRANSFER_Y);
  Assert.AreEqual('TXcomTransferBaseState', FWorld.Top);
  FWorld.Click(150, 164);
  Assert.AreEqual('TXcomTransferItemsState', FWorld.Top);
  // one of the first row, then Transfer
  FWorld.Click(412, 96);
  FWorld.Click(160, 368);
  Assert.AreEqual('TXcomTransferConfirmState', FWorld.Top);
  FWorld.Key(XCOM_KEY_RETURN);
  Assert.AreEqual(LTransfers + 1, FWorld.Save.Bases[1].Transfers.Count);
end;

procedure TTestXcomTourFlows.DovrebbeCombattereUnUfoNelDogfight;
var
  LTurn: Integer;
begin
  if not Variant('save02_dogfight') then
    Exit;
  // the craft is over the UFO: the window of the dogfight opens by itself, the time stops while it is open
  FWorld.Wait(4000);
  for LTurn := 1 to 20 do
  begin
    // aggressive attack, then the other buttons of the window
    FWorld.Click(437, 156);
    FWorld.Wait(1500);
    FWorld.Click(437, 132);
    FWorld.Click(372, 132);
    FWorld.Click(372, 156);
  end;
  Assert.AreEqual(GEOSCAPE, FWorld.Top);
end;

procedure TTestXcomTourFlows.DovrebbeMostrareIlDiarioDiUnSoldato;
begin
  if not Variant('save02_diary') then
    Exit;
  FWorld.Click(TOUR_GEO_BUTTON_X, TOUR_BASES_Y);
  FWorld.Click(TOUR_BASE_BUTTON_X, TOUR_SOLDIERS_Y);
  FWorld.Click(100, 90);
  Assert.AreEqual('TXcomSoldierInfoState', FWorld.Top);
  FWorld.Click(573, 100);
  Assert.AreEqual('TXcomSoldierDiaryOverviewState', FWorld.Top);
  // the first mission of the list
  FWorld.Click(100, 96);
  Assert.AreEqual('TXcomSoldierDiaryMissionState', FWorld.Top);
  FWorld.Key(XCOM_KEY_ESCAPE);
  // Combat and Performance
  FWorld.Click(80, 368);
  Assert.AreEqual('TXcomSoldierDiaryPerformanceState', FWorld.Top);
  FWorld.Key(XCOM_KEY_ESCAPE);
  FWorld.Click(240, 368);
  Assert.AreEqual('TXcomSoldierDiaryPerformanceState', FWorld.Top);
end;

procedure TTestXcomTourFlows.DovrebbeMostrareIMortiNelMemoriale;
begin
  if not Variant('save02_dead') then
    Exit;
  FWorld.Click(TOUR_GEO_BUTTON_X, TOUR_BASES_Y);
  FWorld.Click(TOUR_BASE_BUTTON_X, TOUR_SOLDIERS_Y);
  FWorld.Click(124, 368);
  Assert.AreEqual('TXcomSoldierMemorialState', FWorld.Top);
  FWorld.Click(100, 96);
  Assert.AreEqual('TXcomSoldierInfoState', FWorld.Top, 'un clic su un morto apre le sue statistiche');
end;

end.
