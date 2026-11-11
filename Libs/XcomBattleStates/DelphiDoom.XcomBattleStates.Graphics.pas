{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom battlescape states library - the pictures of the battle     }
{  read from the files of the mod (Mod::loadBattlescapeResources)               }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBattleStates.Graphics;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.Xcom.Types, DelphiDoom.Xcom.Palette,
  DelphiDoom.XcomSurface.Surface, DelphiDoom.XcomSurface.SurfaceSet, DelphiDoom.XcomEngine.Types,
  DelphiDoom.XcomEngine.Rules.Intf, DelphiDoom.XcomMod.ModFiles.Intf, DelphiDoom.XcomBattlescape.Sprites.Intf,
  DelphiDoom.XcomBattleStates.Graphics.Intf;

type
  /// <summary>
  ///   IXcomBattleGraphics on the files of the mod. The PCK sets come from an IXcomBattleSprites (the one of the
  ///   drawing of the map, with the fix of the colors of TFTD) and are completed with the extra sprites of the rules;
  ///   the DAT sets (SPICONS.DAT, MEDIBITS.DAT, DETBLOB.DAT), the screens of UFOGRAPH (SCR, SPK, BDY) and the
  ///   palettes of the depths (D0..D3.LBM of TFTD) are read here. Owns what it reads
  /// </summary>
  TXcomBattleGraphics = class(TInterfacedObject, IXcomBattleGraphics, IXcomBattleSprites)
  strict private
    FFiles: IXcomModFiles;
    FRules: IXcomGameRules;
    FPckSprites: IXcomBattleSprites;
    FSets: TDictionary<string, TXcomSurfaceSet>;
    FOwnedSets: TObjectList<TXcomSurfaceSet>;
    FSurfaces: TObjectDictionary<string, TXcomSurface>;
    FPalettes: array[0..3] of TXcomPalette;
    FHasPalette: array[0..3] of Boolean;
    FPalettesRead: Boolean;
    FTransparencies: array[0..3] of TBytes;
    FVoxelData: TArray<Word>;
    FUfograph: TArray<string>;
    FUfographRead: Boolean;
    FStatePalette: TArray<TXcomColor>;
    function InUfograph(const AName: string): Boolean;
    function LoadDatSet(const AName: string; AWidth, AHeight: Integer): TXcomSurfaceSet;
    function LoadScreen(const AName: string): TXcomSurface;
    procedure ReadPalettes;
  public
    /// <param name="AFiles">The files of the mod (UFOGRAPH, UNITS, TERRAIN, GEODATA)</param>
    /// <param name="ARules">The rules, for the extra sprites and the tints of the transparency tables</param>
    /// <param name="APckSprites">The PCK sets of the game</param>
    /// <param name="ABasePalette">PAL_BATTLESCAPE of a game without UFOGRAPH\D0.LBM (UFO): 256 colors, copied</param>
    constructor Create(const AFiles: IXcomModFiles; const ARules: IXcomGameRules;
      const APckSprites: IXcomBattleSprites; ABasePalette: PXcomColor);
    destructor Destroy; override;
    function Sprites: IXcomBattleSprites;
    function SurfaceSet(const AName: string): TXcomSurfaceSet;
    function TerrainFrame(const ADataSetName: string; AIndex: Integer): TXcomSurface;
    function Surface(const AName: string): TXcomSurface;
    function Palette(ADepth: Integer): PXcomColor;
    function Transparencies(ADepth: Integer): TBytes;
    procedure SetPalette(AColors: PXcomColor);
    function VoxelData: TArray<Word>;
  end;

implementation

uses
  DelphiDoom.Xcom.Image, DelphiDoom.Xcom.Intf, DelphiDoom.Xcom.Factory, DelphiDoom.Xcom.BattlescapePalette,
  DelphiDoom.XcomBattlescape.TransparencyTable;

const
  SCREEN_WIDTH = 320;
  SCREEN_HEIGHT = 200;
  /// the screens that Mod loads with loadSpk although they are not named .SPK
  SPK_SCREENS: array[0..6] of string = ('TAC01.SCR', 'DETBORD.PCK', 'DETBORD2.PCK', 'ICONS.PCK', 'MEDIBORD.PCK',
    'SCANBORD.PCK', 'UNIBORD.PCK');

constructor TXcomBattleGraphics.Create(const AFiles: IXcomModFiles; const ARules: IXcomGameRules;
  const APckSprites: IXcomBattleSprites; ABasePalette: PXcomColor);
begin
  inherited Create;
  FFiles := AFiles;
  FRules := ARules;
  FPckSprites := APckSprites;
  FSets := TDictionary<string, TXcomSurfaceSet>.Create;
  FOwnedSets := TObjectList<TXcomSurfaceSet>.Create(True);
  FSurfaces := TObjectDictionary<string, TXcomSurface>.Create([doOwnsValues]);
  if Assigned(ABasePalette) then
  begin
    FPalettes[0] := TXcomPalette.Create(XCOM_PALETTE_COLORS);
    Move(ABasePalette^, FPalettes[0].Colors[0], XCOM_PALETTE_COLORS * SizeOf(TXcomColor));
    FHasPalette[0] := True;
  end;
end;

destructor TXcomBattleGraphics.Destroy;
begin
  FSurfaces.Free;
  FOwnedSets.Free;
  FSets.Free;
  inherited Destroy;
end;

function TXcomBattleGraphics.Sprites: IXcomBattleSprites;
begin
  Result := Self;
end;

function TXcomBattleGraphics.InUfograph(const AName: string): Boolean;
var
  LName: string;
begin
  if not FUfographRead then
  begin
    FUfograph := FFiles.FolderContents('UFOGRAPH');
    FUfographRead := True;
  end;
  Result := False;
  for LName in FUfograph do
    if SameText(LName, AName) then
      Exit(True);
end;

function TXcomBattleGraphics.LoadDatSet(const AName: string; AWidth, AHeight: Integer): TXcomSurfaceSet;
var
  LImages: TArray<TXcomImage>;
  LIndex: Integer;
begin
  LImages := TXcomFactory.CreateDatDecoder.Decode(FFiles.LoadBytes('UFOGRAPH/' + AName), AWidth, AHeight);
  Result := TXcomSurfaceSet.Create(AWidth, AHeight);
  for LIndex := 0 to High(LImages) do
    Result.AddImage(LIndex, LImages[LIndex]);
end;

function TXcomBattleGraphics.SurfaceSet(const AName: string): TXcomSurfaceSet;
var
  LKey: string;
  LExtra: TXcomSurfaceSet;
  LIndex: Integer;
  LFrame: TXcomSurface;
  LSource: TXcomSurface;
begin
  LKey := UpperCase(AName);
  if FSets.TryGetValue(LKey, Result) then
    Exit;
  Result := nil;
  if LKey = 'SPICONS.DAT' then
    Result := LoadDatSet(LKey, 32, 24)
  else if LKey = 'MEDIBITS.DAT' then
    Result := LoadDatSet(LKey, 52, 58)
  else if LKey = 'DETBLOB.DAT' then
    Result := LoadDatSet(LKey, 16, 16);
  if Assigned(Result) then
    FOwnedSets.Add(Result)
  else
    Result := FPckSprites.SurfaceSet(AName);
  // the extra sprites of the rules: a set of their own (Pathfinding, Projectiles) or frames added to a set of the game
  LExtra := nil;
  if Assigned(FRules) then
    LExtra := FRules.GetSurfaceSet(AName);
  if not Assigned(Result) then
    Result := LExtra
  else if Assigned(LExtra) then
    for LIndex in LExtra.Indexes do
    begin
      LSource := LExtra.GetFrame(LIndex);
      LFrame := Result.GetFrame(LIndex);
      if (not Assigned(LFrame)) or (LFrame.Width <> LSource.Width) or (LFrame.Height <> LSource.Height) then
        LFrame := Result.AddFrame(LIndex);
      if (LFrame.Width = LSource.Width) and (LFrame.Height = LSource.Height) then
        Move(LSource.PixelPointer(0, 0)^, LFrame.PixelPointer(0, 0)^, LSource.Width * LSource.Height);
    end;
  FSets.Add(LKey, Result);
end;

function TXcomBattleGraphics.TerrainFrame(const ADataSetName: string; AIndex: Integer): TXcomSurface;
begin
  Result := FPckSprites.TerrainFrame(ADataSetName, AIndex);
end;

// Mod::modResources: the battlescape info screen gets its rows nine pixels apart
procedure ModifyUnitInfoBackground(ASurface: TXcomSurface);
var
  LX, LY: Integer;
begin
  // erase the old lines
  LY := 39;
  while LY < 199 do
  begin
    for LX := 0 to 168 do
      ASurface.SetPixel(LX, LY, ASurface.GetPixel(LX, 30));
    Inc(LY, 10);
  end;
  // draw the new lines, with the bottom row of pixels as a basis
  LY := 190;
  while LY > 37 do
  begin
    for LX := 0 to 168 do
      ASurface.SetPixel(LX, LY, ASurface.GetPixel(LX, 199));
    Dec(LY, 9);
  end;
  // move the top of the graph down by eight pixels to erase the row that is not needed
  for LY := 37 downto 30 do
    for LX := 0 to 319 do
    begin
      ASurface.SetPixel(LX, LY, ASurface.GetPixel(LX, LY - 8));
      ASurface.SetPixel(LX, LY - 8, 0);
    end;
end;

function TXcomBattleGraphics.LoadScreen(const AName: string): TXcomSurface;
var
  LBase: string;
  LBody: string;
  LDecoder: IXcomImageDecoder;
  LFile: string;
  LImage: TXcomImage;
  LIndex: Integer;
  LIsSpk: Boolean;
begin
  Result := nil;
  LDecoder := nil;
  LBase := ChangeFileExt(AName, '');
  LBody := LBase + '.BDY';
  LFile := AName;
  // a .BDY of UFOGRAPH replaces the screen of the same name: MAN_* as .SPK, TAC01 as .SCR, the others as .PCK
  if InUfograph(LBody) and ((SameText(Copy(LBase, 1, 3), 'MAN') and SameText(ExtractFileExt(AName), '.SPK')) or
    SameText(AName, 'TAC01.SCR') or ((not SameText(Copy(LBase, 1, 3), 'MAN')) and (not SameText(LBase, 'TAC01')) and
    SameText(ExtractFileExt(AName), '.PCK'))) then
  begin
    LDecoder := TXcomFactory.CreateBdyDecoder;
    LFile := LBody;
  end
  else if InUfograph(AName) then
  begin
    LIsSpk := SameText(ExtractFileExt(AName), '.SPK');
    for LIndex := 0 to High(SPK_SCREENS) do
      if SameText(AName, SPK_SCREENS[LIndex]) then
        LIsSpk := True;
    if LIsSpk then
      LDecoder := TXcomFactory.CreateSpkDecoder
    else if SameText(AName, 'TAC00.SCR') then
      LDecoder := TXcomFactory.CreateScrDecoder;
  end;
  if not Assigned(LDecoder) then
    Exit;
  LImage := LDecoder.Decode(FFiles.LoadBytes('UFOGRAPH/' + LFile), SCREEN_WIDTH, SCREEN_HEIGHT);
  Result := TXcomSurface.Create(LImage.Width, LImage.Height);
  Move(LImage.Pixels[0], Result.PixelPointer(0, 0)^, LImage.Width * LImage.Height);
  if SameText(AName, 'UNIBORD.PCK') then
    ModifyUnitInfoBackground(Result);
end;

function TXcomBattleGraphics.Surface(const AName: string): TXcomSurface;
var
  LKey: string;
begin
  LKey := UpperCase(AName);
  if FSurfaces.TryGetValue(LKey, Result) then
    Exit;
  Result := LoadScreen(LKey);
  if Assigned(Result) and (Length(FStatePalette) > 0) then
    Result.SetColors(FStatePalette);
  // a name that the game does not have is remembered too (nil), not to look for the file again
  FSurfaces.Add(LKey, Result);
end;

procedure TXcomBattleGraphics.ReadPalettes;
var
  LIndex: Integer;
  LName: string;
  LPicture: TXcomLbmPicture;
begin
  if FPalettesRead then
    Exit;
  FPalettesRead := True;
  for LIndex := 0 to High(FPalettes) do
  begin
    LName := Format('D%d.LBM', [LIndex]);
    if InUfograph(LName) then
    begin
      LPicture := TXcomFactory.CreateLbmReader.Read(FFiles.LoadBytes('UFOGRAPH/' + LName));
      FPalettes[LIndex] := TXcomBattlescapePalette.FromLbm(LPicture.Image.Palette, LIndex);
      FHasPalette[LIndex] := True;
    end;
    // Mod::createTransparencyLUT: one group of tables for every palette read from an LBM
    if FHasPalette[LIndex] and Assigned(FRules) and Assigned(FRules.Ruleset) and InUfograph(LName) then
      FTransparencies[LIndex] := TXcomTransparencyTable.Build(FPalettes[LIndex], FRules.Ruleset.Transparencies);
  end;
end;

function TXcomBattleGraphics.Palette(ADepth: Integer): PXcomColor;
begin
  ReadPalettes;
  if (ADepth < 0) or (ADepth > High(FPalettes)) or (not FHasPalette[ADepth]) then
    raise EXcomEngineException.CreateFmt('The battlescape has no palette for the depth %d', [ADepth]);
  Result := @FPalettes[ADepth].Colors[0];
end;

function TXcomBattleGraphics.Transparencies(ADepth: Integer): TBytes;
begin
  ReadPalettes;
  Result := nil;
  if (ADepth >= 0) and (ADepth <= High(FTransparencies)) then
    Result := FTransparencies[ADepth];
end;

procedure TXcomBattleGraphics.SetPalette(AColors: PXcomColor);
var
  LSurface: TXcomSurface;
begin
  SetLength(FStatePalette, XCOM_PALETTE_COLORS);
  Move(AColors^, FStatePalette[0], XCOM_PALETTE_COLORS * SizeOf(TXcomColor));
  for LSurface in FSurfaces.Values do
    if Assigned(LSurface) then
      LSurface.SetColors(FStatePalette);
end;

function TXcomBattleGraphics.VoxelData: TArray<Word>;
var
  LName: string;
  LInTerrain: Boolean;
begin
  if Length(FVoxelData) = 0 then
  begin
    // TFTD uses the loftemps of the terrain folder; its copy in GEODATA is the one of UFO, short by two entries
    LInTerrain := False;
    for LName in FFiles.FolderContents('TERRAIN') do
      if SameText(LName, 'LOFTEMPS.DAT') then
        LInTerrain := True;
    if LInTerrain then
      FVoxelData := TXcomFactory.CreateWordTableReader.Read(FFiles.LoadBytes('TERRAIN/LOFTEMPS.DAT'))
    else
      FVoxelData := TXcomFactory.CreateWordTableReader.Read(FFiles.LoadBytes('GEODATA/LOFTEMPS.DAT'));
  end;
  Result := FVoxelData;
end;

end.
