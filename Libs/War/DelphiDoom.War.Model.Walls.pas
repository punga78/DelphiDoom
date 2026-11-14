{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the walls of a map                                 }
{                                                                              }
{  Port of war1 (acoto87/war1), war_walls.c, we_takeWallDamage of              }
{  war_entities.c and the wall of createStartingWalls of war_map.c, (c) 2019   }
{  Alejandro Coto Gutierrez, zlib License (see Libs\War\LICENSE-war1.txt).     }
{  This is an altered version, not the original.                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Model.Walls;

{$R-}
{$Q-}

interface

uses
  System.SysUtils, DelphiDoom.War.Types, DelphiDoom.War.Level.Types, DelphiDoom.War.Autotile.Types, DelphiDoom.War.Autotile.Line,
  DelphiDoom.War.Model.Construction.Types;

type
  /// <summary>
  ///   The wall of a map: its pieces (a tile each, with hit points), in the order in which they were put there. The
  ///   original keeps them in the component of one entity (map->editing.wall); the model keeps them here and the entity
  ///   of the wall, with the idle state that frees or fills the tiles by the hit points of the pieces, is in the pool.
  ///   The piece that fits the neighbors is the one of TWarLine (the same table as the roads)
  /// </summary>
  TWarWalls = class
  strict private
    FLine: TWarLine;
    FPieces: TArray<TWarWallPiece>;
    FCount: Integer;
    function GetPiece(AIndex: Integer): PWarWallPiece;
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>we_addWallPiece: a piece with no hit points and no type yet; its index (the pieces are never removed in the game)</summary>
    function Add(ATileX, ATileY: Integer; APlayer: Byte): Integer;
    /// <summary>
    ///   we_addWallPiecesFromConstruct and the hit points that createStartingWalls gives: every piece of the wall that
    ///   the level draws, with the most hit points
    /// </summary>
    procedure AddFromConstruct(const AConstruct: TWarLevelConstruct);
    /// <summary>we_hasWallPieceAtPosition</summary>
    function HasPieceAt(ATileX, ATileY: Integer): Boolean;
    /// <summary>we_getWallPieceAtPosition: the index of the first piece of the tile, -1 if there is none</summary>
    function IndexAt(ATileX, ATileY: Integer): Integer;
    /// <summary>we_determineWallTypes: the type of every piece by its four neighbors (outside the map counts as a piece)</summary>
    procedure DetermineTypes;
    /// <summary>
    ///   we_takeWallDamage: the minimum damage plus the random one (the armor of a wall is 0), down to 0 hit points.
    ///   EWarException if there is no such piece (the original has a pointer)
    /// </summary>
    procedure TakeDamage(AIndex, AMinDamage, ARndDamage: Integer);
    property Count: Integer read FCount;
    /// <summary>The piece (valid until the next Add); EWarException outside</summary>
    property Pieces[AIndex: Integer]: PWarWallPiece read GetPiece; default;
  end;

implementation

{ TWarWalls }

constructor TWarWalls.Create;
begin
  inherited Create;
  FLine := TWarLine.CreateWall;
end;

destructor TWarWalls.Destroy;
begin
  FLine.Free;
  inherited;
end;

function TWarWalls.GetPiece(AIndex: Integer): PWarWallPiece;
begin
  if (AIndex < 0) or (AIndex >= FCount) then
    raise EWarException.CreateFmt(SWarModelBadWallPiece, [AIndex]);
  Result := @FPieces[AIndex];
end;

function TWarWalls.Add(ATileX, ATileY: Integer; APlayer: Byte): Integer;
begin
  if FCount = Length(FPieces) then
    SetLength(FPieces, FCount * 2 + 16);
  FPieces[FCount] := Default(TWarWallPiece);
  FPieces[FCount].TileX := ATileX;
  FPieces[FCount].TileY := ATileY;
  FPieces[FCount].Player := APlayer;
  FLine.AddPiece(ATileX, ATileY, APlayer);
  Result := FCount;
  Inc(FCount);
end;

procedure TWarWalls.AddFromConstruct(const AConstruct: TWarLevelConstruct);
var
  LFirst: Integer;
  LCells: TArray<TWarLinePiece>;
  LIndex: Integer;
begin
  LFirst := FCount;
  FLine.AddFromConstruct(AConstruct);
  LCells := FLine.Pieces;
  for LIndex := LFirst to High(LCells) do
  begin
    if FCount = Length(FPieces) then
      SetLength(FPieces, FCount * 2 + 16);
    FPieces[FCount] := Default(TWarWallPiece);
    FPieces[FCount].TileX := LCells[LIndex].TileX;
    FPieces[FCount].TileY := LCells[LIndex].TileY;
    FPieces[FCount].Player := LCells[LIndex].Player;
    FPieces[FCount].Hp := WAR_WALL_MAX_HP;
    FPieces[FCount].MaxHp := WAR_WALL_MAX_HP;
    Inc(FCount);
  end;
end;

function TWarWalls.HasPieceAt(ATileX, ATileY: Integer): Boolean;
begin
  Result := IndexAt(ATileX, ATileY) >= 0;
end;

function TWarWalls.IndexAt(ATileX, ATileY: Integer): Integer;
var
  LIndex: Integer;
begin
  for LIndex := 0 to FCount - 1 do
    if (FPieces[LIndex].TileX = ATileX) and (FPieces[LIndex].TileY = ATileY) then
      Exit(LIndex);
  Result := -1;
end;

procedure TWarWalls.DetermineTypes;
var
  LCells: TArray<TWarLinePiece>;
  LIndex: Integer;
begin
  FLine.DetermineTypes;
  LCells := FLine.Pieces;
  for LIndex := 0 to FCount - 1 do
    FPieces[LIndex].PieceType := LCells[LIndex].PieceType;
end;

procedure TWarWalls.TakeDamage(AIndex, AMinDamage, ARndDamage: Integer);
var
  LPiece: PWarWallPiece;
  LRandom: Integer;
begin
  LPiece := GetPiece(AIndex);
  // we_getTotalDamage(min, rnd, 0): the minimum plus the random part, which no armor lowers
  LRandom := ARndDamage;
  if LRandom < 0 then
    LRandom := 0;
  LPiece^.Hp := LPiece^.Hp - (AMinDamage + LRandom);
  if LPiece^.Hp < 0 then
    LPiece^.Hp := 0;
end;

end.
