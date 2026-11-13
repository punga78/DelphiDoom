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
  DelphiDoom.IdLib.Core.Intf, DelphiDoom.MapFile.Aas.Intf;

type
  /// <summary>The only place that knows the concrete class of the .aas reader</summary>
  TAasFileFactory = class
  public
    /// <summary>A reader that takes its files from the file system (the log may be nil)</summary>
    class function CreateReader(const AFileSystem: IIdLibFileSystem; const ALog: IIdLibLog = nil): IAasFileReader; static;
  end;

implementation

uses
  DelphiDoom.MapFile.Aas.FileReader;

{ TAasFileFactory }

class function TAasFileFactory.CreateReader(const AFileSystem: IIdLibFileSystem;
  const ALog: IIdLibLog): IAasFileReader;
begin
  Result := TAasFileReader.Create(AFileSystem, ALog);
end;

end.
