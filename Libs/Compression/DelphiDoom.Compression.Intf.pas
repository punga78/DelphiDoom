{******************************************************************************}
{                                                                              }
{  DelphiDoom: compression library - ICompressor (idCompressor)                }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software): framework\Compressor.h.  }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Compression.Intf;

interface

uses
  System.SysUtils, System.Classes;

type
  /// <summary>
  ///   idCompressor: a layer on top of a stream that compresses what is written to it or decompresses what
  ///   is read from it (a compressor works in one direction, chosen in <c>Init</c>; the other direction
  ///   returns 0). The stream stays the caller's: the compressor never frees it and keeps no position
  ///   of its own. A compressed stream has no header: the reader must know the compressor, the word length
  ///   and how many bytes to ask for.
  /// </summary>
  ICompressor = interface
    ['{7B2E4C10-6A3D-4E58-8F19-0D5C2A9B1E01}']
    /// <summary>
    ///   Starts a compression (ACompress) or a decompression on AStream. AWordLength (1..32) is the size in
    ///   bits of the symbols of the bit stream compressors; the others ignore it.
    /// </summary>
    procedure Init(const AStream: TStream; ACompress: Boolean; AWordLength: Integer);
    /// <summary>Writes what is still buffered; call it after the last Write of a compression</summary>
    procedure FinishCompress;
    /// <summary>The saving in percent, 0 for no compression</summary>
    function GetCompressionRatio: Single;
    /// <summary>Decompresses up to ALength bytes into AData; returns the count</summary>
    function Read(AData: PByte; ALength: Integer): Integer; overload;
    /// <summary>Compresses ALength bytes of AData; returns the count</summary>
    function Write(AData: PByte; ALength: Integer): Integer; overload;
    function Read(var AData: TBytes; ALength: Integer): Integer; overload;
    function Write(const AData: TBytes): Integer; overload;
    /// <summary>The length of the stream underneath</summary>
    function Length: Integer;
    /// <summary>The position of the stream underneath</summary>
    function Tell: Integer;
    /// <summary>Always an error: a compressor cannot seek</summary>
    function Seek(AOffset: Integer; AOrigin: TSeekOrigin): Integer;
  end;

implementation

end.
