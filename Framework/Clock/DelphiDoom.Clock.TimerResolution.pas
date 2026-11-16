{******************************************************************************}
{                                                                              }
{  DelphiDoom: clock library - the resolution of the timer of the system        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Clock.TimerResolution;

interface

uses
  System.SysUtils, DelphiDoom.Clock.Intf;

type
  /// <summary>
  ///   A request for a finer timer, held for as long as the object lives. Without it Sleep(1) of Windows waits for
  ///   the next tick of the system, 15.6 ms: a game that waits for a tic of 14 ms with Sleep(1) loses a tic each
  ///   time. The request is made when the object is created and is given back, once, when it is destroyed
  /// </summary>
  TTimerResolutionLease = class(TInterfacedObject, ITimerResolutionLease)
  strict private
    FSystem: ITimerResolutionSystem;
    FMilliseconds: Integer;
    FGranted: Boolean;
  public
    /// <summary>EArgumentNilException if ASystem is nil, EArgumentOutOfRangeException if AMilliseconds is below 1</summary>
    constructor Create(const ASystem: ITimerResolutionSystem; AMilliseconds: Integer);
    destructor Destroy; override;
    function IsGranted: Boolean;
    function Milliseconds: Integer;
  end;

implementation

{ TTimerResolutionLease }

constructor TTimerResolutionLease.Create(const ASystem: ITimerResolutionSystem; AMilliseconds: Integer);
begin
  inherited Create;
  if not Assigned(ASystem) then
    raise EArgumentNilException.Create('ASystem');
  if AMilliseconds < 1 then
    raise EArgumentOutOfRangeException.Create('AMilliseconds');
  FSystem := ASystem;
  FMilliseconds := AMilliseconds;
  FGranted := FSystem.BeginPeriod(AMilliseconds);
end;

destructor TTimerResolutionLease.Destroy;
begin
  // only a period that was granted is given back (the system counts them)
  if FGranted then
    FSystem.EndPeriod(FMilliseconds);
  inherited Destroy;
end;

function TTimerResolutionLease.IsGranted: Boolean;
begin
  Result := FGranted;
end;

function TTimerResolutionLease.Milliseconds: Integer;
begin
  Result := FMilliseconds;
end;

end.
