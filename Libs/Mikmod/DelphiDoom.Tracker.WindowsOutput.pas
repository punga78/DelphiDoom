{******************************************************************************}
{                                                                              }
{  DelphiDoom: tracker - the output of Windows: waveOut in a thread            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tracker.WindowsOutput;

interface

uses
  DelphiDoom.Tracker.Output.Intf;

type
  /// <summary>The only place that knows the device and the worker of Windows</summary>
  TTrackerWindowsOutputFactory = class(TInterfacedObject, ITrackerOutputFactory)
  public
    function CreateDevice: ITrackerAudioDevice;
    function CreateWorker: ITrackerWorker;
  end;

implementation

uses
  DelphiDoom.Tracker.ThreadWorker,
  DelphiDoom.Tracker.WaveOut;

{ TTrackerWindowsOutputFactory }

function TTrackerWindowsOutputFactory.CreateDevice: ITrackerAudioDevice;
begin
  Result := TTrackerWaveOutDevice.Create;
end;

function TTrackerWindowsOutputFactory.CreateWorker: ITrackerWorker;
begin
  Result := TTrackerThreadWorker.Create;
end;

end.
