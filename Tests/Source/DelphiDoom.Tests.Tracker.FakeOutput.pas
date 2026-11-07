{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the tracker - a fake audio output                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Tracker.FakeOutput;

interface

uses
  System.SysUtils, DelphiDoom.Tracker.Output.Intf;

type
  /// <summary>
  ///   A device that plays nothing: it keeps a copy of what is written, and a
  ///   buffer is done after BusyChecks answers "not done" (each followed by a
  ///   Wait). OnWait lets the test act while the song plays
  /// </summary>
  TFakeTrackerAudioDevice = class(TInterfacedObject, ITrackerAudioDevice)
  public
    OpenResult: Boolean;
    /// <summary>Open raises an exception, as a broken device would</summary>
    OpenRaises: Boolean;
    OpenCalls: Integer;
    OpenedRate: Integer;
    OpenedBuffers: Integer;
    CloseCalls: Integer;
    PauseCalls: Integer;
    RestartCalls: Integer;
    WaitCalls: Integer;
    IsDoneCalls: Integer;
    /// <summary>How many times IsDone says "not done" before it says "done"</summary>
    BusyChecks: Integer;
    /// <summary>Beyond this the playback is taken as never ending, and the test fails</summary>
    MaxIsDoneCalls: Integer;
    Written: TArray<TArray<SmallInt>>;
    OnWait: TProc;
    constructor Create;
    function Open(ASampleRate, ABufferCount: Integer): Boolean;
    procedure Write(ABuffer: Integer; const ASamples: TArray<SmallInt>);
    function IsDone(ABuffer: Integer): Boolean;
    procedure Pause;
    procedure Restart;
    procedure Close;
    procedure Wait;
  end;

  /// <summary>Runs the work at once, in the thread of the test</summary>
  TFakeTrackerWorker = class(TInterfacedObject, ITrackerWorker)
  public
    Running: Boolean;
    /// <summary>WaitFor raises an exception, as a broken thread would</summary>
    WaitForRaises: Boolean;
    StartCalls: Integer;
    WaitForCalls: Integer;
    procedure Start(const AWork: TProc);
    procedure WaitFor;
    function IsRunning: Boolean;
  end;

  /// <summary>Gives always the same fake device and worker, so the test can look at them</summary>
  TFakeTrackerOutputFactory = class(TInterfacedObject, ITrackerOutputFactory)
  public
    Device: TFakeTrackerAudioDevice;
    Worker: TFakeTrackerWorker;
    DeviceCalls: Integer;
    constructor Create;
    destructor Destroy; override;
    function CreateDevice: ITrackerAudioDevice;
    function CreateWorker: ITrackerWorker;
  end;

  /// <summary>Raised by the fake device when the playback does not end</summary>
  EFakeTrackerOutputException = class(Exception);

implementation

{ TFakeTrackerAudioDevice }

constructor TFakeTrackerAudioDevice.Create;
begin
  inherited Create;
  OpenResult := True;
  MaxIsDoneCalls := 100000;
end;

function TFakeTrackerAudioDevice.Open(ASampleRate, ABufferCount: Integer): Boolean;
begin
  Inc(OpenCalls);
  if OpenRaises then
    raise EFakeTrackerOutputException.Create('The device is broken');
  OpenedRate := ASampleRate;
  OpenedBuffers := ABufferCount;
  Result := OpenResult;
end;

procedure TFakeTrackerAudioDevice.Write(ABuffer: Integer; const ASamples: TArray<SmallInt>);
begin
  SetLength(Written, Length(Written) + 1);
  Written[High(Written)] := Copy(ASamples);
end;

function TFakeTrackerAudioDevice.IsDone(ABuffer: Integer): Boolean;
begin
  Inc(IsDoneCalls);
  if IsDoneCalls > MaxIsDoneCalls then
    raise EFakeTrackerOutputException.Create('The playback never ends');
  Result := (BusyChecks = 0) or (IsDoneCalls mod (BusyChecks + 1) = 0);
end;

procedure TFakeTrackerAudioDevice.Pause;
begin
  Inc(PauseCalls);
end;

procedure TFakeTrackerAudioDevice.Restart;
begin
  Inc(RestartCalls);
end;

procedure TFakeTrackerAudioDevice.Close;
begin
  Inc(CloseCalls);
end;

procedure TFakeTrackerAudioDevice.Wait;
begin
  Inc(WaitCalls);
  if Assigned(OnWait) then
    OnWait();
end;

{ TFakeTrackerWorker }

procedure TFakeTrackerWorker.Start(const AWork: TProc);
begin
  Inc(StartCalls);
  Running := True;
  try
    AWork();
  finally
    Running := False;
  end;
end;

procedure TFakeTrackerWorker.WaitFor;
begin
  Inc(WaitForCalls);
  if WaitForRaises then
    raise EFakeTrackerOutputException.Create('The worker is broken');
end;

function TFakeTrackerWorker.IsRunning: Boolean;
begin
  Result := Running;
end;

{ TFakeTrackerOutputFactory }

constructor TFakeTrackerOutputFactory.Create;
begin
  inherited Create;
  Device := TFakeTrackerAudioDevice.Create;
  Device._AddRef;
  Worker := TFakeTrackerWorker.Create;
  Worker._AddRef;
end;

destructor TFakeTrackerOutputFactory.Destroy;
begin
  Device.OnWait := nil;
  Device._Release;
  Worker._Release;
  inherited Destroy;
end;

function TFakeTrackerOutputFactory.CreateDevice: ITrackerAudioDevice;
begin
  Inc(DeviceCalls);
  Result := Device;
end;

function TFakeTrackerOutputFactory.CreateWorker: ITrackerWorker;
begin
  Result := Worker;
end;

end.
