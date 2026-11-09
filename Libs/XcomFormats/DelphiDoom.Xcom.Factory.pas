{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom formats library - the factory: the composition root         }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Xcom.Factory;

interface

uses
  System.SysUtils, DelphiDoom.Xcom.Intf;

type
  /// <summary>The only place that knows the classes behind the contracts of the xcom formats library</summary>
  TXcomFactory = class
  public
    /// <summary>The files in the folders; a file is taken from the first folder that has it</summary>
    class function CreateFolderFiles(const AFolders: array of string): IXcomDataFiles; static;
    class function CreateScrDecoder: IXcomImageDecoder; static;
    class function CreateSpkDecoder: IXcomImageDecoder; static;
    class function CreateBdyDecoder: IXcomImageDecoder; static;
    class function CreatePckDecoder: IXcomPckDecoder; static;
    class function CreateDatDecoder: IXcomDatDecoder; static;
    class function CreatePaletteReader: IXcomPaletteReader; static;
    /// <param name="ABytes">The whole .CAT file</param>
    class function CreateCatArchive(const ABytes: TBytes): IXcomCatArchive; static;
    class function CreateMapReader: IXcomMapReader; static;
    class function CreateRouteReader: IXcomRouteReader; static;
    class function CreateMcdReader: IXcomMcdReader; static;
    class function CreateWorldReader: IXcomWorldReader; static;
    class function CreateWordTableReader: IXcomWordTableReader; static;
    class function CreateLbmReader: IXcomLbmReader; static;
    /// <summary>The data of the game in the given files, with all the readers</summary>
    class function CreateGameData(const AFiles: IXcomDataFiles): IXcomGameData; static;
  end;

implementation

uses
  DelphiDoom.Xcom.FolderFiles, DelphiDoom.Xcom.ScrDecoder, DelphiDoom.Xcom.SpkDecoder, DelphiDoom.Xcom.BdyDecoder,
  DelphiDoom.Xcom.PckDecoder, DelphiDoom.Xcom.DatDecoder, DelphiDoom.Xcom.PaletteReader, DelphiDoom.Xcom.CatArchive,
  DelphiDoom.Xcom.MapReader, DelphiDoom.Xcom.RouteReader, DelphiDoom.Xcom.McdReader, DelphiDoom.Xcom.WorldReader,
  DelphiDoom.Xcom.WordTableReader, DelphiDoom.Xcom.LbmReader, DelphiDoom.Xcom.GameData;

{ TXcomFactory }

class function TXcomFactory.CreateFolderFiles(const AFolders: array of string): IXcomDataFiles;
begin
  Result := TXcomFolderFiles.Create(AFolders);
end;

class function TXcomFactory.CreateScrDecoder: IXcomImageDecoder;
begin
  Result := TXcomScrDecoder.Create;
end;

class function TXcomFactory.CreateSpkDecoder: IXcomImageDecoder;
begin
  Result := TXcomSpkDecoder.Create;
end;

class function TXcomFactory.CreateBdyDecoder: IXcomImageDecoder;
begin
  Result := TXcomBdyDecoder.Create;
end;

class function TXcomFactory.CreatePckDecoder: IXcomPckDecoder;
begin
  Result := TXcomPckDecoder.Create;
end;

class function TXcomFactory.CreateDatDecoder: IXcomDatDecoder;
begin
  Result := TXcomDatDecoder.Create;
end;

class function TXcomFactory.CreatePaletteReader: IXcomPaletteReader;
begin
  Result := TXcomPaletteReader.Create;
end;

class function TXcomFactory.CreateCatArchive(const ABytes: TBytes): IXcomCatArchive;
begin
  Result := TXcomCatArchive.Create(ABytes);
end;

class function TXcomFactory.CreateMapReader: IXcomMapReader;
begin
  Result := TXcomMapReader.Create;
end;

class function TXcomFactory.CreateRouteReader: IXcomRouteReader;
begin
  Result := TXcomRouteReader.Create;
end;

class function TXcomFactory.CreateMcdReader: IXcomMcdReader;
begin
  Result := TXcomMcdReader.Create;
end;

class function TXcomFactory.CreateWorldReader: IXcomWorldReader;
begin
  Result := TXcomWorldReader.Create;
end;

class function TXcomFactory.CreateLbmReader: IXcomLbmReader;
begin
  Result := TXcomLbmReader.Create;
end;

class function TXcomFactory.CreateWordTableReader: IXcomWordTableReader;
begin
  Result := TXcomWordTableReader.Create;
end;

class function TXcomFactory.CreateGameData(const AFiles: IXcomDataFiles): IXcomGameData;
begin
  Result := TXcomGameData.Create(AFiles, CreatePaletteReader, CreateScrDecoder, CreateSpkDecoder,
    CreateBdyDecoder, CreatePckDecoder, CreateDatDecoder, CreateMapReader, CreateRouteReader, CreateMcdReader);
end;

end.
