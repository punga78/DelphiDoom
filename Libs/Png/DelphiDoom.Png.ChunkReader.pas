{******************************************************************************}
{                                                                              }
{  DelphiDoom: PNG - reads the chunks of a PNG file held in memory             }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Png.ChunkReader;

interface

{$POINTERMATH ON}

const
  // Chunk types, as the Cardinal that the four bytes of the type make when
  // they are read in memory order on a little-endian machine ('I' is the
  // lowest byte of IHDR)
  PNG_CHUNK_IHDR = $52444849;  // 'I', 'H', 'D', 'R'
  PNG_CHUNK_PLTE = $45544C50;  // 'P', 'L', 'T', 'E'
  PNG_CHUNK_IDAT = $54414449;  // 'I', 'D', 'A', 'T'
  PNG_CHUNK_IEND = $444E4549;  // 'I', 'E', 'N', 'D'
  PNG_CHUNK_TRNS = $534E5274;  // 't', 'R', 'N', 'S'
  PNG_CHUNK_GRAB = $62417267;  // 'g', 'r', 'A', 'b'

  // Size of the signature at the beginning of the file and of the fields of
  // a chunk around its data (length, type, CRC)
  PNG_SIGNATURE_SIZE = 8;
  PNG_CHUNK_OVERHEAD = 12;

  // The first eight bytes of every PNG file
  PNG_SIGNATURE: array[0..PNG_SIGNATURE_SIZE - 1] of Byte =
    ($89, $50, $4E, $47, $0D, $0A, $1A, $0A);

type
  /// <summary>
  ///   One chunk: Data points into the buffer the reader works on
  /// </summary>
  TPngChunk = record
    ChunkType: Cardinal;
    Data: PByte;
    Size: Cardinal;

    /// <summary>
    ///   True if a decoder that does not know the chunk cannot decode the
    ///   image (the chunk is not ancillary)
    /// </summary>
    function IsCritical: Boolean;
  end;

  /// <summary>
  ///   Walks the chunks of a PNG file held in a buffer, checking the
  ///   signature, the lengths and the CRC. Every failure is an EPngException
  /// </summary>
  TPngChunkReader = class
  private
    FSource: PByte;
    FSize: Cardinal;
    FPosition: Cardinal;
  public
    constructor Create(ASource: Pointer; ASize: Cardinal);

    /// <summary>
    ///   Checks the eight bytes at the beginning of the file and skips them.
    ///   DDPNG_ERR_DATA if they are not the signature of a PNG file,
    ///   DDPNG_ERR_TRUNCATED if the file ends before them but what is there
    ///   is the beginning of the signature
    /// </summary>
    procedure ReadSignature;

    /// <summary>
    ///   Reads the chunk at the current position. The CRC is checked for every
    ///   chunk but the IDAT ones, which are large: those are checked only if
    ///   AVerifyImageData is True
    /// </summary>
    /// <returns>
    ///   The chunk, valid until the buffer is released. Raises
    ///   DDPNG_ERR_TRUNCATED if the file ends inside it, DDPNG_ERR_CRC if the
    ///   CRC is wrong and DDPNG_ERR_DATA if its length is not valid
    /// </returns>
    function Next(AVerifyImageData: Boolean): TPngChunk;

    function AtEnd: Boolean;

    /// <summary>
    ///   Offset in the buffer of the next chunk; it can be set to a value that
    ///   was read to go back to a chunk
    /// </summary>
    property Position: Cardinal read FPosition write FPosition;
  end;

implementation

uses
  DelphiDoom.Png.Intf, DelphiDoom.Png.ByteOrder, DelphiDoom.Png.Crc;

const
  // Largest length of a chunk the specification allows
  PNG_MAX_CHUNK_SIZE = $7FFFFFFF;

{ TPngChunk }

function TPngChunk.IsCritical: Boolean;
begin
  // Bit 5 of the first letter: lower case means ancillary
  Result := (ChunkType and $20) = 0;
end;

{ TPngChunkReader }

constructor TPngChunkReader.Create(ASource: Pointer; ASize: Cardinal);
begin
  inherited Create;
  FSource := ASource;
  FSize := ASize;
  FPosition := 0;
end;

procedure TPngChunkReader.ReadSignature;
var
  LAvailable: Cardinal;
  LIndex: Cardinal;
begin
  LAvailable := FSize;
  if LAvailable > PNG_SIGNATURE_SIZE then
    LAvailable := PNG_SIGNATURE_SIZE;

  // A while loop: the bound would wrap around for an empty buffer
  LIndex := 0;
  while LIndex < LAvailable do
  begin
    if FSource[LIndex] <> PNG_SIGNATURE[LIndex] then
      raise EPngException.CreateCode(DDPNG_ERR_DATA);
    Inc(LIndex);
  end;

  if FSize < PNG_SIGNATURE_SIZE then
    raise EPngException.CreateCode(DDPNG_ERR_TRUNCATED);

  FPosition := PNG_SIGNATURE_SIZE;
end;

function TPngChunkReader.Next(AVerifyImageData: Boolean): TPngChunk;
var
  LLength: Cardinal;
  LStart: PByte;
  LExpectedCrc: Cardinal;
begin
  if Int64(FPosition) + 8 > Int64(FSize) then
    raise EPngException.CreateCode(DDPNG_ERR_TRUNCATED);

  LStart := FSource + FPosition;
  LLength := TPngByteOrder.ReadCardinal(LStart);
  if LLength > PNG_MAX_CHUNK_SIZE then
    raise EPngException.CreateCode(DDPNG_ERR_DATA);

  // The chunk is the length, the type, the data and the CRC
  if Int64(FPosition) + PNG_CHUNK_OVERHEAD + Int64(LLength) > Int64(FSize) then
    raise EPngException.CreateCode(DDPNG_ERR_TRUNCATED);

  Result.ChunkType := PCardinal(LStart + 4)^;
  Result.Data := LStart + 8;
  Result.Size := LLength;

  if AVerifyImageData or (Result.ChunkType <> PNG_CHUNK_IDAT) then
  begin
    // The CRC covers the type and the data, not the length
    LExpectedCrc := TPngByteOrder.ReadCardinal(LStart + 8 + LLength);
    if TPngCrc.Compute(LStart + 4, LLength + 4) <> LExpectedCrc then
      raise EPngException.CreateCode(DDPNG_ERR_CRC);
  end;

  FPosition := FPosition + PNG_CHUNK_OVERHEAD + LLength;
end;

function TPngChunkReader.AtEnd: Boolean;
begin
  Result := FPosition >= FSize;
end;

end.
