{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - ruins                                             }
{                                                                              }
{  Port of war1 (acoto87/war1), war_ruins.c, (c) 2019 Alejandro Coto           }
{  Gutierrez, zlib License (see Libs\War\LICENSE-war1.txt). This is an         }
{  altered version, not the original.                                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Autotile.Ruins;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.War.Autotile.Types;

type
  /// <summary>The cells of the ruins (what a destroyed building leaves) and the piece of each one</summary>
  TWarRuins = class
  strict private
    FPieces: TList<TWarRuinPiece>;
    function GetCount: Integer;
    function GetPieces: TArray<TWarRuinPiece>;
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>we_addRuinsPieces: a square of ADimension cells from (AX, AY); a cell already there is not added again</summary>
    procedure AddSquare(AX, AY, ADimension: Integer);
    /// <summary>we_removeRuinPiece: removes the first piece equal in type and cell</summary>
    procedure RemovePiece(const APiece: TWarRuinPiece);
    function HasPieceAt(AX, AY: Integer): Boolean;
    function TryGetPieceAt(AX, AY: Integer; out APiece: TWarRuinPiece): Boolean;
    /// <summary>
    ///   we_determineRuinTypes: with the eight neighbors (a neighbor outside the map counts as a piece); the
    ///   pieces that get no type (WAR_PIECE_NONE) are removed
    /// </summary>
    procedure DetermineTypes;
    property Count: Integer read GetCount;
    property Pieces: TArray<TWarRuinPiece> read GetPieces;
  end;

implementation

uses
  DelphiDoom.War.Autotile.Data;

const
  DIR_X: array[0..7] of Integer = (-1, 0, 1, 1, 1, 0, -1, -1);
  DIR_Y: array[0..7] of Integer = (-1, -1, -1, 0, 1, 1, 1, 0);

{ TWarRuins }

constructor TWarRuins.Create;
begin
  inherited Create;
  FPieces := TList<TWarRuinPiece>.Create;
end;

destructor TWarRuins.Destroy;
begin
  FPieces.Free;
  inherited;
end;

function TWarRuins.GetCount: Integer;
begin
  Result := FPieces.Count;
end;

function TWarRuins.GetPieces: TArray<TWarRuinPiece>;
begin
  Result := FPieces.ToArray;
end;

procedure TWarRuins.AddSquare(AX, AY, ADimension: Integer);
var
  LPiece: TWarRuinPiece;
  LDeltaX: Integer;
  LDeltaY: Integer;
begin
  for LDeltaY := 0 to ADimension - 1 do
    for LDeltaX := 0 to ADimension - 1 do
      if not HasPieceAt(AX + LDeltaX, AY + LDeltaY) then
      begin
        LPiece.PieceType := 0;
        LPiece.TileX := AX + LDeltaX;
        LPiece.TileY := AY + LDeltaY;
        FPieces.Add(LPiece);
      end;
end;

procedure TWarRuins.RemovePiece(const APiece: TWarRuinPiece);
var
  LPosition: Integer;
begin
  for LPosition := 0 to FPieces.Count - 1 do
    if (FPieces[LPosition].PieceType = APiece.PieceType) and (FPieces[LPosition].TileX = APiece.TileX) and
      (FPieces[LPosition].TileY = APiece.TileY) then
    begin
      FPieces.Delete(LPosition);
      Exit;
    end;
end;

function TWarRuins.HasPieceAt(AX, AY: Integer): Boolean;
var
  LPiece: TWarRuinPiece;
begin
  Result := TryGetPieceAt(AX, AY, LPiece);
end;

function TWarRuins.TryGetPieceAt(AX, AY: Integer; out APiece: TWarRuinPiece): Boolean;
var
  LPosition: Integer;
begin
  for LPosition := 0 to FPieces.Count - 1 do
    if (FPieces[LPosition].TileX = AX) and (FPieces[LPosition].TileY = AY) then
    begin
      APiece := FPieces[LPosition];
      Exit(True);
    end;
  APiece := Default(TWarRuinPiece);
  Result := False;
end;

procedure TWarRuins.DetermineTypes;
var
  LCells: TDictionary<Integer, Boolean>;
  LPiece: TWarRuinPiece;
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
      for LDirection := 0 to 7 do
      begin
        LX := LPiece.TileX + DIR_X[LDirection];
        LY := LPiece.TileY + DIR_Y[LDirection];
        if not WarTileInside(LX, LY) or LCells.ContainsKey(WarTileKey(LX, LY)) then
          LMask := LMask or (1 shl LDirection);
      end;
      LPiece.PieceType := WAR_RUIN_TILE_TYPE_MAP[LMask];
      FPieces[LPosition] := LPiece;
    end;
  finally
    LCells.Free;
  end;
  // from the last to the first, so the positions stay valid
  for LPosition := FPieces.Count - 1 downto 0 do
    if FPieces[LPosition].PieceType = WAR_PIECE_NONE then
      FPieces.Delete(LPosition);
end;

end.
