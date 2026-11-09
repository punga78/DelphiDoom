{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the factory of the library                       }
{  Port of xGreed (Jim Valavanis, GPL v2 or later)                              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.Factory;

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.Greed.Intf;

type
  /// <summary>The only place that knows the classes behind the contracts of the greed library</summary>
  TGreedFactory = class
  public
    /// <summary>The corrections of the data that the original applies (the sprite "pst")</summary>
    class function CreateLumpFixes: IGreedLumpFixes; static;
    /// <summary>The archive in AStream; it is owned by the archive if AOwnsStream. AFixes nil: no corrections</summary>
    class function OpenArchive(AStream: TStream; AOwnsStream: Boolean; const AFixes: IGreedLumpFixes): IGreedArchive; static;
    /// <summary>The archive in a file, with the corrections of the original</summary>
    class function OpenArchiveFile(const APath: string): IGreedArchive; static;
    /// <summary>The files in the folders; a file is taken from the first folder that has it</summary>
    class function CreateFolderFiles(const AFolders: array of string): IGreedExternalFiles; static;
    class function CreateMapReader: IGreedMapReader; static;
    /// <param name="AFiles">Where the maps of the empty lumps are; nil if nowhere</param>
    class function CreateMapLoader(const AArchive: IGreedArchive; const AFiles: IGreedExternalFiles): IGreedMapLoader; static;
    class function CreateLumpClassifier(const AArchive: IGreedArchive): IGreedLumpClassifier; static;
    class function CreateMapRenderer(const AArchive: IGreedArchive): IGreedMapRenderer; static;
  end;

implementation

uses
  DelphiDoom.Greed.LumpFixes, DelphiDoom.Greed.BloArchive, DelphiDoom.Greed.FolderFiles,
  DelphiDoom.Greed.MapReader, DelphiDoom.Greed.MapLoader, DelphiDoom.Greed.LumpClassifier,
  DelphiDoom.Greed.MapRenderer, DelphiDoom.Greed.FlatDecoder, DelphiDoom.Greed.WallDecoder;

{ TGreedFactory }

class function TGreedFactory.CreateLumpFixes: IGreedLumpFixes;
begin
  Result := TGreedLumpFixes.CreateDefault;
end;

class function TGreedFactory.OpenArchive(AStream: TStream; AOwnsStream: Boolean;
  const AFixes: IGreedLumpFixes): IGreedArchive;
begin
  Result := TGreedBloArchive.Create(AStream, AOwnsStream, AFixes);
end;

class function TGreedFactory.OpenArchiveFile(const APath: string): IGreedArchive;
var
  LStream: TFileStream;
begin
  LStream := TFileStream.Create(APath, fmOpenRead or fmShareDenyWrite);
  // the archive owns the stream, also when it cannot read it (it frees it before it raises)
  Result := TGreedBloArchive.Create(LStream, True, CreateLumpFixes);
end;

class function TGreedFactory.CreateFolderFiles(const AFolders: array of string): IGreedExternalFiles;
begin
  Result := TGreedFolderFiles.Create(AFolders);
end;

class function TGreedFactory.CreateMapReader: IGreedMapReader;
begin
  Result := TGreedMapReader.Create;
end;

class function TGreedFactory.CreateMapLoader(const AArchive: IGreedArchive;
  const AFiles: IGreedExternalFiles): IGreedMapLoader;
begin
  Result := TGreedMapLoader.Create(AArchive, CreateMapReader, AFiles);
end;

class function TGreedFactory.CreateLumpClassifier(const AArchive: IGreedArchive): IGreedLumpClassifier;
begin
  Result := TGreedLumpClassifier.Create(AArchive);
end;

class function TGreedFactory.CreateMapRenderer(const AArchive: IGreedArchive): IGreedMapRenderer;
begin
  Result := TGreedMapRenderer.Create(AArchive, TGreedFlatDecoder.Create, TGreedWallDecoder.Create);
end;

end.
