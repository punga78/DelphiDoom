{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - the pieces of the map interface       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.MapUiUnits;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.War.Ui.Types, DelphiDoom.War.Ui.Intf;

type
  /// <summary>An input that a test sets as it likes (the real one needs a game)</summary>
  TFakeInput = class(TInterfacedObject, IWarUiInput)
  public
    X: Single;
    Y: Single;
    LeftHeld: Boolean;
    Keys: set of TWarKey;
    function IsButtonHeld(AButton: TWarMouseButton): Boolean;
    function IsButtonJustPressed(AButton: TWarMouseButton): Boolean;
    function IsButtonJustReleased(AButton: TWarMouseButton): Boolean;
    function IsKeyHeld(AKey: TWarKey): Boolean;
    function IsKeyJustPressed(AKey: TWarKey): Boolean;
    function IsKeyJustReleased(AKey: TWarKey): Boolean;
    function GetPositionX: Single;
    function GetPositionY: Single;
  end;

  [TestFixture]
  [Category('war')]
  TTestWarMapUiUnits = class(TObject)
  public
    [Test]
    procedure DovrebbeDareIPannelliDellaMappa;
    [Test]
    procedure DovrebbeContenereIBordiDelRettangolo;
    [Test]
    [TestCase('Livello 0', '0,100')]
    [TestCase('Livello 2', '2,200')]
    [TestCase('Livello 4', '4,300')]
    procedure DovrebbeDareLaVelocitaDiScorrimento(ALevel: Integer; AExpected: Single);
    [Test]
    procedure DovrebbeNormalizzareLaDirezioneDelleFrecce;
    [Test]
    procedure DovrebbeScorrereColMouseAiBordiEFermarsi;
    [Test]
    procedure DovrebbeSeguireIlClicSulMinimap;
    [Test]
    procedure DovrebbeNonScorrereConLeFrecceConCtrl;
    [Test]
    procedure DovrebbeConvertireLeCoordinate;
    [Test]
    procedure DovrebbeColorareLeUnitaSulMinimap;
    [Test]
    procedure DovrebbeDisegnareUnQuadratinoPerUnContornoSenzaArea;
    [Test]
    procedure DovrebbeDareIMessaggiDelloStato;
    [Test]
    procedure DovrebbeToglierDallaSelezioneUnaEntitaChePerde;
    [Test]
    procedure DovrebbeFareEntitaESceglierePerLeSelezioniEIlRiconoscimento;
    [Test]
    procedure DovrebbeDareSempreLoStessoSpriteDiUnRecord;
    [Test]
    procedure DovrebbeSvuotareIlPannelloDeiComandi;
  end;

implementation

uses
  DelphiDoom.War.Types, DelphiDoom.War.Level.Types, DelphiDoom.War.Render.Types, DelphiDoom.War.Render.Blitter,
  DelphiDoom.War.Map.Types, DelphiDoom.War.Map.Minimap, DelphiDoom.War.Map.Fog, DelphiDoom.War.Sound.Intf,
  DelphiDoom.War.Sound.Factory, DelphiDoom.War.Model.Gather.Intf, DelphiDoom.War.Model.World, DelphiDoom.War.Model.Types, DelphiDoom.War.Model.Intf, DelphiDoom.War.Model.Factory,
  DelphiDoom.War.Model.Context, DelphiDoom.War.MapUi.Types, DelphiDoom.War.MapUi.Camera, DelphiDoom.War.MapUi.Host,
  DelphiDoom.War.MapUi.Intf, DelphiDoom.War.Text.Types, DelphiDoom.War.MapUi.Audio, DelphiDoom.War.MapUi.Sprites, DelphiDoom.War.MapUi.Census,
  DelphiDoom.Tests.War.UiFakes, DelphiDoom.Tests.War.MapSupport;

type
  TCountingRandom = class(TInterfacedObject, IWarRandom)
  public
    Calls: Integer;
    function Below(ALimit: Integer): Integer;
  end;

{ TFakeInput }

function TFakeInput.IsButtonHeld(AButton: TWarMouseButton): Boolean;
begin
  Result := (AButton = wmbLeft) and LeftHeld;
end;

function TFakeInput.IsButtonJustPressed(AButton: TWarMouseButton): Boolean;
begin
  Result := False;
end;

function TFakeInput.IsButtonJustReleased(AButton: TWarMouseButton): Boolean;
begin
  Result := False;
end;

function TFakeInput.IsKeyHeld(AKey: TWarKey): Boolean;
begin
  Result := AKey in Keys;
end;

function TFakeInput.IsKeyJustPressed(AKey: TWarKey): Boolean;
begin
  Result := False;
end;

function TFakeInput.IsKeyJustReleased(AKey: TWarKey): Boolean;
begin
  Result := False;
end;

function TFakeInput.GetPositionX: Single;
begin
  Result := X;
end;

function TFakeInput.GetPositionY: Single;
begin
  Result := Y;
end;

{ TCountingRandom }

function TCountingRandom.Below(ALimit: Integer): Integer;
begin
  Inc(Calls);
  Result := 0;
end;

function NewContext(const ARandom: IWarRandom; out AWorld: TObject): TWarModelContext;
var
  LWorld: TWarModelWorld;
begin
  LWorld := TWarModelFactory.CreateWorld(ARandom);
  AWorld := LWorld;
  Result := LWorld.Context;
end;

function CameraContext: TWarCameraContext;
begin
  Result := Default(TWarCameraContext);
  Result.ScreenWidth := 320;
  Result.ScreenHeight := 200;
  Result.RealDeltaTime := Single(1) / Single(60);
  Result.MouseScrollSpeed := 2;
  Result.KeyScrollSpeed := 2;
end;

{ TTestWarMapUiUnits }

procedure TTestWarMapUiUnits.DovrebbeDareIPannelliDellaMappa;
var
  LPanels: TWarMapPanels;
begin
  LPanels := TWarMapPanels.Standard;
  Assert.AreEqual<Single>(72, LPanels.MapPanel.X);
  Assert.AreEqual<Single>(12, LPanels.MapPanel.Y);
  Assert.AreEqual<Single>(240, LPanels.MapPanel.Width);
  Assert.AreEqual<Single>(176, LPanels.MapPanel.Height);
  Assert.AreEqual<Single>(64, LPanels.MinimapPanel.Width);
  Assert.AreEqual<Single>(188, LPanels.BottomPanel.Y);
  Assert.AreEqual<Single>(312, LPanels.RightPanel.X);
end;

procedure TTestWarMapUiUnits.DovrebbeContenereIBordiDelRettangolo;
var
  LRect: TWarRectF;
begin
  LRect := WarRectI(10, 20, 30, 40);
  Assert.IsTrue(WarRectContains(LRect, 10, 20), 'angolo in alto a sinistra');
  Assert.IsTrue(WarRectContains(LRect, 40, 60), 'angolo in basso a destra');
  Assert.IsFalse(WarRectContains(LRect, 41, 30));
  Assert.IsFalse(WarRectContains(LRect, 20, 19));
end;

procedure TTestWarMapUiUnits.DovrebbeDareLaVelocitaDiScorrimento(ALevel: Integer; AExpected: Single);
begin
  Assert.AreEqual<Single>(AExpected, TWarMapCamera.ScrollSpeed(ALevel));
end;

procedure TTestWarMapUiUnits.DovrebbeNormalizzareLaDirezioneDelleFrecce;
var
  LInput: TFakeInput;
  LInputRef: IWarUiInput;
  LX: Single;
  LY: Single;
begin
  LInput := TFakeInput.Create;
  LInputRef := LInput;
  LInput.Keys := [wkLeft, wkDown];
  TWarMapCamera.DirFromArrowKeys(LInputRef, LX, LY);
  Assert.AreEqual(-0.70710677, Double(LX), 0.000001);
  Assert.AreEqual(0.70710677, Double(LY), 0.000001);
  LInput.Keys := [];
  TWarMapCamera.DirFromArrowKeys(LInputRef, LX, LY);
  Assert.AreEqual<Single>(0, LX);
  Assert.AreEqual<Single>(0, LY);
  LInput.Keys := [wkRight, wkUp];
  TWarMapCamera.DirFromArrowKeys(LInputRef, LX, LY);
  Assert.IsTrue((LX > 0) and (LY < 0));
end;

procedure TTestWarMapUiUnits.DovrebbeScorrereColMouseAiBordiEFermarsi;
var
  LInput: TFakeInput;
  LInputRef: IWarUiInput;
  LCamera: TWarMapCamera;
  LSuppress: Boolean;
  LIndex: Integer;
begin
  LInput := TFakeInput.Create;
  LInputRef := LInput;
  LCamera := TWarMapCamera.Create(TWarMapPanels.Standard, 100, 100);
  try
    LSuppress := False;
    // the left edge of the screen scrolls to the left
    LInput.X := 2;
    LInput.Y := 100;
    LCamera.Update(LInputRef, CameraContext, LSuppress);
    Assert.IsTrue(LCamera.X < 100, 'scorre a sinistra');
    Assert.AreEqual<Single>(100, LCamera.Y);
    Assert.IsTrue(LCamera.IsScrolling);
    // and stops at the edge of the map
    for LIndex := 1 to 300 do
      LCamera.Update(LInputRef, CameraContext, LSuppress);
    Assert.AreEqual<Single>(0, LCamera.X);
    // the right edge, the bottom edge
    LInput.X := 318;
    LInput.Y := 198;
    for LIndex := 1 to 900 do
      LCamera.Update(LInputRef, CameraContext, LSuppress);
    Assert.AreEqual<Single>(1024 - 240, LCamera.X);
    Assert.AreEqual<Single>(1024 - 176, LCamera.Y);
    // in the middle nothing moves and the camera says it stopped
    LInput.X := 160;
    LInput.Y := 100;
    LCamera.Update(LInputRef, CameraContext, LSuppress);
    Assert.IsFalse(LCamera.IsScrolling);
    Assert.IsTrue(LCamera.WasScrolling);
  finally
    LCamera.Free;
  end;
end;

procedure TTestWarMapUiUnits.DovrebbeSeguireIlClicSulMinimap;
var
  LInput: TFakeInput;
  LInputRef: IWarUiInput;
  LCamera: TWarMapCamera;
  LSuppress: Boolean;
  LContext: TWarCameraContext;
begin
  LInput := TFakeInput.Create;
  LInputRef := LInput;
  LCamera := TWarMapCamera.Create(TWarMapPanels.Standard, 0, 0);
  try
    LSuppress := False;
    LInput.LeftHeld := True;
    LInput.X := 3 + 32;
    LInput.Y := 6 + 32;
    LCamera.Update(LInputRef, CameraContext, LSuppress);
    // the middle of the window (15 x 11) on the click: (32 - 7.5) tiles of 16 pixels
    Assert.AreEqual(392.0, Double(LCamera.X), 0.001);
    Assert.AreEqual(424.0, Double(LCamera.Y), 0.001);
    // with a command waiting a click on the minimap is not for the camera
    LContext := CameraContext;
    LContext.CommandActive := True;
    LInput.X := 3 + 4;
    LInput.Y := 6 + 4;
    LCamera.Update(LInputRef, LContext, LSuppress);
    Assert.AreEqual(392.0, Double(LCamera.X), 0.001);
    // and "suppress" stops it until the button is released
    LContext.CommandActive := False;
    LSuppress := True;
    LCamera.Update(LInputRef, LContext, LSuppress);
    Assert.IsTrue(LSuppress);
    LInput.LeftHeld := False;
    LCamera.Update(LInputRef, LContext, LSuppress);
    Assert.IsFalse(LSuppress);
  finally
    LCamera.Free;
  end;
end;

procedure TTestWarMapUiUnits.DovrebbeNonScorrereConLeFrecceConCtrl;
var
  LInput: TFakeInput;
  LInputRef: IWarUiInput;
  LCamera: TWarMapCamera;
  LSuppress: Boolean;
  LContext: TWarCameraContext;
begin
  LInput := TFakeInput.Create;
  LInputRef := LInput;
  LCamera := TWarMapCamera.Create(TWarMapPanels.Standard, 200, 200);
  try
    LSuppress := False;
    LInput.X := 160;
    LInput.Y := 100;
    LInput.Keys := [wkRight, wkCtrl];
    LCamera.Update(LInputRef, CameraContext, LSuppress);
    Assert.AreEqual<Single>(200, LCamera.X);
    LInput.Keys := [wkRight];
    LCamera.Update(LInputRef, CameraContext, LSuppress);
    Assert.IsTrue(LCamera.X > 200);
    // and not while the cheat panel is open, nor while the mouse drags a rectangle
    LContext := CameraContext;
    LContext.CheatsOpen := True;
    LCamera.X := 200;
    LCamera.Update(LInputRef, LContext, LSuppress);
    Assert.AreEqual<Single>(200, LCamera.X);
    LContext.CheatsOpen := False;
    LContext.Dragging := True;
    LInput.X := 2;
    LInput.Keys := [];
    LCamera.Update(LInputRef, LContext, LSuppress);
    Assert.AreEqual<Single>(200, LCamera.X);
  finally
    LCamera.Free;
  end;
end;

procedure TTestWarMapUiUnits.DovrebbeConvertireLeCoordinate;
var
  LCamera: TWarMapCamera;
  LX: Single;
  LY: Single;
begin
  LCamera := TWarMapCamera.Create(TWarMapPanels.Standard, 100, 50);
  try
    LCamera.ScreenToMap(72 + 10, 12 + 20, LX, LY);
    Assert.AreEqual<Single>(110, LX);
    Assert.AreEqual<Single>(70, LY);
    LCamera.MapToScreen(110, 70, LX, LY);
    Assert.AreEqual<Single>(82, LX);
    Assert.AreEqual<Single>(32, LY);
    TWarMapCamera.MapToTile(110, 70, LX, LY);
    Assert.AreEqual<Single>(6, LX);
    Assert.AreEqual<Single>(4, LY);
    TWarMapCamera.TileToMap(6, 4, True, LX, LY);
    Assert.AreEqual<Single>(104, LX);
    Assert.AreEqual<Single>(72, LY);
    TWarMapCamera.TileToMap(6, 4, False, LX, LY);
    Assert.AreEqual<Single>(96, LX);
    Assert.AreEqual<Single>(64, LY);
  finally
    LCamera.Free;
  end;
end;

procedure TTestWarMapUiUnits.DovrebbeColorareLeUnitaSulMinimap;
var
  LMinimap: TWarMinimap;
  LFog: TWarFogOfWar;
  LColor: TWarMinimapColor;
begin
  LColor := TWarMinimap.UnitColorOf(WAR_UNIT_TOWNHALL_HUMANS, 1);
  Assert.AreEqual<Integer>(255, LColor.R);
  Assert.AreEqual<Integer>(0, LColor.B);
  LColor := TWarMinimap.UnitColorOf(WAR_UNIT_FOOTMAN, 0);
  Assert.AreEqual<Integer>(199, LColor.G);
  LColor := TWarMinimap.UnitColorOf(WAR_UNIT_GRUNT, 2);
  Assert.AreEqual<Integer>(199, LColor.R);
  LColor := TWarMinimap.UnitColorOf(WAR_UNIT_GOLDMINE, 4);
  Assert.AreEqual<Integer>(211, LColor.R);
  LMinimap := TWarMinimap.Create(TMapFixtures.Tileset);
  LFog := TWarFogOfWar.Create;
  try
    LFog.Enabled := False;
    LMinimap.BuildTerrain(TMapFixtures.FlatVisual(3));
    LMinimap.BeginFrame(LFog);
    LMinimap.PaintUnit(10, 10, 2, 2, LColor);
    Assert.AreEqual<Integer>(211, LMinimap.Frame[(10 * 64 + 10) * 4]);
    Assert.AreEqual<Integer>(211, LMinimap.Frame[(11 * 64 + 11) * 4]);
    Assert.WillRaise(
      procedure
      begin
        LMinimap.PaintUnit(63, 63, 3, 3, LColor);
      end, EWarException);
  finally
    LFog.Free;
    LMinimap.Free;
  end;
end;

procedure TTestWarMapUiUnits.DovrebbeDisegnareUnQuadratinoPerUnContornoSenzaArea;
var
  LBlitter: TWarImageBlitter;
  LRect: TWarRectF;
  LColor: TWarRgba;
  LPixels: TBytes;

  function Painted(AX, AY: Integer): Boolean;
  begin
    Result := LPixels[(AY * 8 + AX) * 4 + 1] = 200;
  end;

begin
  // SDL_RenderRect of a rectangle with w = h = 0 goes round the corner: four pixels (x, y), (x - 1, y), (x - 1, y - 1), (x, y - 1)
  LBlitter := TWarImageBlitter.Create(8, 8);
  try
    LColor.R := 0;
    LColor.G := 200;
    LColor.B := 0;
    LColor.A := 255;
    LRect.X := 4;
    LRect.Y := 4;
    LRect.Width := 0;
    LRect.Height := 0;
    LBlitter.StrokeRect(LRect, LColor);
    LPixels := LBlitter.Pixels;
    Assert.IsTrue(Painted(4, 4) and Painted(3, 4) and Painted(3, 3) and Painted(4, 3), 'i quattro pixel');
    Assert.IsFalse(Painted(5, 4) or Painted(4, 5), 'e nessun altro');
  finally
    LBlitter.Free;
  end;
end;

procedure TTestWarMapUiUnits.DovrebbeDareIMessaggiDelloStato;
var
  LHost: IWarMapHost;
  LObject: TWarMapHost;
  LMessages: IWarModelEvents;
  LGather: IWarGatherEvents;
begin
  LObject := TWarMapHost.Create(nil);
  LHost := LObject;
  LMessages := LObject;
  LHost.SetRealTime(10);
  LMessages.FlashStatus(wsmNotEnoughGold);
  Assert.IsTrue(LHost.GetFlash.Enabled);
  Assert.AreEqual('NOT ENOUGH GOLD... MINE MORE GOLD', string(LHost.GetFlash.Text));
  Assert.AreEqual(11.5, LHost.GetFlash.EndRealTime, 0.0000001);
  LMessages.FlashStatus(wsmNotEnoughLumber);
  Assert.AreEqual('NOT ENOUGH LUMBER... CHOP MORE TREES', string(LHost.GetFlash.Text));
  LMessages.FlashStatus(wsmNotEnoughMana);
  Assert.AreEqual('NOT ENOUGH MANA', string(LHost.GetFlash.Text));
  LMessages.FlashStatus(wsmNotEnoughFood);
  Assert.AreEqual('NOT ENOUGH FOOD... BUILD MORE FARMS', string(LHost.GetFlash.Text));
  LMessages.FlashStatus(wsmCantBuildThere);
  Assert.AreEqual('CAN''T BUILD THERE', string(LHost.GetFlash.Text));
  // the other events say nothing to the game of the map
  LMessages.UnitDied(1, 0, Default(TWarVec2));
  LMessages.BuildingCollapsing(1, 0, Default(TWarVec2));
  LMessages.BuildingDamaged(1, 50);
  LGather := LObject;
  LGather.TreeChopped(Default(TWarVec2));
  Assert.IsTrue(LObject.IsTileKnown(3, 3), 'senza la nebbia ogni tegola e'' nota');
  LHost.Detach;
end;

procedure TTestWarMapUiUnits.DovrebbeToglierDallaSelezioneUnaEntitaChePerde;
var
  LWorld: TObject;
  LContext: TWarModelContext;
  LObject: TWarMapHost;
  LHost: IWarMapHost;
  LFog: TWarFogOfWar;
begin
  LContext := NewContext(TCountingRandom.Create, LWorld);
  LFog := TWarFogOfWar.Create;
  LObject := TWarMapHost.Create(nil);
  LHost := LObject;
  try
    LContext.Selection.Add(7);
    LContext.Selection.Add(8);
    LHost.Attach(LContext.Selection, LFog, nil);
    (LObject as IWarModelEvents).EntityLeftSelection(7);
    Assert.AreEqual(1, LContext.Selection.Count);
    Assert.AreEqual<Word>(8, LContext.Selection[0]);
    // with the fog on a tile that nobody saw is not known
    Assert.IsFalse(LObject.IsTileKnown(5, 5));
    Assert.AreEqual(0, LObject.UnitFrames(WAR_UNIT_FOOTMAN), 'senza gli sprite nessun fotogramma');
    Assert.AreEqual(0, LObject.ConstructionFrames(WAR_UNIT_FARM_HUMANS));
    LHost.Detach;
    (LObject as IWarModelEvents).EntityLeftSelection(8);
    Assert.AreEqual(1, LContext.Selection.Count, 'staccato non tocca la selezione');
  finally
    LHost := nil;
    LFog.Free;
    LWorld.Free;
  end;
end;

procedure TTestWarMapUiUnits.DovrebbeFareEntitaESceglierePerLeSelezioniEIlRiconoscimento;
var
  LWorld: TObject;
  LContext: TWarModelContext;
  LRandom: TCountingRandom;
  LRandomRef: IWarRandom;
  LAudio: IWarMapAudio;
  LBefore: Integer;
begin
  LRandom := TCountingRandom.Create;
  LRandomRef := LRandom;
  LContext := NewContext(LRandomRef, LWorld);
  try
    LContext.Players[0]^.Race := wraHumans;
    LContext.Players[1]^.Race := wraOrcs;
    LAudio := TWarMapAudio.Create(LContext, TWarSoundFactory.CreatePicker(LRandomRef), LRandomRef);
    LBefore := LContext.Pool.EntityCount;
    // a sound is an entity and draws nothing; a random one draws
    LAudio.PlaySound(485);
    Assert.AreEqual(LBefore + 1, LContext.Pool.EntityCount);
    Assert.AreEqual(0, LRandom.Calls);
    LAudio.PlayRandomSound(520, 524);
    Assert.AreEqual(LBefore + 2, LContext.Pool.EntityCount);
    Assert.AreEqual(1, LRandom.Calls);
    // the answer to an order: once, then not again within 150 ms
    LContext.RealTime := 1;
    LAudio.Acknowledge(0);
    Assert.AreEqual(LBefore + 3, LContext.Pool.EntityCount);
    Assert.AreEqual(2, LRandom.Calls);
    LContext.RealTime := 1.05;
    LAudio.Acknowledge(0);
    Assert.AreEqual(LBefore + 3, LContext.Pool.EntityCount);
    LContext.RealTime := 1.2;
    LAudio.Acknowledge(1);
    Assert.AreEqual(LBefore + 4, LContext.Pool.EntityCount);
    // the sound of a building does not draw
    LAudio.BuildingSelected(1);
    Assert.AreEqual(LBefore + 5, LContext.Pool.EntityCount);
  finally
    LAudio := nil;
    LWorld.Free;
  end;
end;

procedure TTestWarMapUiUnits.DovrebbeDareSempreLoStessoSpriteDiUnRecord;
var
  LFake: TFakeUiSprites;
  LFakeRef: IWarUiSprites;
  LSprites: TWarMapSprites;
  LA: IWarUiSprite;
  LB: IWarUiSprite;
  LPixels: TBytes;
begin
  LFake := TFakeUiSprites.Create;
  LFakeRef := LFake;
  SetLength(LPixels, 512 * 256 * 4);
  LSprites := TWarMapSprites.Create(LFakeRef, LPixels);
  try
    Assert.AreEqual<Integer>(512, LSprites.Tileset.Width);
    Assert.AreEqual<Integer>(16, LSprites.Black.Width);
    Assert.AreEqual<Integer>(255, LSprites.Black.Pixels[3], 'la tegola nera e'' opaca');
    Assert.AreEqual<Integer>(0, LSprites.Black.Pixels[0]);
    Assert.AreEqual<Integer>(64, LSprites.Minimap.Width);
    LSprites.SetMinimapPixels(TBytes.Create(1, 2, 3, 4));
    Assert.AreEqual(4, Length(LSprites.Minimap.Pixels));
    LA := LSprites.Get(300);
    LB := LSprites.Get(300);
    Assert.IsTrue(LA = LB, 'lo stesso oggetto');
    Assert.AreEqual(1, LFake.Created.Count, 'creato una volta sola');
    Assert.IsTrue(LSprites.Get(301) <> LA);
  finally
    LSprites.Free;
  end;
end;

procedure TTestWarMapUiUnits.DovrebbeSvuotareIlPannelloDeiComandi;
var
  LPanel: TWarCommandPanel;
begin
  LPanel := Default(TWarCommandPanel);
  LPanel.SlotsActive[2] := True;
  LPanel.Slots[2].Tooltip := 'MOVE';
  LPanel.TextsVisible[1] := True;
  LPanel.Texts[1] := 'GOLD LEFT';
  LPanel.Clear;
  Assert.IsFalse(LPanel.SlotsActive[2]);
  Assert.AreEqual('', string(LPanel.Slots[2].Tooltip));
  Assert.IsFalse(LPanel.TextsVisible[1]);
  Assert.AreEqual('', string(LPanel.Texts[1]));
  Assert.AreEqual(WAR_NO_HIGHLIGHT, LPanel.TextsHighlightIndex[3]);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestWarMapUiUnits);

end.
