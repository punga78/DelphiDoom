{******************************************************************************}
{                                                                              }
{  DelphiDoom: JPEG - adapter to the decoder of JPEGLIB (IJG 6b, Pascal port)  }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Jpeg.Native;

// Adapts the decoder of the folder JPEGLIB to a stream held in memory and to
// result codes. JPEGLIB has no compressor: encoding is done by
// DelphiDoom.Jpeg.Encoder. The units of JPEGLIB (and Common\d_delphi, which
// they use) are not part of the engine and are linked into the DLL by
// DDJpeg.dpr; this unit has no other dependency on the rest of the engine.

interface

uses
  DelphiDoom.Jpeg.Intf;

const
  JPEG_NATIVE_VERSION_TEXT: PAnsiChar = '6b';

/// <summary>
///   Reads the header of the JPEG stream in ASource
/// </summary>
/// <returns>
///   DDJPEG_OK or the code of the error found
/// </returns>
function JpegReadInfo(ASource: Pointer; ASourceSize: Cardinal;
  out AInfo: TJpegInfo): Integer;

/// <summary>
///   Decodes the JPEG stream in ASource into ADest (ADestSize bytes). AInfo is
///   filled as soon as the header is read. Pixels are written as described in
///   TJpegInfo
/// </summary>
/// <returns>
///   DDJPEG_OK or the code of the error found
/// </returns>
function JpegDecode(ASource: Pointer; ASourceSize: Cardinal; ADest: Pointer;
  ADestSize: Cardinal; out AInfo: TJpegInfo): Integer;

implementation

uses
  System.SysUtils, jpg_morecfg, jpg_deferr, jpg_lib, jpg_error, jpg_dmarker,
  jpg_dmaster, jpg_dapimin, jpg_dapistd;

type
  /// <summary>
  ///   Raised inside the adapter when the decoder reports an error: it never
  ///   leaves this unit
  /// </summary>
  EJpegNativeError = class(Exception)
  private
    FCode: Integer;
  public
    constructor CreateCode(ACode: Integer);
    property Code: Integer read FCode;
  end;

  /// <summary>
  ///   Source manager that reads from a buffer in memory; Pub must be the first
  ///   field so that the pointer the decoder holds is also a pointer to the
  ///   whole record
  /// </summary>
  TJpegMemorySource = record
    Pub: jpeg_source_mgr;
    Exhausted: Boolean;
    EndOfImage: array[0..1] of Byte;
  end;
  PJpegMemorySource = ^TJpegMemorySource;

  TJpegRowBytes = array[0..$FFFFFF] of Byte;
  PJpegRowBytes = ^TJpegRowBytes;

{ EJpegNativeError }

constructor EJpegNativeError.CreateCode(ACode: Integer);
begin
  FCode := ACode;
  inherited Create(EJpegException.TextOf(ACode));
end;

// Translates a message code of JPEGLIB into a result code of the contract
function ResultCodeOfMessage(AMessageCode: Integer): Integer;
begin
  if AMessageCode = Ord(JERR_OUT_OF_MEMORY) then
    Result := DDJPEG_ERR_MEMORY
  else if (AMessageCode = Ord(JERR_CONVERSION_NOTIMPL)) or
          (AMessageCode = Ord(JERR_ARITH_NOTIMPL)) or
          (AMessageCode = Ord(JERR_NOTIMPL)) or
          (AMessageCode = Ord(JERR_NOT_COMPILED)) or
          (AMessageCode = Ord(JERR_SOF_UNSUPPORTED)) or
          (AMessageCode = Ord(JERR_BAD_PRECISION)) or
          (AMessageCode = Ord(JERR_IMAGE_TOO_BIG)) or
          (AMessageCode = Ord(JERR_BAD_PROGRESSION)) then
    Result := DDJPEG_ERR_UNSUPPORTED
  else
    Result := DDJPEG_ERR_DATA;
end;

{ Error manager }

procedure JpegErrorExit(cinfo: j_common_ptr);
begin
  raise EJpegNativeError.CreateCode(ResultCodeOfMessage(cinfo^.err^.msg_code));
end;

procedure JpegEmitMessage(cinfo: j_common_ptr; msg_level: int);
var
  LSource: PJpegMemorySource;
begin
  if msg_level >= 0 then
    Exit;

  // A warning is recoverable for the library, not for us: when the decoder
  // lacks data after the end of the stream it is a truncated image. The other
  // warnings are ignored, as the engine always did
  LSource := PJpegMemorySource(j_decompress_ptr(cinfo)^.src);
  if Assigned(LSource) and LSource^.Exhausted and
     (cinfo^.err^.msg_code = Ord(JWRN_HIT_MARKER)) then
    raise EJpegNativeError.CreateCode(DDJPEG_ERR_TRUNCATED);
end;

procedure JpegOutputMessage(cinfo: j_common_ptr);
begin
  // Messages are not shown: the result code tells what happened
end;

{ Source manager }

procedure JpegSourceInit(cinfo: j_decompress_ptr);
begin
  // The whole stream is already in the buffer
end;

function JpegSourceFill(cinfo: j_decompress_ptr): Boolean;
var
  LSource: PJpegMemorySource;
begin
  // The decoder wants more than the stream holds: hand it an end-of-image
  // marker, as libjpeg does, so that it stops and the check is left to
  // JpegEmitMessage
  LSource := PJpegMemorySource(cinfo^.src);
  LSource^.Exhausted := True;
  LSource^.EndOfImage[0] := $FF;
  LSource^.EndOfImage[1] := JPEG_EOI;
  LSource^.Pub.next_input_byte := @LSource^.EndOfImage[0];
  LSource^.Pub.bytes_in_buffer := 2;
  Result := True;
end;

procedure JpegSourceSkip(cinfo: j_decompress_ptr; num_bytes: long);
var
  LSource: PJpegMemorySource;
begin
  if num_bytes <= 0 then
    Exit;

  LSource := PJpegMemorySource(cinfo^.src);
  if num_bytes >= LSource^.Pub.bytes_in_buffer then
  begin
    // Skipping past the end: the next read gets the end-of-image marker
    inc(LSource^.Pub.next_input_byte, LSource^.Pub.bytes_in_buffer);
    LSource^.Pub.bytes_in_buffer := 0;
  end
  else
  begin
    inc(LSource^.Pub.next_input_byte, num_bytes);
    dec(LSource^.Pub.bytes_in_buffer, num_bytes);
  end;
end;

procedure JpegSourceTerm(cinfo: j_decompress_ptr);
begin
  // Nothing to release
end;

procedure SetupMemorySource(var ASource: TJpegMemorySource; ABuffer: Pointer;
  ASize: Integer; var ADecoder: jpeg_decompress_struct);
begin
  FillChar(ASource, SizeOf(ASource), 0);
  ASource.Pub.init_source := JpegSourceInit;
  ASource.Pub.fill_input_buffer := JpegSourceFill;
  ASource.Pub.skip_input_data := JpegSourceSkip;
  ASource.Pub.resync_to_restart := jpeg_resync_to_restart;
  ASource.Pub.term_source := JpegSourceTerm;
  ASource.Pub.next_input_byte := JOCTETptr(ABuffer);
  ASource.Pub.bytes_in_buffer := ASize;
  ADecoder.src := @ASource.Pub;
end;

// Reads the header and decides the format of the output
procedure ReadHeader(var ADecoder: jpeg_decompress_struct; out AInfo: TJpegInfo);
begin
  jpeg_read_header(@ADecoder, True);

  if ADecoder.jpeg_color_space = JCS_GRAYSCALE then
  begin
    ADecoder.out_color_space := JCS_GRAYSCALE;
    AInfo.Components := 1;
  end
  else
  begin
    // Other color spaces without a conversion to RGB are refused by the
    // decoder when it starts (JERR_CONVERSION_NOTIMPL)
    ADecoder.out_color_space := JCS_RGB;
    AInfo.Components := 3;
  end;
  AInfo.Width := ADecoder.image_width;
  AInfo.Height := ADecoder.image_height;
end;

procedure SwapRedAndBlue(ARow: PJpegRowBytes; AWidth: Integer);
var
  LIndex: Integer;
  LTemp: Byte;
begin
  for LIndex := 0 to AWidth - 1 do
  begin
    LTemp := ARow^[LIndex * 3];
    ARow^[LIndex * 3] := ARow^[LIndex * 3 + 2];
    ARow^[LIndex * 3 + 2] := LTemp;
  end;
end;

// Runs one decompression (header only or whole image) on its own decompression
// object, which is always destroyed
function RunDecoder(ASource: Pointer; ASourceSize: Cardinal;
  out AInfo: TJpegInfo; ADest: Pointer; ADestSize: Cardinal;
  ADecodePixels: Boolean): Integer;
var
  LDecoder: jpeg_decompress_struct;
  LErrors: jpeg_error_mgr;
  LSource: TJpegMemorySource;
  LRow: JSAMPROW;
  LRowStride: Integer;
  LLines: JDIMENSION;
begin
  FillChar(AInfo, SizeOf(AInfo), 0);
  if (ASource = nil) or (ASourceSize = 0) or (ASourceSize > Cardinal(High(Integer))) then
    Exit(DDJPEG_ERR_INVALID_ARGUMENT);

  FillChar(LDecoder, SizeOf(LDecoder), 0);
  FillChar(LErrors, SizeOf(LErrors), 0);
  LDecoder.err := jpeg_std_error(LErrors);
  LErrors.error_exit := JpegErrorExit;
  LErrors.emit_message := JpegEmitMessage;
  LErrors.output_message := JpegOutputMessage;

  Result := DDJPEG_OK;
  try
    jpeg_create_decompress(@LDecoder);
  except
    on E: EJpegNativeError do
      Exit(E.Code);
  end;

  try
    try
      SetupMemorySource(LSource, ASource, Integer(ASourceSize), LDecoder);
      ReadHeader(LDecoder, AInfo);
      if not ADecodePixels then
        Exit;

      LRowStride := AInfo.Width * AInfo.Components;
      if (ADest = nil) or
         (Int64(ADestSize) < Int64(LRowStride) * Int64(AInfo.Height)) then
        Exit(DDJPEG_ERR_BUFFER_TOO_SMALL);

      jpeg_start_decompress(@LDecoder);
      while LDecoder.output_scanline < LDecoder.output_height do
      begin
        LRow := JSAMPROW(PByte(NativeUInt(ADest) +
          NativeUInt(LDecoder.output_scanline) * NativeUInt(LRowStride)));
        LLines := jpeg_read_scanlines(@LDecoder, JSAMParray(@LRow), 1);
        if LLines = 0 then
          raise EJpegNativeError.CreateCode(DDJPEG_ERR_DATA);

        if (AInfo.Components = 3) and (RGB_RED <> 2) then
          SwapRedAndBlue(PJpegRowBytes(LRow), AInfo.Width);
      end;
      // jpeg_finish_decompress is not called on purpose: every pixel is
      // already decoded and a missing end-of-image marker is not an error
    except
      on E: EJpegNativeError do
        Result := E.Code;
    end;
  finally
    jpeg_destroy_decompress(@LDecoder);
  end;
end;

function JpegReadInfo(ASource: Pointer; ASourceSize: Cardinal;
  out AInfo: TJpegInfo): Integer;
begin
  Result := RunDecoder(ASource, ASourceSize, AInfo, nil, 0, False);
end;

function JpegDecode(ASource: Pointer; ASourceSize: Cardinal; ADest: Pointer;
  ADestSize: Cardinal; out AInfo: TJpegInfo): Integer;
begin
  Result := RunDecoder(ASource, ASourceSize, AInfo, ADest, ADestSize, True);
end;

end.
