{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the status bar and the head up display           }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): display.pas, and the parts  }
{  of UpdateView of raven.pas that draw the status bar, the displays, the       }
{  rear view box and the holo suit (DrawHolo)                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.Hud;

// the rotating map multiplies map positions by 16.16 steps and lets the product wrap, as the original does
{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.Greed.Types, DelphiDoom.Greed.Intf,
  DelphiDoom.Greed.Actor.Types, DelphiDoom.Greed.LinkedPool, DelphiDoom.Greed.SaveTypes,
  DelphiDoom.Greed.Elevator.Intf, DelphiDoom.Greed.Game.Constants, DelphiDoom.Greed.Game.Tables,
  DelphiDoom.Greed.Game.State, DelphiDoom.Greed.Canvas, DelphiDoom.Greed.Font, DelphiDoom.Greed.TextPrinter,
  DelphiDoom.Greed.Inventory, DelphiDoom.Greed.Hud.Intf;

const
  /// <summary>The side of the picture of the rear view camera (rearbuf)</summary>
  GREED_REAR_VIEW_SIZE = 64;

  SGreedBadMapMode = 'PlayLoop(): mapmode = %d';

type
  /// <summary>
  ///   display.pas as a class: what the status bar showed last (old*) is the state of the object, the rest comes
  ///   from the state of the game. Everything is drawn on the canvas (the 320 x 200 buffer the original calls
  ///   screen and viewbuffer); the caller clears the canvas at each frame, draws the weapon, then calls
  ///   DrawDisplays (map, heat and motion modes), DrawStatusBar and UpdateDisplay, or DrawOverlay for the three.
  ///   UpdateDisplay chooses by CurrentViewSize: 0 nothing but the inventory item for a while after a change; 1 the
  ///   right statistics (shots, compass, settings, shield, heart, health); 2 the goal item too; 3 and 4 the
  ///   inventory and the ammunition too; 4 also the top bar (body count, score, level score, special effect).
  ///   The sizes from 5 to 9 are the "delta" routines of the DOS game (they draw only what changed, on a screen
  ///   that is not cleared): xGreed never reaches them (MAXVIEWSIZE is 5) but they are ported.
  ///   Not ported: the net game (displaynetbonusitem1 and 2, the pictures of the players).
  ///   Differences from the original, all where it reads or writes outside its arrays: a pixel outside the
  ///   canvas is not drawn (one beyond the edge of its row lands on the next row, as in the original: see
  ///   TGreedCanvas); a weapon number outside the table counts as one without ammunition, and the ammunition type 3
  ///   of the weapon 6 of the table (there are three types) counts as the type 0; a health below 0
  ///   shows the first heart; a goal item below -1 draws nothing; a sprite lump that is missing or too short is
  ///   not drawn; the rotating map with a zoom other than 4, 8 or 16 has no tile offset (the original leaves it
  ///   undefined)
  /// </summary>
  TGreedHud = class
  strict private
    FState: TGreedGameState;
    FCanvas: TGreedCanvas;
    FPrinter: TGreedTextPrinter;
    FInventory: TGreedInventory;
    FArchive: IGreedArchive;
    FLights: IGreedTileLights;
    FFont2: TGreedFont;
    FFont3: TGreedFont;
    FLumps: TDictionary<Integer, TBytes>;
    FHearts: array[0..9] of TBytes;
    FStatusBars: array[0..3] of TBytes;
    FInventoryLump: Integer;
    FPrimaryLump: Integer;
    FSecondaryLump: Integer;
    function Lump(AIndex: Integer): TBytes;
    procedure DrawSprite(ALump, AX, ABase: Integer; ACheckTop: Boolean = False);
    procedure PrintAt(AX, AY: Integer; const AText: string; ABackground: Boolean);
    function HeartIndex: Integer;
    procedure CurrentWeaponAmmo(out AAmmo, AMaxShots, AShots, AAmmoType: Integer);
    function GoalItemTexts(out ALump, AScore: Integer; out AKind, AName, ACount: string): Boolean;
    procedure ClearGoalItem;
    procedure DisplayStats1(AOffset: Integer);
    procedure DisplayCompassBack(AOffset: Integer);
    procedure DisplayCompass1(AOffset: Integer);
    procedure DisplaySettings(AOffset: Integer);
    procedure DisplayInventory1(AOffset: Integer);
    procedure DisplayBonusItem1(AOffset: Integer);
    procedure DisplayRightStats1(AOffset: Integer);
    procedure DisplayStats2;
    procedure DisplayCompass2;
    procedure DisplayInventory2;
    procedure DisplayBonusItem2;
    procedure DisplayRightStats2;
    procedure DisplayBodyCount2;
    procedure DisplayInventoryItem;
    procedure DisplayArrow(AX, AY: Integer);
    procedure MarkTile(ATileX, ATileY, AColor: Integer);
  public
    // ---- the globals of display.pas, with the names of the original ----
    OldBodyCount, OldScore, OldLevelScore: Integer;
    OldShield, OldAngst, OldShots, OldGoalItem, OldAngle: Integer;
    OldAngstPic: Integer;
    StatCursor: Integer;
    // ---- globals of the original that are not in TGreedGameState ----
    /// <summary>currentViewSize: 0 (the whole view) .. 4 (every bar)</summary>
    CurrentViewSize: Integer;
    /// <summary>
    ///   windowWidth and windowHeight while the HUD is drawn: UpdateView sets them to 320 and 200 after the level
    ///   is rendered, whatever the size of the view
    /// </summary>
    WindowWidth: Integer;
    WindowHeight: Integer;
    /// <summary>
    ///   Loads what LoadMiscData loads for the HUD: the lumps STATBAR1 .. STATBAR4 and the ten after HEART. The
    ///   fonts are FONT2 and FONT3. Nothing is owned. Call ResetDisplay before the first frame
    /// </summary>
    constructor Create(AState: TGreedGameState; ACanvas: TGreedCanvas; APrinter: TGreedTextPrinter;
      AInventory: TGreedInventory; const AArchive: IGreedArchive; const ALights: IGreedTileLights; AFont2,
      AFont3: TGreedFont);
    destructor Destroy; override;
    /// <summary>resetdisplay: everything is drawn again; the lumps medtube, primary and secondary are looked up</summary>
    procedure ResetDisplay;
    /// <summary>updatedisplay</summary>
    procedure UpdateDisplay;
    /// <summary>displaymapmode: the map around the player, 4 pixels a tile, north up</summary>
    procedure DisplayMapMode;
    /// <summary>displayswingmapmode: the whole map turned so that the player looks up, MapZoom pixels a tile</summary>
    procedure DisplaySwingMapMode;
    /// <summary>displayheatmode: the heat of the 64 x 64 tiles in a box at the top left</summary>
    procedure DisplayHeatMode;
    /// <summary>displayheatmapmode: the heat on the map</summary>
    procedure DisplayHeatMapMode;
    /// <summary>displaymotionmode: the living sprites in the box at the top left</summary>
    procedure DisplayMotionMode;
    /// <summary>displaymotionmapmode: the living sprites on the map</summary>
    procedure DisplayMotionMapMode;
    /// <summary>
    ///   "update displays" of UpdateView: the map (mode 1 or 2; another value raises as MS_Error does), then heat
    ///   and motion, on the map if it is shown and in the box if not
    /// </summary>
    procedure DrawDisplays;
    /// <summary>The picture of the status bar of UpdateView (none at size 0; at size 4 the top bar too)</summary>
    procedure DrawStatusBar;
    /// <summary>DrawDisplays, DrawStatusBar, UpdateDisplay: what UpdateView draws after the weapon</summary>
    procedure DrawOverlay;
    /// <summary>DrawHolo: the picture of the holo suit at the bottom left, if the player wears one</summary>
    procedure DrawHolo;
    /// <summary>
    ///   The box of the rear view camera of UpdateView: 64 x 64 pixels (the picture RearView made, its 0 already
    ///   turned into ApproxZero) at the top right with a frame of color 30. The caller draws it while
    ///   timecount &lt; RearViewTime
    /// </summary>
    procedure DrawRearView(const ARearBuffer: TBytes);
    /// <summary>oldinventory := -2; inventoryleft; inventoryright (IGreedItemHost.RefreshInventory)</summary>
    procedure RefreshInventory;
    /// <summary>oldshots := -1 (IGreedItemHost.RefreshAmmo)</summary>
    procedure RefreshAmmo;
    /// <summary>oldgoalitem := -1 (IGreedLevelHost.RefreshGoalItem)</summary>
    procedure RefreshGoalItem;
    /// <summary>totaleffecttime := n (IGreedLevelHost.SetTotalEffectTime)</summary>
    procedure SetTotalEffectTime(ATics: Integer);
    /// <summary>ChangeViewSize of utils.pas without the renderer: the size changes by one inside 0 .. 4 and the display is reset</summary>
    procedure ChangeViewSize(AMakeLarger: Boolean);
    property Inventory: TGreedInventory read FInventory;
  end;

const
  /// <summary>primnames: the primary goals</summary>
  GreedPrimaryNames: array[0..21] of string = (
    'Explosives', 'Head of Warden', 'Phlegmatic Eel', 'Byzantium Brass Ring', 'Sacrificial Dagger',
    'Book of Chants', 'Holy Incantation Brazier', 'error 7', 'Personality Encode', 'Space Generator',
    'Imperial Sigil', 'Psiflex Data Module', 'Fissure Prism', 'Mummification Glyph', 'Soylent Brown Narcotic',
    'Viral Stabilization Pods', 'Idol of the Felasha Pont', 'Skull Scepter', 'Sacred Cow of Tooms',
    'Gene Coding Cube', 'Desecrate Summoning Circle', 'Power Coupler');

  /// <summary>secnames: the secondary goals</summary>
  GreedSecondaryNames: array[0..40] of string = (
    'Inmate Uniforms', 'Delousing Kits', 'Truth Serum Vials', 'Hypodermic Needles', 'Lubricants',
    'Emergency Lantern', 'Water Tanks', 'Oxygen Tanks', 'Exo-suit', 'Phosfor Pellets', 'Plasma Conduit Coupling',
    'Madree 3 Cypher Kit', 'Security Key', 'Denatured Bio-Proteins', 'Neural Reanimation Focus', 'Shunt Matrix',
    'Plasmoid CryoVice', 'Rad-Shield Goggles', 'Prayer Scroll', 'Silver Beetle', 'Finger Bones', 'Pain Ankh',
    'War Slug Larvae', 'War Slug Food', 'Ritual Candles', 'Idth Force Key 1', 'Idth Force Key 2',
    'Idth Force Key 3', 'Idth Force Key 4', 'error 29', 'error 30', 'error 31', 'error 32', 'Tribolek Game Cubes',
    'Atomic Space Heater', 'Reactor Coolant Container', 'Power Flow Calibrator', 'Verimax Insulated Gloves',
    'Gold Ingots', 'Soul Orb of Eyul', 'Prayer Scroll');

  /// <summary>ammonames</summary>
  GreedAmmoNames: array[0..2] of string = ('ENERGY', 'BULLET', 'PLASMA');

  /// <summary>inventorynames: 14 characters each</summary>
  GreedInventoryNames: array[0..GREED_MAX_INVENTORY - 1] of string = (
    'Medical Tube  ', 'Shield Charge ', 'Grenade       ', 'Reverso Pill  ', 'Proximity Mine', 'Time Bomb     ',
    'Decoy         ', 'InstaWall     ', 'Clone         ', 'HoloSuit      ', 'Invisibility  ', 'Warp Jammer   ',
    'Soul Stealer  ');

implementation

uses
  DelphiDoom.Greed.LittleEndian, DelphiDoom.Greed.FixedMath, DelphiDoom.Greed.TrigTables,
  DelphiDoom.Greed.Render.Types, DelphiDoom.Greed.Render.Tables;

const
  // SOUTH of r_public_h.pas
  ANGLE_SOUTH = 768;
  MAP_COLS = GREED_MAP_SIZE;
  MAP_ROWS = GREED_MAP_SIZE;
  // the y step of the needle of the compass: the pixels of the 320 x 200 screen are higher than wide
  COMPASS_ASPECT = 54394;
  NO_EFFECT_TIME = $7FFFFFFF;
  COLOR_PLAYER = 40;
  COLOR_BONUS = 44;
  COLOR_EXIT = 187;
  COLOR_SENSOR_FRAME = 73;
  COLOR_MOTION = 152;
  COLOR_FRAME = 30;
  // the color of the status bar pictures that the bars of shield and heart beat are painted over
  COLOR_PLACEHOLDER = 254;

type
  TCompassBackLine = record
    Line, Start, Finish: Integer;
  end;

const
  // compassbackinfo
  CompassBack: array[0..18] of TCompassBackLine = (
    (Line: 152; Start: 234; Finish: 240), (Line: 153; Start: 231; Finish: 243),
    (Line: 154; Start: 230; Finish: 244), (Line: 155; Start: 228; Finish: 246),
    (Line: 156; Start: 228; Finish: 246), (Line: 157; Start: 227; Finish: 247),
    (Line: 158; Start: 227; Finish: 247), (Line: 159; Start: 226; Finish: 248),
    (Line: 160; Start: 226; Finish: 248), (Line: 161; Start: 226; Finish: 248),
    (Line: 162; Start: 226; Finish: 248), (Line: 163; Start: 226; Finish: 248),
    (Line: 164; Start: 227; Finish: 247), (Line: 165; Start: 227; Finish: 247),
    (Line: 166; Start: 228; Finish: 246), (Line: 167; Start: 228; Finish: 246),
    (Line: 168; Start: 230; Finish: 244), (Line: 169; Start: 231; Finish: 243),
    (Line: 170; Start: 234; Finish: 240));

{ TGreedHud }

constructor TGreedHud.Create(AState: TGreedGameState; ACanvas: TGreedCanvas; APrinter: TGreedTextPrinter;
  AInventory: TGreedInventory; const AArchive: IGreedArchive; const ALights: IGreedTileLights; AFont2,
  AFont3: TGreedFont);
var
  LIndex: Integer;
  LHeart: Integer;
begin
  inherited Create;
  if not Assigned(AState) then
    raise EArgumentNilException.Create('AState');
  if not Assigned(ACanvas) then
    raise EArgumentNilException.Create('ACanvas');
  if not Assigned(APrinter) then
    raise EArgumentNilException.Create('APrinter');
  if not Assigned(AInventory) then
    raise EArgumentNilException.Create('AInventory');
  if not Assigned(AArchive) then
    raise EArgumentNilException.Create('AArchive');
  if not Assigned(ALights) then
    raise EArgumentNilException.Create('ALights');
  if not Assigned(AFont2) then
    raise EArgumentNilException.Create('AFont2');
  if not Assigned(AFont3) then
    raise EArgumentNilException.Create('AFont3');
  FState := AState;
  FCanvas := ACanvas;
  FPrinter := APrinter;
  FInventory := AInventory;
  FArchive := AArchive;
  FLights := ALights;
  FFont2 := AFont2;
  FFont3 := AFont3;
  FLumps := TDictionary<Integer, TBytes>.Create;
  for LIndex := 0 to 3 do
    FStatusBars[LIndex] := AArchive.ReadLump(AArchive.RequireIndexOf('STATBAR' + IntToStr(LIndex + 1)));
  LHeart := AArchive.RequireIndexOf('HEART');
  for LIndex := 0 to 9 do
    FHearts[LIndex] := AArchive.ReadLump(LHeart + LIndex);
  StatCursor := 269;
  WindowWidth := ACanvas.Width;
  WindowHeight := ACanvas.Height;
end;

destructor TGreedHud.Destroy;
begin
  FLumps.Free;
  inherited;
end;

function TGreedHud.Lump(AIndex: Integer): TBytes;
begin
  if FLumps.TryGetValue(AIndex, Result) then
    Exit;
  if (AIndex < 0) or (AIndex >= FArchive.LumpCount) then
    Result := nil
  else
    Result := FArchive.ReadLump(AIndex);
  FLumps.Add(AIndex, Result);
end;

procedure TGreedHud.ResetDisplay;
begin
  OldBodyCount := -1;
  OldShield := -1;
  OldAngst := -1;
  OldScore := -1;
  OldShots := -1;
  OldLevelScore := -1;
  OldAngle := -1;
  OldAngstPic := -1;
  FInventory.OldInventory := GREED_INVENTORY_REDRAW;
  OldGoalItem := -1;
  FInventoryLump := FArchive.RequireIndexOf('medtube');
  FPrimaryLump := FArchive.RequireIndexOf('primary');
  FSecondaryLump := FArchive.RequireIndexOf('secondary');
end;

procedure TGreedHud.RefreshInventory;
begin
  FInventory.Refresh;
end;

procedure TGreedHud.RefreshAmmo;
begin
  OldShots := -1;
end;

procedure TGreedHud.RefreshGoalItem;
begin
  OldGoalItem := -1;
end;

procedure TGreedHud.SetTotalEffectTime(ATics: Integer);
begin
  FInventory.TotalEffectTime := ATics;
end;

procedure TGreedHud.ChangeViewSize(AMakeLarger: Boolean);
begin
  if AMakeLarger then
  begin
    if CurrentViewSize < GREED_MAXVIEWSIZE - 1 then
      Inc(CurrentViewSize)
    else
      Exit;
  end
  else
  begin
    if CurrentViewSize > 0 then
      Dec(CurrentViewSize)
    else
      Exit;
  end;
  ResetDisplay;
end;

procedure TGreedHud.DrawSprite(ALump, AX, ABase: Integer; ACheckTop: Boolean);
var
  LPicture: TBytes;
  LWidth: Integer;
  LColumn: Integer;
  LOffset: Integer;
  LTop, LBottom, LCount: Integer;
  LRow: Integer;
  LY: Integer;
  LColor: Byte;
begin
  LPicture := Lump(ALump);
  if Length(LPicture) < GREED_SPRITE_HEADER_BYTES then
    Exit;
  LWidth := TGreedLittleEndian.ReadSmallInt(LPicture, 2);
  if Length(LPicture) < GREED_SPRITE_HEADER_BYTES + 2 * LWidth then
    Exit;
  for LColumn := 0 to LWidth - 1 do
  begin
    LOffset := TGreedLittleEndian.ReadSmallInt(LPicture, GREED_SPRITE_HEADER_BYTES + 2 * LColumn);
    if (LOffset > 0) and (LOffset + 2 <= Length(LPicture)) then
    begin
      LTop := LPicture[LOffset + 1];
      LBottom := LPicture[LOffset];
      LCount := LBottom - LTop + 1;
      LY := ABase - LTop - LCount;
      for LRow := 0 to LCount - 1 do
      begin
        if LOffset + 2 + LRow < Length(LPicture) then
        begin
          LColor := LPicture[LOffset + 2 + LRow];
          // only DrawHolo checks the top; the others would write before the row 0 (not drawn here either way)
          if (LColor <> 0) and ((LY >= 0) or not ACheckTop) then
            FCanvas.PutPixel(AX, LY, LColor);
        end;
        Inc(LY);
      end;
    end;
    Inc(AX);
  end;
end;

procedure TGreedHud.PrintAt(AX, AY: Integer; const AText: string; ABackground: Boolean);
begin
  FPrinter.PrintX := AX;
  FPrinter.PrintY := AY;
  if ABackground then
    FPrinter.RawPrint(AText)
  else
    FPrinter.RawPrint2(AText);
end;

function TGreedHud.HeartIndex: Integer;
begin
  Result := (FState.Player.Angst * 10) div FState.Player.MaxAngst;
  if Result >= 10 then
    Result := 9;
  if Result < 0 then
    Result := 0;
end;

procedure TGreedHud.CurrentWeaponAmmo(out AAmmo, AMaxShots, AShots, AAmmoType: Integer);
var
  LWeapon: Integer;
begin
  AAmmo := 999;
  AMaxShots := 999;
  AShots := 999;
  AAmmoType := 0;
  if (FState.Player.CurrentWeapon < Low(FState.Player.Weapons)) or
    (FState.Player.CurrentWeapon > High(FState.Player.Weapons)) then
    Exit;
  LWeapon := FState.Player.Weapons[FState.Player.CurrentWeapon];
  if (LWeapon < Low(FState.Weapons)) or (LWeapon > High(FState.Weapons)) then
    Exit;
  AAmmoType := FState.Weapons[LWeapon].AmmoType;
  if (AAmmoType < 0) or (AAmmoType > High(FState.Player.Ammo)) then
    AAmmoType := 0;
  if FState.Weapons[LWeapon].AmmoRate > 0 then
  begin
    AAmmo := FState.Player.Ammo[AAmmoType];
    AMaxShots := FState.Weapons[LWeapon].AmmoRate;
    AShots := AAmmo div AMaxShots;
  end;
end;

// ---------------------------------------------------------------------------------------------------------
// the routines that draw everything at each frame (view sizes 1 .. 4)
// ---------------------------------------------------------------------------------------------------------

procedure TGreedHud.DisplayStats1(AOffset: Integer);
var
  LShield, LRow, LColumn, LColor: Integer;
begin
  LShield := (FState.Player.Shield * 28) div FState.Player.MaxShield;
  for LRow := 152 + AOffset to 159 + AOffset do
  begin
    LColor := (LShield * (LRow - (152 + AOffset))) div 8 + 140;
    for LColumn := 272 to 300 do
      if FCanvas.GetPixel(LColumn, LRow) = COLOR_PLACEHOLDER then
        FCanvas.PutPixel(LColumn, LRow, LColor);
  end;
  for LRow := 193 + AOffset to 199 + AOffset do
  begin
    LColor := (LShield * ((199 + AOffset) - LRow)) div 7 + 140;
    for LColumn := 272 to 300 do
      if FCanvas.GetPixel(LColumn, LRow) = COLOR_PLACEHOLDER then
        FCanvas.PutPixel(LColumn, LRow, LColor);
  end;
  for LColumn := 307 to 315 do
  begin
    LColor := (LShield * (315 - LColumn)) div 9 + 140;
    for LRow := 165 + AOffset to 187 + AOffset do
      if FCanvas.GetPixel(LColumn, LRow) = COLOR_PLACEHOLDER then
        FCanvas.PutPixel(LColumn, LRow, LColor);
  end;
  for LColumn := 257 to 265 do
  begin
    LColor := (LShield * (LColumn - 257)) div 9 + 140;
    for LRow := 165 + AOffset to 187 + AOffset do
      if FCanvas.GetPixel(LColumn, LRow) = COLOR_PLACEHOLDER then
        FCanvas.PutPixel(LColumn, LRow, LColor);
  end;
  FCanvas.DrawMaskedPicToBuffer(269, 161 + AOffset, FHearts[HeartIndex]);
  StatCursor := 269 + FState.TimeCount mod 54;
  for LColumn := 269 to 305 do
  begin
    if LColumn > StatCursor then
      LColor := 113
    else
    begin
      LColor := 139 - (StatCursor - LColumn);
      if LColor < 120 then
        LColor := 113;
    end;
    for LRow := 161 + AOffset to 185 + AOffset do
      if FCanvas.GetPixel(LColumn, LRow) = COLOR_PLACEHOLDER then
        FCanvas.PutPixel(LColumn, LRow, LColor);
  end;
  FPrinter.Font := FFont2;
  FPrinter.BaseColor := 0;
  FPrinter.PrintX := 280;
  FPrinter.PrintY := 188 + AOffset;
  FPrinter.RawPrint4(Format('%3d', [FState.Player.Angst]));
end;

procedure TGreedHud.DisplayCompassBack(AOffset: Integer);
var
  LIndex: Integer;
  LColumn: Integer;
begin
  for LIndex := Low(CompassBack) to High(CompassBack) do
    for LColumn := CompassBack[LIndex].Start to CompassBack[LIndex].Finish do
      if FCanvas.GetPixel(LColumn, CompassBack[LIndex].Line + AOffset) = 0 then
        FCanvas.PutPixel(LColumn, CompassBack[LIndex].Line + AOffset, FCanvas.ApproxZero);
end;

procedure TGreedHud.DisplayCompass1(AOffset: Integer);
var
  LColor, LX, LY, LIndex: Integer;
  LFixedX, LFixedY: TGreedFixed;
begin
  DisplayCompassBack(AOffset);
  LX := 237;
  LFixedX := LX * GREED_FRACUNIT;
  LY := 161 + AOffset;
  LFixedY := LY * GREED_FRACUNIT;
  LColor := 139;
  for LIndex := 0 to 9 do
  begin
    FCanvas.PutPixel(LX, LY, LColor);
    LFixedX := LFixedX + TGreedTrigTables.Cosine(FState.Player.Angle);
    LFixedY := LFixedY - TGreedFixedMath.Mul(TGreedTrigTables.Sine(FState.Player.Angle), COMPASS_ASPECT);
    LX := LFixedX div GREED_FRACUNIT;
    LY := LFixedY div GREED_FRACUNIT;
    Dec(LColor);
  end;
end;

procedure TGreedHud.DisplaySettings(AOffset: Integer);
begin
  if FState.HeatMode then
    FCanvas.FillRow(236, 199 + AOffset, 6, 102)
  else
    FCanvas.FillRow(236, 199 + AOffset, 6, FCanvas.ApproxZero);
  if FState.MotionMode then
    FCanvas.FillRow(246, 199 + AOffset, 6, 156)
  else
    FCanvas.FillRow(246, 199 + AOffset, 6, FCanvas.ApproxZero);
  if FState.MapMode <> 0 then
    FCanvas.FillRow(226, 199 + AOffset, 6, 133)
  else
    FCanvas.FillRow(226, 199 + AOffset, 6, FCanvas.ApproxZero);
end;

procedure TGreedHud.DisplayInventory1(AOffset: Integer);
var
  LAmmo, LMaxShots, LShots, LAmmoType: Integer;
  LPicture: TBytes;
begin
  FPrinter.Font := FFont2;
  FPrinter.BaseColor := 0;
  CurrentWeaponAmmo(LAmmo, LMaxShots, LShots, LAmmoType);
  PrintAt(186, 183 + AOffset, Format('%3d', [LAmmo]), False);
  PrintAt(203, 183 + AOffset, Format('%3d', [LMaxShots]), False);
  PrintAt(187, 191 + AOffset, GreedAmmoNames[LAmmoType], False);

  if (FInventory.Cursor = GREED_INVENTORY_NONE) or (FState.Player.Inventory[FInventory.Cursor] = 0) then
    FInventory.Right;
  if FInventory.Cursor <> GREED_INVENTORY_NONE then
  begin
    PrintAt(149, 163 + AOffset, GreedInventoryNames[FInventory.Cursor], False);
    FPrinter.Font := FFont3;
    PrintAt(150, 172 + AOffset, Format('%2d', [FState.Player.Inventory[FInventory.Cursor]]), False);
    LPicture := Lump(FInventoryLump + FInventory.Cursor);
    if Length(LPicture) >= GREED_SPRITE_HEADER_BYTES then
      DrawSprite(FInventoryLump + FInventory.Cursor, 128 - (TGreedLittleEndian.ReadSmallInt(LPicture, 2) div 2),
        188 + AOffset);
  end
  else
  begin
    PrintAt(149, 163 + AOffset, '              ', False);
    FPrinter.Font := FFont3;
    PrintAt(150, 172 + AOffset, '  ', False);
  end;
end;

function TGreedHud.GoalItemTexts(out ALump, AScore: Integer; out AKind, AName, ACount: string): Boolean;
var
  LGoal: Integer;
  LTime: Integer;
  LNumber: Integer;
begin
  Result := True;
  LGoal := FState.GoalItem;
  if LGoal = 0 then
  begin
    if FState.BonusItem.Sprite = GREED_POOL_NIL then
      ALump := -1
    else
      ALump := PGreedSprite(FState.Sprites.Item(FState.BonusItem.Sprite))^.BasePic;
    AScore := FState.BonusItem.Score;
    AKind := 'Bonus  ';
    LTime := (FState.BonusItem.Time - FState.TimeCount) div GREED_TIC_RATE;
    if LTime > 10000 then
      LTime := 0;
    ACount := Format('%3d s', [LTime]);
    AName := Copy(FState.BonusItem.Name, 1, 255);
  end
  else if (LGoal >= 1) and (LGoal <= 2) then
  begin
    LNumber := FState.Primaries[(LGoal - 1) * 2];
    ALump := FPrimaryLump + LNumber;
    AScore := FState.Primaries[(LGoal - 1) * 2 + 1];
    AKind := 'Primary';
    ACount := Format('%2d/%2d', [FState.Player.Primaries[LGoal - 1], FState.PCount[LGoal - 1]]);
    if (LNumber >= Low(GreedPrimaryNames)) and (LNumber <= High(GreedPrimaryNames)) then
      AName := GreedPrimaryNames[LNumber]
    else
      AName := '';
  end
  else if (LGoal >= 3) and (LGoal <= 9) then
  begin
    LNumber := FState.Secondaries[(LGoal - 3) * 2];
    ALump := FSecondaryLump + LNumber;
    AScore := FState.Secondaries[(LGoal - 3) * 2 + 1];
    AKind := 'Second ';
    ACount := Format('%2d/%2d', [FState.Player.Secondaries[LGoal - 3], FState.SCount[LGoal - 3]]);
    if (LNumber >= Low(GreedSecondaryNames)) and (LNumber <= High(GreedSecondaryNames)) then
      AName := GreedSecondaryNames[LNumber]
    else
      AName := '';
  end
  else
    Result := False;
end;

procedure TGreedHud.DisplayBonusItem1(AOffset: Integer);
var
  LLump, LScore: Integer;
  LKind, LName, LCount: string;
  LPicture: TBytes;
begin
  FPrinter.Font := FFont2;
  FPrinter.BaseColor := 0;
  if FState.GoalItem = -1 then
  begin
    if FState.BonusItem.Score <> 0 then
      FState.ToggleGoalItem := True;
    Exit;
  end;
  if (FState.GoalItem = 0) and (FState.BonusItem.Score = 0) then
  begin
    // bonus item go bye-bye
    FState.ToggleGoalItem := True;
    Exit;
  end;
  if not GoalItemTexts(LLump, LScore, LKind, LName, LCount) then
    Exit;
  LPicture := Lump(LLump);
  if Length(LPicture) >= GREED_SPRITE_HEADER_BYTES then
    DrawSprite(LLump, 34 - (TGreedLittleEndian.ReadSmallInt(LPicture, 2) div 2), 188 + AOffset);
  PrintAt(53, 162 + AOffset, LCount, False);
  PrintAt(53, 172 + AOffset, Format('%5d', [LScore]), False);
  PrintAt(53, 182 + AOffset, LKind, False);
  PrintAt(22, 192 + AOffset, StringOfChar(' ', 32 - Length(LName)) + LName, False);
end;

procedure TGreedHud.DisplayRightStats1(AOffset: Integer);
var
  LAmmo, LMaxShots, LShots, LAmmoType: Integer;
begin
  CurrentWeaponAmmo(LAmmo, LMaxShots, LShots, LAmmoType);
  FPrinter.Font := FFont3;
  FPrinter.BaseColor := 0;
  PrintAt(225, 178 + AOffset, Format('%3d', [LShots]), False);
  DisplayCompass1(AOffset);
  DisplaySettings(AOffset);
  DisplayStats1(AOffset);
end;

// ---------------------------------------------------------------------------------------------------------
// the routines that draw only what changed (view sizes 5 .. 9 of the DOS game)
// ---------------------------------------------------------------------------------------------------------

procedure TGreedHud.DisplayStats2;
var
  LShield, LRow, LColumn, LColor, LPixel, LHeart: Integer;

  procedure Paint(AFirst, ALast: Integer);
  begin
    LPixel := FCanvas.GetPixel(LColumn, LRow);
    if (LPixel = COLOR_PLACEHOLDER) or ((LPixel >= AFirst) and (LPixel <= ALast)) then
      FCanvas.PutPixel(LColumn, LRow, LColor);
  end;

begin
  if FState.Player.Shield <> OldShield then
  begin
    OldShield := FState.Player.Shield;
    LShield := (FState.Player.Shield * 28) div FState.Player.MaxShield;
    for LRow := 152 to 159 do
    begin
      LColor := (LShield * (LRow - 152)) div 8 + 140;
      for LColumn := 272 to 300 do
        Paint(140, 168);
    end;
    for LRow := 193 to 199 do
    begin
      LColor := (LShield * (199 - LRow)) div 7 + 140;
      for LColumn := 272 to 300 do
        Paint(140, 168);
    end;
    for LColumn := 307 to 315 do
    begin
      LColor := (LShield * (315 - LColumn)) div 9 + 140;
      for LRow := 165 to 187 do
        Paint(140, 168);
    end;
    for LColumn := 257 to 265 do
    begin
      LColor := (LShield * (LColumn - 257)) div 9 + 140;
      for LRow := 165 to 187 do
        Paint(140, 168);
    end;
  end;
  if FState.Player.Angst <> OldAngst then
  begin
    LHeart := HeartIndex;
    if OldAngstPic <> LHeart then
    begin
      FCanvas.DrawPicSolid(269, 161, FHearts[LHeart]);
      OldAngstPic := LHeart;
    end;
    OldAngst := FState.Player.Angst;
    FPrinter.Font := FFont2;
    FPrinter.BaseColor := 0;
    PrintAt(280, 188, Format('%3d', [FState.Player.Angst]), True);
  end;
  StatCursor := 269 + FState.TimeCount mod 54;
  for LColumn := 269 to 305 do
  begin
    if LColumn > StatCursor then
      LColor := 113
    else
    begin
      LColor := 139 - (StatCursor - LColumn);
      if LColor < 120 then
        LColor := 113;
    end;
    for LRow := 161 to 185 do
      Paint(113, 139);
  end;
end;

procedure TGreedHud.DisplayCompass2;
var
  LColor, LX, LY, LIndex: Integer;
  LFixedX, LFixedY: TGreedFixed;
begin
  DisplayCompassBack(0);
  if OldAngle <> -1 then
  begin
    LX := 237;
    LFixedX := LX * GREED_FRACUNIT;
    LY := 161;
    LFixedY := LY * GREED_FRACUNIT;
    for LIndex := 0 to 9 do
    begin
      FCanvas.PutPixel(LX, LY, 0);
      LFixedX := LFixedX + TGreedTrigTables.Cosine(OldAngle);
      LFixedY := LFixedY - TGreedFixedMath.Mul(TGreedTrigTables.Sine(OldAngle), COMPASS_ASPECT);
      LX := LFixedX div GREED_FRACUNIT;
      LY := LFixedY div GREED_FRACUNIT;
    end;
  end;
  OldAngle := FState.Player.Angle;
  LX := 237;
  LFixedX := LX * GREED_FRACUNIT;
  LY := 161;
  LFixedY := LY * GREED_FRACUNIT;
  LColor := 139;
  for LIndex := 0 to 9 do
  begin
    FCanvas.PutPixel(LX, LY, LColor);
    LFixedX := LFixedX + TGreedTrigTables.Cosine(OldAngle);
    LFixedY := LFixedY - TGreedFixedMath.Mul(TGreedTrigTables.Sine(OldAngle), COMPASS_ASPECT);
    LX := LFixedX div GREED_FRACUNIT;
    LY := LFixedY div GREED_FRACUNIT;
    Dec(LColor);
  end;
end;

procedure TGreedHud.DisplayInventory2;
var
  LAmmo, LMaxShots, LShots, LAmmoType: Integer;
  LRow: Integer;
  LPicture: TBytes;
begin
  FPrinter.Font := FFont2;
  FPrinter.BaseColor := 0;
  CurrentWeaponAmmo(LAmmo, LMaxShots, LShots, LAmmoType);
  FPrinter.PrintX := 186;
  FPrinter.PrintY := 183;
  FPrinter.Print(Format('%3d', [LAmmo]));
  FPrinter.PrintX := 203;
  FPrinter.PrintY := 183;
  FPrinter.Print(Format('%3d', [LMaxShots]));
  PrintAt(187, 191, GreedAmmoNames[LAmmoType], True);

  if (FInventory.Cursor = GREED_INVENTORY_NONE) or (FState.Player.Inventory[FInventory.Cursor] = 0) then
    FInventory.Right;
  if FInventory.Cursor <> FInventory.OldInventory then
  begin
    FInventory.OldInventory := FInventory.Cursor;
    for LRow := 162 to 184 do
      FCanvas.FillRow(113, LRow, 30, FCanvas.ApproxZero);
    if FInventory.Cursor <> GREED_INVENTORY_NONE then
    begin
      PrintAt(149, 163, GreedInventoryNames[FInventory.Cursor], True);
      LPicture := Lump(FInventoryLump + FInventory.Cursor);
      if Length(LPicture) >= GREED_SPRITE_HEADER_BYTES then
        DrawSprite(FInventoryLump + FInventory.Cursor, 128 - (TGreedLittleEndian.ReadSmallInt(LPicture, 2) div 2),
          188);
      FPrinter.Font := FFont3;
      PrintAt(150, 172, Format('%2d', [FState.Player.Inventory[FInventory.Cursor]]), True);
    end
    else
    begin
      PrintAt(149, 163, '              ', True);
      FPrinter.Font := FFont3;
      PrintAt(150, 172, '  ', True);
    end;
  end;
end;

procedure TGreedHud.ClearGoalItem;
var
  LRow: Integer;
begin
  for LRow := 158 to 187 do
    FCanvas.FillRow(19, LRow, 30, FCanvas.ApproxZero);
  FPrinter.Font := FFont2;
  FPrinter.BaseColor := 0;
  PrintAt(53, 162, '     ', True);
  PrintAt(53, 172, '     ', True);
  PrintAt(53, 182, '       ', True);
  PrintAt(22, 192, StringOfChar(' ', 32), True);
end;

procedure TGreedHud.DisplayBonusItem2;
var
  LLump, LScore: Integer;
  LKind, LName, LCount: string;
  LRow: Integer;
  LPicture: TBytes;
begin
  if FState.GoalItem < 0 then
  begin
    if FState.BonusItem.Score <> 0 then
      FState.ToggleGoalItem := True;
    ClearGoalItem;
    Exit;
  end;
  if (FState.GoalItem = 0) and (FState.BonusItem.Score = 0) then
  begin
    FState.ToggleGoalItem := True;
    Exit;
  end;
  if (OldGoalItem = FState.GoalItem) and (FState.GoalItem <> 0) then
    Exit;
  FPrinter.Font := FFont2;
  FPrinter.BaseColor := 0;
  if not GoalItemTexts(LLump, LScore, LKind, LName, LCount) then
    Exit;
  if (FState.GoalItem = 0) and (OldGoalItem = FState.GoalItem) then
  begin
    // only the time that is left changes
    PrintAt(53, 162, LCount, True);
    Exit;
  end;
  OldGoalItem := FState.GoalItem;

  for LRow := 158 to 187 do
    FCanvas.FillRow(19, LRow, 30, FCanvas.ApproxZero);
  LPicture := Lump(LLump);
  if Length(LPicture) >= GREED_SPRITE_HEADER_BYTES then
    DrawSprite(LLump, 34 - (TGreedLittleEndian.ReadSmallInt(LPicture, 2) div 2), 188);

  for LRow := 162 to 167 do
    FCanvas.FillRow(53, LRow, 23, FCanvas.ApproxZero);
  for LRow := 172 to 177 do
    FCanvas.FillRow(53, LRow, 30, FCanvas.ApproxZero);
  for LRow := 182 to 187 do
    FCanvas.FillRow(53, LRow, 39, FCanvas.ApproxZero);
  for LRow := 192 to 197 do
    FCanvas.FillRow(22, LRow, 159, FCanvas.ApproxZero);

  PrintAt(53, 162, LCount, True);
  FPrinter.PrintX := 53;
  FPrinter.PrintY := 172;
  FPrinter.Print(Format('%5d', [LScore]));
  PrintAt(53, 182, LKind, True);
  PrintAt(22, 192, StringOfChar(' ', 32 - Length(LName)) + LName, True);
end;

procedure TGreedHud.DisplayRightStats2;
var
  LAmmo, LMaxShots, LShots, LAmmoType: Integer;
begin
  CurrentWeaponAmmo(LAmmo, LMaxShots, LShots, LAmmoType);
  if LShots <> OldShots then
  begin
    FPrinter.Font := FFont3;
    FPrinter.PrintX := 225;
    FPrinter.PrintY := 178;
    FPrinter.BaseColor := 0;
    FPrinter.Print(Format('%3d', [LShots]));
    OldShots := LShots;
  end;
  DisplayCompass2;
  DisplaySettings(0);
  DisplayStats2;
end;

procedure TGreedHud.DisplayBodyCount2;
var
  LRow, LColumn, LLength, LLeft, LColor: Integer;
begin
  FPrinter.Font := FFont2;
  FPrinter.BaseColor := 0;
  PrintAt(178, 3, Format('%8d', [FState.Player.BodyCount]), True);
  OldBodyCount := FState.Player.BodyCount;
  PrintAt(28, 3, Format('%9d', [FState.Player.Score]), True);
  OldScore := FState.Player.Score;
  PrintAt(104, 3, Format('%9d', [FState.Player.LevelScore]), True);
  OldLevelScore := FState.Player.LevelScore;

  if FState.SpecialEffectTime <> NO_EFFECT_TIME then
  begin
    LLeft := (FState.SpecialEffectTime - FState.TimeCount) div 4;
    if LLeft > 97 then
      LLength := 97
    else if LLeft < 0 then
      LLength := 0
    else
      LLength := LLeft;
    for LColumn := 0 to LLength - 1 do
    begin
      LColor := (LColumn * 26) div LLeft;
      for LRow := 2 to 8 do
        FCanvas.PutPixel(LColumn + 221, LRow, LColor + 140);
    end;
    if LLength < 97 then
      for LColumn := LLength to 97 do
        for LRow := 2 to 8 do
          FCanvas.PutPixel(LColumn + 221, LRow, FCanvas.ApproxZero);
  end;
end;

procedure TGreedHud.DisplayInventoryItem;
var
  LRow: Integer;
begin
  if FInventory.Cursor < 0 then
    Exit;
  for LRow := 0 to 26 do
  begin
    FCanvas.FillRow(WindowWidth - 54, LRow, 54, FCanvas.ApproxZero);
    FCanvas.PutPixel(WindowWidth - 55, LRow, COLOR_FRAME);
  end;
  FCanvas.FillRow(WindowWidth - 55, 27, 55, COLOR_FRAME);
  DrawSprite(FInventoryLump + FInventory.Cursor, WindowWidth - 31, 28);
  FPrinter.BaseColor := 0;
  FPrinter.Font := FFont3;
  FPrinter.PrintX := WindowWidth - 53;
  FPrinter.PrintY := 6;
  FPrinter.RawPrint4(Format('%2d', [FState.Player.Inventory[FInventory.Cursor]]));
end;

procedure TGreedHud.UpdateDisplay;
begin
  case CurrentViewSize of
    0:
      if FState.TimeCount < FState.InventoryTime then
        DisplayInventoryItem;
    1, 2, 3:
      begin
        if CurrentViewSize >= 3 then
          DisplayInventory1(0);
        if CurrentViewSize >= 2 then
          DisplayBonusItem1(0);
        DisplayRightStats1(0);
        if (CurrentViewSize < 3) and (FState.TimeCount < FState.InventoryTime) then
          DisplayInventoryItem;
      end;
    4:
      begin
        DisplayInventory1(0);
        DisplayBonusItem1(0);
        DisplayRightStats1(0);
        DisplayBodyCount2;
      end;
    5, 6, 7, 8, 9:
      begin
        DisplayInventory2;
        DisplayBonusItem2;
        DisplayRightStats2;
        DisplayBodyCount2;
      end;
  end;
end;

// ---------------------------------------------------------------------------------------------------------
// map, heat and motion
// ---------------------------------------------------------------------------------------------------------

procedure TGreedHud.DisplayArrow(AX, AY: Integer);
var
  LAngle: Integer;
begin
  FCanvas.PutPixel(AX, AY, 26);
  // divided by 1023 and not by 1024, as the original: the angle 1023 - 64 gives 8 and no arrow
  LAngle := (((FState.Player.Angle + GREED_DEGREE45_2) and GREED_ANGLES) * 8) div GREED_ANGLES;
  case LAngle of
    0:
      begin
        FCanvas.PutPixel(AX + 1, AY, 40);
        FCanvas.PutPixel(AX - 1, AY, 20);
      end;
    1:
      begin
        FCanvas.PutPixel(AX + 1, AY - 1, 40);
        FCanvas.PutPixel(AX - 1, AY + 1, 20);
      end;
    2:
      begin
        FCanvas.PutPixel(AX, AY - 1, 40);
        FCanvas.PutPixel(AX, AY + 1, 20);
      end;
    3:
      begin
        FCanvas.PutPixel(AX - 1, AY - 1, 40);
        FCanvas.PutPixel(AX + 1, AY + 1, 20);
      end;
    4:
      begin
        FCanvas.PutPixel(AX - 1, AY, 40);
        FCanvas.PutPixel(AX + 1, AY, 20);
      end;
    5:
      begin
        FCanvas.PutPixel(AX - 1, AY + 1, 40);
        FCanvas.PutPixel(AX + 1, AY - 1, 20);
      end;
    6:
      begin
        FCanvas.PutPixel(AX, AY + 1, 40);
        FCanvas.PutPixel(AX, AY - 1, 20);
      end;
    7:
      begin
        FCanvas.PutPixel(AX + 1, AY + 1, 40);
        FCanvas.PutPixel(AX - 1, AY - 1, 20);
      end;
  end;
end;

procedure TGreedHud.DisplayMapMode;
var
  LRow, LColumn, LOffsetX, LOffsetY, LX, LY, LPlayerX, LPlayerY, LMapY, LMapX, LColor, LStep: Integer;
  LMinY, LMaxY, LMinX, LMaxX, LMapSpot: Integer;

  procedure Square(AColor: Integer);
  var
    LDown, LRight: Integer;
  begin
    for LDown := 0 to 3 do
      for LRight := 0 to 3 do
        if (LX + LRight < WindowWidth) and (LX + LRight >= 0) and (LY + LDown < WindowHeight) and
          (LY + LDown >= 0) then
          FCanvas.PutPixel(LRight + LX, LY + LDown, AColor);
  end;

begin
  LY := WindowHeight div 4;
  LMinY := -(LY div 2);
  LMaxY := LY div 2;
  LX := WindowWidth div 4;
  LMinX := -(LX div 2);
  LMaxX := LX div 2;
  LOffsetX := 1 - (TGreedFixedMath.ShiftRight(FState.Player.X, GREED_FRACBITS + 4) and 3);
  LOffsetY := 1 - (TGreedFixedMath.ShiftRight(FState.Player.Y, GREED_FRACBITS + 4) and 3);
  LPlayerX := FState.Player.X div GREED_FRACTILEUNIT;
  LPlayerY := FState.Player.Y div GREED_FRACTILEUNIT;

  // the north walls
  LY := LOffsetY - 4;
  for LRow := LMinY to LMaxY do
  begin
    LY := LY + 4;
    LMapY := LPlayerY + LRow;
    if (LMapY < 0) or (LMapY >= MAP_ROWS) then
      Continue;
    LMapX := LPlayerX + LMinX;
    LMapSpot := LMapY * MAP_COLS + LMapX;
    LX := LOffsetX;
    for LColumn := LMinX to LMaxX do
    begin
      if (LMapX >= 0) and (LMapX < MAP_COLS) and (FState.Player.NorthMap[LMapSpot] <> 0) then
      begin
        LColor := FState.Player.NorthMap[LMapSpot];
        if LColor = GREED_DOOR_COLOR then
        begin
          for LStep := 0 to 4 do
          begin
            if (LX >= 0) and (LX < WindowWidth) and (LY + 2 < WindowHeight) and (LY + 2 >= 0) then
              FCanvas.PutPixel(LX, LY + 2, LColor);
            Inc(LX);
          end;
        end
        else
        begin
          for LStep := 0 to 4 do
          begin
            if (LX >= 0) and (LX < WindowWidth) and (LY < WindowHeight) and (LY >= 0) then
              FCanvas.PutPixel(LX, LY, LColor);
            Inc(LX);
          end;
        end;
        Dec(LX);
      end
      else
        LX := LX + 4;
      Inc(LMapSpot);
      Inc(LMapX);
    end;
  end;

  // the west walls
  LX := LOffsetX - 4;
  for LColumn := LMinX to LMaxX do
  begin
    LX := LX + 4;
    LMapX := LPlayerX + LColumn;
    if (LMapX < 0) or (LMapX >= MAP_COLS) then
      Continue;
    LMapY := LPlayerY + LMinY;
    LMapSpot := LMapY * MAP_COLS + LMapX;
    LY := LOffsetY;
    for LRow := LMinY to LMaxY do
    begin
      if (LMapY >= 0) and (LMapY < MAP_ROWS) and (FState.Player.WestMap[LMapSpot] <> 0) then
      begin
        LColor := FState.Player.WestMap[LMapSpot];
        if LColor = GREED_DOOR_COLOR then
        begin
          for LStep := 0 to 4 do
          begin
            if (LY >= 0) and (LY < WindowHeight) and (LX + 2 < WindowWidth) and (LX + 2 >= 0) then
              FCanvas.PutPixel(LX + 2, LY, LColor);
            Inc(LY);
          end;
        end
        else
        begin
          for LStep := 0 to 4 do
          begin
            if (LY >= 0) and (LY < WindowHeight) and (LX < WindowWidth) and (LX >= 0) then
              FCanvas.PutPixel(LX, LY, LColor);
            Inc(LY);
          end;
        end;
        Dec(LY);
      end
      else
        LY := LY + 4;
      LMapSpot := LMapSpot + MAP_COLS;
      Inc(LMapY);
    end;
  end;

  DisplayArrow(WindowWidth div 2 + 1, WindowHeight div 2 + 1);
  if FState.BonusItem.Score <> 0 then
  begin
    LY := LOffsetY + 4 * (FState.BonusItem.TileY - LPlayerY);
    LY := LY + WindowHeight div 2;
    LX := LOffsetX + 4 * (FState.BonusItem.TileX - LPlayerX);
    LX := LX + WindowWidth div 2;
    Square(COLOR_BONUS);
  end;
  if FState.ExitExists then
  begin
    LY := LOffsetY + 4 * (FState.ExitY - LPlayerY);
    LY := LY + WindowHeight div 2;
    LX := LOffsetX + 4 * (FState.ExitX - LPlayerX);
    LX := LX + WindowWidth div 2;
    Square(COLOR_EXIT);
  end;
end;

procedure TGreedHud.DisplaySwingMapMode;
var
  LRow, LColumn, LOffsetX, LOffsetY, LX, LY, LPlayerX, LPlayerY, LColor, LStep, LX1, LY1, LY2, LX2: Integer;
  LFracX, LFracY, LFracX2, LFracY2, LStepX, LStepY, LStepX2, LStepY2: TGreedFixed;
  LMapSpot: Integer;
  LZoom: Integer;
  LCosines, LSines: PGreedFixedArray;

  procedure Origin(out AFracX, AFracY: TGreedFixed);
  begin
    AFracX := ((WindowWidth div 2) * GREED_FRACUNIT) - (LPlayerY * LStepX2 + LPlayerX * LStepX);
    AFracY := ((WindowHeight div 2) * GREED_FRACUNIT) - (LPlayerY * LStepY2 + LPlayerX * LStepY);
  end;

  procedure Dot(AX, AY, AColor: Integer);
  begin
    if (AY >= 0) and (AX >= 0) and (AX < WindowWidth) and (AY < WindowHeight) then
      FCanvas.PutPixel(AX, AY, AColor);
  end;

  procedure Mark(ATileX, ATileY, AColor: Integer);
  begin
    LFracY2 := LFracY2 + LStepY2 * LZoom * ATileY + (LStepY2 * LZoom div 2);
    LFracX2 := LFracX2 + LStepX2 * LZoom * ATileY + (LStepX2 * LZoom div 2);
    LFracX := LFracX2 + LStepX * LZoom * ATileX + (LStepX * LZoom div 2);
    LFracY := LFracY2 + LStepY * LZoom * ATileX + (LStepY * LZoom div 2);
    LX1 := LFracX div GREED_FRACUNIT;
    LY1 := LFracY div GREED_FRACUNIT;
    Dot(LX1, LY1, AColor);
    Dot(LX1, LY1 + 1, AColor);
    Inc(LX1);
    Dot(LX1, LY1, AColor);
    Inc(LY1);
    Dot(LX1, LY1, AColor);
    Origin(LFracX2, LFracY2);
    LY := LFracY2 div GREED_FRACUNIT;
    LX := LFracX2 div GREED_FRACUNIT;
  end;

begin
  LZoom := FState.MapZoom;
  // the offset of the player inside his tile
  case LZoom of
    8:
      begin
        LOffsetX := 1 - (TGreedFixedMath.ShiftRight(FState.Player.X, GREED_FRACBITS + 3) and 7);
        LOffsetY := 1 - (TGreedFixedMath.ShiftRight(FState.Player.Y, GREED_FRACBITS + 3) and 7);
      end;
    4:
      begin
        LOffsetX := 1 - (TGreedFixedMath.ShiftRight(FState.Player.X, GREED_FRACBITS + 4) and 3);
        LOffsetY := 1 - (TGreedFixedMath.ShiftRight(FState.Player.Y, GREED_FRACBITS + 4) and 3);
      end;
    16:
      begin
        LOffsetX := 1 - (TGreedFixedMath.ShiftRight(FState.Player.X, GREED_FRACBITS + 2) and 15);
        LOffsetY := 1 - (TGreedFixedMath.ShiftRight(FState.Player.Y, GREED_FRACBITS + 2) and 15);
      end;
  else
    LOffsetX := 0;
    LOffsetY := 0;
  end;

  LPlayerX := (FState.Player.X div GREED_FRACTILEUNIT) * LZoom - LOffsetX;
  LPlayerY := (FState.Player.Y div GREED_FRACTILEUNIT) * LZoom - LOffsetY;
  // the steps of the two axes of the turned map
  LCosines := TGreedFineTables.Cosines;
  LSines := TGreedFineTables.Sines;
  LStepX := LCosines^[((FState.Player.Angle + ANGLE_SOUTH) and GREED_ANGLES) * GREED_FINE_UNIT];
  LStepY := LSines^[((FState.Player.Angle + ANGLE_SOUTH) and GREED_ANGLES) * GREED_FINE_UNIT];
  LStepX2 := LCosines^[(FState.Player.Angle and GREED_ANGLES) * GREED_FINE_UNIT];
  LStepY2 := LSines^[(FState.Player.Angle and GREED_ANGLES) * GREED_FINE_UNIT];
  Origin(LFracX2, LFracY2);
  LY := LFracY2 div GREED_FRACUNIT;
  LX := LFracX2 div GREED_FRACUNIT;
  LMapSpot := 0;
  if FState.BonusItem.Score <> 0 then
    Mark(FState.BonusItem.TileX, FState.BonusItem.TileY, COLOR_BONUS);
  if FState.ExitExists then
    Mark(FState.ExitX, FState.ExitY, COLOR_EXIT);

  // from the top left corner of the map: a row of north walls along one axis, the next row one step along the other
  for LRow := 0 to MAP_COLS - 1 do
  begin
    LFracX := LFracX2;
    LFracY := LFracY2;
    LX1 := LX;
    LY1 := LY;
    for LColumn := 0 to MAP_ROWS - 1 do
    begin
      if FState.Player.NorthMap[LMapSpot] <> 0 then
      begin
        LColor := FState.Player.NorthMap[LMapSpot];
        if LColor = GREED_DOOR_COLOR then
        begin
          for LStep := 0 to LZoom do
          begin
            LY2 := LY1 + (((LZoom div 2) * LStepY2) div GREED_FRACUNIT);
            LX2 := LX1 + (((LZoom div 2) * LStepX2) div GREED_FRACUNIT);
            Dot(LX2, LY2, LColor);
            LFracX := LFracX + LStepX;
            LX1 := LFracX div GREED_FRACUNIT;
            LFracY := LFracY + LStepY;
            LY1 := LFracY div GREED_FRACUNIT;
          end;
        end
        else
        begin
          for LStep := 0 to LZoom do
          begin
            Dot(LX1, LY1, LColor);
            LFracX := LFracX + LStepX;
            LX1 := LFracX div GREED_FRACUNIT;
            LFracY := LFracY + LStepY;
            LY1 := LFracY div GREED_FRACUNIT;
          end;
        end;
        LFracX := LFracX - LStepX;
        LX1 := LFracX div GREED_FRACUNIT;
        LFracY := LFracY - LStepY;
        LY1 := LFracY div GREED_FRACUNIT;
      end
      else
      begin
        LFracX := LFracX + LStepX * LZoom;
        LX1 := LFracX div GREED_FRACUNIT;
        LFracY := LFracY + LStepY * LZoom;
        LY1 := LFracY div GREED_FRACUNIT;
      end;
      Inc(LMapSpot);
    end;
    LFracY2 := LFracY2 + LStepY2 * LZoom;
    LY := LFracY2 div GREED_FRACUNIT;
    LFracX2 := LFracX2 + LStepX2 * LZoom;
    LX := LFracX2 div GREED_FRACUNIT;
  end;

  // the west walls, a column of the map at a time
  Origin(LFracX, LFracY);
  LY := LFracY div GREED_FRACUNIT;
  LX := LFracX div GREED_FRACUNIT;
  for LRow := 0 to MAP_COLS - 1 do
  begin
    LFracX2 := LFracX;
    LFracY2 := LFracY;
    LX1 := LX;
    LY1 := LY;
    LMapSpot := LRow;
    for LColumn := 0 to MAP_ROWS - 1 do
    begin
      if FState.Player.WestMap[LMapSpot] <> 0 then
      begin
        LColor := FState.Player.WestMap[LMapSpot];
        if LColor = GREED_DOOR_COLOR then
        begin
          for LStep := 0 to LZoom do
          begin
            LY2 := LY1 + (((LZoom div 2) * LStepY) div GREED_FRACUNIT);
            LX2 := LX1 + (((LZoom div 2) * LStepX) div GREED_FRACUNIT);
            Dot(LX2, LY2, LColor);
            LFracX2 := LFracX2 + LStepX2;
            LX1 := LFracX2 div GREED_FRACUNIT;
            LFracY2 := LFracY2 + LStepY2;
            LY1 := LFracY2 div GREED_FRACUNIT;
          end;
        end
        else
        begin
          for LStep := 0 to LZoom do
          begin
            Dot(LX1, LY1, LColor);
            LFracX2 := LFracX2 + LStepX2;
            LX1 := LFracX2 div GREED_FRACUNIT;
            LFracY2 := LFracY2 + LStepY2;
            LY1 := LFracY2 div GREED_FRACUNIT;
          end;
        end;
        LFracX2 := LFracX2 - LStepX2;
        LX1 := LFracX2 div GREED_FRACUNIT;
        LFracY2 := LFracY2 - LStepY2;
        LY1 := LFracY2 div GREED_FRACUNIT;
      end
      else
      begin
        LFracX2 := LFracX2 + LStepX2 * LZoom;
        LX1 := LFracX2 div GREED_FRACUNIT;
        LFracY2 := LFracY2 + LStepY2 * LZoom;
        LY1 := LFracY2 div GREED_FRACUNIT;
      end;
      LMapSpot := LMapSpot + MAP_COLS;
    end;
    LFracY := LFracY + LStepY * LZoom;
    LY := LFracY div GREED_FRACUNIT;
    LFracX := LFracX + LStepX * LZoom;
    LX := LFracX div GREED_FRACUNIT;
  end;
  FCanvas.PutPixel(WindowWidth div 2 + 1, WindowHeight div 2 + 1, COLOR_PLAYER);
end;

procedure TGreedHud.MarkTile(ATileX, ATileY, AColor: Integer);
begin
  FCanvas.PutPixel(ATileX + 3, ATileY + 21, AColor);
end;

procedure TGreedHud.DisplayHeatMode;
var
  LRow, LColumn, LColor, LLight: Integer;
begin
  for LRow := 0 to 63 do
    for LColumn := 0 to 63 do
    begin
      LLight := FLights.RealLight(LRow * 64 + LColumn);
      if LLight <> 0 then
      begin
        LColor := -LLight div 48;
        if LColor > 15 then
          LColor := 15
        else if LColor < 0 then
          LColor := 0;
        MarkTile(LColumn, LRow, 88 - LColor);
      end;
    end;
  FCanvas.FillRow(2, 20, 66, COLOR_SENSOR_FRAME);
  FCanvas.FillRow(2, 85, 66, COLOR_SENSOR_FRAME);
  for LRow := 21 to 84 do
  begin
    FCanvas.PutPixel(2, LRow, COLOR_SENSOR_FRAME);
    FCanvas.PutPixel(67, LRow, COLOR_SENSOR_FRAME);
  end;
  MarkTile(FState.Player.X div GREED_FRACTILEUNIT, FState.Player.Y div GREED_FRACTILEUNIT, COLOR_PLAYER);
  if FState.BonusItem.Score <> 0 then
    MarkTile(FState.BonusItem.TileX, FState.BonusItem.TileY, COLOR_BONUS);
  if FState.ExitExists then
    MarkTile(FState.ExitX, FState.ExitY, COLOR_EXIT);
end;

procedure TGreedHud.DisplayHeatMapMode;
var
  LRow, LColumn, LOffsetX, LOffsetY, LX, LY, LPlayerX, LPlayerY, LMapY, LMapX, LColor, LDown, LRight: Integer;
  LMinY, LMaxY, LMinX, LMaxX, LMapSpot, LLight: Integer;
begin
  LY := WindowHeight div 4;
  LMinY := -(LY div 2);
  LMaxY := LY div 2;
  LX := WindowWidth div 4;
  LMinX := -(LX div 2);
  LMaxX := LX div 2;
  LOffsetX := 1 - (TGreedFixedMath.ShiftRight(FState.Player.X, GREED_FRACBITS + 4) and 3);
  LOffsetY := 1 - (TGreedFixedMath.ShiftRight(FState.Player.Y, GREED_FRACBITS + 4) and 3);
  LPlayerX := FState.Player.X div GREED_FRACTILEUNIT;
  LPlayerY := FState.Player.Y div GREED_FRACTILEUNIT;
  LY := LOffsetY - 4;
  for LRow := LMinY to LMaxY do
  begin
    LY := LY + 4;
    LMapY := LPlayerY + LRow;
    if (LMapY < 0) or (LMapY >= MAP_ROWS) then
      Continue;
    LMapX := LPlayerX + LMinX;
    LMapSpot := LMapY * MAP_COLS + LMapX;
    LX := LOffsetX;
    for LColumn := LMinX to LMaxX do
    begin
      if (LMapX >= 0) and (LMapX < MAP_COLS) then
      begin
        LLight := FLights.RealLight(LMapSpot);
        if LLight <> 0 then
        begin
          LColor := -LLight div 48;
          if LColor > 15 then
            LColor := 15
          else if LColor < 0 then
            LColor := 0;
          LColor := 88 - LColor;
          for LDown := 0 to 3 do
            if (LY + LDown < WindowHeight) and (LY + LDown >= 0) then
              for LRight := 0 to 3 do
                if (LX + LRight < WindowWidth) and (LX + LRight >= 0) then
                  FCanvas.PutPixel(LRight + LX, LY + LDown, LColor);
        end;
      end;
      LX := LX + 4;
      Inc(LMapSpot);
      Inc(LMapX);
    end;
  end;
end;

procedure TGreedHud.DisplayMotionMode;
var
  LSprite: Integer;
  LItem: PGreedSprite;
  LRow: Integer;
begin
  LSprite := FState.Sprites.First;
  while LSprite <> GREED_POOL_NIL do
  begin
    LItem := PGreedSprite(FState.Sprites.Item(LSprite));
    if LItem^.Active and (LItem^.HitPoints <> 0) then
      MarkTile(LItem^.X div GREED_FRACTILEUNIT, LItem^.Y div GREED_FRACTILEUNIT, COLOR_MOTION);
    LSprite := FState.Sprites.Next(LSprite);
  end;
  FCanvas.FillRow(2, 20, 66, COLOR_SENSOR_FRAME);
  FCanvas.FillRow(2, 85, 66, COLOR_SENSOR_FRAME);
  for LRow := 21 to 84 do
  begin
    FCanvas.PutPixel(2, LRow, COLOR_SENSOR_FRAME);
    FCanvas.PutPixel(67, LRow, COLOR_SENSOR_FRAME);
  end;
  MarkTile(FState.Player.X div GREED_FRACTILEUNIT, FState.Player.Y div GREED_FRACTILEUNIT, COLOR_PLAYER);
  if FState.BonusItem.Score <> 0 then
    MarkTile(FState.BonusItem.TileX, FState.BonusItem.TileY, COLOR_BONUS);
  if FState.ExitExists then
    MarkTile(FState.ExitX, FState.ExitY, COLOR_EXIT);
end;

procedure TGreedHud.DisplayMotionMapMode;
var
  LOffsetX, LOffsetY, LX, LY, LDown, LRight, LPlayerX, LPlayerY: Integer;
  LSprite: Integer;
  LItem: PGreedSprite;
begin
  LOffsetX := 1 - (TGreedFixedMath.ShiftRight(FState.Player.X, GREED_FRACBITS + 4) and 3) + WindowWidth div 2;
  LOffsetY := 1 - (TGreedFixedMath.ShiftRight(FState.Player.Y, GREED_FRACBITS + 4) and 3) + WindowHeight div 2;
  LPlayerX := FState.Player.X div GREED_FRACTILEUNIT;
  LPlayerY := FState.Player.Y div GREED_FRACTILEUNIT;
  LSprite := FState.Sprites.First;
  while LSprite <> GREED_POOL_NIL do
  begin
    LItem := PGreedSprite(FState.Sprites.Item(LSprite));
    if LItem^.Active and (LItem^.HitPoints <> 0) then
    begin
      LX := (((LItem^.X div GREED_FRACTILEUNIT) - LPlayerX) * 4) + LOffsetX;
      LY := (((LItem^.Y div GREED_FRACTILEUNIT) - LPlayerY) * 4) + LOffsetY;
      for LDown := 0 to 3 do
        if (LY + LDown < WindowHeight) and (LY + LDown >= 0) then
          for LRight := 0 to 3 do
            if (LX + LRight < WindowWidth) and (LX + LRight >= 0) then
              FCanvas.PutPixel(LRight + LX, LY + LDown, COLOR_MOTION);
    end;
    LSprite := FState.Sprites.Next(LSprite);
  end;
end;

procedure TGreedHud.DrawDisplays;
begin
  if FState.MapMode = 1 then
    DisplayMapMode
  else if FState.MapMode = 2 then
    DisplaySwingMapMode
  else if FState.MapMode <> 0 then
    raise EGreedException.CreateFmt(SGreedBadMapMode, [FState.MapMode]);
  if FState.HeatMode then
  begin
    if FState.MapMode <> 0 then
      DisplayHeatMapMode
    else
      DisplayHeatMode;
  end;
  if FState.MotionMode then
  begin
    if FState.MapMode <> 0 then
      DisplayMotionMapMode
    else
      DisplayMotionMode;
  end;
end;

procedure TGreedHud.DrawStatusBar;
var
  LPicture: TBytes;
begin
  if (CurrentViewSize > 0) and (CurrentViewSize < GREED_MAXVIEWSIZE) then
  begin
    if CurrentViewSize = 4 then
      LPicture := FStatusBars[2]
    else
      LPicture := FStatusBars[CurrentViewSize - 1];
    FCanvas.DrawMaskedPicToBuffer(TGreedGameTables.StatusBarLocations[CurrentViewSize * 2],
      TGreedGameTables.StatusBarLocations[CurrentViewSize * 2 + 1], LPicture);
    if CurrentViewSize = 4 then
      FCanvas.DrawMaskedPic(0, 0, FStatusBars[3]);
  end;
end;

procedure TGreedHud.DrawOverlay;
begin
  DrawDisplays;
  DrawStatusBar;
  UpdateDisplay;
end;

procedure TGreedHud.DrawHolo;
begin
  if FState.Player.HoloPic <> 0 then
    DrawSprite(FState.Player.HoloPic, 5, WindowHeight - 5, True);
end;

procedure TGreedHud.DrawRearView(const ARearBuffer: TBytes);
var
  LX, LTop, LRow, LColumn: Integer;
begin
  if Length(ARearBuffer) < GREED_REAR_VIEW_SIZE * GREED_REAR_VIEW_SIZE then
    raise EGreedDataException.CreateFmt(SGreedImageTooShort,
      ['rear view', Length(ARearBuffer), GREED_REAR_VIEW_SIZE * GREED_REAR_VIEW_SIZE]);
  LX := WindowWidth - 65;
  if CurrentViewSize >= 4 then
    LTop := 10
  else
    LTop := 0;
  for LRow := 0 to GREED_REAR_VIEW_SIZE - 1 do
  begin
    for LColumn := 0 to GREED_REAR_VIEW_SIZE - 1 do
      FCanvas.PutPixel(LX + LColumn, LTop + LRow + 1, ARearBuffer[LRow * GREED_REAR_VIEW_SIZE + LColumn]);
    FCanvas.PutPixel(LX - 1, LTop + LRow + 1, COLOR_FRAME);
    FCanvas.PutPixel(LX + 64, LTop + LRow + 1, COLOR_FRAME);
  end;
  FCanvas.FillRow(LX - 1, LTop + 64, 66, COLOR_FRAME);
  FCanvas.FillRow(LX - 1, LTop + 1, 66, COLOR_FRAME);
end;

end.
