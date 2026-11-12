{******************************************************************************}
{                                                                              }
{  DelphiDoom: Keen32 - the composition root                                    }
{  Port of Commander Keen in Keen Dreams (id Software), GPL v2 or later         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.Composition;

interface

uses
  System.SysUtils, DelphiDoom.Keen.Types, DelphiDoom.Keen.GameTypes, DelphiDoom.Keen.Intf, DelphiDoom.Clock.Intf,
  DelphiDoom.Keen.HostAudio;

type
  /// <summary>The sound of the game, assembled: the manager that the game calls, the mixer and the output</summary>
  TKeenAudioSet = record
    Sound: IKeenSoundManager;
    Mixer: IKeenAudioMixer;
    /// <summary>The object behind HostKeeper, for Open, Close and Pump</summary>
    Host: TKeenHostAudio;
    HostKeeper: IInterface;
  end;

  /// <summary>
  ///   The one place of Keen32 that knows the classes behind the interfaces: the libraries of the keen port
  ///   (Libs\Keen) and the ones that it shares with the Doom engine (video palette, PNG, files). It does not touch
  ///   ComposeEngine nor TIdTechGeneration: Keen Dreams is not an id Tech 1 game
  /// </summary>
  TKeenComposition = class
  public
    /// <summary>The data files in the given folders, opened</summary>
    class function OpenGameData(const AFolders: array of string): IKeenGameData; static;
    /// <summary>What saves the picture of a map of ADataFolders as a PNG file</summary>
    class function CreateMapExporter(const AData: IKeenGameData): IKeenMapExporter; static;
    /// <summary>What saves the screen of the game (the tile refresh manager on the EGA memory) for a map and a position</summary>
    class function CreateViewExporter(const AData: IKeenGameData): IKeenViewExporter; static;
    /// <summary>The clock of the machine</summary>
    class function CreateClock: IClock; static;
    /// <summary>
    ///   The sound manager (PC speaker and AdLib card on the OPL emulator), its mixer and the waveOut output, not
    ///   opened. AUseDevice false leaves the output out (the time of the sound then goes on with Host.Pump).
    ///   AIdle is what a wait for the end of a sound does between two looks; nil sleeps a millisecond
    /// </summary>
    class function CreateAudio(const AData: IKeenGameData; const AClock: IClock; AUseDevice: Boolean;
      const AIdle: TProc): TKeenAudioSet; static;
    /// <summary>
    ///   Plays a sound of the game to its end and gives what the mixer and the device did, as a line of text:
    ///   the check of the sound that needs no ears
    /// </summary>
    class function PlaySoundReport(const AData: IKeenGameData; ASound: Integer; AMode: TKeenSoundMode;
      AUseDevice: Boolean): string; static;
  end;

implementation

uses
  DelphiDoom.Keen.Factory, DelphiDoom.Keen.PngEncoder, DelphiDoom.Keen.MapExporter, DelphiDoom.Keen.ViewExporter,
  DelphiDoom.Png.Provider, DelphiDoom.Png.IndexedEncoder, DelphiDoom.Platform.Factory, DelphiDoom.Clock.Factory,
  DelphiDoom.Opl.Factory, DelphiDoom.GameHost.Factory, DelphiDoom.GameHost.Audio.Intf, DelphiDoom.Keen.SoundManager,
  DelphiDoom.Keen.SpeakerSynth, DelphiDoom.Keen.OplAdLib, DelphiDoom.Keen.AudioLock, DelphiDoom.Keen.AudioMixer,
  DelphiDoom.Keen.LockedSoundManager;

const
  /// <summary>Samples per second of the sound of the game</summary>
  KEEN_AUDIO_RATE = 44100;

{ TKeenComposition }

class function TKeenComposition.OpenGameData(const AFolders: array of string): IKeenGameData;
begin
  Result := TKeenFactory.OpenGameData(TKeenFactory.CreateFolderFiles(AFolders));
end;

class function TKeenComposition.CreateMapExporter(const AData: IKeenGameData): IKeenMapExporter;
begin
  Result := TKeenMapExporter.Create(AData, TKeenFactory.CreateMapRenderer,
    TKeenPngEncoder.Create(TPngIndexedEncoder.Create(TPngProvider.Client)),
    TPlatformFactory.CreateFileStore);
end;

class function TKeenComposition.CreateViewExporter(const AData: IKeenGameData): IKeenViewExporter;
begin
  Result := TKeenViewExporter.Create(AData,
    TKeenPngEncoder.Create(TPngIndexedEncoder.Create(TPngProvider.Client)),
    TPlatformFactory.CreateFileStore);
end;

class function TKeenComposition.CreateClock: IClock;
begin
  Result := TClockFactory.CreateClock(nil);
end;

class function TKeenComposition.CreateAudio(const AData: IKeenGameData; const AClock: IClock; AUseDevice: Boolean;
  const AIdle: TProc): TKeenAudioSet;
var
  LSpeaker: TKeenSpeakerSynth;
  LCard: TKeenOplAdLib;
  LLock: IKeenAudioLock;
  LInner: IKeenSoundManager;
  LOutput: IGameHostPcmOutput;
  LHost: TKeenHostAudio;
  LClock: IClock;
  LIdle: TProc;
begin
  LSpeaker := TKeenSpeakerSynth.Create(KEEN_AUDIO_RATE);
  LCard := TKeenOplAdLib.Create(TOplFactory.CreateChip(KEEN_ADLIB_CLOCK, KEEN_AUDIO_RATE));
  LLock := TKeenAudioLock.Create;
  LInner := TKeenSoundManager.Create(AData.Audio, LSpeaker, LCard);
  Result.Mixer := TKeenAudioMixer.Create(LInner, [LSpeaker as IKeenSampleSource, LCard as IKeenSampleSource], LLock,
    KEEN_AUDIO_RATE);
  if AUseDevice then
    LOutput := TGameHostFactory.CreatePcmOutput
  else
    LOutput := nil;
  LHost := TKeenHostAudio.Create(Result.Mixer, LOutput, AClock);
  Result.Host := LHost;
  Result.HostKeeper := LHost;
  LClock := AClock;
  LIdle := AIdle;
  Result.Sound := TKeenLockedSoundManager.Create(LInner, LLock,
    procedure
    begin
      LHost.Pump;
      if Assigned(LIdle) then
        LIdle()
      else
        LClock.Sleep(1);
    end);
end;

class function TKeenComposition.PlaySoundReport(const AData: IKeenGameData; ASound: Integer; AMode: TKeenSoundMode;
  AUseDevice: Boolean): string;
var
  LAudio: TKeenAudioSet;
  LClock: IClock;
  LDevice: Boolean;
  LStart: Double;
  LStatistics: TKeenAudioStatistics;
begin
  LClock := CreateClock;
  LAudio := CreateAudio(AData, LClock, AUseDevice, nil);
  try
    if not LAudio.Sound.TrySetMode(AMode) then
      raise EKeenException.Create(SKeenSoundModeRefused);
    LDevice := LAudio.Host.Open;
    LStart := LClock.Seconds;
    LAudio.Sound.PlaySound(ASound);
    // the sound 0 reads as none (SD_SoundPlaying of the C): it is given half a second
    if ASound = 0 then
      while LClock.Seconds - LStart < 0.5 do
      begin
        LAudio.Host.Pump;
        LClock.Sleep(1);
      end
    else
      LAudio.Sound.WaitSoundDone;
    // the release of the last note and the buffers that the device still has
    LStart := LClock.Seconds;
    while LClock.Seconds - LStart < 0.25 do
    begin
      LAudio.Host.Pump;
      LClock.Sleep(1);
    end;
    LStatistics := LAudio.Mixer.Statistics;
    Result := Format('sound %d mode %d device %d: services %d, frames %d, audible frames %d, peak %d, buffers played %d',
      [ASound, Ord(AMode), Ord(LDevice), LStatistics.Services, LStatistics.Frames, LStatistics.AudibleFrames,
       LStatistics.Peak, LAudio.Host.CompletedBuffers]);
  finally
    LAudio.Host.Close;
  end;
end;

end.
