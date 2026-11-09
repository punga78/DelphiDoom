{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom formats library - the data of an installed game             }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Xcom.GameData;

interface

uses
  System.SysUtils, DelphiDoom.Xcom.Types, DelphiDoom.Xcom.Palette, DelphiDoom.Xcom.Image,
  DelphiDoom.Xcom.Map, DelphiDoom.Xcom.Intf;

type
  /// <summary>
  ///   The files of UFO or TFTD by name: the file comes from the data files, the reader that fits its format
  ///   decodes it. The formats of the pictures are chosen from the extension of the name
  /// </summary>
  TXcomGameData = class(TInterfacedObject, IXcomGameData)
  strict private
    FFiles: IXcomDataFiles;
    FPalettes: IXcomPaletteReader;
    FScr: IXcomImageDecoder;
    FSpk: IXcomImageDecoder;
    FBdy: IXcomImageDecoder;
    FPck: IXcomPckDecoder;
    FDat: IXcomDatDecoder;
    FMaps: IXcomMapReader;
    FRoutes: IXcomRouteReader;
    FTerrain: IXcomMcdReader;
    function GetFiles: IXcomDataFiles;
    class function WithPalette(const AImage: TXcomImage; const APalette: TXcomPalette): TXcomImage; static;
  public
    constructor Create(const AFiles: IXcomDataFiles; const APalettes: IXcomPaletteReader;
      const AScr, ASpk, ABdy: IXcomImageDecoder; const APck: IXcomPckDecoder; const ADat: IXcomDatDecoder;
      const AMaps: IXcomMapReader; const ARoutes: IXcomRouteReader; const ATerrain: IXcomMcdReader);
    function LoadPalette(AIndex: Integer): TXcomPalette;
    function LoadImage(const AName: string; AWidth, AHeight: Integer; const APalette: TXcomPalette): TXcomImage;
    function LoadImageSet(const AName, ATabName: string; AWidth, AHeight: Integer;
      const APalette: TXcomPalette): TArray<TXcomImage>;
    function LoadMap(const AName: string): TXcomMap;
    function LoadRoute(const AName: string): TArray<TXcomRmpRecord>;
    function LoadTerrain(const AName: string): TArray<TXcomMcdRecord>;
  end;

implementation

uses
  System.IOUtils;

const
  PALETTES_FILE = 'GEODATA/PALETTES.DAT';

{ TXcomGameData }

constructor TXcomGameData.Create(const AFiles: IXcomDataFiles; const APalettes: IXcomPaletteReader;
  const AScr, ASpk, ABdy: IXcomImageDecoder; const APck: IXcomPckDecoder; const ADat: IXcomDatDecoder;
  const AMaps: IXcomMapReader; const ARoutes: IXcomRouteReader; const ATerrain: IXcomMcdReader);
begin
  inherited Create;
  if not (Assigned(AFiles) and Assigned(APalettes) and Assigned(AScr) and Assigned(ASpk) and Assigned(ABdy) and
    Assigned(APck) and Assigned(ADat) and Assigned(AMaps) and Assigned(ARoutes) and Assigned(ATerrain)) then
    raise EArgumentNilException.Create('a dependency of TXcomGameData');
  FFiles := AFiles;
  FPalettes := APalettes;
  FScr := AScr;
  FSpk := ASpk;
  FBdy := ABdy;
  FPck := APck;
  FDat := ADat;
  FMaps := AMaps;
  FRoutes := ARoutes;
  FTerrain := ATerrain;
end;

function TXcomGameData.GetFiles: IXcomDataFiles;
begin
  Result := FFiles;
end;

class function TXcomGameData.WithPalette(const AImage: TXcomImage; const APalette: TXcomPalette): TXcomImage;
begin
  Result := AImage;
  Result.Palette := APalette;
  Result.HasPalette := True;
end;

function TXcomGameData.LoadPalette(AIndex: Integer): TXcomPalette;
begin
  if AIndex < 0 then
    raise EXcomException.CreateFmt(SXcomOffsetInvalid, [AIndex]);
  Result := FPalettes.Read(FFiles.ReadAll(PALETTES_FILE), XCOM_PALETTE_COLORS, FPalettes.OffsetOf(AIndex));
end;

function TXcomGameData.LoadImage(const AName: string; AWidth, AHeight: Integer;
  const APalette: TXcomPalette): TXcomImage;
var
  LExtension: string;
  LBytes: TBytes;
begin
  LExtension := TPath.GetExtension(AName).ToUpperInvariant;
  LBytes := FFiles.ReadAll(AName);
  if LExtension = '.SPK' then
    Result := FSpk.Decode(LBytes, AWidth, AHeight)
  else if LExtension = '.BDY' then
    Result := FBdy.Decode(LBytes, AWidth, AHeight)
  else
    Result := FScr.Decode(LBytes, AWidth, AHeight);
  Result := WithPalette(Result, APalette);
end;

function TXcomGameData.LoadImageSet(const AName, ATabName: string; AWidth, AHeight: Integer;
  const APalette: TXcomPalette): TArray<TXcomImage>;
var
  LTabName: string;
  LTab: TBytes;
  LIndex: Integer;
begin
  if TPath.GetExtension(AName).ToUpperInvariant = '.DAT' then
    Result := FDat.Decode(FFiles.ReadAll(AName), AWidth, AHeight)
  else
  begin
    LTabName := ATabName;
    if LTabName = '' then
      LTabName := TPath.ChangeExtension(AName, '.TAB');
    // a .TAB that was named must be there; the one that is only guessed from the .PCK may not be
    if (ATabName <> '') or FFiles.Exists(LTabName) then
      LTab := FFiles.ReadAll(LTabName)
    else
      LTab := nil;
    Result := FPck.Decode(FFiles.ReadAll(AName), LTab, AWidth, AHeight);
  end;
  for LIndex := 0 to High(Result) do
    Result[LIndex] := WithPalette(Result[LIndex], APalette);
end;

function TXcomGameData.LoadMap(const AName: string): TXcomMap;
begin
  Result := FMaps.Read(FFiles.ReadAll(AName));
end;

function TXcomGameData.LoadRoute(const AName: string): TArray<TXcomRmpRecord>;
begin
  Result := FRoutes.Read(FFiles.ReadAll(AName));
end;

function TXcomGameData.LoadTerrain(const AName: string): TArray<TXcomMcdRecord>;
begin
  Result := FTerrain.Read(FFiles.ReadAll(AName));
end;

end.
