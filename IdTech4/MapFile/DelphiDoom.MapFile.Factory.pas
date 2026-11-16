{******************************************************************************}
{                                                                              }
{  DelphiDoom: map file library - the composition point                        }
{                                                                              }
{  Written for this library. Licensed under the GNU General Public License,    }
{  version 2 or later.                                                         }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapFile.Factory;

interface

uses
  DelphiDoom.IdLib.Core.Intf, DelphiDoom.MapFile.Intf;

type
  /// <summary>The only place that knows the concrete classes of the library</summary>
  TMapFileFactory = class
  public
    /// <summary>A reader that takes its files from the file system (the log may be nil)</summary>
    class function CreateReader(const AFileSystem: IIdLibFileSystem; const ALog: IIdLibLog = nil): IMapFileReader; static;
    /// <summary>A writer that puts its files into the file system (the log may be nil)</summary>
    class function CreateWriter(const AFileSystem: IIdLibFileSystem; const ALog: IIdLibLog = nil): IMapFileWriter; static;
    /// <summary>A writer of the format of Quake III Arena (brushes of three points, patchDef2, no version)</summary>
    class function CreateQ3Writer(const AFileSystem: IIdLibFileSystem; const ALog: IIdLibLog = nil): IMapFileWriter; static;
  end;

implementation

uses
  DelphiDoom.MapFile.FileReader, DelphiDoom.MapFile.FileWriter, DelphiDoom.MapFile.Q3FileWriter;

{ TMapFileFactory }

class function TMapFileFactory.CreateReader(const AFileSystem: IIdLibFileSystem;
  const ALog: IIdLibLog): IMapFileReader;
begin
  Result := TMapFileReader.Create(AFileSystem, ALog);
end;

class function TMapFileFactory.CreateWriter(const AFileSystem: IIdLibFileSystem;
  const ALog: IIdLibLog): IMapFileWriter;
begin
  Result := TMapFileWriter.Create(AFileSystem, ALog);
end;

class function TMapFileFactory.CreateQ3Writer(const AFileSystem: IIdLibFileSystem;
  const ALog: IIdLibLog): IMapFileWriter;
begin
  Result := TMapQ3FileWriter.Create(AFileSystem, ALog);
end;

end.
