{******************************************************************************}
{                                                                              }
{  DelphiDoom: cinematic library - the RoQ decoder                             }
{                                                                              }
{  Port of RoQ_init, RoQReset, readQuadInfo and the chunk loop of RoQInterrupt }
{  of the RoQ decoder of Quake III Arena (cl_cin.c, GPL v2 or later,           }
{  Copyright (C) 1999-2005 Id Software, Inc.) and of Doom 3 (Cinematic.cpp,    }
{  GPL v3 with the additional terms of the Doom 3 Source Code License,         }
{  Copyright (C) 1999-2011 id Software LLC). Based on the Doom 3 GPL Source    }
{  Code (id Software).                                                         }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Cinematic.Decoder;

{$Q-}
{$R-}

interface

uses
  System.SysUtils,
  DelphiDoom.Imaging.Types,
  DelphiDoom.Cinematic.Types,
  DelphiDoom.Cinematic.Intf,
  DelphiDoom.Cinematic.YuvConverter,
  DelphiDoom.Cinematic.SoundDecoder,
  DelphiDoom.Cinematic.Codebook,
  DelphiDoom.Cinematic.FramePainter;

type
  /// <summary>
  ///   Reads a RoQ file chunk by chunk: the information, the codebooks, the frames (images
  ///   of 32 bit pixels) and the DPCM audio, which goes to the sink of the caller. It does
  ///   not know about time: that is the job of the player
  /// </summary>
  TRoqDecoder = class(TInterfacedObject, IRoqDecoder)
  strict private
    FSource: IRoqSource;
    FSink: IRoqAudioSink;
    FConverter: TRoqYuvConverter;
    FSound: TRoqSoundDecoder;
    FCodebook: TRoqCodebook;
    FPainter: TRoqFramePainter;
    FFramesPerSecond: Integer;
    // numQuads of the original: -1 at the start, then 0 after the information chunk and the
    // number of frames decoded; another information chunk puts it back to 0 (the next frame
    // is then painted as the first one)
    FQuadCount: Integer;
    FFrameIndex: Integer;
    FFrame: TImagingPixels;
    function GetWidth: Integer;
    function GetHeight: Integer;
    function GetFramesPerSecond: Integer;
    function GetFrameIndex: Integer;
    function GetFrame: TImagingPixels;
    procedure ReadFileHeader;
    function ReadHeader(out AHeader: TRoqChunkHeader): Boolean;
    procedure HandleInfo(const AData: TBytes);
    procedure HandleFrame(const AData: TBytes; AFlags: Word);
    procedure HandleSound(const AData: TBytes; AHeader: TRoqChunkHeader);
  public
    /// <param name="ASource">The file; its position must be the start of it</param>
    /// <param name="ASink">Receives the audio; nil to ignore it (the silent cinematics)</param>
    /// <param name="AAlpha">Alpha byte of the pixels: $FF as Quake III, 0 as Doom 3</param>
    constructor Create(const ASource: IRoqSource; const ASink: IRoqAudioSink; AAlpha: Byte);
    destructor Destroy; override;
    function ReadChunk(out AKind: TRoqChunkKind): Boolean;
    function NextFrame: Boolean;
    procedure Reset;
  end;

implementation

resourcestring
  SNotRoq = 'The data are not a RoQ file (the first chunk is $%.4x)';
  SHeaderEnd = 'The file ends inside a chunk header';
  SChunkEnd = 'The chunk $%.4x has %d bytes, but the file has only %d';
  SChunkTooBig = 'The chunk $%.4x has %d bytes (the largest is %d)';
  SInfoShort = 'The information chunk has %d bytes instead of 8';
  SFrameWithoutInfo = 'A frame comes before the information chunk';

{ TRoqDecoder }

constructor TRoqDecoder.Create(const ASource: IRoqSource; const ASink: IRoqAudioSink;
  AAlpha: Byte);
begin
  inherited Create;
  FSource := ASource;
  FSink := ASink;
  FConverter := TRoqYuvConverter.Create(AAlpha);
  FSound := TRoqSoundDecoder.Create;
  FCodebook := TRoqCodebook.Create(FConverter);
  FQuadCount := -1;
  FFrameIndex := -1;
  ReadFileHeader;
end;

destructor TRoqDecoder.Destroy;
begin
  FPainter.Free;
  FCodebook.Free;
  FSound.Free;
  FConverter.Free;
  inherited Destroy;
end;

function TRoqDecoder.GetWidth: Integer;
begin
  Result := 0;
  if Assigned(FPainter) then
    Result := FPainter.Width;
end;

function TRoqDecoder.GetHeight: Integer;
begin
  Result := 0;
  if Assigned(FPainter) then
    Result := FPainter.Height;
end;

function TRoqDecoder.GetFramesPerSecond: Integer;
begin
  Result := FFramesPerSecond;
end;

function TRoqDecoder.GetFrameIndex: Integer;
begin
  Result := FFrameIndex;
end;

function TRoqDecoder.GetFrame: TImagingPixels;
begin
  Result := FFrame;
end;

function TRoqDecoder.ReadHeader(out AHeader: TRoqChunkHeader): Boolean;
var
  LBytes: array[0..ROQ_HEADER_SIZE - 1] of Byte;
  LCount: Integer;
begin
  LCount := FSource.Read(LBytes, ROQ_HEADER_SIZE);
  Result := LCount > 0;
  if not Result then
    Exit;
  if LCount < ROQ_HEADER_SIZE then
    raise ERoqTruncatedException.Create(SHeaderEnd);
  // little endian, byte by byte
  AHeader.Id := LBytes[0] or (Word(LBytes[1]) shl 8);
  AHeader.Size := Cardinal(LBytes[2]) or (Cardinal(LBytes[3]) shl 8) or
    (Cardinal(LBytes[4]) shl 16) or (Cardinal(LBytes[5]) shl 24);
  AHeader.Flags := LBytes[6] or (Word(LBytes[7]) shl 8);
end;

procedure TRoqDecoder.ReadFileHeader;
var
  LHeader: TRoqChunkHeader;
begin
  if not ReadHeader(LHeader) then
    raise ERoqTruncatedException.Create(SHeaderEnd);
  if LHeader.Id <> ROQ_FILE then
    raise ERoqInvalidDataException.CreateFmt(SNotRoq, [LHeader.Id]);
  FFramesPerSecond := LHeader.Flags;
  if FFramesPerSecond = 0 then
    FFramesPerSecond := ROQ_DEFAULT_FPS;
end;

procedure TRoqDecoder.Reset;
begin
  FSource.Seek(0);
  FreeAndNil(FPainter);
  FCodebook.Clear;
  FFrame := nil;
  FQuadCount := -1;
  FFrameIndex := -1;
  ReadFileHeader;
end;

procedure TRoqDecoder.HandleInfo(const AData: TBytes);
var
  LWidth, LHeight: Integer;
begin
  if Length(AData) < 8 then
    raise ERoqTruncatedException.CreateFmt(SInfoShort, [Length(AData)]);
  if FQuadCount = -1 then
  begin
    // readQuadInfo and setupQuad; the block sizes in the last four bytes are not used by the original
    LWidth := AData[0] or (AData[1] shl 8);
    LHeight := AData[2] or (AData[3] shl 8);
    FreeAndNil(FPainter);
    FPainter := TRoqFramePainter.Create(LWidth, LHeight, FCodebook);
  end;
  if FQuadCount <> 1 then
    FQuadCount := 0;
end;

procedure TRoqDecoder.HandleFrame(const AData: TBytes; AFlags: Word);
var
  LFrame: Integer;
begin
  if not Assigned(FPainter) then
    raise ERoqMissingInfoException.Create(SFrameWithoutInfo);
  // the two bytes of the flags are the offset of the motion vectors, as signed chars
  if Odd(FQuadCount) then
  begin
    LFrame := 1;
    FPainter.PrepareMotion(ShortInt(AFlags shr 8), ShortInt(AFlags and $FF), -FPainter.Delta);
  end
  else
  begin
    LFrame := 0;
    FPainter.PrepareMotion(ShortInt(AFlags shr 8), ShortInt(AFlags and $FF), FPainter.Delta);
  end;
  FPainter.Paint(AData, Length(AData), LFrame);
  if FQuadCount = 0 then
    FPainter.CopyFirstToSecond;
  Inc(FQuadCount);
  Inc(FFrameIndex);
  FFrame := FPainter.FrameCopy(LFrame);
end;

procedure TRoqDecoder.HandleSound(const AData: TBytes; AHeader: TRoqChunkHeader);
begin
  if not Assigned(FSink) then
    Exit;
  if AHeader.Id = ROQ_SOUND_MONO then
    FSink.AudioReceived(FSound.DecodeMonoToStereo(AData, Length(AData), AHeader.Flags), 2,
      ROQ_SOUND_RATE)
  else
    FSink.AudioReceived(FSound.DecodeStereoToStereo(AData, Length(AData), AHeader.Flags), 2,
      ROQ_SOUND_RATE);
end;

function TRoqDecoder.ReadChunk(out AKind: TRoqChunkKind): Boolean;
var
  LHeader: TRoqChunkHeader;
  LData: TBytes;
  LRead: Integer;
begin
  AKind := rckOther;
  Result := ReadHeader(LHeader);
  // a header of file in the middle ends the data, as in the original
  if (not Result) or (LHeader.Id = ROQ_FILE) then
  begin
    Result := False;
    Exit;
  end;
  if LHeader.Size > ROQ_MAX_CHUNK_SIZE then
    raise ERoqInvalidDataException.CreateFmt(SChunkTooBig,
      [LHeader.Id, LHeader.Size, ROQ_MAX_CHUNK_SIZE]);
  // a packet is a container: the chunks that it holds follow its header
  if LHeader.Id = ROQ_PACKET then
    Exit;
  SetLength(LData, LHeader.Size);
  if LHeader.Size > 0 then
  begin
    LRead := FSource.Read(LData[0], LHeader.Size);
    if LRead < Integer(LHeader.Size) then
      raise ERoqTruncatedException.CreateFmt(SChunkEnd, [LHeader.Id, LHeader.Size, LRead]);
  end;
  case LHeader.Id of
    ROQ_QUAD_INFO:
      begin
        HandleInfo(LData);
        AKind := rckInfo;
      end;
    ROQ_CODEBOOK:
      begin
        FCodebook.Decode(LData, LHeader.Flags);
        AKind := rckCodebook;
      end;
    ROQ_QUAD_VQ:
      begin
        HandleFrame(LData, LHeader.Flags);
        AKind := rckFrame;
      end;
    ROQ_SOUND_MONO, ROQ_SOUND_STEREO:
      begin
        HandleSound(LData, LHeader);
        AKind := rckSound;
      end;
  end;
end;

function TRoqDecoder.NextFrame: Boolean;
var
  LKind: TRoqChunkKind;
begin
  repeat
    Result := ReadChunk(LKind);
  until (not Result) or (LKind = rckFrame);
end;

end.
