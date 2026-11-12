{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the xcom battlescape states library - the map      }
{  seen from above of the minimap (TXcomMiniMapView)                            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (the library itself is derived from OpenXcom, GPL v3 or later)               }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomBattleStates.MiniMapView;

interface

uses
  DelphiDoom.Clock.Intf,
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Tests.Xcom.Skip, DelphiDoom.XcomMod.MapBlock, DelphiDoom.XcomEngine.Intf,
  DelphiDoom.Clock.ManualClock, DelphiDoom.XcomSurface.SurfaceSet,
  DelphiDoom.XcomBattlescape.Camera, DelphiDoom.XcomBattleStates.MiniMapView,
  DelphiDoom.Tests.XcomBattleStates.BattleWorld;

type
  [TestFixture]
  [Category('XcomBattleStates')]
  TTestXcomMiniMapView = class
  strict private
    FClock: IClock;
    FCamera: TXcomCamera;
    FView: TXcomMiniMapView;
    class function DragOptions: TXcomMiniMapDragOptions; static;
    /// <summary>A set like SCANG.DAT: frames of 4x4 pixels, each of one color that is neither black nor the background</summary>
    class function NewSet: TXcomSurfaceSet; static;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeNonDisegnareNullaSenzaLeImmagini;
    [Test]
    procedure DovrebbeFarGirareITreFotogrammi;
    [Test]
    procedure DovrebbeSalireEScendereDiLivelloEntroLaMappa;
    [Test]
    procedure DovrebbeDisegnareLaCroceColColoreDelFotogramma;
    [Test]
    procedure DovrebbeDisegnareLeUnitaDellaBattaglia;
  end;

implementation

const
  VIEW_WIDTH = 221;
  VIEW_HEIGHT = 148;
  MAP_LEVELS = 4;
  SET_FRAMES = 1000;
  // the color of the frame 9 of the set of the tests
  ITEM_COLOR = 32 + 9 mod 8 * 16;
  // the first pixel of the top left arm of the cross: the center less a cell
  CROSS_X = VIEW_WIDTH div 2 - 1 - 4;
  CROSS_Y = VIEW_HEIGHT div 2 - 1 - 4;

class function TTestXcomMiniMapView.DragOptions: TXcomMiniMapDragOptions;
begin
  Result.Button := 2;
  Result.Invert := False;
  Result.TimeTolerance := 300;
  Result.PixelTolerance := 10;
end;

class function TTestXcomMiniMapView.NewSet: TXcomSurfaceSet;
var
  LIndex: Integer;
begin
  Result := TXcomSurfaceSet.Create(4, 4);
  for LIndex := 0 to SET_FRAMES - 1 do
    Result.AddFrame(LIndex).DrawRect(0, 0, 4, 4, Byte(32 + LIndex mod 8 * 16));
end;

procedure TTestXcomMiniMapView.Setup;
begin
  FClock := TManualClock.Create;
  FCamera := TXcomCamera.Create(32, 40, 50, 50, MAP_LEVELS, 320, 200, 144, 320, 56);
  // no images and no battle: nothing of the battle is read
  FView := TXcomMiniMapView.Create(VIEW_WIDTH, VIEW_HEIGHT, 48, 16, nil, FCamera, nil, FClock, DragOptions, 3);
end;

procedure TTestXcomMiniMapView.TearDown;
begin
  FView.Free;
  FCamera.Free;
  FClock := nil;
end;

procedure TTestXcomMiniMapView.DovrebbeNonDisegnareNullaSenzaLeImmagini;
begin
  FView.Draw;
  Assert.AreEqual(0, Integer(FView.GetPixel(0, 0)));
  Assert.AreEqual(0, Integer(FView.GetPixel(CROSS_X, CROSS_Y)));
  Assert.IsFalse(FView.Redraw);
end;

procedure TTestXcomMiniMapView.DovrebbeFarGirareITreFotogrammi;
begin
  Assert.AreEqual(0, FView.Frame);
  FView.Redraw := False;
  FView.Animate;
  Assert.AreEqual(1, FView.Frame);
  Assert.IsTrue(FView.Redraw, 'a new frame is drawn again');
  FView.Animate;
  Assert.AreEqual(2, FView.Frame);
  FView.Animate;
  Assert.AreEqual(0, FView.Frame);
end;

procedure TTestXcomMiniMapView.DovrebbeSalireEScendereDiLivelloEntroLaMappa;
var
  LLevel: Integer;
begin
  Assert.AreEqual(0, FView.Down, 'not below the ground');
  for LLevel := 1 to MAP_LEVELS - 1 do
    Assert.AreEqual(LLevel, FView.Up);
  Assert.AreEqual(MAP_LEVELS - 1, FView.Up, 'not above the last level');
  Assert.AreEqual(MAP_LEVELS - 1, FCamera.ViewLevel);
  Assert.AreEqual(MAP_LEVELS - 2, FView.Down);
  Assert.IsTrue(FView.Redraw);
end;

procedure TTestXcomMiniMapView.DovrebbeDisegnareLaCroceColColoreDelFotogramma;
var
  LWorld: TBattleTestWorld;
  LView: TXcomMiniMapView;
  LSet: TXcomSurfaceSet;
begin
  LWorld := TBattleTestWorld.TryCreate;
  if not Assigned(LWorld) then
  begin
    TXcomTestSkip.Ignore('The data of the real game are not on this machine');
    Exit;
  end;
  try
    LSet := NewSet;
    LView := TXcomMiniMapView.Create(VIEW_WIDTH, VIEW_HEIGHT, 48, 16, LSet, LWorld.Parent.Map.Camera, LWorld.Battle,
      FClock, DragOptions, 3);
    try
      // the line of the cross looks its color up in the palette of the surface
      LView.SetPalette(@LWorld.Parent.Palette^[0]);
      LView.Draw;
      Assert.AreEqual(1,Integer(LView.GetPixel(CROSS_X, CROSS_Y)));
      LView.Animate;
      LView.Draw;
      Assert.AreEqual(4, Integer(LView.GetPixel(CROSS_X, CROSS_Y)));
      LView.Animate;
      LView.Draw;
      Assert.AreEqual(7, Integer(LView.GetPixel(CROSS_X, CROSS_Y)));
    finally
      LView.Free;
      LSet.Free;
    end;
  finally
    LWorld.Free;
  end;
end;

procedure TTestXcomMiniMapView.DovrebbeDisegnareLeUnitaDellaBattaglia;
var
  LWorld: TBattleTestWorld;
  LView: TXcomMiniMapView;
  LSet: TXcomSurfaceSet;
  LCenter: TXcomPosition;
  LExpected, LPixel: Integer;
begin
  LWorld := TBattleTestWorld.TryCreate;
  if not Assigned(LWorld) then
  begin
    TXcomTestSkip.Ignore('The data of the real game are not on this machine');
    Exit;
  end;
  try
    LSet := NewSet;
    LView := TXcomMiniMapView.Create(VIEW_WIDTH, VIEW_HEIGHT, 48, 16, LSet, LWorld.Parent.Map.Camera, LWorld.Battle,
      FClock, DragOptions, 3);
    try
      // the selected soldier in the middle: its cell is the one right of and below the center of the view
      LCenter := LWorld.Battle.SelectedUnit.Position;
      LWorld.Parent.Map.Camera.SetViewLevel(LCenter.Z);
      LWorld.Parent.Map.Camera.CenterOnPosition(LCenter);
      LView.Draw;
      // the frame of the soldier, or the one of the items (9) when something lies on its tile
      LExpected := 32 + LWorld.Battle.SelectedUnit.GetMiniMapSpriteIndex mod 8 * 16;
      LPixel := LView.GetPixel((VIEW_WIDTH div 4 div 2) * 4, (VIEW_HEIGHT div 4 div 2) * 4);
      Assert.IsTrue((LPixel = LExpected) or (LPixel = ITEM_COLOR),
        Format('the sprite of the soldier in its cell: color %d', [LPixel]));
    finally
      LView.Free;
      LSet.Free;
    end;
  finally
    LWorld.Free;
  end;
end;

end.
