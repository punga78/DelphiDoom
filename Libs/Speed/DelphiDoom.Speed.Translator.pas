{******************************************************************************}
{                                                                              }
{  DelphiDoom: speed library - TSpeedTranslator                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{  Copyright (C) 1995 by Noriaworks (Speed Haste)                              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of TSpeedToWADConverter (speed_xlat_wad.pas)                           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Speed.Translator;

interface

uses
  System.SysUtils,
  DelphiDoom.Logging.Intf, DelphiDoom.Palette.Intf, DelphiDoom.GameData.Intf,
  DelphiDoom.Speed.Types, DelphiDoom.Speed.Intf;

type
  /// <summary>
  ///   Turns the container of the game into the lumps of a WAD in the format of Doom, in the order of
  ///   the old translator: PLAYPAL and COLORMAP, the wall textures (with PNAMES and TEXTURE1),
  ///   the flats, the floors of the circuits, the levels E1M1 to E1M8 (with MAPDATA), the pictures
  ///   (.PIX and .IS2), the fonts, the sprites, the music, the sounds (with SNDINFO), the original
  ///   palette and tiles and the lumps of text SPEEDINF (which lump is which file of the container)
  ///   and FLATSIZE (the size of the flats). What is missing from the container is left out, as the
  ///   old code did; what is not good is left out with a warning
  /// </summary>
  TSpeedTranslator = class(TInterfacedObject, ISpeedTranslator)
  strict private
    FLog: ILog;
    FMatcher: IColorMatcher;
    FPatches: IGamePatchBuilder;
    FPalettes: ISpeedPaletteBuilder;
    FBitmaps: ISpeedBitmapDecoder;
    FCircuits: ISpeedCircuitReader;
    FLevels: ISpeedLevelBuilder;
    FFonts: ISpeedFontBuilder;
    FMapBitmaps: ISpeedMapBitmapBuilder;
  public
    /// <param name="APatches">Makes the patches with the options of Speed</param>
    /// <exception cref="EArgumentNilException">When a dependency is nil</exception>
    constructor Create(const ALog: ILog; const AMatcher: IColorMatcher; const APatches: IGamePatchBuilder;
      const APalettes: ISpeedPaletteBuilder; const ABitmaps: ISpeedBitmapDecoder;
      const ACircuits: ISpeedCircuitReader; const ALevels: ISpeedLevelBuilder;
      const AFonts: ISpeedFontBuilder; const AMapBitmaps: ISpeedMapBitmapBuilder);
    function Translate(const AContainer: ISpeedContainer;
      const AWad: IGameWadComposer): TArray<TSpeedPakEntry>;
  end;

implementation

uses
  System.Generics.Collections,
  DelphiDoom.GameData.Types, DelphiDoom.Speed.Names, DelphiDoom.Speed.RawSound;

const
  CRLF = #13#10;
  NAME_PALETTE = 'GRAFS.PAL';
  NAME_TILES = 'GRAFS.DAT';
  NAME_CIRCUITS = 'CIRCUITS.LST';
  EXTENSION_IS2 = '.IS2';
  EXTENSION_PIX = '.PIX';
  EXTENSION_RAW = '.RAW';
  EXTENSION_I3D = '.I3D';
  SKY_COUNT = 7;
  /// <summary>The flats are shown 2 x 64 units wide: the size that FLATSIZE says</summary>
  FLAT_UNITS = SPEED_LEVEL_SCALE * SPEED_TILE_SIZE;
  CHAMPIONSHIP_TILE = 'FLAT';

type
  /// <summary>What one translation keeps while it runs</summary>
  TSpeedTranslation = class
  strict private
    FLog: ILog;
    FMatcher: IColorMatcher;
    FPatches: IGamePatchBuilder;
    FPalettes: ISpeedPaletteBuilder;
    FBitmaps: ISpeedBitmapDecoder;
    FCircuits: ISpeedCircuitReader;
    FLevels: ISpeedLevelBuilder;
    FFonts: ISpeedFontBuilder;
    FMapBitmaps: ISpeedMapBitmapBuilder;
    FContainer: ISpeedContainer;
    FWad: IGameWadComposer;
    FColors: TArray<Cardinal>;
    FSources: TList<string>;
    FFlatSizes: TList<string>;
    FExtraFlats: array[0..SPEED_MAP_COUNT - 1] of string;
    FPakEntries: TList<TSpeedPakEntry>;
    function Texts(const ALines: TList<string>): string;
    function MakeIs2Patch(const AName: string; ASolid, ARightCrop: Boolean; out AWidth, AHeight: Integer;
      out APatch: TBytes): Boolean;
    function MakeIs2Lump(const ASource, ALumpName: string; ASolid, ARightCrop: Boolean;
      out AWidth, AHeight: Integer): Boolean;
    procedure MakePalette;
    procedure MakeTextures;
    procedure MakeFlats;
    procedure MakeMapFlats;
    procedure MakeLevels;
    procedure MakePictures;
    procedure MakePixPicture(const ASource, ALumpName: string; ASolid: Boolean);
    procedure MakeSprites;
    procedure MakeMusic;
    procedure MakeSounds;
    procedure MakeModelEntries;
    procedure MakeOriginalData;
    procedure WriteInfoLumps;
    function CollectNames(const AExtension: string; AFilter: TFunc<string, Boolean>): TArray<string>;
  public
    constructor Create(const ALog: ILog; const AMatcher: IColorMatcher;
      const APatches: IGamePatchBuilder; const APalettes: ISpeedPaletteBuilder;
      const ABitmaps: ISpeedBitmapDecoder; const ACircuits: ISpeedCircuitReader;
      const ALevels: ISpeedLevelBuilder; const AFonts: ISpeedFontBuilder;
      const AMapBitmaps: ISpeedMapBitmapBuilder);
    destructor Destroy; override;
    function Run(const AContainer: ISpeedContainer; const AWad: IGameWadComposer): TArray<TSpeedPakEntry>;
  end;

  TSpriteName = record
    Source: string;
    Sprite: string;
  end;

const
  SPRITE_NAMES: array[0..45] of TSpriteName = (
    (Source: 'XPR020.IS2'; Sprite: 'S020A0'), (Source: 'XPR021.IS2'; Sprite: 'S021A0'),
    (Source: 'XPR022.IS2'; Sprite: 'S022A0'), (Source: 'XPR023.IS2'; Sprite: 'S023A0'),
    (Source: 'XPR024.IS2'; Sprite: 'S024A0'), (Source: 'XPR025.IS2'; Sprite: 'S025A0'),
    (Source: 'XPR026.IS2'; Sprite: 'S026A0'), (Source: 'XPR027.IS2'; Sprite: 'S027A0'),
    (Source: 'XPR028.IS2'; Sprite: 'S028A0'), (Source: 'XPR029.IS2'; Sprite: 'S029A0'),
    (Source: 'XPR02A.IS2'; Sprite: 'S02AA0'), (Source: 'XPR02B.IS2'; Sprite: 'S02BA0'),
    (Source: 'XPR02C.IS2'; Sprite: 'S02CA0'), (Source: 'XPR02D.IS2'; Sprite: 'S02DA0'),
    (Source: 'XPR02E.IS2'; Sprite: 'S02EA0'), (Source: 'XPR02F.IS2'; Sprite: 'S02FA0'),
    (Source: 'GND001AA.IS2'; Sprite: 'GND0A0'), (Source: 'GND002AA.IS2'; Sprite: 'GND0B0'),
    (Source: 'GND003AA.IS2'; Sprite: 'GND0C0'), (Source: 'GND004AA.IS2'; Sprite: 'GND0D0'),
    (Source: 'GND005AA.IS2'; Sprite: 'GND0E0'), (Source: 'GND006AA.IS2'; Sprite: 'GND0F0'),
    (Source: 'GND101AA.IS2'; Sprite: 'GND1A0'), (Source: 'GND102AA.IS2'; Sprite: 'GND1B0'),
    (Source: 'GND103AA.IS2'; Sprite: 'GND1C0'), (Source: 'GND104AA.IS2'; Sprite: 'GND1D0'),
    (Source: 'GND105AA.IS2'; Sprite: 'GND1E0'), (Source: 'GND106AA.IS2'; Sprite: 'GND1F0'),
    (Source: 'GND201AA.IS2'; Sprite: 'GND2A0'), (Source: 'GND202AA.IS2'; Sprite: 'GND2B0'),
    (Source: 'GND203AA.IS2'; Sprite: 'GND2C0'), (Source: 'GND204AA.IS2'; Sprite: 'GND2D0'),
    (Source: 'GND205AA.IS2'; Sprite: 'GND2E0'), (Source: 'GND206AA.IS2'; Sprite: 'GND2F0'),
    (Source: 'SMOK01AA.IS2'; Sprite: 'SMOKA0'), (Source: 'SMOK02AA.IS2'; Sprite: 'SMOKB0'),
    (Source: 'SMOK03AA.IS2'; Sprite: 'SMOKC0'), (Source: 'SMOK04AA.IS2'; Sprite: 'SMOKD0'),
    (Source: 'SMOK05AA.IS2'; Sprite: 'SMOKE0'), (Source: 'SMOK06AA.IS2'; Sprite: 'SMOKF0'),
    (Source: 'SPRK01AA.IS2'; Sprite: 'SPRKA0'), (Source: 'SPRK02AA.IS2'; Sprite: 'SPRKB0'),
    (Source: 'SPRK03AA.IS2'; Sprite: 'SPRKC0'), (Source: 'SPRK04AA.IS2'; Sprite: 'SPRKD0'),
    (Source: 'SPRK05AA.IS2'; Sprite: 'SPRKE0'), (Source: 'SPRK06AA.IS2'; Sprite: 'SPRKF0'));

  /// <summary>The pictures (.PIX) that have holes, because they are drawn over something</summary>
  TRANSPARENT_PICTURES: array[0..11] of string = (
    'MSCBAR.PIX', 'MSFBAR.PIX', 'SALP0.PIX', 'SALP1.PIX', 'MOUNT0.PIX', 'MOUNT1.PIX', 'MOUNT2.PIX',
    'MOUNT3.PIX', 'MOUNT4.PIX', 'MOUNT5.PIX', 'MOUNT6.PIX', 'MOUNT7.PIX');

  LEVEL_NAMES: array[0..SPEED_MAP_COUNT - 1] of string = (
    'E1M1', 'E1M2', 'E1M3', 'E1M4', 'E1M5', 'E1M6', 'E1M7', 'E1M8');

{ TSpeedTranslation }

constructor TSpeedTranslation.Create(const ALog: ILog; const AMatcher: IColorMatcher; const APatches: IGamePatchBuilder; const APalettes: ISpeedPaletteBuilder;
  const ABitmaps: ISpeedBitmapDecoder; const ACircuits: ISpeedCircuitReader;
  const ALevels: ISpeedLevelBuilder; const AFonts: ISpeedFontBuilder;
  const AMapBitmaps: ISpeedMapBitmapBuilder);
begin
  inherited Create;
  FLog := ALog;
  FMatcher := AMatcher;
  FPatches := APatches;
  FPalettes := APalettes;
  FBitmaps := ABitmaps;
  FCircuits := ACircuits;
  FLevels := ALevels;
  FFonts := AFonts;
  FMapBitmaps := AMapBitmaps;
  FSources := TList<string>.Create;
  FFlatSizes := TList<string>.Create;
  FPakEntries := TList<TSpeedPakEntry>.Create;
  // without the palette of the game everything is matched to black
  SetLength(FColors, 256);
end;

destructor TSpeedTranslation.Destroy;
begin
  FPakEntries.Free;
  FFlatSizes.Free;
  FSources.Free;
  inherited Destroy;
end;

function TSpeedTranslation.Texts(const ALines: TList<string>): string;
var
  LLine: string;
begin
  Result := '';
  for LLine in ALines do
    Result := Result + LLine + CRLF;
end;

function TSpeedTranslation.CollectNames(const AExtension: string; AFilter: TFunc<string, Boolean>): TArray<string>;
var
  LIndex: Integer;
  LName: string;
  LList: TList<string>;
begin
  LList := TList<string>.Create;
  try
    for LIndex := 0 to FContainer.Count - 1 do
    begin
      LName := FContainer.Entries[LIndex].Name;
      if TSpeedNames.EndsWith(LName, AExtension) and ((not Assigned(AFilter)) or AFilter(LName)) then
        LList.Add(LName);
    end;
    Result := LList.ToArray;
  finally
    LList.Free;
  end;
end;

function TSpeedTranslation.MakeIs2Patch(const AName: string; ASolid, ARightCrop: Boolean;
  out AWidth, AHeight: Integer; out APatch: TBytes): Boolean;
var
  LData: TBytes;
  LBitmap: TSpeedBitmap;
  LIndex: Integer;
begin
  AWidth := 0;
  AHeight := 0;
  APatch := nil;
  Result := False;
  LIndex := FContainer.IndexOf(AName);
  if LIndex < 0 then
    Exit;
  LData := FContainer.Read(LIndex);
  // a picture says how long it is, and the directory may say less
  if (Length(LData) >= SizeOf(TSpeedIs2Header)) and (PCardinal(@LData[0])^ = SPEED_IS2_MAGIC) and
    (Length(LData) < PSpeedIs2Header(@LData[0])^.Length + SizeOf(TSpeedIs2Header)) then
    LData := FContainer.ReadAtLeast(LIndex, PSpeedIs2Header(@LData[0])^.Length + SizeOf(TSpeedIs2Header));
  if not FBitmaps.DecodeIs2(LData, LBitmap) then
  begin
    FLog.Warning(Format('Speed: %s is not a picture of the game', [AName]));
    Exit;
  end;
  if ARightCrop and (LBitmap.Width > 0) then
  begin
    // the last column is dropped
    Dec(LBitmap.Width);
    SetLength(LBitmap.Pixels, LBitmap.Width * LBitmap.Height);
  end;
  try
    APatch := FPatches.FromColumns(LBitmap.Pixels, LBitmap.Width, LBitmap.Height, ASolid);
  except
    on E: EGameDataException do
    begin
      FLog.Warning(Format('Speed: %s was left out: %s', [AName, E.Message]));
      Exit;
    end;
  end;
  AWidth := LBitmap.Width;
  AHeight := LBitmap.Height;
  Result := True;
end;

function TSpeedTranslation.MakeIs2Lump(const ASource, ALumpName: string; ASolid, ARightCrop: Boolean;
  out AWidth, AHeight: Integer): Boolean;
var
  LPatch: TBytes;
begin
  Result := MakeIs2Patch(ASource, ASolid, ARightCrop, AWidth, AHeight, LPatch);
  if Result then
    FWad.AddLump(ALumpName, LPatch);
end;

procedure TSpeedTranslation.MakePalette;
var
  LFile: TBytes;
  LPalette: TSpeedPalette;
begin
  if not FContainer.TryRead(NAME_PALETTE, LFile) then
    Exit;
  if Length(LFile) < GAMEDATA_PALETTE_SIZE then
  begin
    FLog.Warning(Format('Speed: %s has %d bytes and the palette needs %d', [NAME_PALETTE, Length(LFile),
      GAMEDATA_PALETTE_SIZE]));
    Exit;
  end;
  LPalette := FPalettes.Build(LFile);
  FColors := LPalette.Colors;
  FWad.AddLump('PLAYPAL', LPalette.PlayPal);
  FWad.AddLump('COLORMAP', LPalette.ColorMap);
end;

procedure TSpeedTranslation.MakeTextures;
var
  LNames: TArray<string>;
  LPatchNames: TList<string>;
  LTextures: TBytes;
  LNamesLump: TBytes;
  LCount: Integer;
  LIndex: Integer;
  LName: string;
  LWallName: string;
  LWidth: Integer;
  LHeight: Integer;
  LPatch: TBytes;
  LStub: TBytes;
  LSky: TBytes;
  LTextureEntries: TList<TBytes>;
  LGenerated: Integer;

  function Name8(const AText: string): TBytes;
  var
    LCharacter: Integer;
  begin
    SetLength(Result, 8);
    FillChar(Result[0], 8, 0);
    for LCharacter := 1 to Length(AText) do
      Result[LCharacter - 1] := Byte(Ord(AText[LCharacter]) and $FF);
  end;

  // a texture of one patch: name, masked, width, height, an unused long, 1 patch (index of PNAMES)
  procedure AddTexture(const ATextureName: string; AWidthOfTexture, AHeightOfTexture, APatchIndex: Integer);
  var
    LEntry: TBytes;
  begin
    SetLength(LEntry, 32);
    FillChar(LEntry[0], 32, 0);
    Move(Name8(ATextureName)[0], LEntry[0], 8);
    PSmallInt(@LEntry[12])^ := SmallInt(AWidthOfTexture);
    PSmallInt(@LEntry[14])^ := SmallInt(AHeightOfTexture);
    PSmallInt(@LEntry[20])^ := 1;
    PSmallInt(@LEntry[26])^ := SmallInt(APatchIndex);
    LTextureEntries.Add(LEntry);
  end;

begin
  // the textures of the walls are the pictures whose names are numbers
  LNames := CollectNames(EXTENSION_IS2,
    function(AName: string): Boolean
    begin
      Result := TSpeedNames.HasCanonicalNumberStem(AName);
    end);

  LPatchNames := TList<string>.Create;
  LTextureEntries := TList<TBytes>.Create;
  try
    FWad.AddMarker('P_START');

    // a stub for the first texture of the table: the engine does not use the texture 0 for the walls
    SetLength(LStub, 32 * 32);
    FillChar(LStub[0], Length(LStub), 0);
    FWad.AddLump('AA0000', FPatches.FromColumns(LStub, 32, 32, True));
    LPatchNames.Add('AA0000');
    AddTexture('AA0000', 32, 32, 0);

    LGenerated := 0;
    for LName in LNames do
    begin
      LWallName := SPEED_WALL_PREFIX + TSpeedNames.WithoutExtension(LName);
      if MakeIs2Patch(LName, False, True, LWidth, LHeight, LPatch) then
      begin
        FWad.AddLump(LWallName, LPatch);
        Inc(LGenerated);
        LPatchNames.Add(LWallName);
        AddTexture(LWallName, LWidth, LHeight, LGenerated);
        FSources.Add(LWallName + '=' + LName);
      end;
    end;

    // the skies are stubs, the engine draws its own
    SetLength(LSky, 256 * 128);
    for LIndex := 1 to SKY_COUNT do
    begin
      FillChar(LSky[0], Length(LSky), 127);
      LName := 'SKY' + IntToStr(LIndex);
      FWad.AddLump(LName, FPatches.FromColumns(LSky, 256, 128, True));
      LPatchNames.Add(LName);
      AddTexture(LName, 256, 128, LGenerated + LIndex);
    end;
    FWad.AddMarker('P_END');

    LCount := LTextureEntries.Count;
    SetLength(LTextures, 4 + LCount * 4 + LCount * 32);
    PInteger(@LTextures[0])^ := LCount;
    for LIndex := 0 to LCount - 1 do
    begin
      PInteger(@LTextures[4 + LIndex * 4])^ := 4 + LCount * 4 + LIndex * 32;
      Move(LTextureEntries[LIndex][0], LTextures[4 + LCount * 4 + LIndex * 32], 32);
    end;
    SetLength(LNamesLump, 4 + LPatchNames.Count * 8);
    FillChar(LNamesLump[0], Length(LNamesLump), 0);
    PInteger(@LNamesLump[0])^ := LPatchNames.Count;
    for LIndex := 0 to LPatchNames.Count - 1 do
      Move(Name8(LPatchNames[LIndex])[0], LNamesLump[4 + LIndex * 8], 8);
    FWad.AddLump('TEXTURE1', LTextures);
    FWad.AddLump('PNAMES', LNamesLump);
  finally
    LTextureEntries.Free;
    LPatchNames.Free;
  end;
  // the second table is empty
  FWad.AddLump('TEXTURE2', TBytes.Create(0, 0, 0, 0));
end;

procedure TSpeedTranslation.MakeFlats;
var
  LTiles: TBytes;
  LCount: Integer;
  LFlat: TBytes;
  LTranslated: TBytes;
  LIndex: Integer;
  LTranslation: Integer;
  LPixel: Integer;
  LName: string;
  LSky: TBytes;
  LValue: Byte;
begin
  if not FContainer.TryRead(NAME_TILES, LTiles) then
    Exit;
  LCount := Length(LTiles) div SPEED_TILE_PIXELS;
  SetLength(LFlat, SPEED_TILE_PIXELS);
  SetLength(LTranslated, SPEED_TILE_PIXELS);

  FWad.AddMarker('F_START');
  for LIndex := 0 to LCount - 1 do
  begin
    Move(LTiles[LIndex * SPEED_TILE_PIXELS], LFlat[0], SPEED_TILE_PIXELS);
    LName := SPEED_FLAT_PREFIX + TSpeedNames.ZeroFill(4, LIndex + 1);
    FWad.AddLump(LName, LFlat);
    FFlatSizes.Add(LName + '=' + IntToStr(FLAT_UNITS));
    if LIndex = SPEED_TRANSLATED_TILE then
      for LTranslation := 1 to SPEED_TRANSLATION_COUNT - 1 do
      begin
        for LPixel := 0 to SPEED_TILE_PIXELS - 1 do
          if LFlat[LPixel] in [64..79] then
            LTranslated[LPixel] := Byte(SPEED_TRANSLATION_ROVERS[LTranslation] + (LFlat[LPixel] - 64) div 2)
          else
            LTranslated[LPixel] := LFlat[LPixel];
        LName := SPEED_TRANSLATED_FLAT_PREFIX + TSpeedNames.ZeroFill(4, LTranslation);
        FWad.AddLump(LName, LTranslated);
        FFlatSizes.Add(LName + '=' + IntToStr(FLAT_UNITS));
      end;
  end;

  // the sky of the flats: a plain light blue
  LValue := Byte(FMatcher.FindApproximateIndex(FColors, (77 shl 16) + (179 shl 8) + 255, 0, 255));
  SetLength(LSky, SPEED_TILE_PIXELS);
  FillChar(LSky[0], SPEED_TILE_PIXELS, LValue);
  FWad.AddLump('F_SKY1', LSky);
  FFlatSizes.Add('F_SKY1=' + IntToStr(SPEED_TILE_SIZE));
  FWad.AddMarker('F_END');
end;

procedure TSpeedTranslation.MakeMapFlats;
var
  LTiles: TBytes;
  LMapData: TBytes;
  LBitmap: TBytes;
  LFirstTile: Integer;
  LMap: Integer;
  LPrefix: string;
begin
  if not FContainer.TryRead(NAME_TILES, LTiles) then
    Exit;
  FWad.AddMarker('F_START');
  for LMap := 0 to SPEED_MAP_COUNT - 1 do
  begin
    LPrefix := TSpeedNames.ZeroFill(2, LMap);
    if not FContainer.TryRead('MAP' + LPrefix + '.DAT', LMapData) then
      Continue;
    if not FMapBitmaps.Build(LMapData, LTiles, LBitmap, LFirstTile) then
    begin
      FLog.Warning(Format('Speed: MAP%s.DAT is too short to hold the tiles of a circuit', [LPrefix]));
      Continue;
    end;
    // the flat under the circuit, outside of the picture, is the first tile
    FExtraFlats[LMap] := SPEED_FLAT_PREFIX + TSpeedNames.ZeroFill(4, LFirstTile + 1);
    FWad.AddLump('FMAP' + LPrefix, LBitmap);
    FFlatSizes.Add('FMAP' + LPrefix + '=' + IntToStr(SPEED_LEVEL_SCALE * SPEED_MAP_BITMAP_SIDE));
  end;
  FWad.AddMarker('F_END');
end;

procedure TSpeedTranslation.MakeLevels;
var
  LText: TBytes;
  LCircuits: TArray<TSpeedCircuit>;
  LMapData: TBytes;
  LSectors: TBytes;
  LPath: TBytes;
  LMap: Integer;
  LPrefix: string;
  LLines: TList<string>;
  LCircuit: TSpeedCircuit;
  LCharacters: string;
  LIndex: Integer;
begin
  LCharacters := '';
  if FContainer.TryRead(NAME_CIRCUITS, LText) then
  begin
    SetLength(LCharacters, Length(LText));
    for LIndex := 0 to High(LText) do
      LCharacters[LIndex + 1] := Char(LText[LIndex]);
  end;
  LCircuits := FCircuits.Parse(LCharacters);

  for LMap := 0 to SPEED_MAP_COUNT - 1 do
  begin
    LPrefix := TSpeedNames.ZeroFill(2, LMap);
    if not (FContainer.TryRead('MAP' + LPrefix + '.DAT', LMapData) and
      FContainer.TryRead('MAP' + LPrefix + '.SEC', LSectors) and
      FContainer.TryRead('MAP' + LPrefix + '.PTH', LPath)) then
      Continue;
    if not FLevels.Build(LEVEL_NAMES[LMap], LPrefix, LMapData, LSectors, LPath, SPEED_LEVEL_SCALE,
      FExtraFlats[LMap], FWad) then
      Continue;
    LCircuit := LCircuits[LMap];
    LLines := TList<string>.Create;
    try
      LLines.Add('sprite=MAPSPR' + LPrefix);
      LLines.Add('sky=NUBES' + IntToStr(LMap));
      LLines.Add('mountain=MOUNT' + IntToStr(LMap));
      LLines.Add('ground=' + FExtraFlats[LMap]);
      LLines.Add('name=' + LCircuit.Name);
      LLines.Add('length=' + IntToStr(LCircuit.Length));
      LLines.Add('best=' + IntToStr(LCircuit.Best));
      LLines.Add('level=' + IntToStr(LCircuit.Level));
      FWad.AddText('MAPDATA', Texts(LLines));
    finally
      LLines.Free;
    end;
  end;
end;

procedure TSpeedTranslation.MakePixPicture(const ASource, ALumpName: string; ASolid: Boolean);
var
  LData: TBytes;
  LPalette: TBytes;
  LPaletteName: string;
  LPixels: TBytes;
  LWidth: Integer;
  LHeight: Integer;
  LIndex: Integer;
  LPatch: TBytes;
begin
  if not FContainer.TryRead(ASource, LData) then
    Exit;
  LWidth := 320;
  LHeight := Length(LData) div LWidth;
  SetLength(LPixels, LWidth * LHeight);
  if Length(LPixels) > 0 then
    Move(LData[0], LPixels[0], Length(LPixels));
  LPaletteName := Copy(ASource, 1, Length(ASource) - 3) + 'PAL';
  try
    if FContainer.TryRead(LPaletteName, LPalette) then
    begin
      // a picture with a palette of its own: its colors go to the palette of the game
      SetLength(LPalette, GAMEDATA_PALETTE_SIZE);
      LPatch := FPatches.FromPalettedRows(LPixels, LWidth, LHeight, LPalette, ASolid, FColors);
    end
    else
    begin
      // the colors that the palette of the game does not have are the one before
      for LIndex := 1 to High(LPixels) do
        if (LPixels[LIndex] > 0) and ((LPixels[LIndex] < 16) or (LPixels[LIndex] > 239)) then
          LPixels[LIndex] := LPixels[LIndex - 1];
      if not ASolid then
        for LIndex := 0 to High(LPixels) do
          if LPixels[LIndex] = 0 then
            LPixels[LIndex] := 255
          else if LPixels[LIndex] = 191 then
            LPixels[LIndex] := 190;
      LPatch := FPatches.FromRows(LPixels, LWidth, LHeight, ASolid);
    end;
  except
    on E: EGameDataException do
    begin
      FLog.Warning(Format('Speed: %s was left out: %s', [ASource, E.Message]));
      Exit;
    end;
  end;
  FWad.AddLump(ALumpName, LPatch);
end;

procedure TSpeedTranslation.MakePictures;
var
  LNames: TArray<string>;
  LName: string;
  LWidth: Integer;
  LHeight: Integer;
  LStem: string;
  LFour: string;
  LTransparent: Boolean;
  LIndex: Integer;
begin
  FWad.AddMarker('G_START');

  LNames := CollectNames(EXTENSION_PIX, nil);
  for LName in LNames do
  begin
    LTransparent := False;
    for LIndex := 0 to High(TRANSPARENT_PICTURES) do
      if TRANSPARENT_PICTURES[LIndex] = LName then
        LTransparent := True;
    MakePixPicture(LName, TSpeedNames.WithoutExtension(LName), not LTransparent);
    FSources.Add(TSpeedNames.WithoutExtension(LName) + '=' + LName);
  end;

  // the other pictures: not the walls, not the sprites (the cars, the ground, the smoke and the sparks)
  LNames := CollectNames(EXTENSION_IS2,
    function(AName: string): Boolean
    var
      LPrefix: string;
    begin
      LPrefix := TSpeedNames.Stem(AName);
      Result := (not TSpeedNames.HasCanonicalNumberStem(AName)) and (UpperCase(Copy(LPrefix, 1, 3)) <> 'XPR');
      if Result then
      begin
        LFour := UpperCase(Copy(LPrefix, 1, 4));
        Result := (LFour <> 'SPRK') and (LFour <> 'SMOK') and (LFour <> 'GND0') and (LFour <> 'GND1') and
          (LFour <> 'GND2');
      end;
    end);
  for LName in LNames do
  begin
    LStem := TSpeedNames.WithoutExtension(LName);
    MakeIs2Lump(LName, LStem, False, False, LWidth, LHeight);
    FSources.Add(LStem + '=' + LName);
  end;
  FWad.AddMarker('G_END');
end;

procedure TSpeedTranslation.MakeSprites;
var
  LIndex: Integer;
  LWidth: Integer;
  LHeight: Integer;
begin
  FWad.AddMarker('S_START');
  for LIndex := 0 to High(SPRITE_NAMES) do
  begin
    MakeIs2Lump(SPRITE_NAMES[LIndex].Source, SPRITE_NAMES[LIndex].Sprite, False, False, LWidth, LHeight);
    // the file is in the list of sources even when it is not in the container
    FSources.Add(SPRITE_NAMES[LIndex].Sprite + '=' + SPRITE_NAMES[LIndex].Source);
  end;
  FWad.AddMarker('S_END');
end;

procedure TSpeedTranslation.MakeMusic;
var
  LData: TBytes;
  LIndex: Integer;
begin
  // without the music of the menu there is no music at all
  if not FContainer.TryRead('MENUS.S3M', LData) then
    Exit;
  FWad.AddLump('D_INTRO', LData);
  for LIndex := 1 to 9 do
    if FContainer.TryRead('HASTE' + IntToStr(LIndex) + '.S3M', LData) then
      FWad.AddLump('D_E1M' + IntToStr(LIndex), LData);
  if FContainer.TryRead('SCIRCUIT.S3M', LData) then
    FWad.AddLump('D_INTER', LData);
  if FContainer.TryRead('FINAL.S3M', LData) then
    FWad.AddLump('D_VICTOR', LData);
  if FContainer.TryRead('FIN.S3M', LData) then
    FWad.AddLump('D_FIN', LData);
end;

procedure TSpeedTranslation.MakeSounds;
var
  LNames: TArray<string>;
  LName: string;
  LPlain: TList<string>;
  LEngines: TList<string>;
  LLines: TList<string>;
  LData: TBytes;
  LIndex: Integer;
  LVariant: Integer;
  LLumpName: string;
  LAny: Boolean;
begin
  LPlain := TList<string>.Create;
  LEngines := TList<string>.Create;
  LLines := TList<string>.Create;
  try
    LNames := CollectNames(EXTENSION_RAW, nil);
    for LName in LNames do
      if ((LName <> 'MOTOR0.RAW') and (LName <> 'MOTOR1.RAW')) or (LName = 'CRASH.RAW') then
        LPlain.Add(LName)
      else
        LEngines.Add(LName);

    LLines.Add('// Speed Haste sounds');
    LLines.Add('');
    LAny := False;
    for LIndex := 0 to LPlain.Count - 1 do
      if FContainer.TryRead(LPlain[LIndex], LData) then
      begin
        LLumpName := 'DS_' + TSpeedNames.ZeroFill(5, LIndex);
        FWad.AddLump(LLumpName, TSpeedRawSound.ToWav(LData, 13000, SPEED_FRACUNIT));
        FSources.Add(LLumpName + '=' + LPlain[LIndex]);
        LLines.Add('speedhaste/' + LPlain[LIndex] + ' ' + LLumpName);
        LAny := True;
      end;
    // the sound of an engine: ten variants, one higher than the other, for the revs
    for LIndex := 0 to LEngines.Count - 1 do
      if FContainer.TryRead(LEngines[LIndex], LData) then
        for LVariant := 0 to 9 do
        begin
          LLumpName := TSpeedNames.Stem(LEngines[LIndex]) + '_' + IntToStr(LVariant);
          FWad.AddLump(LLumpName, TSpeedRawSound.ToWav(LData, 11025 + LVariant * 100, SPEED_FRACUNIT div 2));
          LLines.Add('speedhaste/' + LLumpName + ' ' + LLumpName);
          LAny := True;
        end;
    if LAny then
      FWad.AddText('SNDINFO', Texts(LLines));
  finally
    LLines.Free;
    LEngines.Free;
    LPlain.Free;
  end;
end;

procedure TSpeedTranslation.MakeModelEntries;
var
  LNames: TArray<string>;
  LName: string;
  LIndex: Integer;
  LEntry: TSpeedPakEntry;
begin
  LNames := CollectNames(EXTENSION_I3D, nil);
  for LName in LNames do
  begin
    LIndex := FContainer.IndexOf(LName);
    LEntry.Position := FContainer.Entries[LIndex].Position;
    LEntry.Size := FContainer.Entries[LIndex].Size;
    LEntry.Name := 'MODELS\' + LName;
    FPakEntries.Add(LEntry);
  end;
end;

procedure TSpeedTranslation.MakeOriginalData;
var
  LData: TBytes;
begin
  if not FContainer.TryRead(NAME_PALETTE, LData) then
    Exit;
  FWad.AddLump('GRAFSPAL', LData);
  // the tiles are written even when there are none (an empty lump)
  FContainer.TryRead(NAME_TILES, LData);
  FWad.AddLump('GRAFSDAT', LData);
end;

procedure TSpeedTranslation.WriteInfoLumps;
begin
  if FSources.Count > 0 then
    FWad.AddText(SPEED_INFO_LUMP, Texts(FSources));
  if FFlatSizes.Count > 0 then
    FWad.AddText(SPEED_FLAT_SIZE_LUMP, Texts(FFlatSizes));
end;

function TSpeedTranslation.Run(const AContainer: ISpeedContainer;
  const AWad: IGameWadComposer): TArray<TSpeedPakEntry>;
begin
  FContainer := AContainer;
  FWad := AWad;
  MakePalette;
  MakeTextures;
  MakeFlats;
  MakeMapFlats;
  MakeLevels;
  MakePictures;
  FFonts.Build(FColors, FWad);
  MakeSprites;
  MakeMusic;
  MakeSounds;
  MakeModelEntries;
  MakeOriginalData;
  WriteInfoLumps;
  Result := FPakEntries.ToArray;
end;

{ TSpeedTranslator }

constructor TSpeedTranslator.Create(const ALog: ILog; const AMatcher: IColorMatcher;
  const APatches: IGamePatchBuilder; const APalettes: ISpeedPaletteBuilder;
  const ABitmaps: ISpeedBitmapDecoder; const ACircuits: ISpeedCircuitReader;
  const ALevels: ISpeedLevelBuilder; const AFonts: ISpeedFontBuilder;
  const AMapBitmaps: ISpeedMapBitmapBuilder);
begin
  inherited Create;
  if not Assigned(ALog) then
    raise EArgumentNilException.Create('ALog');
  if not Assigned(AMatcher) then
    raise EArgumentNilException.Create('AMatcher');
  if not Assigned(APatches) then
    raise EArgumentNilException.Create('APatches');
  if not Assigned(APalettes) then
    raise EArgumentNilException.Create('APalettes');
  if not Assigned(ABitmaps) then
    raise EArgumentNilException.Create('ABitmaps');
  if not Assigned(ACircuits) then
    raise EArgumentNilException.Create('ACircuits');
  if not Assigned(ALevels) then
    raise EArgumentNilException.Create('ALevels');
  if not Assigned(AFonts) then
    raise EArgumentNilException.Create('AFonts');
  if not Assigned(AMapBitmaps) then
    raise EArgumentNilException.Create('AMapBitmaps');
  FLog := ALog;
  FMatcher := AMatcher;
  FPatches := APatches;
  FPalettes := APalettes;
  FBitmaps := ABitmaps;
  FCircuits := ACircuits;
  FLevels := ALevels;
  FFonts := AFonts;
  FMapBitmaps := AMapBitmaps;
end;

function TSpeedTranslator.Translate(const AContainer: ISpeedContainer;
  const AWad: IGameWadComposer): TArray<TSpeedPakEntry>;
var
  LTranslation: TSpeedTranslation;
begin
  if not Assigned(AContainer) then
    raise EArgumentNilException.Create('AContainer');
  if not Assigned(AWad) then
    raise EArgumentNilException.Create('AWad');
  LTranslation := TSpeedTranslation.Create(FLog, FMatcher, FPatches, FPalettes, FBitmaps, FCircuits,
    FLevels, FFonts, FMapBitmaps);
  try
    Result := LTranslation.Run(AContainer, AWad);
  finally
    LTranslation.Free;
  end;
end;

end.
