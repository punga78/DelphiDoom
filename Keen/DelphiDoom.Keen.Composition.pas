{******************************************************************************}
{                                                                              }
{  DelphiDoom: Keen32 - the composition root                                    }
{  Port of Commander Keen in Keen Dreams (id Software), GPL v2 or later         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.Composition;

interface

uses
  System.SysUtils, DelphiDoom.Keen.Intf;

type
  /// <summary>
  ///   The one place of Keen32 that knows the classes behind the interfaces: the libraries of the keen port
  ///   (Libs\Keen) and the ones that it shares with the Doom engine (video palette, PNG, files). It does not touch
  ///   ComposeEngine nor TIdTechGeneration: Keen Dreams is not an id Tech 1 game
  /// </summary>
  TKeenComposition = class
  public
    /// <summary>The data files in the given folders, opened</summary>
    class function OpenGameData(const AFolders: array of string): IKeenGameData; static;
    /// <summary>What saves the picture of a map of ADataFolders as a PNG file</summary>
    class function CreateMapExporter(const AData: IKeenGameData): IKeenMapExporter; static;
    /// <summary>What saves the screen of the game (the tile refresh manager on the EGA memory) for a map and a position</summary>
    class function CreateViewExporter(const AData: IKeenGameData): IKeenViewExporter; static;
  end;

implementation

uses
  DelphiDoom.Keen.Factory, DelphiDoom.Keen.PngEncoder, DelphiDoom.Keen.MapExporter, DelphiDoom.Keen.ViewExporter,
  DelphiDoom.Video.Factory, DelphiDoom.Png.Provider, DelphiDoom.Platform.Factory;

{ TKeenComposition }

class function TKeenComposition.OpenGameData(const AFolders: array of string): IKeenGameData;
begin
  Result := TKeenFactory.OpenGameData(TKeenFactory.CreateFolderFiles(AFolders));
end;

class function TKeenComposition.CreateMapExporter(const AData: IKeenGameData): IKeenMapExporter;
begin
  Result := TKeenMapExporter.Create(AData, TKeenFactory.CreateMapRenderer,
    TKeenPngEncoder.Create(TVideoFactory.CreatePaletteConverter, TPngProvider.Client),
    TPlatformFactory.CreateFileStore);
end;

class function TKeenComposition.CreateViewExporter(const AData: IKeenGameData): IKeenViewExporter;
begin
  Result := TKeenViewExporter.Create(AData,
    TKeenPngEncoder.Create(TVideoFactory.CreatePaletteConverter, TPngProvider.Client),
    TPlatformFactory.CreateFileStore);
end;

end.
