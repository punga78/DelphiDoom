{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - the drawing and the selection on a    }
{  small map made in memory                                                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.MapUiWorld;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.War.Render.Types, DelphiDoom.War.Render.Blitter,
  DelphiDoom.War.Render.Transform, DelphiDoom.War.Map.Game, DelphiDoom.War.Map.Factory, DelphiDoom.War.Model.MapBinding,
  DelphiDoom.War.Ui.Intf, DelphiDoom.War.MapUi.Camera, DelphiDoom.War.MapUi.Sprites, DelphiDoom.War.MapUi.Renderer,
  DelphiDoom.War.Ui.Types, DelphiDoom.War.MapUi.Intf, DelphiDoom.Tests.War.UiFakes;

type
  /// <summary>Collects the drawing calls that reach the canvas, one line each, as the harness of the C writes them</summary>
  TTraceCollector = class(TInterfacedObject, IWarRenderTrace)
  public
    Lines: TStringList;
    constructor Create;
    destructor Destroy; override;
    procedure TraceBlit(const ABlit: TWarBlit);
    procedure TraceRect(const ARect: TWarRectF; const AColor: TWarRgba; AStroke: Boolean);
  end;

  /// <summary>An input for the mouse: the left button held, just pressed or just released, Control, and the position</summary>
  TSelectInput = class(TInterfacedObject, IWarUiInput)
  public
    X: Single;
    Y: Single;
    Held: Boolean;
    Pressed: Boolean;
    Released: Boolean;
    CtrlHeld: Boolean;
    function IsButtonHeld(AButton: TWarMouseButton): Boolean;
    function IsButtonJustPressed(AButton: TWarMouseButton): Boolean;
    function IsButtonJustReleased(AButton: TWarMouseButton): Boolean;
    function IsKeyHeld(AKey: TWarKey): Boolean;
    function IsKeyJustPressed(AKey: TWarKey): Boolean;
    function IsKeyJustReleased(AKey: TWarKey): Boolean;
    function GetPositionX: Single;
    function GetPositionY: Single;
  end;

  /// <summary>Counts what the selection asks of the audio</summary>
  TCountingAudio = class(TInterfacedObject, IWarMapAudio)
  public
    Dudes: Integer;
    Buildings: Integer;
    Clicks: Integer;
    procedure PlaySound(AAudioId: Integer);
    procedure PlayRandomSound(AFromId, AToId: Integer);
    procedure Acknowledge(APlayer: Integer);
    procedure DudeSelected(ASlot: Integer);
    procedure BuildingSelected(ASlot: Integer);
  end;

  [TestFixture]
  [Category('war')]
  TTestWarMapUiWorld = class(TObject)
  strict private
    FBinding: TWarMapBinding;
    FMap: TWarGameMap;
    FCamera: TWarMapCamera;
    FSprites: TWarMapSprites;
    FSpritesSource: IWarUiSprites;
    FTarget: TWarImageBlitter;
    FTransform: TWarRenderTransform;
    FRenderer: TWarMapRenderer;
    FTrace: TTraceCollector;
    FTraceRef: IWarRenderTrace;
    function UnitSlot(AUnitType: Integer; APlayer: Integer): Integer;
    procedure Build(ATilesetType: Word);
    function CountLines(const APrefix: string): Integer;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeDisegnareIMuriSecondoLaVita;
    [Test]
    procedure DovrebbeUsareITileDellaPaludeSeIlTerrenoELaPalude;
    [Test]
    procedure DovrebbeDisegnareLeRovine;
    [Test]
    procedure DovrebbeDisegnareLeUnitaInvisibiliEInvulnerabili;
    [Test]
    procedure DovrebbeColorareLaSelezioneSecondoChiPossiedeLUnita;
    [Test]
    procedure DovrebbeOrdinareSulPostoLeUnitaEIProiettili;
    [Test]
    procedure DovrebbeTrovareCiCheStaSottoIlMouse;
    [Test]
    procedure DovrebbeSelezionareConIlClicELaMusicaDeiSuoni;
    [Test]
    procedure DovrebbeSelezionareConIlRettangoloEConCtrl;
  end;

implementation

uses
  DelphiDoom.War.Types, DelphiDoom.War.Level.Types, DelphiDoom.War.Model.Types, DelphiDoom.War.Model.Factory,
  DelphiDoom.War.Model.Context, DelphiDoom.War.Model.Construction.Types, DelphiDoom.War.Sound.SeededRandom,
  DelphiDoom.War.Autotile.Data, DelphiDoom.War.Map.Types, DelphiDoom.War.Map.Builder, DelphiDoom.War.MapUi.Types,
  DelphiDoom.War.MapUi.Picker, DelphiDoom.War.MapUi.Selecting, DelphiDoom.War.Sound.Ids,
  DelphiDoom.Tests.War.MapSupport;

{ TTraceCollector }

constructor TTraceCollector.Create;
begin
  inherited Create;
  Lines := TStringList.Create;
end;

destructor TTraceCollector.Destroy;
begin
  Lines.Free;
  inherited Destroy;
end;

procedure TTraceCollector.TraceBlit(const ABlit: TWarBlit);
begin
  Lines.Add(Format('T %d %d > %d %d a%d', [Round(ABlit.Source.X), Round(ABlit.Source.Y), Round(ABlit.Destination.X),
    Round(ABlit.Destination.Y), ABlit.Color.A]));
end;

procedure TTraceCollector.TraceRect(const ARect: TWarRectF; const AColor: TWarRgba; AStroke: Boolean);
begin
  if AStroke then
    Lines.Add(Format('S %d,%d,%d', [AColor.R, AColor.G, AColor.B]))
  else
    Lines.Add(Format('F %d,%d,%d', [AColor.R, AColor.G, AColor.B]));
end;

{ TTestWarMapUiWorld }

procedure TTestWarMapUiWorld.Setup;
begin
  FSpritesSource := TFakeUiSprites.Create;
end;

procedure TTestWarMapUiWorld.TearDown;
begin
  FRenderer.Free;
  FTransform.Free;
  FTarget.Free;
  FCamera.Free;
  FSprites.Free;
  FBinding.Free;
  FMap.Free;
  FTraceRef := nil;
  FSpritesSource := nil;
end;

procedure TTestWarMapUiWorld.Build(ATilesetType: Word);
var
  LInfo: TWarLevelInfo;
  LConstruct: TWarLevelConstruct;
  LBuilder: TWarMapBuilder;
  LPassable: TArray<Word>;
begin
  LInfo := TMapFixtures.BasicInfo;
  LInfo.TilesetType := ATilesetType;
  LInfo.StartEntities := [
    TMapFixtures.StartUnit(10, 10, WAR_UNIT_TOWNHALL_HUMANS, 0, wrkNone, 0),
    TMapFixtures.StartUnit(14, 10, WAR_UNIT_FOOTMAN, 0, wrkNone, 0),
    TMapFixtures.StartUnit(14, 12, WAR_UNIT_PEASANT, 0, wrkNone, 0),
    TMapFixtures.StartUnit(40, 40, WAR_UNIT_TOWNHALL_ORCS, 1, wrkNone, 0),
    TMapFixtures.StartUnit(42, 44, WAR_UNIT_GRUNT, 1, wrkNone, 0),
    TMapFixtures.StartUnit(20, 20, WAR_UNIT_GOLDMINE, 4, wrkGold, 10000)];
  LConstruct := Default(TWarLevelConstruct);
  LConstruct.ConstructType := wctRoad;
  LConstruct.X1 := 30;
  LConstruct.Y1 := 30;
  LConstruct.X2 := 33;
  LConstruct.Y2 := 30;
  LInfo.StartRoads := [LConstruct];
  LConstruct.ConstructType := wctWall;
  LConstruct.X1 := 50;
  LConstruct.Y1 := 50;
  LConstruct.X2 := 50;
  LConstruct.Y2 := 52;
  LInfo.StartWalls := [LConstruct];
  LPassable := TMapFixtures.EmptyPassable;
  TMapFixtures.PutWood(LPassable, 5, 5, 3, 3);
  LBuilder := TWarMapFactory.CreateBuilder;
  try
    FMap := LBuilder.Build(TMapFixtures.MakeLevel(LInfo, LPassable), TMapFixtures.Tileset);
  finally
    LBuilder.Free;
  end;
  FBinding := TWarModelFactory.CreateMapBinding(FMap, TWarSeededRandom.Create(1));
  // the whole map is in sight
  FMap.Fog.Enabled := False;
  FSprites := TWarMapSprites.Create(FSpritesSource, TMapFixtures.Tileset);
  FCamera := TWarMapCamera.Create(TWarMapPanels.Standard, 0, 0);
  FTarget := TWarImageBlitter.Create(320, 200);
  FTransform := TWarRenderTransform.Create(FTarget);
  FTrace := TTraceCollector.Create;
  FTraceRef := FTrace;
  FTransform.Trace := FTraceRef;
  FRenderer := TWarMapRenderer.Create(FTransform, FMap, FBinding.World.Context, FBinding.World.Machine, FSprites,
    FCamera);
end;

function TTestWarMapUiWorld.UnitSlot(AUnitType: Integer; APlayer: Integer): Integer;
var
  LIndex: Integer;
  LUnits: TArray<Integer>;
begin
  LUnits := FBinding.World.Context.Pool.OfType[WAR_ENTITY_UNIT].ToArray;
  for LIndex := 0 to High(LUnits) do
    if (FBinding.World.Context.Pool.Slots[LUnits[LIndex]]^.UnitData.UnitType = AUnitType) and
      (FBinding.World.Context.Pool.Slots[LUnits[LIndex]]^.UnitData.Player = APlayer) then
      Exit(LUnits[LIndex]);
  Result := 0;
end;

function TTestWarMapUiWorld.CountLines(const APrefix: string): Integer;
var
  LLine: string;
begin
  Result := 0;
  for LLine in FTrace.Lines do
    if LLine.StartsWith(APrefix) then
      Inc(Result);
end;

procedure TTestWarMapUiWorld.DovrebbeDisegnareIMuriSecondoLaVita;
var
  LWalls: TObject;
  LContext: TWarModelContext;
  LExpected: string;
  LPiece: Integer;
begin
  Build(WAR_TILESET_FOREST);
  LContext := FBinding.World.Context;
  Assert.IsTrue(LContext.Walls.Count >= 3);
  // whole, damaged (under half), destroyed
  LContext.Walls[1]^.Hp := 20;
  LContext.Walls[2]^.Hp := 0;
  FRenderer.RenderEntitiesOfType(WAR_ENTITY_WALL);
  for LPiece := 0 to 2 do
  begin
    case LPiece of
      0: LExpected := Format('T %d %d', [(WAR_WALL_DATA[LContext.Walls[0]^.PieceType].Forest mod 32) * 16,
           (WAR_WALL_DATA[LContext.Walls[0]^.PieceType].Forest div 32) * 16]);
      1: LExpected := Format('T %d %d', [(WAR_WALL_DATA[LContext.Walls[1]^.PieceType].DamagedForest mod 32) * 16,
           (WAR_WALL_DATA[LContext.Walls[1]^.PieceType].DamagedForest div 32) * 16]);
    else
      LExpected := Format('T %d %d', [(WAR_WALL_DATA[LContext.Walls[2]^.PieceType].DestroyedForest mod 32) * 16,
        (WAR_WALL_DATA[LContext.Walls[2]^.PieceType].DestroyedForest div 32) * 16]);
    end;
    Assert.IsTrue(FTrace.Lines[LPiece].StartsWith(LExpected), Format('pezzo %d: "%s" voleva "%s"', [LPiece,
      FTrace.Lines[LPiece], LExpected]));
  end;
  LWalls := nil;
  Assert.IsNull(LWalls);
end;

procedure TTestWarMapUiWorld.DovrebbeUsareITileDellaPaludeSeIlTerrenoELaPalude;
var
  LContext: TWarModelContext;
  LPiece: PWarWallPiece;
begin
  Build(WAR_TILESET_SWAMP);
  LContext := FBinding.World.Context;
  LPiece := LContext.Walls[0];
  FRenderer.RenderEntitiesOfType(WAR_ENTITY_WALL);
  FRenderer.RenderEntitiesOfType(WAR_ENTITY_ROAD);
  Assert.IsTrue(FTrace.Lines[0].StartsWith(Format('T %d %d', [(WAR_WALL_DATA[LPiece^.PieceType].Swamp mod 32) * 16,
    (WAR_WALL_DATA[LPiece^.PieceType].Swamp div 32) * 16])), 'il muro');
  LContext.Walls[0]^.Hp := 10;
  LContext.Walls[1]^.Hp := 0;
  FTrace.Lines.Clear;
  FRenderer.RenderEntitiesOfType(WAR_ENTITY_WALL);
  Assert.AreEqual(LContext.Walls.Count, FTrace.Lines.Count);
end;

procedure TTestWarMapUiWorld.DovrebbeDisegnareLeRovine;
var
  LContext: TWarModelContext;
begin
  Build(WAR_TILESET_FOREST);
  LContext := FBinding.World.Context;
  LContext.Ruins.AddSquare(30, 10, 2);
  LContext.Ruins.DetermineTypes;
  FRenderer.RenderEntitiesOfType(WAR_ENTITY_RUIN);
  Assert.IsTrue(FTrace.Lines.Count > 0, 'le rovine sono disegnate');
  FTrace.Lines.Clear;
  FRenderer.RenderEntitiesOfType(WAR_ENTITY_ROAD);
  Assert.AreEqual(LContext.Roads.Count, FTrace.Lines.Count, 'un tile per ogni pezzo di strada');
  // the forests do not draw: they write the tiles of their trees into the map
  FTrace.Lines.Clear;
  FRenderer.RenderEntitiesOfType(WAR_ENTITY_FOREST);
  Assert.AreEqual(0, FTrace.Lines.Count);
end;

procedure TTestWarMapUiWorld.DovrebbeDisegnareLeUnitaInvisibiliEInvulnerabili;
var
  LSlot: Integer;
begin
  Build(WAR_TILESET_FOREST);
  LSlot := UnitSlot(WAR_UNIT_FOOTMAN, 0);
  FBinding.World.Context.Pool.Slots[LSlot]^.UnitData.Invisible := True;
  FBinding.World.Context.Pool.Slots[LSlot]^.UnitData.Invulnerable := True;
  FRenderer.RenderEntitiesOfType(WAR_ENTITY_UNIT);
  Assert.AreEqual(1, CountLines('S 0,0,199'), 'il contorno blu dell''invulnerabile');
  Assert.IsTrue(CountLines('T') >= 6, 'ogni unita'' disegna uno sprite');
  Assert.IsTrue(FTrace.Lines.IndexOf('S 0,0,199') >= 0);
end;

procedure TTestWarMapUiWorld.DovrebbeColorareLaSelezioneSecondoChiPossiedeLUnita;
var
  LContext: TWarModelContext;
begin
  Build(WAR_TILESET_FOREST);
  LContext := FBinding.World.Context;
  LContext.Selection.Add(LContext.Pool.Slots[UnitSlot(WAR_UNIT_FOOTMAN, 0)]^.Id);
  LContext.Selection.Add(LContext.Pool.Slots[UnitSlot(WAR_UNIT_GRUNT, 1)]^.Id);
  LContext.Selection.Add(LContext.Pool.Slots[UnitSlot(WAR_UNIT_GOLDMINE, 4)]^.Id);
  FRenderer.RenderUnitSelection;
  Assert.AreEqual(1, CountLines('S 0,199,0'), 'verde: il mio');
  Assert.AreEqual(1, CountLines('S 199,0,0'), 'rosso: il nemico');
  Assert.AreEqual(1, CountLines('S 199,199,199'), 'bianco: nessuno');
  // an id that is not in the pool is skipped
  LContext.Selection.Add(4000);
  FTrace.Lines.Clear;
  FRenderer.RenderUnitSelection;
  Assert.AreEqual(3, FTrace.Lines.Count);
end;

procedure TTestWarMapUiWorld.DovrebbeOrdinareSulPostoLeUnitaEIProiettili;
var
  LContext: TWarModelContext;
  LFirst: Integer;
  LSecond: Integer;
  LThird: Integer;
  LUnits: TArray<Integer>;
  LIndex: Integer;
begin
  Build(WAR_TILESET_FOREST);
  LContext := FBinding.World.Context;
  // projectiles: by the y of the position, then by the id
  LFirst := LContext.Pool.CreateEntity(WAR_ENTITY_PROJECTILE, True);
  LSecond := LContext.Pool.CreateEntity(WAR_ENTITY_PROJECTILE, True);
  LThird := LContext.Pool.CreateEntity(WAR_ENTITY_PROJECTILE, True);
  LContext.Pool.Slots[LFirst]^.Position.Y := 50;
  LContext.Pool.Slots[LSecond]^.Position.Y := 10;
  LContext.Pool.Slots[LThird]^.Position.Y := 10;
  FRenderer.RenderEntitiesOfType(WAR_ENTITY_PROJECTILE);
  Assert.AreEqual(LSecond, LContext.Pool.OfType[WAR_ENTITY_PROJECTILE][0]);
  Assert.AreEqual(LThird, LContext.Pool.OfType[WAR_ENTITY_PROJECTILE][1]);
  Assert.AreEqual(LFirst, LContext.Pool.OfType[WAR_ENTITY_PROJECTILE][2]);
  // units: by y (the list of the pool is sorted in place), the same y by id
  FRenderer.RenderEntitiesOfType(WAR_ENTITY_UNIT);
  LUnits := LContext.Pool.OfType[WAR_ENTITY_UNIT].ToArray;
  for LIndex := 1 to High(LUnits) do
    Assert.IsTrue(LContext.Pool.Slots[LUnits[LIndex - 1]]^.Position.Y <= LContext.Pool.Slots[LUnits[LIndex]]^.Position.Y,
      'in ordine di y');
  // a unit that is dying goes first, whatever its y
  LContext.Pool.Slots[UnitSlot(WAR_UNIT_GRUNT, 1)]^.UnitData.UnitType := WAR_UNIT_ORC_CORPSE;
  FRenderer.RenderEntitiesOfType(WAR_ENTITY_UNIT);
  Assert.AreEqual(WAR_UNIT_ORC_CORPSE, LContext.Pool.Slots[LContext.Pool.OfType[WAR_ENTITY_UNIT][0]]^.UnitData.UnitType);
end;

procedure TTestWarMapUiWorld.DovrebbeTrovareCiCheStaSottoIlMouse;
var
  LPicker: TWarMapPicker;
  LSlot: Integer;
  LContext: TWarModelContext;
  LPiece: PWarWallPiece;
begin
  Build(WAR_TILESET_FOREST);
  LContext := FBinding.World.Context;
  LPicker := TWarMapPicker.Create(FMap, LContext, FBinding.World.Machine);
  try
    // the footman at the tile (14, 10)
    Assert.AreEqual(WAR_ENTITY_UNIT, LPicker.Find(14 * 16 + 2, 10 * 16 + 2, False, False, LSlot));
    Assert.AreEqual(UnitSlot(WAR_UNIT_FOOTMAN, 0), LSlot);
    // a tree (the wood of the tile (5, 5)) only if trees are asked for
    Assert.AreEqual(WAR_ENTITY_NONE, LPicker.Find(5 * 16 + 2, 5 * 16 + 2, False, False, LSlot));
    Assert.AreEqual(WAR_ENTITY_FOREST, LPicker.Find(5 * 16 + 2, 5 * 16 + 2, True, False, LSlot));
    // a wall that stands, and a wall that does not
    LPiece := LContext.Walls[0];
    Assert.AreEqual(WAR_ENTITY_WALL, LPicker.Find(LPiece^.TileX * 16 + 2, LPiece^.TileY * 16 + 2, False, True, LSlot));
    Assert.AreEqual(WAR_ENTITY_NONE, LPicker.Find(LPiece^.TileX * 16 + 2, LPiece^.TileY * 16 + 2, False, False, LSlot));
    LPiece^.Hp := 0;
    Assert.AreEqual(WAR_ENTITY_NONE, LPicker.Find(LPiece^.TileX * 16 + 2, LPiece^.TileY * 16 + 2, False, True, LSlot));
    // with the fog on a unit that nobody sees is not there; a dying unit neither
    FMap.Fog.Enabled := True;
    Assert.AreEqual(WAR_ENTITY_NONE, LPicker.Find(14 * 16 + 2, 10 * 16 + 2, False, False, LSlot));
    FMap.Fog.Enabled := False;
    LContext.Pool.Slots[UnitSlot(WAR_UNIT_FOOTMAN, 0)]^.UnitData.UnitType := WAR_UNIT_HUMAN_CORPSE;
    Assert.AreEqual(WAR_ENTITY_NONE, LPicker.Find(14 * 16 + 2, 10 * 16 + 2, False, False, LSlot));
  finally
    LPicker.Free;
  end;
end;

procedure TTestWarMapUiWorld.DovrebbeSelezionareConIlClicELaMusicaDeiSuoni;
var
  LInput: TSelectInput;
  LInputRef: IWarUiInput;
  LAudio: TCountingAudio;
  LAudioRef: IWarMapAudio;
  LSelecting: TWarMapSelecting;
  LPicker: TWarMapPicker;
  LContext: TWarModelContext;

  procedure Click(AX, AY: Single);
  begin
    LInput.X := AX;
    LInput.Y := AY;
    LInput.Pressed := True;
    LInput.Held := True;
    LSelecting.UpdateDragRect(LInputRef);
    LInput.Pressed := False;
    LInput.Released := True;
    LInput.Held := False;
    LSelecting.UpdateDragRect(LInputRef);
    LSelecting.UpdateSelection(LInputRef);
    LInput.Released := False;
    // the frame after: the drag is over
    LSelecting.UpdateDragRect(LInputRef);
  end;

begin
  Build(WAR_TILESET_FOREST);
  LContext := FBinding.World.Context;
  LInput := TSelectInput.Create;
  LInputRef := LInput;
  LAudio := TCountingAudio.Create;
  LAudioRef := LAudio;
  FCamera.X := 150;
  FCamera.Y := 100;
  LPicker := TWarMapPicker.Create(FMap, LContext, FBinding.World.Machine);
  LSelecting := TWarMapSelecting.Create(FMap, LContext, FBinding.World.Machine, FCamera, LPicker,
    FBinding.Commands.Selecting, LAudioRef);
  try
    // my footman at (146, 72): a unit of mine is heard
    Click(150, 76);
    Assert.AreEqual(1, LContext.Selection.Count, 'il fante');
    Assert.AreEqual(1, LAudio.Dudes, 'il suono del fante');
    // the grunt of the enemy: a click
    FCamera.X := 500;
    FCamera.Y := 550;
    Click(244 + 2, 166 + 2);
    FCamera.X := 150;
    FCamera.Y := 100;
    Assert.AreEqual(1, LContext.Selection.Count, 'il nemico');
    Assert.AreEqual(1, LAudio.Clicks, 'il clic');
    // my town hall: a building of mine is heard
    Click(90, 80);
    Assert.AreEqual(1, LAudio.Buildings, 'il municipio');
    // nothing: the selection is cleared
    Click(200, 30);
    Assert.AreEqual(0, LContext.Selection.Count);
    // Control and the same unit twice: it is selected once
    LInput.CtrlHeld := True;
    Click(150, 76);
    Click(150, 76);
    Assert.AreEqual(1, LContext.Selection.Count);
    // the click that gave an order does not select when the button is released
    LInput.CtrlHeld := False;
    LSelecting.SuppressOnRelease := True;
    Click(90, 80);
    Assert.AreEqual(1, LContext.Selection.Count, 'la selezione non e'' cambiata');
    Assert.IsFalse(LSelecting.SuppressOnRelease);
  finally
    LSelecting.Free;
    LPicker.Free;
  end;
end;

procedure TTestWarMapUiWorld.DovrebbeSelezionareConIlRettangoloEConCtrl;
var
  LInput: TSelectInput;
  LInputRef: IWarUiInput;
  LSelecting: TWarMapSelecting;
  LPicker: TWarMapPicker;
  LContext: TWarModelContext;
begin
  Build(WAR_TILESET_FOREST);
  LContext := FBinding.World.Context;
  LInput := TSelectInput.Create;
  LInputRef := LInput;
  FCamera.X := 150;
  FCamera.Y := 100;
  LPicker := TWarMapPicker.Create(FMap, LContext, FBinding.World.Machine);
  LSelecting := TWarMapSelecting.Create(FMap, LContext, FBinding.World.Machine, FCamera, LPicker,
    FBinding.Commands.Selecting, nil);
  try
    // a rectangle over the town hall, the footman and the peasant: the units only
    LInput.X := 80;
    LInput.Y := 60;
    LInput.Pressed := True;
    LInput.Held := True;
    LSelecting.UpdateDragRect(LInputRef);
    LInput.Pressed := False;
    LInput.X := 200;
    LInput.Y := 130;
    LSelecting.UpdateDragRect(LInputRef);
    Assert.IsTrue(LSelecting.IsDragging);
    Assert.AreEqual<Single>(120, LSelecting.DragRect.Width);
    LInput.Held := False;
    LInput.Released := True;
    LSelecting.UpdateDragRect(LInputRef);
    LSelecting.UpdateSelection(LInputRef);
    Assert.AreEqual(2, LContext.Selection.Count);
    // a rectangle over the town hall alone: the building
    LInput.Released := False;
    LSelecting.UpdateDragRect(LInputRef);
    LInput.X := 82;
    LInput.Y := 75;
    LInput.Pressed := True;
    LInput.Held := True;
    LSelecting.UpdateDragRect(LInputRef);
    LInput.Pressed := False;
    LInput.X := 125;
    LInput.Y := 119;
    LSelecting.UpdateDragRect(LInputRef);
    LInput.Held := False;
    LInput.Released := True;
    LSelecting.UpdateDragRect(LInputRef);
    LSelecting.UpdateSelection(LInputRef);
    Assert.AreEqual(1, LContext.Selection.Count);
    // while the camera scrolls the drag is cancelled
    FCamera.IsScrolling := True;
    LSelecting.UpdateDragRect(LInputRef);
    Assert.IsFalse(LSelecting.IsDragging);
  finally
    LSelecting.Free;
    LPicker.Free;
  end;
end;

{ TSelectInput }

function TSelectInput.IsButtonHeld(AButton: TWarMouseButton): Boolean;
begin
  Result := (AButton = wmbLeft) and Held;
end;

function TSelectInput.IsButtonJustPressed(AButton: TWarMouseButton): Boolean;
begin
  Result := (AButton = wmbLeft) and Pressed;
end;

function TSelectInput.IsButtonJustReleased(AButton: TWarMouseButton): Boolean;
begin
  Result := (AButton = wmbLeft) and Released;
end;

function TSelectInput.IsKeyHeld(AKey: TWarKey): Boolean;
begin
  Result := (AKey = wkCtrl) and CtrlHeld;
end;

function TSelectInput.IsKeyJustPressed(AKey: TWarKey): Boolean;
begin
  Result := False;
end;

function TSelectInput.IsKeyJustReleased(AKey: TWarKey): Boolean;
begin
  Result := False;
end;

function TSelectInput.GetPositionX: Single;
begin
  Result := X;
end;

function TSelectInput.GetPositionY: Single;
begin
  Result := Y;
end;

{ TCountingAudio }

procedure TCountingAudio.PlaySound(AAudioId: Integer);
begin
  if AAudioId = WAR_SND_UI_CLICK then
    Inc(Clicks);
end;

procedure TCountingAudio.PlayRandomSound(AFromId, AToId: Integer);
begin
end;

procedure TCountingAudio.Acknowledge(APlayer: Integer);
begin
end;

procedure TCountingAudio.DudeSelected(ASlot: Integer);
begin
  Inc(Dudes);
end;

procedure TCountingAudio.BuildingSelected(ASlot: Integer);
begin
  Inc(Buildings);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestWarMapUiWorld);

end.
