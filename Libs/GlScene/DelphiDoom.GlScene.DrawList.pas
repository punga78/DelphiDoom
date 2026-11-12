{******************************************************************************}
{                                                                              }
{  DelphiDoom: OpenGL scene - the draw list of a frame                         }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Port of gld_drawinfo and gld_AddDrawItem of OPENGL\gl_render.pas            }
{  (walls, flats and sprites of a frame and their runs)                        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.GlScene.DrawList;

interface

uses
  DelphiDoom.GlScene.Types;

type
  /// <summary>
  ///   The walls, flats and sprites the BSP walk collected for one frame, each kind in its own block, and the
  ///   runs that keep the order in which the kinds alternated
  /// </summary>
  /// <remarks>
  ///   A plain class, not an interface: it is on the hot path (one call per wall, flat and sprite of every
  ///   frame), so its owner calls it directly. The records of the three blocks belong to the engine: the list
  ///   only knows their size. The blocks grow and are given back only by Release. As in the old code the run
  ///   at LastRun is the one being filled: after BeginFrame, until the first item, it still is the first run of
  ///   the frame before
  /// </remarks>
  TGlSceneDrawList = class(TObject)
  strict private
    const
      ITEM_GROW_STEP = 128;
      RUN_GROW_STEP = 64;
  strict private
    FSizes: TGlSceneItemSizes;
    FWalls: Pointer;
    FWallCount: Integer;
    FWallCapacity: Integer;
    FFlats: Pointer;
    FFlatCount: Integer;
    FFlatCapacity: Integer;
    FSprites: Pointer;
    FSpriteCount: Integer;
    FSpriteCapacity: Integer;
    FRuns: PGlSceneRunArray;
    FRunIndex: Integer;
    FRunCapacity: Integer;
    FMarker: Byte;
    procedure AddToRun(const AKind: TGlSceneItemKind; const AIndex: Integer);
  public
    /// <exception cref="EGlSceneException">A size is not positive</exception>
    constructor Create(const ASizes: TGlSceneItemSizes);
    destructor Destroy; override;
    /// <summary>Empties the three blocks for the frame AMarker; the memory is kept</summary>
    procedure BeginFrame(const AMarker: Byte);
    /// <summary>Adds a wall to the current run (or opens a run) and gives the place to copy its record to</summary>
    function AddWall: Pointer;
    function AddFlat: Pointer;
    function AddSprite: Pointer;
    /// <summary>Empties the list and gives the memory back (a new level)</summary>
    procedure Release;
    /// <summary>The first wall (the others follow it in memory); it changes when the block grows</summary>
    property Walls: Pointer read FWalls;
    property WallCount: Integer read FWallCount;
    property Flats: Pointer read FFlats;
    property FlatCount: Integer read FFlatCount;
    property Sprites: Pointer read FSprites;
    property SpriteCount: Integer read FSpriteCount;
    /// <summary>The runs, 0..LastRun; nil until the first item after Create or Release</summary>
    property Runs: PGlSceneRunArray read FRuns;
    /// <summary>Index of the run being filled</summary>
    property LastRun: Integer read FRunIndex;
  end;

implementation

const
  SBadItemSize = 'The size of the items of a draw list has to be positive';

{ TGlSceneDrawList }

constructor TGlSceneDrawList.Create(const ASizes: TGlSceneItemSizes);
begin
  inherited Create;
  if (ASizes.Wall <= 0) or (ASizes.Flat <= 0) or (ASizes.Sprite <= 0) then
    raise EGlSceneException.Create(SBadItemSize);
  FSizes := ASizes;
end;

destructor TGlSceneDrawList.Destroy;
begin
  Release;
  inherited Destroy;
end;

procedure TGlSceneDrawList.BeginFrame(const AMarker: Byte);
begin
  FMarker := AMarker;
  FWallCount := 0;
  FFlatCount := 0;
  FSpriteCount := 0;
  FRunIndex := 0;
end;

procedure TGlSceneDrawList.AddToRun(const AKind: TGlSceneItemKind; const AIndex: Integer);
var
  LRun: PGlSceneRun;
begin
  // the three steps of gld_AddDrawItem, in its order: a full block opens a run without looking at what the
  // place had; a run of another frame counts as empty; a run of another kind is closed and the next one opened
  if FRunIndex >= FRunCapacity then
  begin
    Inc(FRunCapacity, RUN_GROW_STEP);
    ReallocMem(FRuns, FRunCapacity * SizeOf(TGlSceneRun));
    LRun := @FRuns[FRunIndex];
    LRun.Kind := AKind;
    LRun.Count := 1;
    LRun.First := AIndex;
    LRun.Marker := FMarker;
    Exit;
  end;
  LRun := @FRuns[FRunIndex];
  if LRun.Marker <> FMarker then
  begin
    LRun.Kind := gskNone;
    LRun.Marker := FMarker;
  end;
  if LRun.Kind <> AKind then
  begin
    if LRun.Kind <> gskNone then
      Inc(FRunIndex);
    if FRunIndex >= FRunCapacity then
    begin
      Inc(FRunCapacity, RUN_GROW_STEP);
      ReallocMem(FRuns, FRunCapacity * SizeOf(TGlSceneRun));
    end;
    LRun := @FRuns[FRunIndex];
    LRun.Kind := AKind;
    LRun.Count := 1;
    LRun.First := AIndex;
    LRun.Marker := FMarker;
    Exit;
  end;
  Inc(LRun.Count);
end;

function TGlSceneDrawList.AddWall: Pointer;
begin
  if FWallCount >= FWallCapacity then
  begin
    Inc(FWallCapacity, ITEM_GROW_STEP);
    ReallocMem(FWalls, FWallCapacity * FSizes.Wall);
  end;
  AddToRun(gskWall, FWallCount);
  Result := PByte(FWalls) + FWallCount * FSizes.Wall;
  Inc(FWallCount);
end;

function TGlSceneDrawList.AddFlat: Pointer;
begin
  if FFlatCount >= FFlatCapacity then
  begin
    Inc(FFlatCapacity, ITEM_GROW_STEP);
    ReallocMem(FFlats, FFlatCapacity * FSizes.Flat);
  end;
  AddToRun(gskFlat, FFlatCount);
  Result := PByte(FFlats) + FFlatCount * FSizes.Flat;
  Inc(FFlatCount);
end;

function TGlSceneDrawList.AddSprite: Pointer;
begin
  if FSpriteCount >= FSpriteCapacity then
  begin
    Inc(FSpriteCapacity, ITEM_GROW_STEP);
    ReallocMem(FSprites, FSpriteCapacity * FSizes.Sprite);
  end;
  AddToRun(gskSprite, FSpriteCount);
  Result := PByte(FSprites) + FSpriteCount * FSizes.Sprite;
  Inc(FSpriteCount);
end;

procedure TGlSceneDrawList.Release;
begin
  FreeMem(FWalls);
  FWalls := nil;
  FWallCount := 0;
  FWallCapacity := 0;
  FreeMem(FFlats);
  FFlats := nil;
  FFlatCount := 0;
  FFlatCapacity := 0;
  FreeMem(FSprites);
  FSprites := nil;
  FSpriteCount := 0;
  FSpriteCapacity := 0;
  FreeMem(FRuns);
  FRuns := nil;
  FRunIndex := 0;
  FRunCapacity := 0;
end;

end.
