{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom battlescape drawing library - the map of the battlefield    }
{  (Map: the tiles, the walls, the objects, the units, the smoke and the fire,  }
{  the cursor and the arrow of the selected unit)                               }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBattlescape.Map;

interface

uses
  System.SysUtils, System.Classes, System.Math, System.Generics.Collections, DelphiDoom.XcomMod.MapBlock,
  DelphiDoom.XcomSurface.Types, DelphiDoom.XcomSurface.Surface, DelphiDoom.XcomSurface.Shade,
  DelphiDoom.XcomBattle.Types, DelphiDoom.XcomBattle.Model, DelphiDoom.XcomBattle.SavedBattleGame,
  DelphiDoom.XcomMod.Random, DelphiDoom.XcomBattlescape.Camera, DelphiDoom.XcomBattlescape.Sprites.Intf,
  DelphiDoom.XcomBattlescape.Particle, DelphiDoom.XcomBattlescape.Explosion;

type
  /// <summary>The numbers the map needs from the rules and the screen that are not in the saved battle</summary>
  TXcomBattleMapSettings = record
    /// <summary>The size of the map surface (the whole screen)</summary>
    Width: Integer;
    Height: Integer;
    /// <summary>The panel of the icons at the bottom (interface "battlescape", element "icons")</summary>
    IconWidth: Integer;
    IconHeight: Integer;
    /// <summary>Mod::SMOKE_OFFSET and Mod::UNDERWATER_SMOKE_OFFSET</summary>
    SmokeOffset: Integer;
    UnderwaterSmokeOffset: Integer;
    /// <summary>
    ///   The transparency tables (TXcomTransparencyTable.Build, 1024 bytes per tint): the particles are drawn through
    ///   them; empty draws none, as the C++ does for a tint that has no table
    /// </summary>
    Transparencies: TBytes;
  end;

  /// <summary>
  ///   The picture of the battle: Map::draw clears the surface and draws every tile from the lowest level to the
  ///   one in view, in rows from the back to the front, with its walls, objects, units and effects. It keeps the
  ///   drawings of the units (the cache that BattleUnit holds in the C++) and the frame of the animation.
  ///   It also keeps the particles of the vapor of the shots under water (that the C++ keeps in the tiles) and
  ///   draws them through the transparency tables.
  ///   Not drawn: projectiles in flight, explosions, the preview of the path, the waypoints, the message of the
  ///   hidden movement
  /// </summary>
  TXcomBattleMap = class
  strict private
    FSave: TXcomSavedBattleGame;
    FSprites: IXcomBattleSprites;
    FSettings: TXcomBattleMapSettings;
    FSurface: TXcomSurface;
    FCamera: TXcomCamera;
    FArrow: TXcomSurface;
    FCaches: TObjectDictionary<TXcomBattleUnit, TObjectList<TXcomSurface>>;
    FParticles: TObjectDictionary<TXcomTile, TObjectList<TXcomParticle>>;
    FParticleRandom: IXcomRandom;
    FExplosions: TObjectList<TXcomExplosion>;
    FExplosionInFov: Boolean;
    FFlashScreen: Boolean;
    FSpriteWidth: Integer;
    FSpriteHeight: Integer;
    FSelectorX: Integer;
    FSelectorY: Integer;
    FCursorType: Integer;
    FCursorSize: Integer;
    FAnimFrame: Integer;
    FUnitDying: Boolean;
    FRedraw: Boolean;
    FWhat: string;
    FTileText: string;
    FBlitCount: Integer;
    FSkipBlit: Integer;
    FShadeDelta: Integer;
    FShowObstacles: Boolean;
    FTrace: TStrings;
    procedure CreateArrow;
    function TileSprite(const ATile: TXcomTile; APart: Integer): TXcomSurface;
    function GetTerrainLevel(const APosition: TXcomPosition; ASize: Integer): Integer;
    procedure DrawUnit(const AUnitTile, ACurrentTile: TXcomTile; const ATileScreen: TXcomPosition; AShade,
      AObstacleShade: Integer; ATopLayer: Boolean);
    procedure DrawTerrain;
    procedure DrawParticles(const ATile: TXcomTile; const AScreen: TXcomPosition);
    procedure AnimateParticles(const ATile: TXcomTile);
    procedure BlitShade(const ASource: TXcomSurface; AX, AY, AShade: Integer; AHalf: Boolean = False);
  public
    constructor Create(const ASave: TXcomSavedBattleGame; const ASprites: IXcomBattleSprites;
      const ASettings: TXcomBattleMapSettings);
    destructor Destroy; override;
    /// <summary>Map::draw: false when the screen of the hidden movement would be shown (it is not drawn here)</summary>
    function Draw: Boolean;
    /// <summary>animate: the next frame of the animation, the tiles and the units that always move</summary>
    procedure Animate(ARedraw: Boolean);
    /// <summary>cacheUnits</summary>
    procedure CacheUnits;
    /// <summary>cacheUnit: draws the unit again when its cache is not valid</summary>
    procedure CacheUnit(const AUnit: TXcomBattleUnit);
    /// <summary>calculateWalkingOffset</summary>
    procedure CalculateWalkingOffset(const AUnit: TXcomBattleUnit; out AOffset: TXcomPosition;
      out AShadeOffset: Integer);
    procedure SetCursorType(ACursorType: Integer; ASize: Integer = 1);
    procedure SetSelectorPosition(AX, AY: Integer);
    procedure Invalidate;
    /// <summary>Projectile::addVaporCloud: ADensity particles at the voxel, on the tile that holds it</summary>
    procedure AddVaporCloud(const AVoxel: TXcomPosition; ADensity, AColor: Integer);
    /// <summary>Tile::addParticle (the map keeps them, the tile of the model does not know them)</summary>
    procedure AddParticle(const ATile: TXcomTile; const AParticle: TXcomParticle);
    /// <summary>
    ///   getExplosions()->push_back(new Explosion(...)): the sprite is drawn when ExplosionInFov is set
    /// </summary>
    procedure AddExplosion(const ACenter: TXcomPosition; AStartFrame, AFrameDelay: Integer; ABig, AHit: Boolean);
    /// <summary>
    ///   The step of the animation that ExplosionBState::think does on the list: every explosion advances, those that
    ///   are over are removed; false when the list is empty
    /// </summary>
    function AnimateExplosions: Boolean;
    /// <summary>setExplosionInFOV</summary>
    property ExplosionInFov: Boolean read FExplosionInFov write FExplosionInFov;
    /// <summary>The next draw is the flash of the blast (setBlastFlash): it is off again after the draw</summary>
    property FlashScreen: Boolean read FFlashScreen write FFlashScreen;
    property Explosions: TObjectList<TXcomExplosion> read FExplosions;
    /// <summary>resetObstacles: clears the obstacle marks of the tiles and stops showing them</summary>
    procedure ResetObstacles;
    /// <summary>enableObstacles: the tiles that block the shot are drawn with the obstacle shade (the owner stops it)</summary>
    procedure EnableObstacles;
    /// <summary>disableObstacles</summary>
    procedure DisableObstacles;
    property ShowObstacles: Boolean read FShowObstacles;
    /// <summary>Removes every particle</summary>
    procedure ClearParticles;
    /// <summary>Tile::getParticleCloud: the particles of the tile (not owned), nil if it has none</summary>
    function ParticlesOf(const ATile: TXcomTile): TObjectList<TXcomParticle>;
    /// <summary>The generator of the jitter of the particles (RNG::seedless): a time seed unless it is replaced</summary>
    property ParticleRandom: IXcomRandom read FParticleRandom write FParticleRandom;
    property Camera: TXcomCamera read FCamera;
    property Surface: TXcomSurface read FSurface;
    property CursorType: Integer read FCursorType;
    property AnimFrame: Integer read FAnimFrame;
    property UnitDying: Boolean read FUnitDying write FUnitDying;
    /// <summary>For the tests that look for a difference: the draw skips the blit with this number (0 based), -1 none</summary>
    property SkipBlit: Integer read FSkipBlit write FSkipBlit;
    /// <summary>With SkipBlit set and this not zero, that blit is drawn with the shade changed by this much</summary>
    property ShadeDelta: Integer read FShadeDelta write FShadeDelta;
    /// <summary>The number of blits of the last draw (counted from Draw)</summary>
    property BlitCount: Integer read FBlitCount;
    /// <summary>For the tests and the logs: every blit of a draw is added here (not owned), or nil</summary>
    property Trace: TStrings read FTrace write FTrace;
  end;

implementation

uses
  System.Types, DelphiDoom.XcomMod.MapData, DelphiDoom.XcomMod.MapDataSet, DelphiDoom.XcomSurface.SurfaceSet,
  DelphiDoom.XcomBattlescape.UnitSprite;

const
  PART_FLOOR = 0;
  PART_WEST_WALL = 1;
  PART_NORTH_WALL = 2;
  PART_OBJECT = 3;
  BLOCK_COLOR_BLACK = 15;
  ARROW_BOB: array[0..7] of Integer = (0, 1, 2, 1, 0, 1, 2, 1);

constructor TXcomBattleMap.Create(const ASave: TXcomSavedBattleGame; const ASprites: IXcomBattleSprites;
  const ASettings: TXcomBattleMapSettings);
var
  LBlanks: TXcomSurface;
begin
  inherited Create;
  FSave := ASave;
  FSprites := ASprites;
  FSettings := ASettings;
  FSurface := TXcomSurface.Create(ASettings.Width, ASettings.Height);
  LBlanks := FSprites.SurfaceSet('BLANKS.PCK').GetFrame(0);
  FSpriteWidth := LBlanks.Width;
  FSpriteHeight := LBlanks.Height;
  FCamera := TXcomCamera.Create(FSpriteWidth, FSpriteHeight, FSave.MapSizeX, FSave.MapSizeY, FSave.MapSizeZ,
    ASettings.Width, ASettings.Height, ASettings.Height - ASettings.IconHeight, ASettings.IconWidth,
    ASettings.IconHeight);
  FCamera.OnChanged :=
    procedure
    begin
      FRedraw := True;
    end;
  FCaches := TObjectDictionary<TXcomBattleUnit, TObjectList<TXcomSurface>>.Create([doOwnsValues]);
  FParticles := TObjectDictionary<TXcomTile, TObjectList<TXcomParticle>>.Create([doOwnsValues]);
  FExplosions := TObjectList<TXcomExplosion>.Create(True);
  FParticleRandom := TXcomRandom.Create(UInt64(TThread.GetTickCount64) or 1);
  FSkipBlit := -1;
  FCursorType := CT_NORMAL;
  FCursorSize := 1;
  FRedraw := True;
  CreateArrow;
end;

destructor TXcomBattleMap.Destroy;
begin
  FExplosions.Free;
  FParticles.Free;
  FCaches.Free;
  FArrow.Free;
  FCamera.Free;
  FSurface.Free;
  inherited Destroy;
end;

procedure TXcomBattleMap.CreateArrow;
var
  LPixels: array[0..80] of Integer;
  LX: Integer;
  LY: Integer;
  LF: Integer;
  LB: Integer;
begin
  // the tiny arrow of the selected unit: yellow with a black border
  LF := 1 * 16; // Palette::blockOffset(1)
  LB := 15;
  LPixels[0] := 0;  LPixels[1] := 0;  LPixels[2] := LB; LPixels[3] := LB; LPixels[4] := LB; LPixels[5] := LB; LPixels[6] := LB; LPixels[7] := 0; LPixels[8] := 0;
  LPixels[9] := 0;  LPixels[10] := 0; LPixels[11] := LB; LPixels[12] := LF; LPixels[13] := LF; LPixels[14] := LF; LPixels[15] := LB; LPixels[16] := 0; LPixels[17] := 0;
  LPixels[18] := 0; LPixels[19] := 0; LPixels[20] := LB; LPixels[21] := LF; LPixels[22] := LF; LPixels[23] := LF; LPixels[24] := LB; LPixels[25] := 0; LPixels[26] := 0;
  LPixels[27] := LB; LPixels[28] := LB; LPixels[29] := LB; LPixels[30] := LF; LPixels[31] := LF; LPixels[32] := LF; LPixels[33] := LB; LPixels[34] := LB; LPixels[35] := LB;
  LPixels[36] := LB; LPixels[37] := LF; LPixels[38] := LF; LPixels[39] := LF; LPixels[40] := LF; LPixels[41] := LF; LPixels[42] := LF; LPixels[43] := LF; LPixels[44] := LB;
  LPixels[45] := 0; LPixels[46] := LB; LPixels[47] := LF; LPixels[48] := LF; LPixels[49] := LF; LPixels[50] := LF; LPixels[51] := LF; LPixels[52] := LB; LPixels[53] := 0;
  LPixels[54] := 0; LPixels[55] := 0; LPixels[56] := LB; LPixels[57] := LF; LPixels[58] := LF; LPixels[59] := LF; LPixels[60] := LB; LPixels[61] := 0; LPixels[62] := 0;
  LPixels[63] := 0; LPixels[64] := 0; LPixels[65] := 0; LPixels[66] := LB; LPixels[67] := LF; LPixels[68] := LB; LPixels[69] := 0; LPixels[70] := 0; LPixels[71] := 0;
  LPixels[72] := 0; LPixels[73] := 0; LPixels[74] := 0; LPixels[75] := 0; LPixels[76] := LB; LPixels[77] := 0; LPixels[78] := 0; LPixels[79] := 0; LPixels[80] := 0;
  FArrow := TXcomSurface.Create(9, 9);
  for LY := 0 to 8 do
    for LX := 0 to 8 do
      FArrow.SetPixel(LX, LY, Byte(LPixels[LX + LY * 9]));
end;

procedure TXcomBattleMap.Invalidate;
begin
  FRedraw := True;
end;

procedure TXcomBattleMap.SetCursorType(ACursorType, ASize: Integer);
begin
  FCursorType := ACursorType;
  if FCursorType = CT_NORMAL then
    FCursorSize := ASize
  else
    FCursorSize := 1;
end;

procedure TXcomBattleMap.SetSelectorPosition(AX, AY: Integer);
begin
  FSelectorX := AX;
  FSelectorY := AY;
end;

function TXcomBattleMap.TileSprite(const ATile: TXcomTile; APart: Integer): TXcomSurface;
var
  LData: TXcomMapData;
begin
  LData := ATile.MapData[APart];
  if not Assigned(LData) then
    Exit(nil);
  Result := FSprites.TerrainFrame((LData.Dataset as TXcomMapDataSet).Name, LData.GetSprite(ATile.CurrentFrame[APart]));
end;

procedure TXcomBattleMap.BlitShade(const ASource: TXcomSurface; AX, AY, AShade: Integer; AHalf: Boolean);
begin
  if Assigned(FTrace) then
    FTrace.Add(Format('%s x=%d y=%d w=%d h=%d shade=%d tile=%s', [FWhat, AX, AY, ASource.Width, ASource.Height, AShade,
      FTileText]));
  Inc(FBlitCount);
  if FBlitCount - 1 = FSkipBlit then
  begin
    if FShadeDelta = 0 then
      Exit;
    AShade := EnsureRange(AShade + FShadeDelta, 0, 16);
  end;
  TXcomSurfaceShader.Blit(ASource, FSurface, AX, AY, AShade, AHalf);
end;

function TXcomBattleMap.GetTerrainLevel(const APosition: TXcomPosition; ASize: Integer): Integer;
var
  LX: Integer;
  LY: Integer;
  LLevel: Integer;
begin
  // terrain level goes from 0 to -24: for a larger unit the highest, which is the lowest number
  Result := 0;
  for LX := 0 to ASize - 1 do
    for LY := 0 to ASize - 1 do
    begin
      LLevel := FSave.TileAt(APosition + TXcomPosition.Make(LX, LY, 0)).GetTerrainLevel;
      if LLevel < Result then
        Result := LLevel;
    end;
end;

procedure TXcomBattleMap.CalculateWalkingOffset(const AUnit: TXcomBattleUnit; out AOffset: TXcomPosition;
  out AShadeOffset: Integer);
const
  OFFSET_X: array[0..7] of Integer = (1, 1, 1, 0, -1, -1, -1, 0);
  OFFSET_Y: array[0..7] of Integer = (1, 0, -1, -1, -1, 0, 1, 1);
var
  LPhase: Integer;
  LDir: Integer;
  LMidPhase: Integer;
  LEndPhase: Integer;
  LSize: Integer;
  LFromLevel: Integer;
  LToLevel: Integer;
  LZ: Integer;
  LBelow: TXcomTile;
begin
  AOffset := TXcomPosition.Make(0, 0, 0);
  LPhase := AUnit.WalkingPhase + AUnit.DiagonalWalkingPhase;
  LDir := AUnit.Direction;
  LMidPhase := 4 + 4 * (LDir mod 2);
  LEndPhase := 8 + 8 * (LDir mod 2);
  LSize := AUnit.Armor.Size;
  if LEndPhase = 16 then
    AShadeOffset := LPhase
  else
    AShadeOffset := LPhase * 2;
  if LSize > 1 then
  begin
    if (LDir < 1) or (LDir > 5) then
      LMidPhase := LEndPhase
    else if LDir = 5 then
      LMidPhase := 12
    else if LDir = 1 then
      LMidPhase := 5
    else
      LMidPhase := 1;
  end;
  if AUnit.VerticalDirection <> 0 then
  begin
    LMidPhase := 4;
    LEndPhase := 8;
  end
  else if (AUnit.Status = STATUS_WALKING) or (AUnit.Status = STATUS_FLYING) then
  begin
    if LPhase < LMidPhase then
    begin
      AOffset.X := LPhase * 2 * OFFSET_X[LDir];
      AOffset.Y := -LPhase * OFFSET_Y[LDir];
    end
    else
    begin
      AOffset.X := (LPhase - LEndPhase) * 2 * OFFSET_X[LDir];
      AOffset.Y := -(LPhase - LEndPhase) * OFFSET_Y[LDir];
    end;
  end;
  // if we are walking in between tiles, interpolate its terrain level
  if (AUnit.Status = STATUS_WALKING) or (AUnit.Status = STATUS_FLYING) then
  begin
    if LPhase < LMidPhase then
    begin
      LFromLevel := GetTerrainLevel(AUnit.Position, LSize);
      LToLevel := GetTerrainLevel(AUnit.Destination, LSize);
      if AUnit.Position.Z > AUnit.Destination.Z then
        // going down a level, so toLevel 0 becomes +24, -8 becomes 16
        LToLevel := LToLevel + 24 * (AUnit.Position.Z - AUnit.Destination.Z)
      else if AUnit.Position.Z < AUnit.Destination.Z then
        // going up a level, so toLevel 0 becomes -24, -8 becomes -16
        LToLevel := -24 * (AUnit.Destination.Z - AUnit.Position.Z) + Abs(LToLevel);
      AOffset.Y := AOffset.Y + ((LFromLevel * (LEndPhase - LPhase)) div LEndPhase) + ((LToLevel * LPhase) div LEndPhase);
    end
    else
    begin
      // from phase 4 onwards the unit behind the scenes already is on the destination tile: its last position
      LFromLevel := GetTerrainLevel(AUnit.LastPosition, LSize);
      LToLevel := GetTerrainLevel(AUnit.Destination, LSize);
      if AUnit.LastPosition.Z > AUnit.Destination.Z then
        // going down a level, so fromLevel 0 becomes -24, -8 becomes -32
        LFromLevel := LFromLevel - 24 * (AUnit.LastPosition.Z - AUnit.Destination.Z)
      else if AUnit.LastPosition.Z < AUnit.Destination.Z then
        // going up a level, so fromLevel 0 becomes +24, -8 becomes 16
        LFromLevel := 24 * (AUnit.Destination.Z - AUnit.LastPosition.Z) - Abs(LFromLevel);
      AOffset.Y := AOffset.Y + ((LFromLevel * (LEndPhase - LPhase)) div LEndPhase) + ((LToLevel * LPhase) div LEndPhase);
    end;
  end
  else
  begin
    AOffset.Y := AOffset.Y + GetTerrainLevel(AUnit.Position, LSize);
    if FSave.Depth > 0 then
    begin
      AUnit.FloorAbove := False;
      // make sure this unit isn't obscured by the floor above him, otherwise it looks weird
      if FCamera.ViewLevel > AUnit.Position.Z then
      begin
        LZ := Min(FCamera.ViewLevel, FSave.MapSizeZ - 1);
        while LZ <> AUnit.Position.Z do
        begin
          LBelow := FSave.TileAt(TXcomPosition.Make(AUnit.Position.X, AUnit.Position.Y, LZ));
          if not LBelow.HasNoFloor(nil) then
          begin
            AUnit.FloorAbove := True;
            Break;
          end;
          Dec(LZ);
        end;
      end;
    end;
  end;
end;

procedure TXcomBattleMap.CacheUnits;
var
  LUnit: TXcomBattleUnit;
begin
  for LUnit in FSave.Units do
    CacheUnit(LUnit);
end;

procedure TXcomBattleMap.CacheUnit(const AUnit: TXcomBattleUnit);
var
  LSprite: TXcomUnitSprite;
  LParts: Integer;
  LPart: Integer;
  LList: TObjectList<TXcomSurface>;
  LCache: TXcomSurface;
begin
  if not AUnit.CacheInvalid then
    Exit;
  LSprite := TXcomUnitSprite.Create(FSave.Depth <> 0);
  try
    LParts := AUnit.Armor.Size * AUnit.Armor.Size;
    if not FCaches.TryGetValue(AUnit, LList) then
    begin
      LList := TObjectList<TXcomSurface>.Create(True);
      FCaches.Add(AUnit, LList);
    end;
    // 1 or 4 iterations, depending on unit size
    for LPart := 0 to LParts - 1 do
    begin
      if LPart < LList.Count then
        LCache := LList[LPart]
      else
      begin
        LCache := TXcomSurface.Create(FSpriteWidth * 2, FSpriteHeight);
        LList.Add(LCache);
      end;
      LSprite.SetBattleUnit(AUnit, LPart);
      LSprite.SetSurfaces(FSprites.SurfaceSet(AUnit.Armor.SpriteSheet), FSprites.SurfaceSet('HANDOB.PCK'),
        FSprites.SurfaceSet('HANDOB2.PCK'));
      LSprite.SetAnimationFrame(FAnimFrame);
      LCache.Clear;
      LSprite.Draw(LCache);
      AUnit.CacheInvalid := False;
    end;
  finally
    LSprite.Free;
  end;
end;

procedure TXcomBattleMap.AddParticle(const ATile: TXcomTile; const AParticle: TXcomParticle);
var
  LList: TObjectList<TXcomParticle>;
begin
  if not FParticles.TryGetValue(ATile, LList) then
  begin
    LList := TObjectList<TXcomParticle>.Create(True);
    FParticles.Add(ATile, LList);
  end;
  LList.Add(AParticle);
end;

procedure TXcomBattleMap.ResetObstacles;
var
  LIndex: Integer;
begin
  for LIndex := 0 to FSave.MapSizeXyz - 1 do
    FSave.TileByIndex(LIndex).ResetObstacle;
  FShowObstacles := False;
  FRedraw := True;
end;

procedure TXcomBattleMap.EnableObstacles;
begin
  FShowObstacles := True;
  FRedraw := True;
end;

procedure TXcomBattleMap.DisableObstacles;
begin
  FShowObstacles := False;
  FRedraw := True;
end;

procedure TXcomBattleMap.ClearParticles;
begin
  FParticles.Clear;
end;

function TXcomBattleMap.ParticlesOf(const ATile: TXcomTile): TObjectList<TXcomParticle>;
begin
  if not FParticles.TryGetValue(ATile, Result) then
    Result := nil;
end;

procedure TXcomBattleMap.AddVaporCloud(const AVoxel: TXcomPosition; ADensity, AColor: Integer);
var
  LTile: TXcomTile;
  LTilePosition: TXcomPosition;
  LVoxelPosition: TXcomPosition;
  LIndex: Integer;
  LX: Integer;
  LY: Integer;
  LDensity: Integer;
  LOpacity: Integer;
begin
  LTile := FSave.TileAt(AVoxel div TXcomPosition.Make(16, 16, 24));
  if not Assigned(LTile) then
    Exit;
  LTilePosition := FCamera.ConvertMapToScreen(AVoxel div TXcomPosition.Make(16, 16, 24)) + FCamera.MapOffset;
  LVoxelPosition := FCamera.ConvertVoxelToScreen(AVoxel);
  for LIndex := 1 to ADensity do
  begin
    // the arguments of Particle(...) are evaluated from the right: opacity, density, y, x
    LOpacity := FParticleRandom.Generate(32, 44);
    LDensity := FParticleRandom.Generate(48, 224);
    LY := LVoxelPosition.Y - LTilePosition.Y + FParticleRandom.Generate(0, 4) - 2;
    LX := LVoxelPosition.X - LTilePosition.X + FParticleRandom.Generate(0, 4) - 2;
    AddParticle(LTile, TXcomParticle.Create(LX, LY, LDensity, AColor, LOpacity));
  end;
end;

procedure TXcomBattleMap.AnimateParticles(const ATile: TXcomTile);
var
  LList: TObjectList<TXcomParticle>;
  LIndex: Integer;
begin
  if not FParticles.TryGetValue(ATile, LList) then
    Exit;
  LIndex := 0;
  while LIndex < LList.Count do
    if LList[LIndex].Animate(FParticleRandom) then
      Inc(LIndex)
    else
      LList.Delete(LIndex);
  if LList.Count = 0 then
    FParticles.Remove(ATile);
end;

procedure TXcomBattleMap.DrawParticles(const ATile: TXcomTile; const AScreen: TXcomPosition);
var
  LList: TObjectList<TXcomParticle>;
  LParticle: TXcomParticle;
  LX: Integer;
  LY: Integer;
  LBase: Integer;

  procedure Mix(AX, AY: Integer);
  begin
    FSurface.SetPixel(AX, AY, FSettings.Transparencies[LBase + FSurface.GetPixel(AX, AY)]);
  end;

begin
  if not FParticles.TryGetValue(ATile, LList) then
    Exit;
  for LParticle in LList do
  begin
    // int vaporX = screenPosition.x + getX(): the sum is a float, truncated
    LX := Trunc(Single(AScreen.X + LParticle.XOffset));
    LY := Trunc(Single(AScreen.Y + LParticle.YOffset));
    if Length(FSettings.Transparencies) >= (LParticle.Color + 1) * 1024 then
    begin
      LBase := LParticle.Color * 1024 + LParticle.OpacityLevel * 256;
      // the switch of the C++ falls through: a bigger particle also draws the points of the smaller ones
      if LParticle.Size >= 3 then
        Mix(LX + 1, LY + 1);
      if LParticle.Size >= 2 then
        Mix(LX + 1, LY);
      if LParticle.Size >= 1 then
        Mix(LX, LY + 1);
      Mix(LX, LY);
    end;
  end;
end;

procedure TXcomBattleMap.Animate(ARedraw: Boolean);
var
  LIndex: Integer;
  LUnit: TXcomBattleUnit;
begin
  Inc(FAnimFrame);
  if FAnimFrame = 8 then
    FAnimFrame := 0;
  // animate tiles
  for LIndex := 0 to FSave.MapSizeXyz - 1 do
  begin
    FSave.TileByIndex(LIndex).Animate;
    AnimateParticles(FSave.TileByIndex(LIndex));
  end;
  // animate certain units (large flying units have a propulsion animation)
  for LUnit in FSave.Units do
    if not LUnit.IsOut then
      if LUnit.Armor.ConstantAnimation then
      begin
        LUnit.CacheInvalid := True;
        CacheUnit(LUnit);
      end;
  if ARedraw then
    FRedraw := True;
end;

function TXcomBattleMap.Draw: Boolean;
begin
  Result := True;
  if not FRedraw then
    Exit;
  // the background is color 15 (black in every palette), not the transparent 0
  FRedraw := False;
  FBlitCount := 0;
  FSurface.Clear(BLOCK_COLOR_BLACK);
  if (Assigned(FSave.SelectedUnit) and FSave.SelectedUnit.GetVisible) or FUnitDying or
    (not Assigned(FSave.SelectedUnit)) or FSave.DebugMode then
    DrawTerrain
  else
    Result := False;
end;

procedure TXcomBattleMap.DrawUnit(const AUnitTile, ACurrentTile: TXcomTile; const ATileScreen: TXcomPosition; AShade,
  AObstacleShade: Integer; ATopLayer: Boolean);
const
  TILE_FLOOR_WIDTH = 32;
  TILE_FLOOR_HEIGHT = 16;
  TILE_HEIGHT = 40;
var
  LUnit: TXcomBattleUnit;
  LUnitOffset: TXcomPosition;
  LFromBelow: Boolean;
  LBelow: TXcomTile;
  LPart: Integer;
  LCache: TXcomSurface;
  LList: TObjectList<TXcomSurface>;
  LMoving: Boolean;
  LBonusWidth: Integer;
  LTopMargin: Integer;
  LBottomMargin: Integer;
  LTop: TXcomTile;
  LMask: TXcomGraphSubset;
  LLeftMask: TXcomGraphSubset;
  LRightMask: TXcomGraphSubset;
  LDirection: Integer;
  LPartCurr: TXcomPosition;
  LPartDest: TXcomPosition;
  LPartLast: TXcomPosition;
  LIsDest: Boolean;
  LIsLast: Boolean;
  LLeftPos: TXcomPosition;
  LRightPos: TXcomPosition;
  LTileScreen: TXcomPosition;
  LOffset: TXcomPosition;
  LShadeOffset: Integer;
  LTileShade: Integer;
  LUnitShade: Integer;
  LFrame: TXcomSurface;
  LFrameNumber: Integer;

  function SameXY(const AFirst, ASecond: TXcomPosition): Boolean;
  begin
    Result := (AFirst.X = ASecond.X) and (AFirst.Y = ASecond.Y);
  end;

begin
  if not Assigned(AUnitTile) then
    Exit;
  LUnit := AUnitTile.CurrentUnit;
  LFromBelow := False;
  if not Assigned(LUnit) then
  begin
    LBelow := FSave.TileAt(AUnitTile.Position + TXcomPosition.Make(0, 0, -1));
    if Assigned(LBelow) and AUnitTile.HasNoFloor(LBelow) then
    begin
      LUnit := LBelow.CurrentUnit;
      if not Assigned(LUnit) then
        Exit;
      LFromBelow := True;
    end
    else
      Exit;
  end;
  if not (LUnit.GetVisible or FSave.DebugMode) then
    Exit;
  LUnitOffset := TXcomPosition.Make(AUnitTile.Position.X - LUnit.Position.X, AUnitTile.Position.Y - LUnit.Position.Y, 0);
  LPart := LUnitOffset.X + LUnitOffset.Y * 2;
  if LPart < 0 then
    LPart := 0;
  if (not FCaches.TryGetValue(LUnit, LList)) or (LPart >= LList.Count) then
    Exit;
  LCache := LList[LPart];
  LMoving := (LUnit.Status = STATUS_WALKING) or (LUnit.Status = STATUS_FLYING);
  if LMoving then
    LBonusWidth := 0
  else
    LBonusWidth := TILE_FLOOR_WIDTH;
  LBottomMargin := 0;
  // if unit is from below then we draw only the part that is in the tile
  if LFromBelow then
  begin
    LBottomMargin := -TILE_FLOOR_HEIGHT div 2;
    LTopMargin := TILE_FLOOR_HEIGHT;
  end
  else if ATopLayer then
    LTopMargin := 2 * TILE_FLOOR_HEIGHT
  else
  begin
    LTop := FSave.TileAt(AUnitTile.Position + TXcomPosition.Make(0, 0, 1));
    if Assigned(LTop) and LTop.HasNoFloor(AUnitTile) then
      LTopMargin := -TILE_FLOOR_HEIGHT div 2
    else
      LTopMargin := TILE_FLOOR_HEIGHT;
  end;
  LMask := TXcomGraphSubset.Make(0, TILE_FLOOR_WIDTH + LBonusWidth, 0, TILE_HEIGHT + LTopMargin + LBottomMargin)
    .Offset(ATileScreen.X - LBonusWidth div 2, ATileScreen.Y - LTopMargin);
  if LMoving then
  begin
    LLeftMask := LMask.Offset(-TILE_FLOOR_WIDTH div 2, 0);
    LRightMask := LMask.Offset(TILE_FLOOR_WIDTH div 2, 0);
    LDirection := LUnit.Direction;
    LPartCurr := ACurrentTile.Position;
    LPartDest := LUnit.Destination + LUnitOffset;
    LPartLast := LUnit.LastPosition + LUnitOffset;
    LIsDest := SameXY(LPartDest, LPartCurr);
    LIsLast := SameXY(LPartLast, LPartCurr);
    // adjusting mask
    if SameXY(LPartLast, LPartDest) then
    begin
      if ACurrentTile <> AUnitTile then
        // nothing to draw
        Exit;
    end
    else if LIsDest then
    begin
      // unit is moving to this tile
      case LDirection of
        0, 1: LMask := TXcomGraphSubset.Intersection(LMask, LRightMask);
        5, 6: LMask := TXcomGraphSubset.Intersection(LMask, LLeftMask);
        7: Exit;
      end;
    end
    else if LIsLast then
    begin
      // unit is exiting this tile
      case LDirection of
        1, 2: LMask := TXcomGraphSubset.Intersection(LMask, LLeftMask);
        3: Exit;
        4, 5: LMask := TXcomGraphSubset.Intersection(LMask, LRightMask);
      end;
    end
    else
    begin
      LLeftPos := LPartCurr + TXcomPosition.Make(-1, 0, 0);
      LRightPos := LPartCurr + TXcomPosition.Make(0, -1, 0);
      if (not ATopLayer) and ((LPartDest.Z > LPartCurr.Z) or (LPartLast.Z > LPartCurr.Z)) then
        // unit change layers, it will be drawn by upper layer not lower
        Exit
      else if ((LDirection = 1) and ((LPartDest = LRightPos) or (LPartLast = LLeftPos))) or
        ((LDirection = 5) and ((LPartDest = LLeftPos) or (LPartLast = LRightPos))) then
        LMask := TXcomGraphSubset.Make(0, TILE_FLOOR_WIDTH, 0, TILE_HEIGHT + 2 * TILE_FLOOR_HEIGHT)
          .Offset(ATileScreen.X, ATileScreen.Y - 2 * TILE_FLOOR_HEIGHT)
      else
        // unit is not moving close to tile
        Exit;
    end;
  end
  else if AUnitTile <> ACurrentTile then
    Exit;
  LTileScreen := FCamera.ConvertMapToScreen(AUnitTile.Position + TXcomPosition.Make(0, 0, IfThen(LFromBelow, -1, 0)));
  LTileScreen := LTileScreen + FCamera.MapOffset;
  // draw unit
  CalculateWalkingOffset(LUnit, LOffset, LShadeOffset);
  if ACurrentTile.IsDiscovered(2) then
    LTileShade := ACurrentTile.GetShade
  else
    LTileShade := 16;
  LUnitShade := (LTileShade * (16 - LShadeOffset) + AShade * LShadeOffset) div 16;
  if (not LMoving) and AUnitTile.GetObstacle(4) then
    LUnitShade := AObstacleShade;
  if Assigned(FTrace) then
    FTrace.Add(Format('unit %d x=%d y=%d shade=%d mask=%d..%d,%d..%d', [LUnit.Id,
      LTileScreen.X + LOffset.X - FSpriteWidth div 2, LTileScreen.Y + LOffset.Y, LUnitShade, LMask.BegX, LMask.EndX,
      LMask.BegY, LMask.EndY]));
  TXcomSurfaceShader.Blit(LCache, FSurface, LTileScreen.X + LOffset.X - FSpriteWidth div 2, LTileScreen.Y + LOffset.Y,
    LUnitShade, LMask);
  // draw fire
  if LUnit.Fire > 0 then
  begin
    LFrameNumber := 4 + (FAnimFrame div 2);
    LFrame := FSprites.SurfaceSet('SMOKE.PCK').GetFrame(LFrameNumber);
    TXcomSurfaceShader.Blit(LFrame, FSurface, LTileScreen.X + LOffset.X, LTileScreen.Y + LOffset.Y, 0, LMask);
  end;
end;

procedure TXcomBattleMap.DrawTerrain;
const
  BACK_POS: array[0..2, 0..1] of Integer = ((0, -1), (-1, -1), (-1, 0));
  FRONT_POS: array[0..4, 0..1] of Integer = ((-1, 1), (0, 1), (1, 1), (1, 0), (1, -1));
var
  LBeginX: Integer;
  LEndX: Integer;
  LBeginY: Integer;
  LEndY: Integer;
  LBeginZ: Integer;
  LEndZ: Integer;
  LDummy: Integer;
  LItZ: Integer;
  LItX: Integer;
  LItY: Integer;
  LTopLayer: Boolean;
  LMapPosition: TXcomPosition;
  LScreen: TXcomPosition;
  LTile: TXcomTile;
  LTileShade: Integer;
  LObstacleShade: Integer;
  LWallShade: Integer;
  LUnit: TXcomBattleUnit;
  LFrame: TXcomSurface;
  LFrameNumber: Integer;
  LSprite: Integer;
  LShade: Integer;
  LIndex: Integer;
  LBigWall: Integer;
  LSelected: TXcomBattleUnit;
  LOffset: TXcomPosition;
  LShadeOffset: Integer;
  LExplosion: TXcomExplosion;

  function Shade(APart: Integer; ADefault: Integer): Integer;
  begin
    if LTile.GetObstacle(APart) then
      Result := LObstacleShade
    else
      Result := ADefault;
  end;

  function OnScreen: Boolean;
  begin
    Result := (LScreen.X > -FSpriteWidth) and (LScreen.X < FSurface.Width + FSpriteWidth) and
      (LScreen.Y > -FSpriteHeight) and (LScreen.Y < FSurface.Height + FSpriteHeight);
  end;

  function CursorOnTile: Boolean;
  begin
    Result := (FCursorType <> CT_NONE) and (FSelectorX > LItX - FCursorSize) and (FSelectorY > LItY - FCursorSize) and
      (FSelectorX < LItX + 1) and (FSelectorY < LItY + 1);
  end;

begin
  LBeginZ := 0;
  if FCamera.ShowAllLayers then
    LEndZ := FSave.MapSizeZ - 1
  else
    LEndZ := FCamera.ViewLevel;
  // get corner map coordinates to give rough boundaries in which tiles to redraw are
  FCamera.ConvertScreenToMap(0, 0, LBeginX, LDummy);
  FCamera.ConvertScreenToMap(FSurface.Width, 0, LDummy, LBeginY);
  FCamera.ConvertScreenToMap(FSurface.Width + FSpriteWidth, FSurface.Height + FSpriteHeight, LEndX, LDummy);
  FCamera.ConvertScreenToMap(0, FSurface.Height + FSpriteHeight, LDummy, LEndY);
  LBeginY := LBeginY - FCamera.ViewLevel * 2;
  LBeginX := LBeginX - FCamera.ViewLevel * 2;
  if LBeginX < 0 then
    LBeginX := 0;
  if LBeginY < 0 then
    LBeginY := 0;
  for LItZ := LBeginZ to LEndZ do
  begin
    LTopLayer := LItZ = LEndZ;
    for LItX := LBeginX to LEndX do
      for LItY := LBeginY to LEndY do
      begin
        LMapPosition := TXcomPosition.Make(LItX, LItY, LItZ);
        LScreen := FCamera.ConvertMapToScreen(LMapPosition) + FCamera.MapOffset;
        // only render cells that are inside the surface
        if not OnScreen then
          Continue;
        LTile := FSave.TileAt(LMapPosition);
        if Assigned(FTrace) then
          FTileText := Format('%d,%d,%d', [LItX, LItY, LItZ]);
        if not Assigned(LTile) then
          Continue;
        if LTile.IsDiscovered(2) then
        begin
          LTileShade := LTile.GetShade;
          LObstacleShade := LTileShade;
          if FShowObstacles and LTile.IsObstacle then
          begin
            if LTileShade > 7 then
              LObstacleShade := 7;
            if LTileShade < 2 then
              LObstacleShade := 2;
            LObstacleShade := LObstacleShade + (ARROW_BOB[FAnimFrame] * 2 - 2);
          end;
        end
        else
        begin
          LTileShade := 16;
          LObstacleShade := 16;
        end;
        FWhat := 'floor';
        LFrame := TileSprite(LTile, PART_FLOOR);
        if Assigned(LFrame) then
          BlitShade(LFrame, LScreen.X, LScreen.Y - LTile.MapData[PART_FLOOR].YOffset, Shade(PART_FLOOR, LTileShade));
        LUnit := LTile.CurrentUnit;
        FWhat := 'cursor';
        if CursorOnTile then
        begin
          if FCamera.ViewLevel = LItZ then
          begin
            if FCursorType <> CT_AIM then
            begin
              if Assigned(LUnit) and (LUnit.GetVisible or FSave.DebugMode) then
                LFrameNumber := FAnimFrame mod 2 // yellow box
              else
                LFrameNumber := 0; // red box
            end
            else if Assigned(LUnit) and (LUnit.GetVisible or FSave.DebugMode) then
              LFrameNumber := 7 + (FAnimFrame div 2) // yellow animated crosshairs
            else
              LFrameNumber := 6; // red static crosshairs
            BlitShade(FSprites.SurfaceSet('CURSOR.PCK').GetFrame(LFrameNumber), LScreen.X, LScreen.Y, 0);
          end
          else if FCamera.ViewLevel > LItZ then
            BlitShade(FSprites.SurfaceSet('CURSOR.PCK').GetFrame(2), LScreen.X, LScreen.Y, 0); // blue box
        end;
        // special handling for a moving unit in background of tile
        for LIndex := 0 to 2 do
          DrawUnit(FSave.TileAt(LMapPosition + TXcomPosition.Make(BACK_POS[LIndex, 0], BACK_POS[LIndex, 1], 0)), LTile,
            LScreen, LTileShade, LObstacleShade, LTopLayer);
        // draw walls
        if not LTile.IsVoid then
        begin
          FWhat := 'west';
          LFrame := TileSprite(LTile, PART_WEST_WALL);
          if Assigned(LFrame) then
          begin
            if (LTile.MapData[PART_WEST_WALL].IsDoor or LTile.MapData[PART_WEST_WALL].IsUfoDoor) and
              LTile.IsDiscovered(0) then
              LWallShade := LTile.GetShade
            else
              LWallShade := LTileShade;
            BlitShade(LFrame, LScreen.X, LScreen.Y - LTile.MapData[PART_WEST_WALL].YOffset,
              Shade(PART_WEST_WALL, LWallShade));
          end;
          FWhat := 'north';
          LFrame := TileSprite(LTile, PART_NORTH_WALL);
          if Assigned(LFrame) then
          begin
            if (LTile.MapData[PART_NORTH_WALL].IsDoor or LTile.MapData[PART_NORTH_WALL].IsUfoDoor) and
              LTile.IsDiscovered(1) then
              LWallShade := LTile.GetShade
            else
              LWallShade := LTileShade;
            BlitShade(LFrame, LScreen.X, LScreen.Y - LTile.MapData[PART_NORTH_WALL].YOffset,
              Shade(PART_NORTH_WALL, LWallShade), Assigned(LTile.MapData[PART_WEST_WALL]));
          end;
          FWhat := 'object';
          if Assigned(LTile.MapData[PART_OBJECT]) then
          begin
            LBigWall := LTile.MapData[PART_OBJECT].BigWall;
            if (LBigWall < 6) or (LBigWall = 9) then
            begin
              LFrame := TileSprite(LTile, PART_OBJECT);
              if Assigned(LFrame) then
                BlitShade(LFrame, LScreen.X, LScreen.Y - LTile.MapData[PART_OBJECT].YOffset,
                  Shade(PART_OBJECT, LTileShade));
            end;
          end;
          FWhat := 'flooritem';
          LSprite := LTile.GetTopItemSprite;
          if LSprite <> -1 then
            BlitShade(FSprites.SurfaceSet('FLOOROB.PCK').GetFrame(LSprite), LScreen.X,
              LScreen.Y + LTile.GetTerrainLevel, LTileShade);
        end;
        LUnit := LTile.CurrentUnit;
        // draw soldier from this tile or below
        DrawUnit(LTile, LTile, LScreen, LTileShade, LObstacleShade, LTopLayer);
        // special handling for a moving unit in foreground of tile
        for LIndex := 0 to 4 do
          DrawUnit(FSave.TileAt(LMapPosition + TXcomPosition.Make(FRONT_POS[LIndex, 0], FRONT_POS[LIndex, 1], 0)), LTile,
            LScreen, LTileShade, LObstacleShade, LTopLayer);
        FWhat := 'smoke';
        if (LTile.Smoke <> 0) and LTile.IsDiscovered(2) then
        begin
          LFrameNumber := 0;
          LShade := 0;
          if LTile.Fire = 0 then
          begin
            if FSave.Depth > 0 then
              LFrameNumber := LFrameNumber + FSettings.UnderwaterSmokeOffset
            else
              LFrameNumber := LFrameNumber + FSettings.SmokeOffset;
            LFrameNumber := LFrameNumber + Floor((LTile.Smoke / 6.0) - 0.1);
            LShade := LTileShade;
          end;
          if (FAnimFrame div 2) + LTile.AnimationOffset > 3 then
            LFrameNumber := LFrameNumber + ((FAnimFrame div 2) + LTile.AnimationOffset - 4)
          else
            LFrameNumber := LFrameNumber + (FAnimFrame div 2) + LTile.AnimationOffset;
          BlitShade(FSprites.SurfaceSet('SMOKE.PCK').GetFrame(LFrameNumber), LScreen.X, LScreen.Y, LShade);
        end;
        // draw particle clouds
        DrawParticles(LTile, LScreen);
        if not LTile.IsVoid then
        begin
          FWhat := 'object';
          if Assigned(LTile.MapData[PART_OBJECT]) then
          begin
            LBigWall := LTile.MapData[PART_OBJECT].BigWall;
            if (LBigWall >= 6) and (LBigWall <> 9) then
            begin
              LFrame := TileSprite(LTile, PART_OBJECT);
              if Assigned(LFrame) then
                BlitShade(LFrame, LScreen.X, LScreen.Y - LTile.MapData[PART_OBJECT].YOffset,
                  Shade(PART_OBJECT, LTileShade));
            end;
          end;
        end;
        FWhat := 'cursor';
        if CursorOnTile then
        begin
          if FCamera.ViewLevel = LItZ then
          begin
            if FCursorType <> CT_AIM then
            begin
              if Assigned(LUnit) and (LUnit.GetVisible or FSave.DebugMode) then
                LFrameNumber := 3 + (FAnimFrame mod 2) // yellow box
              else
                LFrameNumber := 3; // red box
            end
            else if Assigned(LUnit) and (LUnit.GetVisible or FSave.DebugMode) then
              LFrameNumber := 7 + (FAnimFrame div 2) // yellow animated crosshairs
            else
              LFrameNumber := 6; // red static crosshairs
            BlitShade(FSprites.SurfaceSet('CURSOR.PCK').GetFrame(LFrameNumber), LScreen.X, LScreen.Y, 0);
          end
          else if FCamera.ViewLevel > LItZ then
            BlitShade(FSprites.SurfaceSet('CURSOR.PCK').GetFrame(5), LScreen.X, LScreen.Y, 0); // blue box
          if (FCursorType > 2) and (FCamera.ViewLevel = LItZ) then
          begin
            case FCursorType of
              3: LFrameNumber := 11;
              4: LFrameNumber := 13;
            else
              LFrameNumber := 15;
            end;
            BlitShade(FSprites.SurfaceSet('CURSOR.PCK').GetFrame(LFrameNumber + (FAnimFrame div 4)), LScreen.X,
              LScreen.Y, 0);
          end;
        end;
      end;
  end;
  LSelected := FSave.SelectedUnit;
  if Assigned(LSelected) and ((FSave.Side = FACTION_PLAYER) or FSave.DebugMode) and
    (LSelected.Position.Z <= FCamera.ViewLevel) then
  begin
    LScreen := FCamera.ConvertMapToScreen(LSelected.Position) + FCamera.MapOffset;
    CalculateWalkingOffset(LSelected, LOffset, LShadeOffset);
    if LSelected.Armor.Size > 1 then
      LOffset.Y := LOffset.Y + 4;
    LOffset.Y := LOffset.Y + 24 - (LSelected.GetHeight + LSelected.FloatHeight);
    if LSelected.IsKneeled then
      LOffset.Y := LOffset.Y - 2;
    if FCursorType <> CT_NONE then
      BlitShade(FArrow, LScreen.X + LOffset.X + (FSpriteWidth div 2) - (FArrow.Width div 2),
        LScreen.Y + LOffset.Y - FArrow.Height + ARROW_BOB[FAnimFrame], 0);
  end;
  if FExplosionInFov then
  begin
    if FFlashScreen then
    begin
      // the screen in the EGA colors of the blast: every pixel loses its shade
      for LIndex := 0 to FSurface.Width * FSurface.Height - 1 do
        FSurface.SetPixel(LIndex mod FSurface.Width, LIndex div FSurface.Width,
          (FSurface.GetPixel(LIndex mod FSurface.Width, LIndex div FSurface.Width) div 16) * 16);
      FFlashScreen := False;
    end
    else
      for LExplosion in FExplosions do
      begin
        LScreen := FCamera.ConvertVoxelToScreen(LExplosion.Position);
        if LExplosion.IsBig then
        begin
          if LExplosion.CurrentFrame >= 0 then
          begin
            LFrame := FSprites.SurfaceSet('X1.PCK').GetFrame(LExplosion.CurrentFrame);
            BlitShade(LFrame, LScreen.X - (LFrame.Width div 2), LScreen.Y - (LFrame.Height div 2), 0);
          end;
        end
        else if LExplosion.IsHit then
          BlitShade(FSprites.SurfaceSet('HIT.PCK').GetFrame(LExplosion.CurrentFrame), LScreen.X - 15, LScreen.Y - 25, 0)
        else
          BlitShade(FSprites.SurfaceSet('SMOKE.PCK').GetFrame(LExplosion.CurrentFrame), LScreen.X - 15,
            LScreen.Y - 15, 0);
      end;
  end;
end;

procedure TXcomBattleMap.AddExplosion(const ACenter: TXcomPosition; AStartFrame, AFrameDelay: Integer; ABig,
  AHit: Boolean);
begin
  FExplosions.Add(TXcomExplosion.Create(ACenter, AStartFrame, AFrameDelay, ABig, AHit));
end;

function TXcomBattleMap.AnimateExplosions: Boolean;
var
  LIndex: Integer;
begin
  // ExplosionBState::think: the explosions that are over are removed; true while any is left
  LIndex := 0;
  while LIndex < FExplosions.Count do
    if FExplosions[LIndex].Animate then
      Inc(LIndex)
    else
      FExplosions.Delete(LIndex);
  Result := FExplosions.Count > 0;
end;

end.
