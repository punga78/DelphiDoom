{******************************************************************************}
{                                                                              }
{  DelphiDoom: clock library - timeBeginPeriod and timeEndPeriod of Windows     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Clock.WindowsTimerResolution;

interface

uses
  DelphiDoom.Clock.Intf;

type
  /// <summary>The timer of Windows (winmm): the period is global to the system while the program holds it</summary>
  TWindowsTimerResolutionSystem = class(TInterfacedObject, ITimerResolutionSystem)
  public
    function BeginPeriod(AMilliseconds: Integer): Boolean;
    procedure EndPeriod(AMilliseconds: Integer);
  end;

implementation

uses
  Winapi.Windows, Winapi.MMSystem;

{ TWindowsTimerResolutionSystem }

function TWindowsTimerResolutionSystem.BeginPeriod(AMilliseconds: Integer): Boolean;
begin
  Result := timeBeginPeriod(Cardinal(AMilliseconds)) = TIMERR_NOERROR;
end;

procedure TWindowsTimerResolutionSystem.EndPeriod(AMilliseconds: Integer);
begin
  timeEndPeriod(Cardinal(AMilliseconds));
end;

end.
