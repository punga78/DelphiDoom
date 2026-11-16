{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom engine library - the trace of the reads and writes of the  }
{  options file (issue 186)                                                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomEngine.OptionsAudit.Intf;

interface

type
  /// <summary>
  ///   Where the options file says what it reads and writes, and for whom (OK, defaults, exit...). It exists to find out
  ///   when an option comes back to an old value; a store without one writes nothing
  /// </summary>
  IXcomOptionsAudit = interface
    ['{4E7A1B52-0C93-4D68-A5F1-186000000001}']
    /// <summary>The trace of a read or a write (written only when the trace is on)</summary>
    /// <param name="AReason">Who asked: "ok", "defaults", "confirm-revert", "mods-ok", "exit"...</param>
    /// <param name="AMessage">What happened, one line</param>
    procedure Report(const AReason, AMessage: string);
    /// <summary>Something the player should be able to find out even without the trace (a file that was not readable)</summary>
    procedure Warning(const AMessage: string);
  end;

implementation

end.
