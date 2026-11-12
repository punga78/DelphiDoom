{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the greed library - the scenarios of the HUD            }
{                                                                              }
{  The same steps are given to the classes of the library (here) and to the     }
{  original display.pas, d_font.pas and d_video.pas of xGreed (the harness      }
{  Tools\Verifica\175-hud): the pixels of the buffer must be the same           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Greed.HudScenarios;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.Greed.Types, DelphiDoom.Greed.Intf, DelphiDoom.Greed.SaveTypes,
  DelphiDoom.Greed.Actor.Types, DelphiDoom.Greed.LinkedPool, DelphiDoom.Greed.World.Intf,
  DelphiDoom.Greed.Game.Intf, DelphiDoom.Greed.Game.State, DelphiDoom.Greed.Render.Assets.Intf,
  DelphiDoom.Greed.Render.State, DelphiDoom.Greed.Canvas, DelphiDoom.Greed.PaletteFader, DelphiDoom.Greed.Font,
  DelphiDoom.Greed.TextPrinter, DelphiDoom.Greed.MessageLine, DelphiDoom.Greed.Inventory,
  DelphiDoom.Greed.Hud.Intf, DelphiDoom.Greed.Hud, DelphiDoom.Greed.WeaponLight, DelphiDoom.Greed.WeaponPictures;

const
  HUD_SEED = 20261112;
  /// <summary>The sections of a run and how many cases each has</summary>
  HUD_PALETTE_CASES = 8;
  HUD_CANVAS_CASES = 40;
  HUD_TEXT_CASES = 60;
  HUD_SCENARIOS = 48;
  HUD_FRAMES = 12;
  /// <summary>The tables of the light of the scenarios (the lump "lights" of the synthetic data has as many)</summary>
  HUD_COLORMAPS = 32;

type
  /// <summary>The generator of the scenarios: the same numbers in the harness and in the tests</summary>
  THudRandom = record
    Seed: Cardinal;
    /// <summary>A number from 0 to ARange - 1</summary>
    function Next(ARange: Integer): Integer;
    function Chance(APercent: Integer): Boolean;
  end;

  /// <summary>FNV-1a of the numbers and texts that a step leaves behind</summary>
  THudTrace = record
    Hash: Cardinal;
    procedure Clear;
    procedure Add(AValue: Integer);
    procedure AddText(const AText: string);
    procedure AddBytes(const AData; ASize: Integer);
  end;

  THudSpriteSeed = record
    X, Y: TGreedFixed;
    Active: Boolean;
    HitPoints: Integer;
    BasePic: Integer;
    Scale: Integer;
  end;

  THudLight = record
    Spot: Integer;
    Value: Integer;
  end;

  THudInventoryOperation = (hioLeft, hioRight, hioUse, hioRefresh);

  /// <summary>One frame of a HUD scenario: the state of the game, what happens before the frame, what is drawn</summary>
  THudStep = record
    /// <summary>The first frame of a scenario sets the inventory and the effects too; later they change by the game</summary>
    First: Boolean;
    /// <summary>A scenario of the routines that draw only what changed (view sizes 5 .. 9, the buffer is not cleared)</summary>
    Delta: Boolean;
    ViewSize: Integer;
    TimeCount: Integer;
    Player: TGreedPlayerRecord;
    InventoryTime, GoalItem, SpecialEffect, SpecialEffectTime, MapMode, MapZoom, WeapMode: Integer;
    HeatMode, MotionMode, ExitExists: Boolean;
    ExitX, ExitY: Integer;
    BonusScore, BonusTime, BonusTileX, BonusTileY, BonusPic: Integer;
    BonusName: string;
    Primaries: array[0..3] of Integer;
    Secondaries: array[0..13] of Integer;
    PCount: array[0..1] of Integer;
    SCount: array[0..6] of Integer;
    Lights: TArray<THudLight>;
    Sprites: TArray<THudSpriteSeed>;
    // the light on the weapon
    MapEffect, MapLight, WallGlow, WallFlicker1, WallFlicker2, WallFlicker3, WallFlicker4, WallCycle: Integer;
    // what happens before the frame
    ResetDisplay: Boolean;
    Operations: TArray<THudInventoryOperation>;
    Messages: TArray<string>;
    LoadWeapon: Integer;
    // what is drawn
    DrawHolo, DrawRear, DrawWeapon: Boolean;
    RearSeed: Cardinal;
    WeaponX, WeaponY: Integer;
  end;

  THudCanvasOperationKind = (hcoSolid, hcoSolidUntranslated, hcoMasked, hcoMaskedToBuffer, hcoTrans, hcoLit);

  THudCanvasOperation = record
    Kind: THudCanvasOperationKind;
    Lump: Integer;
    X, Y: Integer;
    Colormap: Integer;
  end;

  THudCanvasCase = record
    ApproxZero: Byte;
    BackgroundSeed: Cardinal;
    Operations: TArray<THudCanvasOperation>;
  end;

  THudTextKind = (htkRaw1, htkRaw2, htkRaw3, htkRaw4, htkPrint, htkCentered, htkBlock);

  THudTextCase = record
    Kind: THudTextKind;
    FontNumber: Integer;
    BaseColor, Spacing, X, Y: Integer;
    ApproxZero: Byte;
    Text: string;
  end;

  THudPaletteCase = record
    Shown, Target: TBytes;
    Start, Stop, Red, Green, Blue, Steps: Integer;
  end;

  /// <summary>What the scenarios know of the archive: the lumps the HUD uses</summary>
  THudData = record
    Archive: IGreedArchive;
    /// <summary>The picture lumps the canvas cases draw (status bars, hearts, weapons)</summary>
    Pictures: TArray<Integer>;
    /// <summary>The numbers of the weapons whose lumps are in the archive</summary>
    Weapons: TArray<Integer>;
    /// <summary>medtube, primary and secondary</summary>
    InventoryLump, PrimaryLump, SecondaryLump: Integer;
    Fonts: array[1..3] of TBytes;
    /// <summary>The color tables: HUD_COLORMAPS * 256 bytes and the 512 the renderer wants after them</summary>
    ColorMaps: TBytes;
    Transparency: TBytes;
  end;

  /// <summary>Makes the data and the cases; everything depends only on the archive and on the numbers given</summary>
  THudScenarios = class
  public
    /// <summary>An archive with made up fonts, status bars, hearts, items, goals and weapons: no data of the game</summary>
    class function SyntheticArchive: IGreedArchive; static;
    class function Describe(const AArchive: IGreedArchive): THudData; static;
    class function PaletteCase(AIndex: Integer): THudPaletteCase; static;
    class function CanvasCase(const AData: THudData; AIndex: Integer): THudCanvasCase; static;
    class function TextCase(const AData: THudData; AIndex: Integer): THudTextCase; static;
    /// <summary>The frames of a scenario</summary>
    class function Frames(const AData: THudData; AScenario: Integer): TArray<THudStep>; static;
    /// <summary>The 64 x 64 picture of the rear view of a step, before its 0 are translated</summary>
    class function RearPicture(ASeed: Cardinal): TBytes; static;
    /// <summary>The noise the canvas cases start from (no 0)</summary>
    class function Background(ASeed: Cardinal; ASize: Integer): TBytes; static;
  end;

  THudSpawnFake = class(TInterfacedObject, IGreedSpawner, IGreedGameSound, IGreedPlayerHealth)
  public
    Trace: ^THudTrace;
    function SpawnSprite(AValue: Integer; AX, AY, AZ, AZAdjust: TGreedFixed; AAngle, AAngle2: Integer;
      AActive: Boolean; ASpawnId: Integer): Integer;
    procedure DemandLoadMonster(ALump, ACount: Integer);
    procedure SoundEffect(ASound, AVariation: Integer; AX, AY: TGreedFixed);
    procedure Hurt(AAmount: Integer);
    procedure Heal(AAmount: Integer);
    procedure MedPaks(AAmount: Integer);
    procedure AddScore(AAmount: Integer);
  end;

  THudAssetsFake = class(TInterfacedObject, IGreedRenderAssets)
  public
    ColorMapBytes: TBytes;
    function GetWallCount: Integer;
    function GetFlatCount: Integer;
    function WallLump(AIndex: Integer): TBytes;
    function FlatLump(AIndex: Integer): TBytes;
    function SpriteLump(ALump: Integer): TBytes;
    function ColorMaps: TBytes;
    function Transparency: TBytes;
    function Backdrop: TBytes;
  end;

  /// <summary>The classes of the library put together as a program would, run on the cases</summary>
  THudLibraryRunner = class
  strict private
    FData: THudData;
    FWorld: IGreedWorld;
    FSprites: TGreedLinkedPool<TGreedSprite>;
    FElevators: TGreedLinkedPool<TGreedElevator>;
    FState: TGreedGameState;
    FRenderState: TGreedRenderState;
    FCanvas: TGreedCanvas;
    FPrinter: TGreedTextPrinter;
    FFonts: array[1..3] of TGreedFont;
    FMessages: TGreedMessageLine;
    FMessagesIntf: IGreedMessages;
    FFake: THudSpawnFake;
    FFakeSpawner: IGreedSpawner;
    FInventory: TGreedInventory;
    FLight: TGreedWeaponLight;
    FLightIntf: IGreedWeaponLight;
    FHud: TGreedHud;
    FWeapons: TGreedWeaponPictures;
    FWeaponsIntf: IGreedWeaponView;
    FPictures: TArray<TBytes>;
    FLoaded: TArray<Boolean>;
    function Picture(ALump: Integer): TBytes;
    procedure Apply(const AStep: THudStep);
  public
    Trace: THudTrace;
    constructor Create(const AData: THudData);
    destructor Destroy; override;
    /// <summary>The approx zero and the FNV-1a of the palettes of every step of a fade out and of a fade in</summary>
    procedure RunPalette(const ACase: THudPaletteCase; out AApproxZero: Byte; out AHash: Cardinal);
    procedure RunCanvas(const ACase: THudCanvasCase);
    procedure RunText(const ACase: THudTextCase);
    /// <summary>One frame; the trace has what the step left in the state</summary>
    procedure RunFrame(const AStep: THudStep);
    function PixelHash: Cardinal;
    property Canvas: TGreedCanvas read FCanvas;
    property Printer: TGreedTextPrinter read FPrinter;
    property State: TGreedGameState read FState;
    property Hud: TGreedHud read FHud;
    property Inventory: TGreedInventory read FInventory;
    property Weapons: TGreedWeaponPictures read FWeapons;
    property Messages: TGreedMessageLine read FMessages;
  end;

/// <summary>FNV-1a of a block of memory, continued from AHash</summary>
function HudFnv(AHash: Cardinal; const AData; ASize: Integer): Cardinal;
/// <summary>The lines of the golden file for an archive, computed with the library</summary>
function HudLibraryLines(const AArchive: IGreedArchive): TStringList;

const
  HUD_FNV_START = 2166136261;

implementation

uses
  DelphiDoom.Greed.World, DelphiDoom.Greed.Render.Types, DelphiDoom.Tests.Greed.Builders;

function HudFnv(AHash: Cardinal; const AData; ASize: Integer): Cardinal;
var
  LIndex: Integer;
  LByte: PByte;
begin
  Result := AHash;
  LByte := @AData;
  for LIndex := 0 to ASize - 1 do
  begin
    Result := (Result xor LByte^) * 16777619;
    Inc(LByte);
  end;
end;

{ THudRandom }

function THudRandom.Next(ARange: Integer): Integer;
begin
  Seed := Seed * 1103515245 + 12345;
  if ARange <= 0 then
    Result := 0
  else
    Result := Integer((Seed shr 8) mod Cardinal(ARange));
end;

function THudRandom.Chance(APercent: Integer): Boolean;
begin
  Result := Next(100) < APercent;
end;

{ THudTrace }

procedure THudTrace.Clear;
begin
  Hash := HUD_FNV_START;
end;

procedure THudTrace.Add(AValue: Integer);
begin
  Hash := HudFnv(Hash, AValue, SizeOf(AValue));
end;

procedure THudTrace.AddBytes(const AData; ASize: Integer);
begin
  Hash := HudFnv(Hash, AData, ASize);
end;

procedure THudTrace.AddText(const AText: string);
var
  LIndex: Integer;
begin
  Add(Length(AText));
  for LIndex := 1 to Length(AText) do
    Add(Ord(AText[LIndex]));
end;

// ---------------------------------------------------------------------------------------------------------
// the synthetic data
// ---------------------------------------------------------------------------------------------------------

function SyntheticFont(AHeight: Integer; ASeed: Cardinal): TBytes;
var
  LRandom: THudRandom;
  LCharacter, LWidth, LOffset, LIndex: Integer;
begin
  LRandom.Seed := ASeed;
  SetLength(Result, GREED_FONT_HEADER_BYTES);
  FillChar(Result[0], Length(Result), 0);
  TGreedLumps.PutWord(Result, 0, AHeight);
  for LCharacter := 32 to 126 do
  begin
    if LCharacter = 32 then
      LWidth := 3
    else
      LWidth := 2 + LRandom.Next(5);
    LOffset := Length(Result);
    Result[2 + LCharacter] := LWidth;
    TGreedLumps.PutWord(Result, 2 + 256 + 2 * LCharacter, LOffset);
    SetLength(Result, LOffset + LWidth * AHeight);
    for LIndex := 0 to LWidth * AHeight - 1 do
      if (LCharacter = 32) or LRandom.Chance(45) then
        Result[LOffset + LIndex] := 0
      else
        Result[LOffset + LIndex] := 1 + LRandom.Next(6);
  end;
end;

function SyntheticPicture(AWidth, AHeight, AOriginX, AOriginY: Integer; ASeed: Cardinal): TBytes;
var
  LRandom: THudRandom;
  LIndex, LRoll: Integer;
begin
  LRandom.Seed := ASeed;
  SetLength(Result, GREED_PICTURE_HEADER_BYTES + AWidth * AHeight);
  TGreedLumps.PutWord(Result, 0, AWidth);
  TGreedLumps.PutWord(Result, 2, AHeight);
  TGreedLumps.PutWord(Result, 4, AOriginX);
  TGreedLumps.PutWord(Result, 6, AOriginY);
  for LIndex := 0 to AWidth * AHeight - 1 do
  begin
    LRoll := LRandom.Next(100);
    if LRoll < 25 then
      Result[GREED_PICTURE_HEADER_BYTES + LIndex] := 0
    else if LRoll < 55 then
      Result[GREED_PICTURE_HEADER_BYTES + LIndex] := 254
    else
      Result[GREED_PICTURE_HEADER_BYTES + LIndex] := 1 + LRandom.Next(253);
  end;
end;

function SyntheticSprite(AWidth, AMaxHeight: Integer; ASeed: Cardinal): TBytes;
var
  LRandom: THudRandom;
  LColumn, LTop, LCount, LOffset, LIndex: Integer;
begin
  LRandom.Seed := ASeed;
  SetLength(Result, GREED_SPRITE_HEADER_BYTES + 2 * AWidth);
  FillChar(Result[0], Length(Result), 0);
  TGreedLumps.PutWord(Result, 0, AWidth div 2);
  TGreedLumps.PutWord(Result, 2, AWidth);
  for LColumn := 0 to AWidth - 1 do
  begin
    if LRandom.Chance(15) then
      Continue;
    LTop := LRandom.Next(4);
    LCount := 1 + LRandom.Next(AMaxHeight - LTop);
    LOffset := Length(Result);
    TGreedLumps.PutWord(Result, GREED_SPRITE_HEADER_BYTES + 2 * LColumn, LOffset);
    SetLength(Result, LOffset + 2 + LCount);
    // as display.pas reads a column: the first byte minus the second, plus one, is the number of pixels
    Result[LOffset] := LTop + LCount - 1;
    Result[LOffset + 1] := LTop;
    for LIndex := 0 to LCount - 1 do
      if LRandom.Chance(20) then
        Result[LOffset + 2 + LIndex] := 0
      else
        Result[LOffset + 2 + LIndex] := 1 + LRandom.Next(255);
  end;
end;

function SyntheticBytes(ASize: Integer; ASeed: Cardinal; ARange: Integer): TBytes;
var
  LRandom: THudRandom;
  LIndex: Integer;
begin
  LRandom.Seed := ASeed;
  SetLength(Result, ASize);
  for LIndex := 0 to ASize - 1 do
    Result[LIndex] := LRandom.Next(ARange);
end;

class function THudScenarios.SyntheticArchive: IGreedArchive;
var
  LBlo: TGreedBlo;
  LIndex, LWeapon, LPicture: Integer;
  LLumps: TGreedWeaponLumps;
  LName: string;
begin
  LBlo := TGreedBlo.Create;
  try
    LBlo.Add('palette', SyntheticBytes(768, 11, 64));
    LBlo.Add('FONT1', SyntheticFont(5, 21));
    LBlo.Add('FONT2', SyntheticFont(6, 22));
    LBlo.Add('FONT3', SyntheticFont(8, 23));
    LBlo.Add('STATBAR1', SyntheticPicture(100, 51, 0, 0, 31));
    LBlo.Add('STATBAR2', SyntheticPicture(316, 51, 0, 0, 32));
    LBlo.Add('STATBAR3', SyntheticPicture(316, 51, 0, 0, 33));
    LBlo.Add('STATBAR4', SyntheticPicture(320, 12, 0, 0, 34));
    for LIndex := 0 to 9 do
    begin
      if LIndex = 0 then
        LName := 'HEART'
      else
        LName := 'heart' + IntToStr(LIndex);
      LBlo.Add(LName, SyntheticPicture(37, 25, 0, 0, 40 + LIndex));
    end;
    for LIndex := 0 to GREED_MAX_INVENTORY - 1 do
    begin
      if LIndex = 0 then
        LName := 'medtube'
      else
        LName := 'item' + IntToStr(LIndex);
      LBlo.Add(LName, SyntheticSprite(12 + LIndex, 22, 60 + LIndex));
    end;
    for LIndex := Low(GreedPrimaryNames) to High(GreedPrimaryNames) do
    begin
      if LIndex = 0 then
        LName := 'primary'
      else
        LName := 'prim' + IntToStr(LIndex);
      LBlo.Add(LName, SyntheticSprite(10 + LIndex, 28, 100 + LIndex));
    end;
    for LIndex := Low(GreedSecondaryNames) to High(GreedSecondaryNames) do
    begin
      if LIndex = 0 then
        LName := 'secondary'
      else
        LName := 'sec' + IntToStr(LIndex);
      LBlo.Add(LName, SyntheticSprite(8 + LIndex mod 24, 28, 200 + LIndex));
    end;
    for LWeapon := 0 to 18 do
    begin
      LLumps := TGreedWeaponPictures.LumpsOf(LWeapon);
      for LPicture := 0 to LLumps.Count - 1 do
      begin
        if LPicture = 0 then
          LName := LLumps.Name
        else
          LName := LLumps.Name + IntToStr(LPicture);
        if LPicture = 0 then
          LBlo.Add(LName, SyntheticPicture(60 + LWeapon * 3, 50 + LWeapon * 2, 0, 0, 300 + LWeapon * 8))
        else
          LBlo.Add(LName, SyntheticPicture(50 + LWeapon * 4 + LPicture, 40 + LWeapon + LPicture * 7, LPicture * 3,
            LPicture * 2, 300 + LWeapon * 8 + LPicture));
      end;
    end;
    LBlo.Add('TRANSPARENCY', SyntheticBytes(GREED_TRANSPARENCY_BYTES, 501, 256));
    LBlo.Add('lights', SyntheticBytes(HUD_COLORMAPS * 256, 502, 256));
    Result := LBlo.Open;
  finally
    LBlo.Free;
  end;
end;

class function THudScenarios.Describe(const AArchive: IGreedArchive): THudData;
var
  LIndex, LWeapon, LPicture, LFirst: Integer;
  LLumps: TGreedWeaponLumps;
  LLights: TBytes;

  procedure AddPicture(ALump: Integer);
  begin
    SetLength(Result.Pictures, Length(Result.Pictures) + 1);
    Result.Pictures[High(Result.Pictures)] := ALump;
  end;

begin
  Result.Archive := AArchive;
  Result.Pictures := nil;
  Result.Weapons := nil;
  for LIndex := 1 to 4 do
    AddPicture(AArchive.RequireIndexOf('STATBAR' + IntToStr(LIndex)));
  LFirst := AArchive.RequireIndexOf('HEART');
  for LIndex := 0 to 9 do
    AddPicture(LFirst + LIndex);
  for LWeapon := 0 to 18 do
  begin
    LLumps := TGreedWeaponPictures.LumpsOf(LWeapon);
    if (LLumps.Count > 0) and (AArchive.IndexOf(LLumps.Name) >= 0) then
    begin
      SetLength(Result.Weapons, Length(Result.Weapons) + 1);
      Result.Weapons[High(Result.Weapons)] := LWeapon;
      for LPicture := 0 to LLumps.Count - 1 do
        AddPicture(AArchive.IndexOf(LLumps.Name) + LPicture);
    end;
  end;
  Result.InventoryLump := AArchive.RequireIndexOf('medtube');
  Result.PrimaryLump := AArchive.RequireIndexOf('primary');
  Result.SecondaryLump := AArchive.RequireIndexOf('secondary');
  for LIndex := 1 to 3 do
    Result.Fonts[LIndex] := AArchive.ReadLump(AArchive.RequireIndexOf('FONT' + IntToStr(LIndex)));
  Result.Transparency := AArchive.ReadLump(AArchive.RequireIndexOf('TRANSPARENCY'));
  // the first HUD_COLORMAPS tables of the lights of the archive, padded with the last one if there are fewer
  LLights := AArchive.ReadLump(AArchive.RequireIndexOf('lights'));
  SetLength(Result.ColorMaps, HUD_COLORMAPS * 256 + 512);
  FillChar(Result.ColorMaps[0], Length(Result.ColorMaps), 0);
  for LIndex := 0 to HUD_COLORMAPS * 256 - 1 do
    if LIndex < Length(LLights) then
      Result.ColorMaps[LIndex] := LLights[LIndex]
    else
      Result.ColorMaps[LIndex] := Byte(LIndex);
end;

// ---------------------------------------------------------------------------------------------------------
// the cases
// ---------------------------------------------------------------------------------------------------------

class function THudScenarios.PaletteCase(AIndex: Integer): THudPaletteCase;
var
  LRandom: THudRandom;
  LRange: Integer;
begin
  LRandom.Seed := HUD_SEED + 1000 + Cardinal(AIndex);
  // the first cases are 6 bit palettes as the game has, the others use the whole byte
  if AIndex < HUD_PALETTE_CASES div 2 then
    LRange := 64
  else
    LRange := 256;
  Result.Shown := SyntheticBytes(768, LRandom.Seed + 1, LRange);
  Result.Target := SyntheticBytes(768, LRandom.Seed + 2, LRange);
  if AIndex mod 3 = 2 then
  begin
    // some colors equal to the color 0: the search of the approx zero stops at the first
    Result.Shown[30] := Result.Shown[0];
    Result.Shown[31] := Result.Shown[1];
    Result.Shown[32] := Result.Shown[2];
  end;
  if AIndex mod 2 = 0 then
  begin
    Result.Start := 0;
    Result.Stop := 256;
  end
  else
  begin
    Result.Start := LRandom.Next(100);
    Result.Stop := Result.Start + 1 + LRandom.Next(256 - Result.Start);
  end;
  Result.Red := LRandom.Next(LRange);
  Result.Green := LRandom.Next(LRange);
  Result.Blue := LRandom.Next(LRange);
  if AIndex = 0 then
  begin
    Result.Red := 0;
    Result.Green := 0;
    Result.Blue := 0;
  end;
  case AIndex mod 4 of
    0: Result.Steps := 64;
    1: Result.Steps := 20;
    2: Result.Steps := 1;
  else
    Result.Steps := 2 + LRandom.Next(100);
  end;
end;

class function THudScenarios.Background(ASeed: Cardinal; ASize: Integer): TBytes;
var
  LIndex: Integer;
begin
  Result := SyntheticBytes(ASize, ASeed, 255);
  for LIndex := 0 to ASize - 1 do
    Inc(Result[LIndex]);
end;

class function THudScenarios.RearPicture(ASeed: Cardinal): TBytes;
begin
  Result := SyntheticBytes(GREED_REAR_VIEW_SIZE * GREED_REAR_VIEW_SIZE, ASeed, 6);
end;

class function THudScenarios.CanvasCase(const AData: THudData; AIndex: Integer): THudCanvasCase;
var
  LRandom: THudRandom;
  LIndex, LWidth, LHeight: Integer;
  LLump: TBytes;
begin
  LRandom.Seed := HUD_SEED + 2000 + Cardinal(AIndex);
  Result.ApproxZero := 1 + LRandom.Next(255);
  Result.BackgroundSeed := LRandom.Seed;
  SetLength(Result.Operations, 3 + LRandom.Next(6));
  for LIndex := 0 to High(Result.Operations) do
  begin
    Result.Operations[LIndex].Kind := THudCanvasOperationKind(LRandom.Next(Ord(High(THudCanvasOperationKind)) + 1));
    Result.Operations[LIndex].Lump := AData.Pictures[LRandom.Next(Length(AData.Pictures))];
    Result.Operations[LIndex].Colormap := LRandom.Next(HUD_COLORMAPS);
    LLump := AData.Archive.ReadLump(Result.Operations[LIndex].Lump);
    LWidth := TGreedCanvas.PictureWidth(LLump);
    LHeight := TGreedCanvas.PictureHeight(LLump);
    case Result.Operations[LIndex].Kind of
      hcoSolid, hcoSolidUntranslated:
        begin
          // the original copies whole rows without a check: only inside the screen
          Result.Operations[LIndex].X := LRandom.Next(GREED_CANVAS_WIDTH - LWidth + 1);
          Result.Operations[LIndex].Y := LRandom.Next(GREED_CANVAS_HEIGHT - LHeight + 1);
        end;
      hcoMasked, hcoMaskedToBuffer:
        begin
          // these are clipped by the original: anywhere, also half outside
          Result.Operations[LIndex].X := LRandom.Next(GREED_CANVAS_WIDTH + LWidth) - LWidth + 5;
          Result.Operations[LIndex].Y := LRandom.Next(GREED_CANVAS_HEIGHT + LHeight) - LHeight + 5;
        end;
    else
      // the original checks the rows and not the columns (and the lit one only the bottom)
      Result.Operations[LIndex].X := 8 + LRandom.Next(GREED_CANVAS_WIDTH - LWidth - 15);
      if Result.Operations[LIndex].Kind = hcoTrans then
        Result.Operations[LIndex].Y := LRandom.Next(GREED_CANVAS_HEIGHT + LHeight) - LHeight + 5
      else
        Result.Operations[LIndex].Y := LRandom.Next(GREED_CANVAS_HEIGHT);
    end;
  end;
end;

function RandomText(var ARandom: THudRandom; ALength: Integer): string;
var
  LIndex: Integer;
begin
  SetLength(Result, ALength);
  for LIndex := 1 to ALength do
    if ARandom.Chance(15) then
      Result[LIndex] := ' '
    else
      Result[LIndex] := Char(33 + ARandom.Next(94));
end;

// cuts a line until the font can print it inside AWidth pixels (the original has no check and would go on in the next row)
function FitText(const AFont: TBytes; const AText: string; AWidth: Integer): string;
var
  LFont: TGreedFont;
begin
  Result := AText;
  LFont := TGreedFont.Create(AFont);
  try
    while (Result <> '') and (LFont.RawWidth(Result) > AWidth) do
      SetLength(Result, Length(Result) - 1);
  finally
    LFont.Free;
  end;
end;

function FontHeight(const AFont: TBytes): Integer;
begin
  Result := SmallInt(AFont[0] or (AFont[1] shl 8));
end;

class function THudScenarios.TextCase(const AData: THudData; AIndex: Integer): THudTextCase;
var
  LRandom: THudRandom;
  LLines, LLine, LHeight: Integer;
  LText: string;
begin
  LRandom.Seed := HUD_SEED + 3000 + Cardinal(AIndex);
  Result.Kind := THudTextKind(AIndex mod (Ord(High(THudTextKind)) + 1));
  Result.FontNumber := 1 + (AIndex div 7) mod 3;
  Result.BaseColor := LRandom.Next(200);
  Result.Spacing := 1;
  Result.ApproxZero := 1 + LRandom.Next(255);
  LHeight := FontHeight(AData.Fonts[Result.FontNumber]);
  Result.X := LRandom.Next(60);
  Result.Y := LRandom.Next(60);
  case Result.Kind of
    htkRaw1, htkRaw2, htkRaw3, htkRaw4:
      // every length, from nothing to what fits in the row
      Result.Text := FitText(AData.Fonts[Result.FontNumber], RandomText(LRandom, LRandom.Next(80)),
        GREED_CANVAS_WIDTH - Result.X - 2);
  else
    LLines := 1 + LRandom.Next(5);
    // the lines after the first start at the left edge
    Result.Text := '';
    for LLine := 0 to LLines - 1 do
    begin
      LText := FitText(AData.Fonts[Result.FontNumber], RandomText(LRandom, LRandom.Next(50)),
        GREED_CANVAS_WIDTH - 62);
      if LRandom.Chance(15) then
        LText := '';
      if LLine > 0 then
        Result.Text := Result.Text + #10;
      Result.Text := Result.Text + LText;
    end;
    if Result.Y + LLines * LHeight >= GREED_CANVAS_HEIGHT then
      Result.Y := 0;
  end;
end;

class function THudScenarios.Frames(const AData: THudData; AScenario: Integer): TArray<THudStep>;
var
  LRandom: THudRandom;
  LFrame, LIndex, LCount, LTime, LViewSize, LWeapon: Integer;
  LDelta: Boolean;
  LStep: THudStep;
  LLump: TBytes;
  LNames: array[0..7] of string;

  function ItemPicture: Integer;
  begin
    case LRandom.Next(3) of
      0: Result := AData.InventoryLump + LRandom.Next(GREED_MAX_INVENTORY);
      1: Result := AData.PrimaryLump + LRandom.Next(Length(GreedPrimaryNames));
    else
      Result := AData.SecondaryLump + LRandom.Next(Length(GreedSecondaryNames));
    end;
  end;

begin
  LRandom.Seed := HUD_SEED + 4000 + Cardinal(AScenario) * 977;
  LNames[0] := 'Bonus';
  LNames[1] := 'Rubber Chicken of Doom';
  LNames[2] := '';
  LNames[3] := 'A name of thirty two characters!';
  LNames[4] := 'x';
  LNames[5] := 'Golden Toilet Seat';
  LNames[6] := 'Stuffed Animal';
  LNames[7] := 'Fuzzy Dice';
  // one scenario in six is of the routines of the sizes 5 .. 9
  LDelta := AScenario mod 6 = 5;
  if LDelta then
    LViewSize := 5 + (AScenario div 6) mod 5
  else
    LViewSize := AScenario mod 5;
  LTime := LRandom.Next(5000);
  SetLength(Result, HUD_FRAMES);
  LStep := Default(THudStep);
  for LFrame := 0 to HUD_FRAMES - 1 do
  begin
    LStep.First := LFrame = 0;
    LStep.Delta := LDelta;
    // the size of the view changes now and then (not in a delta scenario: its screen is never cleared)
    if (not LDelta) and (LFrame > 0) and LRandom.Chance(25) then
      LViewSize := LRandom.Next(5);
    LStep.ViewSize := LViewSize;
    LTime := LTime + 1 + LRandom.Next(180);
    LStep.TimeCount := LTime;
    // ---- the player ----
    if LStep.First then
    begin
      LStep.Player := Default(TGreedPlayerRecord);
      for LIndex := 0 to GREED_MAX_INVENTORY - 1 do
        if LRandom.Chance(55) then
          LStep.Player.Inventory[LIndex] := 1 + LRandom.Next(12);
      if AScenario mod 7 = 3 then
        FillChar(LStep.Player.Inventory, SizeOf(LStep.Player.Inventory), 0);
      LStep.Player.MaxShield := 100 + LRandom.Next(400);
      LStep.Player.MaxAngst := 100 + LRandom.Next(400);
      LStep.Player.CharType := LRandom.Next(6);
      for LIndex := 0 to 4 do
        LStep.Player.Weapons[LIndex] := LRandom.Next(19);
      FillChar(LStep.Player.NorthMap, SizeOf(LStep.Player.NorthMap), 0);
      FillChar(LStep.Player.WestMap, SizeOf(LStep.Player.WestMap), 0);
      for LIndex := 0 to 600 + LRandom.Next(1200) do
        if LRandom.Chance(12) then
          LStep.Player.NorthMap[LRandom.Next(GREED_MAP_TILES)] := GREED_DOOR_COLOR
        else
          LStep.Player.NorthMap[LRandom.Next(GREED_MAP_TILES)] := 1 + LRandom.Next(255);
      for LIndex := 0 to 600 + LRandom.Next(1200) do
        if LRandom.Chance(12) then
          LStep.Player.WestMap[LRandom.Next(GREED_MAP_TILES)] := GREED_DOOR_COLOR
        else
          LStep.Player.WestMap[LRandom.Next(GREED_MAP_TILES)] := 1 + LRandom.Next(255);
      LStep.SpecialEffect := 0;
      LStep.SpecialEffectTime := $7FFFFFFF;
      if LRandom.Chance(50) then
        LStep.SpecialEffectTime := LTime + LRandom.Next(900);
    end;
    LStep.Player.Shield := LRandom.Next(LStep.Player.MaxShield + 1);
    LStep.Player.Angst := LRandom.Next(LStep.Player.MaxAngst + 1);
    if LRandom.Chance(8) then
      LStep.Player.Angst := 0;
    if LRandom.Chance(8) then
      LStep.Player.Angst := LStep.Player.MaxAngst;
    LStep.Player.Angle := LRandom.Next(GREED_ANGLES + 1);
    if LRandom.Chance(5) then
      LStep.Player.Angle := GREED_ANGLES - GREED_DEGREE45_2;
    LStep.Player.X := (LRandom.Next(62) + 1) * GREED_FRACTILEUNIT + LRandom.Next(GREED_FRACTILEUNIT);
    LStep.Player.Y := (LRandom.Next(62) + 1) * GREED_FRACTILEUNIT + LRandom.Next(GREED_FRACTILEUNIT);
    if LRandom.Chance(10) then
    begin
      // a corner of the map: the map modes look outside it
      LStep.Player.X := LRandom.Next(3) * GREED_FRACTILEUNIT + 77777;
      LStep.Player.Y := (61 + LRandom.Next(3)) * GREED_FRACTILEUNIT + 99999;
    end;
    LStep.Player.Z := LRandom.Next(200) * GREED_FRACUNIT;
    LStep.Player.Height := (40 + LRandom.Next(30)) * GREED_FRACUNIT;
    LStep.Player.ScrollMin := LRandom.Next(40) - 20;
    LStep.Player.MapSpot := (LStep.Player.Y div GREED_FRACTILEUNIT) * GREED_MAP_SIZE +
      (LStep.Player.X div GREED_FRACTILEUNIT);
    LStep.Player.CurrentWeapon := LRandom.Next(5);
    for LIndex := 0 to 2 do
      LStep.Player.Ammo[LIndex] := LRandom.Next(1000);
    LStep.Player.BodyCount := LRandom.Next(100000);
    LStep.Player.Score := LRandom.Next(2000000000);
    LStep.Player.LevelScore := LRandom.Next(999999999);
    for LIndex := 0 to 1 do
      LStep.Player.Primaries[LIndex] := LRandom.Next(100);
    for LIndex := 0 to 6 do
      LStep.Player.Secondaries[LIndex] := LRandom.Next(100);
    // ---- the game ----
    LStep.InventoryTime := LTime + LRandom.Next(200) - 100;
    LStep.GoalItem := LRandom.Next(11) - 1;
    for LIndex := 0 to 1 do
    begin
      LStep.Primaries[LIndex * 2] := LRandom.Next(Length(GreedPrimaryNames));
      LStep.Primaries[LIndex * 2 + 1] := LRandom.Next(100000);
      LStep.PCount[LIndex] := LRandom.Next(100);
    end;
    for LIndex := 0 to 6 do
    begin
      LStep.Secondaries[LIndex * 2] := LRandom.Next(Length(GreedSecondaryNames));
      LStep.Secondaries[LIndex * 2 + 1] := LRandom.Next(100000);
      LStep.SCount[LIndex] := LRandom.Next(100);
    end;
    LStep.BonusScore := 0;
    if LRandom.Chance(70) then
      LStep.BonusScore := 1 + LRandom.Next(99999);
    LStep.BonusTime := LTime + LRandom.Next(70 * 400) - 300;
    if LRandom.Chance(5) then
      LStep.BonusTime := LTime + 70 * 20000;
    LStep.BonusTileX := LRandom.Next(64);
    LStep.BonusTileY := LRandom.Next(64);
    LStep.BonusPic := ItemPicture;
    LStep.BonusName := LNames[LRandom.Next(Length(LNames))];
    LStep.MapMode := 0;
    LStep.HeatMode := False;
    LStep.MotionMode := False;
    if not LDelta then
    begin
      LStep.MapMode := LRandom.Next(3);
      LStep.HeatMode := LRandom.Chance(40);
      LStep.MotionMode := LRandom.Chance(40);
    end;
    case LRandom.Next(3) of
      0: LStep.MapZoom := 4;
      1: LStep.MapZoom := 8;
    else
      LStep.MapZoom := 16;
    end;
    LStep.ExitExists := LRandom.Chance(50);
    LStep.ExitX := LRandom.Next(64);
    LStep.ExitY := LRandom.Next(64);
    SetLength(LStep.Lights, LRandom.Next(300));
    for LIndex := 0 to High(LStep.Lights) do
    begin
      LStep.Lights[LIndex].Spot := LRandom.Next(GREED_MAP_TILES);
      LStep.Lights[LIndex].Value := LRandom.Next(1400) - 1000;
    end;
    SetLength(LStep.Sprites, LRandom.Next(40));
    for LIndex := 0 to High(LStep.Sprites) do
    begin
      LStep.Sprites[LIndex].X := LRandom.Next(64) * GREED_FRACTILEUNIT + LRandom.Next(GREED_FRACTILEUNIT);
      LStep.Sprites[LIndex].Y := LRandom.Next(64) * GREED_FRACTILEUNIT + LRandom.Next(GREED_FRACTILEUNIT);
      LStep.Sprites[LIndex].Active := LRandom.Chance(60);
      LStep.Sprites[LIndex].HitPoints := 0;
      if LRandom.Chance(65) then
        LStep.Sprites[LIndex].HitPoints := 1 + LRandom.Next(500);
      LStep.Sprites[LIndex].BasePic := ItemPicture;
      LStep.Sprites[LIndex].Scale := LRandom.Next(4);
    end;
    // ---- the light on the weapon ----
    LStep.MapEffect := LRandom.Next(12);
    if LRandom.Chance(40) then
      LStep.MapEffect := 0;
    LStep.MapLight := LRandom.Next(20);
    LStep.WallGlow := LRandom.Next(HUD_COLORMAPS);
    LStep.WallFlicker1 := LRandom.Next(HUD_COLORMAPS);
    LStep.WallFlicker2 := LRandom.Next(HUD_COLORMAPS);
    LStep.WallFlicker3 := LRandom.Next(HUD_COLORMAPS);
    LStep.WallFlicker4 := LRandom.Next(40) - 20;
    LStep.WallCycle := LRandom.Next(4);
    // ---- what happens ----
    LStep.ResetDisplay := LStep.First or LRandom.Chance(10);
    SetLength(LStep.Operations, LRandom.Next(4));
    for LIndex := 0 to High(LStep.Operations) do
      LStep.Operations[LIndex] := THudInventoryOperation(LRandom.Next(4));
    LCount := 0;
    if LRandom.Chance(45) then
      LCount := 1 + LRandom.Next(3);
    SetLength(LStep.Messages, LCount);
    for LIndex := 0 to LCount - 1 do
      // every length, from nothing to what fits in the row
      LStep.Messages[LIndex] := FitText(AData.Fonts[1], RandomText(LRandom, LRandom.Next(90)),
        GREED_CANVAS_WIDTH - 6);
    LStep.LoadWeapon := -1;
    if LStep.First or LRandom.Chance(30) then
    begin
      LStep.LoadWeapon := LRandom.Next(19);
      if (Length(AData.Weapons) > 0) and (LStep.First or LRandom.Chance(85)) then
        LStep.LoadWeapon := AData.Weapons[LRandom.Next(Length(AData.Weapons))];
    end;
    LWeapon := LStep.LoadWeapon;
    // ---- what is drawn ----
    LStep.DrawHolo := (not LDelta) and LRandom.Chance(50);
    LStep.DrawRear := (not LDelta) and LRandom.Chance(35);
    LStep.RearSeed := LRandom.Seed;
    LStep.DrawWeapon := (not LDelta) and (Length(AData.Weapons) > 0) and LRandom.Chance(85);
    LStep.WeapMode := 0;
    if LRandom.Chance(40) then
      LStep.WeapMode := LRandom.Next(2);
    // the place of the weapon is as UpdateWeaponView gives it: centered, more or less, and on the bottom edge
    if LWeapon >= 0 then
      LLump := AData.Archive.ReadLump(AData.Archive.IndexOf(TGreedWeaponPictures.LumpsOf(AData.Weapons[0]).Name));
    LStep.WeaponX := 100 + LRandom.Next(40);
    LStep.WeaponY := 90 + LRandom.Next(100);
    Result[LFrame] := LStep;
    LStep.Lights := nil;
    LStep.Sprites := nil;
    LStep.Operations := nil;
    LStep.Messages := nil;
  end;
end;

{ THudSpawnFake }

function THudSpawnFake.SpawnSprite(AValue: Integer; AX, AY, AZ, AZAdjust: TGreedFixed; AAngle, AAngle2: Integer;
  AActive: Boolean; ASpawnId: Integer): Integer;
begin
  Trace^.Add(1);
  Trace^.Add(AValue);
  Trace^.Add(AX);
  Trace^.Add(AY);
  Trace^.Add(AZ);
  Trace^.Add(AZAdjust);
  Trace^.Add(AAngle);
  Trace^.Add(AAngle2);
  Trace^.Add(Ord(AActive));
  Trace^.Add(ASpawnId);
  Result := GREED_POOL_NIL;
end;

procedure THudSpawnFake.DemandLoadMonster(ALump, ACount: Integer);
begin
end;

procedure THudSpawnFake.SoundEffect(ASound, AVariation: Integer; AX, AY: TGreedFixed);
begin
  Trace^.Add(2);
  Trace^.Add(ASound);
  Trace^.Add(AVariation);
  Trace^.Add(AX);
  Trace^.Add(AY);
end;

procedure THudSpawnFake.Hurt(AAmount: Integer);
begin
end;

procedure THudSpawnFake.Heal(AAmount: Integer);
begin
  Trace^.Add(3);
  Trace^.Add(AAmount);
end;

procedure THudSpawnFake.MedPaks(AAmount: Integer);
begin
  Trace^.Add(4);
  Trace^.Add(AAmount);
end;

procedure THudSpawnFake.AddScore(AAmount: Integer);
begin
end;

{ THudAssetsFake }

function THudAssetsFake.Backdrop: TBytes;
begin
  Result := nil;
end;

function THudAssetsFake.ColorMaps: TBytes;
begin
  Result := ColorMapBytes;
end;

function THudAssetsFake.FlatLump(AIndex: Integer): TBytes;
begin
  Result := nil;
end;

function THudAssetsFake.GetFlatCount: Integer;
begin
  Result := 0;
end;

function THudAssetsFake.GetWallCount: Integer;
begin
  Result := 0;
end;

function THudAssetsFake.SpriteLump(ALump: Integer): TBytes;
begin
  Result := nil;
end;

function THudAssetsFake.Transparency: TBytes;
begin
  Result := nil;
end;

function THudAssetsFake.WallLump(AIndex: Integer): TBytes;
begin
  Result := nil;
end;

{ THudLibraryRunner }

constructor THudLibraryRunner.Create(const AData: THudData);
var
  LAssets: THudAssetsFake;
  LIndex: Integer;
begin
  inherited Create;
  FData := AData;
  FWorld := TGreedWorld.Create;
  FSprites := TGreedLinkedPool<TGreedSprite>.Create(GREED_MAX_SPRITES, 'sprites');
  FElevators := TGreedLinkedPool<TGreedElevator>.Create(GREED_MAX_ELEVATORS, 'elevators');
  FState := TGreedGameState.Create(FWorld, FSprites, FElevators);
  FState.PlayerNum := 1;
  LAssets := THudAssetsFake.Create;
  LAssets.ColorMapBytes := AData.ColorMaps;
  FRenderState := TGreedRenderState.Create(LAssets);
  FCanvas := TGreedCanvas.Create;
  FCanvas.SetTransparency(AData.Transparency);
  FPrinter := TGreedTextPrinter.Create(FCanvas);
  for LIndex := 1 to 3 do
    FFonts[LIndex] := TGreedFont.Create(AData.Fonts[LIndex]);
  FMessages := TGreedMessageLine.Create(FState, FPrinter, FFonts[1]);
  FMessagesIntf := FMessages;
  FFake := THudSpawnFake.Create;
  FFake.Trace := @Trace;
  FFakeSpawner := FFake;
  FInventory := TGreedInventory.Create(FState, FFake, FFake, FFake, FMessagesIntf);
  FLight := TGreedWeaponLight.Create(FRenderState);
  FLightIntf := FLight;
  FHud := TGreedHud.Create(FState, FCanvas, FPrinter, FInventory, AData.Archive, FLight, FFonts[2], FFonts[3]);
  FWeapons := TGreedWeaponPictures.Create(FState, AData.Archive, FCanvas, FLightIntf);
  FWeaponsIntf := FWeapons;
  SetLength(FPictures, AData.Archive.LumpCount);
  SetLength(FLoaded, AData.Archive.LumpCount);
  Trace.Clear;
end;

destructor THudLibraryRunner.Destroy;
var
  LIndex: Integer;
begin
  FWeaponsIntf := nil;
  FHud.Free;
  FLightIntf := nil;
  FInventory.Free;
  FFakeSpawner := nil;
  FMessagesIntf := nil;
  for LIndex := 1 to 3 do
    FFonts[LIndex].Free;
  FPrinter.Free;
  FCanvas.Free;
  FRenderState.Free;
  FState.Free;
  FElevators.Free;
  FSprites.Free;
  inherited;
end;

function THudLibraryRunner.Picture(ALump: Integer): TBytes;
begin
  // one copy of each lump for the whole run, as the lump cache of the original: DrawPicSolid changes it
  if not FLoaded[ALump] then
  begin
    FPictures[ALump] := FData.Archive.ReadLump(ALump);
    FLoaded[ALump] := True;
  end;
  Result := FPictures[ALump];
end;

function THudLibraryRunner.PixelHash: Cardinal;
begin
  Result := HudFnv(HUD_FNV_START, FCanvas.Pixels[0], Length(FCanvas.Pixels));
end;

procedure THudLibraryRunner.RunPalette(const ACase: THudPaletteCase; out AApproxZero: Byte; out AHash: Cardinal);
var
  LFader: TGreedPaletteFader;
begin
  AApproxZero := TGreedPaletteFader.ApproximateZero(ACase.Shown);
  AHash := HUD_FNV_START;
  LFader := TGreedPaletteFader.Create;
  try
    LFader.StartFadeOut(ACase.Shown, ACase.Start, ACase.Stop, ACase.Red, ACase.Green, ACase.Blue, ACase.Steps);
    while LFader.Step do
      AHash := HudFnv(AHash, LFader.Current[0], GREED_FADE_PALETTE_BYTES);
    LFader.StartFadeIn(ACase.Shown, ACase.Target, ACase.Start, ACase.Stop, ACase.Steps);
    while LFader.Step do
      AHash := HudFnv(AHash, LFader.Current[0], GREED_FADE_PALETTE_BYTES);
  finally
    LFader.Free;
  end;
end;

procedure THudLibraryRunner.RunCanvas(const ACase: THudCanvasCase);
var
  LBackground: TBytes;
  LIndex: Integer;
  LPicture: TBytes;
begin
  FCanvas.ApproxZero := ACase.ApproxZero;
  LBackground := THudScenarios.Background(ACase.BackgroundSeed, Length(FCanvas.Pixels));
  Move(LBackground[0], FCanvas.Pixels[0], Length(LBackground));
  for LIndex := 0 to High(ACase.Operations) do
  begin
    LPicture := Picture(ACase.Operations[LIndex].Lump);
    case ACase.Operations[LIndex].Kind of
      hcoSolid:
        FCanvas.DrawPicSolid(ACase.Operations[LIndex].X, ACase.Operations[LIndex].Y, LPicture);
      hcoSolidUntranslated:
        FCanvas.DrawPicSolidUntranslated(ACase.Operations[LIndex].X, ACase.Operations[LIndex].Y, LPicture);
      hcoMasked:
        FCanvas.DrawMaskedPic(ACase.Operations[LIndex].X, ACase.Operations[LIndex].Y, LPicture);
      hcoMaskedToBuffer:
        FCanvas.DrawMaskedPicToBuffer(ACase.Operations[LIndex].X, ACase.Operations[LIndex].Y, LPicture);
      hcoTrans:
        FCanvas.DrawTransPicToBuffer(ACase.Operations[LIndex].X, ACase.Operations[LIndex].Y, LPicture);
      hcoLit:
        FCanvas.DrawMaskedPicToBuffer2(ACase.Operations[LIndex].X, ACase.Operations[LIndex].Y, LPicture,
          @FData.ColorMaps[ACase.Operations[LIndex].Colormap * 256], GREED_CANVAS_HEIGHT);
    end;
  end;
end;

procedure THudLibraryRunner.RunText(const ACase: THudTextCase);
begin
  FCanvas.ApproxZero := ACase.ApproxZero;
  FCanvas.Clear;
  FPrinter.Font := FFonts[ACase.FontNumber];
  FPrinter.BaseColor := ACase.BaseColor;
  FPrinter.Spacing := ACase.Spacing;
  FPrinter.PrintX := ACase.X;
  FPrinter.PrintY := ACase.Y;
  case ACase.Kind of
    htkRaw1: FPrinter.RawPrint(ACase.Text);
    htkRaw2: FPrinter.RawPrint2(ACase.Text);
    htkRaw3: FPrinter.RawPrint3(ACase.Text);
    htkRaw4: FPrinter.RawPrint4(ACase.Text);
    htkPrint: FPrinter.Print(ACase.Text);
    htkCentered: FPrinter.PrintCentered(ACase.Text);
    htkBlock: FPrinter.BlockCenterPrint(ACase.Text);
  end;
  Trace.Clear;
  Trace.Add(FPrinter.PrintX);
  Trace.Add(FPrinter.PrintY);
  Trace.Add(FPrinter.RawWidth(ACase.Text));
end;

procedure THudLibraryRunner.Apply(const AStep: THudStep);
var
  LIndex, LSprite: Integer;
  LItem: PGreedSprite;
  LInventory: array[0..GREED_MAX_INVENTORY - 1] of Integer;
  LHoloPic, LHoloScale: Integer;
begin
  Move(FState.Player.Inventory, LInventory, SizeOf(LInventory));
  LHoloPic := FState.Player.HoloPic;
  LHoloScale := FState.Player.HoloScale;
  FState.Player := AStep.Player;
  if not AStep.First then
  begin
    Move(LInventory, FState.Player.Inventory, SizeOf(LInventory));
    FState.Player.HoloPic := LHoloPic;
    FState.Player.HoloScale := LHoloScale;
  end
  else
  begin
    FState.SpecialEffect := AStep.SpecialEffect;
    FState.SpecialEffectTime := AStep.SpecialEffectTime;
    FState.WarpJammer := False;
    FCanvas.ApproxZero := 1 + AStep.TimeCount mod 255;
  end;
  FState.TimeCount := AStep.TimeCount;
  FState.InventoryTime := AStep.InventoryTime;
  FState.GoalItem := AStep.GoalItem;
  FState.ToggleGoalItem := False;
  FState.MapMode := AStep.MapMode;
  FState.MapZoom := AStep.MapZoom;
  FState.WeapMode := AStep.WeapMode;
  FState.HeatMode := AStep.HeatMode;
  FState.MotionMode := AStep.MotionMode;
  FState.ExitExists := AStep.ExitExists;
  FState.ExitX := AStep.ExitX;
  FState.ExitY := AStep.ExitY;
  for LIndex := 0 to 3 do
    FState.Primaries[LIndex] := AStep.Primaries[LIndex];
  for LIndex := 0 to 13 do
    FState.Secondaries[LIndex] := AStep.Secondaries[LIndex];
  for LIndex := 0 to 1 do
    FState.PCount[LIndex] := AStep.PCount[LIndex];
  for LIndex := 0 to 6 do
    FState.SCount[LIndex] := AStep.SCount[LIndex];
  // the sprites of the step and, last, the one of the bonus item
  FSprites.Clear;
  for LIndex := 0 to High(AStep.Sprites) do
  begin
    LSprite := FSprites.Add;
    LItem := PGreedSprite(FSprites.Item(LSprite));
    LItem^.X := AStep.Sprites[LIndex].X;
    LItem^.Y := AStep.Sprites[LIndex].Y;
    LItem^.Active := AStep.Sprites[LIndex].Active;
    LItem^.HitPoints := AStep.Sprites[LIndex].HitPoints;
    LItem^.BasePic := AStep.Sprites[LIndex].BasePic;
    LItem^.Scale := AStep.Sprites[LIndex].Scale;
  end;
  LSprite := FSprites.Add;
  LItem := PGreedSprite(FSprites.Item(LSprite));
  LItem^.X := AStep.BonusTileX * GREED_FRACTILEUNIT;
  LItem^.Y := AStep.BonusTileY * GREED_FRACTILEUNIT;
  LItem^.BasePic := AStep.BonusPic;
  FState.BonusItem.Sprite := LSprite;
  FState.BonusItem.Score := AStep.BonusScore;
  FState.BonusItem.Time := AStep.BonusTime;
  FState.BonusItem.TileX := AStep.BonusTileX;
  FState.BonusItem.TileY := AStep.BonusTileY;
  FState.BonusItem.Name := AStep.BonusName;
  // the renderer
  FillChar(FRenderState.RealLight, SizeOf(FRenderState.RealLight), 0);
  for LIndex := 0 to High(AStep.Lights) do
    FRenderState.RealLight[AStep.Lights[LIndex].Spot] := AStep.Lights[LIndex].Value;
  FRenderState.MapEffects[AStep.Player.MapSpot] := AStep.MapEffect;
  FRenderState.MapLights[AStep.Player.MapSpot] := AStep.MapLight;
  FRenderState.WallGlow := AStep.WallGlow;
  FRenderState.WallFlicker1 := AStep.WallFlicker1;
  FRenderState.WallFlicker2 := AStep.WallFlicker2;
  FRenderState.WallFlicker3 := AStep.WallFlicker3;
  FRenderState.WallFlicker4 := AStep.WallFlicker4;
  FRenderState.WallCycle := AStep.WallCycle;
  FHud.CurrentViewSize := AStep.ViewSize;
end;

procedure THudLibraryRunner.RunFrame(const AStep: THudStep);
var
  LIndex: Integer;
  LRear: TBytes;
begin
  Trace.Clear;
  Apply(AStep);
  if AStep.ResetDisplay then
    FHud.ResetDisplay;
  for LIndex := 0 to High(AStep.Operations) do
    case AStep.Operations[LIndex] of
      hioLeft: FInventory.Left;
      hioRight: FInventory.Right;
      hioUse: FInventory.Use;
      hioRefresh: FHud.RefreshInventory;
    end;
  FInventory.ThrowGrenade;
  for LIndex := 0 to High(AStep.Messages) do
    FMessagesIntf.WriteMessage(AStep.Messages[LIndex]);
  if AStep.LoadWeapon >= 0 then
    FWeaponsIntf.LoadWeapon(AStep.LoadWeapon);
  if AStep.Delta then
  begin
    if AStep.First then
    begin
      // the screen of the DOS game: the bars are drawn once and stay
      FCanvas.Clear;
      FCanvas.DrawPicSolidUntranslated(4, 149, Picture(FData.Pictures[2]));
      FCanvas.DrawPicSolidUntranslated(0, 0, Picture(FData.Pictures[3]));
    end;
  end
  else
    FCanvas.Clear;
  if AStep.DrawHolo then
    FHud.DrawHolo;
  if AStep.DrawRear then
  begin
    LRear := THudScenarios.RearPicture(AStep.RearSeed);
    FCanvas.TranslateBuffer(LRear, 0, Length(LRear));
    FHud.DrawRearView(LRear);
  end;
  if AStep.DrawWeapon then
    FWeapons.Draw(AStep.WeaponX, AStep.WeaponY, FHud.WindowHeight);
  FHud.DrawOverlay;
  FMessages.Rewrite(FHud.CurrentViewSize);
  // what the frame left behind
  Trace.Add(FHud.OldShots);
  Trace.Add(FHud.OldGoalItem);
  Trace.Add(FHud.OldAngle);
  Trace.Add(FHud.OldAngst);
  Trace.Add(FHud.OldAngstPic);
  Trace.Add(FHud.OldShield);
  Trace.Add(FHud.OldBodyCount);
  Trace.Add(FHud.OldScore);
  Trace.Add(FHud.OldLevelScore);
  Trace.Add(FHud.StatCursor);
  Trace.Add(FInventory.Cursor);
  Trace.Add(FInventory.OldInventory);
  Trace.Add(FInventory.TotalEffectTime);
  Trace.Add(Ord(FInventory.FireGrenade));
  Trace.Add(Ord(FState.ToggleGoalItem));
  Trace.Add(FPrinter.PrintX);
  Trace.Add(FPrinter.PrintY);
  for LIndex := 0 to GREED_MAX_INVENTORY - 1 do
    Trace.Add(FState.Player.Inventory[LIndex]);
  Trace.Add(FState.Player.HoloPic);
  Trace.Add(FState.Player.HoloScale);
  Trace.Add(FState.SpecialEffect);
  Trace.Add(FState.SpecialEffectTime);
  Trace.Add(Ord(FState.WarpJammer));
  for LIndex := 0 to 18 do
  begin
    Trace.Add(FState.Weapons[LIndex].Charge);
    Trace.Add(FState.Weapons[LIndex].ChargeTime);
  end;
  for LIndex := 0 to GREED_WEAPON_PICTURES - 1 do
  begin
    Trace.Add(FWeapons.PictureWidth(LIndex));
    Trace.Add(FWeapons.PictureHeight(LIndex));
  end;
end;

function HudLibraryLines(const AArchive: IGreedArchive): TStringList;
var
  LData: THudData;
  LRunner: THudLibraryRunner;
  LIndex, LFrame: Integer;
  LApprox: Byte;
  LHash: Cardinal;
  LFrames: TArray<THudStep>;
begin
  Result := TStringList.Create;
  try
    LData := THudScenarios.Describe(AArchive);
    LRunner := THudLibraryRunner.Create(LData);
    try
      for LIndex := 0 to HUD_PALETTE_CASES - 1 do
      begin
        LRunner.RunPalette(THudScenarios.PaletteCase(LIndex), LApprox, LHash);
        Result.Add(Format('P %d %d %s', [LIndex, LApprox, IntToHex(LHash, 8)]));
      end;
      for LIndex := 0 to HUD_CANVAS_CASES - 1 do
      begin
        LRunner.RunCanvas(THudScenarios.CanvasCase(LData, LIndex));
        Result.Add(Format('C %d %s', [LIndex, IntToHex(LRunner.PixelHash, 8)]));
      end;
      for LIndex := 0 to HUD_TEXT_CASES - 1 do
      begin
        LRunner.RunText(THudScenarios.TextCase(LData, LIndex));
        Result.Add(Format('T %d %s %s', [LIndex, IntToHex(LRunner.PixelHash, 8), IntToHex(LRunner.Trace.Hash, 8)]));
      end;
      for LIndex := 0 to HUD_SCENARIOS - 1 do
      begin
        LFrames := THudScenarios.Frames(LData, LIndex);
        for LFrame := 0 to High(LFrames) do
        begin
          LRunner.RunFrame(LFrames[LFrame]);
          Result.Add(Format('H %d %d %s %s', [LIndex, LFrame, IntToHex(LRunner.PixelHash, 8),
            IntToHex(LRunner.Trace.Hash, 8)]));
        end;
      end;
    finally
      LRunner.Free;
    end;
  except
    Result.Free;
    raise;
  end;
end;

end.
