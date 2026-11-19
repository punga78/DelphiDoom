{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III program - Sys_Milliseconds for the game modules       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Quake3.HostTime;

interface

uses
  DelphiDoom.Q3Host.Intf, DelphiDoom.Quake3.Clock.Intf;

type
  /// <summary>The time the host gives the modules (G_MILLISECONDS) and the server (the ids and the seeds): the clock of the loop</summary>
  TQ3ClockHostTime = class(TInterfacedObject, IQ3HostTime)
  strict private
    FClock: IQ3Clock;
  public
    constructor Create(const AClock: IQ3Clock);
    function Milliseconds: Integer;
  end;

implementation

{ TQ3ClockHostTime }

constructor TQ3ClockHostTime.Create(const AClock: IQ3Clock);
begin
  inherited Create;
  FClock := AClock;
end;

function TQ3ClockHostTime.Milliseconds: Integer;
begin
  Result := FClock.Milliseconds;
end;

end.
