{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom engine library - the game data of a mod as the interface    }
{  needs it (a part of Mod of OpenXcom: palettes, full screen pictures, fonts,  }
{  interface rules, cursor colors and extra strings)                            }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomEngine.ModResources;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, DelphiDoom.Yaml.Types, DelphiDoom.Yaml.Intf,
  DelphiDoom.Xcom.Types, DelphiDoom.Xcom.Palette, DelphiDoom.Xcom.Image, DelphiDoom.Xcom.Intf,
  DelphiDoom.XcomSurface.Surface, DelphiDoom.XcomSurface.Font, DelphiDoom.XcomSurface.Intf,
  DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Intf, DelphiDoom.XcomEngine.FileMap,
  DelphiDoom.XcomEngine.RuleInterface, DelphiDoom.XcomEngine.Resources.Intf, DelphiDoom.XcomEngine.Rules.Intf,
  DelphiDoom.XcomEngine.GameRules, DelphiDoom.XcomSurface.SurfaceSet, DelphiDoom.XcomMod.Ruleset,
  DelphiDoom.XcomMod.ModFiles.Intf, DelphiDoom.Png.Client, DelphiDoom.Xcom.CatArchive, DelphiDoom.XcomEngine.SoundSet,
  DelphiDoom.XcomEngine.SoundConverter, DelphiDoom.XcomEngine.SoundFormats.Intf;

type
  /// <summary>
  ///   The data of one palette (256 colors) at a stable address, so that a pointer to it can be given away
  /// </summary>
  TXcomPaletteBox = class
  public
    Colors: TXcomColors;
  end;

  /// <summary>
  ///   IXcomResources for a game directory (UFO or TFTD) and the ruleset of a mod: Mod::loadVanillaResources and
  ///   loadExtraResources for the palettes and the fonts, and loadFile for the "interfaces", "constants", "fontName"
  ///   and "extraStrings" of the ruleset files. The full screen pictures (BACK01.SCR...) are read the first time they
  ///   are asked for, and so are the sounds: the sets of soundDefs (TFTD) or, without them, the CAT files of UFO
  ///   chosen by the preferred format (ResolveSoundSets, IXcomSoundFormats)
  /// </summary>
  TXcomModResources = class(TInterfacedObject, IXcomResources, IXcomGameRules, IXcomSoundFormats)
  strict private
    FRules: TXcomGameRules;
    FFiles: TXcomFileMap;
    FGameData: IXcomGameData;
    FParser: IYamlParser;
    FFontLoader: IXcomSurfaceLoader;
    FPaletteReader: IXcomPaletteReader;
    FModFolder: string;
    FFileSystem: IXcomFileSystem;
    FPalettes: TObjectDictionary<string, TXcomPaletteBox>;
    FSurfaces: TObjectDictionary<string, TXcomSurface>;
    FFonts: TObjectDictionary<string, TXcomFont>;
    FInterfaces: TObjectDictionary<string, TXcomRuleInterface>;
    FExtraStrings: TObjectDictionary<string, TDictionary<string, string>>;
    FStatePalette: TXcomColors;
    FHasStatePalette: Boolean;
    FFontName: string;
    FGeoscapeCursor: Integer;
    FBasescapeCursor: Integer;
    FBattlescapeCursor: Integer;
    FUfopaediaCursor: Integer;
    FGraphsCursor: Integer;
    FHasSoundDefinitions: Boolean;
    FConstants: TDictionary<string, Integer>;
    FSoundSets: TObjectDictionary<string, TXcomSoundSet>;
    FCatalogs: TDictionary<string, IXcomCatArchive>;
    FPreferredSound: Integer;
    FCurrentSound: Integer;
    FSoundSetsResolved: Boolean;
    FMusics: TDictionary<string, TXcomMusicRule>;
    procedure LoadMusic(const ANode: IYamlNode);
    procedure AddPalette(const AName: string; const APalette: TXcomPalette);
    procedure LoadPalettes;
    procedure LoadRulesets;
    procedure LoadRuleset(const ANode: IYamlNode);
    procedure LoadSoundSet(const ANode: IYamlNode);
    procedure ResolveSoundSets;
    procedure AddWholeFileSet(const AName, AFile: string; AFormat: TXcomSoundSetFormat);
    function SoundCatalog(const AFile: string): IXcomCatArchive;
    procedure LoadFonts;
    function LoadFullScreen(const AName: string): TXcomSurface;
    function BuildAltGeoBorder: TXcomSurface;
    function BuildAltBack07: TXcomSurface;
    procedure ModifySoldierBackground(ASurface: TXcomSurface);
  public
    /// <param name="AFiles">The resources own the map. The virtual files: the common data (Language\Font.dat), the mod and the game files</param>
    /// <param name="AGameData">The game directory seen with the names that OpenXcom uses (GEODATA\PALETTES.DAT...)</param>
    /// <param name="AModFolder">The folder of the mod, where the .rul files are (standard\xcom2)</param>
    constructor Create(AFiles: TXcomFileMap; const AGameData: IXcomGameData; const AFileSystem: IXcomFileSystem;
      const AParser: IYamlParser; const AFontLoader: IXcomSurfaceLoader; const APaletteReader: IXcomPaletteReader;
      const AModFolder: string);
    destructor Destroy; override;
    /// <summary>Reads the palettes, the rulesets and the fonts; EXcomEngineException when the data is not there</summary>
    procedure Load;
    function HasSoundDefinitions: Boolean;
    /// <summary>IXcomSoundFormats: the sets of a game without soundDefs are chosen again at the next sound</summary>
    procedure SetPreferredSound(AFormat: Integer);
    function CurrentSound: Integer;
    function SoundWave(const ASet: string; AIndex: Integer): TBytes;
    function MusicRules: TArray<TXcomMusicRule>;
    function SoundFile(const AName: string): TBytes;
    function Constant(const AName: string; ADefault: Integer): Integer;
    function GetSurface(const AName: string): TXcomSurface;
    function GetFont(const AName: string): TXcomFont;
    function GetInterface(const AId: string): TXcomRuleInterface;
    function GetPalette(const AName: string): PXcomColor;
    function CursorColor(const APalette: string): Integer;
    procedure SetPalette(AColors: PXcomColor; AFirst: Integer = 0; ACount: Integer = 256);
    /// <summary>Mod::getExtraStrings: the strings of a language that the rulesets define (nil when there are none)</summary>
    function ExtraStrings(const ALanguage: string): TDictionary<string, string>;
    function FontName: string;
    /// <summary>
    ///   Mod::loadAll for the strategy screens: reads the ruleset of the master mod (the resources own the rules from
    ///   here). Without this call IXcomGameRules has no ruleset and no surface sets
    /// </summary>
    procedure LoadRules(const AParser: IYamlParser; APng: TPngClient; const AModId: string);
    function HasRules: Boolean;
    function Ruleset: TXcomRuleset;
    function ModFiles: IXcomModFiles;
    function GetSurfaceSet(const AName: string): TXcomSurfaceSet;
  end;

implementation

uses
  System.IOUtils, System.Generics.Defaults, DelphiDoom.XcomEngine.YamlFields, DelphiDoom.Xcom.Factory,
  DelphiDoom.Xcom.BattlescapePalette;

const
  PALETTE_NAMES: array[0..4] of string = ('PAL_GEOSCAPE', 'PAL_BASESCAPE', 'PAL_GRAPHS', 'PAL_UFOPAEDIA',
    'PAL_BATTLEPEDIA');
  SCREEN_WIDTH = 320;
  SCREEN_HEIGHT = 200;

constructor TXcomModResources.Create(AFiles: TXcomFileMap; const AGameData: IXcomGameData;
  const AFileSystem: IXcomFileSystem; const AParser: IYamlParser; const AFontLoader: IXcomSurfaceLoader;
  const APaletteReader: IXcomPaletteReader; const AModFolder: string);
begin
  inherited Create;
  FPaletteReader := APaletteReader;
  FFiles := AFiles;
  FGameData := AGameData;
  FFileSystem := AFileSystem;
  FParser := AParser;
  FFontLoader := AFontLoader;
  FModFolder := AModFolder;
  FPalettes := TObjectDictionary<string, TXcomPaletteBox>.Create([doOwnsValues]);
  FSurfaces := TObjectDictionary<string, TXcomSurface>.Create([doOwnsValues]);
  FFonts := TObjectDictionary<string, TXcomFont>.Create([doOwnsValues]);
  FInterfaces := TObjectDictionary<string, TXcomRuleInterface>.Create([doOwnsValues]);
  FExtraStrings := TObjectDictionary<string, TDictionary<string, string>>.Create([doOwnsValues]);
  FConstants := TDictionary<string, Integer>.Create;
  FSoundSets := TObjectDictionary<string, TXcomSoundSet>.Create([doOwnsValues]);
  FCatalogs := TDictionary<string, IXcomCatArchive>.Create;
  FMusics := TDictionary<string, TXcomMusicRule>.Create;
  FFontName := 'Font.dat';
  // Mod::resetGlobalStatics
  FGeoscapeCursor := 252;
  FBasescapeCursor := 252;
  FBattlescapeCursor := 144;
  FUfopaediaCursor := 252;
  FGraphsCursor := 252;
end;

destructor TXcomModResources.Destroy;
begin
  FMusics.Free;
  FCatalogs.Free;
  FSoundSets.Free;
  FConstants.Free;
  FRules.Free;
  FFiles.Free;
  FExtraStrings.Free;
  FInterfaces.Free;
  FFonts.Free;
  FSurfaces.Free;
  FPalettes.Free;
  inherited Destroy;
end;

procedure TXcomModResources.AddPalette(const AName: string; const APalette: TXcomPalette);
var
  LBox: TXcomPaletteBox;
begin
  LBox := TXcomPaletteBox.Create;
  FillChar(LBox.Colors, SizeOf(LBox.Colors), 0);
  Move(APalette.Colors, LBox.Colors, SizeOf(TXcomColor) * APalette.Count);
  FPalettes.AddOrSetValue(AName, LBox);
end;

procedure TXcomModResources.LoadPalettes;
var
  LIndex: Integer;
  LPalette: TXcomPalette;
  LBackPalettes: TXcomPalette;
begin
  for LIndex := 0 to High(PALETTE_NAMES) do
    AddPalette(PALETTE_NAMES[LIndex], FGameData.LoadPalette(LIndex));
  LPalette := FGameData.LoadPalette(4);
  LPalette.ApplyBattlescapeGradient;
  AddPalette('PAL_BATTLESCAPE', LPalette);
  // Mod::loadBattlescapeResources: a game with UFOGRAPH D0..D3.LBM (TFTD) takes the battlescape palettes of the
  // depths from them, and the first one replaces PAL_BATTLESCAPE
  for LIndex := 0 to TXcomBattlescapePalette.COUNT - 1 do
    if TXcomBattlescapePalette.TryLoad(FGameData.Files, TXcomFactory.CreateLbmReader, LIndex, LPalette) then
    begin
      if LIndex = 0 then
        AddPalette('PAL_BATTLESCAPE', LPalette)
      else
        AddPalette(Format('PAL_BATTLESCAPE_%d', [LIndex]), LPalette);
    end;
  // BACKPALS.DAT: 128 colors, the blocks of 16 that the windows take as their background colors
  LBackPalettes := FPaletteReader.Read(FGameData.Files.ReadAll('GEODATA/BACKPALS.DAT'), 128, 0);
  AddPalette('BACKPALS.DAT', LBackPalettes);
end;

procedure TXcomModResources.LoadRuleset(const ANode: IYamlNode);
var
  LItem: IYamlNode;
  LId: string;
  LRule: TXcomRuleInterface;
  LConstants: IYamlNode;
  LStrings: TDictionary<string, string>;
  LPair: TYamlPair;
  LNumber: Integer;
begin
  FFontName := TXcomYamlFields.ReadString(ANode, 'fontName', FFontName);
  LConstants := TXcomYamlFields.Field(ANode, 'constants');
  if Assigned(LConstants) then
  begin
    FGeoscapeCursor := TXcomYamlFields.ReadInteger(LConstants, 'geoscapeCursor', FGeoscapeCursor);
    FBasescapeCursor := TXcomYamlFields.ReadInteger(LConstants, 'basescapeCursor', FBasescapeCursor);
    FBattlescapeCursor := TXcomYamlFields.ReadInteger(LConstants, 'battlescapeCursor', FBattlescapeCursor);
    FUfopaediaCursor := TXcomYamlFields.ReadInteger(LConstants, 'ufopaediaCursor', FUfopaediaCursor);
    FGraphsCursor := TXcomYamlFields.ReadInteger(LConstants, 'graphsCursor', FGraphsCursor);
  end;
  if Assigned(LConstants) and LConstants.IsMap then
    for LPair in LConstants.Pairs do
      if LPair.Value.TryAsInteger(LNumber) then
        FConstants.AddOrSetValue(LPair.Key.ScalarString, LNumber);
  for LItem in TXcomYamlFields.Sequence(ANode, 'soundDefs') do
    LoadSoundSet(LItem);
  if Length(TXcomYamlFields.Sequence(ANode, 'soundDefs')) > 0 then
    FHasSoundDefinitions := True;
  for LItem in TXcomYamlFields.Sequence(ANode, 'musics') do
    LoadMusic(LItem);
  for LItem in TXcomYamlFields.Sequence(ANode, 'extraStrings') do
  begin
    LId := TXcomYamlFields.ReadString(LItem, 'type', '');
    if not FExtraStrings.TryGetValue(LId, LStrings) then
    begin
      LStrings := TDictionary<string, string>.Create;
      FExtraStrings.Add(LId, LStrings);
    end;
    if Assigned(TXcomYamlFields.Field(LItem, 'strings')) then
      for LPair in TXcomYamlFields.Field(LItem, 'strings').Pairs do
        LStrings.AddOrSetValue(LPair.Key.ScalarString, LPair.Value.ScalarString);
  end;
  for LItem in TXcomYamlFields.Sequence(ANode, 'interfaces') do
  begin
    LId := TXcomYamlFields.ReadString(LItem, 'type', '');
    if LId = '' then
      Continue;
    if not FInterfaces.TryGetValue(LId, LRule) then
    begin
      LRule := TXcomRuleInterface.Create(LId);
      FInterfaces.Add(LId, LRule);
    end;
    LRule.Load(LItem);
  end;
end;

procedure TXcomModResources.LoadRulesets;
var
  LNames: TArray<string>;
  LName: string;
  LBytes: TBytes;
  LText: string;
begin
  LNames := FFileSystem.FolderContents(FModFolder, 'rul');
  for LName in LNames do
  begin
    LBytes := FFileSystem.ReadAll(TPath.Combine(FModFolder, LName + '.rul'));
    // the files that have none of the keys that are read here are not parsed (the big rulesets of the items...)
    LText := TEncoding.UTF8.GetString(LBytes);
    if (Pos('interfaces:', LText) = 0) and (Pos('constants:', LText) = 0) and (Pos('fontName:', LText) = 0) and
      (Pos('extraStrings:', LText) = 0) and (Pos('soundDefs:', LText) = 0) and (Pos('musics:', LText) = 0) then
      Continue;
    try
      LoadRuleset(FParser.Load(LBytes));
    except
      on E: EYamlException do
        raise EXcomEngineException.Create(LName + '.rul: ' + E.Message);
    end;
  end;
end;

procedure TXcomModResources.LoadSoundSet(const ANode: IYamlNode);
var
  LType: string;
  LSet: TXcomSoundSet;
  LItem: IYamlNode;
  LPair: TArray<IYamlNode>;
  LFirst: Integer;
  LLast: Integer;
  LValue: Integer;
  LList: TList<Integer>;
begin
  LType := TXcomYamlFields.ReadString(ANode, 'type', '');
  if LType = '' then
    Exit;
  if not FSoundSets.TryGetValue(LType, LSet) then
  begin
    LSet := TXcomSoundSet.Create;
    FSoundSets.Add(LType, LSet);
  end;
  LSet.CatFile := TXcomYamlFields.ReadString(ANode, 'file', LSet.CatFile);
  LList := TList<Integer>.Create;
  try
    LList.AddRange(LSet.Sounds);
    // the ranges (pairs first, last) come before the single numbers, as in SoundDefinition::load
    for LItem in TXcomYamlFields.Sequence(ANode, 'soundRanges') do
    begin
      LPair := LItem.Items;
      if (Length(LPair) = 2) and LPair[0].TryAsInteger(LFirst) and LPair[1].TryAsInteger(LLast) then
        for LValue := LFirst to LLast do
          LList.Add(LValue);
    end;
    for LItem in TXcomYamlFields.Sequence(ANode, 'sounds') do
      if LItem.TryAsInteger(LValue) then
        LList.Add(LValue)
      else
        LList.Add(-1);
    LSet.Sounds := LList.ToArray;
  finally
    LList.Free;
  end;
end;

function TXcomModResources.Constant(const AName: string; ADefault: Integer): Integer;
begin
  if not FConstants.TryGetValue(AName, Result) then
    Result := ADefault;
end;

function TXcomModResources.SoundCatalog(const AFile: string): IXcomCatArchive;
var
  LBytes: TBytes;
begin
  if FCatalogs.TryGetValue(AFile, Result) then
    Exit;
  Result := nil;
  LBytes := SoundFile(AFile);
  // a file too short to have an index is not a set of sounds
  if Length(LBytes) < 4 then
    Exit;
  Result := TXcomCatArchive.Create(LBytes);
  FCatalogs.Add(AFile, Result);
end;

procedure TXcomModResources.AddWholeFileSet(const AName, AFile: string; AFormat: TXcomSoundSetFormat);
var
  LSet: TXcomSoundSet;
begin
  LSet := TXcomSoundSet.Create;
  LSet.CatFile := AFile;
  LSet.Format := AFormat;
  LSet.WholeFile := True;
  FSoundSets.AddOrSetValue(AName, LSet);
end;

procedure TXcomModResources.ResolveSoundSets;
const
  SET_NAMES: array[0..1] of string = ('GEO.CAT', 'BATTLE.CAT');
  // the files by format: XCOM_SOUND_14 and XCOM_SOUND_10
  SET_FILES: array[XCOM_SOUND_14..XCOM_SOUND_10, 0..1] of string = (('SAMPLE.CAT', 'SAMPLE2.CAT'),
    ('SOUND2.CAT', 'SOUND1.CAT'));
var
  LOrder: TArray<Integer>;
  LSetIndex: Integer;
  LFormat: Integer;
begin
  if FSoundSetsResolved then
    Exit;
  FSoundSetsResolved := True;
  // Mod::loadExtraResources: without soundDefs the two sets are whole files, the preferred format first and then
  // the Windows one and the DOS one
  if not FHasSoundDefinitions then
  begin
    if (FPreferredSound = XCOM_SOUND_14) or (FPreferredSound = XCOM_SOUND_10) then
      LOrder := [FPreferredSound, XCOM_SOUND_14, XCOM_SOUND_10]
    else
      LOrder := [XCOM_SOUND_14, XCOM_SOUND_10];
    FCurrentSound := XCOM_SOUND_AUTO;
    for LSetIndex := Low(SET_NAMES) to High(SET_NAMES) do
    begin
      FSoundSets.Remove(SET_NAMES[LSetIndex]);
      for LFormat in LOrder do
        if Length(SoundFile(SET_FILES[LFormat, LSetIndex])) > 0 then
        begin
          if LFormat = XCOM_SOUND_14 then
            AddWholeFileSet(SET_NAMES[LSetIndex], SET_FILES[LFormat, LSetIndex], sfWave)
          else
            AddWholeFileSet(SET_NAMES[LSetIndex], SET_FILES[LFormat, LSetIndex], sfDos);
          FCurrentSound := LFormat;
          Break;
        end;
    end;
  end;
  if Length(SoundFile('INTRO.CAT')) > 0 then
    AddWholeFileSet('INTRO.CAT', 'INTRO.CAT', sfDos);
  if Length(SoundFile('SAMPLE3.CAT')) > 0 then
    AddWholeFileSet('SAMPLE3.CAT', 'SAMPLE3.CAT', sfWave);
end;

procedure TXcomModResources.SetPreferredSound(AFormat: Integer);
begin
  if AFormat = FPreferredSound then
    Exit;
  FPreferredSound := AFormat;
  FSoundSetsResolved := False;
end;

function TXcomModResources.CurrentSound: Integer;
begin
  ResolveSoundSets;
  Result := FCurrentSound;
end;

function TXcomModResources.SoundWave(const ASet: string; AIndex: Integer): TBytes;
var
  LSet: TXcomSoundSet;
  LCatalog: IXcomCatArchive;
  LEntry: Integer;
begin
  Result := nil;
  ResolveSoundSets;
  if (not FSoundSets.TryGetValue(ASet, LSet)) or (AIndex < 0) then
    Exit;
  if LSet.WholeFile then
    LEntry := AIndex
  else if AIndex < Length(LSet.Sounds) then
    LEntry := LSet.Sounds[AIndex]
  else
    Exit;
  LCatalog := SoundCatalog(LSet.CatFile);
  if (LCatalog = nil) or (LEntry < 0) or (LEntry >= LCatalog.Count) then
    Exit;
  case LSet.Format of
    // the sets of soundDefs are loaded with SoundSet::loadCatbyIndex (signed samples at 11025 Hz)
    sfIndexed: Result := TXcomSoundConverter.IndexedToWave(LCatalog.Load(LEntry));
    sfDos: Result := TXcomSoundConverter.RawToWave(LCatalog.Load(LEntry));
    sfWave: Result := TXcomSoundConverter.WaveToWave(LCatalog.Load(LEntry));
  end;
end;

procedure TXcomModResources.LoadMusic(const ANode: IYamlNode);
var
  LType: string;
  LRule: TXcomMusicRule;
begin
  // Mod::loadFile "musics": loadRule by type, then RuleMusic::load over what is there
  LType := TXcomYamlFields.ReadString(ANode, 'type', '');
  if LType = '' then
    Exit;
  if not FMusics.TryGetValue(LType, LRule) then
  begin
    LRule.MusicType := LType;
    LRule.Name := '';
    LRule.CatPos := MaxInt;
    LRule.Normalization := 0.76;
  end;
  LRule.Name := TXcomYamlFields.ReadString(ANode, 'name', LRule.Name);
  LRule.CatPos := TXcomYamlFields.ReadInteger(ANode, 'catPos', LRule.CatPos);
  if Assigned(TXcomYamlFields.Field(ANode, 'normalization')) then
    LRule.Normalization := TXcomYamlFields.Field(ANode, 'normalization').AsSingle(LRule.Normalization);
  FMusics.AddOrSetValue(LType, LRule);
end;

function TXcomModResources.MusicRules: TArray<TXcomMusicRule>;
var
  LList: TList<TXcomMusicRule>;
  LRule: TXcomMusicRule;
  LSource: TXcomMusicRule;
begin
  LList := TList<TXcomMusicRule>.Create;
  try
    for LSource in FMusics.Values do
    begin
      LRule := LSource;
      if LRule.Name = '' then
        LRule.Name := LRule.MusicType;
      LList.Add(LRule);
    end;
    // std::map order: the keys are compared as bytes
    LList.Sort(TComparer<TXcomMusicRule>.Construct(
      function(const ALeft, ARight: TXcomMusicRule): Integer
      begin
        Result := CompareStr(ALeft.MusicType, ARight.MusicType);
      end));
    Result := LList.ToArray;
  finally
    LList.Free;
  end;
end;

function TXcomModResources.SoundFile(const AName: string): TBytes;
var
  LPath: string;
begin
  Result := nil;
  if FFiles.Exists('SOUND/' + AName) then
    Exit(FFiles.ReadAll('SOUND/' + AName));
  LPath := 'SOUND/' + AName;
  if FGameData.Files.Exists(LPath) then
    Result := FGameData.Files.ReadAll(LPath);
end;

function TXcomModResources.HasSoundDefinitions: Boolean;
begin
  Result := FHasSoundDefinitions;
end;

procedure TXcomModResources.LoadFonts;
var
  LDocument: IYamlNode;
  LItem: IYamlNode;
  LImage: IYamlNode;
  LDefinition: TXcomFontDefinition;
  LImageDefinition: TXcomFontImageDefinition;
  LImages: TList<TXcomFontImageDefinition>;
  LWidth: Integer;
  LHeight: Integer;
  LSpacing: Integer;
  LFont: TXcomFont;
begin
  LDocument := FParser.Load(FFiles.ReadAll('Language/' + FFontName));
  for LItem in TXcomYamlFields.Sequence(LDocument, 'fonts') do
  begin
    LWidth := TXcomYamlFields.ReadInteger(LItem, 'width', 0);
    LHeight := TXcomYamlFields.ReadInteger(LItem, 'height', 0);
    LSpacing := TXcomYamlFields.ReadInteger(LItem, 'spacing', 0);
    LDefinition.Monospace := TXcomYamlFields.ReadBoolean(LItem, 'monospace', False);
    LImages := TList<TXcomFontImageDefinition>.Create;
    try
      for LImage in TXcomYamlFields.Sequence(LItem, 'images') do
      begin
        LImageDefinition.Width := TXcomYamlFields.ReadInteger(LImage, 'width', LWidth);
        LImageDefinition.Height := TXcomYamlFields.ReadInteger(LImage, 'height', LHeight);
        LImageDefinition.Spacing := TXcomYamlFields.ReadInteger(LImage, 'spacing', LSpacing);
        LImageDefinition.FileName := TXcomYamlFields.ReadString(LImage, 'file', '');
        LImageDefinition.Chars := TXcomYamlFields.ReadString(LImage, 'chars', '');
        LImages.Add(LImageDefinition);
      end;
      LDefinition.Images := LImages.ToArray;
    finally
      LImages.Free;
    end;
    LFont := TXcomFont.Create;
    try
      LFont.Load(LDefinition, FFontLoader);
    except
      LFont.Free;
      raise;
    end;
    FFonts.AddOrSetValue(TXcomYamlFields.ReadString(LItem, 'id', ''), LFont);
  end;
end;

procedure TXcomModResources.Load;
begin
  LoadPalettes;
  LoadRulesets;
  LoadFonts;
end;

function TXcomModResources.BuildAltGeoBorder: TXcomSurface;
const
  NEW_WIDTH = 320 - 64;
  NEW_HEIGHT = 200;
var
  LOld: TXcomSurface;
  LX, LY: Integer;
  LPixel: Byte;
begin
  // Mod::modResources: the background of the geoscape is made bigger by mirroring the contents
  LOld := GetSurface('GEOBORD.SCR');
  Result := TXcomSurface.Create(NEW_WIDTH * 3, NEW_HEIGHT * 3);
  for LX := 0 to NEW_WIDTH - 1 do
    for LY := 0 to NEW_HEIGHT - 1 do
    begin
      LPixel := LOld.GetPixel(LX, LY);
      Result.SetPixel(NEW_WIDTH + LX, NEW_HEIGHT + LY, LPixel);
      Result.SetPixel(NEW_WIDTH - LX - 1, NEW_HEIGHT + LY, LPixel);
      Result.SetPixel(NEW_WIDTH * 3 - LX - 1, NEW_HEIGHT + LY, LPixel);
      Result.SetPixel(NEW_WIDTH + LX, NEW_HEIGHT - LY - 1, LPixel);
      Result.SetPixel(NEW_WIDTH - LX - 1, NEW_HEIGHT - LY - 1, LPixel);
      Result.SetPixel(NEW_WIDTH * 3 - LX - 1, NEW_HEIGHT - LY - 1, LPixel);
      Result.SetPixel(NEW_WIDTH + LX, NEW_HEIGHT * 3 - LY - 1, LPixel);
      Result.SetPixel(NEW_WIDTH - LX - 1, NEW_HEIGHT * 3 - LY - 1, LPixel);
      Result.SetPixel(NEW_WIDTH * 3 - LX - 1, NEW_HEIGHT * 3 - LY - 1, LPixel);
    end;
  if FHasStatePalette then
    Result.SetColors(FStatePalette);
end;

function TXcomModResources.BuildAltBack07: TXcomSurface;
var
  LX, LY: Integer;
begin
  // Mod::modResources: the "alternate" background of the base information screen (one more row of bars)
  Result := LoadFullScreen('BACK07.SCR');
  for LY := 172 downto 152 do
    for LX := 5 to 314 do
      Result.SetPixel(LX, LY + 4, Result.GetPixel(LX, LY));
  for LY := 147 downto 134 do
    for LX := 5 to 314 do
      Result.SetPixel(LX, LY + 9, Result.GetPixel(LX, LY));
  for LY := 132 downto 109 do
    for LX := 5 to 314 do
      Result.SetPixel(LX, LY + 10, Result.GetPixel(LX, LY));
end;

procedure TXcomModResources.ModifySoldierBackground(ASurface: TXcomSurface);
var
  LX, LY: Integer;
begin
  // Mod::modResources: the soldier stats screen gets one more row by shrinking all of them one pixel;
  // erase the old lines, copying from a +2 offset to account for the dithering
  LY := 91;
  while LY < 199 do
  begin
    for LX := 0 to 148 do
      ASurface.SetPixel(LX, LY, ASurface.GetPixel(LX, LY + 2));
    Inc(LY, 12);
  end;
  // new lines: the bottom row of pixels is the basis
  LY := 89;
  while LY < 199 do
  begin
    for LX := 0 to 148 do
      ASurface.SetPixel(LX, LY, ASurface.GetPixel(LX, 199));
    Inc(LY, 11);
  end;
  // finally the top of the graph moves up by one pixel (the last row again offset for the dithering)
  for LY := 72 to 79 do
    for LX := 0 to 319 do
      if LY = 79 then
        ASurface.SetPixel(LX, LY, ASurface.GetPixel(LX, LY + 2))
      else
        ASurface.SetPixel(LX, LY, ASurface.GetPixel(LX, LY + 1));
end;

function TXcomModResources.LoadFullScreen(const AName: string): TXcomSurface;
var
  LImage: TXcomImage;
  LPalette: TXcomPalette;
  LPath: string;
begin
  if SameText(AName, 'ALTGEOBORD.SCR') then
    Exit(BuildAltGeoBorder);
  if SameText(AName, 'ALTBACK07.SCR') and not FGameData.Files.Exists('GEOGRAPH/ALTBACK07.SCR') then
    Exit(BuildAltBack07);
  LPalette := TXcomPalette.Create(0);
  if SameText(AName, 'INTERWIN.DAT') then
    LImage := FGameData.LoadImage('GEODATA/INTERWIN.DAT', 160, 600, LPalette)
  else
  begin
    LPath := 'GEOGRAPH/' + AName;
    if not FGameData.Files.Exists(LPath) then
      raise EXcomEngineException.Create('Surface ' + AName + ' not found');
    LImage := FGameData.LoadImage(LPath, SCREEN_WIDTH, SCREEN_HEIGHT, LPalette);
  end;
  Result := TXcomSurface.Create(LImage.Width, LImage.Height);
  Move(LImage.Pixels[0], Result.PixelPointer(0, 0)^, LImage.Width * LImage.Height);
  if SameText(AName, 'BACK06.SCR') then
    ModifySoldierBackground(Result);
  if FHasStatePalette then
    Result.SetColors(FStatePalette);
end;

function TXcomModResources.GetSurface(const AName: string): TXcomSurface;
var
  LName: string;
begin
  LName := UpperCase(AName);
  if not FSurfaces.TryGetValue(LName, Result) then
  begin
    Result := LoadFullScreen(LName);
    FSurfaces.Add(LName, Result);
  end;
end;

procedure TXcomModResources.LoadRules(const AParser: IYamlParser; APng: TPngClient; const AModId: string);
begin
  FRules := TXcomGameRules.Create(FFiles, FGameData, FFileSystem, AParser, APng, FModFolder, AModId);
  FRules.Load;
end;

function TXcomModResources.HasRules: Boolean;
begin
  Result := Assigned(FRules);
end;

function TXcomModResources.Ruleset: TXcomRuleset;
begin
  Result := nil;
  if Assigned(FRules) then
    Result := FRules.Ruleset;
end;

function TXcomModResources.ModFiles: IXcomModFiles;
begin
  Result := nil;
  if Assigned(FRules) then
    Result := FRules.ModFiles;
end;

function TXcomModResources.GetSurfaceSet(const AName: string): TXcomSurfaceSet;
begin
  Result := nil;
  if Assigned(FRules) then
    Result := FRules.GetSurfaceSet(AName);
end;

function TXcomModResources.GetFont(const AName: string): TXcomFont;
begin
  if not FFonts.TryGetValue(AName, Result) then
    raise EXcomEngineException.Create('Font ' + AName + ' not found');
end;

function TXcomModResources.GetInterface(const AId: string): TXcomRuleInterface;
begin
  if not FInterfaces.TryGetValue(AId, Result) then
    Result := nil;
end;

function TXcomModResources.GetPalette(const AName: string): PXcomColor;
var
  LBox: TXcomPaletteBox;
begin
  if not FPalettes.TryGetValue(AName, LBox) then
    raise EXcomEngineException.Create('Palette ' + AName + ' not found');
  Result := @LBox.Colors[0];
end;

function TXcomModResources.CursorColor(const APalette: string): Integer;
begin
  if APalette = 'PAL_GEOSCAPE' then
    Result := FGeoscapeCursor
  else if APalette = 'PAL_BASESCAPE' then
    Result := FBasescapeCursor
  else if APalette = 'PAL_UFOPAEDIA' then
    Result := FUfopaediaCursor
  else if APalette = 'PAL_GRAPHS' then
    Result := FGraphsCursor
  else
    Result := FBattlescapeCursor;
end;

procedure TXcomModResources.SetPalette(AColors: PXcomColor; AFirst, ACount: Integer);
var
  LColors: TArray<TXcomColor>;
  LSurface: TXcomSurface;
  LFont: TXcomFont;
  LIndex: Integer;
begin
  if ACount <= 0 then
    Exit;
  Move(AColors^, FStatePalette[AFirst], ACount * SizeOf(TXcomColor));
  FHasStatePalette := True;
  SetLength(LColors, ACount);
  Move(AColors^, LColors[0], ACount * SizeOf(TXcomColor));
  for LFont in FFonts.Values do
    for LIndex := 0 to LFont.ImageCount - 1 do
      LFont.ImageSurface(LIndex).SetColors(LColors, AFirst);
  for LSurface in FSurfaces.Values do
    LSurface.SetColors(LColors, AFirst);
  // Mod::setPalette: the sets of sprites too
  if Assigned(FRules) then
    FRules.SetPalette(LColors, AFirst);
end;

function TXcomModResources.ExtraStrings(const ALanguage: string): TDictionary<string, string>;
begin
  if not FExtraStrings.TryGetValue(ALanguage, Result) then
    Result := nil;
end;

function TXcomModResources.FontName: string;
begin
  Result := FFontName;
end;

end.
