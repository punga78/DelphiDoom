{******************************************************************************}
{                                                                              }
{  DelphiDoom: PNG - writes the chunks of a PNG file into a buffer             }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Png.ChunkWriter;

interface

{$POINTERMATH ON}

type
  /// <summary>
  ///   Writes the signature and the chunks of a PNG file into a buffer of the
  ///   caller. Raises DDPNG_ERR_BUFFER_TOO_SMALL when the buffer is full
  /// </summary>
  TPngChunkWriter = class
  private
    FDest: PByte;
    FCapacity: Cardinal;
    FPosition: Cardinal;
    FChunkStart: Cardinal;
    FChunkType: Cardinal;
    FChunkOpen: Boolean;

    procedure Reserve(ACount: Int64);
  public
    constructor Create(ADest: Pointer; ACapacity: Cardinal);

    procedure WriteSignature;

    /// <summary>
    ///   Writes a whole chunk (AData is nil when ASize is 0)
    /// </summary>
    procedure WriteChunk(AChunkType: Cardinal; AData: PByte; ASize: Cardinal);

    /// <summary>
    ///   Starts a chunk whose data is written directly into the buffer by the
    ///   caller. AData is where the data goes and the result is how many
    ///   bytes fit there, leaving room for the CRC and for ATrailingBytes
    ///   more bytes that will follow the chunk
    /// </summary>
    function OpenChunk(AChunkType: Cardinal; ATrailingBytes: Cardinal;
      out AData: PByte): Cardinal;

    /// <summary>
    ///   Ends the chunk started by OpenChunk after ADataSize bytes of data
    /// </summary>
    procedure CloseChunk(ADataSize: Cardinal);

    /// <summary>
    ///   Bytes written so far
    /// </summary>
    property Position: Cardinal read FPosition;
  end;

implementation

uses
  DelphiDoom.Png.Intf, DelphiDoom.Png.ByteOrder, DelphiDoom.Png.Crc,
  DelphiDoom.Png.ChunkReader;

{ TPngChunkWriter }

constructor TPngChunkWriter.Create(ADest: Pointer; ACapacity: Cardinal);
begin
  inherited Create;
  FDest := ADest;
  FCapacity := ACapacity;
end;

procedure TPngChunkWriter.Reserve(ACount: Int64);
begin
  if Int64(FPosition) + ACount > Int64(FCapacity) then
    raise EPngException.CreateCode(DDPNG_ERR_BUFFER_TOO_SMALL);
end;

procedure TPngChunkWriter.WriteSignature;
begin
  Reserve(PNG_SIGNATURE_SIZE);
  Move(PNG_SIGNATURE, FDest[FPosition], PNG_SIGNATURE_SIZE);
  Inc(FPosition, PNG_SIGNATURE_SIZE);
end;

procedure TPngChunkWriter.WriteChunk(AChunkType: Cardinal; AData: PByte;
  ASize: Cardinal);
var
  LData: PByte;
begin
  Reserve(Int64(ASize) + PNG_CHUNK_OVERHEAD);
  if OpenChunk(AChunkType, 0, LData) < ASize then
    raise EPngException.CreateCode(DDPNG_ERR_BUFFER_TOO_SMALL);
  if ASize > 0 then
    Move(AData^, LData^, ASize);
  CloseChunk(ASize);
end;

function TPngChunkWriter.OpenChunk(AChunkType: Cardinal;
  ATrailingBytes: Cardinal; out AData: PByte): Cardinal;
var
  LFixed: Int64;
begin
  if FChunkOpen then
    raise EPngException.CreateCode(DDPNG_ERR_INTERNAL);

  // Length and type before the data, CRC after it, then what follows
  LFixed := PNG_CHUNK_OVERHEAD + Int64(ATrailingBytes);
  Reserve(LFixed);

  FChunkStart := FPosition;
  FChunkType := AChunkType;
  FChunkOpen := True;
  AData := FDest + FPosition + 8;
  Result := Cardinal(Int64(FCapacity) - Int64(FPosition) - LFixed);
end;

procedure TPngChunkWriter.CloseChunk(ADataSize: Cardinal);
var
  LStart: PByte;
begin
  if not FChunkOpen then
    raise EPngException.CreateCode(DDPNG_ERR_INTERNAL);
  FChunkOpen := False;

  LStart := FDest + FChunkStart;
  TPngByteOrder.WriteCardinal(LStart, ADataSize);
  // The type is kept as the Cardinal that reads the four letters in order
  PCardinal(LStart + 4)^ := FChunkType;
  // The CRC covers the type and the data, not the length
  TPngByteOrder.WriteCardinal(LStart + 8 + ADataSize,
    TPngCrc.Compute(LStart + 4, ADataSize + 4));

  FPosition := FChunkStart + PNG_CHUNK_OVERHEAD + ADataSize;
end;

end.
