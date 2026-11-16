{******************************************************************************}
{                                                                              }
{  DelphiDoom: keen library - a clock that the program moves                    }
{  Port of Commander Keen in Keen Dreams (id Software), GPL v2 or later         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.ManualClock;

interface

uses
  System.SysUtils, DelphiDoom.Keen.Intf;

type
  /// <summary>
  ///   TimeCount that only changes when the program says so: for the code that draws a still picture or
  ///   plays a recorded demo. A loop that waits for the time (RF_Refresh waits for 2 tics) moves the clock on
  ///   by itself, so it never waits for real
  /// </summary>
  TKeenManualClock = class(TInterfacedObject, IKeenClock)
  strict private
    FTimeCount: Integer;
    FIdleStep: Integer;
  public
    /// <param name="AIdleStep">The tics that the clock moves on each time that the code waits</param>
    constructor Create(AIdleStep: Integer = 1);
    function GetTimeCount: Integer;
    procedure SetTimeCount(AValue: Integer);
    procedure Idle;
  end;

implementation

{ TKeenManualClock }

constructor TKeenManualClock.Create(AIdleStep: Integer);
begin
  inherited Create;
  FIdleStep := AIdleStep;
end;

function TKeenManualClock.GetTimeCount: Integer;
begin
  Result := FTimeCount;
end;

procedure TKeenManualClock.SetTimeCount(AValue: Integer);
begin
  FTimeCount := AValue;
end;

procedure TKeenManualClock.Idle;
begin
  Inc(FTimeCount, FIdleStep);
end;

end.
