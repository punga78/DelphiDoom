{******************************************************************************}
{                                                                              }
{  DelphiDoom: keen library - the factory: the composition root of the library  }
{  Port of Commander Keen in Keen Dreams (id Software), GPL v2 or later         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.Factory;

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.Keen.Intf;

type
  /// <summary>The only place that knows the classes behind the contracts of the keen library</summary>
  TKeenFactory = class
  public
    /// <param name="ADictionary">The bytes of a .KDR dictionary</param>
    class function CreateHuffman(const ADictionary: TBytes): IKeenHuffman; static;
    class function CreateRlew: IKeenRlew; static;
    /// <summary>The files in the folders; a file is taken from the first folder that has it</summary>
    class function CreateFolderFiles(const AFolders: array of string): IKeenDataFiles; static;
    /// <summary>The offsets of EGAHEAD or AUDIOHHD</summary>
    class function CreateOffsetTable(const ABytes: TBytes; const AName: string): IKeenOffsetTable; static;
    /// <summary>The chunks of KDREAMS.EGA; the source owns AStream</summary>
    class function CreateGraphicsChunks(const AOffsets: IKeenOffsetTable; const AHuffman: IKeenHuffman;
      AStream: TStream): IKeenChunkSource; static;
    /// <summary>The chunks of KDREAMS.AUD; the source owns AStream</summary>
    class function CreateAudioChunks(const AOffsets: IKeenOffsetTable; const AHuffman: IKeenHuffman;
      AStream: TStream): IKeenChunkSource; static;
    /// <summary>The maps of KDREAMS.MAP; the source owns AStream</summary>
    class function CreateMapSource(const AMapHeader: TBytes; const AHuffman: IKeenHuffman;
      AStream: TStream): IKeenMapSource; static;
    class function CreateGraphics(const AChunks: IKeenChunkSource): IKeenGraphics; static;
    class function CreateMapRenderer: IKeenMapRenderer; static;
    /// <summary>Opens the three files with their headers and dictionaries</summary>
    class function OpenGameData(const AFiles: IKeenDataFiles): IKeenGameData; static;
  end;

implementation

uses
  DelphiDoom.Keen.Huffman, DelphiDoom.Keen.Rlew, DelphiDoom.Keen.FolderFiles, DelphiDoom.Keen.OffsetTable,
  DelphiDoom.Keen.GraphicsLayout, DelphiDoom.Keen.ExplicitLayout, DelphiDoom.Keen.ChunkSource,
  DelphiDoom.Keen.MapSource, DelphiDoom.Keen.Graphics, DelphiDoom.Keen.MapRenderer,
  DelphiDoom.Keen.GameLoader;

{ TKeenFactory }

class function TKeenFactory.CreateHuffman(const ADictionary: TBytes): IKeenHuffman;
begin
  Result := TKeenHuffman.Create(ADictionary);
end;

class function TKeenFactory.CreateRlew: IKeenRlew;
begin
  Result := TKeenRlew.Create;
end;

class function TKeenFactory.CreateFolderFiles(const AFolders: array of string): IKeenDataFiles;
begin
  Result := TKeenFolderFiles.Create(AFolders);
end;

class function TKeenFactory.CreateOffsetTable(const ABytes: TBytes;
  const AName: string): IKeenOffsetTable;
begin
  Result := TKeenOffsetTable.Create(ABytes, AName);
end;

class function TKeenFactory.CreateGraphicsChunks(const AOffsets: IKeenOffsetTable;
  const AHuffman: IKeenHuffman; AStream: TStream): IKeenChunkSource;
begin
  Result := TKeenChunkSource.Create(AOffsets, AHuffman, TKeenGraphicsLayout.Create, AStream);
end;

class function TKeenFactory.CreateAudioChunks(const AOffsets: IKeenOffsetTable;
  const AHuffman: IKeenHuffman; AStream: TStream): IKeenChunkSource;
begin
  Result := TKeenChunkSource.Create(AOffsets, AHuffman, TKeenExplicitLayout.Create(True), AStream);
end;

class function TKeenFactory.CreateMapSource(const AMapHeader: TBytes; const AHuffman: IKeenHuffman;
  AStream: TStream): IKeenMapSource;
begin
  Result := TKeenMapSource.Create(AMapHeader, AHuffman, TKeenRlew.Create, AStream);
end;

class function TKeenFactory.CreateGraphics(const AChunks: IKeenChunkSource): IKeenGraphics;
begin
  Result := TKeenGraphics.Create(AChunks);
end;

class function TKeenFactory.CreateMapRenderer: IKeenMapRenderer;
begin
  Result := TKeenMapRenderer.Create;
end;

class function TKeenFactory.OpenGameData(const AFiles: IKeenDataFiles): IKeenGameData;
begin
  Result := TKeenGameLoader.Open(AFiles);
end;

end.
