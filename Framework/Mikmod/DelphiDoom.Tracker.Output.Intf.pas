{******************************************************************************}
{                                                                              }
{  DelphiDoom: tracker - the contracts of the output: device and worker        }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tracker.Output.Intf;

interface

uses
  System.SysUtils;

type
  /// <summary>
  ///   An audio output of 16 bit stereo, fed a few buffers at a time: each
  ///   buffer is written, played by the device and then marked done
  /// </summary>
  /// <remarks>
  ///   The samples of a buffer must stay alive and unchanged from Write until
  ///   the buffer is done, written again or the device is closed
  /// </remarks>
  ITrackerAudioDevice = interface
    ['{5C0E8A43-2B71-4F96-8D1E-7A93B04C61F2}']
    /// <summary>Opens the device; False if there is no device for this format</summary>
    function Open(ASampleRate, ABufferCount: Integer): Boolean;
    /// <summary>Queues the samples (left and right, interleaved) of the buffer ABuffer</summary>
    procedure Write(ABuffer: Integer; const ASamples: TArray<SmallInt>);
    /// <summary>True when the device has played the buffer written last in ABuffer</summary>
    function IsDone(ABuffer: Integer): Boolean;
    procedure Pause;
    procedure Restart;
    /// <summary>Stops the playback, gives the buffers back and closes the device</summary>
    procedure Close;
    /// <summary>Lets the time go by while the device plays (a few milliseconds)</summary>
    procedure Wait;
  end;

  /// <summary>Runs the playback away from the caller, one piece of work at a time</summary>
  ITrackerWorker = interface
    ['{A41F6D07-93C2-4E58-B0A7-2E6C8D15F93B}']
    /// <summary>Starts AWork; the work before must have ended (WaitFor)</summary>
    procedure Start(const AWork: TProc);
    /// <summary>Waits for the work to end; nothing to do if none was started</summary>
    procedure WaitFor;
    function IsRunning: Boolean;
  end;

  /// <summary>What a player needs to make music: a device for each song and a worker</summary>
  ITrackerOutputFactory = interface
    ['{E2B9734C-6A08-4D1F-9C55-81F3A0D7B6E4}']
    function CreateDevice: ITrackerAudioDevice;
    function CreateWorker: ITrackerWorker;
  end;

implementation

end.
