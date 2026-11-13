{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - the lines of the map dump            }
{                                                                              }
{  The same lines war_map_ref.exe writes (Tools\Verifica\193), made from the   }
{  Delphi map, to compare with Tests\Data\War\map.*.golden.txt                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.MapDump;

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.War.Autotile.Types, DelphiDoom.War.Map.Types, DelphiDoom.War.Map.Forest,
  DelphiDoom.War.Map.Game;

type
  /// <summary>The impronte and the lines of the dump of the C harness, in Delphi</summary>
  TWarMapDump = class
  public
    /// <summary>CRC-32 of the bytes, as 8 lowercase hex digits</summary>
    class function Hex(const ABytes: TBytes): string; static;
    class function Words(const AValues: TArray<Word>): string; static;
    class function ForestChecksum(const AForest: TWarMapForest): string; static;
    /// <summary>CRC-32 of the ids and checksums of all the forests; also the forests and trees counts</summary>
    class function ForestsChecksum(const AMap: TWarGameMap; out AForests, ATrees: Integer): string; static;
    class function UnitsChecksum(const AMap: TWarGameMap): string; static;
    class function TilesChecksum(const AMap: TWarGameMap; AWhat: Integer): string; static;
    /// <summary>dumpMap of the harness: M, P, T, TE, Q, W, R, N, H, S, V, I</summary>
    class procedure DumpMap(const AMap: TWarGameMap; AIndex: Integer; ALines: TStrings); static;
    /// <summary>dumpFog of the harness: F</summary>
    class procedure DumpFog(const AMap: TWarGameMap; AIndex: Integer; ALines: TStrings); static;
    /// <summary>dumpMinimap of the harness (the frame after RenderMinimap)</summary>
    class procedure DumpMinimap(const AMap: TWarGameMap; AIndex: Integer; const ATag: string; ALines: TStrings); static;
  end;

implementation

uses
  DelphiDoom.MathCore.Crc32, DelphiDoom.War.Level.Types;

type
  TPut = class
  strict private
    FCrc: TCrc32;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Put32(AValue: Cardinal);
    procedure PutBytes(const ABytes: array of Byte);
    function Text: string;
  end;

constructor TPut.Create;
begin
  inherited Create;
  FCrc := TCrc32.Create;
end;

destructor TPut.Destroy;
begin
  FCrc.Free;
  inherited;
end;

procedure TPut.Put32(AValue: Cardinal);
begin
  FCrc.Update(AValue, 4);
end;

procedure TPut.PutBytes(const ABytes: array of Byte);
begin
  if Length(ABytes) > 0 then
    FCrc.Update(ABytes[0], Length(ABytes));
end;

function TPut.Text: string;
begin
  Result := LowerCase(TCrc32.ToHex(FCrc.Value));
end;

{ TWarMapDump }

class function TWarMapDump.Hex(const ABytes: TBytes): string;
begin
  if Length(ABytes) = 0 then
    Exit('00000000');
  Result := LowerCase(TCrc32.ToHex(TCrc32.Calculate(ABytes[0], Length(ABytes))));
end;

class function TWarMapDump.Words(const AValues: TArray<Word>): string;
var
  LBytes: TBytes;
  LIndex: Integer;
begin
  SetLength(LBytes, Length(AValues) * 2);
  for LIndex := 0 to High(AValues) do
  begin
    LBytes[LIndex * 2] := Byte(AValues[LIndex]);
    LBytes[LIndex * 2 + 1] := Byte(AValues[LIndex] shr 8);
  end;
  Result := Hex(LBytes);
end;

class function TWarMapDump.ForestChecksum(const AForest: TWarMapForest): string;
var
  LPut: TPut;
  LTree: TWarTree;
begin
  LPut := TPut.Create;
  try
    LPut.Put32(AForest.Trees.Count);
    for LTree in AForest.Trees do
    begin
      LPut.Put32(LTree.TileType);
      LPut.Put32(Cardinal(LTree.TileX));
      LPut.Put32(Cardinal(LTree.TileY));
      LPut.Put32(Cardinal(LTree.Amount));
    end;
    Result := LPut.Text;
  finally
    LPut.Free;
  end;
end;

class function TWarMapDump.ForestsChecksum(const AMap: TWarGameMap; out AForests, ATrees: Integer): string;
var
  LPut: TPut;
  LIndex: Integer;
  LForest: TWarMapForest;
begin
  LPut := TPut.Create;
  try
    AForests := AMap.Forests.Count;
    ATrees := 0;
    for LIndex := 0 to AMap.Forests.Count - 1 do
    begin
      LForest := AMap.Forests[LIndex];
      LPut.Put32(LForest.Id);
      LPut.Put32(Cardinal(StrToInt64('$' + ForestChecksum(LForest))));
      Inc(ATrees, LForest.Trees.Count);
    end;
    Result := LPut.Text;
  finally
    LPut.Free;
  end;
end;

class function TWarMapDump.UnitsChecksum(const AMap: TWarGameMap): string;
var
  LPut: TPut;
  LUnit: TWarMapUnit;
begin
  LPut := TPut.Create;
  try
    for LUnit in AMap.Units do
    begin
      LPut.Put32(LUnit.Id);
      LPut.Put32(Cardinal(LUnit.UnitType));
      LPut.Put32(Cardinal(LUnit.Direction));
      LPut.Put32(Cardinal(LUnit.TileX));
      LPut.Put32(Cardinal(LUnit.TileY));
      LPut.Put32(Cardinal(LUnit.SizeX));
      LPut.Put32(Cardinal(LUnit.SizeY));
      LPut.Put32(LUnit.Player);
      LPut.Put32(Ord(LUnit.ResourceKind));
      LPut.Put32(Cardinal(LUnit.Amount));
      LPut.Put32(Cardinal(LUnit.MaxHp));
      LPut.Put32(Cardinal(LUnit.Hp));
      LPut.Put32(Cardinal(LUnit.MaxMana));
      LPut.Put32(Cardinal(LUnit.Mana));
      LPut.Put32(Cardinal(LUnit.Armor));
      LPut.Put32(Cardinal(LUnit.Range));
      LPut.Put32(Cardinal(LUnit.MinDamage));
      LPut.Put32(Cardinal(LUnit.RndDamage));
      LPut.Put32(Cardinal(LUnit.Decay));
      LPut.Put32(Cardinal(LUnit.ManaTime));
      LPut.Put32(Ord(LUnit.HasBeenSeen));
      LPut.Put32(Cardinal(LUnit.TileX * WAR_MEGA_TILE_SIZE));
      LPut.Put32(Cardinal(LUnit.TileY * WAR_MEGA_TILE_SIZE));
    end;
    Result := LPut.Text;
  finally
    LPut.Free;
  end;
end;

class function TWarMapDump.TilesChecksum(const AMap: TWarGameMap; AWhat: Integer): string;
var
  LBytes: TBytes;
  LIndex: Integer;
  LTile: TWarMapTile;
begin
  SetLength(LBytes, WAR_MAP_TILE_COUNT);
  for LIndex := 0 to WAR_MAP_TILE_COUNT - 1 do
  begin
    LTile := AMap.Fog.GetTile(LIndex mod WAR_MAP_TILES_WIDTH, LIndex div WAR_MAP_TILES_WIDTH);
    case AWhat of
      0: LBytes[LIndex] := Byte(Ord(LTile.State));
      1: LBytes[LIndex] := LTile.PieceType;
    else
      LBytes[LIndex] := Byte(Ord(LTile.Boundary));
    end;
  end;
  Result := Hex(LBytes);
end;

class procedure TWarMapDump.DumpMap(const AMap: TWarGameMap; AIndex: Integer; ALines: TStrings);
var
  LPlayer: Integer;
  LForests: Integer;
  LTrees: Integer;
  LForestsText: string;
  LFeatures: TBytes;
  LUpgrades: TBytes;
  LIndex: Integer;
  LPut: TPut;
  LPiece: TWarLinePiece;
  LCrc: string;
  LPlayerInfo: TWarPlayerInfo;
begin
  ALines.Add(Format('M %d %d %d %d %d %d', [AIndex, AMap.PlayersCount, Ord(AMap.Info.CustomMap), AMap.Info.TilesetType,
    AMap.Viewport.X, AMap.Viewport.Y]));
  for LPlayer := 0 to WAR_MAX_PLAYERS_COUNT - 1 do
  begin
    LPlayerInfo := AMap.Players[LPlayer];
    SetLength(LFeatures, WAR_MAX_FEATURES_COUNT);
    for LIndex := 0 to WAR_MAX_FEATURES_COUNT - 1 do
      LFeatures[LIndex] := LPlayerInfo.Features[LIndex];
    SetLength(LUpgrades, WAR_MAX_UPGRADES_COUNT * 2);
    for LIndex := 0 to WAR_MAX_UPGRADES_COUNT - 1 do
    begin
      LUpgrades[LIndex * 2] := LPlayerInfo.Upgrades[LIndex].Allowed;
      LUpgrades[LIndex * 2 + 1] := LPlayerInfo.Upgrades[LIndex].Level;
    end;
    ALines.Add(Format('P %d %d %d %d %d %d %s %s', [AIndex, LPlayer, LPlayerInfo.Index, Ord(LPlayerInfo.Race),
      LPlayerInfo.Gold, LPlayerInfo.Wood, Hex(LFeatures), Hex(LUpgrades)]));
  end;
  LForestsText := ForestsChecksum(AMap, LForests, LTrees);
  ALines.Add(Format('T %d %d %d %s', [AIndex, LForests, LTrees, LForestsText]));
  ALines.Add(Format('TE %d %d %s', [AIndex, AMap.Forests.EditingForest.Id, ForestChecksum(AMap.Forests.EditingForest)]));
  LPut := TPut.Create;
  try
    for LPiece in AMap.Road.Pieces do
      LPut.PutBytes([LPiece.PieceType, Byte(LPiece.TileX), Byte(LPiece.TileY), LPiece.Player]);
    ALines.Add(Format('Q %d %d %d %s', [AIndex, AMap.RoadId, AMap.Road.Count, LPut.Text]));
  finally
    LPut.Free;
  end;
  LPut := TPut.Create;
  try
    for LPiece in AMap.Wall.Pieces do
      LPut.PutBytes([LPiece.PieceType, Byte(LPiece.TileX), Byte(LPiece.TileY), LPiece.Player, WAR_WALL_MAX_HP,
        WAR_WALL_MAX_HP]);
    ALines.Add(Format('W %d %d %d %s', [AIndex, AMap.WallId, AMap.Wall.Count, LPut.Text]));
  finally
    LPut.Free;
  end;
  ALines.Add(Format('R %d %d %d', [AIndex, AMap.RuinsId, AMap.Ruins.Count]));
  ALines.Add(Format('N %d %d %s %d', [AIndex, AMap.Units.Count, UnitsChecksum(AMap), AMap.LastEntityId]));
  ALines.Add(Format('H %d %s', [AIndex, Words(AMap.Grid.ToArray)]));
  ALines.Add(Format('S %d %s', [AIndex, TilesChecksum(AMap, 0)]));
  ALines.Add(Format('V %d %s', [AIndex, Words(AMap.Visual)]));
  LCrc := Hex(AMap.Minimap.Frame);
  ALines.Add(Format('I %d %s %s', [AIndex, LCrc, Hex(AMap.Minimap.Terrain)]));
end;

class procedure TWarMapDump.DumpFog(const AMap: TWarGameMap; AIndex: Integer; ALines: TStrings);
begin
  ALines.Add(Format('F %d %d %d %d %s %s %s', [AIndex, AMap.Fog.CountState(wtsVisible), AMap.Fog.CountState(wtsFog),
    AMap.Fog.CountState(wtsUnknown), TilesChecksum(AMap, 0), TilesChecksum(AMap, 1), TilesChecksum(AMap, 2)]));
end;

class procedure TWarMapDump.DumpMinimap(const AMap: TWarGameMap; AIndex: Integer; const ATag: string; ALines: TStrings);
begin
  ALines.Add(Format('%s %d %s 0', [ATag, AIndex, Hex(AMap.Minimap.Frame)]));
end;

end.
