{******************************************************************************}
{                                                                              }
{  DelphiDoom: XMI/CMF - contract shared by the DLL and its clients            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Xmi.Intf;

interface

uses
  System.SysUtils;

{$SCOPEDENUMS ON}

const
  // Result codes (zero is success, every error is negative)
  XMI_OK = 0;
  XMI_ERROR_ARGUMENT = -1;   // nil buffer, empty buffer or buffer too large
  XMI_ERROR_FORMAT = -2;     // the data is not in a format that can be converted
  XMI_ERROR_DATA = -3;       // the format is recognized but the data is corrupted
  XMI_ERROR_TRACK = -4;      // the requested track does not exist
  XMI_ERROR_BUFFER = -5;     // the destination buffer is too small
  XMI_ERROR_MEMORY = -6;     // out of memory
  XMI_ERROR_INTERNAL = -7;   // unexpected failure inside the library

  // Name of the DLL and of its only export
  DDXMI_LIBRARY_NAME = 'DDXmi.dll';
  DDXMI_CREATE_EXPORT = 'DDXmiCreate';

type
  /// <summary>
  ///   Music formats the library can tell apart. IXmi.DetectFormat returns
  ///   the ordinal value
  /// </summary>
  TXmiFormat = (
    Unknown = 0,
    /// <summary>Extended MIDI (Miles Sound System), IFF container</summary>
    Xmi = 1,
    /// <summary>Creative Music File (Sound Blaster / AdLib)</summary>
    Cmf = 2,
    /// <summary>Sopepos (AdLib, 4 operators)</summary>
    Sop = 3,
    /// <summary>Standard MIDI file: nothing to convert</summary>
    Midi = 4
  );

  /// <summary>
  ///   Contract of the XMI/CMF DLL: converts the formats of the DOS sound
  ///   drivers into standard MIDI
  /// </summary>
  /// <remarks>
  ///   Only raw buffers and integers cross the DLL boundary: the caller owns
  ///   every buffer, the DLL never allocates memory the caller has to free.
  ///   Methods are stdcall so that the binary layout does not depend on the
  ///   compiler settings of the client.
  ///   The converter keeps global state: calls are serialized by the DLL, but
  ///   all of them must be made from one thread (the one that made the first
  ///   call), because the code underneath uses a hidden window
  /// </remarks>
  IXmi = interface
    ['{B47D0E52-6A19-4C83-9F2E-5D1A7C3B8E40}']

    /// <summary>
    ///   Tells which format ASource is, looking at its content
    /// </summary>
    /// <returns>
    ///   Ord(TXmiFormat); Ord(TXmiFormat.Unknown) for a nil or empty buffer
    ///   and for data that is not recognized; XMI_ERROR_INTERNAL if the
    ///   library failed
    /// </returns>
    function DetectFormat(ASource: Pointer; ASourceSize: Cardinal): Integer; stdcall;

    /// <summary>
    ///   Number of tracks (songs) a convertible buffer contains: XMI files can
    ///   hold several songs, CMF files hold one
    /// </summary>
    /// <returns>
    ///   XMI_OK, XMI_ERROR_FORMAT if the buffer is not XMI, CMF or SOP,
    ///   XMI_ERROR_DATA if it is corrupted, or another error code
    /// </returns>
    function GetTrackCount(ASource: Pointer; ASourceSize: Cardinal;
      out ATrackCount: Cardinal): Integer; stdcall;

    /// <summary>
    ///   Converts track ATrack (zero based) of an XMI, CMF or SOP buffer into
    ///   a standard MIDI file. ADestSize is the size of ADest on input and the
    ///   size of the MIDI file on output
    /// </summary>
    /// <returns>
    ///   XMI_OK; XMI_ERROR_BUFFER if ADest is nil or too small, and then
    ///   ADestSize is the size needed (call again with a buffer of that
    ///   size: the converted data is kept until the next call that
    ///   completes); XMI_ERROR_FORMAT also for a buffer that already is
    ///   standard MIDI; XMI_ERROR_TRACK if ATrack does not exist; or another
    ///   error code
    /// </returns>
    function ConvertToMidi(ASource: Pointer; ASourceSize: Cardinal;
      ATrack: Cardinal; ADest: Pointer; var ADestSize: Cardinal): Integer; stdcall;
  end;

  /// <summary>
  ///   Signature of the export DDXMI_CREATE_EXPORT of the DLL. Returns XMI_OK
  ///   and an IXmi on success
  /// </summary>
  TDDXmiCreate = function(out AXmi: IXmi): Integer; stdcall;

  /// <summary>
  ///   Raised by the classes that wrap the DLL
  /// </summary>
  EXmiException = class(Exception)
  private
    FCode: Integer;
  public
    constructor CreateCode(ACode: Integer);
    class function TextOf(ACode: Integer): string; static;
    property Code: Integer read FCode;
  end;

implementation

{ EXmiException }

constructor EXmiException.CreateCode(ACode: Integer);
begin
  FCode := ACode;
  inherited CreateFmt('XMI error %d: %s', [ACode, TextOf(ACode)]);
end;

class function EXmiException.TextOf(ACode: Integer): string;
begin
  case ACode of
    XMI_OK:             Result := 'OK';
    XMI_ERROR_ARGUMENT: Result := 'Invalid argument';
    XMI_ERROR_FORMAT:   Result := 'Unsupported format';
    XMI_ERROR_DATA:     Result := 'Corrupted data';
    XMI_ERROR_TRACK:    Result := 'Track not found';
    XMI_ERROR_BUFFER:   Result := 'Buffer too small';
    XMI_ERROR_MEMORY:   Result := 'Insufficient memory';
    XMI_ERROR_INTERNAL: Result := 'Internal error';
  else
    Result := 'Unknown error';
  end;
end;

end.
