{******************************************************************************}
{                                                                              }
{  DelphiDoom: map file library - the composition point of the .proc classes   }
{                                                                              }
{  Written for this library. Licensed under the GNU General Public License,    }
{  version 2 or later.                                                         }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapFile.Proc.Factory;

interface

uses
  DelphiDoom.IdLib.Core.Intf, DelphiDoom.MapFile.Proc.Intf;

type
  /// <summary>The only place that knows the concrete classes of the .proc reader and writer</summary>
  TProcFileFactory = class
  public
    /// <summary>A reader that takes its files from the file system (the log may be nil)</summary>
    class function CreateReader(const AFileSystem: IIdLibFileSystem; const ALog: IIdLibLog = nil): IProcFileReader; static;
    /// <summary>A writer that puts its files into the file system (the log may be nil)</summary>
    class function CreateWriter(const AFileSystem: IIdLibFileSystem; const ALog: IIdLibLog = nil): IProcFileWriter; static;
  end;

implementation

uses
  DelphiDoom.MapFile.Proc.FileReader, DelphiDoom.MapFile.Proc.FileWriter;

{ TProcFileFactory }

class function TProcFileFactory.CreateReader(const AFileSystem: IIdLibFileSystem;
  const ALog: IIdLibLog): IProcFileReader;
begin
  Result := TProcFileReader.Create(AFileSystem, ALog);
end;

class function TProcFileFactory.CreateWriter(const AFileSystem: IIdLibFileSystem;
  const ALog: IIdLibLog): IProcFileWriter;
begin
  Result := TProcFileWriter.Create(AFileSystem, ALog);
end;

end.
