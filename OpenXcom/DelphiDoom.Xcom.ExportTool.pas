{******************************************************************************}
{                                                                              }
{  DelphiDoom: Xcom32 - exports a data file of the game as a PNG               }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Xcom.ExportTool;

interface

uses
  System.SysUtils, DelphiDoom.Xcom.Types, DelphiDoom.Xcom.Palette, DelphiDoom.Xcom.Map, DelphiDoom.Xcom.Intf,
  DelphiDoom.Xcom.ExportArguments;

type
  /// <summary>
  ///   The export mode of Xcom32: decodes a picture, a set of sprites or a block of the battlescape of UFO: Enemy
  ///   Unknown or Terror from the Deep and saves it as a PNG, without a window and without the game (the proof of
  ///   the data layer, first slice of the issue 176). What it says goes to the given procedure, a line at a time
  /// </summary>
  TXcomExportTool = class
  strict private
    FSay: TProc<string>;
    FExecutableFolder: string;
    function ResolveFolders(const AFolders: TArray<string>): TArray<string>;
    function LoadPalette(const AData: IXcomGameData; APaletteIndex: Integer): TXcomPalette;
    procedure WriteMap(const AMap: TXcomMap; const ARecords: TArray<TXcomRmpRecord>;
      const AResolver: IXcomRouteReader);
  public
    /// <summary>
    ///   ASay receives each line of the output; AExecutableFolder is where TFTD\ or UFO\ are looked for when the
    ///   command line has no folder and the current one is not a folder of the game
    /// </summary>
    constructor Create(const ASay: TProc<string>; const AExecutableFolder: string);
    /// <summary>The arguments of the export, a line at a time</summary>
    class procedure ShowUsage(const ASay: TProc<string>); static;
    /// <summary>Decodes what the arguments ask for and saves the PNG; a file that is missing or wrong raises</summary>
    procedure Run(const AArguments: TXcomExportArguments);
  end;

implementation

uses
  DelphiDoom.Xcom.Image, DelphiDoom.Xcom.SpriteSheet, DelphiDoom.Xcom.MapPicture, DelphiDoom.Xcom.ImageExporter,
  DelphiDoom.Xcom.BattlescapePalette, DelphiDoom.Xcom.Composition;

const
  PALETTE_FOLDER = 'GEODATA';
  GAME_FOLDERS: array[0..1] of string = ('TFTD', 'UFO');
  FIRST_BATTLESCAPE_PALETTE = 4;
  SPRITE_WIDTH = 32;
  SPRITE_HEIGHT = 40;
  SCREEN_WIDTH = 320;
  SCREEN_HEIGHT = 200;

{ TXcomExportTool }

constructor TXcomExportTool.Create(const ASay: TProc<string>; const AExecutableFolder: string);
begin
  inherited Create;
  if not Assigned(ASay) then
    raise EArgumentNilException.Create('ASay');
  FSay := ASay;
  FExecutableFolder := IncludeTrailingPathDelimiter(AExecutableFolder);
end;

class procedure TXcomExportTool.ShowUsage(const ASay: TProc<string>);
begin
  ASay('Xcom32 [-data <folder>]... [-pal <n>] [-png <file>] <what>      (exports a data file as a PNG)');
  ASay('  the export mode is the one of a command line with -pck, -dat, -scr or -map');
  ASay('  -data     a folder of the game (the one that has GEODATA\PALETTES.DAT); it can be repeated and -game is the');
  ASay('            same. Default: the current folder when it is one, otherwise TFTD\ or UFO\ next to the executable');
  ASay('  -pal      the palette of GEODATA\PALETTES.DAT (0 geoscape, 1 basescape, 2 graphs, 3 ufopaedia, 4 battlescape), default 0;');
  ASay('            4..7 are the battlescape palettes of UFOGRAPH\D0..D3.LBM when the game has them (TFTD)');
  ASay('  -png      the file to write (default xcom.png)');
  ASay('  -pck      the sprites of a .PCK with its .TAB (-tab, default the same name); -w and -h are the size of a frame (32 x 40)');
  ASay('  -dat      the frames of a .DAT of raw pictures; -w and -h are the size of a frame');
  ASay('  -scr      a full picture: .SCR, .SPK or .BDY by the extension; -w and -h default 320 x 200');
  ASay('  -map      a block of the battlescape (.MAP, with -rmp the routes of it): its cells are written, and a picture');
  ASay('            of the layer -z (default 0, the lowest) goes into the PNG');
  ASay('  -columns  frames in a row of the sheet of sprites (default 16)');
end;

function TXcomExportTool.ResolveFolders(const AFolders: TArray<string>): TArray<string>;
var
  LName: string;
begin
  if Length(AFolders) > 0 then
    Exit(AFolders);
  Result := [GetCurrentDir];
  if DirectoryExists(IncludeTrailingPathDelimiter(GetCurrentDir) + PALETTE_FOLDER) then
    Exit;
  // the same folders that the game opens without arguments
  for LName in GAME_FOLDERS do
    if DirectoryExists(FExecutableFolder + LName + PathDelim + PALETTE_FOLDER) then
    begin
      Result := [FExecutableFolder + LName];
      Exit;
    end;
end;

function TXcomExportTool.LoadPalette(const AData: IXcomGameData; APaletteIndex: Integer): TXcomPalette;
var
  LBattlescapeIndex: Integer;
begin
  LBattlescapeIndex := APaletteIndex - FIRST_BATTLESCAPE_PALETTE;
  if (LBattlescapeIndex < 0) or (LBattlescapeIndex > TXcomBattlescapePalette.COUNT - 1) then
    Result := AData.LoadPalette(APaletteIndex)
  else if not TXcomBattlescapePalette.TryLoad(AData.Files, TXcomComposition.CreateLbmReader, LBattlescapeIndex,
    Result) then
  begin
    // no UFOGRAPH\D0.LBM (UFO: Enemy Unknown): the battlescape palette of PALETTES.DAT, as Mod does
    if LBattlescapeIndex <> 0 then
      raise EXcomFileNotFoundException.CreateFmt(SXcomFileMissing, [TXcomBattlescapePalette.FileName(
        LBattlescapeIndex)]);
    Result := AData.LoadPalette(FIRST_BATTLESCAPE_PALETTE);
    Result.ApplyBattlescapeGradient;
  end;
  if Result.Count = 0 then
    raise EXcomDataException.CreateFmt(SXcomPaletteBadCount, [0, XCOM_PALETTE_COLORS]);
end;

procedure TXcomExportTool.WriteMap(const AMap: TXcomMap; const ARecords: TArray<TXcomRmpRecord>;
  const AResolver: IXcomRouteReader);
var
  LX: Integer;
  LY: Integer;
  LZ: Integer;
  LCell: TXcomMapCell;
  LNodes: TArray<TXcomRouteNode>;
  LCulled: TArray<Integer>;
  LNode: TXcomRouteNode;
begin
  FSay(Format('Map %d x %d x %d (x, y, layers); %d cells in the file', [AMap.SizeX, AMap.SizeY, AMap.SizeZ,
    Length(AMap.Cells)]));
  FSay('x   y   z   floor west north object');
  for LZ := 0 to AMap.SizeZ - 1 do
    for LY := 0 to AMap.SizeY - 1 do
      for LX := 0 to AMap.SizeX - 1 do
      begin
        LCell := AMap.CellAt(LX, LY, LZ);
        if (LCell.Floor or LCell.WestWall or LCell.NorthWall or LCell.Obj) <> 0 then
          FSay(Format('%-3d %-3d %-3d %-5d %-4d %-5d %d', [LX, LY, LZ, LCell.Floor, LCell.WestWall,
            LCell.NorthWall, LCell.Obj]));
      end;
  if Assigned(AResolver) then
  begin
    LNodes := AResolver.Resolve(ARecords, AMap.SizeX, AMap.SizeY, AMap.SizeZ, 0, 0, 0, LCulled);
    FSay(Format('%d nodes (%d outside the block)', [Length(LNodes), Length(LCulled)]));
    for LNode in LNodes do
      if LNode.IsDummy then
        FSay(Format('node %d: outside the block', [LNode.Index]))
      else
        FSay(Format('node %d: (%d, %d, %d) type %d rank %d flags %d priority %d links %d %d %d %d %d',
          [LNode.Index, LNode.X, LNode.Y, LNode.Z, LNode.NodeType, LNode.Rank, LNode.Flags, LNode.Priority,
          LNode.Links[0], LNode.Links[1], LNode.Links[2], LNode.Links[3], LNode.Links[4]]));
  end;
end;

procedure TXcomExportTool.Run(const AArguments: TXcomExportArguments);
var
  LData: IXcomGameData;
  LPalette: TXcomPalette;
  LImage: TXcomImage;
  LFrames: TArray<TXcomImage>;
  LMap: TXcomMap;
  LRoute: TArray<TXcomRmpRecord>;
  LRouteReader: IXcomRouteReader;
  LExporter: TXcomImageExporter;
  LWidth: Integer;
  LHeight: Integer;
begin
  LData := TXcomComposition.OpenGameData(ResolveFolders(AArguments.Folders));
  LPalette := LoadPalette(LData, AArguments.PaletteIndex);
  LWidth := AArguments.Width;
  LHeight := AArguments.Height;
  LExporter := TXcomComposition.CreateImageExporter;
  try
    case AArguments.Mode of
      xmPck, xmDat:
        begin
          if LWidth = 0 then
            LWidth := SPRITE_WIDTH;
          if LHeight = 0 then
            LHeight := SPRITE_HEIGHT;
          LFrames := LData.LoadImageSet(AArguments.InputFile, AArguments.TabFile, LWidth, LHeight, LPalette);
          LImage := TXcomSpriteSheet.Compose(LFrames, AArguments.Columns);
          FSay(Format('%d frames of %d x %d', [Length(LFrames), LWidth, LHeight]));
          LExporter.Save(LImage, AArguments.PngFile, True);
        end;
      xmScr:
        begin
          if LWidth = 0 then
            LWidth := SCREEN_WIDTH;
          if LHeight = 0 then
            LHeight := SCREEN_HEIGHT;
          LImage := LData.LoadImage(AArguments.InputFile, LWidth, LHeight, LPalette);
          LExporter.Save(LImage, AArguments.PngFile, False);
        end;
      xmMap:
        begin
          LMap := LData.LoadMap(AArguments.InputFile);
          LRouteReader := nil;
          LRoute := nil;
          if AArguments.RouteFile <> '' then
          begin
            LRoute := LData.LoadRoute(AArguments.RouteFile);
            LRouteReader := TXcomComposition.CreateRouteReader;
          end;
          WriteMap(LMap, LRoute, LRouteReader);
          LImage := TXcomMapPicture.Render(LMap, AArguments.Layer);
          LImage.Palette := LPalette;
          LImage.HasPalette := True;
          LExporter.Save(LImage, AArguments.PngFile, False);
        end;
    end;
  finally
    LExporter.Free;
  end;
  FSay('Saved in ' + AArguments.PngFile);
end;

end.
