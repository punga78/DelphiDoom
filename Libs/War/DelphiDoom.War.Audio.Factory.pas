{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the factory of the audio                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Audio.Factory;

interface

uses
  DelphiDoom.GameHost.Audio.Intf, DelphiDoom.War.Intf, DelphiDoom.War.Audio.Intf;

type
  /// <summary>
  ///   The only place that knows the concrete classes of the audio. In its own unit so that who uses the archive
  ///   and the graphics of Libs\War does not need Libs\Xmi and Libs\GameHost
  /// </summary>
  TWarAudioFactory = class
  public
    /// <summary>The converter of the songs: TXmiConverter of Libs\Xmi</summary>
    class function CreateMusicConverter: IWarMusicConverter; static;
    /// <summary>The sounds and songs of an archive</summary>
    class function CreateLibrary(const AArchive: IWarArchive; const ACatalog: IWarCatalog): IWarAudioLibrary; overload; static;
    /// <summary>The same with another converter (a fake in a test)</summary>
    class function CreateLibrary(const AArchive: IWarArchive; const ACatalog: IWarCatalog;
      const AConverter: IWarMusicConverter): IWarAudioLibrary; overload; static;
    class function CreateMixer(const ALibrary: IWarAudioLibrary): IWarSoundMixer; static;
    /// <summary>The mixer for IGameHostPcmOutput.Open(WAR_PLAYBACK_RATE, ...)</summary>
    class function CreatePcmSource(const AMixer: IWarSoundMixer): IGameHostPcmSource; static;
  end;

implementation

uses
  DelphiDoom.War.Audio.XmiMusicConverter, DelphiDoom.War.Audio.Records, DelphiDoom.War.Audio.Mixer,
  DelphiDoom.War.Audio.PcmSource;

{ TWarAudioFactory }

class function TWarAudioFactory.CreateMusicConverter: IWarMusicConverter;
begin
  Result := TWarXmiMusicConverter.Create;
end;

class function TWarAudioFactory.CreateLibrary(const AArchive: IWarArchive; const ACatalog: IWarCatalog): IWarAudioLibrary;
begin
  Result := CreateLibrary(AArchive, ACatalog, CreateMusicConverter);
end;

class function TWarAudioFactory.CreateLibrary(const AArchive: IWarArchive; const ACatalog: IWarCatalog;
  const AConverter: IWarMusicConverter): IWarAudioLibrary;
begin
  Result := TWarAudioLibrary.Create(AArchive, ACatalog, AConverter);
end;

class function TWarAudioFactory.CreateMixer(const ALibrary: IWarAudioLibrary): IWarSoundMixer;
begin
  Result := TWarSoundMixer.Create(ALibrary);
end;

class function TWarAudioFactory.CreatePcmSource(const AMixer: IWarSoundMixer): IGameHostPcmSource;
begin
  Result := TWarPcmSource.Create(AMixer);
end;

end.
