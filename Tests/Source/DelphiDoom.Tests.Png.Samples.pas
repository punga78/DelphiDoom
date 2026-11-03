{******************************************************************************}
{                                                                              }
{  DelphiDoom: PNG files built byte by byte for the tests                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Png.Samples;

interface

uses
  System.SysUtils, DelphiDoom.Zlib.Intf;

type
  /// <summary>
  ///   Builds PNG files without using the encoder of the library, so that
  ///   the decoder is tested against data written by hand: the filtered
  ///   scanlines are given as they appear in the stream, the chunks are
  ///   assembled here and only the compression is done by zlib
  /// </summary>
  TPngSamples = class sealed
  public
    class function Bytes(const AValues: array of Byte): TBytes; static;
    class function Concat(const AParts: array of TBytes): TBytes; static;

    class function Signature: TBytes; static;

    /// <summary>
    ///   A chunk: length, the four letters of AType (ASCII), AData, CRC
    /// </summary>
    class function Chunk(const AType: string; const AData: TBytes): TBytes; static;

    /// <summary>
    ///   An IHDR chunk with the given fields
    /// </summary>
    class function Header(AWidth, AHeight, ABitDepth, AColorType,
      AInterlace: Integer): TBytes; static;

    /// <summary>
    ///   The zlib stream of ARaw
    /// </summary>
    class function Compress(const AZlib: IZlib; const ARaw: TBytes): TBytes; static;

    /// <summary>
    ///   Signature, header, AExtraChunks (already built chunks that go before
    ///   the image data), one IDAT chunk with the compressed ARaw and IEND
    /// </summary>
    class function Assemble(const AZlib: IZlib; AWidth, AHeight, ABitDepth,
      AColorType, AInterlace: Integer; const AExtraChunks,
      ARaw: TBytes): TBytes; static;

    /// <summary>
    ///   Same as Assemble but with the image data given as the IDAT chunks
    ///   (already built) and the IEND chunk written only if AWithEnd
    /// </summary>
    class function AssembleWithChunks(AWidth, AHeight, ABitDepth, AColorType,
      AInterlace: Integer; const AExtraChunks, AImageChunks: TBytes;
      AWithEnd: Boolean): TBytes; static;

    /// <summary>
    ///   Bytes ABegin..AEnd-1 of ASource
    /// </summary>
    class function Slice(const ASource: TBytes; ABegin,
      AEnd: Integer): TBytes; static;

    /// <summary>
    ///   Deterministic pseudo-random bytes
    /// </summary>
    class function Noise(ACount: Integer; ASeed: Integer = 12345): TBytes; static;
  end;

implementation

uses
  DelphiDoom.Png.ByteOrder, DelphiDoom.Png.Crc;

{ TPngSamples }

class function TPngSamples.Bytes(const AValues: array of Byte): TBytes;
var
  LIndex: Integer;
begin
  SetLength(Result, Length(AValues));
  for LIndex := 0 to High(AValues) do
    Result[LIndex] := AValues[LIndex];
end;

class function TPngSamples.Concat(const AParts: array of TBytes): TBytes;
var
  LIndex: Integer;
  LTotal: Integer;
  LOffset: Integer;
begin
  LTotal := 0;
  for LIndex := 0 to High(AParts) do
    Inc(LTotal, Length(AParts[LIndex]));

  SetLength(Result, LTotal);
  LOffset := 0;
  for LIndex := 0 to High(AParts) do
  begin
    if Length(AParts[LIndex]) > 0 then
      Move(AParts[LIndex][0], Result[LOffset], Length(AParts[LIndex]));
    Inc(LOffset, Length(AParts[LIndex]));
  end;
end;

class function TPngSamples.Signature: TBytes;
begin
  Result := Bytes([$89, $50, $4E, $47, $0D, $0A, $1A, $0A]);
end;

class function TPngSamples.Chunk(const AType: string; const AData: TBytes): TBytes;
var
  LType: TBytes;
  LBody: TBytes;
  LTrailer: TBytes;
  LLength: TBytes;
begin
  // The letters of a chunk type are ASCII
  LType := TEncoding.ASCII.GetBytes(AType);
  Assert(Length(LType) = 4);

  LBody := Concat([LType, AData]);

  SetLength(LLength, 4);
  TPngByteOrder.WriteCardinal(@LLength[0], Cardinal(Length(AData)));
  SetLength(LTrailer, 4);
  TPngByteOrder.WriteCardinal(@LTrailer[0],
    TPngCrc.Compute(@LBody[0], Cardinal(Length(LBody))));

  Result := Concat([LLength, LBody, LTrailer]);
end;

class function TPngSamples.Header(AWidth, AHeight, ABitDepth, AColorType,
  AInterlace: Integer): TBytes;
var
  LData: TBytes;
begin
  SetLength(LData, 13);
  TPngByteOrder.WriteCardinal(@LData[0], Cardinal(AWidth));
  TPngByteOrder.WriteCardinal(@LData[4], Cardinal(AHeight));
  LData[8] := Byte(ABitDepth);
  LData[9] := Byte(AColorType);
  LData[10] := 0;
  LData[11] := 0;
  LData[12] := Byte(AInterlace);
  Result := Chunk('IHDR', LData);
end;

class function TPngSamples.Compress(const AZlib: IZlib; const ARaw: TBytes): TBytes;
var
  LSize: Cardinal;
begin
  LSize := AZlib.CompressBound(Length(ARaw));
  SetLength(Result, LSize);
  if AZlib.Compress(Pointer(ARaw), Length(ARaw), Pointer(Result), LSize,
    ZLIB_DEFAULT_LEVEL) <> ZLIB_OK then
    raise Exception.Create('zlib failed to compress the sample');
  SetLength(Result, LSize);
end;

class function TPngSamples.AssembleWithChunks(AWidth, AHeight, ABitDepth,
  AColorType, AInterlace: Integer; const AExtraChunks, AImageChunks: TBytes;
  AWithEnd: Boolean): TBytes;
begin
  if AWithEnd then
    Result := Concat([Signature, Header(AWidth, AHeight, ABitDepth, AColorType,
      AInterlace), AExtraChunks, AImageChunks, Chunk('IEND', nil)])
  else
    Result := Concat([Signature, Header(AWidth, AHeight, ABitDepth, AColorType,
      AInterlace), AExtraChunks, AImageChunks]);
end;

class function TPngSamples.Assemble(const AZlib: IZlib; AWidth, AHeight,
  ABitDepth, AColorType, AInterlace: Integer; const AExtraChunks,
  ARaw: TBytes): TBytes;
begin
  Result := AssembleWithChunks(AWidth, AHeight, ABitDepth, AColorType,
    AInterlace, AExtraChunks, Chunk('IDAT', Compress(AZlib, ARaw)), True);
end;

class function TPngSamples.Slice(const ASource: TBytes; ABegin,
  AEnd: Integer): TBytes;
begin
  SetLength(Result, AEnd - ABegin);
  if AEnd > ABegin then
    Move(ASource[ABegin], Result[0], AEnd - ABegin);
end;

class function TPngSamples.Noise(ACount, ASeed: Integer): TBytes;
var
  LIndex: Integer;
  LState: Int64;
begin
  SetLength(Result, ACount);
  LState := ASeed;
  for LIndex := 0 to ACount - 1 do
  begin
    LState := (LState * 1103515245 + 12345) and $7FFFFFFF;
    Result[LIndex] := Byte((LState shr 16) and $FF);
  end;
end;

end.
