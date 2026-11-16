{******************************************************************************}
{                                                                              }
{  DelphiDoom: flic library - the frames of a FLI/FLC animation (issue #229)    }
{  Moved from TXcomFlcDecoder (Libs\XcomFormats), the decoder of FlcPlayer of  }
{  OpenXcom (GPL v3 or later) without screen, clock and audio device: see       }
{  Libs\XcomFormats\README.md for the license of this unit                    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Flic.FrameDecoder;

interface

uses
  System.SysUtils, DelphiDoom.Flic.Types;

const
  FLIC_FILE_HEADER_BYTES = 128;
  FLIC_FILE_TYPE_FLI = $AF11;
  FLIC_FILE_TYPE_FLC = $AF12;

type
  /// <summary>The colors first .. first + count - 1 of the palette of the decoder have changed</summary>
  TFlicPaletteHandler = reference to procedure(AFirst, ACount: Integer);

  /// <summary>
  ///   FlcPlayer without the screen: reads the header, finds the frames one after the other and decodes their
  ///   chunks (COLOR_256, COLOR_64, FLI_BRUN, FLI_LC, FLI_SS2, FLI_COPY, BLACK) into a buffer of pixels that the
  ///   caller gives (the surface of the screen: a pitch and the offset of the first pixel of the picture). The
  ///   audio chunks of the videos of TFTD (type $AAAA) are read with their own cursor, as the C++ does. The
  ///   oddities of the C++ are kept (BLACK clears "height" pixels per row; the skip of a COLOR_256 packet adds
  ///   the count of the packet before). What the C++ leaves undefined (a chunk that reads past the file or
  ///   writes past the picture) is EFlicFormatException
  /// </summary>
  TFlicFrameDecoder = class
  strict private
    FBytes: TBytes;
    FHeaderType: Word;
    FHeaderFrames: Word;
    FHeaderWidth: Word;
    FHeaderHeight: Word;
    FHeaderDepth: Word;
    FHeaderSpeed: Word;
    FVideoPosition: Integer;
    FAudioPosition: Integer;
    FChunkPosition: Integer;
    FFrameChunks: Word;
    FDelayOverride: Word;
    FFrameCount: Integer;
    FFinished: Boolean;
    FFrameFound: Boolean;
    FHasAudio: Boolean;
    FSampleRate: Integer;
    FAudioFrameSize: Cardinal;
    FVideoDelay: Integer;
    FColors: array[0..255] of TFlicColor;
    FOnPalette: TFlicPaletteHandler;
    FTarget: TBytes;
    FPitch: Integer;
    FOffset: Integer;
    function ByteAt(APosition: Integer): Byte;
    function WordAt(APosition: Integer): Word;
    function CardinalAt(APosition: Integer): Cardinal;
    function IsValidFrame(APosition: Integer; out ASize: Cardinal; out AType: Word): Boolean;
    function IsEndOfFile(APosition: Integer): Boolean; inline;
    procedure Put(APosition: Integer; AValue: Byte);
    procedure PaletteChanged(AFirst, ACount: Integer);
    procedure Color256;
    procedure Color64;
    procedure FliBRun;
    procedure FliLC;
    procedure FliSS2;
    procedure FliCopy;
    procedure Black;
    procedure PlayVideoFrame;
  public
    /// <summary>FlcPlayer::init: keeps the bytes and reads the header; EFlicFormatException when it is not FLI or FLC</summary>
    constructor Create(const ABytes: TBytes);
    /// <summary>
    ///   The first part of FlcPlayer::decodeVideo: skips the audio and prefix chunks up to the next frame and
    ///   reads its header. False (and Finished) when what is there is not a frame
    /// </summary>
    function FindFrame: Boolean;
    /// <summary>
    ///   The delay before the frame found by FindFrame, in milliseconds: a FLI uses its own delay or the speed
    ///   of the header in 1/70 s; a FLC that plays its own audio (the videos of TFTD) the length of an audio
    ///   chunk; any other FLC the speed of the header
    /// </summary>
    function FrameDelay(AInternalAudio: Boolean): Cardinal;
    /// <summary>
    ///   The second part of FlcPlayer::decodeVideo: draws the frame found by FindFrame in ATarget (APitch bytes
    ///   per row, the picture starts at AOffset). The last frame of the file sets Finished and, with
    ///   ASkipLastFrame, is not drawn
    /// </summary>
    procedure DecodeFrame(const ATarget: TBytes; APitch, AOffset: Integer; ASkipLastFrame: Boolean);
    /// <summary>
    ///   FlcPlayer::decodeAudio(1): the next audio chunk of the file, as the unsigned 8 bit samples it holds.
    ///   False when the file has no more audio chunks (Finished when what is there is not a frame)
    /// </summary>
    function NextAudioChunk(out ASamples: TBytes): Boolean;
    /// <summary>FlcPlayer::playAudioFrame: 16 bit samples, (sample - 128) * 240 * volume as a float truncated</summary>
    class function ToSigned16(const ASamples: TBytes; AVolume: Double): TArray<SmallInt>; static;
    /// <summary>FlcPlayer::setHeaderSpeed</summary>
    procedure SetHeaderSpeed(ASpeed: Integer);
    /// <summary>FlcPlayer::stop</summary>
    procedure Stop;
    /// <summary>The color of the palette of the animation</summary>
    function Color(AIndex: Integer): TFlicColor;
    property OnPalette: TFlicPaletteHandler read FOnPalette write FOnPalette;
    function IsFli: Boolean;
    property HeaderType: Word read FHeaderType;
    property Frames: Word read FHeaderFrames;
    property Width: Word read FHeaderWidth;
    property Height: Word read FHeaderHeight;
    property Depth: Word read FHeaderDepth;
    property Speed: Word read FHeaderSpeed;
    /// <summary>FlcPlayer::getFrameCount: the frames found so far (also the last one when it is not drawn)</summary>
    property FrameCount: Integer read FFrameCount;
    property Finished: Boolean read FFinished;
    /// <summary>The file has audio chunks and one was read (the rate of the first one)</summary>
    property HasAudio: Boolean read FHasAudio;
    property SampleRate: Integer read FSampleRate;
    /// <summary>1000 / (sample rate / samples of the first audio chunk), with the integer divisions of the C++</summary>
    property VideoDelay: Integer read FVideoDelay;
  end;

implementation

const
  SMissingHeader = 'FLI/FLC file of %d bytes: the header needs %d';
  SBadHeader = 'Flx file failed header check (type %.4x)';
  SReadPastEnd = 'FLI/FLC chunk reads past the end of the file (offset %d of %d)';
  SWritePastEnd = 'FLI/FLC chunk writes outside the picture (offset %d of %d)';
  SNoFrame = 'DecodeFrame without a frame found by FindFrame';
  FRAME_HEADER_BYTES = 16;
  CHUNK_HEADER_BYTES = 6;
  CHUNK_COLOR_256 = $04;
  CHUNK_FLI_SS2 = $07;
  CHUNK_COLOR_64 = $0B;
  CHUNK_FLI_LC = $0C;
  CHUNK_BLACK = $0D;
  CHUNK_FLI_BRUN = $0F;
  CHUNK_FLI_COPY = $10;
  FRAME_AUDIO = $AAAA;
  FRAME_PREFIX = $F100;
  FRAME_VIDEO = $F1FA;
  OPCODE_PACKETS_COUNT = $0000;
  OPCODE_LAST_PIXEL = $8000;
  OPCODE_SKIP_LINES = $C000;
  OPCODE_MASK = $C000;
  // 1000.0 / 70.0 as the double constant of the C++ (the product is then made in the precision of the FPU)
  FLI_TICK_MILLISECONDS: Double = 1000.0 / 70.0;

{ TFlicFrameDecoder }

constructor TFlicFrameDecoder.Create(const ABytes: TBytes);
begin
  inherited Create;
  FBytes := ABytes;
  if Length(FBytes) < FLIC_FILE_HEADER_BYTES then
    raise EFlicFormatException.CreateFmt(SMissingHeader, [Length(FBytes), FLIC_FILE_HEADER_BYTES]);
  // FlcPlayer::readFileHeader
  FHeaderType := WordAt(4);
  FHeaderFrames := WordAt(6);
  FHeaderWidth := WordAt(8);
  FHeaderHeight := WordAt(10);
  FHeaderDepth := WordAt(12);
  FHeaderSpeed := WordAt(16);
  if (FHeaderType <> FLIC_FILE_TYPE_FLI) and (FHeaderType <> FLIC_FILE_TYPE_FLC) then
    raise EFlicFormatException.CreateFmt(SBadHeader, [FHeaderType]);
  FVideoPosition := FLIC_FILE_HEADER_BYTES;
  FAudioPosition := FLIC_FILE_HEADER_BYTES;
end;

function TFlicFrameDecoder.ByteAt(APosition: Integer): Byte;
begin
  if (APosition < 0) or (APosition >= Length(FBytes)) then
    raise EFlicFormatException.CreateFmt(SReadPastEnd, [APosition, Length(FBytes)]);
  Result := FBytes[APosition];
end;

function TFlicFrameDecoder.WordAt(APosition: Integer): Word;
begin
  Result := ByteAt(APosition) or (Word(ByteAt(APosition + 1)) shl 8);
end;

function TFlicFrameDecoder.CardinalAt(APosition: Integer): Cardinal;
begin
  Result := WordAt(APosition) or (Cardinal(WordAt(APosition + 2)) shl 16);
end;

function TFlicFrameDecoder.IsEndOfFile(APosition: Integer): Boolean;
begin
  Result := APosition = Length(FBytes);
end;

function TFlicFrameDecoder.IsValidFrame(APosition: Integer; out ASize: Cardinal; out AType: Word): Boolean;
begin
  ASize := 0;
  AType := 0;
  // the C++ reads whatever follows the file; here what is not a whole header is not a frame
  if (APosition < 0) or (APosition > Length(FBytes) - CHUNK_HEADER_BYTES) then
    Exit(False);
  ASize := CardinalAt(APosition);
  AType := WordAt(APosition + 4);
  Result := (AType = FRAME_VIDEO) or (AType = FRAME_AUDIO) or (AType = FRAME_PREFIX);
end;

procedure TFlicFrameDecoder.Put(APosition: Integer; AValue: Byte);
begin
  if (APosition < 0) or (APosition >= Length(FTarget)) then
    raise EFlicFormatException.CreateFmt(SWritePastEnd, [APosition, Length(FTarget)]);
  FTarget[APosition] := AValue;
end;

procedure TFlicFrameDecoder.PaletteChanged(AFirst, ACount: Integer);
begin
  if Assigned(FOnPalette) then
    FOnPalette(AFirst, ACount);
end;

function TFlicFrameDecoder.FindFrame: Boolean;
var
  LSize: Cardinal;
  LType: Word;
begin
  FFrameFound := False;
  while not FFrameFound do
  begin
    if not IsValidFrame(FVideoPosition, LSize, LType) then
    begin
      FFinished := True;
      Exit(False);
    end;
    case LType of
      FRAME_VIDEO:
        begin
          FFrameChunks := WordAt(FVideoPosition + 6);
          FDelayOverride := WordAt(FVideoPosition + 8);
          FChunkPosition := FVideoPosition + FRAME_HEADER_BYTES;
          FVideoPosition := FVideoPosition + Integer(LSize);
          FFrameFound := True;
        end;
      FRAME_AUDIO:
        FVideoPosition := FVideoPosition + Integer(LSize) + FRAME_HEADER_BYTES;
      FRAME_PREFIX:
        FVideoPosition := FVideoPosition + Integer(LSize);
    end;
  end;
  Result := True;
end;

function TFlicFrameDecoder.FrameDelay(AInternalAudio: Boolean): Cardinal;
begin
  if FHeaderType = FLIC_FILE_TYPE_FLI then
  begin
    if FDelayOverride > 0 then
      Result := FDelayOverride
    else
      Result := Trunc(FHeaderSpeed * FLI_TICK_MILLISECONDS);
  end
  else if AInternalAudio then
    Result := Cardinal(FVideoDelay)
  else
    Result := FHeaderSpeed;
end;

procedure TFlicFrameDecoder.DecodeFrame(const ATarget: TBytes; APitch, AOffset: Integer; ASkipLastFrame: Boolean);
begin
  if not FFrameFound then
    raise EFlicFormatException.Create(SNoFrame);
  FFrameFound := False;
  // if this frame is the last one, don't play it
  if IsEndOfFile(FVideoPosition) then
    FFinished := True;
  if (not FFinished) or (not ASkipLastFrame) then
  begin
    FTarget := ATarget;
    FPitch := APitch;
    FOffset := AOffset;
    try
      PlayVideoFrame;
    finally
      FTarget := nil;
    end;
  end;
end;

procedure TFlicFrameDecoder.PlayVideoFrame;
var
  LIndex: Integer;
  LChunkSize: Cardinal;
begin
  Inc(FFrameCount);
  for LIndex := 0 to Integer(FFrameChunks) - 1 do
  begin
    LChunkSize := CardinalAt(FChunkPosition);
    case WordAt(FChunkPosition + 4) of
      CHUNK_COLOR_256:
        Color256;
      CHUNK_FLI_SS2:
        FliSS2;
      CHUNK_COLOR_64:
        Color64;
      CHUNK_FLI_LC:
        FliLC;
      CHUNK_BLACK:
        Black;
      CHUNK_FLI_BRUN:
        FliBRun;
      CHUNK_FLI_COPY:
        FliCopy;
    end;
    // the other types (18 is the thumbnail) are skipped
    FChunkPosition := FChunkPosition + Integer(LChunkSize);
  end;
end;

procedure TFlicFrameDecoder.Color256;
var
  LSource: Integer;
  LPackets: Word;
  LColors: Word;
  LSkip: Byte;
  LIndex: Integer;
begin
  LSource := FChunkPosition + CHUNK_HEADER_BYTES;
  LPackets := WordAt(LSource);
  Inc(LSource, 2);
  LColors := 0;
  while LPackets > 0 do
  begin
    Dec(LPackets);
    // the skip adds the count of the packet before and wraps at 8 bits, as the Uint8 of the C++
    LSkip := Byte(ByteAt(LSource) + LColors);
    LColors := ByteAt(LSource + 1);
    Inc(LSource, 2);
    if LColors = 0 then
      LColors := 256;
    for LIndex := 0 to LColors - 1 do
    begin
      // SDL_SetColors stops at the end of the palette
      if LSkip + LIndex <= 255 then
      begin
        FColors[LSkip + LIndex].Red := ByteAt(LSource);
        FColors[LSkip + LIndex].Green := ByteAt(LSource + 1);
        FColors[LSkip + LIndex].Blue := ByteAt(LSource + 2);
        FColors[LSkip + LIndex].Alpha := 255;
      end;
      Inc(LSource, 3);
    end;
    if LSkip + LColors > 256 then
      PaletteChanged(LSkip, 256 - LSkip)
    else
      PaletteChanged(LSkip, LColors);
    if LPackets >= 1 then
      Inc(LColors);
  end;
end;

procedure TFlicFrameDecoder.Color64;
var
  LSource: Integer;
  LPackets: Word;
  LColors: Word;
  LSkip: Byte;
  LIndex: Integer;
begin
  LSource := FChunkPosition + CHUNK_HEADER_BYTES;
  LPackets := WordAt(LSource);
  Inc(LSource, 2);
  while LPackets > 0 do
  begin
    Dec(LPackets);
    LSkip := ByteAt(LSource);
    LColors := ByteAt(LSource + 1);
    Inc(LSource, 2);
    if LColors = 0 then
      LColors := 256;
    for LIndex := 0 to LColors - 1 do
    begin
      if LSkip + LIndex <= 255 then
      begin
        // 6 bit colors; the shift wraps at 8 bits
        FColors[LSkip + LIndex].Red := Byte(ByteAt(LSource) shl 2);
        FColors[LSkip + LIndex].Green := Byte(ByteAt(LSource + 1) shl 2);
        FColors[LSkip + LIndex].Blue := Byte(ByteAt(LSource + 2) shl 2);
        FColors[LSkip + LIndex].Alpha := 255;
      end;
      Inc(LSource, 3);
    end;
    if LSkip + LColors > 256 then
      PaletteChanged(LSkip, 256 - LSkip)
    else
      PaletteChanged(LSkip, LColors);
  end;
end;

procedure TFlicFrameDecoder.FliBRun;
var
  LSource: Integer;
  LLine: Integer;
  LTarget: Integer;
  LRow: Integer;
  LPixels: Integer;
  LCount: Integer;
  LFill: Byte;
  LIndex: Integer;
begin
  LSource := FChunkPosition + CHUNK_HEADER_BYTES;
  LRow := FOffset;
  for LLine := 1 to FHeaderHeight do
  begin
    LTarget := LRow;
    // the packet count is read and skipped
    Inc(LSource);
    LPixels := 0;
    while LPixels <> FHeaderWidth do
    begin
      LCount := Shortint(ByteAt(LSource));
      Inc(LSource);
      if LCount > 0 then
      begin
        LFill := ByteAt(LSource);
        Inc(LSource);
        for LIndex := 1 to LCount do
        begin
          Put(LTarget, LFill);
          Inc(LTarget);
        end;
        Inc(LPixels, LCount);
      end
      else if LCount < 0 then
      begin
        LCount := -LCount;
        for LIndex := 1 to LCount do
        begin
          Put(LTarget, ByteAt(LSource));
          Inc(LTarget);
          Inc(LSource);
        end;
        Inc(LPixels, LCount);
      end;
    end;
    Inc(LRow, FPitch);
  end;
end;

procedure TFlicFrameDecoder.FliLC;
var
  LSource: Integer;
  LRow: Integer;
  LTarget: Integer;
  LLines: Integer;
  LPackets: Integer;
  LCount: Integer;
  LFill: Byte;
  LIndex: Integer;
begin
  LSource := FChunkPosition + CHUNK_HEADER_BYTES;
  LRow := FOffset + WordAt(LSource) * FPitch;
  Inc(LSource, 2);
  LLines := WordAt(LSource);
  Inc(LSource, 2);
  while LLines > 0 do
  begin
    Dec(LLines);
    LTarget := LRow;
    LPackets := ByteAt(LSource);
    Inc(LSource);
    while LPackets > 0 do
    begin
      Dec(LPackets);
      Inc(LTarget, ByteAt(LSource));
      LCount := Shortint(ByteAt(LSource + 1));
      Inc(LSource, 2);
      if LCount > 0 then
      begin
        for LIndex := 1 to LCount do
        begin
          Put(LTarget, ByteAt(LSource));
          Inc(LTarget);
          Inc(LSource);
        end;
      end
      else if LCount < 0 then
      begin
        LFill := ByteAt(LSource);
        Inc(LSource);
        for LIndex := 1 to -LCount do
        begin
          Put(LTarget, LFill);
          Inc(LTarget);
        end;
      end;
    end;
    Inc(LRow, FPitch);
  end;
end;

procedure TFlicFrameDecoder.FliSS2;
var
  LSource: Integer;
  LRow: Integer;
  LTarget: Integer;
  LLines: Integer;
  LCount: Integer;
  LData: Integer;
  LSetLastByte: Boolean;
  LLastByte: Byte;
  LFill1: Byte;
  LFill2: Byte;
  LIndex: Integer;
begin
  LSetLastByte := False;
  LLastByte := 0;
  LSource := FChunkPosition + CHUNK_HEADER_BYTES;
  LRow := FOffset;
  LLines := WordAt(LSource);
  Inc(LSource, 2);
  while LLines > 0 do
  begin
    Dec(LLines);
    LCount := Smallint(WordAt(LSource));
    Inc(LSource, 2);
    if (LCount and OPCODE_MASK) = OPCODE_SKIP_LINES then
    begin
      Inc(LRow, (-LCount) * FPitch);
      Inc(LLines);
      Continue;
    end
    else if (LCount and OPCODE_MASK) = OPCODE_LAST_PIXEL then
    begin
      LSetLastByte := True;
      LLastByte := LCount and $FF;
      LCount := Smallint(WordAt(LSource));
      Inc(LSource, 2);
    end;
    if (LCount and OPCODE_MASK) = OPCODE_PACKETS_COUNT then
    begin
      LTarget := LRow;
      while LCount > 0 do
      begin
        Dec(LCount);
        Inc(LTarget, ByteAt(LSource));
        LData := Shortint(ByteAt(LSource + 1));
        Inc(LSource, 2);
        if LData > 0 then
        begin
          for LIndex := 1 to 2 * LData do
          begin
            Put(LTarget, ByteAt(LSource));
            Inc(LTarget);
            Inc(LSource);
          end;
        end
        else if LData < 0 then
        begin
          LFill1 := ByteAt(LSource);
          LFill2 := ByteAt(LSource + 1);
          Inc(LSource, 2);
          for LIndex := 1 to -LData do
          begin
            Put(LTarget, LFill1);
            Put(LTarget + 1, LFill2);
            Inc(LTarget, 2);
          end;
        end;
      end;
      if LSetLastByte then
      begin
        LSetLastByte := False;
        Put(LRow + FPitch - 1, LLastByte);
      end;
      Inc(LRow, FPitch);
    end;
  end;
end;

procedure TFlicFrameDecoder.FliCopy;
var
  LSource: Integer;
  LRow: Integer;
  LLine: Integer;
  LIndex: Integer;
begin
  LSource := FChunkPosition + CHUNK_HEADER_BYTES;
  LRow := FOffset;
  for LLine := 1 to FHeaderHeight do
  begin
    for LIndex := 0 to Integer(FHeaderWidth) - 1 do
      Put(LRow + LIndex, ByteAt(LSource + LIndex));
    Inc(LSource, FHeaderWidth);
    Inc(LRow, FPitch);
  end;
end;

procedure TFlicFrameDecoder.Black;
var
  LRow: Integer;
  LLine: Integer;
  LIndex: Integer;
begin
  LRow := FOffset;
  for LLine := 1 to FHeaderHeight do
  begin
    // memset(pDst, 0, _screenHeight): the C++ clears "height" pixels of every row, not "width"
    for LIndex := 0 to Integer(FHeaderHeight) - 1 do
      Put(LRow + LIndex, 0);
    Inc(LRow, FPitch);
  end;
end;

function TFlicFrameDecoder.NextAudioChunk(out ASamples: TBytes): Boolean;
var
  LSize: Cardinal;
  LType: Word;
  LRate: Integer;
begin
  ASamples := nil;
  while not IsEndOfFile(FAudioPosition) do
  begin
    if not IsValidFrame(FAudioPosition, LSize, LType) then
    begin
      FFinished := True;
      Exit(False);
    end;
    if LType = FRAME_AUDIO then
    begin
      LRate := WordAt(FAudioPosition + 8);
      if not FHasAudio then
      begin
        FHasAudio := True;
        FSampleRate := LRate;
        FAudioFrameSize := LSize;
        // FlcPlayer::initAudio: 1000 / (rate / frame size), integer divisions; a chunk longer than a second
        // divides by zero in the C++
        if (LSize > 0) and (FSampleRate div Integer(LSize) > 0) then
          FVideoDelay := 1000 div (FSampleRate div Integer(LSize));
      end;
      if Integer(LSize) > 0 then
      begin
        // the last byte of the chunk must be in the file
        ByteAt(FAudioPosition + FRAME_HEADER_BYTES + Integer(LSize) - 1);
        ASamples := Copy(FBytes, FAudioPosition + FRAME_HEADER_BYTES, Integer(LSize));
      end;
      FAudioPosition := FAudioPosition + Integer(LSize) + FRAME_HEADER_BYTES;
      Exit(True);
    end;
    FAudioPosition := FAudioPosition + Integer(LSize);
    // a frame of size zero would never end
    if LSize = 0 then
    begin
      FFinished := True;
      Exit(False);
    end;
  end;
  Result := False;
end;

class function TFlicFrameDecoder.ToSigned16(const ASamples: TBytes; AVolume: Double): TArray<SmallInt>;
var
  LIndex: Integer;
  LValue: Single;
begin
  SetLength(Result, Length(ASamples));
  for LIndex := 0 to High(ASamples) do
  begin
    // (float)(sample - 128) * 240 * volume, stored in a Sint16
    LValue := (Integer(ASamples[LIndex]) - 128);
    Result[LIndex] := SmallInt(Trunc(LValue * 240 * AVolume));
  end;
end;

procedure TFlicFrameDecoder.SetHeaderSpeed(ASpeed: Integer);
begin
  FHeaderSpeed := Word(ASpeed);
end;

function TFlicFrameDecoder.IsFli: Boolean;
begin
  Result := FHeaderType = FLIC_FILE_TYPE_FLI;
end;

procedure TFlicFrameDecoder.Stop;
begin
  FFinished := True;
end;

function TFlicFrameDecoder.Color(AIndex: Integer): TFlicColor;
begin
  Result := FColors[AIndex and $FF];
end;

end.
