{******************************************************************************}
{                                                                              }
{  DelphiDoom: tracker - the waveform audio device of Windows                  }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tracker.WaveOut;

interface

uses
  Winapi.MMSystem,
  DelphiDoom.Tracker.Output.Intf;

type
  /// <summary>
  ///   waveOut of Windows, 16 bit stereo PCM: one header for each buffer, prepared when it is
  ///   written and given back when it is written again or the device is closed
  /// </summary>
  TTrackerWaveOutDevice = class(TInterfacedObject, ITrackerAudioDevice)
  strict private
    FDevice: HWAVEOUT;
    FOpen: Boolean;
    FHeaders: TArray<TWaveHdr>;
    procedure Unprepare(ABuffer: Integer);
  public
    destructor Destroy; override;
    function Open(ASampleRate, ABufferCount: Integer): Boolean;
    procedure Write(ABuffer: Integer; const ASamples: TArray<SmallInt>);
    function IsDone(ABuffer: Integer): Boolean;
    procedure Pause;
    procedure Restart;
    procedure Close;
    procedure Wait;
  end;

implementation

uses
  Winapi.Windows;

const
  CHANNELS = 2;
  BITS_PER_SAMPLE = 16;
  WAIT_MS = 10;

{ TTrackerWaveOutDevice }

destructor TTrackerWaveOutDevice.Destroy;
begin
  Close;
  inherited Destroy;
end;

function TTrackerWaveOutDevice.Open(ASampleRate, ABufferCount: Integer): Boolean;
var
  LFormat: TWaveFormatEx;
begin
  FillChar(LFormat, SizeOf(LFormat), 0);
  LFormat.wFormatTag := WAVE_FORMAT_PCM;
  LFormat.nChannels := CHANNELS;
  LFormat.nSamplesPerSec := ASampleRate;
  LFormat.wBitsPerSample := BITS_PER_SAMPLE;
  LFormat.nBlockAlign := CHANNELS * (BITS_PER_SAMPLE div 8);
  LFormat.nAvgBytesPerSec := LFormat.nSamplesPerSec * LFormat.nBlockAlign;
  FDevice := 0;
  FOpen := waveOutOpen(@FDevice, WAVE_MAPPER, @LFormat, 0, 0, CALLBACK_NULL) = MMSYSERR_NOERROR;
  SetLength(FHeaders, ABufferCount);
  if Length(FHeaders) > 0 then
    FillChar(FHeaders[0], Length(FHeaders) * SizeOf(TWaveHdr), 0);
  Result := FOpen;
end;

procedure TTrackerWaveOutDevice.Unprepare(ABuffer: Integer);
begin
  if (FHeaders[ABuffer].dwFlags and WHDR_PREPARED) <> 0 then
    waveOutUnprepareHeader(FDevice, @FHeaders[ABuffer], SizeOf(TWaveHdr));
end;

procedure TTrackerWaveOutDevice.Write(ABuffer: Integer; const ASamples: TArray<SmallInt>);
begin
  Unprepare(ABuffer);
  FillChar(FHeaders[ABuffer], SizeOf(TWaveHdr), 0);
  FHeaders[ABuffer].lpData := PAnsiChar(Pointer(ASamples));
  FHeaders[ABuffer].dwBufferLength := Length(ASamples) * SizeOf(SmallInt);
  if waveOutPrepareHeader(FDevice, @FHeaders[ABuffer], SizeOf(TWaveHdr)) = MMSYSERR_NOERROR then
    waveOutWrite(FDevice, @FHeaders[ABuffer], SizeOf(TWaveHdr));
end;

function TTrackerWaveOutDevice.IsDone(ABuffer: Integer): Boolean;
begin
  Result := (FHeaders[ABuffer].dwFlags and WHDR_DONE) <> 0;
end;

procedure TTrackerWaveOutDevice.Pause;
begin
  waveOutPause(FDevice);
end;

procedure TTrackerWaveOutDevice.Restart;
begin
  waveOutRestart(FDevice);
end;

procedure TTrackerWaveOutDevice.Close;
var
  LIndex: Integer;
begin
  if not FOpen then
    Exit;
  FOpen := False;
  waveOutReset(FDevice);
  for LIndex := 0 to High(FHeaders) do
    Unprepare(LIndex);
  waveOutClose(FDevice);
end;

procedure TTrackerWaveOutDevice.Wait;
begin
  Sleep(WAIT_MS);
end;

end.
