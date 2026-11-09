{******************************************************************************}
{                                                                              }
{  DelphiDoom: Xcom32 - the composition root                                    }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Xcom.Composition;

interface

uses
  System.SysUtils, DelphiDoom.Xcom.Intf, DelphiDoom.Xcom.ImageExporter;

type
  /// <summary>
  ///   The one place of Xcom32 that knows the classes behind the interfaces: the xcom formats library and the
  ///   libraries that it shares with the Doom engine (video palette, PNG, files). It does not touch ComposeEngine
  ///   nor TIdTechGeneration: OpenXcom is not an id Tech game
  /// </summary>
  TXcomComposition = class
  public
    /// <summary>The data of the game in the given folders</summary>
    class function OpenGameData(const AFolders: array of string): IXcomGameData; static;
    /// <summary>What saves an image as a PNG file</summary>
    class function CreateImageExporter: TXcomImageExporter; static;
    /// <summary>The reader of .RMP files, that also turns the records into the nodes of a block</summary>
    class function CreateRouteReader: IXcomRouteReader; static;
    /// <summary>The reader of .LBM files (the battlescape palettes of TFTD)</summary>
    class function CreateLbmReader: IXcomLbmReader; static;
  end;

implementation

uses
  DelphiDoom.Xcom.Factory, DelphiDoom.Xcom.PngEncoder, DelphiDoom.Video.Factory, DelphiDoom.Png.Provider,
  DelphiDoom.Platform.Factory;

{ TXcomComposition }

class function TXcomComposition.OpenGameData(const AFolders: array of string): IXcomGameData;
begin
  Result := TXcomFactory.CreateGameData(TXcomFactory.CreateFolderFiles(AFolders));
end;

class function TXcomComposition.CreateImageExporter: TXcomImageExporter;
begin
  Result := TXcomImageExporter.Create(
    TXcomPngEncoder.Create(TVideoFactory.CreatePaletteConverter, TPngProvider.Client),
    TPlatformFactory.CreateFileStore);
end;

class function TXcomComposition.CreateLbmReader: IXcomLbmReader;
begin
  Result := TXcomFactory.CreateLbmReader;
end;

class function TXcomComposition.CreateRouteReader: IXcomRouteReader;
begin
  Result := TXcomFactory.CreateRouteReader;
end;

end.
