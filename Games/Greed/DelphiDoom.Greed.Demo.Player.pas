{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the recorded games: playing a tape               }
{                                                                              }
{  xGreed (Jim Valavanis) and Raven 3D engine (c) 1996 Softdisk Publishing:    }
{  the user declares this port GPL v2 or later; the right on the parts         }
{  derived from the Softdisk code is not verified (docs\LICENZE.md)            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.Demo.Player;

interface

uses
  System.SysUtils, DelphiDoom.Greed.PlayerControl.Intf, DelphiDoom.Greed.CommandState,
  DelphiDoom.Greed.Level.Intf, DelphiDoom.Greed.Demo.Types, DelphiDoom.Greed.Demo.Intf,
  DelphiDoom.Greed.Demo.Source, DelphiDoom.Greed.Demo.Reader;

type
  /// <summary>
  ///   Gives the game what a tape recorded, in the order in which the game asks: the readings of the controls,
  ///   the answers of the clock of the system and the tics before each turn of the loop. The same program on the
  ///   same data asks in the same order; if it asks for something that is not the next record (other data, another
  ///   version of the game) the tape is out of step: Desynchronized becomes true, the tape is over and the answers
  ///   are "nothing pressed", the last clock and no tics. The reader is not owned.
  ///   WaitForClock (the window): a turn is played only when the clock of the program has reached its tics, so the
  ///   game is seen at its speed; without it (no window) every turn is played at once
  /// </summary>
  TGreedDemoPlayer = class(TGreedDemoSource, IGreedSystemClock, IGreedFramePacer)
  strict private
    FReader: TGreedDemoReader;
    FWaitForClock: Boolean;
    FDesynchronized: Boolean;
    FLastClock: Cardinal;
    FReadings: Integer;
    FFrames: Integer;
    function Take(AKind: TGreedDemoRecordKind; out ARecord: TGreedDemoRecord): Boolean;
  public
    /// <summary>EArgumentNilException if AReader is nil</summary>
    constructor Create(AReader: TGreedDemoReader; AWaitForClock: Boolean);
    procedure BeginReading; override;
    // IGreedSystemClock
    function Clock: Cardinal;
    // IGreedFramePacer
    function NextFrame(var ATics: Integer): Boolean;
    function Finished: Boolean;
    /// <summary>The game asked for something that the tape does not have next</summary>
    property Desynchronized: Boolean read FDesynchronized;
    /// <summary>The readings and the turns given so far</summary>
    property Readings: Integer read FReadings;
    property Frames: Integer read FFrames;
  end;

implementation

constructor TGreedDemoPlayer.Create(AReader: TGreedDemoReader; AWaitForClock: Boolean);
begin
  inherited Create;
  if not Assigned(AReader) then
    raise EArgumentNilException.Create('AReader');
  FReader := AReader;
  FWaitForClock := AWaitForClock;
end;

function TGreedDemoPlayer.Take(AKind: TGreedDemoRecordKind; out ARecord: TGreedDemoRecord): Boolean;
begin
  ARecord := Default(TGreedDemoRecord);
  if FDesynchronized then
    Exit(False);
  Result := FReader.PeekKind = AKind;
  if Result then
    ARecord := FReader.Next
  else if FReader.PeekKind <> gdrEnd then
    // the tape goes on with something else: the game is not the one that was recorded
    FDesynchronized := True;
end;

procedure TGreedDemoPlayer.BeginReading;
var
  LRecord: TGreedDemoRecord;
begin
  if Take(gdrReading, LRecord) then
    Inc(FReadings);
  // past the end of the tape nothing is pressed
  SetReading(LRecord.Reading);
end;

function TGreedDemoPlayer.Clock: Cardinal;
var
  LRecord: TGreedDemoRecord;
begin
  if Take(gdrClock, LRecord) then
    FLastClock := LRecord.Clock;
  Result := FLastClock;
end;

function TGreedDemoPlayer.NextFrame(var ATics: Integer): Boolean;
var
  LRecord: TGreedDemoRecord;
begin
  if Finished or (FReader.PeekKind <> gdrFrame) then
  begin
    if (not FDesynchronized) and (FReader.PeekKind <> gdrEnd) then
      FDesynchronized := True;
    ATics := 0;
    Exit(True);
  end;
  if FWaitForClock and (ATics < FReader.Peek.Tics) then
    Exit(False);
  Take(gdrFrame, LRecord);
  ATics := LRecord.Tics;
  Inc(FFrames);
  Result := True;
end;

function TGreedDemoPlayer.Finished: Boolean;
begin
  Result := FDesynchronized or (FReader.PeekKind = gdrEnd);
end;

end.
