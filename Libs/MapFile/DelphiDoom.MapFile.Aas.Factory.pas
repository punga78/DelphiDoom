{******************************************************************************}
{                                                                              }
{  DelphiDoom: map file library - the composition point of the .aas reader     }
{                                                                              }
{  Written for this library. Licensed under the GNU General Public License,    }
{  version 2 or later.                                                         }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapFile.Aas.Factory;

interface

uses
  DelphiDoom.IdLib.Core.Intf, DelphiDoom.MapFile.Aas.AasFile, DelphiDoom.MapFile.Aas.Intf;

type
  /// <summary>The only place that knows the concrete class of the .aas reader</summary>
  TAasFileFactory = class
  public
    /// <summary>A reader that takes its files from the file system (the log may be nil)</summary>
    class function CreateReader(const AFileSystem: IIdLibFileSystem; const ALog: IIdLibLog = nil): IAasFileReader; static;
    /// <summary>
    ///   A sampler on a file that is loaded. The file is borrowed: it must outlive the sampler
    /// </summary>
    class function CreateSampler(const AFile: TAasFile): IAasSampler; static;
    /// <summary>A writer that puts its files in the file system (the log may be nil)</summary>
    class function CreateWriter(const AFileSystem: IIdLibFileSystem; const ALog: IIdLibLog = nil): IAasFileWriter; static;
  end;

implementation

uses
  DelphiDoom.MapFile.Aas.FileReader, DelphiDoom.MapFile.Aas.FileWriter, DelphiDoom.MapFile.Aas.Sampler;

{ TAasFileFactory }

class function TAasFileFactory.CreateReader(const AFileSystem: IIdLibFileSystem;
  const ALog: IIdLibLog): IAasFileReader;
begin
  Result := TAasFileReader.Create(AFileSystem, ALog);
end;

class function TAasFileFactory.CreateSampler(const AFile: TAasFile): IAasSampler;
begin
  Result := TAasSampler.Create(AFile);
end;

class function TAasFileFactory.CreateWriter(const AFileSystem: IIdLibFileSystem;
  const ALog: IIdLibLog): IAasFileWriter;
begin
  Result := TAasFileWriter.Create(AFileSystem, ALog);
end;

end.
