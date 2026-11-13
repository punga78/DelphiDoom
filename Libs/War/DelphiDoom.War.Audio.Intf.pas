{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - audio contracts                                   }
{                                                                              }
{  Port of war1 (acoto87/war1), war_audio.c and wres_loadXmi/Wave/Voc of       }
{  war_resources.c, (c) 2019 Alejandro Coto Gutierrez, zlib License (see       }
{  Libs\War\LICENSE-war1.txt). This is an altered version, not the original.   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Audio.Intf;

interface

uses
  System.SysUtils, DelphiDoom.War.Audio.Types;

type
  /// <summary>Turns the bytes of an XMI song into a standard MIDI file: how the game gets its music</summary>
  IWarMusicConverter = interface
    ['{4D1B7E93-0A26-4C58-9E3F-71B2C86D5A04}']
    /// <summary>False if the data are not a convertible song</summary>
    function TryConvert(const AXmi: TBytes; out AMidi: TBytes): Boolean;
  end;

  /// <summary>The sounds and the songs of DATA.WAR, ready to play</summary>
  IWarAudioLibrary = interface
    ['{A2E58C10-93D7-4F46-B8A1-0C5D3E92F7B6}']
    /// <summary>What the record AIndex plays; EWarException if it is not a song or a sound</summary>
    function KindOf(AIndex: Integer): TWarAudioKind;
    /// <summary>
    ///   The sound of a VOC or WAVE record at WAR_PLAYBACK_RATE (wres_loadVoc, wres_loadWave); the mixer reads
    ///   it as 8 bit unsigned mono. EWarException if it is not a sound or cannot be decoded
    /// </summary>
    function GetSound(AIndex: Integer): TWarPcmBuffer;
    /// <summary>The standard MIDI file of an XMID record (wres_loadXmi); EWarException if it cannot be converted</summary>
    function GetMusic(AIndex: Integer): TBytes;
  end;

  /// <summary>The effects of the game: voices that play a sound, mixed to 16 bit mono at WAR_PLAYBACK_RATE</summary>
  IWarSoundMixer = interface
    ['{7C3F90D2-18B4-4E65-A0D9-5B6E21C48F37}']
    /// <summary>Starts a sound that has no place on the map; returns the handle of the voice</summary>
    function Play(ASoundIndex: Integer; ALoop: Boolean): Integer;
    /// <summary>Starts a sound that has a place on the map (pixels): outside the viewport it is quieter</summary>
    function PlayAt(ASoundIndex: Integer; AX, AY: Single; ALoop: Boolean): Integer;
    procedure Stop(AHandle: Integer);
    procedure StopAll;
    /// <summary>The rectangle of the map that is on screen, in pixels</summary>
    procedure SetViewport(AX, AY, AWidth, AHeight: Single);
    /// <summary>soundVolume and soundEnabled of the context</summary>
    procedure SetVolume(AVolume: Single; AEnabled: Boolean);
    /// <summary>
    ///   While True nothing is heard (the original does it during the change of scene): the voices do not advance
    /// </summary>
    procedure SetSilenced(ASilenced: Boolean);
    /// <summary>Adds ASampleCount samples of the voices to ABuffer (it does not clear it); finished voices go away</summary>
    procedure Mix(ABuffer: PSmallInt; ASampleCount: Integer);
    function ActiveVoices: Integer;
  end;

implementation

end.
