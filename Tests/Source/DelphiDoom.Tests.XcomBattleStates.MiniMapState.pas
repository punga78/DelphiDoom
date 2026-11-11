{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the xcom battlescape states library - the screen   }
{  of the minimap (TXcomMiniMapState) over a real saved battle                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (the library itself is derived from OpenXcom, GPL v3 or later)               }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomBattleStates.MiniMapState;

interface

uses
  System.SysUtils, System.Math, DUnitX.TestFramework, DelphiDoom.XcomMod.MapBlock, DelphiDoom.XcomEngine.Types,
  DelphiDoom.XcomBattlescape.Camera, DelphiDoom.XcomBattleStates.MiniMapState,
  DelphiDoom.Tests.XcomBattleStates.BattleWorld;

type
  [TestFixture]
  [Category('XcomBattleStates')]
  TTestXcomMiniMapState = class
  strict private
    FWorld: TBattleTestWorld;
    function Open: TXcomMiniMapState;
    function Available: Boolean;
    function Camera: TXcomCamera;
    procedure Motion(AX, AY: Integer);
    procedure Button(AKind: TXcomEventKind; AX, AY, AButton: Integer);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeAprirsiConLaMappaEIlLivelloDellaCamera;
    [Test]
    procedure DovrebbeCambiareLivelloConIPulsanti;
    [Test]
    procedure DovrebbeCambiareLivelloConLaRotella;
    [Test]
    procedure DovrebbeLampeggiareOgniCentoventicinqueMillisecondi;
    [Test]
    procedure DovrebbeCentrareLaCameraDoveSiClicca;
    [Test]
    procedure DovrebbeScorrereTrascinandoColPulsanteCentrale;
    [Test]
    procedure DovrebbeChiudersiConOk;
    [Test]
    procedure DovrebbeChiudersiColPulsanteDestroSullaMappa;
    [Test]
    procedure DovrebbeChiudersiColTastoAnnulla;
  end;

implementation

const
  // the minimap of a game without the "minimap" interface: the positions of the constructor
  VIEW_X = 48;
  VIEW_Y = 16;
  VIEW_WIDTH = 221;
  VIEW_HEIGHT = 148;
  LEVEL_UP_X = 33;
  LEVEL_UP_Y = 72;
  LEVEL_DOWN_X = 33;
  LEVEL_DOWN_Y = 98;
  OK_X = 291;
  OK_Y = 161;
  WINDOW_SCALE = 2;

procedure TTestXcomMiniMapState.Setup;
begin
  FWorld := TBattleTestWorld.TryCreate;
end;

procedure TTestXcomMiniMapState.TearDown;
begin
  FWorld.Free;
end;

function TTestXcomMiniMapState.Available: Boolean;
begin
  Result := Assigned(FWorld);
  if not Result then
    Assert.Pass('The data of the real game are not on this machine');
end;

function TTestXcomMiniMapState.Camera: TXcomCamera;
begin
  Result := FWorld.Parent.Map.Camera;
end;

function TTestXcomMiniMapState.Open: TXcomMiniMapState;
begin
  Result := FWorld.Parent.Screens.MiniMap(FWorld.Parent) as TXcomMiniMapState;
  FWorld.World.Game.PushState(Result);
  FWorld.World.Wait(40);
end;

procedure TTestXcomMiniMapState.Motion(AX, AY: Integer);
var
  LEvent: TXcomInputEvent;
begin
  LEvent := TXcomInputEvent.Make(ekMouseMotion);
  LEvent.X := AX * WINDOW_SCALE;
  LEvent.Y := AY * WINDOW_SCALE;
  FWorld.World.Events.Enqueue(LEvent);
  FWorld.World.Wait(20);
end;

procedure TTestXcomMiniMapState.Button(AKind: TXcomEventKind; AX, AY, AButton: Integer);
var
  LEvent: TXcomInputEvent;
begin
  LEvent := TXcomInputEvent.Make(AKind);
  LEvent.X := AX * WINDOW_SCALE;
  LEvent.Y := AY * WINDOW_SCALE;
  LEvent.Button := AButton;
  FWorld.World.Events.Enqueue(LEvent);
  FWorld.World.Wait(20);
end;

procedure TTestXcomMiniMapState.DovrebbeAprirsiConLaMappaEIlLivelloDellaCamera;
var
  LState: TXcomMiniMapState;
begin
  if not Available then
    Exit;
  LState := Open;
  Assert.IsTrue(FWorld.World.Game.IsState(LState));
  Assert.AreEqual(VIEW_WIDTH, LState.MiniMapView.Width);
  Assert.AreEqual(VIEW_HEIGHT, LState.MiniMapView.Height);
  Assert.AreEqual(VIEW_X, LState.MiniMapView.X);
  Assert.AreEqual(VIEW_Y, LState.MiniMapView.Y);
  Assert.IsTrue(LState.IsScreen, 'on a screen of 320x200 the minimap covers the battlescape');
  Assert.AreEqual(FWorld.World.Game.Language.GetString('STR_LEVEL_SHORT').Arg(Camera.ViewLevel).Text,
    LState.TxtLevel.GetText);
end;

procedure TTestXcomMiniMapState.DovrebbeCambiareLivelloConIPulsanti;
var
  LState: TXcomMiniMapState;
  LLevel: Integer;
begin
  if not Available then
    Exit;
  LState := Open;
  LLevel := Camera.ViewLevel;
  FWorld.ClickButton(LEVEL_UP_X, LEVEL_UP_Y, XCOM_BUTTON_LEFT);
  Assert.AreEqual(Min(LLevel + 1, FWorld.Battle.MapSizeZ - 1), Camera.ViewLevel, 'a level up');
  Assert.AreEqual(FWorld.World.Game.Language.GetString('STR_LEVEL_SHORT').Arg(Camera.ViewLevel).Text,
    LState.TxtLevel.GetText);
  LLevel := Camera.ViewLevel;
  FWorld.ClickButton(LEVEL_DOWN_X, LEVEL_DOWN_Y, XCOM_BUTTON_LEFT);
  Assert.AreEqual(Max(LLevel - 1, 0), Camera.ViewLevel, 'a level down');
  Assert.IsTrue(FWorld.World.Game.IsState(LState));
end;

procedure TTestXcomMiniMapState.DovrebbeCambiareLivelloConLaRotella;
var
  LLevel: Integer;
begin
  if not Available then
    Exit;
  Open;
  LLevel := Camera.ViewLevel;
  Button(ekMouseDown, 10, 190, XCOM_BUTTON_WHEELUP);
  Assert.AreEqual(Min(LLevel + 1, FWorld.Battle.MapSizeZ - 1), Camera.ViewLevel);
  LLevel := Camera.ViewLevel;
  Button(ekMouseDown, 10, 190, XCOM_BUTTON_WHEELDOWN);
  Assert.AreEqual(Max(LLevel - 1, 0), Camera.ViewLevel);
end;

procedure TTestXcomMiniMapState.DovrebbeLampeggiareOgniCentoventicinqueMillisecondi;
var
  LState: TXcomMiniMapState;
  LFrame: Integer;
begin
  if not Available then
    Exit;
  LState := Open;
  LFrame := LState.MiniMapView.Frame;
  FWorld.World.Wait(125);
  Assert.AreEqual((LFrame + 1) mod 3, LState.MiniMapView.Frame);
  FWorld.World.Wait(125);
  Assert.AreEqual((LFrame + 2) mod 3, LState.MiniMapView.Frame);
  FWorld.World.Wait(125);
  Assert.AreEqual(LFrame, LState.MiniMapView.Frame);
end;

procedure TTestXcomMiniMapState.DovrebbeCentrareLaCameraDoveSiClicca;
var
  LBefore: TXcomPosition;
begin
  if not Available then
    Exit;
  Open;
  Camera.CenterOnPosition(TXcomPosition.Make(10, 10, Camera.ViewLevel));
  LBefore := Camera.CenterPosition;
  // two cells right of the middle cell and one below it
  FWorld.ClickButton(VIEW_X + (VIEW_WIDTH div 2 div 4 + 2) * 4 + 1, VIEW_Y + (VIEW_HEIGHT div 2 div 4 + 1) * 4 + 1,
    XCOM_BUTTON_LEFT);
  Assert.AreEqual(LBefore.X + 2, Camera.CenterPosition.X);
  Assert.AreEqual(LBefore.Y + 1, Camera.CenterPosition.Y);
  Assert.AreEqual(LBefore.Z, Camera.CenterPosition.Z);
end;

procedure TTestXcomMiniMapState.DovrebbeScorrereTrascinandoColPulsanteCentrale;
var
  LState: TXcomMiniMapState;
  LBefore: TXcomPosition;
begin
  if not Available then
    Exit;
  LState := Open;
  Camera.CenterOnPosition(TXcomPosition.Make(10, 10, Camera.ViewLevel));
  LBefore := Camera.CenterPosition;
  Motion(160, 90);
  Button(ekMouseDown, 160, 90, XCOM_BUTTON_MIDDLE);
  // twenty pixels of the screen to the left: the map follows by five cells of four pixels
  Motion(140, 90);
  Assert.AreEqual(LBefore.X + 5, Camera.CenterPosition.X, 'the map scrolls while dragging');
  Assert.AreEqual(LBefore.Y, Camera.CenterPosition.Y);
  Button(ekMouseUp, 140, 90, XCOM_BUTTON_MIDDLE);
  Assert.AreEqual(LBefore.X + 5, Camera.CenterPosition.X, 'the release keeps the scroll');
  Assert.IsTrue(FWorld.World.Game.IsState(LState));
end;

procedure TTestXcomMiniMapState.DovrebbeChiudersiConOk;
begin
  if not Available then
    Exit;
  Open;
  FWorld.ClickButton(OK_X, OK_Y, XCOM_BUTTON_LEFT);
  Assert.IsTrue(FWorld.World.Game.IsState(FWorld.Parent));
end;

procedure TTestXcomMiniMapState.DovrebbeChiudersiColPulsanteDestroSullaMappa;
begin
  if not Available then
    Exit;
  Open;
  FWorld.ClickButton(VIEW_X + 100, VIEW_Y + 70, XCOM_BUTTON_RIGHT);
  Assert.IsTrue(FWorld.World.Game.IsState(FWorld.Parent));
end;

procedure TTestXcomMiniMapState.DovrebbeChiudersiColTastoAnnulla;
begin
  if not Available then
    Exit;
  Open;
  FWorld.PressKey(FWorld.World.Game.Options.KeyCancel);
  Assert.IsTrue(FWorld.World.Game.IsState(FWorld.Parent));
end;

end.
