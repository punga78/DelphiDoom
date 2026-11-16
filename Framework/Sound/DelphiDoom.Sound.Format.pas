{******************************************************************************}
{                                                                              }
{  DelphiDoom: sound decoder - contract of a sound format                      }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Sound.Format;

interface

uses
  System.SysUtils, DelphiDoom.Sound.Samples;

type
  /// <summary>
  ///   A container (WAV, VOC, FLAC, Ogg...) that can be decoded to samples.
  ///   TSoundEngine receives the list of formats it knows from its creator
  /// </summary>
  ISoundFormat = interface
    ['{4C0F9A1E-6F0B-4C2E-9D43-2D1B5E7A8C61}']

    /// <summary>
    ///   Decodes the whole sound. Returns SNDFILE_ERR_UNRECOGNISED_FORMAT, and
    ///   no samples, if ASource is not of this format; any other code means
    ///   that it is, but the data is damaged or uses an unsupported encoding
    /// </summary>
    function Decode(const ASource: TBytes; out ASamples: TSoundSamples): Integer;
  end;

implementation

end.
