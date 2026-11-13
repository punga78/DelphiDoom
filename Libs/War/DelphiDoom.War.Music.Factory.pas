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
  DelphiDoom.Logging.Intf, DelphiDoom.Midi.Intf, DelphiDoom.War.Music.Intf;

type
  /// <summary>
  ///   The only place that knows the concrete classes of the music. In its own unit: who uses it lists also the
  ///   units of Libs\Midi, Libs\M2m and Libs\Logging (see Tests\DelphiDoom.Tests.War.dpr)
  /// </summary>
  TWarMusicFactory = class
  public
    /// <summary>The synth that makes no sound</summary>
    class function CreateSilentSynth: IWarMusicSynth; static;
    /// <summary>The events of a song on a sequencer of Libs\Midi that is given (a fake in a test)</summary>
    class function CreateTimeline(const ASequencer: IMidiStreamSequencer): IWarMusicTimeline; overload; static;
    /// <summary>The events of a song on the real sequencer; ALog may be nil</summary>
    class function CreateTimeline(const ALog: ILog): IWarMusicTimeline; overload; static;
    /// <summary>The player with the timeline and the synth it is given, at WAR_PLAYBACK_RATE</summary>
    class function CreatePlayer(const ASynth: IWarMusicSynth; const ATimeline: IWarMusicTimeline): IWarMusicPlayer; static;
  end;

implementation

uses
  DelphiDoom.Midi.Factory, DelphiDoom.War.Audio.Types, DelphiDoom.War.Music.SilentSynth,
  DelphiDoom.War.Music.Timeline, DelphiDoom.War.Music.Player;

{ TWarMusicFactory }

class function TWarMusicFactory.CreateSilentSynth: IWarMusicSynth;
begin
  Result := TWarSilentMusicSynth.Create;
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
