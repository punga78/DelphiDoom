{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the sound card through the PCM output of the game host  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Engine.Audio.WaveOutDevice;

interface

uses
  DelphiDoom.Audio.Types,
  DelphiDoom.Audio.Intf,
  DelphiDoom.Audio.Mixer.Intf,
  DelphiDoom.GameHost.Audio.Intf,
  DelphiDoom.Logging.Intf;

type
  /// <summary>
  ///   ISoundDevice that mixes the sound effects in software (ISfxMixer) and plays the result on the PCM output of
  ///   the game host (16 bit stereo at a fixed rate): the output asks for samples from its own thread. It replaces
  ///   the buffers of DirectSound
  /// </summary>
  TEngineWaveOutSoundDevice = class(TInterfacedObject, ISoundDevice, IGameHostPcmSource)
  strict private
    FOutput: IGameHostPcmOutput;
    FMixer: ISfxMixer;
    FRate: Integer;
    FLog: ILog;
  public
    /// <param name="AOutput">The output of the machine, closed</param>
    /// <param name="AMixer">The mixer of the voices, made for the same rate</param>
    /// <param name="ARate">Frames per second of the output</param>
    /// <param name="ALog">May be nil</param>
    constructor Create(const AOutput: IGameHostPcmOutput; const AMixer: ISfxMixer; ARate: Integer;
      const ALog: ILog);
    function Initialize: Boolean;
    procedure Shutdown;
    function CreateVoice(const ASample: TSfxSample; out AVoice: IAudioVoice): Integer;
    /// <summary>IGameHostPcmSource: called by the thread of the output</summary>
    procedure Render(ABuffer: PByte; AByteCount: Integer);
  end;

implementation

uses
  System.SysUtils;

const
  SOpenFailed = 'I_InitSound(): the sound output could not be opened (no sound device)';

{ TEngineWaveOutSoundDevice }

constructor TEngineWaveOutSoundDevice.Create(const AOutput: IGameHostPcmOutput; const AMixer: ISfxMixer;
  ARate: Integer; const ALog: ILog);
begin
  inherited Create;
  if not Assigned(AOutput) then
    raise EArgumentNilException.Create('AOutput');
  if not Assigned(AMixer) then
    raise EArgumentNilException.Create('AMixer');
  FOutput := AOutput;
  FMixer := AMixer;
  FRate := ARate;
  FLog := ALog;
end;

function TEngineWaveOutSoundDevice.Initialize: Boolean;
begin
  Result := FOutput.Open(FRate, Self);
  if (not Result) and Assigned(FLog) then
    FLog.Info(SOpenFailed);
end;

procedure TEngineWaveOutSoundDevice.Shutdown;
begin
  // Close returns when the output does not ask for samples any more
  FOutput.Close;
  FMixer.Clear;
end;

function TEngineWaveOutSoundDevice.CreateVoice(const ASample: TSfxSample; out AVoice: IAudioVoice): Integer;
begin
  Result := FMixer.CreateVoice(ASample, AVoice);
end;

procedure TEngineWaveOutSoundDevice.Render(ABuffer: PByte; AByteCount: Integer);
begin
  FMixer.Render(ABuffer, AByteCount);
end;

end.
