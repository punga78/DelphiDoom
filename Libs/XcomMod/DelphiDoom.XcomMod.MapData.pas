{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom ruleset library - a part of a tile of the battlescape       }
{  (MapData, one record of a MCD file)                                          }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomMod.MapData;

interface

uses
  System.SysUtils, DelphiDoom.XcomMod.Types;

const
  /// <summary>SpecialTileType: TILE, START_POINT, ..., MUST_DESTROY (the numbers of the enumeration)</summary>
  XCOM_TILE_SPECIAL_MUST_DESTROY = 14;
  /// <summary>MovementType</summary>
  XCOM_MOVE_WALK = 0;
  XCOM_MOVE_FLY = 1;
  XCOM_MOVE_SLIDE = 2;
  XCOM_MOVE_FLOAT = 3;
  XCOM_MOVE_SINK = 4;
  /// <summary>TilePart</summary>
  XCOM_PART_FLOOR = 0;
  XCOM_PART_WESTWALL = 1;
  XCOM_PART_NORTHWALL = 2;
  XCOM_PART_OBJECT = 3;
  /// <summary>MapData::O_DUMMY</summary>
  XCOM_PART_DUMMY = 999;
  /// <summary>The number of sprite frames, of block values and of LOFT layers of a part</summary>
  XCOM_MAPDATA_FRAMES = 8;
  XCOM_MAPDATA_BLOCKS = 6;
  XCOM_MAPDATA_LOFTS = 12;

type
  /// <summary>
  ///   What a part of a tile is: sprites, movement costs, blocking of light, fire and explosions, the shape
  ///   in the LOFT file, how it burns and what it becomes when it is destroyed (MapData). The numbers of
  ///   enumerations (special type, tile part) are kept as integers because the C++ casts a byte of the file
  ///   without checking it. An index of a frame, a block or a layer out of its range is EXcomModException
  ///   (the C++ reads past the array)
  /// </summary>
  TXcomMapData = class
  strict private
    FSpecialType: Integer;
    FIsUfoDoor: Boolean;
    FStopLos: Boolean;
    FIsNoFloor: Boolean;
    FIsGravLift: Boolean;
    FIsDoor: Boolean;
    FBlockFire: Boolean;
    FBlockSmoke: Boolean;
    FBaseModule: Boolean;
    FYOffset: Integer;
    FTuWalk: Integer;
    FTuFly: Integer;
    FTuSlide: Integer;
    FTerrainLevel: Integer;
    FFootstepSound: Integer;
    FDieMcd: Integer;
    FAltMcd: Integer;
    FObjectType: Integer;
    FLightSource: Integer;
    FArmor: Integer;
    FFlammable: Integer;
    FFuel: Integer;
    FExplosive: Integer;
    FExplosiveType: Integer;
    FBigWall: Integer;
    FSprite: array[0..XCOM_MAPDATA_FRAMES - 1] of Integer;
    FBlock: array[0..XCOM_MAPDATA_BLOCKS - 1] of Integer;
    FLoftId: array[0..XCOM_MAPDATA_LOFTS - 1] of Integer;
    FMiniMapIndex: Word;
    class procedure CheckRange(AIndex, ACount: Integer); static;
  public
    constructor Create;
    /// <summary>getSprite / setSprite: the sprite of a frame of animation (0..7)</summary>
    function GetSprite(AFrame: Integer): Integer;
    procedure SetSprite(AFrame, AValue: Integer);
    /// <summary>setFlags</summary>
    procedure SetFlags(AIsUfoDoor, AStopLos, AIsNoFloor: Boolean; ABigWall: Integer; AIsGravLift, AIsDoor,
      ABlockFire, ABlockSmoke, ABaseModule: Boolean);
    /// <summary>
    ///   getBlock: how much a damage type is stopped (ItemDamageType: none gives the sight block, smoke the
    ///   smoke block, HE, incendiary and stun the explosion block, any other 0)
    /// </summary>
    function GetBlock(ADamageType: Integer): Integer;
    /// <summary>The raw value of the block number (0..5), for the tests and the dumps</summary>
    function BlockValue(AIndex: Integer): Integer;
    /// <summary>setBlockValue: the vision block is 255 and the smoke block 256 if the flag is 1</summary>
    procedure SetBlockValue(ALightBlock, AVisionBlock, AHeBlock, ASmokeBlock, AFireBlock, AGasBlock: Integer);
    procedure SetHeBlock(AHeBlock: Integer);
    /// <summary>setSpecialType</summary>
    procedure SetSpecialType(AValue, AObjectType: Integer);
    /// <summary>getTUCost: the cost for walking, flying and sliding; 0 for the other kinds of movement</summary>
    function GetTuCost(AMovementType: Integer): Integer;
    procedure SetTuCosts(AWalk, AFly, ASlide: Integer);
    /// <summary>getLightSource: the lamp posts (1) give 15, the others the number minus 1</summary>
    function GetLightSource: Integer;
    function GetLoftId(ALayer: Integer): Integer;
    procedure SetLoftId(ALoft, ALayer: Integer);
    /// <summary>setStopLOS: also sets the vision block (255 or 0)</summary>
    procedure SetStopLos(AValue: Boolean);
    property SpecialType: Integer read FSpecialType;
    property ObjectType: Integer read FObjectType write FObjectType;
    property IsUfoDoor: Boolean read FIsUfoDoor;
    property StopLos: Boolean read FStopLos;
    property IsNoFloor: Boolean read FIsNoFloor write FIsNoFloor;
    property IsGravLift: Boolean read FIsGravLift;
    property IsDoor: Boolean read FIsDoor;
    property BlockFire: Boolean read FBlockFire;
    property BlockSmoke: Boolean read FBlockSmoke;
    property IsBaseModule: Boolean read FBaseModule;
    property BigWall: Integer read FBigWall write FBigWall;
    property YOffset: Integer read FYOffset write FYOffset;
    property TuWalk: Integer read FTuWalk write FTuWalk;
    property TuFly: Integer read FTuFly write FTuFly;
    property TuSlide: Integer read FTuSlide write FTuSlide;
    property TerrainLevel: Integer read FTerrainLevel write FTerrainLevel;
    property FootstepSound: Integer read FFootstepSound write FFootstepSound;
    property AltMcd: Integer read FAltMcd write FAltMcd;
    property DieMcd: Integer read FDieMcd write FDieMcd;
    /// <summary>The raw light source number (setLightSource); GetLightSource gives the light that it emits</summary>
    property LightSource: Integer read FLightSource write FLightSource;
    property Armor: Integer read FArmor write FArmor;
    property Flammable: Integer read FFlammable write FFlammable;
    property Fuel: Integer read FFuel write FFuel;
    property Explosive: Integer read FExplosive write FExplosive;
    property ExplosiveType: Integer read FExplosiveType write FExplosiveType;
    property MiniMapIndex: Word read FMiniMapIndex write FMiniMapIndex;
  end;

implementation

const
  SBadIndex = 'Xcom: index of a tile part out of range';
  DT_NONE = 0;
  DT_IN = 2;
  DT_HE = 3;
  DT_STUN = 6;
  DT_SMOKE = 9;

{ TXcomMapData }

constructor TXcomMapData.Create;
begin
  // the fields of a class start at zero: TILE, O_FLOOR and all the arrays, as the constructor of MapData sets them
  inherited Create;
end;

class procedure TXcomMapData.CheckRange(AIndex, ACount: Integer);
begin
  if (AIndex < 0) or (AIndex >= ACount) then
    raise EXcomModException.Create(SBadIndex);
end;

function TXcomMapData.GetSprite(AFrame: Integer): Integer;
begin
  CheckRange(AFrame, XCOM_MAPDATA_FRAMES);
  Result := FSprite[AFrame];
end;

procedure TXcomMapData.SetSprite(AFrame, AValue: Integer);
begin
  CheckRange(AFrame, XCOM_MAPDATA_FRAMES);
  FSprite[AFrame] := AValue;
end;

procedure TXcomMapData.SetFlags(AIsUfoDoor, AStopLos, AIsNoFloor: Boolean; ABigWall: Integer; AIsGravLift, AIsDoor,
  ABlockFire, ABlockSmoke, ABaseModule: Boolean);
begin
  FIsUfoDoor := AIsUfoDoor;
  FStopLos := AStopLos;
  FIsNoFloor := AIsNoFloor;
  FBigWall := ABigWall;
  FIsGravLift := AIsGravLift;
  FIsDoor := AIsDoor;
  FBlockFire := ABlockFire;
  FBlockSmoke := ABlockSmoke;
  FBaseModule := ABaseModule;
end;

function TXcomMapData.GetBlock(ADamageType: Integer): Integer;
begin
  case ADamageType of
    DT_NONE:
      Result := FBlock[1];
    DT_SMOKE:
      Result := FBlock[3];
    DT_HE, DT_IN, DT_STUN:
      Result := FBlock[2];
  else
    Result := 0;
  end;
end;

function TXcomMapData.BlockValue(AIndex: Integer): Integer;
begin
  CheckRange(AIndex, XCOM_MAPDATA_BLOCKS);
  Result := FBlock[AIndex];
end;

procedure TXcomMapData.SetBlockValue(ALightBlock, AVisionBlock, AHeBlock, ASmokeBlock, AFireBlock,
  AGasBlock: Integer);
begin
  FBlock[0] := ALightBlock;
  if AVisionBlock = 1 then
    FBlock[1] := 255
  else
    FBlock[1] := 0;
  FBlock[2] := AHeBlock;
  if ASmokeBlock = 1 then
    FBlock[3] := 256
  else
    FBlock[3] := 0;
  FBlock[4] := AFireBlock;
  FBlock[5] := AGasBlock;
end;

procedure TXcomMapData.SetHeBlock(AHeBlock: Integer);
begin
  FBlock[2] := AHeBlock;
end;

procedure TXcomMapData.SetSpecialType(AValue, AObjectType: Integer);
begin
  FSpecialType := AValue;
  FObjectType := AObjectType;
end;

function TXcomMapData.GetTuCost(AMovementType: Integer): Integer;
begin
  case AMovementType of
    XCOM_MOVE_WALK:
      Result := FTuWalk;
    XCOM_MOVE_FLY:
      Result := FTuFly;
    XCOM_MOVE_SLIDE:
      Result := FTuSlide;
  else
    Result := 0;
  end;
end;

procedure TXcomMapData.SetTuCosts(AWalk, AFly, ASlide: Integer);
begin
  FTuWalk := AWalk;
  FTuFly := AFly;
  FTuSlide := ASlide;
end;

function TXcomMapData.GetLightSource: Integer;
begin
  if FLightSource = 1 then
    Result := 15
  else
    Result := FLightSource - 1;
end;

function TXcomMapData.GetLoftId(ALayer: Integer): Integer;
begin
  CheckRange(ALayer, XCOM_MAPDATA_LOFTS);
  Result := FLoftId[ALayer];
end;

procedure TXcomMapData.SetLoftId(ALoft, ALayer: Integer);
begin
  CheckRange(ALayer, XCOM_MAPDATA_LOFTS);
  FLoftId[ALayer] := ALoft;
end;

procedure TXcomMapData.SetStopLos(AValue: Boolean);
begin
  FStopLos := AValue;
  if AValue then
    FBlock[1] := 255
  else
    FBlock[1] := 0;
end;

end.
