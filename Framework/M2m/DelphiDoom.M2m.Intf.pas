{******************************************************************************}
{                                                                              }
{  DelphiDoom: MIDI to MUS - contract shared by the engine and its clients     }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{  Derived from m2m by Colin Phipps (BSD licence)                              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.M2m.Intf;

interface

uses
  System.SysUtils;

const
  // Result codes (zero is success, every error is negative)
  M2M_OK = 0;
  M2M_ERROR_ARGUMENT = -1;   // nil or empty buffer
  M2M_ERROR_MIDI = -2;       // the data is not a Standard MIDI file that can be read
  M2M_ERROR_CONVERT = -3;    // the song cannot be written as MUS (type 2 file, track too big, ...)
  M2M_ERROR_BUFFER = -4;     // the destination buffer is too small
  M2M_ERROR_INTERNAL = -5;   // unexpected failure inside the library

type
  /// <summary>
  ///   Converts a Standard MIDI file (type 0 or 1) into the MUS format of Doom
  /// </summary>
  /// <remarks>
  ///   Only raw buffers and integers cross the interface: the caller owns
  ///   every buffer. Methods are stdcall so that the binary layout does not
  ///   depend on the compiler settings of the client
  /// </remarks>
  IM2m = interface
    ['{2C6A9D41-7E15-4B8F-A3D0-91F5E7B24C68}']

    /// <summary>
    ///   Converts AMidi to MUS and writes it to AMus
    /// </summary>
    /// <param name="AMus">Destination buffer, owned by the caller</param>
    /// <param name="AMusCapacity">Size of AMus in bytes</param>
    /// <param name="AMusSize">The bytes written, or the bytes needed when the result is M2M_ERROR_BUFFER</param>
    /// <returns>M2M_OK or a negative M2M_ERROR_* code</returns>
    function ConvertMidiToMus(AMidi: Pointer; AMidiSize: Cardinal; AMus: Pointer;
      AMusCapacity: Cardinal; out AMusSize: Cardinal): Integer; stdcall;
  end;

  /// <summary>
  ///   Raised by the classes that use the converter
  /// </summary>
  EM2mException = class(Exception)
  private
    FCode: Integer;
  public
    constructor CreateCode(ACode: Integer);
    class function TextOf(ACode: Integer): string; static;
    property Code: Integer read FCode;
  end;

implementation

{ EM2mException }

constructor EM2mException.CreateCode(ACode: Integer);
begin
  FCode := ACode;
  inherited CreateFmt('M2M error %d: %s', [ACode, TextOf(ACode)]);
end;

class function EM2mException.TextOf(ACode: Integer): string;
begin
  case ACode of
    M2M_OK:             Result := 'OK';
    M2M_ERROR_ARGUMENT: Result := 'Invalid argument';
    M2M_ERROR_MIDI:     Result := 'Not a readable MIDI file';
    M2M_ERROR_CONVERT:  Result := 'The song cannot be converted to MUS';
    M2M_ERROR_BUFFER:   Result := 'Buffer too small';
    M2M_ERROR_INTERNAL: Result := 'Internal error';
  else
    Result := 'Unknown error';
  end;
end;

end.
