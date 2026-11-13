{******************************************************************************}
{                                                                              }
{  DelphiDoom: audio mix library - shared types                                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.AudioMix.Types;

interface

uses
  System.SysUtils;

type
  /// <summary>The audio data cannot be mixed or converted (a sample format that the strategy does not handle)</summary>
  EAudioMixException = class(Exception);

  /// <summary>
  ///   Samples as the decoders of the games give them: the bytes of the samples, interleaved by channel, 8 bits
  ///   unsigned or 16 bits signed little endian
  /// </summary>
  TPcmBuffer = record
    Channels: Cardinal;
    SampleRate: Cardinal;
    BitsPerSample: Cardinal;
    Data: TBytes;
  end;

resourcestring
  SAudioMixBadFormat = 'Cannot resample %d channels of %d bits';

implementation

end.
