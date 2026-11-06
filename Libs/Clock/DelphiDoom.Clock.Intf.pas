{******************************************************************************}
{                                                                              }
{  DelphiDoom: clock library - the contracts                                    }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Clock.Intf;

interface

type
  /// <summary>
  ///   Where time comes from: a counter that only goes forward, the number of its steps in a
  ///   second, and a way to let the thread rest
  /// </summary>
  IClockSource = interface
    ['{6D2B1F40-9A3C-4E57-B8D1-3C70A5E92F14}']
    /// <summary>Steps of the counter in one second; it may change if the source has to switch to a worse counter</summary>
    function GetFrequency: Int64;
    /// <summary>The counter now</summary>
    function Read: Int64;
    procedure Sleep(AMilliseconds: Integer);
    property Frequency: Int64 read GetFrequency;
  end;

  /// <summary>The time of the program: seconds from the first time somebody asked</summary>
  IClock = interface
    ['{A04E7C93-5B1D-4F28-9C66-D8E31B7A0F52}']
    /// <summary>Seconds from the first reading; the first reading is 0</summary>
    function Seconds: Double;
    /// <summary>Whole steps of a rate (for example 35 tics per second) since the first reading</summary>
    function Steps(ARate: Integer): Integer;
    /// <summary>Steps of a rate with a fixed point part: Seconds * ARate * AScale, truncated</summary>
    function ScaledSteps(ARate, AScale: Integer): Integer;
    procedure Sleep(AMilliseconds: Integer);
    /// <summary>Waits for a number of milliseconds, giving the processor back all the time</summary>
    procedure Wait(AMilliseconds: Integer);
  end;

implementation

end.
