{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - finds and loads a map of the archive             }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): LoadNewMap of utils.pas     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.MapLoader;

interface

uses
  System.SysUtils, DelphiDoom.Greed.Types, DelphiDoom.Greed.Intf;

type
  /// <summary>
  ///   The map of a number is the lump that follows "map" by that number plus one (CA_GetNamedNum('map') + map + 1).
  ///   In the full game the lump has the planes; in the demos it is empty and has the name of the .LAY
  ///   file that is next to the archive (the original reads the planes from that file with the option -file)
  /// </summary>
  TGreedMapLoader = class(TInterfacedObject, IGreedMapLoader)
  strict private
    FArchive: IGreedArchive;
    FReader: IGreedMapReader;
    FFiles: IGreedExternalFiles;
  public
    /// <param name="AFiles">Where the files of the empty lumps are; nil if there is no such place</param>
    constructor Create(const AArchive: IGreedArchive; const AReader: IGreedMapReader;
      const AFiles: IGreedExternalFiles);
    function Load(AMapNumber: Integer): IGreedMap;
  end;

implementation

{ TGreedMapLoader }

constructor TGreedMapLoader.Create(const AArchive: IGreedArchive; const AReader: IGreedMapReader;
  const AFiles: IGreedExternalFiles);
begin
  inherited Create;
  if not Assigned(AArchive) then
    raise EArgumentNilException.Create('AArchive');
  if not Assigned(AReader) then
    raise EArgumentNilException.Create('AReader');
  FArchive := AArchive;
  FReader := AReader;
  FFiles := AFiles;
end;

function TGreedMapLoader.Load(AMapNumber: Integer): IGreedMap;
var
  LMarker: Integer;
  LLump: Integer;
  LName: string;
  LBytes: TBytes;
begin
  LMarker := FArchive.RequireIndexOf(GREED_LUMP_MAP);
  LLump := LMarker + AMapNumber + 1;
  if (AMapNumber < 0) or (LLump >= FArchive.LumpCount) then
    raise EGreedNotFoundException.CreateFmt(SGreedMapInvalid, [AMapNumber, FArchive.LumpCount - LMarker - 1]);
  if FArchive.GetLumpSize(LLump) >= GREED_MAP_BYTES then
    Exit(FReader.Read(FArchive.ReadLump(LLump)));
  LName := FArchive.GetLumpName(LLump);
  if (LName = '') or not Assigned(FFiles) or not FFiles.Exists(LName) then
    raise EGreedNotFoundException.CreateFmt(SGreedMapEmpty, [AMapNumber, LName]);
  LBytes := FFiles.ReadAll(LName);
  // a .LAY file is the 18 planes and nothing else; another size is another layout (the .LVL of the demo 1.016 has
  // 143360 bytes) that this reader does not know, and it would give a map of garbage
  if Length(LBytes) <> GREED_MAP_BYTES then
    raise EGreedDataException.CreateFmt(SGreedMapFileSize, [LName, Length(LBytes), GREED_MAP_BYTES]);
  Result := FReader.Read(LBytes);
end;

end.
