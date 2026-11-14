{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the rear view camera of TGreedGame (RearView of    }
{  raven.pas), with the renderer and the view of the fakes                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Greed.RearView;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Greed.Types, DelphiDoom.Greed.Game,
  DelphiDoom.Tests.Greed.GameFakes;

type
  [TestFixture]
  [Category('greed')]
  TTestGreedRearView = class(TObject)
  strict private
    FSetup: TFakeGameSetup;
    procedure Start;
    /// plays turns with the key of the camera held until the camera has taken a picture
    procedure TurnCameraOn;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure SenzaIlComandoNonDovrebbeDisegnareLoSpecchietto;
    [Test]
    procedure DovrebbeDisegnareUnaVistaDi64Per64AlleSpalleDelGiocatore;
    [Test]
    procedure DovrebbeTenereLImmagineDelRenderer;
    [Test]
    procedure DovrebbeFareVivereIlLivelloAncheMentreDisegnaLoSpecchietto;
    [Test]
    procedure DovrebbeDareLImmagineAllaVistaFinoAScadenza;
    [Test]
    procedure DovrebbeRifareLImmagineOgniCameraDelayTic;
    [Test]
    procedure ConCameraDelayDiUnSecondoDovrebbeFareUnaSolaImmagine;
    [Test]
    procedure IlComandoDovrebbeSpegnereLoSpecchiettoAcceso;
    [Test]
    procedure LaVistaNemicaDovrebbeGuardareDalPostoDelNemico;
    [Test]
    procedure LaVistaNemicaSenzaObiettivoDovrebbeRestareAlleSpalle;
  end;

implementation

uses
  DelphiDoom.Greed.Game.Constants, DelphiDoom.Greed.PlayerControl.Intf;

const
  TIC_RATE = 70;
  HALF_TURN = 512;
  ANGLE_MASK = 1023;

{ TTestGreedRearView }

procedure TTestGreedRearView.Setup;
begin
  FSetup := TFakeGameSetup.Create;
end;

procedure TTestGreedRearView.TearDown;
begin
  FreeAndNil(FSetup);
end;

procedure TTestGreedRearView.Start;
begin
  FSetup.CreateGame;
  FSetup.Game.NewGame(0, 0, 2);
  FSetup.Renderer.CameraColor := 77;
end;

procedure TTestGreedRearView.TurnCameraOn;
var
  LTurn: Integer;
begin
  FSetup.Commands.Pressed := [gcRearView];
  LTurn := 0;
  while (FSetup.Renderer.CameraViews = 0) and (LTurn < 40) do
  begin
    FSetup.Play(1);
    Inc(LTurn);
  end;
  FSetup.Commands.Pressed := [];
  Assert.AreEqual(1, FSetup.Renderer.CameraViews, 'the camera did not take its picture');
end;

procedure TTestGreedRearView.SenzaIlComandoNonDovrebbeDisegnareLoSpecchietto;
begin
  Start;
  FSetup.Play(30);
  Assert.AreEqual(0, FSetup.Renderer.CameraViews);
  Assert.AreEqual(0, Length(FSetup.Game.RearBuffer));
  Assert.IsFalse(FSetup.View.LastOverlay.RearViewVisible);
  Assert.IsFalse(FSetup.Game.State.RearViewOn);
end;

procedure TTestGreedRearView.DovrebbeDisegnareUnaVistaDi64Per64AlleSpalleDelGiocatore;
var
  LScrollMin: Integer;
begin
  Start;
  FSetup.Game.State.Player.ScrollMin := 17;
  LScrollMin := FSetup.Game.State.Player.ScrollMin;
  TurnCameraOn;
  Assert.AreEqual(GREED_REAR_VIEW_SIZE, FSetup.Renderer.CameraWidth);
  Assert.AreEqual(GREED_REAR_VIEW_SIZE, FSetup.Renderer.CameraHeight);
  Assert.AreEqual(FSetup.Game.State.Player.X, FSetup.Renderer.CameraX);
  Assert.AreEqual(FSetup.Game.State.Player.Y, FSetup.Renderer.CameraY);
  // the camera is at the height of the eyes, without the bobbing of the head
  Assert.AreEqual(FSetup.Game.State.Player.Z, FSetup.Renderer.CameraZ);
  Assert.AreEqual((FSetup.Game.State.Player.Angle + HALF_TURN) and ANGLE_MASK,
    FSetup.Renderer.CameraAngle and ANGLE_MASK, 'half a turn from where the player looks');
  Assert.AreEqual(LScrollMin, FSetup.Game.State.Player.ScrollMin, 'the look of the player is not touched');
  Assert.IsTrue(FSetup.Game.State.RearViewOn);
end;

procedure TTestGreedRearView.DovrebbeTenereLImmagineDelRenderer;
var
  LBuffer: TBytes;
begin
  Start;
  TurnCameraOn;
  LBuffer := FSetup.Game.RearBuffer;
  Assert.AreEqual(GREED_REAR_VIEW_SIZE * GREED_REAR_VIEW_SIZE, Integer(Length(LBuffer)));
  Assert.AreEqual(0, Integer(LBuffer[0]), 'a hole of the view stays 0: who draws makes it black');
  Assert.AreEqual(77, Integer(LBuffer[1]));
  Assert.AreEqual(77, Integer(LBuffer[High(LBuffer)]));
end;

procedure TTestGreedRearView.DovrebbeFareVivereIlLivelloAncheMentreDisegnaLoSpecchietto;
var
  LUpdates: Integer;
begin
  Start;
  // the camera is on and its next picture is due at the next turn
  FSetup.Game.State.RearViewOn := True;
  FSetup.Game.State.RearViewDelay := 0;
  LUpdates := FSetup.Sound.Updates;
  FSetup.Play(1);
  Assert.AreEqual(1, FSetup.Renderer.CameraViews);
  // the 12 TimeUpdate of a turn and the 4 of the second view (RF_CheckActionFlag)
  Assert.AreEqual(16, FSetup.Sound.Updates - LUpdates);
  Assert.AreEqual(1, FSetup.Renderer.Views, 'the view of the player is drawn as always');
end;

procedure TTestGreedRearView.DovrebbeDareLImmagineAllaVistaFinoAScadenza;
var
  LTurn: Integer;
begin
  Start;
  FSetup.Game.CameraDelay := TIC_RATE;
  TurnCameraOn;
  Assert.IsTrue(FSetup.View.LastOverlay.RearViewVisible);
  Assert.AreEqual(GREED_REAR_VIEW_SIZE * GREED_REAR_VIEW_SIZE, Integer(Length(FSetup.View.LastOverlay.RearView)));
  Assert.AreEqual(77, Integer(FSetup.View.LastOverlay.RearView[5]));
  Assert.AreEqual(FSetup.Game.State.TimeCount + 2 * TIC_RATE, FSetup.Game.State.RearViewTime + 0,
    'the box stays two seconds after the picture');
  // one picture and off: the box goes away two seconds later (2 tics a turn)
  for LTurn := 1 to TIC_RATE - 1 do
    FSetup.Play(1);
  Assert.IsTrue(FSetup.View.LastOverlay.RearViewVisible, 'one tic before the two seconds');
  FSetup.Play(1);
  Assert.IsFalse(FSetup.View.LastOverlay.RearViewVisible);
  Assert.AreEqual(1, FSetup.Renderer.CameraViews);
end;

procedure TTestGreedRearView.DovrebbeRifareLImmagineOgniCameraDelayTic;
begin
  Start;
  FSetup.Game.CameraDelay := 10;
  TurnCameraOn;
  // 2 tics a turn: the next picture is due 10 tics after the first, at the fifth turn
  FSetup.Play(4);
  Assert.AreEqual(1, FSetup.Renderer.CameraViews);
  FSetup.Play(1);
  Assert.AreEqual(2, FSetup.Renderer.CameraViews);
  FSetup.Play(5);
  Assert.AreEqual(3, FSetup.Renderer.CameraViews);
  Assert.IsTrue(FSetup.Game.State.RearViewOn);
  Assert.IsTrue(FSetup.View.LastOverlay.RearViewVisible);
end;

procedure TTestGreedRearView.ConCameraDelayDiUnSecondoDovrebbeFareUnaSolaImmagine;
begin
  Start;
  FSetup.Game.CameraDelay := TIC_RATE;
  TurnCameraOn;
  Assert.IsFalse(FSetup.Game.State.RearViewOn, 'SC.camdelay = TICRATE: a picture and off');
  FSetup.Play(60);
  Assert.AreEqual(1, FSetup.Renderer.CameraViews);
end;

procedure TTestGreedRearView.IlComandoDovrebbeSpegnereLoSpecchiettoAcceso;
var
  LTurn, LViews: Integer;
begin
  Start;
  FSetup.Game.CameraDelay := 10;
  TurnCameraOn;
  // the key again, once the keyboard is ready
  FSetup.Play(20);
  FSetup.Commands.Pressed := [gcRearView];
  LTurn := 0;
  while FSetup.Game.State.RearViewOn and (LTurn < 40) do
  begin
    FSetup.Play(1);
    Inc(LTurn);
  end;
  FSetup.Commands.Pressed := [];
  Assert.IsFalse(FSetup.Game.State.RearViewOn);
  LViews := FSetup.Renderer.CameraViews;
  FSetup.Play(30);
  Assert.AreEqual(LViews, FSetup.Renderer.CameraViews, 'no pictures with the camera off');
end;

procedure TTestGreedRearView.LaVistaNemicaDovrebbeGuardareDalPostoDelNemico;
var
  LEnemy: TGreedEnemyView;
begin
  Start;
  // the first turn chooses the goal item of a new map
  FSetup.Play(1);
  // the secret code "taco" and a goal item: the camera looks from playerdata[goalitem - 1]
  FSetup.Game.State.EnemyViewMode := 1;
  FSetup.Game.State.GoalItem := 1;
  LEnemy.X := 11 * GREED_FRACUNIT;
  LEnemy.Y := 22 * GREED_FRACUNIT;
  LEnemy.Z := 33 * GREED_FRACUNIT;
  LEnemy.Angle := 300;
  FSetup.Game.EnemyView := LEnemy;
  FSetup.Game.State.RearViewOn := True;
  FSetup.Game.State.RearViewDelay := 0;
  FSetup.Play(1);
  Assert.AreEqual(1, FSetup.Renderer.CameraViews);
  Assert.AreEqual(LEnemy.X, FSetup.Renderer.CameraX);
  Assert.AreEqual(LEnemy.Y, FSetup.Renderer.CameraY);
  Assert.AreEqual(LEnemy.Z, FSetup.Renderer.CameraZ);
  Assert.AreEqual(300, FSetup.Renderer.CameraAngle);
end;

procedure TTestGreedRearView.LaVistaNemicaSenzaObiettivoDovrebbeRestareAlleSpalle;
begin
  Start;
  FSetup.Play(1);
  FSetup.Game.State.EnemyViewMode := 1;
  FSetup.Game.State.GoalItem := 0;
  FSetup.Game.State.RearViewOn := True;
  FSetup.Game.State.RearViewDelay := 0;
  FSetup.Play(1);
  Assert.AreEqual(FSetup.Game.State.Player.X, FSetup.Renderer.CameraX);
  Assert.AreEqual((FSetup.Game.State.Player.Angle + HALF_TURN) and ANGLE_MASK,
    FSetup.Renderer.CameraAngle and ANGLE_MASK);
end;

end.
