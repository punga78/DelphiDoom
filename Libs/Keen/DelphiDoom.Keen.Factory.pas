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
    /// <summary>The 4 planes of the video memory of the EGA</summary>
    class function CreateEgaMemory: IKeenEgaMemory; static;
    /// <summary>The video manager (id_vw): AGraphics and ASprites can be nil for a manager that draws only blocks and pixels</summary>
    class function CreateVideo(const AMemory: IKeenEgaMemory; const AGraphics: IKeenGraphics;
      const ASprites: IKeenSpriteCache): IKeenVideo; static;
    /// <summary>The sprites of the graphics, with their shifted copies</summary>
    class function CreateSpriteCache(const AGraphics: IKeenGraphics): IKeenSpriteCache; static;
    /// <summary>The map that is played, a copy of a map of the file</summary>
    class function CreateWorkingMap(const AMap: IKeenMap): IKeenWorkingMap; static;
    /// <summary>The tile refresh manager (id_rf)</summary>
    class function CreateRefresh(const AVideo: IKeenVideo; const AGraphics: IKeenGraphics;
      const ATileInfo: IKeenTileInfo; const ASprites: IKeenSpriteCache; const AClock: IKeenClock;
      ACompatibility: Boolean = False): IKeenRefresh; static;
    /// <summary>The input manager (id_in): AMouse, AJoysticks and APump can be nil</summary>
    class function CreateInput(const AClock: IKeenClock; const AMouse: IKeenMouse; const AJoysticks: IKeenJoysticks;
      const APump: IKeenInputPump): IKeenInput; static;
    /// <summary>The random numbers of the game (US_RndT)</summary>
    class function CreateRandom: IKeenRandom; static;
    /// <summary>A copy of the table of the 213 states of the actors</summary>
    class function CreateGameStateTable: IKeenStateTable; static;
    /// <summary>The list of the actors (objarray), with the player and the score box</summary>
    class function CreateObjectList(const ARefresh: IKeenRefresh): IKeenObjectList; static;
    /// <summary>Opens the three files with their headers and dictionaries</summary>
    class function OpenGameData(const AFiles: IKeenDataFiles): IKeenGameData; static;
  end;

implementation

uses
  DelphiDoom.Platform.FolderFiles.Factory,
  DelphiDoom.Keen.Huffman, DelphiDoom.Keen.Rlew, DelphiDoom.Keen.FolderFiles, DelphiDoom.Keen.OffsetTable,
  DelphiDoom.Keen.GraphicsLayout, DelphiDoom.Keen.ExplicitLayout, DelphiDoom.Keen.ChunkSource,
  DelphiDoom.Keen.MapSource, DelphiDoom.Keen.Graphics, DelphiDoom.Keen.MapRenderer,
  DelphiDoom.Keen.GameLoader, DelphiDoom.Keen.EgaMemory, DelphiDoom.Keen.Video, DelphiDoom.Keen.SpriteCache,
  DelphiDoom.Keen.WorkingMap, DelphiDoom.Keen.Refresh, DelphiDoom.Keen.Input, DelphiDoom.Keen.Random,
  DelphiDoom.Keen.StateTableCopy, DelphiDoom.Keen.ObjectList;

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
  Result := TKeenFolderFiles.Create(TFolderFilesFactory.CreateFolderFiles(AFolders));
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

class function TKeenFactory.CreateEgaMemory: IKeenEgaMemory;
begin
  Result := TKeenEgaMemory.Create;
end;

class function TKeenFactory.CreateVideo(const AMemory: IKeenEgaMemory; const AGraphics: IKeenGraphics;
  const ASprites: IKeenSpriteCache): IKeenVideo;
begin
  Result := TKeenVideo.Create(AMemory, AGraphics, ASprites);
end;

class function TKeenFactory.CreateSpriteCache(const AGraphics: IKeenGraphics): IKeenSpriteCache;
begin
  Result := TKeenSpriteCache.Create(AGraphics);
end;

class function TKeenFactory.CreateWorkingMap(const AMap: IKeenMap): IKeenWorkingMap;
begin
  Result := TKeenWorkingMap.Create(AMap);
end;

class function TKeenFactory.CreateRefresh(const AVideo: IKeenVideo; const AGraphics: IKeenGraphics;
  const ATileInfo: IKeenTileInfo; const ASprites: IKeenSpriteCache; const AClock: IKeenClock;
  ACompatibility: Boolean): IKeenRefresh;
begin
  Result := TKeenRefresh.Create(AVideo, AGraphics, ATileInfo, ASprites, AClock, ACompatibility);
end;

class function TKeenFactory.CreateInput(const AClock: IKeenClock; const AMouse: IKeenMouse;
  const AJoysticks: IKeenJoysticks; const APump: IKeenInputPump): IKeenInput;
begin
  Result := TKeenInput.Create(AClock, AMouse, AJoysticks, APump);
end;

class function TKeenFactory.CreateRandom: IKeenRandom;
begin
  Result := TKeenRandom.Create;
end;

class function TKeenFactory.CreateGameStateTable: IKeenStateTable;
begin
  Result := TKeenStateTableCopy.CreateGameStates;
end;

class function TKeenFactory.CreateObjectList(const ARefresh: IKeenRefresh): IKeenObjectList;
begin
  Result := TKeenObjectList.Create(ARefresh);
end;

class function TKeenFactory.OpenGameData(const AFiles: IKeenDataFiles): IKeenGameData;
begin
  Result := TKeenGameLoader.Open(AFiles);
end;

end.
