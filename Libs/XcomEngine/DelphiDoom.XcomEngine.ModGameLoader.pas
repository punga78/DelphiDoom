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
  DelphiDoom.XcomEngine.Resources.Intf, DelphiDoom.XcomEngine.GameLoader.Intf,
  DelphiDoom.XcomSurface.FontOverlay.Intf;

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
    /// <summary>Folders laid over the data, the last one first: a Language\Font.dat in one of them replaces the fonts</summary>
    ExtraFolders: TArray<string>;
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
    FFontOverlay: IXcomFontOverlay;
  public
    /// <summary>
    ///   Also reads the ruleset of the master mod (IXcomGameRules of the resources), that the strategy screens need.
    ///   Off by default: the screens of the menu do not use it
    /// </summary>
    property LoadRules: Boolean read FLoadRules write FLoadRules;
    /// <summary>Given to the resources: the characters of the fonts from another source (nil: the pictures of the game)</summary>
    property FontOverlay: IXcomFontOverlay read FFontOverlay write FFontOverlay;
    /// <param name="APng">Not owned: the client shared by the engine</param>
    constructor Create(const ASettings: TXcomLoaderSettings; const AFiles: IXcomFileSystem;
      const AParser: IYamlParser; APng: TPngClient; const ALog: IXcomLog = nil);
    procedure Load(out AResources: IXcomResources; out ALanguage: TXcomLanguage);
  end;

implementation

uses
  DelphiDoom.Yaml.Factory, DelphiDoom.Xcom.Intf, DelphiDoom.Xcom.Factory, DelphiDoom.XcomEngine.FileMap, DelphiDoom.XcomEngine.ModResources,
  DelphiDoom.XcomEngine.PngSurfaceLoader, DelphiDoom.XcomEngine.FolderLanguageProvider,
  DelphiDoom.XcomEngine.LanguageProvider.Intf;

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
var
  LMap: TXcomFileMap;
  LModFolder: string;
  LResources: TXcomModResources;
  LReference: IXcomResources;
  LGameData: IXcomGameData;
  LProvider: IXcomLanguageProvider;
  LExtraFolder: string;
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
  for LExtraFolder in FSettings.ExtraFolders do
    LMap.AddRoot(LExtraFolder);
  LGameData := TXcomFactory.CreateGameData(TXcomFactory.CreateFolderFiles([FSettings.GameFolder]));
  // the resources own the map from here
  LResources := TXcomModResources.Create(LMap, LGameData, FFiles, FParser,
    TXcomPngSurfaceLoader.Create(LMap, FPng), TXcomFactory.CreatePaletteReader, LModFolder);
  LReference := LResources;
  LResources.FontOverlay := FFontOverlay;
  LResources.Load;
  if FLoadRules then
    LResources.LoadRules(TYamlFactory.CreateDiskParser, FPng, FSettings.ModId);
  // the language is the one of the provider of the menus (Game::loadLanguages): there is no second copy of the code
  LProvider := TXcomFolderLanguageProvider.Create(FSettings.DataFolder, LModFolder, FFiles, FParser, FLog);
  ALanguage := LProvider.Load(FSettings.LanguageId, FSettings.Wordwrap, LReference);
  AResources := LReference;
end;

end.
