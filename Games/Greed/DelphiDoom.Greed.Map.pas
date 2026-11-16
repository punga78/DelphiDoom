{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - a map                                            }
{  Port of xGreed (Jim Valavanis, GPL v2 or later)                              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.Map;

interface

uses
  System.SysUtils, DelphiDoom.Greed.Types, DelphiDoom.Greed.Intf;

type
  /// <summary>
  ///   The 18 planes of a map (northwall, northflags, westwall ... mapslopes), 4096 bytes each, and what comes
  ///   after them in the lump. The planes are copies: the map does not share memory with the archive
  /// </summary>
  TGreedMap = class(TInterfacedObject, IGreedMap)
  strict private
    FPlanes: array[TGreedPlane] of TBytes;
    FTrailer: TBytes;
  public
    /// <param name="ABytes">At least 18 * 4096 bytes</param>
    constructor Create(const ABytes: TBytes);
    function GetPlane(APlane: TGreedPlane): TBytes;
    function GetTile(APlane: TGreedPlane; X, Y: Integer): Byte;
    function GetTrailer: TBytes;
  end;

implementation

{ TGreedMap }

constructor TGreedMap.Create(const ABytes: TBytes);
var
  LPlane: TGreedPlane;
begin
  inherited Create;
  if Length(ABytes) < GREED_MAP_BYTES then
    raise EGreedDataException.CreateFmt(SGreedMapTooShort, [GREED_MAP_BYTES, Length(ABytes)]);
  for LPlane := Low(TGreedPlane) to High(TGreedPlane) do
  begin
    FPlanes[LPlane] := Copy(ABytes, Ord(LPlane) * GREED_MAP_TILES, GREED_MAP_TILES);
  end;
  FTrailer := Copy(ABytes, GREED_MAP_BYTES, Length(ABytes) - GREED_MAP_BYTES);
end;

function TGreedMap.GetPlane(APlane: TGreedPlane): TBytes;
begin
  Result := Copy(FPlanes[APlane]);
end;

function TGreedMap.GetTile(APlane: TGreedPlane; X, Y: Integer): Byte;
begin
  if (X < 0) or (X >= GREED_MAP_SIZE) or (Y < 0) or (Y >= GREED_MAP_SIZE) then
    raise EGreedDataException.CreateFmt(SGreedTileOutside, [X, Y]);
  Result := FPlanes[APlane][Y * GREED_MAP_SIZE + X];
end;

function TGreedMap.GetTrailer: TBytes;
begin
  Result := Copy(FTrailer);
end;

end.
