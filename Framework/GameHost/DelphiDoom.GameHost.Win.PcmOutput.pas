{******************************************************************************}
{                                                                              }
{  DelphiDoom: game host library - the sound output of Windows (waveOut) that  }
{  asks the mixer of a game for samples, as the audio callback of SDL does      }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.GameHost.Win.PcmOutput;

interface

uses
  Winapi.Windows, Winapi.MMSystem, System.SysUtils, System.Classes, DelphiDoom.GameHost.Audio.Intf;

type
  /// <summary>
  ///   IGameHostPcmOutput on waveOut: four buffers of 1024 frames (16 bit stereo) that a thread keeps full by
  ///   asking the source, so the music goes on while the game draws. The source is not owned (a weak reference:
  ///   the mixer owns the output, not the other way round) and stops being asked before Close returns
  /// </summary>
  TGameHostWinPcmOutput = class(TInterfacedObject, IGameHostPcmOutput)
  strict private
    const
      BUFFER_COUNT = 4;
      FRAMES_PER_BUFFER = 1024;
      BYTES_PER_FRAME = 4;
    type
      TPumpThread = class(TThread)
      strict private
        FOwner: TGameHostWinPcmOutput;
      protected
        procedure Execute; override;
      public
        constructor Create(AOwner: TGameHostWinPcmOutput);
      end;
    var
      [weak] FSource: IGameHostPcmSource;
      FWave: HWAVEOUT;
      FHeaders: array[0..BUFFER_COUNT - 1] of TWaveHdr;
      FBuffers: array[0..BUFFER_COUNT - 1] of TBytes;
      FEvent: THandle;
      FThread: TPumpThread;
      FOpen: Boolean;
      FCompleted: Integer;
    procedure Fill(AIndex: Integer);
  public
    destructor Destroy; override;
    function Open(ARate: Integer; const ASource: IGameHostPcmSource): Boolean;
    procedure Close;
    function IsOpen: Boolean;
    /// <summary>The buffers the device has finished playing since it was opened (proof that the output consumes)</summary>
    function CompletedBuffers: Integer;
  end;

implementation

{ TGameHostWinPcmOutput.TPumpThread }

constructor TGameHostWinPcmOutput.TPumpThread.Create(AOwner: TGameHostWinPcmOutput);
begin
  inherited Create(False);
  FOwner := AOwner;
end;

procedure TGameHostWinPcmOutput.TPumpThread.Execute;
var
  LIndex: Integer;
begin
  while not Terminated do
  begin
    WaitForSingleObject(FOwner.FEvent, 50);
    for LIndex := 0 to BUFFER_COUNT - 1 do
      if (not Terminated) and ((FOwner.FHeaders[LIndex].dwFlags and WHDR_DONE) <> 0) then
      begin
        Inc(FOwner.FCompleted);
        FOwner.Fill(LIndex);
      end;
  end;
end;

{ TGameHostWinPcmOutput }

destructor TGameHostWinPcmOutput.Destroy;
begin
  Close;
  inherited Destroy;
end;

procedure TGameHostWinPcmOutput.Fill(AIndex: Integer);
var
  LSource: IGameHostPcmSource;
begin
  LSource := FSource;
  if LSource <> nil then
    LSource.Render(@FBuffers[AIndex][0], Length(FBuffers[AIndex]))
  else
    FillChar(FBuffers[AIndex][0], Length(FBuffers[AIndex]), 0);
  waveOutWrite(FWave, @FHeaders[AIndex], SizeOf(TWaveHdr));
end;

function TGameHostWinPcmOutput.Open(ARate: Integer; const ASource: IGameHostPcmSource): Boolean;
var
  LFormat: TWaveFormatEx;
  LIndex: Integer;
begin
  if FOpen then
    Exit(True);
  Result := False;
  if waveOutGetNumDevs = 0 then
    Exit;
  FSource := ASource;
  LFormat.wFormatTag := WAVE_FORMAT_PCM;
  LFormat.nChannels := 2;
  LFormat.nSamplesPerSec := ARate;
  LFormat.wBitsPerSample := 16;
  LFormat.nBlockAlign := BYTES_PER_FRAME;
  LFormat.nAvgBytesPerSec := ARate * BYTES_PER_FRAME;
  LFormat.cbSize := 0;
  FEvent := CreateEvent(nil, False, False, nil);
  if waveOutOpen(@FWave, WAVE_MAPPER, @LFormat, DWORD_PTR(FEvent), 0, CALLBACK_EVENT) <> MMSYSERR_NOERROR then
  begin
    CloseHandle(FEvent);
    FEvent := 0;
    FSource := nil;
    Exit;
  end;
  FCompleted := 0;
  for LIndex := 0 to BUFFER_COUNT - 1 do
  begin
    SetLength(FBuffers[LIndex], FRAMES_PER_BUFFER * BYTES_PER_FRAME);
    FillChar(FHeaders[LIndex], SizeOf(TWaveHdr), 0);
    FHeaders[LIndex].lpData := PAnsiChar(@FBuffers[LIndex][0]);
    FHeaders[LIndex].dwBufferLength := Length(FBuffers[LIndex]);
    waveOutPrepareHeader(FWave, @FHeaders[LIndex], SizeOf(TWaveHdr));
  end;
  FOpen := True;
  for LIndex := 0 to BUFFER_COUNT - 1 do
    Fill(LIndex);
  FThread := TPumpThread.Create(Self);
  Result := True;
end;

procedure TGameHostWinPcmOutput.Close;
var
  LIndex: Integer;
begin
  if not FOpen then
    Exit;
  FOpen := False;
  FThread.Terminate;
  SetEvent(FEvent);
  FThread.WaitFor;
  FreeAndNil(FThread);
  waveOutReset(FWave);
  for LIndex := 0 to BUFFER_COUNT - 1 do
    waveOutUnprepareHeader(FWave, @FHeaders[LIndex], SizeOf(TWaveHdr));
  waveOutClose(FWave);
  CloseHandle(FEvent);
  FEvent := 0;
  FSource := nil;
end;

function TGameHostWinPcmOutput.IsOpen: Boolean;
begin
  Result := FOpen;
end;

function TGameHostWinPcmOutput.CompletedBuffers: Integer;
begin
  Result := FCompleted;
end;

end.
