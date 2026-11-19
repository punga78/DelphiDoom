{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III program - the loop time on the clock library          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Quake3.Clock.Adapter;

interface

uses
  DelphiDoom.Clock.Intf, DelphiDoom.Quake3.Clock.Intf;

type
  /// <summary>
  ///   IQ3Clock on the IClock of Framework\Clock (the real one on the counters of Windows, or the manual
  ///   one of the tests, whose Sleep moves the time forward)
  /// </summary>
  TQ3ClockAdapter = class(TInterfacedObject, IQ3Clock)
  strict private
    FClock: IClock;
  public
    constructor Create(const AClock: IClock);
    function Milliseconds: Integer;
    procedure Sleep(AMilliseconds: Integer);
  end;

implementation

const
  MILLISECONDS_PER_SECOND = 1000;

{ TQ3ClockAdapter }

constructor TQ3ClockAdapter.Create(const AClock: IClock);
begin
  inherited Create;
  FClock := AClock;
end;

function TQ3ClockAdapter.Milliseconds: Integer;
begin
  Result := FClock.Steps(MILLISECONDS_PER_SECOND);
end;

procedure TQ3ClockAdapter.Sleep(AMilliseconds: Integer);
begin
  FClock.Sleep(AMilliseconds);
end;

end.
