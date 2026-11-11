{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom engine library - the ruleset and the surface sets of the    }
{  loaded game (Mod::loadAll, loadVanillaResources and loadExtraSprite for the  }
{  sets that the strategy screens use)                                          }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomEngine.GameRules;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.Yaml.Intf, DelphiDoom.Png.Client, DelphiDoom.Xcom.Types,
  DelphiDoom.Xcom.Intf,
  DelphiDoom.XcomSurface.SurfaceSet, DelphiDoom.XcomMod.Ruleset, DelphiDoom.XcomMod.ModFiles.Intf,
  DelphiDoom.XcomEngine.Intf, DelphiDoom.XcomEngine.FileMap, DelphiDoom.XcomEngine.Rules.Intf;

type
  /// <summary>
  ///   Loads the ruleset of the master mod from the .rul files of its folder and builds the surface sets the first
  ///   time they are asked for: the sets of the original game (BASEBITS.PCK, INTICON.PCK, TEXTURE.DAT, SCANG.DAT),
  ///   GlobeMarkers, and the sets that the "extraSprites" of the rulesets add or replace. The map and the png client are
  ///   not owned
  /// </summary>
  TXcomGameRules = class
  strict private
    FMap: TXcomFileMap;
    FGameData: IXcomGameData;
    FFiles: IXcomFileSystem;
    FParser: IYamlParser;
    FPng: TPngClient;
    FModFolder: string;
    FModId: string;
    FModFiles: IXcomModFiles;
    FRuleset: TXcomRuleset;
    FSets: TObjectDictionary<string, TXcomSurfaceSet>;
    FStatePalette: array[0..255] of TXcomColor;
    FHasStatePalette: Boolean;
    function CreateVanillaSet(const AName: string): TXcomSurfaceSet;
    procedure ApplyExtraSprites(const AName: string; var ASet: TXcomSurfaceSet);
    procedure LoadSubdivided(ASet: TXcomSurfaceSet; AStart, AWidth, AHeight, ASubX, ASubY: Integer; const APath: string);
  public
    constructor Create(AMap: TXcomFileMap; const AGameData: IXcomGameData; const AFiles: IXcomFileSystem;
      const AParser: IYamlParser; APng: TPngClient; const AModFolder, AModId: string);
    destructor Destroy; override;
    /// <summary>Reads the .rul files of the mod folder, in the order of their names</summary>
    procedure Load;
    function Ruleset: TXcomRuleset;
    function ModFiles: IXcomModFiles;
    function GetSurfaceSet(const AName: string): TXcomSurfaceSet;
    /// <summary>Mod::setPalette: the colors go to every set that exists and to the ones that are made later (the state palette)</summary>
    procedure SetPalette(const AColors: TArray<TXcomColor>; AFirst: Integer);
  end;

implementation

uses
  System.Classes, System.IOUtils, System.Generics.Defaults, DelphiDoom.Xcom.Palette, DelphiDoom.Xcom.Image,
  DelphiDoom.XcomMod.ModLoader, DelphiDoom.XcomMod.ExtraSprites, DelphiDoom.XcomMod.Types,
  DelphiDoom.XcomSurface.Surface, DelphiDoom.XcomEngine.FileMapModFiles, DelphiDoom.XcomEngine.SharedResources;

constructor TXcomGameRules.Create(AMap: TXcomFileMap; const AGameData: IXcomGameData; const AFiles: IXcomFileSystem;
  const AParser: IYamlParser; APng: TPngClient; const AModFolder, AModId: string);
begin
  inherited Create;
  FMap := AMap;
  FGameData := AGameData;
  FFiles := AFiles;
  FParser := AParser;
  FPng := APng;
  FModFolder := AModFolder;
  FModId := AModId;
  FModFiles := TXcomFileMapModFiles.Create(AMap, AParser);
  FSets := TObjectDictionary<string, TXcomSurfaceSet>.Create([doOwnsValues]);
end;

destructor TXcomGameRules.Destroy;
begin
  FSets.Free;
  FRuleset.Free;
  inherited Destroy;
end;

procedure TXcomGameRules.Load;
var
  LNames: TList<string>;
  LPath: string;
  LFiles: TArray<string>;
  LLoader: TXcomModLoader;
  LIndex: Integer;
begin
  LNames := TList<string>.Create;
  try
    for LPath in TDirectory.GetFiles(FModFolder, '*.rul') do
      LNames.Add(ExtractFileName(LPath));
    // std::set<std::string>: the order of the bytes of the names
    LNames.Sort(TComparer<string>.Construct(
      function(const ALeft, ARight: string): Integer
      begin
        Result := CompareStr(ALeft, ARight);
      end));
    SetLength(LFiles, LNames.Count);
    for LIndex := 0 to LNames.Count - 1 do
      LFiles[LIndex] := TPath.Combine(FModFolder, LNames[LIndex]);
  finally
    LNames.Free;
  end;
  LLoader := TXcomModLoader.Create(FParser, TXcomVanillaSharedResources.Create, FModFiles);
  try
    FRuleset := LLoader.LoadAll([TXcomModSource.Make(FModId, 1, LFiles)]);
  finally
    LLoader.Free;
  end;
end;

function TXcomGameRules.Ruleset: TXcomRuleset;
begin
  Result := FRuleset;
end;

function TXcomGameRules.ModFiles: IXcomModFiles;
begin
  Result := FModFiles;
end;

function TXcomGameRules.CreateVanillaSet(const AName: string): TXcomSurfaceSet;
var
  LPalette: TXcomPalette;
  LImages: TArray<TXcomImage>;
  LIndex: Integer;
begin
  Result := nil;
  LPalette := TXcomPalette.Create(0);
  if (AName = 'BASEBITS.PCK') or (AName = 'INTICON.PCK') then
  begin
    LImages := FGameData.LoadImageSet('GEOGRAPH/' + AName, '', 32, 40, LPalette);
    Result := TXcomSurfaceSet.Create(32, 40);
  end
  else if AName = 'TEXTURE.DAT' then
  begin
    LImages := FGameData.LoadImageSet('GEOGRAPH/' + AName, '', 32, 32, LPalette);
    Result := TXcomSurfaceSet.Create(32, 32);
  end
  else if AName = 'SCANG.DAT' then
  begin
    LImages := FGameData.LoadImageSet('GEODATA/' + AName, '', 4, 4, LPalette);
    Result := TXcomSurfaceSet.Create(4, 4);
  end
  else if AName = 'BIGOBS.PCK' then
  begin
    // the items in the hands (Mod::loadBattlescapeResources), for the Ufopaedia
    LImages := FGameData.LoadImageSet('UNITS/BIGOBS.PCK', 'UNITS/BIGOBS.TAB', 32, 48, LPalette);
    Result := TXcomSurfaceSet.Create(32, 48);
  end
  else if AName = 'GlobeMarkers' then
    Result := TXcomSurfaceSet.Create(3, 3);
  if Assigned(Result) then
    for LIndex := 0 to High(LImages) do
      Result.AddImage(LIndex, LImages[LIndex]);
end;

procedure TXcomGameRules.LoadSubdivided(ASet: TXcomSurfaceSet; AStart, AWidth, AHeight, ASubX, ASubY: Integer;
  const APath: string);
var
  LImage: TPngIndexedImage;
  LFrame: TXcomSurface;
  LX, LY, LRow, LOffset, LColumns, LRows, LPixelX, LPixelY, LSourceX, LSourceY: Integer;
  LColors: array[0..255] of TXcomColor;
  LColor: Integer;
begin
  LImage := FPng.DecodeIndexed(FMap.ReadAll(APath));
  for LColor := 0 to 255 do
  begin
    LColors[LColor].Blue := LImage.Palette[LColor * 4];
    LColors[LColor].Green := LImage.Palette[LColor * 4 + 1];
    LColors[LColor].Red := LImage.Palette[LColor * 4 + 2];
    LColors[LColor].Alpha := LImage.Palette[LColor * 4 + 3];
  end;
  LColumns := AWidth div ASubX;
  LRows := AHeight div ASubY;
  LOffset := AStart;
  for LY := 0 to LRows - 1 do
    for LX := 0 to LColumns - 1 do
    begin
      LFrame := ASet.AddFrame(LOffset);
      for LRow := 0 to ASubY - 1 do
        for LPixelX := 0 to ASubX - 1 do
        begin
          LSourceX := LX * ASubX + LPixelX;
          LSourceY := LY * ASubY + LRow;
          LPixelY := LRow;
          // the temporary surface is AWidth x AHeight: what is outside the picture is transparent
          if (LSourceX < LImage.Info.Width) and (LSourceY < LImage.Info.Height) then
            LFrame.SetPixel(LPixelX, LPixelY, LImage.Pixels[LSourceY * LImage.Info.Width + LSourceX]);
        end;
      LFrame.SetColors(LColors);
      Inc(LOffset);
    end;
end;

procedure TXcomGameRules.ApplyExtraSprites(const AName: string; var ASet: TXcomSurfaceSet);
var
  LList: TObjectList<TXcomExtraSprites>;
  LSprites: TXcomExtraSprites;
  LSubdivision: Boolean;
  LSetWidth, LSetHeight, LEntry: Integer;
  LImage: TPngIndexedImage;
  LPicture: TXcomImage;
  LShared: Integer;
begin
  if not FRuleset.ExtraSprites.TryGetValue(AName, LList) then
    Exit;
  for LSprites in LList do
  begin
    if LSprites.SingleImage then
      Continue;
    LSubdivision := (LSprites.SubX <> 0) and (LSprites.SubY <> 0);
    if LSubdivision then
    begin
      LSetWidth := LSprites.SubX;
      LSetHeight := LSprites.SubY;
    end
    else
    begin
      LSetWidth := LSprites.Width;
      LSetHeight := LSprites.Height;
    end;
    if not Assigned(ASet) then
      ASet := TXcomSurfaceSet.Create(LSetWidth, LSetHeight)
    else if (ASet.TotalFrames = 0) and ((ASet.Width <> LSetWidth) or (ASet.Height <> LSetHeight)) then
    begin
      LShared := ASet.MaxSharedFrames;
      ASet.Free;
      ASet := TXcomSurfaceSet.Create(LSetWidth, LSetHeight);
      ASet.MaxSharedFrames := LShared;
    end;
    for LEntry := 0 to LSprites.Sprites.Count - 1 do
    begin
      if LSprites.Sprites.Value(LEntry).EndsWith('/') then
        Continue;
      if not LSubdivision then
      begin
        LImage := FPng.DecodeIndexed(FMap.ReadAll(LSprites.Sprites.Value(LEntry)));
        LPicture := TXcomImage.Create(LImage.Info.Width, LImage.Info.Height);
        Move(LImage.Pixels[0], LPicture.Pixels[0], LImage.Info.Width * LImage.Info.Height);
        ASet.AddImage(LSprites.Sprites.Key(LEntry), LPicture);
      end
      else
        LoadSubdivided(ASet, LSprites.Sprites.Key(LEntry), LSprites.Width, LSprites.Height, LSprites.SubX,
          LSprites.SubY, LSprites.Sprites.Value(LEntry));
    end;
  end;
end;

procedure TXcomGameRules.SetPalette(const AColors: TArray<TXcomColor>; AFirst: Integer);
var
  LSet: TXcomSurfaceSet;
  LIndex: Integer;
begin
  for LIndex := 0 to High(AColors) do
    if AFirst + LIndex <= 255 then
      FStatePalette[AFirst + LIndex] := AColors[LIndex];
  FHasStatePalette := True;
  for LSet in FSets.Values do
    LSet.SetPalette(AColors, AFirst);
end;

function TXcomGameRules.GetSurfaceSet(const AName: string): TXcomSurfaceSet;
begin
  if FSets.TryGetValue(AName, Result) then
    Exit;
  Result := CreateVanillaSet(AName);
  ApplyExtraSprites(AName, Result);
  if Assigned(Result) then
  begin
    if FHasStatePalette then
      Result.SetPalette(FStatePalette);
    if AName = 'GlobeMarkers' then
      Result.MaxSharedFrames := 9
    else if (AName = 'BASEBITS.PCK') or (AName = 'INTICON.PCK') then
      Result.MaxSharedFrames := Result.TotalFrames;
    FSets.Add(AName, Result);
  end;
end;

end.
