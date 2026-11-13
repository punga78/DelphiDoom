{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - roads and walls                                   }
{                                                                              }
{  Port of war1 (acoto87/war1), war_roads.c and war_walls.c, (c) 2019          }
{  Alejandro Coto Gutierrez, zlib License (see Libs\War\LICENSE-war1.txt).     }
{  This is an altered version, not the original.                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Autotile.Line;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.War.Level.Types, DelphiDoom.War.Autotile.Types;

type
  /// <summary>
  ///   The cells of the roads (or of the walls) of a level and the piece of each one. A road and a wall work
  ///   the same, only the table of the pieces is not the one: the constructor takes it
  /// </summary>
  TWarLine = class
  strict private
    FTypeMap: TWarLineTypeMap;
    FPieces: TList<TWarLinePiece>;
    function GetCount: Integer;
    function GetPieces: TArray<TWarLinePiece>;
  public
    constructor Create(const ATypeMap: TWarLineTypeMap);
    destructor Destroy; override;
    /// <summary>The roads, with roadTileTypeMap</summary>
    class function CreateRoad: TWarLine; static;
    /// <summary>The walls, with wallTileTypeMap</summary>
    class function CreateWall: TWarLine; static;
    /// <summary>we_addRoadPiece / we_addWallPiece (the piece type is set by DetermineTypes)</summary>
    procedure AddPiece(AX, AY: Integer; APlayer: Byte);
    /// <summary>
    ///   we_add*PiecesFromConstruct: the cells from (X1, Y1) along X to X2 and then along Y to Y2. The corner
    ///   cell and the last one are added twice, as in the original (they are the same cell: the piece type does
    ///   not change, the count does)
    /// </summary>
    procedure AddFromConstruct(const AConstruct: TWarLevelConstruct);
    /// <summary>we_remove*Piece: removes the first piece equal in type, cell and player</summary>
    procedure RemovePiece(const APiece: TWarLinePiece);
    /// <summary>we_has*PieceAtPosition</summary>
    function HasPieceAt(AX, AY: Integer): Boolean;
    /// <summary>we_get*PieceAtPosition: the first piece of the cell</summary>
    function TryGetPieceAt(AX, AY: Integer; out APiece: TWarLinePiece): Boolean;
    /// <summary>
    ///   we_determine*Types: a neighbor outside the map counts as a piece; bit 0 up, 1 right, 2 down, 3 left
    /// </summary>
    procedure DetermineTypes;
    property Count: Integer read GetCount;
    property Pieces: TArray<TWarLinePiece> read GetPieces;
  end;

implementation

uses
  DelphiDoom.War.Autotile.Data;

const
  DIR_X: array[0..3] of Integer = (0, 1, 0, -1);
  DIR_Y: array[0..3] of Integer = (-1, 0, 1, 0);

{ TWarLine }

constructor TWarLine.Create(const ATypeMap: TWarLineTypeMap);
begin
  inherited Create;
  FTypeMap := ATypeMap;
  FPieces := TList<TWarLinePiece>.Create;
end;

destructor TWarLine.Destroy;
begin
  FPieces.Free;
  inherited;
end;

class function TWarLine.CreateRoad: TWarLine;
var
  LMap: TWarLineTypeMap;
begin
  Move(WAR_ROAD_TILE_TYPE_MAP, LMap, SizeOf(LMap));
  Result := TWarLine.Create(LMap);
end;

class function TWarLine.CreateWall: TWarLine;
var
  LMap: TWarLineTypeMap;
begin
  Move(WAR_WALL_TILE_TYPE_MAP, LMap, SizeOf(LMap));
  Result := TWarLine.Create(LMap);
end;

function TWarLine.GetCount: Integer;
begin
  Result := FPieces.Count;
end;

function TWarLine.GetPieces: TArray<TWarLinePiece>;
begin
  Result := FPieces.ToArray;
end;

procedure TWarLine.AddPiece(AX, AY: Integer; APlayer: Byte);
var
  LPiece: TWarLinePiece;
begin
  LPiece.PieceType := 0;
  LPiece.TileX := AX;
  LPiece.TileY := AY;
  LPiece.Player := APlayer;
  FPieces.Add(LPiece);
end;

procedure TWarLine.AddFromConstruct(const AConstruct: TWarLevelConstruct);
var
  LX: Integer;
  LY: Integer;
  LDeltaX: Integer;
  LDeltaY: Integer;
begin
  // SIGN(0) of the original is 1
  if AConstruct.X2 < AConstruct.X1 then
    LDeltaX := -1
  else
    LDeltaX := 1;
  if AConstruct.Y2 < AConstruct.Y1 then
    LDeltaY := -1
  else
    LDeltaY := 1;
  LX := AConstruct.X1;
  LY := AConstruct.Y1;
  while LX <> AConstruct.X2 do
  begin
    AddPiece(LX, LY, AConstruct.Player);
    Inc(LX, LDeltaX);
  end;
  AddPiece(LX, LY, AConstruct.Player);
  while LY <> AConstruct.Y2 do
  begin
    AddPiece(LX, LY, AConstruct.Player);
    Inc(LY, LDeltaY);
  end;
  AddPiece(LX, LY, AConstruct.Player);
end;

procedure TWarLine.RemovePiece(const APiece: TWarLinePiece);
var
  LPosition: Integer;
begin
  for LPosition := 0 to FPieces.Count - 1 do
    if (FPieces[LPosition].PieceType = APiece.PieceType) and (FPieces[LPosition].Player = APiece.Player) and
      (FPieces[LPosition].TileX = APiece.TileX) and (FPieces[LPosition].TileY = APiece.TileY) then
    begin
      FPieces.Delete(LPosition);
      Exit;
    end;
end;

function TWarLine.HasPieceAt(AX, AY: Integer): Boolean;
var
  LPiece: TWarLinePiece;
begin
  Result := TryGetPieceAt(AX, AY, LPiece);
end;

function TWarLine.TryGetPieceAt(AX, AY: Integer; out APiece: TWarLinePiece): Boolean;
var
  LPosition: Integer;
begin
  for LPosition := 0 to FPieces.Count - 1 do
    if (FPieces[LPosition].TileX = AX) and (FPieces[LPosition].TileY = AY) then
    begin
      APiece := FPieces[LPosition];
      Exit(True);
    end;
  APiece := Default(TWarLinePiece);
  Result := False;
end;

procedure TWarLine.DetermineTypes;
var
  LCells: TDictionary<Integer, Boolean>;
  LPiece: TWarLinePiece;
  LPosition: Integer;
  LDirection: Integer;
  LMask: Integer;
  LX: Integer;
  LY: Integer;
begin
  LCells := TDictionary<Integer, Boolean>.Create;
  try
    for LPiece in FPieces do
      LCells.AddOrSetValue(WarTileKey(LPiece.TileX, LPiece.TileY), True);
    for LPosition := 0 to FPieces.Count - 1 do
    begin
      LPiece := FPieces[LPosition];
      LMask := 0;
      for LDirection := 0 to 3 do
      begin
        LX := LPiece.TileX + DIR_X[LDirection];
        LY := LPiece.TileY + DIR_Y[LDirection];
        if not WarTileInside(LX, LY) or LCells.ContainsKey(WarTileKey(LX, LY)) then
          LMask := LMask or (1 shl LDirection);
      end;
      LPiece.PieceType := FTypeMap[LMask];
      FPieces[LPosition] := LPiece;
    end;
  finally
    LCells.Free;
  end;
end;

end.
