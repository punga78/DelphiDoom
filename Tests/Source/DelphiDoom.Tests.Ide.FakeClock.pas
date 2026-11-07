{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the ide library - a clock that stands still            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Ide.FakeClock;

interface

uses
  DelphiDoom.Ide.Intf;

type
  /// <summary>Always tells the same moment: 4 March 2022, 10:30</summary>
  TFakeIdeClock = class(TInterfacedObject, IIdeClock)
  public
    /// <summary>The date of the clock in the form of the backup of a file</summary>
    const BACKUP_DATE = '20220304';
    function Now: TDateTime;
  end;

implementation

uses
  System.SysUtils;

{ TFakeIdeClock }

function TFakeIdeClock.Now: TDateTime;
begin
  Result := EncodeDate(2022, 3, 4) + EncodeTime(10, 30, 0, 0);
end;

end.
