{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the greed library - the runner of the renderer scenarios}
{                                                                              }
{  Gives the scenarios of DelphiDoom.Tests.Greed.RenderScenarios to the          }
{  renderer of the library (the harness gives them to the original one)         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Greed.RenderRunner;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Greed.Types, DelphiDoom.Greed.Intf, DelphiDoom.Greed.SaveTypes,
  DelphiDoom.Greed.Actor.Types, DelphiDoom.Greed.LinkedPool, DelphiDoom.Greed.World.Intf, DelphiDoom.Greed.Frame.Intf,
  DelphiDoom.Greed.Random, DelphiDoom.Greed.Render.Types, DelphiDoom.Greed.Render.Assets.Intf, DelphiDoom.Greed.Render.ArchiveAssets,
  DelphiDoom.Greed.Render.FrameRenderer, DelphiDoom.Tests.Greed.RenderScenarios;

type
  TRenderClockFake = class(TInterfacedObject, IGreedRenderClock)
  public
    TimeCount: Integer;
    SpriteMoveTime: Integer;
    function GetTimeCount: Integer;
    function GetSpriteMoveTime: Integer;
  end;

  /// <summary>The renderer of the library with a map of the archive and a scenario made from it</summary>
  TRenderRunner = class
  strict private
    FArchive: IGreedArchive;
    FLoader: IGreedMapLoader;
    FWorld: IGreedWorld;
    FAssets: TGreedArchiveRenderAssets;
    FAssetsIntf: IGreedRenderAssets;
    FSprites: TGreedLinkedPool<TGreedSprite>;
    FClock: TRenderClockFake;
    FClockIntf: IGreedRenderClock;
    FRandom: TGreedRandomTable;
    FRandomIntf: IGreedRandom;
    FRenderer: TGreedFrameRenderer;
    FRendererIntf: IGreedFrameRenderer;
    FScenario: TRenderScenario;
    FWallNumbers: TArray<Integer>;
    FSpriteRuns: TArray<Integer>;
    FPlayer: TGreedPlayerRecord;
    FWallLump: Integer;
  public
    constructor Create(const AArchive: IGreedArchive; const AFiles: IGreedExternalFiles);
    destructor Destroy; override;
    /// <summary>The numbers of the walls that are walls (lumps between startwalls and endwalls)</summary>
    property WallNumbers: TArray<Integer> read FWallNumbers;
    /// <summary>For each lump the sprite lumps that follow it</summary>
    property SpriteRuns: TArray<Integer> read FSpriteRuns;
    property World: IGreedWorld read FWorld;
    property Scenario: TRenderScenario read FScenario;
    property Player: TGreedPlayerRecord read FPlayer;
    property Sprites: TGreedLinkedPool<TGreedSprite> read FSprites;
    property Random: TGreedRandomTable read FRandom;
    property Renderer: TGreedFrameRenderer read FRenderer;
    property Assets: TGreedArchiveRenderAssets read FAssets;
    /// <summary>Loads the map, makes the scenario of the seed and puts doors, sprites and lights in the level</summary>
    procedure LoadMap(AMapNumber: Integer; ASeed: Cardinal; AViewCount, ASpriteCount: Integer);
    /// <summary>The sprites of the scenario as they were made (the animations of the pictures drawn so far are undone)</summary>
    procedure ResetSprites;
    /// <summary>The picture of a view of the scenario</summary>
    function RenderView(AIndex: Integer): TGreedFrame;
  end;

/// <summary>The sky of the scenarios: 65536 bytes that the original and the library both get</summary>
function RenderTestBackdrop: TBytes;
/// <summary>CRC-32 of a block of memory</summary>
function RenderCrc32(const AData; ASize: Integer): Cardinal;
/// <summary>FNV-1a of the fields of a sprite that the renderer changes (the next hash is given as AHash)</summary>
function RenderSpriteHash(AHash: Cardinal; const ASprite: TGreedSprite): Cardinal;
/// <summary>The hash of all the sprites of the pool, in the order of the list</summary>
function RenderSpritesHash(APool: TGreedLinkedPool<TGreedSprite>): Cardinal;

implementation

uses
  System.ZLib, DelphiDoom.Greed.Factory, DelphiDoom.Greed.World, DelphiDoom.Greed.TrigTables;

function RenderTestBackdrop: TBytes;
var
  LIndex: Integer;
  LRandom: TRenderRandom;
begin
  SetLength(Result, 256 * 256);
  LRandom := TRenderRandom.Create(12345);
  try
    for LIndex := 0 to High(Result) do
      Result[LIndex] := Byte(LRandom.Next shr 8);
  finally
    LRandom.Free;
  end;
end;

function RenderCrc32(const AData; ASize: Integer): Cardinal;
begin
  Result := System.ZLib.crc32(0, nil, 0);
  if ASize > 0 then
    Result := System.ZLib.crc32(Result, PByte(@AData), ASize);
end;

function RenderSpriteHash(AHash: Cardinal; const ASprite: TGreedSprite): Cardinal;
var
  LValues: array[0..6] of Integer;
  LIndex, LByte: Integer;
begin
  LValues[0] := ASprite.BasePic;
  LValues[1] := ASprite.Angle;
  LValues[2] := ASprite.Animation;
  LValues[3] := ASprite.AnimationTime;
  LValues[4] := ASprite.X;
  LValues[5] := ASprite.Y;
  LValues[6] := ASprite.Z;
  Result := AHash;
  for LIndex := 0 to 6 do
    for LByte := 0 to 3 do
      Result := (Result xor Cardinal((LValues[LIndex] shr (LByte * 8)) and 255)) * 16777619;
end;

function RenderSpritesHash(APool: TGreedLinkedPool<TGreedSprite>): Cardinal;
var
  LIndex: Integer;
begin
  Result := 2166136261;
  LIndex := APool.First;
  while LIndex <> GREED_POOL_NIL do
  begin
    Result := RenderSpriteHash(Result, APool.Item(LIndex)^);
    LIndex := APool.Next(LIndex);
  end;
end;

{ TRenderClockFake }

function TRenderClockFake.GetTimeCount: Integer;
begin
  Result := TimeCount;
end;

function TRenderClockFake.GetSpriteMoveTime: Integer;
begin
  Result := SpriteMoveTime;
end;

{ TRenderRunner }

constructor TRenderRunner.Create(const AArchive: IGreedArchive; const AFiles: IGreedExternalFiles);
var
  LClassifier: IGreedLumpClassifier;
  LIndex, LStartSprites, LEndSprites, LRun: Integer;
begin
  inherited Create;
  FArchive := AArchive;
  FLoader := TGreedFactory.CreateMapLoader(AArchive, AFiles);
  FAssets := TGreedArchiveRenderAssets.Create(AArchive);
  FAssetsIntf := FAssets;
  FAssets.SetBackdrop(RenderTestBackdrop);
  FSprites := TGreedLinkedPool<TGreedSprite>.Create(GREED_MAX_SPRITES, 'sprites');
  FClock := TRenderClockFake.Create;
  FClockIntf := FClock;
  FRandom := TGreedRandomTable.Create;
  FRandomIntf := FRandom;
  FRenderer := TGreedFrameRenderer.Create(FAssetsIntf, FSprites, FClockIntf, FRandomIntf);
  FRendererIntf := FRenderer;
  LClassifier := TGreedFactory.CreateLumpClassifier(AArchive);
  FWallLump := AArchive.RequireIndexOf(GREED_LUMP_START_WALLS);
  for LIndex := FWallLump + 1 to AArchive.RequireIndexOf(GREED_LUMP_END_WALLS) - 1 do
    if LClassifier.Classify(LIndex) = glkWall then
    begin
      SetLength(FWallNumbers, Length(FWallNumbers) + 1);
      FWallNumbers[High(FWallNumbers)] := LIndex - FWallLump;
    end;
  LStartSprites := AArchive.RequireIndexOf(GREED_LUMP_START_SPRITES);
  LEndSprites := AArchive.RequireIndexOf(GREED_LUMP_END_SPRITES);
  SetLength(FSpriteRuns, AArchive.LumpCount);
  LRun := 0;
  for LIndex := LEndSprites - 1 downto LStartSprites + 1 do
  begin
    if LClassifier.Classify(LIndex) = glkSprite then
      Inc(LRun)
    else
      LRun := 0;
    FSpriteRuns[LIndex] := LRun;
  end;
end;

destructor TRenderRunner.Destroy;
begin
  FRendererIntf := nil;
  FSprites.Free;
  inherited Destroy;
end;

procedure TRenderRunner.LoadMap(AMapNumber: Integer; ASeed: Cardinal; AViewCount, ASpriteCount: Integer);
var
  LIndex, LDoorIndex: Integer;
  LSprite: Integer;
begin
  FWorld := TGreedWorld.Create;
  FWorld.Load(FLoader.Load(AMapNumber));
  FScenario := TRenderScenarios.Build(FWorld, ASeed, AViewCount, ASpriteCount, FWallNumbers, FSpriteRuns);
  FSprites.Clear;
  for LIndex := 0 to High(FScenario.Doors) do
  begin
    LDoorIndex := FWorld.AddDoor(FScenario.Doors[LIndex].TileX, FScenario.Doors[LIndex].TileY);
    FWorld.SetDoor(LDoorIndex, FScenario.Doors[LIndex]);
  end;
  for LIndex := 0 to High(FScenario.Sprites) do
  begin
    LSprite := FSprites.Add;
    FSprites.Item(LSprite)^ := FScenario.Sprites[LIndex];
  end;
  for LIndex := 0 to GREED_MAP_TILES + 127 do
    FRenderer.State.RealLight[LIndex] := 0;
  for LIndex := 0 to High(FScenario.Lights) do
    FRenderer.State.RealLight[FScenario.Lights[LIndex].Spot] := FScenario.Lights[LIndex].Value;
end;

procedure TRenderRunner.ResetSprites;
var
  LIndex: Integer;
begin
  FSprites.Clear;
  for LIndex := 0 to High(FScenario.Sprites) do
    FSprites.Item(FSprites.Add)^ := FScenario.Sprites[LIndex];
end;

function TRenderRunner.RenderView(AIndex: Integer): TGreedFrame;
var
  LView: TRenderView;
begin
  LView := FScenario.Views[AIndex];
  FClock.TimeCount := LView.TimeCount;
  FClock.SpriteMoveTime := LView.SpriteMoveTime;
  FillChar(FPlayer, SizeOf(FPlayer), 0);
  FPlayer.X := LView.X;
  FPlayer.Y := LView.Y;
  FPlayer.Z := LView.Z;
  FPlayer.Angle := LView.Angle;
  FPlayer.ScrollMin := LView.ScrollMin;
  Result := TGreedFrame.Make(LView.Width, LView.Height);
  FRendererIntf.Render(FWorld, FPlayer, Result);
end;

end.
