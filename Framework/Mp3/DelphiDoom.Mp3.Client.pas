{******************************************************************************}
{                                                                              }
{  DelphiDoom: mp3 - the class the engine uses in place of the library         }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Mp3.Client;

interface

uses
  System.SysUtils, DelphiDoom.Mp3.Intf;

const
  // Size of the PCM blocks Drain asks the decoder for
  MP3_CLIENT_PCM_BLOCK_SIZE = 64 * 1024;

type
  /// <summary>
  ///   Stands for the MP3 decoder in the rest of the engine: works with TBytes
  ///   and raises EMp3Exception instead of returning error codes
  /// </summary>
  /// <remarks>
  ///   Depends only on IMp3, so it works the same with the DLL (see
  ///   TMp3Loader) and with an engine linked in the executable, or with a
  ///   fake in the tests. Destroy it before the loader that supplied the IMp3
  /// </remarks>
  TMp3Client = class
  private
    FDecoder: IMp3Decoder;
    class procedure Check(ACode: Integer); static;
    function GetFrequency: Cardinal;
    function GetChannels: Cardinal;
    function GetPendingSize: Cardinal;
  public
    /// <param name="AChannels">One of the MP3_CHANNELS_* values</param>
    /// <param name="AVolume">Percentage, MP3_VOLUME_MIN..MP3_VOLUME_MAX</param>
    constructor Create(const AMp3: IMp3; AChannels: Integer = MP3_CHANNELS_BOTH;
      AVolume: Integer = MP3_DEFAULT_VOLUME);

    procedure Feed(const AData: TBytes); overload;
    procedure Feed(AData: Pointer; ASize: Cardinal); overload;

    /// <summary>
    ///   Decodes into a buffer of the caller. AWritten is the number of bytes
    ///   written
    /// </summary>
    /// <returns>
    ///   True when the buffer is full and more PCM may be available, False
    ///   when the input fed so far is exhausted
    /// </returns>
    function Decode(APcm: Pointer; APcmSize: Cardinal;
      out AWritten: Cardinal): Boolean;

    /// <summary>
    ///   Decodes everything the input fed so far allows
    /// </summary>
    function Drain: TBytes;

    /// <summary>
    ///   Decodes a whole MP3 file held in memory
    /// </summary>
    function DecodeAll(const AMp3Data: TBytes): TBytes;

    /// <summary>
    ///   Drops the input and the state of the decoder (to play a track again)
    /// </summary>
    procedure Reset;

    /// <summary>Sampling rate in Hz, 0 until the first frame is found</summary>
    property Frequency: Cardinal read GetFrequency;

    /// <summary>PCM channels (1 or 2), 0 until the first frame is found</summary>
    property Channels: Cardinal read GetChannels;

    /// <summary>Bytes fed and not consumed yet</summary>
    property PendingSize: Cardinal read GetPendingSize;
  end;

implementation

{ TMp3Client }

constructor TMp3Client.Create(const AMp3: IMp3; AChannels, AVolume: Integer);
begin
  inherited Create;
  if not Assigned(AMp3) then
    raise EArgumentNilException.Create('AMp3');
  Check(AMp3.CreateDecoder(AChannels, AVolume, FDecoder));
end;

class procedure TMp3Client.Check(ACode: Integer);
begin
  // MP3_NEED_DATA is not a failure
  if ACode < MP3_OK then
    raise EMp3Exception.CreateCode(ACode);
end;

function TMp3Client.GetFrequency: Cardinal;
begin
  Result := FDecoder.GetFrequency;
end;

function TMp3Client.GetChannels: Cardinal;
begin
  Result := FDecoder.GetChannels;
end;

function TMp3Client.GetPendingSize: Cardinal;
begin
  Result := FDecoder.GetPendingSize;
end;

procedure TMp3Client.Feed(const AData: TBytes);
begin
  Feed(Pointer(AData), Cardinal(Length(AData)));
end;

procedure TMp3Client.Feed(AData: Pointer; ASize: Cardinal);
begin
  Check(FDecoder.Feed(AData, ASize));
end;

function TMp3Client.Decode(APcm: Pointer; APcmSize: Cardinal;
  out AWritten: Cardinal): Boolean;
var
  LCode: Integer;
begin
  LCode := FDecoder.Decode(APcm, APcmSize, AWritten);
  Check(LCode);
  Result := LCode = MP3_OK;
end;

function TMp3Client.Drain: TBytes;
var
  LUsed: Integer;
  LWritten: Cardinal;
  LMore: Boolean;
begin
  Result := nil;
  LUsed := 0;
  repeat
    if Length(Result) - LUsed < MP3_CLIENT_PCM_BLOCK_SIZE then
      SetLength(Result, Length(Result) * 2 + MP3_CLIENT_PCM_BLOCK_SIZE);
    LMore := Decode(PByte(Result) + LUsed, Cardinal(Length(Result) - LUsed),
      LWritten);
    Inc(LUsed, Integer(LWritten));
  until not LMore;
  SetLength(Result, LUsed);
end;

function TMp3Client.DecodeAll(const AMp3Data: TBytes): TBytes;
begin
  Feed(AMp3Data);
  Result := Drain;
end;

procedure TMp3Client.Reset;
begin
  Check(FDecoder.Reset);
end;

end.
