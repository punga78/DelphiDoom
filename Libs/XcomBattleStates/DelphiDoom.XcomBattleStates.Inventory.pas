{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom battlescape states library - the interactive view of the    }
{  inventory of a soldier (Inventory: grid, items, the item in the hand of      }
{  the player, moving, loading and unloading, stacking on the ground)           }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBattleStates.Inventory;

interface

uses
  DelphiDoom.Clock.Intf,
  System.SysUtils, System.Types, System.Generics.Collections, DelphiDoom.XcomSurface.Surface,
  DelphiDoom.XcomSurface.Font, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Intf,
  DelphiDoom.XcomEngine.Language, DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.Widget,
  DelphiDoom.XcomEngine.InteractiveSurface, DelphiDoom.XcomEngine.Timer, DelphiDoom.XcomUi.Text,
  DelphiDoom.XcomUi.NumberText,
  DelphiDoom.XcomMod.RuleInventory, DelphiDoom.XcomBattle.Model, DelphiDoom.XcomBattleStates.Graphics.Intf,
  DelphiDoom.XcomBattleStates.WarningMessage;

type
  /// <summary>The colors of the inventory, from the interfaces "inventory" and "battlescape" of the rules</summary>
  TXcomInventoryStyle = record
    /// <summary>inventory/grid: the lines of the slots</summary>
    GridColor: Byte;
    /// <summary>inventory/textSlots: the names of the sections</summary>
    SlotTextColor: Byte;
    /// <summary>inventory/numStack: the number of items stacked on the ground</summary>
    StackColor: Byte;
    /// <summary>battlescape/warning color2: the background of the warning</summary>
    WarningColor: Byte;
    /// <summary>battlescape/warning color: the text of the warning</summary>
    WarningTextColor: Byte;
  end;

  /// <summary>The two sounds of the inventory (Mod::ITEM_DROP and Mod::ITEM_RELOAD)</summary>
  TXcomInventorySound = (isDrop, isReload);

  TXcomInventorySoundHandler = reference to procedure(ASound: TXcomInventorySound);
  TXcomInventoryItemHandler = reference to procedure(AItem: TXcomBattleItem);

  /// <summary>
  ///   Interactive view of an inventory: lets the player see and manage the equipment of a soldier. It owns its
  ///   layers (grid, items, the item that follows the mouse), the warning and the timer of the primed grenades; the
  ///   unit, the items, the sections and the pictures are not its own. What the C++ asks to Game comes from the
  ///   constructor (clock, sections, pictures, translation, colors) and goes out through handlers (sounds, closing,
  ///   priming a grenade): nil handlers do nothing
  /// </summary>
  TXcomInventory = class(TXcomInteractiveSurface)
  strict private
    FInventories: TArray<TXcomRuleInventory>;
    FGraphics: IXcomBattleGraphics;
    FTranslate: TFunc<string, string>;
    FStyle: TXcomInventoryStyle;
    FGrid: TXcomWidget;
    FItems: TXcomWidget;
    FSelection: TXcomWidget;
    FStackLayer: TXcomWidget;
    FWarning: TXcomWarningMessage;
    FStackNumber: TXcomNumberText;
    FLabel: TXcomText;
    FAnimTimer: TXcomTimer;
    FSelUnit: TXcomBattleUnit;
    FSelItem: TXcomBattleItem;
    FMouseOverItem: TXcomBattleItem;
    FTimeUnits: Boolean;
    FBase: Boolean;
    FGroundOffset: Integer;
    FAnimFrame: Integer;
    FStackLevel: TDictionary<Int64, Integer>;
    FGrenadeIndicators: TList<TPoint>;
    FOnSound: TXcomInventorySoundHandler;
    FOnClose: TXcomNotify;
    FOnPrimeGrenade: TXcomInventoryItemHandler;
    class function StackKey(AX, AY: Integer): Int64; static; inline;
    procedure AddStackLevel(AX, AY, ADelta: Integer);
    function Section(const AId: string): TXcomRuleInventory;
    function SlotInPosition(var AX, AY: Integer): TXcomRuleInventory;
    function SpendTimeUnits(ACost: Integer): Boolean;
    procedure MoveItem(const AItem: TXcomBattleItem; const ASlot: TXcomRuleInventory; AX, AY: Integer);
    procedure DrawSlot(AX, AY, AWidth, AHeight: Integer);
    procedure BlitItem(const AItem: TXcomBattleItem; ATarget: TXcomSurface; AX, AY: Integer);
    procedure PlaySound(ASound: TXcomInventorySound);
    procedure Warn(const AId: string);
    procedure LeftClick(AMouseX, AMouseY: Integer; AControl: Boolean);
    procedure RightClick(AMouseX, AMouseY: Integer);
    procedure PickUpOrQuickMove(AMouseX, AMouseY: Integer; AControl: Boolean);
    procedure QuickMove(const AItem: TXcomBattleItem; const ASlot: TXcomRuleInventory);
    procedure DropSelected(AMouseX, AMouseY: Integer);
    procedure StackSelectedOn(const AItem: TXcomBattleItem; const ASlot: TXcomRuleInventory);
    procedure LoadSelectedInto(const AWeapon: TXcomBattleItem);
  protected
    procedure MouseOver(AAction: TXcomAction); override;
    procedure MouseClick(AAction: TXcomAction); override;
  public
    /// <param name="AInventories">Mod::getInventories: the sections in the order of their ids (a std::map)</param>
    /// <param name="AGraphics">BIGOBS.PCK and SCANG.DAT; a set that is missing draws nothing</param>
    /// <param name="ATranslate">Language::getString of an id</param>
    /// <param name="ABase">The inventory is called from the basescape</param>
    constructor Create(const AClock: IClock; const AInventories: TArray<TXcomRuleInventory>;
      const AGraphics: IXcomBattleGraphics; const ATranslate: TFunc<string, string>;
      const AStyle: TXcomInventoryStyle; AWidth, AHeight: Integer; AX: Integer = 0; AY: Integer = 0;
      ABase: Boolean = False);
    destructor Destroy; override;
    procedure SetPalette(AColors: PXcomColor; AFirst: Integer = 0; ACount: Integer = 256); override;
    procedure InitText(ABig, ASmall: TXcomFont; ALanguage: TXcomLanguage); override;
    /// <summary>setTuMode: when true the actions cost time units (battle), when false nothing (pre-equip)</summary>
    procedure SetTuMode(ATimeUnits: Boolean);
    /// <summary>setSelectedUnit: the unit whose inventory is shown; the ground is arranged again</summary>
    procedure SetSelectedUnit(const AUnit: TXcomBattleUnit);
    procedure Draw; override;
    /// <summary>drawGrid: the slots of every section and their names</summary>
    procedure DrawGrid;
    /// <summary>drawItems: the items of the soldier and of the ground, with the stack numbers</summary>
    procedure DrawItems;
    /// <summary>setSelectedItem: the item grabbed by the player (nil: none; a fixed weapon cannot be grabbed)</summary>
    procedure SetSelectedItem(const AItem: TXcomBattleItem);
    /// <summary>setMouseOverItem</summary>
    procedure SetMouseOverItem(const AItem: TXcomBattleItem);
    procedure Think; override;
    procedure Blit(ATarget: TXcomSurface); override;
    /// <summary>mouseOver without the handlers: the mouse is at this point of the screen (320x200)</summary>
    procedure Hover(AMouseX, AMouseY: Integer);
    /// <summary>
    ///   mouseClick without the handlers: a click of AButton at this point of the screen; the item in the hand is
    ///   dropped where the last Hover left it. AControl: the Ctrl key is down (quick move)
    /// </summary>
    procedure Click(AMouseX, AMouseY, AButton: Integer; AControl: Boolean = False);
    /// <summary>unload: the weapon in the hand of the player goes to the right hand and its clip to the left</summary>
    function Unload: Boolean;
    /// <summary>arrangeGround: gives a place to every item of the ground; AAlterOffset moves to the next page</summary>
    procedure ArrangeGround(AAlterOffset: Boolean = True);
    /// <summary>fitItem: puts the item in the first free place of the section; AWarning changes when the TUs are missing</summary>
    function FitItem(const ANewSlot: TXcomRuleInventory; const AItem: TXcomBattleItem; var AWarning: string): Boolean;
    /// <summary>canBeStacked: same rules, same ammunition, not primed, not a body, same charges</summary>
    class function CanBeStacked(const AItemA, AItemB: TXcomBattleItem): Boolean; static;
    /// <summary>showWarning: the text as it is (already translated)</summary>
    procedure ShowWarning(const AMessage: string);
    /// <summary>drawPrimers: the pulsing mark over every primed grenade (every 125 ms)</summary>
    procedure DrawPrimers;
    /// <summary>How many items are stacked at a place of the ground (_stackLevel)</summary>
    function StackLevel(AX, AY: Integer): Integer;
    /// <summary>The text of the warning shown last</summary>
    function WarningText: string;
    /// <summary>Whether the warning is on screen</summary>
    function WarningVisible: Boolean;
    /// <summary>getSelectedItem</summary>
    property SelectedItem: TXcomBattleItem read FSelItem;
    /// <summary>getMouseOverItem</summary>
    property MouseOverItem: TXcomBattleItem read FMouseOverItem;
    property SelectedUnit: TXcomBattleUnit read FSelUnit;
    /// <summary>The first column of the ground that is shown</summary>
    property GroundOffset: Integer read FGroundOffset;
    property OnSound: TXcomInventorySoundHandler read FOnSound write FOnSound;
    /// <summary>Game::popState: a right click with nothing in the hand closes the inventory of a battle</summary>
    property OnClose: TXcomNotify read FOnClose write FOnClose;
    /// <summary>pushState(new PrimeGrenadeState(0, true, item))</summary>
    property OnPrimeGrenade: TXcomInventoryItemHandler read FOnPrimeGrenade write FOnPrimeGrenade;
  end;

implementation

uses
  System.Math, DelphiDoom.XcomSurface.SurfaceSet, DelphiDoom.XcomSurface.Shade, DelphiDoom.XcomMod.MapBlock,
  DelphiDoom.XcomMod.RuleItem, DelphiDoom.XcomBattle.Types, DelphiDoom.XcomBattle.InventoryRules,
  DelphiDoom.XcomBattleStates.OffsetBlit;

const
  SCREEN_WIDTH = 320;
  SCREEN_HEIGHT = 200;
  SLOT_W = INV_SLOT_WIDTH;
  SLOT_H = INV_SLOT_HEIGHT;
  HAND_W = INV_HAND_WIDTH;
  HAND_H = INV_HAND_HEIGHT;
  PRIMER_INTERVAL = 125;
  PRIMER_FRAME = 6;
  LOAD_COST = 15;
  UNLOAD_COST = 8;
  FAR_AWAY = 1000000;
  SInventoryMissing = 'Xcom: the rules have no inventory section %s';

constructor TXcomInventory.Create(const AClock: IClock; const AInventories: TArray<TXcomRuleInventory>;
  const AGraphics: IXcomBattleGraphics; const ATranslate: TFunc<string, string>; const AStyle: TXcomInventoryStyle;
  AWidth, AHeight, AX, AY: Integer; ABase: Boolean);
begin
  inherited Create(AWidth, AHeight, AX, AY);
  FInventories := AInventories;
  FGraphics := AGraphics;
  FTranslate := ATranslate;
  FStyle := AStyle;
  FTimeUnits := True;
  FBase := ABase;
  FStackLevel := TDictionary<Int64, Integer>.Create;
  FGrenadeIndicators := TList<TPoint>.Create;
  FGrid := TXcomWidget.Create(AWidth, AHeight, 0, 0);
  FItems := TXcomWidget.Create(AWidth, AHeight, 0, 0);
  FStackLayer := TXcomWidget.Create(AWidth, AHeight, 0, 0);
  FSelection := TXcomWidget.Create(HAND_W * SLOT_W, HAND_H * SLOT_H, AX, AY);
  FWarning := TXcomWarningMessage.Create(AClock, 224, 24, 48, 176);
  FStackNumber := TXcomNumberText.Create(15, 15, 0, 0);
  FStackNumber.SetBordered(True);
  FLabel := TXcomText.Create(80, 9, 0, 0);
  FWarning.SetColor(AStyle.WarningColor);
  FWarning.SetTextColor(AStyle.WarningTextColor);
  FAnimTimer := TXcomTimer.Create(AClock, PRIMER_INTERVAL);
  FAnimTimer.OnTimerSurface(DrawPrimers);
  FAnimTimer.Start;
end;

destructor TXcomInventory.Destroy;
begin
  FAnimTimer.Free;
  FLabel.Free;
  FStackNumber.Free;
  FWarning.Free;
  FSelection.Free;
  FStackLayer.Free;
  FItems.Free;
  FGrid.Free;
  FGrenadeIndicators.Free;
  FStackLevel.Free;
  inherited Destroy;
end;

procedure TXcomInventory.SetPalette(AColors: PXcomColor; AFirst, ACount: Integer);
begin
  inherited SetPalette(AColors, AFirst, ACount);
  FGrid.SetPalette(AColors, AFirst, ACount);
  FItems.SetPalette(AColors, AFirst, ACount);
  FStackLayer.SetPalette(AColors, AFirst, ACount);
  FSelection.SetPalette(AColors, AFirst, ACount);
  FWarning.SetPalette(AColors, AFirst, ACount);
  FStackNumber.SetPalette(AColors, AFirst, ACount);
  FLabel.SetPalette(AColors, AFirst, ACount);
end;

procedure TXcomInventory.InitText(ABig, ASmall: TXcomFont; ALanguage: TXcomLanguage);
begin
  FWarning.InitText(ABig, ASmall, ALanguage);
  FLabel.InitText(ABig, ASmall, ALanguage);
end;

procedure TXcomInventory.SetTuMode(ATimeUnits: Boolean);
begin
  FTimeUnits := ATimeUnits;
end;

procedure TXcomInventory.SetSelectedUnit(const AUnit: TXcomBattleUnit);
begin
  FSelUnit := AUnit;
  FGroundOffset := 999;
  ArrangeGround;
end;

class function TXcomInventory.StackKey(AX, AY: Integer): Int64;
begin
  Result := Int64(AX) * 65536 + AY;
end;

function TXcomInventory.StackLevel(AX, AY: Integer): Integer;
begin
  if not FStackLevel.TryGetValue(StackKey(AX, AY), Result) then
    Result := 0;
end;

procedure TXcomInventory.AddStackLevel(AX, AY, ADelta: Integer);
begin
  FStackLevel.AddOrSetValue(StackKey(AX, AY), StackLevel(AX, AY) + ADelta);
end;

function TXcomInventory.Section(const AId: string): TXcomRuleInventory;
var
  LSection: TXcomRuleInventory;
begin
  for LSection in FInventories do
    if LSection.Id = AId then
      Exit(LSection);
  // Mod::getInventory(id, true) throws
  raise EXcomBattleException.CreateFmt(SInventoryMissing, [AId]);
end;

function TXcomInventory.SlotInPosition(var AX, AY: Integer): TXcomRuleInventory;
var
  LSection: TXcomRuleInventory;
  LSlot: TXcomRuleSlot;
begin
  // RuleInventory::checkSlotInPosition of every section, in the order of the ids
  for LSection in FInventories do
    case LSection.InventoryType of
      INV_HAND:
        if LSection.IsSlotInPosition(AX, AY) then
        begin
          AX := 0;
          AY := 0;
          Exit(LSection);
        end;
      INV_GROUND:
        if LSection.IsSlotInPosition(AX, AY) then
        begin
          AX := (AX - LSection.X) div SLOT_W;
          AY := (AY - LSection.Y) div SLOT_H;
          Exit(LSection);
        end;
    else
      for LSlot in LSection.Slots do
        if (AX >= LSection.X + LSlot.X * SLOT_W) and (AX < LSection.X + (LSlot.X + 1) * SLOT_W) and
          (AY >= LSection.Y + LSlot.Y * SLOT_H) and (AY < LSection.Y + (LSlot.Y + 1) * SLOT_H) then
        begin
          AX := LSlot.X;
          AY := LSlot.Y;
          Exit(LSection);
        end;
    end;
  Result := nil;
end;

function TXcomInventory.SpendTimeUnits(ACost: Integer): Boolean;
begin
  Result := (not FTimeUnits) or FSelUnit.SpendTimeUnits(ACost);
end;

procedure TXcomInventory.PlaySound(ASound: TXcomInventorySound);
begin
  if Assigned(FOnSound) then
    FOnSound(ASound);
end;

procedure TXcomInventory.Warn(const AId: string);
begin
  FWarning.ShowMessage(FTranslate(AId));
end;

procedure TXcomInventory.ShowWarning(const AMessage: string);
begin
  FWarning.ShowMessage(AMessage);
end;

function TXcomInventory.WarningText: string;
begin
  Result := FWarning.Text;
end;

function TXcomInventory.WarningVisible: Boolean;
begin
  Result := FWarning.Visible;
end;

procedure TXcomInventory.Draw;
begin
  Redraw := False;
  DrawGrid;
  DrawItems;
end;

procedure TXcomInventory.DrawSlot(AX, AY, AWidth, AHeight: Integer);
var
  LLeft, LTop, LRight, LBottom: Integer;
begin
  // SDL_FillRect leaves in the rectangle what it has drawn: the inside is computed from the clipped rectangle, so
  // the last column and the last row of the ground keep their line at the edge of the screen
  LLeft := Max(AX, 0);
  LTop := Max(AY, 0);
  LRight := Min(AX + AWidth, FGrid.Width);
  LBottom := Min(AY + AHeight, FGrid.Height);
  if (LRight <= LLeft) or (LBottom <= LTop) then
    Exit;
  FGrid.DrawRect(LLeft, LTop, LRight - LLeft, LBottom - LTop, FStyle.GridColor);
  if (LRight - LLeft > 2) and (LBottom - LTop > 2) then
    FGrid.DrawRect(LLeft + 1, LTop + 1, LRight - LLeft - 2, LBottom - LTop - 2, 0);
end;

procedure TXcomInventory.DrawGrid;
var
  LSection: TXcomRuleInventory;
  LSlot: TXcomRuleSlot;
  LX, LY: Integer;
  LFont: TXcomFont;
begin
  FGrid.Clear;
  FLabel.SetColor(FStyle.SlotTextColor);
  FLabel.SetHighContrast(True);
  for LSection in FInventories do
  begin
    case LSection.InventoryType of
      INV_SLOT:
        for LSlot in LSection.Slots do
          DrawSlot(LSection.X + SLOT_W * LSlot.X, LSection.Y + SLOT_H * LSlot.Y, SLOT_W + 1, SLOT_H + 1);
      INV_HAND:
        DrawSlot(LSection.X, LSection.Y, HAND_W * SLOT_W, HAND_H * SLOT_H);
      INV_GROUND:
        begin
          LX := LSection.X;
          while LX <= SCREEN_WIDTH do
          begin
            LY := LSection.Y;
            while LY <= SCREEN_HEIGHT do
            begin
              DrawSlot(LX, LY, SLOT_W + 1, SLOT_H + 1);
              Inc(LY, SLOT_H);
            end;
            Inc(LX, SLOT_W);
          end;
        end;
    end;
    // the name of the section over it
    LFont := FLabel.GetFont;
    if not Assigned(LFont) then
      Continue;
    FLabel.X := LSection.X;
    FLabel.Y := LSection.Y - LFont.Height - LFont.Spacing;
    FLabel.SetText(FTranslate(LSection.Id));
    FLabel.Blit(FGrid);
  end;
end;

procedure TXcomInventory.BlitItem(const AItem: TXcomBattleItem; ATarget: TXcomSurface; AX, AY: Integer);
var
  LSet: TXcomSurfaceSet;
  LFrame: TXcomSurface;
begin
  LSet := FGraphics.SurfaceSet('BIGOBS.PCK');
  if not Assigned(LSet) then
    Exit;
  LFrame := LSet.GetFrame(AItem.Rules.BigSprite);
  // the shaded blit takes the position of the target into account and copies the pixels as they are
  if Assigned(LFrame) then
    TXcomSurfaceShader.Blit(LFrame, ATarget, ATarget.X + AX, ATarget.Y + AY, 0);
end;

procedure TXcomInventory.DrawItems;
var
  LItem: TXcomBattleItem;
  LX, LY, LLevel: Integer;
begin
  FItems.Clear;
  FGrenadeIndicators.Clear;
  if not Assigned(FSelUnit) then
    Exit;
  // the items of the soldier
  for LItem in FSelUnit.Inventory do
  begin
    if (LItem = FSelItem) or (not Assigned(LItem.Slot)) then
      Continue;
    if LItem.Slot.InventoryType = INV_HAND then
    begin
      LX := LItem.Slot.X + (HAND_W - LItem.Rules.InventoryWidth) * SLOT_W div 2;
      LY := LItem.Slot.Y + (HAND_H - LItem.Rules.InventoryHeight) * SLOT_H div 2;
    end
    else
    begin
      LX := LItem.Slot.X + LItem.SlotX * SLOT_W;
      LY := LItem.Slot.Y + LItem.SlotY * SLOT_H;
    end;
    BlitItem(LItem, FItems, LX, LY);
    if LItem.FuseTimer >= 0 then
      FGrenadeIndicators.Add(Point(LX, LY));
  end;
  if not Assigned(FSelUnit.Tile) then
    Exit;
  FStackLayer.Clear;
  // the items of the ground
  for LItem in FSelUnit.Tile.Inventory do
  begin
    // an item can be made invisible by setting its width or height to 0 (the corpse of a tank)
    if (LItem = FSelItem) or (LItem.SlotX < FGroundOffset) or (LItem.Rules.InventoryHeight = 0) or
      (LItem.Rules.InventoryWidth = 0) or (not Assigned(LItem.Slot)) then
      Continue;
    LX := LItem.Slot.X + (LItem.SlotX - FGroundOffset) * SLOT_W;
    LY := LItem.Slot.Y + LItem.SlotY * SLOT_H;
    BlitItem(LItem, FItems, LX, LY);
    if LItem.FuseTimer >= 0 then
      FGrenadeIndicators.Add(Point(LX, LY));
    LLevel := StackLevel(LItem.SlotX, LItem.SlotY);
    if LLevel > 1 then
    begin
      FStackNumber.X := LItem.Slot.X + ((LItem.SlotX + LItem.Rules.InventoryWidth) - FGroundOffset) * SLOT_W - 4;
      if LLevel > 9 then
        FStackNumber.X := FStackNumber.X - 4;
      FStackNumber.Y := LItem.Slot.Y + (LItem.SlotY + LItem.Rules.InventoryHeight) * SLOT_H - 6;
      FStackNumber.SetValue(Cardinal(LLevel));
      FStackNumber.Draw;
      FStackNumber.SetColor(FStyle.StackColor);
      FStackNumber.Blit(FStackLayer);
    end;
  end;
  FStackLayer.Blit(FItems);
end;

procedure TXcomInventory.MoveItem(const AItem: TXcomBattleItem; const ASlot: TXcomRuleInventory; AX, AY: Integer);
begin
  // make items vanish (the ammunition in a weapon)
  if not Assigned(ASlot) then
  begin
    if AItem.Slot.InventoryType = INV_GROUND then
      FSelUnit.Tile.RemoveItem(AItem)
    else
      AItem.MoveToOwner(nil);
    Exit;
  end;
  // dropping from or to the ground
  if ASlot <> AItem.Slot then
  begin
    if ASlot.InventoryType = INV_GROUND then
    begin
      AItem.MoveToOwner(nil);
      FSelUnit.Tile.AddItem(AItem, AItem.Slot);
      if Assigned(AItem.CorpseUnit) and (AItem.CorpseUnit.Status = STATUS_UNCONSCIOUS) then
        AItem.CorpseUnit.SetPosition(FSelUnit.Position);
    end
    else if (not Assigned(AItem.Slot)) or (AItem.Slot.InventoryType = INV_GROUND) then
    begin
      AItem.MoveToOwner(FSelUnit);
      FSelUnit.Tile.RemoveItem(AItem);
      AItem.TurnFlag := False;
      if Assigned(AItem.CorpseUnit) and (AItem.CorpseUnit.Status = STATUS_UNCONSCIOUS) then
        AItem.CorpseUnit.SetPosition(TXcomPosition.Make(-1, -1, -1));
    end;
  end;
  AItem.Slot := ASlot;
  AItem.SlotX := AX;
  AItem.SlotY := AY;
end;

procedure TXcomInventory.SetSelectedItem(const AItem: TXcomBattleItem);
begin
  if Assigned(AItem) and (not AItem.Rules.FixedWeapon) then
    FSelItem := AItem
  else
    FSelItem := nil;
  FSelection.Clear;
  if Assigned(FSelItem) then
  begin
    if FSelItem.Slot.InventoryType = INV_GROUND then
      AddStackLevel(FSelItem.SlotX, FSelItem.SlotY, -1);
    // RuleItem::drawHandSprite: the big sprite in the middle of a hand
    BlitItem(FSelItem, FSelection, (HAND_W - FSelItem.Rules.InventoryWidth) * SLOT_W div 2,
      (HAND_H - FSelItem.Rules.InventoryHeight) * SLOT_H div 2);
  end;
  DrawItems;
end;

procedure TXcomInventory.SetMouseOverItem(const AItem: TXcomBattleItem);
begin
  if Assigned(AItem) and (not AItem.Rules.FixedWeapon) then
    FMouseOverItem := AItem
  else
    FMouseOverItem := nil;
end;

procedure TXcomInventory.Think;
begin
  FWarning.Think;
  FAnimTimer.Think(False, True);
end;

procedure TXcomInventory.Blit(ATarget: TXcomSurface);
begin
  Clear;
  FGrid.Blit(Self);
  FItems.Blit(Self);
  FSelection.Blit(Self);
  // the layers are drawn when they change, never by the blit
  Redraw := False;
  inherited Blit(ATarget);
  // the warning goes on the target after the inventory, not into it, so that its text is drawn at the resolution
  // of the screen (issue 188); the order over the layers is the same
  TXcomOffsetBlit.Blit(FWarning, ATarget, X, Y);
end;

procedure TXcomInventory.Hover(AMouseX, AMouseY: Integer);
var
  LX, LY: Integer;
  LSlot: TXcomRuleInventory;
begin
  FSelection.X := AMouseX - FSelection.Width div 2 - X;
  FSelection.Y := AMouseY - FSelection.Height div 2 - Y;
  if not Assigned(FSelUnit) then
    Exit;
  LX := AMouseX - X;
  LY := AMouseY - Y;
  LSlot := SlotInPosition(LX, LY);
  if Assigned(LSlot) then
  begin
    if LSlot.InventoryType = INV_GROUND then
      Inc(LX, FGroundOffset);
    SetMouseOverItem(FSelUnit.GetItem(LSlot, LX, LY));
  end
  else
    SetMouseOverItem(nil);
end;

procedure TXcomInventory.MouseOver(AAction: TXcomAction);
begin
  Hover(Floor(AAction.AbsoluteXMouse), Floor(AAction.AbsoluteYMouse));
  // the C++ leaves before the handlers when there is no unit
  if Assigned(FSelUnit) then
    inherited MouseOver(AAction);
end;

procedure TXcomInventory.MouseClick(AAction: TXcomAction);
begin
  // the C++ leaves before the handlers on a left click without a unit
  if (AAction.Details^.Button = XCOM_BUTTON_LEFT) and (not Assigned(FSelUnit)) then
    Exit;
  Click(Floor(AAction.AbsoluteXMouse), Floor(AAction.AbsoluteYMouse), AAction.Details^.Button,
    (AAction.Details^.Modifiers and XCOM_KMOD_CTRL) <> 0);
  inherited MouseClick(AAction);
end;

procedure TXcomInventory.Click(AMouseX, AMouseY, AButton: Integer; AControl: Boolean);
begin
  if AButton = XCOM_BUTTON_LEFT then
    LeftClick(AMouseX, AMouseY, AControl)
  else if AButton = XCOM_BUTTON_RIGHT then
    RightClick(AMouseX, AMouseY);
end;

procedure TXcomInventory.LeftClick(AMouseX, AMouseY: Integer; AControl: Boolean);
begin
  if not Assigned(FSelUnit) then
    Exit;
  if not Assigned(FSelItem) then
    PickUpOrQuickMove(AMouseX, AMouseY, AControl)
  else
    DropSelected(AMouseX, AMouseY);
end;

procedure TXcomInventory.PickUpOrQuickMove(AMouseX, AMouseY: Integer; AControl: Boolean);
var
  LX, LY: Integer;
  LSlot: TXcomRuleInventory;
  LItem: TXcomBattleItem;
begin
  LX := AMouseX - X;
  LY := AMouseY - Y;
  LSlot := SlotInPosition(LX, LY);
  if not Assigned(LSlot) then
    Exit;
  if LSlot.InventoryType = INV_GROUND then
    Inc(LX, FGroundOffset);
  LItem := FSelUnit.GetItem(LSlot, LX, LY);
  if (not Assigned(LItem)) or LItem.Rules.FixedWeapon then
    Exit;
  if AControl then
    QuickMove(LItem, LSlot)
  else
  begin
    SetSelectedItem(LItem);
    if LItem.FuseTimer >= 0 then
      Warn('STR_GRENADE_IS_ACTIVATED');
  end;
end;

procedure TXcomInventory.QuickMove(const AItem: TXcomBattleItem; const ASlot: TXcomRuleInventory);
var
  LNewSlot, LWildCard: TXcomRuleInventory;
  LWarning: string;
  LPlaced: Boolean;
begin
  LNewSlot := Section('STR_GROUND');
  LWarning := 'STR_NOT_ENOUGH_SPACE';
  LPlaced := False;
  if ASlot.InventoryType = INV_GROUND then
    case AItem.Rules.BattleType of
      TXcomRuleItem.BT_FIREARM:
        LNewSlot := Section('STR_RIGHT_HAND');
      TXcomRuleItem.BT_MINDPROBE, TXcomRuleItem.BT_PSIAMP, TXcomRuleItem.BT_MELEE, TXcomRuleItem.BT_CORPSE:
        LNewSlot := Section('STR_LEFT_HAND');
    else
      if AItem.Rules.InventoryHeight > 2 then
        LNewSlot := Section('STR_BACK_PACK')
      else
        LNewSlot := Section('STR_BELT');
    end;
  if LNewSlot.InventoryType <> INV_GROUND then
  begin
    AddStackLevel(AItem.SlotX, AItem.SlotY, -1);
    LPlaced := FitItem(LNewSlot, AItem, LWarning);
    if not LPlaced then
      for LWildCard in FInventories do
      begin
        if LWildCard.InventoryType = INV_GROUND then
          Continue;
        LPlaced := FitItem(LWildCard, AItem, LWarning);
        if LPlaced then
          Break;
      end;
    if not LPlaced then
      AddStackLevel(AItem.SlotX, AItem.SlotY, 1);
  end
  else if SpendTimeUnits(AItem.Slot.GetCost(LNewSlot)) then
  begin
    LPlaced := True;
    MoveItem(AItem, LNewSlot, 0, 0);
    PlaySound(isDrop);
    ArrangeGround(False);
  end
  else
    LWarning := 'STR_NOT_ENOUGH_TIME_UNITS';
  if not LPlaced then
    Warn(LWarning);
end;

procedure TXcomInventory.StackSelectedOn(const AItem: TXcomBattleItem; const ASlot: TXcomRuleInventory);
begin
  if SpendTimeUnits(FSelItem.Slot.GetCost(ASlot)) then
  begin
    MoveItem(FSelItem, ASlot, AItem.SlotX, AItem.SlotY);
    AddStackLevel(AItem.SlotX, AItem.SlotY, 1);
    SetSelectedItem(nil);
    PlaySound(isDrop);
  end
  else
    Warn('STR_NOT_ENOUGH_TIME_UNITS');
end;

procedure TXcomInventory.LoadSelectedInto(const AWeapon: TXcomBattleItem);
var
  LType: string;
  LWrong: Boolean;
  LClip: TXcomBattleItem;
begin
  LWrong := True;
  for LType in AWeapon.Rules.CompatibleAmmo do
    if LType = FSelItem.Rules.ItemType then
    begin
      LWrong := False;
      Break;
    end;
  if LWrong then
    Warn('STR_WRONG_AMMUNITION_FOR_THIS_WEAPON')
  else if Assigned(AWeapon.AmmoItem) then
    Warn('STR_WEAPON_IS_ALREADY_LOADED')
  else if SpendTimeUnits(LOAD_COST) then
  begin
    LClip := FSelItem;
    MoveItem(LClip, nil, 0, 0);
    AWeapon.SetAmmoItem(LClip);
    LClip.MoveToOwner(nil);
    SetSelectedItem(nil);
    PlaySound(isReload);
    if AWeapon.Slot.InventoryType = INV_GROUND then
      ArrangeGround(False);
  end
  else
    Warn('STR_NOT_ENOUGH_TIME_UNITS');
end;

procedure TXcomInventory.DropSelected(AMouseX, AMouseY: Integer);
var
  LX, LY: Integer;
  LSlot: TXcomRuleInventory;
  LItem: TXcomBattleItem;
  LCanStack: Boolean;
begin
  // the slot under the top left cell of the item, not under the mouse
  LX := FSelection.X + (HAND_W - FSelItem.Rules.InventoryWidth) * SLOT_W div 2 + SLOT_W div 2;
  LY := FSelection.Y + (HAND_H - FSelItem.Rules.InventoryHeight) * SLOT_H div 2 + SLOT_H div 2;
  LSlot := SlotInPosition(LX, LY);
  if Assigned(LSlot) then
  begin
    if LSlot.InventoryType = INV_GROUND then
      Inc(LX, FGroundOffset);
    LItem := FSelUnit.GetItem(LSlot, LX, LY);
    LCanStack := (LSlot.InventoryType = INV_GROUND) and CanBeStacked(LItem, FSelItem);
    // put the item in an empty slot, or stack it, if possible
    if (not Assigned(LItem)) or (LItem = FSelItem) or LCanStack then
    begin
      if (not TXcomInventoryRules.OverlapItems(FSelUnit, FSelItem, LSlot, LX, LY)) and
        LSlot.FitItemInSlot(FSelItem.Rules.InventoryWidth, FSelItem.Rules.InventoryHeight, LX, LY) then
      begin
        if SpendTimeUnits(FSelItem.Slot.GetCost(LSlot)) then
        begin
          MoveItem(FSelItem, LSlot, LX, LY);
          if LSlot.InventoryType = INV_GROUND then
            AddStackLevel(LX, LY, 1);
          SetSelectedItem(nil);
          PlaySound(isDrop);
        end
        else
          Warn('STR_NOT_ENOUGH_TIME_UNITS');
      end
      else if LCanStack then
        StackSelectedOn(LItem, LSlot);
    end
    // put the item in a weapon
    else if Length(LItem.Rules.CompatibleAmmo) > 0 then
      LoadSelectedInto(LItem);
    Exit;
  end;
  // try again with the position of the mouse, not of the item (more intuitive for stacking)
  LX := AMouseX - X;
  LY := AMouseY - Y;
  LSlot := SlotInPosition(LX, LY);
  if Assigned(LSlot) and (LSlot.InventoryType = INV_GROUND) then
  begin
    Inc(LX, FGroundOffset);
    LItem := FSelUnit.GetItem(LSlot, LX, LY);
    if CanBeStacked(LItem, FSelItem) then
      StackSelectedOn(LItem, LSlot);
  end;
end;

procedure TXcomInventory.RightClick(AMouseX, AMouseY: Integer);
var
  LX, LY: Integer;
  LSlot: TXcomRuleInventory;
  LItem: TXcomBattleItem;
begin
  if Assigned(FSelItem) then
  begin
    // the item goes back where it was
    if FSelItem.Slot.InventoryType = INV_GROUND then
      AddStackLevel(FSelItem.SlotX, FSelItem.SlotY, 1);
    SetSelectedItem(nil);
    Exit;
  end;
  // Options::includePrimeStateInSavedLayout is not ported: from the base nothing happens
  if FBase then
    Exit;
  if FTimeUnits then
  begin
    // closes the inventory window (not in the equip screen before the battle)
    if Assigned(FOnClose) then
      FOnClose();
    Exit;
  end;
  if not Assigned(FSelUnit) then
    Exit;
  LX := AMouseX - X;
  LY := AMouseY - Y;
  LSlot := SlotInPosition(LX, LY);
  if not Assigned(LSlot) then
    Exit;
  if LSlot.InventoryType = INV_GROUND then
    Inc(LX, FGroundOffset);
  LItem := FSelUnit.GetItem(LSlot, LX, LY);
  if (not Assigned(LItem)) or (not (LItem.Rules.BattleType in [TXcomRuleItem.BT_GRENADE,
    TXcomRuleItem.BT_PROXIMITYGRENADE])) then
    Exit;
  if LItem.FuseTimer = -1 then
  begin
    // prime that grenade
    if LItem.Rules.BattleType = TXcomRuleItem.BT_PROXIMITYGRENADE then
    begin
      Warn('STR_GRENADE_IS_ACTIVATED');
      LItem.FuseTimer := 0;
      ArrangeGround(False);
    end
    else if Assigned(FOnPrimeGrenade) then
      FOnPrimeGrenade(LItem);
  end
  else
  begin
    Warn('STR_GRENADE_IS_DEACTIVATED');
    LItem.FuseTimer := -1;
    ArrangeGround(False);
  end;
end;

function TXcomInventory.Unload: Boolean;
var
  LItem, LWeapon, LClip: TXcomBattleItem;
begin
  // must be holding an item
  if not Assigned(FSelItem) then
    Exit(False);
  LWeapon := FSelItem;
  // the item must be loaded
  if (not Assigned(LWeapon.AmmoItem)) and (Length(LWeapon.Rules.CompatibleAmmo) > 0) then
    Warn('STR_NO_AMMUNITION_LOADED');
  if (not Assigned(LWeapon.AmmoItem)) or (not LWeapon.NeedsAmmo) then
    Exit(False);
  // the hands must be free
  for LItem in FSelUnit.Inventory do
    if Assigned(LItem.Slot) and (LItem.Slot.InventoryType = INV_HAND) and (LItem <> LWeapon) then
    begin
      Warn('STR_BOTH_HANDS_MUST_BE_EMPTY');
      Exit(False);
    end;
  if not SpendTimeUnits(UNLOAD_COST) then
  begin
    Warn('STR_NOT_ENOUGH_TIME_UNITS');
    Exit(False);
  end;
  LClip := LWeapon.AmmoItem;
  MoveItem(LClip, Section('STR_LEFT_HAND'), 0, 0);
  LClip.MoveToOwner(FSelUnit);
  MoveItem(LWeapon, Section('STR_RIGHT_HAND'), 0, 0);
  LWeapon.MoveToOwner(FSelUnit);
  LWeapon.SetAmmoItem(nil);
  SetSelectedItem(nil);
  Result := True;
end;

procedure TXcomInventory.ArrangeGround(AAlterOffset: Boolean);
var
  LGround: TXcomRuleInventory;
  LSlotsX, LSlotsY, LX, LY, LXd, LYd, LXMax: Integer;
  LOk: Boolean;
  LItem, LOther: TXcomBattleItem;
begin
  LGround := Section('STR_GROUND');
  LSlotsX := (SCREEN_WIDTH - LGround.X) div SLOT_W;
  LSlotsY := (SCREEN_HEIGHT - LGround.Y) div SLOT_H;
  LXMax := 0;
  FStackLevel.Clear;
  if Assigned(FSelUnit) and Assigned(FSelUnit.Tile) then
  begin
    // first move all items out of the way: a big number in the X direction
    for LItem in FSelUnit.Tile.Inventory do
    begin
      LItem.Slot := LGround;
      LItem.SlotX := FAR_AWAY;
      LItem.SlotY := 0;
    end;
    // now for each item find the most top left position that is not occupied and will fit
    for LItem in FSelUnit.Tile.Inventory do
    begin
      LX := 0;
      LY := 0;
      repeat
        // assume the item can be put here: if one of the following checks fails, it cannot
        LOk := True;
        LXd := 0;
        while (LXd < LItem.Rules.InventoryWidth) and LOk do
        begin
          if (LX + LXd) mod LSlotsX < LX mod LSlotsX then
            LOk := False
          else
          begin
            LYd := 0;
            while (LYd < LItem.Rules.InventoryHeight) and LOk do
            begin
              LOther := FSelUnit.GetItem(LGround, LX + LXd, LY + LYd);
              LOk := (not Assigned(LOther)) or CanBeStacked(LOther, LItem);
              Inc(LYd);
            end;
          end;
          Inc(LXd);
        end;
        if LOk then
        begin
          LItem.SlotX := LX;
          LItem.SlotY := LY;
          // only increase the stack level if the item is actually visible
          if LItem.Rules.InventoryWidth <> 0 then
            AddStackLevel(LX, LY, 1);
          LXMax := Max(LXMax, LX + LItem.Rules.InventoryWidth);
        end
        else
        begin
          Inc(LY);
          if LY > LSlotsY - LItem.Rules.InventoryHeight then
          begin
            LY := 0;
            Inc(LX);
          end;
        end;
      until LOk;
    end;
  end;
  if AAlterOffset then
  begin
    if LXMax >= FGroundOffset + LSlotsX then
      Inc(FGroundOffset, LSlotsX)
    else
      FGroundOffset := 0;
  end;
  DrawItems;
end;

function TXcomInventory.FitItem(const ANewSlot: TXcomRuleInventory; const AItem: TXcomBattleItem;
  var AWarning: string): Boolean;
var
  LSlot: TXcomRuleSlot;
  LMaxX, LMaxY, LX, LY: Integer;
begin
  Result := False;
  LMaxX := 0;
  LMaxY := 0;
  for LSlot in ANewSlot.Slots do
  begin
    LMaxX := Max(LMaxX, LSlot.X);
    LMaxY := Max(LMaxY, LSlot.Y);
  end;
  for LY := 0 to LMaxY do
    for LX := 0 to LMaxX do
      if (not TXcomInventoryRules.OverlapItems(FSelUnit, AItem, ANewSlot, LX, LY)) and
        ANewSlot.FitItemInSlot(AItem.Rules.InventoryWidth, AItem.Rules.InventoryHeight, LX, LY) then
      begin
        if SpendTimeUnits(AItem.Slot.GetCost(ANewSlot)) then
        begin
          MoveItem(AItem, ANewSlot, LX, LY);
          PlaySound(isDrop);
          DrawItems;
          Exit(True);
        end;
        AWarning := 'STR_NOT_ENOUGH_TIME_UNITS';
      end;
end;

class function TXcomInventory.CanBeStacked(const AItemA, AItemB: TXcomBattleItem): Boolean;
begin
  Result := Assigned(AItemA) and Assigned(AItemB) and (AItemA.Rules = AItemB.Rules) and
    (((not Assigned(AItemA.AmmoItem)) and (not Assigned(AItemB.AmmoItem))) or
    (Assigned(AItemA.AmmoItem) and Assigned(AItemB.AmmoItem) and
    (AItemA.AmmoItem.Rules = AItemB.AmmoItem.Rules) and
    (AItemA.AmmoItem.AmmoQuantity = AItemB.AmmoItem.AmmoQuantity))) and
    (AItemA.FuseTimer = -1) and (AItemB.FuseTimer = -1) and
    (not Assigned(AItemA.CorpseUnit)) and (not Assigned(AItemB.CorpseUnit)) and
    (AItemA.PainKillerQuantity = AItemB.PainKillerQuantity) and (AItemA.HealQuantity = AItemB.HealQuantity) and
    (AItemA.StimulantQuantity = AItemB.StimulantQuantity);
end;

procedure TXcomInventory.DrawPrimers;
const
  PULSATE: array[0..7] of Integer = (0, 1, 2, 3, 4, 3, 2, 1);
var
  LSet: TXcomSurfaceSet;
  LFrame: TXcomSurface;
  LPoint: TPoint;
begin
  if FAnimFrame = 8 then
    FAnimFrame := 0;
  LSet := FGraphics.SurfaceSet('SCANG.DAT');
  if Assigned(LSet) then
  begin
    LFrame := LSet.GetFrame(PRIMER_FRAME);
    if Assigned(LFrame) then
      for LPoint in FGrenadeIndicators do
        TXcomSurfaceShader.Blit(LFrame, FItems, LPoint.X, LPoint.Y, PULSATE[FAnimFrame]);
  end;
  Inc(FAnimFrame);
end;

end.
