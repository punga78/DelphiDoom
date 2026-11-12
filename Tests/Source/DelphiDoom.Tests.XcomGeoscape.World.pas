{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the xcom geoscape library - the real data of TFTD and   }
{  the ruleset that the strategy screens use (skipped when the data is missing) }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (the library itself is derived from OpenXcom, GPL v3 or later)               }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomGeoscape.World;

interface

uses
  DelphiDoom.Tests.Shared.Files,
  System.SysUtils, DelphiDoom.XcomEngine.FileMap, DelphiDoom.XcomEngine.GameRules, DelphiDoom.XcomEngine.Intf,
  DelphiDoom.Xcom.Intf, DelphiDoom.Xcom.Palette;

type
  /// <summary>
  ///   The data of X-COM: Terror from the Deep that the repository does not have (Reference\_dati\xcom_tftd), found by
  ///   climbing from the program, and the game rules built on it
  /// </summary>
  TXcomGeoWorld = class
  strict private
    FRoot: string;
    FFiles: IXcomFileSystem;
    FMap: TXcomFileMap;
    FRules: TXcomGameRules;
    FGameData: IXcomGameData;
  public
    /// <summary>The data is there; otherwise Rules is nil and the tests do nothing</summary>
    constructor Create;
    destructor Destroy; override;
    function HasData: Boolean;
    /// <summary>The palette of the geoscape (PAL_GEOSCAPE: the first of PALETTES.DAT)</summary>
    function GeoscapePalette: TXcomPalette;
    /// <summary>A palette of PALETTES.DAT (0 geoscape, 1 basescape)</summary>
    function GamePalette(AIndex: Integer): TXcomPalette;
    property Rules: TXcomGameRules read FRules;
    property Map: TXcomFileMap read FMap;
    property Root: string read FRoot;
  end;

implementation

uses
  System.IOUtils, DelphiDoom.Yaml.Factory, DelphiDoom.Png.Provider, DelphiDoom.Xcom.Factory,
  DelphiDoom.XcomEngine.DiskFileSystem;

constructor TXcomGeoWorld.Create;
var
  LData, LGame, LMod: string;
begin
  inherited Create;
  FRoot := TTestFiles.FindFolderUp('Reference\_dati\xcom_tftd');
  if FRoot = '' then
    Exit;
  LData := TPath.Combine(FRoot, 'openxcom');
  LGame := TPath.Combine(FRoot, 'TFTD');
  LMod := TPath.Combine(LData, 'standard\xcom2');
  if not (TDirectory.Exists(LMod) and TDirectory.Exists(LGame)) then
    Exit;
  FFiles := TXcomDiskFileSystem.Create;
  FMap := TXcomFileMap.Create(FFiles);
  FMap.AddRoot(TPath.Combine(LData, 'common'));
  FMap.AddRoot(LGame);
  FMap.AddRoot(LMod);
  FGameData := TXcomFactory.CreateGameData(TXcomFactory.CreateFolderFiles([LGame]));
  FRules := TXcomGameRules.Create(FMap, FGameData, FFiles,
    TYamlFactory.CreateDiskParser, TPngProvider.Client, LMod, 'xcom2');
  FRules.Load;
end;

destructor TXcomGeoWorld.Destroy;
begin
  FRules.Free;
  FMap.Free;
  inherited Destroy;
end;

function TXcomGeoWorld.GamePalette(AIndex: Integer): TXcomPalette;
begin
  Result := FGameData.LoadPalette(AIndex);
end;

function TXcomGeoWorld.GeoscapePalette: TXcomPalette;
const
  BACK_POSITION = 224;
  BACK_BLOCK = 4;
var
  LBack: TXcomPalette;
  LIndex: Integer;
begin
  Result := FGameData.LoadPalette(0);
  // State::setInterface: the element "palette" of the interface "geoscape" (color 4) gives the block of BACKPALS.DAT that
  // takes the colors 224..239
  LBack := TXcomFactory.CreatePaletteReader.Read(FGameData.Files.ReadAll('GEODATA/BACKPALS.DAT'), 128, 0);
  for LIndex := 0 to 15 do
    Result.Colors[BACK_POSITION + LIndex] := LBack.Colors[BACK_BLOCK * 16 + LIndex];
end;

function TXcomGeoWorld.HasData: Boolean;
begin
  Result := Assigned(FRules);
end;

end.
