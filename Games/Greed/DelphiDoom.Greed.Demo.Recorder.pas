{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the recorded games: recording                    }
{                                                                              }
{  xGreed (Jim Valavanis) and Raven 3D engine (c) 1996 Softdisk Publishing:    }
{  the user declares this port GPL v2 or later; the right on the parts         }
{  derived from the Softdisk code is not verified (docs\LICENZE.md)            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.Demo.Recorder;

interface

uses
  System.SysUtils, DelphiDoom.Greed.PlayerControl.Intf, DelphiDoom.Greed.CommandState,
  DelphiDoom.Greed.Level.Intf, DelphiDoom.Greed.Demo.Types, DelphiDoom.Greed.Demo.Intf,
  DelphiDoom.Greed.Demo.Source, DelphiDoom.Greed.Demo.Writer;

type
  /// <summary>
  ///   Stands between the game and what the game is driven by, and writes on a tape everything that is not decided
  ///   by the game itself: each reading of the controls (the commands, the characters, the mouse of the source of
  ///   the program), each answer of the clock of the system (the original adds it to some random choices) and the
  ///   tics before each turn of the loop. The game is given the source, the clock and the pacer that this object
  ///   is. The writer is not owned; Close writes the end of the tape
  /// </summary>
  TGreedDemoRecorder = class(TGreedDemoSource, IGreedSystemClock, IGreedFramePacer)
  strict private
    FWriter: TGreedDemoWriter;
    FSource: IGreedCommandSource;
    FClock: IGreedSystemClock;
  public
    /// <summary>EArgumentNilException if one is nil</summary>
    constructor Create(AWriter: TGreedDemoWriter; const ASource: IGreedCommandSource;
      const AClock: IGreedSystemClock);
    procedure BeginReading; override;
    // IGreedSystemClock
    function Clock: Cardinal;
    // IGreedFramePacer
    function NextFrame(var ATics: Integer): Boolean;
    function Finished: Boolean;
    /// <summary>The end of the tape</summary>
    procedure Close;
  end;

implementation

constructor TGreedDemoRecorder.Create(AWriter: TGreedDemoWriter; const ASource: IGreedCommandSource;
  const AClock: IGreedSystemClock);
begin
  inherited Create;
  if not Assigned(AWriter) then
    raise EArgumentNilException.Create('AWriter');
  if not Assigned(ASource) then
    raise EArgumentNilException.Create('ASource');
  if not Assigned(AClock) then
    raise EArgumentNilException.Create('AClock');
  FWriter := AWriter;
  FSource := ASource;
  FClock := AClock;
end;

procedure TGreedDemoRecorder.BeginReading;
var
  LReading: TGreedDemoReading;
  LCommand: TGreedCommand;
  LButton: TGreedMouseButton;
  LCharacter: Char;
begin
  FSource.BeginReading;
  LReading := Default(TGreedDemoReading);
  for LCommand := Low(TGreedCommand) to High(TGreedCommand) do
    if FSource.IsPressed(LCommand) then
      Include(LReading.Commands, LCommand);
  while FSource.TakeTyped(LCharacter) do
    // a tape holds 255 characters for a reading: more than a keyboard can type in two tics
    if Length(LReading.Typed) < 255 then
      LReading.Typed := LReading.Typed + Char(Ord(LCharacter) and $FF);
  for LButton := Low(TGreedMouseButton) to High(TGreedMouseButton) do
    if FSource.IsMousePressed(LButton) then
      Include(LReading.MouseButtons, LButton);
  FSource.TakeMouseMove(LReading.MouseDeltaX, LReading.MouseDeltaY);
  FWriter.WriteReading(LReading);
  SetReading(LReading);
end;

function TGreedDemoRecorder.Clock: Cardinal;
begin
  Result := FClock.Clock;
  FWriter.WriteClock(Result);
end;

function TGreedDemoRecorder.NextFrame(var ATics: Integer): Boolean;
begin
  if ATics < 0 then
    ATics := 0
  else if ATics > 255 then
    ATics := 255;
  FWriter.WriteFrame(ATics);
  Result := True;
end;

function TGreedDemoRecorder.Finished: Boolean;
begin
  Result := False;
end;

procedure TGreedDemoRecorder.Close;
begin
  FWriter.Close;
end;

end.
