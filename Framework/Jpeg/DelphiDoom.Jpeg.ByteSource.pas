{******************************************************************************}
{                                                                              }
{  DelphiDoom: JPEG - the bytes of the stream, read one by one                 }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{  Derived from libjpeg 6b by the Independent JPEG Group                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Jpeg.ByteSource;

interface

type
  /// <summary>
  ///   The stream in memory, as the decoder of libjpeg sees it
  /// </summary>
  /// <remarks>
  ///   When the bytes are over the source does not stop: it gives the two
  ///   bytes of a marker of end of image, again and again, like the memory
  ///   source of libjpeg. The decoder then ends the image in a natural way,
  ///   and the only trace of the missing bytes is Exhausted. Skip behaves as
  ///   skip_input_data of libjpeg, which empties the buffer that it has
  ///   instead of going further, so that after a skip past the end the next
  ///   byte is the start of a new marker of end of image
  /// </remarks>
  TJpegByteSource = class
  private
    FNext: PByte;
    FRemaining: Integer;
    FEndOfImage: array[0..1] of Byte;
    FExhausted: Boolean;
    procedure Refill;
  public
    constructor Create(AData: Pointer; ASize: Integer);

    /// <summary>The next byte of the stream</summary>
    function ReadByte: Integer; inline;

    /// <summary>Goes over ACount bytes; nothing for a count that is not positive</summary>
    procedure Skip(ACount: Integer);

    /// <summary>
    ///   True once the decoder has asked for a byte that the stream does not
    ///   have
    /// </summary>
    property Exhausted: Boolean read FExhausted;
  end;

implementation

{ TJpegByteSource }

constructor TJpegByteSource.Create(AData: Pointer; ASize: Integer);
begin
  inherited Create;
  FNext := PByte(AData);
  FRemaining := ASize;
end;

procedure TJpegByteSource.Refill;
begin
  // fill_input_buffer of libjpeg: a marker of end of image
  FExhausted := True;
  FEndOfImage[0] := $FF;
  FEndOfImage[1] := $D9;
  FNext := @FEndOfImage[0];
  FRemaining := 2;
end;

function TJpegByteSource.ReadByte: Integer;
begin
  if FRemaining = 0 then
    Refill;
  Dec(FRemaining);
  Result := FNext^;
  Inc(FNext);
end;

procedure TJpegByteSource.Skip(ACount: Integer);
begin
  if ACount <= 0 then
    Exit;
  if ACount >= FRemaining then
  begin
    Inc(FNext, FRemaining);
    FRemaining := 0;
  end
  else
  begin
    Inc(FNext, ACount);
    Dec(FRemaining, ACount);
  end;
end;

end.
