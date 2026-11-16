{******************************************************************************}
{                                                                              }
{  DelphiDoom: cinematic library - painting a RoQ frame with its vectors       }
{                                                                              }
{  Port of blitVQQuad32fs, blit8_32, blit4_32, blit2_32, move8_32, move4_32,   }
{  RoQPrepMcomp and the double buffer of the RoQ decoder of Quake III Arena    }
{  (cl_cin.c, GPL v2 or later, Copyright (C) 1999-2005 Id Software, Inc.) and  }
{  of Doom 3 (Cinematic.cpp, GPL v3 with the additional terms of the Doom 3    }
{  Source Code License, Copyright (C) 1999-2011 id Software LLC). Based on     }
{  the Doom 3 GPL Source Code (id Software).                                   }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Cinematic.FramePainter;

{$Q-}
{$R-}

interface

uses
  System.SysUtils,
  DelphiDoom.Imaging.Types,
  DelphiDoom.Cinematic.Codebook,
  DelphiDoom.Cinematic.QuadMap;

type
  /// <summary>
  ///   The image of a video as the original keeps it: two frames one after the other in a
  ///   buffer (the one being painted and the previous one, which the motion vectors read).
  ///   Paint decodes the data of a ROQ_QUAD_VQ chunk into one of them
  /// </summary>
  TRoqFramePainter = class
  strict private
    FWidth: Integer;
    FHeight: Integer;
    FDelta: Integer;
    FCodebook: TRoqCodebook;
    FMap: TRoqQuadMap;
    FImage: TImagingPixels;
    FMotion: array[0..255] of Integer;
    FData: TBytes;
    FSize: Integer;
    FPosition: Integer;
    FBase: Integer;
    function NextByte: Byte;
    procedure RequireCodebook;
    procedure BlitVector(const AVectors: TArray<Cardinal>; AVector, ASide, ADestination: Integer);
    procedure MoveBlock(ASide, ADestination, ADisplacement: Integer);
  public
    /// <param name="AWidth">Pixels per row; a multiple of 16</param>
    /// <param name="AHeight">Rows; a multiple of 16</param>
    /// <param name="ACodebook">The vectors; they stay the property of the caller</param>
    constructor Create(AWidth, AHeight: Integer; const ACodebook: TRoqCodebook);
    destructor Destroy; override;
    /// <summary>
    ///   RoQPrepMcomp: the table of the motion vectors for the next frame. AOffsetX and
    ///   AOffsetY are the two bytes of the flags of the chunk, signed; AOtherFrame is the
    ///   distance in pixels from the frame that is painted to the previous one (Delta, or
    ///   -Delta)
    /// </summary>
    procedure PrepareMotion(AOffsetX, AOffsetY, AOtherFrame: Integer);
    /// <summary>
    ///   Paints the data of a frame in the half of the buffer with the given number (0 or 1)
    /// </summary>
    procedure Paint(const AData: TBytes; ASize: Integer; AFrameNumber: Integer);
    /// <summary>The first frame is copied into the second half, so the next one has a past</summary>
    procedure CopyFirstToSecond;
    /// <summary>
    ///   Puts a whole frame (Width * Height pixels) in the first buffer and copies it to the second,
    ///   as <c>JPEGBlit</c> of Doom 3 does; a different number of pixels is an
    ///   <c>ERoqInvalidDataException</c> (the original writes outside the buffer or leaves it as it was)
    /// </summary>
    procedure LoadFirstFrame(const APixels: TImagingPixels);
    /// <summary>The pixels of a half of the buffer, as a new array</summary>
    function FrameCopy(AFrameNumber: Integer): TImagingPixels;
    /// <summary>Pixels of a frame (Width * Height): the distance between the two halves</summary>
    property Delta: Integer read FDelta;
    property Width: Integer read FWidth;
    property Height: Integer read FHeight;
  end;

implementation

uses
  DelphiDoom.Cinematic.Types;

resourcestring
  SSizeNotMultiple = 'The size of the video (%dx%d) is not a multiple of 16';
  SDataEnd = 'The frame data end before the last block';
  SNoCodebook = 'The frame uses a vector but there is no codebook';
  SFrameSize = 'The frame has %d pixels but the video needs %d';
  SMotionOutside ='A motion vector reads outside the buffers of the video';

{ TRoqFramePainter }

constructor TRoqFramePainter.Create(AWidth, AHeight: Integer; const ACodebook: TRoqCodebook);
begin
  inherited Create;
  if (AWidth <= 0) or (AHeight <= 0) or (AWidth mod ROQ_MACROBLOCK <> 0) or
    (AHeight mod ROQ_MACROBLOCK <> 0) then
    raise ERoqInvalidDataException.CreateFmt(SSizeNotMultiple, [AWidth, AHeight]);
  FWidth := AWidth;
  FHeight := AHeight;
  FDelta := AWidth * AHeight;
  FCodebook := ACodebook;
  FMap := TRoqQuadMap.Create(AWidth, AHeight);
  SetLength(FImage, FDelta * 2);
end;

destructor TRoqFramePainter.Destroy;
begin
  FMap.Free;
  inherited Destroy;
end;

procedure TRoqFramePainter.PrepareMotion(AOffsetX, AOffsetY, AOtherFrame: Integer);
var
  LRow, LColumn, LLine, LStep: Integer;
begin
  LLine := FWidth;
  LStep := 1;
  // a video four times wider than high moves by twice the distance (as the original does)
  if FWidth = FHeight * 4 then
  begin
    LStep := LStep + LStep;
    LLine := LLine + LLine;
  end;
  for LRow := 0 to 15 do
    for LColumn := 0 to 15 do
      FMotion[LColumn * 16 + LRow] :=
        AOtherFrame - ((LRow + AOffsetY - 8) * LLine + (LColumn + AOffsetX - 8) * LStep);
end;

function TRoqFramePainter.NextByte: Byte;
begin
  if FPosition >= FSize then
    raise ERoqTruncatedException.Create(SDataEnd);
  Result := FData[FPosition];
  Inc(FPosition);
end;

procedure TRoqFramePainter.RequireCodebook;
begin
  if not FCodebook.Loaded then
    raise ERoqMissingCodebookException.Create(SNoCodebook);
end;

procedure TRoqFramePainter.BlitVector(const AVectors: TArray<Cardinal>;
  AVector, ASide, ADestination: Integer);
var
  LRow, LColumn, LSource: Integer;
begin
  RequireCodebook;
  LSource := AVector * ASide * ASide;
  for LRow := 0 to ASide - 1 do
    for LColumn := 0 to ASide - 1 do
      FImage[ADestination + LRow * FWidth + LColumn] := AVectors[LSource + LRow * ASide + LColumn];
end;

procedure TRoqFramePainter.MoveBlock(ASide, ADestination, ADisplacement: Integer);
var
  LRow, LColumn, LSource: Integer;
begin
  LSource := ADestination + ADisplacement;
  if (LSource < 0) or (LSource + (ASide - 1) * FWidth + ASide > Length(FImage)) then
    raise ERoqInvalidDataException.Create(SMotionOutside);
  for LRow := 0 to ASide - 1 do
    for LColumn := 0 to ASide - 1 do
      FImage[ADestination + LRow * FWidth + LColumn] :=
        FImage[LSource + LRow * FWidth + LColumn];
end;

procedure TRoqFramePainter.Paint(const AData: TBytes; ASize: Integer; AFrameNumber: Integer);
var
  LNew, LCell, LCode, LSubCode: Word;
  LIndex, LSub, LByte: Integer;

  procedure NextCode(out ACode: Word);
  begin
    if LNew = 0 then
    begin
      LNew := 7;
      LCell := NextByte;
      LCell := LCell + Word(NextByte) * 256;
    end
    else
      Dec(LNew);
    ACode := LCell and $C000;
    LCell := Word(LCell shl 2);
  end;

  function Place(AOffset: Integer): Integer;
  begin
    Result := FMap.Offset(AOffset) + FBase;
  end;

begin
  FData := AData;
  FSize := ASize;
  FPosition := 0;
  FBase := AFrameNumber * FDelta;
  LNew := 0;
  LCell := 0;
  LIndex := 0;
  repeat
    NextCode(LCode);
    case LCode of
      $8000:
        begin
          // vq code
          BlitVector(FCodebook.Vq8, NextByte, 8, Place(LIndex));
          Inc(LIndex, 5);
        end;
      $C000:
        begin
          // drop: the 8x8 block is split into four 4x4 ones
          Inc(LIndex);
          for LSub := 0 to 3 do
          begin
            NextCode(LSubCode);
            case LSubCode of
              $8000:
                BlitVector(FCodebook.Vq4, NextByte, 4, Place(LIndex));
              $C000:
                begin
                  LByte := Place(LIndex);
                  BlitVector(FCodebook.Vq2, NextByte, 2, LByte);
                  BlitVector(FCodebook.Vq2, NextByte, 2, LByte + 2);
                  BlitVector(FCodebook.Vq2, NextByte, 2, LByte + FWidth * 2);
                  BlitVector(FCodebook.Vq2, NextByte, 2, LByte + FWidth * 2 + 2);
                end;
              $4000:
                MoveBlock(4, Place(LIndex), FMotion[NextByte]);
            end;
            Inc(LIndex);
          end;
        end;
      $4000:
        begin
          // motion compensation
          MoveBlock(8, Place(LIndex), FMotion[NextByte]);
          Inc(LIndex, 5);
        end;
    else
      Inc(LIndex, 5);
    end;
  until LIndex >= FMap.Count;
  FData := nil;
end;

procedure TRoqFramePainter.CopyFirstToSecond;
begin
  Move(FImage[0], FImage[FDelta], FDelta * SizeOf(Cardinal));
end;

procedure TRoqFramePainter.LoadFirstFrame(const APixels: TImagingPixels);
begin
  if Length(APixels) <> FDelta then
    raise ERoqInvalidDataException.CreateFmt(SFrameSize, [Length(APixels), FDelta]);
  Move(APixels[0], FImage[0], FDelta * SizeOf(Cardinal));
  CopyFirstToSecond;
end;

function TRoqFramePainter.FrameCopy(AFrameNumber: Integer): TImagingPixels;
begin
  SetLength(Result, FDelta);
  Move(FImage[AFrameNumber * FDelta], Result[0], FDelta * SizeOf(Cardinal));
end;

end.
