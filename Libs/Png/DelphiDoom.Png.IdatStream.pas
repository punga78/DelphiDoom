{******************************************************************************}
{                                                                              }
{  DelphiDoom: PNG - the decompressed content of the IDAT chunks               }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Png.IdatStream;

interface

uses
  DelphiDoom.Zlib.Intf, DelphiDoom.Png.ChunkReader;

type
  /// <summary>
  ///   Feeds the zlib stream that the consecutive IDAT chunks make to an
  ///   IZlibInflater and hands out the decompressed bytes a few at a time (a
  ///   scanline), so that the whole image is never held decompressed
  /// </summary>
  /// <remarks>
  ///   When the data of the stream is exhausted the reader is left at the
  ///   first chunk that is not IDAT
  /// </remarks>
  TPngIdatStream = class
  private
    FReader: TPngChunkReader;
    FInflater: IZlibInflater;
    FBuffers: TZlibStreamBuffers;
    FStreamEnded: Boolean;

    function LoadNextChunk: Boolean;
    class procedure RaiseForZlib(ACode: Integer); static;
  public
    /// <summary>
    ///   AFirstChunk is the first IDAT chunk, already read from AReader
    /// </summary>
    constructor Create(AReader: TPngChunkReader; const AInflater: IZlibInflater;
      const AFirstChunk: TPngChunk);

    /// <summary>
    ///   Fills ADest with the next ACount decompressed bytes. DDPNG_ERR_DATA
    ///   if the zlib stream is corrupted or ends too early,
    ///   DDPNG_ERR_TRUNCATED if the chunks end before the stream does
    /// </summary>
    procedure Read(ADest: PByte; ACount: Cardinal);

    /// <summary>
    ///   Checks that the stream ends right after the bytes already read (and
    ///   that its checksum is right), consuming the rest of the chunks that
    ///   hold it
    /// </summary>
    procedure Finish;
  end;

implementation

uses
  DelphiDoom.Png.Intf;

{ TPngIdatStream }

constructor TPngIdatStream.Create(AReader: TPngChunkReader;
  const AInflater: IZlibInflater; const AFirstChunk: TPngChunk);
begin
  inherited Create;
  FReader := AReader;
  FInflater := AInflater;
  FillChar(FBuffers, SizeOf(FBuffers), 0);
  FBuffers.NextIn := AFirstChunk.Data;
  FBuffers.AvailIn := AFirstChunk.Size;
end;

class procedure TPngIdatStream.RaiseForZlib(ACode: Integer);
begin
  case ACode of
    ZLIB_DATA_ERROR, ZLIB_NEED_DICT:
      raise EPngException.CreateCode(DDPNG_ERR_DATA);
    ZLIB_MEM_ERROR:
      raise EPngException.CreateCode(DDPNG_ERR_MEMORY);
  else
    raise EPngException.CreateCode(DDPNG_ERR_INTERNAL);
  end;
end;

function TPngIdatStream.LoadNextChunk: Boolean;
var
  LPosition: Cardinal;
  LChunk: TPngChunk;
begin
  LPosition := FReader.Position;
  LChunk := FReader.Next(True);
  Result := LChunk.ChunkType = PNG_CHUNK_IDAT;
  if Result then
  begin
    FBuffers.NextIn := LChunk.Data;
    FBuffers.AvailIn := LChunk.Size;
  end
  else
    // Not ours: leave it to whoever reads the chunks after the image
    FReader.Position := LPosition;
end;

procedure TPngIdatStream.Read(ADest: PByte; ACount: Cardinal);
var
  LCode: Integer;
begin
  FBuffers.NextOut := ADest;
  FBuffers.AvailOut := ACount;

  while FBuffers.AvailOut > 0 do
  begin
    // The stream is over but more bytes are needed: the data is too short
    if FStreamEnded then
      raise EPngException.CreateCode(DDPNG_ERR_DATA);

    LCode := FInflater.Inflate(FBuffers, ZLIB_NO_FLUSH);
    case LCode of
      ZLIB_OK:
        ;
      ZLIB_STREAM_END:
        FStreamEnded := True;
      ZLIB_BUF_ERROR:
        // No progress is possible only without input: anything else would
        // loop forever
        if FBuffers.AvailIn <> 0 then
          raise EPngException.CreateCode(DDPNG_ERR_INTERNAL);
    else
      RaiseForZlib(LCode);
    end;

    // The chunk is used up and the stream wants more
    if (FBuffers.AvailOut > 0) and not FStreamEnded and
       (FBuffers.AvailIn = 0) then
      if not LoadNextChunk then
        raise EPngException.CreateCode(DDPNG_ERR_TRUNCATED);
  end;
end;

procedure TPngIdatStream.Finish;
var
  LCode: Integer;
  LScratch: Byte;
begin
  while not FStreamEnded do
  begin
    // One byte of room: any byte the stream still produces is surplus data
    FBuffers.NextOut := @LScratch;
    FBuffers.AvailOut := 1;

    LCode := FInflater.Inflate(FBuffers, ZLIB_NO_FLUSH);
    if FBuffers.AvailOut = 0 then
      raise EPngException.CreateCode(DDPNG_ERR_DATA);

    case LCode of
      ZLIB_OK:
        ;
      ZLIB_STREAM_END:
        FStreamEnded := True;
      ZLIB_BUF_ERROR:
        if FBuffers.AvailIn <> 0 then
          raise EPngException.CreateCode(DDPNG_ERR_INTERNAL);
    else
      RaiseForZlib(LCode);
    end;

    if not FStreamEnded and (FBuffers.AvailIn = 0) then
      if not LoadNextChunk then
        raise EPngException.CreateCode(DDPNG_ERR_TRUNCATED);
  end;
end;

end.
