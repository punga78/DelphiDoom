{******************************************************************************}
{                                                                              }
{  DelphiDoom: keen library - opens the files of the game                       }
{  Port of Commander Keen in Keen Dreams (id Software), GPL v2 or later:        }
{  CA_Startup of id_ca.c                                                        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.GameLoader;

interface

uses
  System.SysUtils, DelphiDoom.Keen.Intf;

type
  /// <summary>
  ///   Finds the three data files and their headers and dictionaries (the names of TKeenFileNames), and builds
  ///   the sources on them. Used by the factory
  /// </summary>
  TKeenGameLoader = class
  public
    class function Open(const AFiles: IKeenDataFiles): IKeenGameData; static;
  end;

implementation

uses
  System.Classes, DelphiDoom.Keen.FileNames, DelphiDoom.Keen.Huffman, DelphiDoom.Keen.Rlew,
  DelphiDoom.Keen.OffsetTable, DelphiDoom.Keen.GraphicsLayout, DelphiDoom.Keen.ExplicitLayout,
  DelphiDoom.Keen.ChunkSource, DelphiDoom.Keen.MapSource, DelphiDoom.Keen.Graphics,
  DelphiDoom.Keen.GameData;

{ TKeenGameLoader }

class function TKeenGameLoader.Open(const AFiles: IKeenDataFiles): IKeenGameData;
var
  LGraphicsName: string;
  LMapsName: string;
  LAudioName: string;
  LGraphicsHeader: string;
  LAudioHeader: string;
  LGraphicsChunks: IKeenChunkSource;
  LAudioChunks: IKeenChunkSource;
  LMaps: IKeenMapSource;
  LStream: TStream;
begin
  if not Assigned(AFiles) then
    raise EArgumentNilException.Create('AFiles');
  // every name is looked for before a file is opened: a missing one stops the loading with nothing left open
  LGraphicsName := TKeenFileNames.Resolve(AFiles, TKeenFileNames.GraphicsData);
  LGraphicsHeader := TKeenFileNames.Resolve(AFiles, TKeenFileNames.GraphicsHeader);
  LMapsName := TKeenFileNames.Resolve(AFiles, TKeenFileNames.MapData);
  LAudioName := TKeenFileNames.Resolve(AFiles, TKeenFileNames.AudioData);
  LAudioHeader := TKeenFileNames.Resolve(AFiles, TKeenFileNames.AudioHeader);
  TKeenFileNames.Resolve(AFiles, TKeenFileNames.GraphicsDictionary);
  TKeenFileNames.Resolve(AFiles, TKeenFileNames.MapHeader);
  TKeenFileNames.Resolve(AFiles, TKeenFileNames.MapDictionary);
  TKeenFileNames.Resolve(AFiles, TKeenFileNames.AudioDictionary);

  LStream := AFiles.OpenStream(LGraphicsName);
  try
    LGraphicsChunks := TKeenChunkSource.Create(
      TKeenOffsetTable.Create(AFiles.ReadAll(LGraphicsHeader), LGraphicsHeader),
      TKeenHuffman.Create(AFiles.ReadAll(TKeenFileNames.GraphicsDictionary[0])),
      TKeenGraphicsLayout.Create, LStream);
  except
    LStream.Free;
    raise;
  end;
  LStream := AFiles.OpenStream(LMapsName);
  try
    LMaps := TKeenMapSource.Create(AFiles.ReadAll(TKeenFileNames.MapHeader[0]),
      TKeenHuffman.Create(AFiles.ReadAll(TKeenFileNames.MapDictionary[0])), TKeenRlew.Create, LStream);
  except
    LStream.Free;
    raise;
  end;
  LStream := AFiles.OpenStream(LAudioName);
  try
    LAudioChunks := TKeenChunkSource.Create(
      TKeenOffsetTable.Create(AFiles.ReadAll(LAudioHeader), LAudioHeader),
      TKeenHuffman.Create(AFiles.ReadAll(TKeenFileNames.AudioDictionary[0])),
      TKeenExplicitLayout.Create(True), LStream);
  except
    LStream.Free;
    raise;
  end;
  Result := TKeenGameData.Create(TKeenGraphics.Create(LGraphicsChunks), LMaps, LAudioChunks);
end;

end.
