{******************************************************************************}
{                                                                              }
{  DelphiDoom: radix library - types of the mission briefing                   }
{  Copyright (C) 2004-2024 by Jim Valavanis (original DelphiDoom, Rad-X)       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of the records of radix_briefing.pas of Rad-X                          }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Radix.Briefing.Types;

interface

const
  RADIX_BRIEFING_NUMBERS = 5;

type
  /// <summary>The commands of the script of a mission briefing ("MissionBrief[episode][map]")</summary>
  TRadixBriefingCommandKind = (
    bckClearAnimWindow,
    bckClearTextWindow,
    /// <summary>Numbers[0]: tics to wait</summary>
    bckDelay,
    /// <summary>Text: the first picture; Numbers: how many pictures, tics of each one, -1</summary>
    bckDisplayAnimation,
    /// <summary>Text: the picture</summary>
    bckDisplayImage,
    /// <summary>Numbers[0], [1]: a point of RADIX.DAT; Text: what is written there on the map</summary>
    bckMapPrint,
    bckNextPoint,
    /// <summary>Numbers[0], [1]: a point of RADIX.DAT; [2..4]: red, green, blue (0..63) of its mark</summary>
    bckPointMap,
    /// <summary>Text: what is typed in the text window, one character for every tic</summary>
    bckPrint,
    /// <summary>Numbers[0]: where the map scrolls to</summary>
    bckScrollMapX,
    bckShowScreen,
    /// <summary>Waits for the pilot (fire or use)</summary>
    bckWaitAction);

  /// <summary>One command of a briefing</summary>
  TRadixBriefingCommand = record
    Kind: TRadixBriefingCommandKind;
    Text: string;
    Numbers: array[0..RADIX_BRIEFING_NUMBERS - 1] of Integer;
  end;

  /// <summary>
  ///   The map of the level that the briefing draws on: the game makes it from the lines of the
  ///   level. A command for the map waits until the map is ready
  /// </summary>
  IRadixBriefingMap = interface
    ['{6E0B1F6C-3C1B-4F53-9E0B-5F0D3A6B7C21}']
    function IsReady: Boolean;
    /// <summary>A cross at a point of RADIX.DAT, with its color (each part 0..63)</summary>
    procedure MarkPoint(AX, AY, ARed, AGreen, ABlue: Integer);
    /// <summary>A text at a point of RADIX.DAT</summary>
    procedure Print(AX, AY: Integer; const AText: string);
  end;

implementation

end.
