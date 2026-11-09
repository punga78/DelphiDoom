{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom engine library - the loading of the game data of a master   }
{  mod (Game::loadMods and Game::loadLanguages)                                 }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomEngine.ModGameLoader;

interface

uses
  System.SysUtils, System.IOUtils, System.Generics.Collections, DelphiDoom.Yaml.Intf, DelphiDoom.Png.Client,
  DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Intf, DelphiDoom.XcomEngine.Language,
  DelphiDoom.XcomEngine.Resources.Intf, DelphiDoom.XcomEngine.GameLoader.Intf;

type
  /// <summary>Where the data is and what to load (the parts of Options and of the mod infos that the loading reads)</summary>
  TXcomLoaderSettings = record
    /// <summary>The folder with common\ and standard\ (the data folder of OpenXcom)</summary>
    DataFolder: string;
    /// <summary>The folder of the original game (UFO or TFTD: GEODATA, GEOGRAPH...)</summary>
    GameFolder: string;
    /// <summary>The id of the master mod (xcom1, xcom2): the folder of standard\ with its rulesets</summary>
    ModId: string;
    /// <summary>Options::language; empty means the default en-US</summary>
    LanguageId: string;
    Wordwrap: TXcomTextWrapping;
  end;

  /// <summary>
  ///   Loads the resources of a master mod (palettes, fonts, interface rules) and the strings of the language (the
  ///   common file, the one of the mod and the extra strings of its rulesets). It runs in the loading thread, so it
  ///   only creates its own objects. The locale of the machine is not looked at (the language is the one in the
  ///   options, en-US when it is empty)
  /// </summary>
  TXcomModGameLoader = class(TInterfacedObject, IXcomGameLoader)
  strict private
    FSettings: TXcomLoaderSettings;
    FFiles: IXcomFileSystem;
    FParser: IYamlParser;
    FPng: TPngClient;
    FLog: IXcomLog;
    FLoadRules: Boolean;
  public
    /// <summary>
    ///   Also reads the ruleset of the master mod (IXcomGameRules of the resources), that the strategy screens need.
    ///   Off by default: the screens of the menu do not use it
    /// </summary>
    property LoadRules: Boolean read FLoadRules write FLoadRules;
    /// <param name="APng">Not owned: the client shared by the engine</param>
    constructor Create(const ASettings: TXcomLoaderSettings; const AFiles: IXcomFileSystem;
      const AParser: IYamlParser; APng: TPngClient; const ALog: IXcomLog = nil);
    procedure Load(out AResources: IXcomResources; out ALanguage: TXcomLanguage);
  end;

implementation

uses
  DelphiDoom.Yaml.Factory, DelphiDoom.Xcom.Intf, DelphiDoom.Xcom.Factory, DelphiDoom.XcomEngine.FileMap, DelphiDoom.XcomEngine.ModResources,
  DelphiDoom.XcomEngine.PngSurfaceLoader;

constructor TXcomModGameLoader.Create(const ASettings: TXcomLoaderSettings; const AFiles: IXcomFileSystem;
  const AParser: IYamlParser; APng: TPngClient; const ALog: IXcomLog);
begin
  inherited Create;
  FSettings := ASettings;
  FFiles := AFiles;
  FParser := AParser;
  FPng := APng;
  FLog := ALog;
end;

procedure TXcomModGameLoader.Load(out AResources: IXcomResources; out ALanguage: TXcomLanguage);
const
  DEFAULT_LANGUAGE = 'en-US';
var
  LMap: TXcomFileMap;
  LModFolder: string;
  LResources: TXcomModResources;
  LReference: IXcomResources;
  LGameData: IXcomGameData;
  LLanguageId: string;
  LLanguage: TXcomLanguage;
  LStrings: TDictionary<string, string>;
begin
  AResources := nil;
  ALanguage := nil;
  LModFolder := TPath.Combine(TPath.Combine(FSettings.DataFolder, 'standard'), FSettings.ModId);
  if not FFiles.FolderExists(LModFolder) then
    raise EXcomEngineException.Create('The mod ' + FSettings.ModId + ' is not in ' + FSettings.DataFolder);
  if not FFiles.FileExists(TPath.Combine(FSettings.GameFolder, 'GEODATA\PALETTES.DAT')) then
    raise EXcomEngineException.Create('No X-COM installation found in ' + FSettings.GameFolder);
  LMap := TXcomFileMap.Create(FFiles);
  LMap.AddRoot(TPath.Combine(FSettings.DataFolder, 'common'));
  LMap.AddRoot(FSettings.GameFolder);
  LMap.AddRoot(LModFolder);
  LGameData := TXcomFactory.CreateGameData(TXcomFactory.CreateFolderFiles([FSettings.GameFolder]));
  // the resources own the map from here
  LResources := TXcomModResources.Create(LMap, LGameData, FFiles, FParser,
    TXcomPngSurfaceLoader.Create(LMap, FPng), TXcomFactory.CreatePaletteReader, LModFolder);
  LReference := LResources;
  LResources.Load;
  if FLoadRules then
    LResources.LoadRules(TYamlFactory.CreateDiskParser, FPng, FSettings.ModId);
  LLanguageId := FSettings.LanguageId;
  if (LLanguageId = '') or
    (not FFiles.FileExists(TPath.Combine(TPath.Combine(FSettings.DataFolder, 'common\Language'),
    LLanguageId + '.yml'))) then
    LLanguageId := DEFAULT_LANGUAGE;
  LLanguage := TXcomLanguage.Create(LLanguageId, FSettings.Wordwrap, FFiles, FParser, FLog);
  try
    LLanguage.LoadFile(TPath.Combine(FSettings.DataFolder, 'common\Language\' + DEFAULT_LANGUAGE + '.yml'));
    if LLanguageId <> DEFAULT_LANGUAGE then
      LLanguage.LoadFile(TPath.Combine(FSettings.DataFolder, 'common\Language\' + LLanguageId + '.yml'));
    LLanguage.LoadFile(TPath.Combine(LModFolder, 'Language\' + DEFAULT_LANGUAGE + '.yml'));
    if LLanguageId <> DEFAULT_LANGUAGE then
      LLanguage.LoadFile(TPath.Combine(LModFolder, 'Language\' + LLanguageId + '.yml'));
    LStrings := LResources.ExtraStrings(DEFAULT_LANGUAGE);
    if Assigned(LStrings) then
      LLanguage.AddStrings(LStrings);
    if LLanguageId <> DEFAULT_LANGUAGE then
    begin
      LStrings := LResources.ExtraStrings(LLanguageId);
      if Assigned(LStrings) then
        LLanguage.AddStrings(LStrings);
    end;
  except
    LLanguage.Free;
    raise;
  end;
  AResources := LReference;
  ALanguage := LLanguage;
end;

end.
