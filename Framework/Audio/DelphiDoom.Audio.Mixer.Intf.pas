{******************************************************************************}
{                                                                              }
{  DelphiDoom: audio library - the contracts of the software mixer of the       }
{  sound effects                                                                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Audio.Mixer.Intf;

interface

uses
  System.SyncObjs,
  DelphiDoom.AudioMix.Intf,
  DelphiDoom.Audio.Types,
  DelphiDoom.Audio.Intf;

const
  /// <summary>CreateVoice answer for a sample the mixer cannot play (only PCM, 8 or 16 bit, one or two channels)</summary>
  SFX_MIXER_BAD_FORMAT = 1;

type
  /// <summary>
  ///   What a voice asks to the mixer that owns it: to be put in the list of the voices that play, and to be taken
  ///   out. The lock is the one of the list: the voice takes it to change its state while the audio thread mixes
  /// </summary>
  ISfxVoiceScheduler = interface
    ['{4B7E1D93-2A5C-4F08-B6D1-9E3A70C58F24}']
    function GetLock: TCriticalSection;
    /// <summary>Puts the voice at the end of the list; gives its handle</summary>
    function Start(const AVoice: IPcmVoice): Integer;
    procedure Remove(AHandle: Integer);
    property Lock: TCriticalSection read GetLock;
  end;

  /// <summary>
  ///   The sound effects mixed in software: it makes the voices and, called by the thread of the audio output, fills
  ///   a buffer of 16 bit stereo samples with the voices that play
  /// </summary>
  ISfxMixer = interface
    ['{D2A86F15-7C4B-4E90-A3B8-51F0E6C92D73}']
    /// <summary>A voice for the sample; 0 when done, else SFX_MIXER_BAD_FORMAT (AVoice is nil)</summary>
    function CreateVoice(const ASample: TSfxSample; out AVoice: IAudioVoice): Integer;
    /// <summary>Fills AByteCount bytes (a multiple of 4) with the sum of the voices that play; silence if none</summary>
    procedure Render(ABuffer: PByte; AByteCount: Integer);
    /// <summary>Stops every voice</summary>
    procedure Clear;
  end;

implementation

end.
