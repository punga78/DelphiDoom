{******************************************************************************}
{                                                                              }
{  DelphiDoom: audio library - the factory: the composition root                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Audio.Factory;

interface

uses
  System.SysUtils, DelphiDoom.Audio.Intf, DelphiDoom.Logging.Intf;

type
  /// <summary>The only place that knows the classes behind the audio contracts</summary>
  TAudioFactory = class
  public
    /// <summary>ADevice and ALog may be nil: without a device the player only gives handles</summary>
    class function CreateSfxPlayer(const ADevice: ISoundDevice;
      const ASource: ISfxSampleSource; const ALog: ILog): ISfxPlayer; static;
    /// <summary>The backends in the order they are asked about a song</summary>
    class function CreateMusicPlayer(const ABackends: TArray<IMusicBackend>): IMusicPlayer; static;
  end;

implementation

uses
  DelphiDoom.Audio.SfxPlayer, DelphiDoom.Audio.MusicPlayer;

{ TAudioFactory }

class function TAudioFactory.CreateSfxPlayer(const ADevice: ISoundDevice;
  const ASource: ISfxSampleSource; const ALog: ILog): ISfxPlayer;
begin
  Result := TSfxPlayer.Create(ADevice, ASource, ALog);
end;

class function TAudioFactory.CreateMusicPlayer(const ABackends: TArray<IMusicBackend>): IMusicPlayer;
begin
  Result := TMusicPlayer.Create(ABackends);
end;

end.
