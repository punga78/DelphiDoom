{******************************************************************************}
{                                                                              }
{  DelphiDoom: parity library - shared types and exceptions                    }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Parity.Types;

interface

uses
  System.SysUtils;

type
  /// <summary>Raised for a wrong option, a wrong layout or a log that cannot be written</summary>
  EParityException = class(Exception);

  /// <summary>
  ///   What the command line asked for. Every field is off (empty, -1 or False) unless the option was
  ///   given: with no option the parity tools do nothing
  /// </summary>
  TParityOptions = record
    /// <summary>-statehash file: one line of hashes of the game state for every tic</summary>
    StateHashFile: string;
    /// <summary>-statehash-detail first last: the value of every field for the tics of the range</summary>
    StateDetail: Boolean;
    StateDetailFirstTic: Integer;
    StateDetailLastTic: Integer;
    /// <summary>-framehash file: one line of hashes of the screen for every frame</summary>
    FrameHashFile: string;
    /// <summary>-framedump tic file: the frame of that tic as a BMP file (-1 when not asked)</summary>
    FrameDumpTic: Integer;
    FrameDumpFile: string;
    /// <summary>-autodemo seed tics: the automatic pilot plays the first player</summary>
    AutoDemo: Boolean;
    AutoDemoSeed: Cardinal;
    AutoDemoTics: Integer;
    /// <summary>True when at least one option was given</summary>
    function IsActive: Boolean;
  end;

  /// <summary>One command of the automatic pilot, independent of the layout of the ticcmd of a game</summary>
  TParityPilotCommand = record
    /// <summary>Forward (positive) or backward move, in the units of the ticcmd (up to 50)</summary>
    Forward: Integer;
    /// <summary>Right (positive) or left strafe, in the units of the ticcmd (up to 40)</summary>
    Side: Integer;
    /// <summary>Turn to the left (positive) or right, in the units of the angle of the ticcmd (65536 = a full turn)</summary>
    Turn: Integer;
    Fire: Boolean;
    Use: Boolean;
    /// <summary>Number of the weapon to take (1 and up), 0 to keep the one in hand</summary>
    Weapon: Integer;
  end;

  /// <summary>What the pilot may know about the world: the player and nothing else</summary>
  TParityPilotView = record
    /// <summary>The tic of the game that is being built</summary>
    Tic: Integer;
    Alive: Boolean;
    /// <summary>Position of the player (fixed point 16.16)</summary>
    X: Integer;
    Y: Integer;
  end;

  /// <summary>Where the 3D view is inside a frame (all the numbers are pixels)</summary>
  TParityFrameLayout = record
    Width: Integer;
    Height: Integer;
    ViewX: Integer;
    ViewY: Integer;
    ViewWidth: Integer;
    ViewHeight: Integer;
  end;

  /// <summary>The first line where two logs differ</summary>
  TParityDifference = record
    Found: Boolean;
    /// <summary>1-based number of the line in the logs (comments are counted)</summary>
    LineNumber: Integer;
    /// <summary>The tic of the line (-1 if the line has none)</summary>
    Tic: Integer;
    Expected: string;
    Actual: string;
    /// <summary>The names of the hashes or fields that differ, separated by a comma</summary>
    Differing: string;
    /// <summary>One line that tells it all, in plain words</summary>
    function Describe: string;
  end;

implementation

{ TParityOptions }

function TParityOptions.IsActive: Boolean;
begin
  Result := (StateHashFile <> '') or (FrameHashFile <> '') or (FrameDumpTic >= 0) or AutoDemo;
end;

{ TParityDifference }

function TParityDifference.Describe: string;
begin
  if not Found then
    Exit('EQUAL');
  Result := Format('DIFFERENT at line %d (tic %d): %s | expected: %s | actual: %s',
    [LineNumber, Tic, Differing, Expected, Actual]);
end;

end.
