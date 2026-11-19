{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III program - the time of the main loop                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Quake3.Clock.Intf;

interface

type
  /// <summary>
  ///   Sys_Milliseconds and Sys_Sleep for the main loop: the time is a number of milliseconds that only goes
  ///   forward, and waiting is a call to the clock, so the tests move the time instead of waiting
  /// </summary>
  IQ3Clock = interface
    ['{5B3E8A17-C4D2-4F90-9E61-7A0D2C85B3F4}']
    /// <summary>Milliseconds since the first reading</summary>
    function Milliseconds: Integer;
    /// <summary>Lets the processor rest for about AMilliseconds (a fake clock just moves forward)</summary>
    procedure Sleep(AMilliseconds: Integer);
  end;

implementation

end.
