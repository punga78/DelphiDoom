{******************************************************************************}
{                                                                              }
{  DelphiDoom: Keen32 - TimeCount of the game on the clock of the machine       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.HostClock;

interface

uses
  System.SysUtils, DelphiDoom.Keen.Types, DelphiDoom.Keen.Intf, DelphiDoom.Clock.Intf;

type
  /// <summary>
  ///   TimeCount of the original is a counter that the timer interrupt moves 70 times a second and that the game
  ///   sets when it wants (to 0, or back by the tics of a frame that was too long). Here it is the number of
  ///   seventieths of a second of an IClock plus an offset that a write changes. What a loop does while it waits
  ///   (the messages of the window, the picture, a short sleep) is given from outside
  /// </summary>
  TKeenHostClock = class(TInterfacedObject, IKeenClock)
  strict private
    FClock: IClock;
    FOffset: Integer;
    FOnIdle: TProc;
  public
    /// <param name="AClock">The clock of the machine</param>
    constructor Create(const AClock: IClock);
    function GetTimeCount: Integer;
    procedure SetTimeCount(AValue: Integer);
    procedure Idle;
    /// <summary>What Idle does; nil sleeps a millisecond</summary>
    property OnIdle: TProc read FOnIdle write FOnIdle;
  end;

implementation

{ TKeenHostClock }

constructor TKeenHostClock.Create(const AClock: IClock);
begin
  inherited Create;
  if not Assigned(AClock) then
    raise EArgumentNilException.Create('AClock');
  FClock := AClock;
  FOffset := -FClock.Steps(KEEN_TICKBASE);
end;

function TKeenHostClock.GetTimeCount: Integer;
begin
  Result := FClock.Steps(KEEN_TICKBASE) + FOffset;
end;

procedure TKeenHostClock.SetTimeCount(AValue: Integer);
begin
  FOffset := AValue - FClock.Steps(KEEN_TICKBASE);
end;

procedure TKeenHostClock.Idle;
begin
  if Assigned(FOnIdle) then
    FOnIdle()
  else
    FClock.Sleep(1);
end;

end.
