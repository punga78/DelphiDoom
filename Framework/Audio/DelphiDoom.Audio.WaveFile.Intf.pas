{******************************************************************************}
{                                                                              }
{  DelphiDoom: audio library - what a wave file needs from the engine          }
{                                                                              }
{  Small contracts for the file system and for the OGG decoder that            }
{  idWaveFile reaches through fileSystem and the Vorbis library.               }
{  Based on the Doom 3 GPL Source Code (id Software); GPL v3 with the          }
{  additional terms of the Doom 3 Source Code License, as DelphiDoom.Audio.    }
{  WaveFile.Types. Copyright (C) 1999-2011 id Software LLC.                    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Audio.WaveFile.Intf;

interface

uses
  System.SysUtils, DelphiDoom.Audio.WaveFile.Types;

type
  /// <summary>The part of <c>idFileSystem</c> that <c>idWaveFile::Open</c> uses</summary>
  IWaveFileSystem = interface
    ['{3F6A8C14-95D2-4B7E-A1C0-52E4D8B67F31}']
    /// <summary><c>ReadFile(name, NULL, NULL)</c>: the length of the file, -1 if there is none</summary>
    function FileLength(const AName: string): Integer;
    /// <summary><c>OpenFileRead</c> and the whole file: False when there is no such file</summary>
    function TryReadFile(const AName: string; out AData: TBytes): Boolean;
    /// <summary><c>idFile::Timestamp</c>: 0 when the file is not in a folder (as the files of a pak)</summary>
    function Timestamp(const AName: string): Int64;
  end;

  /// <summary>The Vorbis decoder that <c>OpenOGG</c> uses: <c>ov_open</c>, <c>ov_info</c>, <c>ov_pcm_total</c> and <c>ov_read</c></summary>
  IWaveOggDecoder = interface
    ['{3F6A8C14-95D2-4B7E-A1C0-52E4D8B67F32}']
    /// <summary>
    ///   Decodes a whole OGG Vorbis file to 16-bit little endian interleaved samples; False if it is
    ///   not one (<c>ov_openFile</c> fails)
    /// </summary>
    function TryDecode(const AData: TBytes; out AChannels: Integer; out ASamplesPerSecond: Cardinal;
      out APcm: TBytes): Boolean;
  end;

implementation

end.
