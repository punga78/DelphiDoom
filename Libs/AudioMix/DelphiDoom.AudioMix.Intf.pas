{******************************************************************************}
{                                                                              }
{  DelphiDoom: audio mix library - contracts                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.AudioMix.Intf;

interface

uses
  DelphiDoom.AudioMix.Types;

type
  /// <summary>
  ///   Changes the sample rate of a buffer. The strategies differ in the formats they accept and in how they take
  ///   the samples (linear interpolation, nearest sample): each game keeps the one that gives its samples
  /// </summary>
  IPcmResampler = interface
    ['{6D0A4C71-2E93-4B58-A7F1-3C85B9E20D46}']
    /// <summary>The samples at ATargetRate; EAudioMixException for a format the strategy cannot handle</summary>
    function Resample(const ASource: TPcmBuffer; ATargetRate: Cardinal): TPcmBuffer;
  end;

  /// <summary>
  ///   One sound that plays. The voice adds its next samples to a destination that the caller owns: the type of the
  ///   sample (16 bit mono, 16 bit stereo, a wide sum) is a convention between the voice and the code that mixes, not
  ///   something the list knows. Called once per voice and per block, never per sample
  /// </summary>
  IPcmVoice = interface
    ['{B5E7219A-48C3-4D06-9F82-E1A60D7C3B54}']
    /// <summary>
    ///   Adds ACount units (samples or frames, as the voice defines them) to ADestination. True when the voice has
    ///   ended (or was stopped) and must leave the list
    /// </summary>
    function Mix(ADestination: Pointer; ACount: Integer): Boolean;
  end;

implementation

end.
