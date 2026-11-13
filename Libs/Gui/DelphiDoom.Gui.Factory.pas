{******************************************************************************}
{                                                                              }
{  DelphiDoom: Gui library - the one place that knows the concrete classes     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Gui.Factory;

interface

uses
  DelphiDoom.Gui.Intf, DelphiDoom.Gui.MenuSet, DelphiDoom.Gui.FontRegistry, DelphiDoom.Gui.MenuFileReader,
  DelphiDoom.Gui.ScriptRunner, DelphiDoom.IdLib.Core.Intf;

type
  /// <summary>Builds the objects of the library from the services the caller owns</summary>
  TGuiFactory = class
  public
    /// <summary>The loader of menu files over idParser; the messages of the parser go to the log (nil: silence)</summary>
    class function CreateSourceLoader(const AFileSystem: IIdLibFileSystem; const ALog: IGuiLog = nil): IGuiSourceLoader;
      static;
    class function CreateFontRegistry(const AFileSystem: IIdLibFileSystem; const AAssets: IGuiAssetRegistry;
      const ALog: IGuiLog = nil): TGuiFontRegistry; static;
    class function CreateMenuSet(const AAssets: IGuiAssetRegistry; const AFonts: TGuiFontRegistry;
      const ARandom: IGuiRandom = nil): TGuiMenuSet; static;
    class function CreateMenuFileReader(const ALoader: IGuiSourceLoader; const AMenus: TGuiMenuSet;
      const ALog: IGuiLog = nil): TGuiMenuFileReader; static;
    class function CreateScriptRunner(const AMenus: TGuiMenuSet; const AHost: IGuiScriptHost;
      const AMedia: IGuiMediaHost): TGuiScriptRunner; static;
  end;

implementation

uses
  DelphiDoom.Gui.PrecompilerLoader, DelphiDoom.Gui.IdLibLog;

class function TGuiFactory.CreateSourceLoader(const AFileSystem: IIdLibFileSystem;
  const ALog: IGuiLog): IGuiSourceLoader;
begin
  Result := TGuiPrecompilerLoader.Create(AFileSystem, TGuiIdLibLog.Create(ALog));
end;

class function TGuiFactory.CreateFontRegistry(const AFileSystem: IIdLibFileSystem;
  const AAssets: IGuiAssetRegistry; const ALog: IGuiLog): TGuiFontRegistry;
begin
  Result := TGuiFontRegistry.Create(AFileSystem, AAssets, ALog);
end;

class function TGuiFactory.CreateMenuSet(const AAssets: IGuiAssetRegistry; const AFonts: TGuiFontRegistry;
  const ARandom: IGuiRandom): TGuiMenuSet;
begin
  Result := TGuiMenuSet.Create(AAssets, AFonts, ARandom);
end;

class function TGuiFactory.CreateMenuFileReader(const ALoader: IGuiSourceLoader; const AMenus: TGuiMenuSet;
  const ALog: IGuiLog): TGuiMenuFileReader;
begin
  Result := TGuiMenuFileReader.Create(ALoader, AMenus, ALog);
end;

class function TGuiFactory.CreateScriptRunner(const AMenus: TGuiMenuSet; const AHost: IGuiScriptHost;
  const AMedia: IGuiMediaHost): TGuiScriptRunner;
begin
  Result := TGuiScriptRunner.Create(AMenus.Assets, AMenus.Registry, AMenus.Strings, AHost, AMedia);
end;

end.
