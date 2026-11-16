{******************************************************************************}
{                                                                              }
{  DelphiDoom: demo library - old demos, the commands after the player dies    }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Demo.DeathTrimmer;

{$POINTERMATH ON}

interface

type
  /// <summary>
  ///   Old versions compatibility (G_SafeCompatibilityDemo): when the player is dead in an old
  ///   demo, the commands that follow are cleared and the demo ends at most four seconds later
  /// </summary>
  TDemoDeathTrimmer = class sealed
  public
    /// <summary>
    ///   Clears the commands from the current position to the end marker or to the four seconds
    /// </summary>
    /// <param name="APosition">The next command of the demo; the buffer is changed</param>
    /// <param name="AEnd">The end of the buffer of the demo</param>
    class procedure Trim(const APosition: PByte; const AEnd: PByte); static;
  end;

implementation

uses
  DelphiDoom.Demo.Types;

const
  // The old commands are four bytes; the game ran at 35 tics per second
  OLD_COMMAND_SIZE = 4;
  DEMO_TICS_PER_SECOND = 35;
  SECONDS_AFTER_DEATH = 4;

{ TDemoDeathTrimmer }

class procedure TDemoDeathTrimmer.Trim(const APosition: PByte; const AEnd: PByte);
var
  LLength: Integer;
  LLimit: Integer;
begin
  LLength := OLD_COMMAND_SIZE;
  while (NativeInt(@APosition[LLength]) < NativeInt(AEnd) - 4) and
        (APosition[LLength] <> DEMO_MARKER) do
    Inc(LLength, OLD_COMMAND_SIZE);

  // Leave maximum 4 seconds after the player death
  LLimit := OLD_COMMAND_SIZE * DEMO_TICS_PER_SECOND * SECONDS_AFTER_DEATH;
  if LLength > LLimit then
  begin
    LLength := LLimit;
    APosition[LLength] := DEMO_MARKER;
  end;
  FillChar(APosition^, LLength, 0);
end;

end.
