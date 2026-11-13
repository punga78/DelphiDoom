{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - fakes and builders of the map        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.MapSupport;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.War.Level.Types, DelphiDoom.War.Level.Intf,
  DelphiDoom.War.Map.Types, DelphiDoom.War.Map.Intf;

type
  /// <summary>A painter that only remembers what it was asked (no minimap, no visual map)</summary>
  TFakeTilePainter = class(TInterfacedObject, IWarTilePainter)
  strict private
    FCalls: TList<TArray<Integer>>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure SetTileIndex(AX, AY, ATile: Integer);
    function GetTileIndex(AX, AY: Integer): Integer;
    function GetVisual: TArray<Word>;
    /// <summary>X, Y and tile of each call</summary>
    property Calls: TList<TArray<Integer>> read FCalls;
  end;

  /// <summary>Data for the tests of the map: a tileset image, a passable map and a level made in memory</summary>
  TMapFixtures = class
  public
    /// <summary>
    ///   An image of the tileset: the mega tile K is one solid color, (K mod 256, K div 2 mod 256, 7), alpha 255,
    ///   as large as the real one (512 x 256 pixels)
    /// </summary>
    class function Tileset: TBytes; static;
    /// <summary>A passable map of 64 x 64 empty cells</summary>
    class function EmptyPassable: TArray<Word>; static;
    /// <summary>A visual map with the tile ATile in every cell</summary>
    class function FlatVisual(ATile: Word): TArray<Word>; static;
    /// <summary>The passable cell is wood: a block of cells at (AX, AY), AWidth x AHeight</summary>
    class procedure PutWood(var APassable: TArray<Word>; AX, AY, AWidth, AHeight: Integer); static;
    /// <summary>A level with the info, a flat visual map and the passable map</summary>
    class function MakeLevel(const AInfo: TWarLevelInfo; const APassable: TArray<Word>): IWarLevel; static;
    /// <summary>A level info with two players (human and orcs), gold and wood and the forest tileset</summary>
    class function BasicInfo: TWarLevelInfo; static;
    class function StartUnit(AX, AY, AUnitType, APlayer: Byte; AKind: TWarResourceKind; AAmount: Word): TWarLevelUnit; static;
  end;

implementation

uses
  DelphiDoom.War.Level;

{ TFakeTilePainter }

constructor TFakeTilePainter.Create;
begin
  inherited Create;
  FCalls := TList<TArray<Integer>>.Create;
end;

destructor TFakeTilePainter.Destroy;
begin
  FCalls.Free;
  inherited;
end;

procedure TFakeTilePainter.SetTileIndex(AX, AY, ATile: Integer);
begin
  FCalls.Add([AX, AY, ATile]);
end;

function TFakeTilePainter.GetTileIndex(AX, AY: Integer): Integer;
begin
  Result := 0;
end;

function TFakeTilePainter.GetVisual: TArray<Word>;
begin
  SetLength(Result, WAR_MAP_TILE_COUNT);
end;

{ TMapFixtures }

class function TMapFixtures.Tileset: TBytes;
var
  LTile: Integer;
  LX: Integer;
  LY: Integer;
  LOffset: Integer;
begin
  SetLength(Result, 512 * 256 * 4);
  for LY := 0 to 255 do
    for LX := 0 to 511 do
    begin
      LTile := (LY div 16) * 32 + (LX div 16);
      LOffset := (LY * 512 + LX) * 4;
      Result[LOffset] := Byte(LTile);
      Result[LOffset + 1] := Byte(LTile div 2);
      Result[LOffset + 2] := 7;
      Result[LOffset + 3] := 255;
    end;
end;

class function TMapFixtures.EmptyPassable: TArray<Word>;
begin
  SetLength(Result, WAR_MAP_TILE_COUNT);
end;

class function TMapFixtures.FlatVisual(ATile: Word): TArray<Word>;
var
  LIndex: Integer;
begin
  SetLength(Result, WAR_MAP_TILE_COUNT);
  for LIndex := 0 to WAR_MAP_TILE_COUNT - 1 do
    Result[LIndex] := ATile;
end;

class procedure TMapFixtures.PutWood(var APassable: TArray<Word>; AX, AY, AWidth, AHeight: Integer);
var
  LX: Integer;
  LY: Integer;
begin
  for LY := AY to AY + AHeight - 1 do
    for LX := AX to AX + AWidth - 1 do
      APassable[LY * WAR_MAP_TILES_WIDTH + LX] := 128;
end;

class function TMapFixtures.MakeLevel(const AInfo: TWarLevelInfo; const APassable: TArray<Word>): IWarLevel;
begin
  Result := TWarLevel.Create(AInfo, FlatVisual(3), APassable);
end;

class function TMapFixtures.BasicInfo: TWarLevelInfo;
var
  LIndex: Integer;
begin
  Result := Default(TWarLevelInfo);
  Result.Index := 117;
  Result.TilesetType := WAR_TILESET_FOREST;
  Result.StartX := 5;
  Result.StartY := 7;
  Result.Races[0] := wraHumans;
  Result.Races[1] := wraOrcs;
  Result.Gold[0] := 2000;
  Result.Gold[1] := 1500;
  Result.Lumber[0] := 900;
  Result.Lumber[1] := 800;
  for LIndex := 0 to WAR_MAX_FEATURES_COUNT - 1 do
    Result.AllowedFeatures[LIndex] := Byte(LIndex and 1);
  Result.AllowedUpgrades[2, 1] := 1;
end;

class function TMapFixtures.StartUnit(AX, AY, AUnitType, APlayer: Byte; AKind: TWarResourceKind;
  AAmount: Word): TWarLevelUnit;
begin
  Result.X := AX;
  Result.Y := AY;
  Result.UnitType := AUnitType;
  Result.Player := APlayer;
  Result.ResourceKind := AKind;
  Result.Amount := AAmount;
end;

end.
