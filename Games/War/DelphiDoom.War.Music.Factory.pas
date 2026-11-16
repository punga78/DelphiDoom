{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the factory of the music                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Music.Factory;

interface

uses
  DelphiDoom.Logging.Intf, DelphiDoom.Midi.Intf, DelphiDoom.Midi.Output.Intf, DelphiDoom.War.Music.Intf;

type
  /// <summary>
  ///   The only place that knows the concrete classes of the music. In its own unit: who uses it lists also the
  ///   units of Framework\Midi, Framework\M2m and Framework\Logging (see Tests\DelphiDoom.Tests.War.dpr)
  /// </summary>
  TWarMusicFactory = class
  public
    /// <summary>The synth that makes no sound</summary>
    class function CreateSilentSynth: IWarMusicSynth; static;
    /// <summary>The synth that sends the song to a MIDI output (a fake in a test)</summary>
    class function CreateMidiSynth(const AOutput: IMidiShortOutput): IWarMusicSynth; static;
    /// <summary>The MIDI output of Windows (the MIDI mapper); it is not opened</summary>
    class function CreateWindowsMidiOutput: IMidiShortOutput; static;
    /// <summary>The events of a song on a sequencer of Framework\Midi that is given (a fake in a test)</summary>
    class function CreateTimeline(const ASequencer: IMidiStreamSequencer): IWarMusicTimeline; overload; static;
    /// <summary>The events of a song on the real sequencer; ALog may be nil</summary>
    class function CreateTimeline(const ALog: ILog): IWarMusicTimeline; overload; static;
    /// <summary>The player with the timeline and the synth it is given, at WAR_PLAYBACK_RATE</summary>
    class function CreatePlayer(const ASynth: IWarMusicSynth; const ATimeline: IWarMusicTimeline): IWarMusicPlayer; static;
  end;

implementation

uses
  DelphiDoom.Midi.Factory, DelphiDoom.Midi.Win.ShortOutput, DelphiDoom.War.Audio.Types,
  DelphiDoom.War.Music.SilentSynth, DelphiDoom.War.Music.MidiSynth, DelphiDoom.War.Music.Timeline,
  DelphiDoom.War.Music.Player;

{ TWarMusicFactory }

class function TWarMusicFactory.CreateSilentSynth: IWarMusicSynth;
begin
  Result := TWarSilentMusicSynth.Create;
end;

class function TWarMusicFactory.CreateMidiSynth(const AOutput: IMidiShortOutput): IWarMusicSynth;
begin
  Result := TWarMidiMusicSynth.Create(AOutput);
end;

class function TWarMusicFactory.CreateWindowsMidiOutput: IMidiShortOutput;
begin
  Result := TMidiWinShortOutput.Create;
end;

class function TWarMusicFactory.CreateTimeline(const ASequencer: IMidiStreamSequencer): IWarMusicTimeline;
begin
  Result := TWarMusicTimeline.Create(ASequencer);
end;

class function TWarMusicFactory.CreateTimeline(const ALog: ILog): IWarMusicTimeline;
begin
  Result := TWarMusicTimeline.Create(TMidiFactory.CreateSequencer(ALog));
end;

class function TWarMusicFactory.CreatePlayer(const ASynth: IWarMusicSynth;
  const ATimeline: IWarMusicTimeline): IWarMusicPlayer;
begin
  Result := TWarMusicPlayer.Create(ASynth, ATimeline, WAR_PLAYBACK_RATE);
end;

end.
