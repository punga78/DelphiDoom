{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the world                                        }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): LoadNewMap, ActivateSlopes  }
{  and RF_ClearWorld, RF_GetDoor, RF_GetSpawnArea                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.World;

interface

uses
  System.SysUtils, DelphiDoom.Greed.Types, DelphiDoom.Greed.Intf, DelphiDoom.Greed.World.Intf;

type
  /// <summary>The planes, the flags and the lists of doors and spawn areas of the level, owned by the object</summary>
  TGreedWorld = class(TInterfacedObject, IGreedWorld)
  strict private
    FPlanes: array[TGreedPlane] of TBytes;
    FMapFlags: TBytes;
    FDoors: array[0..GREED_MAX_DOORS - 1] of TGreedDoor;
    FDoorCount: Integer;
    FSpawnAreas: array[0..GREED_MAX_SPAWN_AREAS - 1] of TGreedSpawnArea;
    FSpawnAreaCount: Integer;
    procedure ActivateSlopes;
  public
    constructor Create;
    procedure Load(const AMap: IGreedMap);
    function GetValue(APlane: TGreedPlane; ASpot: Integer): Byte;
    procedure SetValue(APlane: TGreedPlane; ASpot: Integer; AValue: Byte);
    procedure CopyPlane(APlane: TGreedPlane; ADest: PByte);
    procedure CopyMapFlags(ADest: PByte);
    function GetMapFlags(ASpot: Integer): Byte;
    procedure SetMapFlags(ASpot: Integer; AValue: Byte);
    function AddDoor(ATileX, ATileY: Integer): Integer;
    function GetDoorCount: Integer;
    function GetDoor(AIndex: Integer): TGreedDoor;
    procedure SetDoor(AIndex: Integer; const ADoor: TGreedDoor);
    function AddSpawnArea: Integer;
    function GetSpawnAreaCount: Integer;
    function GetSpawnArea(AIndex: Integer): TGreedSpawnArea;
    procedure SetSpawnArea(AIndex: Integer; const AArea: TGreedSpawnArea);
  end;

implementation

uses
  DelphiDoom.Greed.Slopes;

const
  // the ground definition that a tile without one gets (LoadNewMap)
  DEFAULT_DEFINITION = 56;

{ TGreedWorld }

constructor TGreedWorld.Create;
var
  LPlane: TGreedPlane;
begin
  inherited Create;
  for LPlane := Low(TGreedPlane) to High(TGreedPlane) do
    SetLength(FPlanes[LPlane], GREED_MAP_TILES);
  SetLength(FMapFlags, GREED_MAP_TILES);
end;

procedure TGreedWorld.ActivateSlopes;
var
  LSpot: Integer;
begin
  for LSpot := 0 to GREED_MAP_TILES - 1 do
    FMapFlags[LSpot] := FMapFlags[LSpot] or TGreedSlopes.FlagsOf(FPlanes[gpMapSlopes][LSpot]);
end;

procedure TGreedWorld.Load(const AMap: IGreedMap);
var
  LPlane: TGreedPlane;
  LSpot: Integer;
begin
  if not Assigned(AMap) then
    raise EArgumentNilException.Create('AMap');
  // RF_ClearWorld: the lists of doors and spawn areas (the sprites and the elevators are not here yet)
  FDoorCount := 0;
  FSpawnAreaCount := 0;
  for LPlane := Low(TGreedPlane) to High(TGreedPlane) do
    FPlanes[LPlane] := Copy(AMap.Planes[LPlane], 0, GREED_MAP_TILES);
  FillChar(FMapFlags[0], Length(FMapFlags), 0);
  for LSpot := 0 to GREED_MAP_TILES - 1 do
  begin
    if FPlanes[gpFloorDef][LSpot] = 0 then
      FPlanes[gpFloorDef][LSpot] := DEFAULT_DEFINITION;
    if FPlanes[gpCeilingDef][LSpot] = 0 then
      FPlanes[gpCeilingDef][LSpot] := DEFAULT_DEFINITION;
  end;
  ActivateSlopes;
end;

function TGreedWorld.GetValue(APlane: TGreedPlane; ASpot: Integer): Byte;
begin
  if (ASpot < 0) or (ASpot >= GREED_MAP_TILES) then
    Exit(0);
  Result := FPlanes[APlane][ASpot];
end;

procedure TGreedWorld.SetValue(APlane: TGreedPlane; ASpot: Integer; AValue: Byte);
begin
  if (ASpot < 0) or (ASpot >= GREED_MAP_TILES) then
    raise EGreedDataException.CreateFmt(SGreedTileOutside, [ASpot mod GREED_MAP_SIZE, ASpot div GREED_MAP_SIZE]);
  FPlanes[APlane][ASpot] := AValue;
end;

procedure TGreedWorld.CopyPlane(APlane: TGreedPlane; ADest: PByte);
begin
  Move(FPlanes[APlane][0], ADest^, GREED_MAP_TILES);
end;

procedure TGreedWorld.CopyMapFlags(ADest: PByte);
begin
  Move(FMapFlags[0], ADest^, GREED_MAP_TILES);
end;

function TGreedWorld.GetMapFlags(ASpot: Integer): Byte;
begin
  if (ASpot < 0) or (ASpot >= GREED_MAP_TILES) then
    Exit(0);
  Result := FMapFlags[ASpot];
end;

procedure TGreedWorld.SetMapFlags(ASpot: Integer; AValue: Byte);
begin
  if (ASpot < 0) or (ASpot >= GREED_MAP_TILES) then
    raise EGreedDataException.CreateFmt(SGreedTileOutside, [ASpot mod GREED_MAP_SIZE, ASpot div GREED_MAP_SIZE]);
  FMapFlags[ASpot] := AValue;
end;

function TGreedWorld.AddDoor(ATileX, ATileY: Integer): Integer;
var
  LSpot: Integer;
begin
  if FDoorCount = GREED_MAX_DOORS then
    raise EGreedException.CreateFmt(SGreedTooMany, ['doors', GREED_MAX_DOORS]);
  LSpot := ATileY * GREED_MAP_SIZE + ATileX;
  if (ATileX < 0) or (ATileX >= GREED_MAP_SIZE) or (LSpot < 0) or (LSpot >= GREED_MAP_TILES) then
    raise EGreedDataException.CreateFmt(SGreedTileOutside, [ATileX, ATileY]);
  Result := FDoorCount;
  Inc(FDoorCount);
  // kept defect of the original: RF_ClearWorld only sets the count of the doors to zero and RF_GetDoor only
  // writes the tile, so a door keeps the fields that the door with the same number had in the map before (the
  // same map loaded again after the player died: a door that was open is "open" again while it looks closed)
  FDoors[Result].TileX := ATileX;
  FDoors[Result].TileY := ATileY;
  FMapFlags[LSpot] := FMapFlags[LSpot] or GREED_FL_DOOR;
end;

function TGreedWorld.GetDoorCount: Integer;
begin
  Result := FDoorCount;
end;

function TGreedWorld.GetDoor(AIndex: Integer): TGreedDoor;
begin
  if (AIndex < 0) or (AIndex >= FDoorCount) then
    raise EGreedException.CreateFmt(SGreedArgumentRange, [AIndex, 'the door', 0, FDoorCount - 1]);
  Result := FDoors[AIndex];
end;

procedure TGreedWorld.SetDoor(AIndex: Integer; const ADoor: TGreedDoor);
begin
  if (AIndex < 0) or (AIndex >= FDoorCount) then
    raise EGreedException.CreateFmt(SGreedArgumentRange, [AIndex, 'the door', 0, FDoorCount - 1]);
  FDoors[AIndex] := ADoor;
end;

function TGreedWorld.AddSpawnArea: Integer;
begin
  if FSpawnAreaCount = GREED_MAX_SPAWN_AREAS then
    raise EGreedException.CreateFmt(SGreedTooMany, ['spawn areas', GREED_MAX_SPAWN_AREAS]);
  Result := FSpawnAreaCount;
  Inc(FSpawnAreaCount);
  FSpawnAreas[Result] := Default(TGreedSpawnArea);
end;

function TGreedWorld.GetSpawnAreaCount: Integer;
begin
  Result := FSpawnAreaCount;
end;

function TGreedWorld.GetSpawnArea(AIndex: Integer): TGreedSpawnArea;
begin
  if (AIndex < 0) or (AIndex >= FSpawnAreaCount) then
    raise EGreedException.CreateFmt(SGreedArgumentRange, [AIndex, 'the spawn area', 0, FSpawnAreaCount - 1]);
  Result := FSpawnAreas[AIndex];
end;

procedure TGreedWorld.SetSpawnArea(AIndex: Integer; const AArea: TGreedSpawnArea);
begin
  if (AIndex < 0) or (AIndex >= FSpawnAreaCount) then
    raise EGreedException.CreateFmt(SGreedArgumentRange, [AIndex, 'the spawn area', 0, FSpawnAreaCount - 1]);
  FSpawnAreas[AIndex] := AArea;
end;

end.
