{******************************************************************************}
{                                                                              }
{  DelphiDoom: Keen32 - where the loop of the window spends its time            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.LoopProfile;

interface

uses
  System.SysUtils, DelphiDoom.Clock.Intf;

type
  /// <summary>The parts of what the game does while it waits for the next tic</summary>
  TKeenLoopSection = (klsMessages, klsAudio, klsPicture, klsSleep);

  /// <summary>
  ///   Counts and times (on an IClock) the parts of the loop of the window, and the refreshes of the game, so that
  ///   the speed of the game is a number: tics of the clock of the game a second (70 by construction), refreshes a
  ///   second (at most 70 / MINTICS = 35 in the original), pictures a second, seconds spent in each part
  /// </summary>
  TKeenLoopProfile = class
  strict private
    FClock: IClock;
    FStart: Double;
    FEntered: Double;
    FCurrent: TKeenLoopSection;
    FSeconds: array[TKeenLoopSection] of Double;
    FCounts: array[TKeenLoopSection] of Integer;
    FLongest: array[TKeenLoopSection] of Double;
    FLate: array[TKeenLoopSection] of Integer;
    FMarked: Boolean;
    FMarkTime: Double;
    FMarkRefreshes: Integer;
  public
    /// <summary>EArgumentNilException if AClock is nil</summary>
    constructor Create(const AClock: IClock);
    /// <summary>A part of the loop begins</summary>
    procedure Enter(ASection: TKeenLoopSection);
    /// <summary>The part that began ends</summary>
    procedure Leave;
    function Seconds(ASection: TKeenLoopSection): Double;
    function Count(ASection: TKeenLoopSection): Integer;
    /// <summary>
    ///   Remembers the time and the refreshes now, once: what is counted from here is the speed of the game without
    ///   the start (loading, fades) that is not the speed of play
    /// </summary>
    procedure Mark(ARefreshes: Integer);
    property IsMarked: Boolean read FMarked;
    /// <summary>Seconds from the creation</summary>
    function Elapsed: Double;
    /// <summary>Tics of the game clock (TicRate a second) that went by since the creation</summary>
    function Tics(ATicRate: Integer): Integer;
    /// <summary>The numbers of the run as a line of text, for -report (ARefreshes: the refreshes of the game)</summary>
    function Summary(ATicRate, ARefreshes: Integer): string;
  end;

implementation

const
  /// A stay in a part of the loop longer than this (more than 5 ms) is late: a sleep of 1 ms that overslept
  LATE_SECONDS = 0.005;
  SECTION_NAMES: array[TKeenLoopSection] of string = ('messages', 'audio', 'picture', 'sleep');

{ TKeenLoopProfile }

constructor TKeenLoopProfile.Create(const AClock: IClock);
begin
  inherited Create;
  if not Assigned(AClock) then
    raise EArgumentNilException.Create('AClock');
  FClock := AClock;
  FStart := FClock.Seconds;
end;

procedure TKeenLoopProfile.Enter(ASection: TKeenLoopSection);
begin
  FCurrent := ASection;
  FEntered := FClock.Seconds;
end;

procedure TKeenLoopProfile.Leave;
var
  LSpan: Double;
begin
  LSpan := FClock.Seconds - FEntered;
  FSeconds[FCurrent] := FSeconds[FCurrent] + LSpan;
  if LSpan > FLongest[FCurrent] then
    FLongest[FCurrent] := LSpan;
  if LSpan > LATE_SECONDS then
    Inc(FLate[FCurrent]);
  Inc(FCounts[FCurrent]);
end;

procedure TKeenLoopProfile.Mark(ARefreshes: Integer);
begin
  if FMarked then
    Exit;
  FMarked := True;
  FMarkTime := Elapsed;
  FMarkRefreshes := ARefreshes;
end;

function TKeenLoopProfile.Seconds(ASection: TKeenLoopSection): Double;
begin
  Result := FSeconds[ASection];
end;

function TKeenLoopProfile.Count(ASection: TKeenLoopSection): Integer;
begin
  Result := FCounts[ASection];
end;

function TKeenLoopProfile.Elapsed: Double;
begin
  Result := FClock.Seconds - FStart;
end;

function TKeenLoopProfile.Tics(ATicRate: Integer): Integer;
begin
  Result := Trunc(Elapsed * ATicRate);
end;

function TKeenLoopProfile.Summary(ATicRate, ARefreshes: Integer): string;
var
  LSection: TKeenLoopSection;
  LElapsed: Double;
  LBusy: Double;
begin
  LBusy := 0;
  LElapsed := Elapsed;
  if LElapsed <= 0 then
    LElapsed := 1;
  Result := Format('speed: %.1f tics/s, %.1f refreshes/s, %.1f pictures/s', [Tics(ATicRate) / LElapsed,
    ARefreshes / LElapsed, FCounts[klsPicture] / LElapsed], TFormatSettings.Invariant);
  for LSection := Low(TKeenLoopSection) to High(TKeenLoopSection) do
    begin
      Result := Result + Format('; %s %d calls %.3f s (longest %.1f ms, %d over 5 ms)', [SECTION_NAMES[LSection],
        FCounts[LSection], FSeconds[LSection], FLongest[LSection] * 1000, FLate[LSection]], TFormatSettings.Invariant);
      LBusy := LBusy + FSeconds[LSection];
    end;
  if FMarked and (LElapsed > FMarkTime) then
    Result := Result + Format('; steady %.1f refreshes/s (after %.1f s)', [(ARefreshes - FMarkRefreshes) / (LElapsed - FMarkTime),
      FMarkTime], TFormatSettings.Invariant);
  // the rest of the time is the game itself: its logic, its drawing and the refresh
  Result := Result + Format('; game %.3f s', [LElapsed - LBusy], TFormatSettings.Invariant);
end;

end.
