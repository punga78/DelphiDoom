{******************************************************************************}
{                                                                              }
{  DelphiDoom: cinematic library - the codebook in the modes of Quake III      }
{                                                                              }
{  Port of decodeCodeBook of the RoQ decoder of Quake III Arena (cl_cin.c, GPL }
{  v2 or later, Copyright (C) 1999-2005 Id Software, Inc.) for every           }
{  combination of samplesPerPixel (4, 2, 1), half and smootheddouble.          }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Cinematic.ModeCodebook;

{$Q-}
{$R-}

interface

uses
  System.SysUtils,
  DelphiDoom.Cinematic.Types,
  DelphiDoom.Cinematic.YuvConverter;

type
  /// <summary>
  ///   The vectors of a RoQ codebook as <c>decodeCodeBook</c> of Quake III builds them in each of its
  ///   modes: 32 bit pixels, RGB 5-6-5 pixels or gray levels, normal, <c>half</c> (a quarter of the
  ///   screen) or <c>smootheddouble</c> (double height). The three buffers have the size of the
  ///   original (vq2 = 32 KB, vq4 = 128 KB, vq8 = 512 KB) and keep what a chunk does not rewrite;
  ///   <c>Vq2Bytes</c>, <c>Vq4Bytes</c> and <c>Vq8Bytes</c> give them as the bytes that the original
  ///   holds in memory (little endian words). <b>Only the codebook is ported</b>: in the original the
  ///   frame painters (<c>blitVQQuad32fs</c>) read the vectors as 32 bit pixels in every mode, so a
  ///   frame painted in the other modes is garbage there and is not reproduced here; the 32 bit
  ///   codebook in normal mode is <c>TRoqCodebook</c>, which this class repeats with other storage
  /// </summary>
  TRoqModeCodebook = class
  strict private
    FConverter: TRoqYuvConverter;
    FOwnsConverter: Boolean;
    FMode: TRoqCodebookMode;
    FGray: TBytes;
    FUnitSize: Integer;
    FVq2: TArray<Cardinal>;
    FVq4: TArray<Cardinal>;
    FVq8: TArray<Cardinal>;
    FLoaded: Boolean;
    function Element(AY, ACr, ACb: Integer): Cardinal;
    function ToBytes(const AElements: TArray<Cardinal>): TBytes;
    function ReadVectors(const AData: TBytes; ATwo: Integer): Integer;
    procedure WriteBlocks(const AData: TBytes; AInput, AFour: Integer);
  public
    /// <param name="AConverter">The colors of the 32 bit and 16 bit pixels (not owned)</param>
    /// <param name="AGray">
    ///   The 256 gray levels for <c>rpfGray8</c> (<c>cinTable.gray</c>, which the original never fills
    ///   and then reads through a nil pointer); ignored for the other formats
    /// </param>
    /// <param name="AOwnsConverter">True when the codebook frees the converter with itself</param>
    constructor Create(const AConverter: TRoqYuvConverter; const AMode: TRoqCodebookMode;
      const AGray: TBytes = nil; AOwnsConverter: Boolean = False);
    destructor Destroy; override;
    /// <summary>
    ///   decodeCodeBook: the chunk flags have the number of 2x2 vectors in the high byte (0 = 256) and of
    ///   pairs in the low byte (all zero = 256 and 256). Data shorter than needed are an
    ///   <c>ERoqTruncatedException</c> (the original reads past them)
    /// </summary>
    procedure Decode(const AData: TBytes; AFlags: Word);
    /// <summary>Back to the zeroed buffers of a new video</summary>
    procedure Clear;
    function Vq2Bytes: TBytes;
    function Vq4Bytes: TBytes;
    function Vq8Bytes: TBytes;
    property Mode: TRoqCodebookMode read FMode;
    /// <summary>The bytes of one pixel: 4, 2 or 1</summary>
    property PixelSize: Integer read FUnitSize;
    property Loaded: Boolean read FLoaded;
  end;

implementation

const
  VQ2_BYTES = 256 * 16 * 4 * 2;
  VQ4_BYTES = 256 * 64 * 4 * 2;
  VQ8_BYTES = 256 * 256 * 4 * 2;

resourcestring
  SModeCodebookTooShort = 'The codebook chunk has %d bytes but %d are needed';
  SModeGrayTable = 'The gray format needs a table of 256 levels';

{ TRoqModeCodebook }

constructor TRoqModeCodebook.Create(const AConverter: TRoqYuvConverter;
  const AMode: TRoqCodebookMode; const AGray: TBytes; AOwnsConverter: Boolean);
begin
  inherited Create;
  FConverter := AConverter;
  FMode := AMode;
  case AMode.PixelFormat of
    rpfRgba32:
      FUnitSize := 4;
    rpfRgb565:
      FUnitSize := 2;
  else
    FUnitSize := 1;
    if Length(AGray) <> 256 then
      raise ERoqInvalidDataException.Create(SModeGrayTable);
    FGray := Copy(AGray);
  end;
  // the converter is taken only when the constructor can no longer fail, so the factory frees it
  // itself if the gray table is wrong
  FOwnsConverter := AOwnsConverter;
  Clear;
end;

destructor TRoqModeCodebook.Destroy;
begin
  if FOwnsConverter then
    FConverter.Free;
  inherited Destroy;
end;

procedure TRoqModeCodebook.Clear;
begin
  FVq2 := nil;
  FVq4 := nil;
  FVq8 := nil;
  SetLength(FVq2, VQ2_BYTES div FUnitSize);
  SetLength(FVq4, VQ4_BYTES div FUnitSize);
  SetLength(FVq8, VQ8_BYTES div FUnitSize);
  FLoaded := False;
end;

function TRoqModeCodebook.Element(AY, ACr, ACb: Integer): Cardinal;
begin
  case FMode.PixelFormat of
    rpfRgba32:
      Result := FConverter.ToPixel(AY, ACr, ACb);
    rpfRgb565:
      Result := FConverter.ToRgb565(AY, ACr, ACb);
  else
    Result := FGray[AY];
  end;
end;

function TRoqModeCodebook.ToBytes(const AElements: TArray<Cardinal>): TBytes;
var
  LIndex, LByte: Integer;
begin
  SetLength(Result, Length(AElements) * FUnitSize);
  for LIndex := 0 to High(AElements) do
    for LByte := 0 to FUnitSize - 1 do
      Result[LIndex * FUnitSize + LByte] := Byte(AElements[LIndex] shr (8 * LByte));
end;

function TRoqModeCodebook.Vq2Bytes: TBytes;
begin
  Result := ToBytes(FVq2);
end;

function TRoqModeCodebook.Vq4Bytes: TBytes;
begin
  Result := ToBytes(FVq4);
end;

function TRoqModeCodebook.Vq8Bytes: TBytes;
begin
  Result := ToBytes(FVq8);
end;

function TRoqModeCodebook.ReadVectors(const AData: TBytes; ATwo: Integer): Integer;
var
  LIndex, LInput, LOutput: Integer;
  LY0, LY1, LY2, LY3, LCr, LCb: Integer;
begin
  LInput := 0;
  LOutput := 0;
  for LIndex := 0 to ATwo - 1 do
  begin
    LY0 := AData[LInput];
    LY1 := AData[LInput + 1];
    LY2 := AData[LInput + 2];
    LY3 := AData[LInput + 3];
    LCr := AData[LInput + 4];
    LCb := AData[LInput + 5];
    if FMode.Half then
    begin
      // a quarter of the screen: the first and the third luminance only
      FVq2[LOutput] := Element(LY0, LCr, LCb);
      FVq2[LOutput + 1] := Element(LY2, LCr, LCb);
      Inc(LOutput, 2);
    end
    else if FMode.SmoothedDouble then
    begin
      // double height: the two middle rows are mixes of the rows above and below
      FVq2[LOutput] := Element(LY0, LCr, LCb);
      FVq2[LOutput + 1] := Element(LY1, LCr, LCb);
      FVq2[LOutput + 2] := Element((LY0 * 3 + LY2) div 4, LCr, LCb);
      FVq2[LOutput + 3] := Element((LY1 * 3 + LY3) div 4, LCr, LCb);
      FVq2[LOutput + 4] := Element((LY0 + LY2 * 3) div 4, LCr, LCb);
      FVq2[LOutput + 5] := Element((LY1 + LY3 * 3) div 4, LCr, LCb);
      FVq2[LOutput + 6] := Element(LY2, LCr, LCb);
      FVq2[LOutput + 7] := Element(LY3, LCr, LCb);
      Inc(LOutput, 8);
    end
    else
    begin
      FVq2[LOutput] := Element(LY0, LCr, LCb);
      FVq2[LOutput + 1] := Element(LY1, LCr, LCb);
      FVq2[LOutput + 2] := Element(LY2, LCr, LCb);
      FVq2[LOutput + 3] := Element(LY3, LCr, LCb);
      Inc(LOutput, 4);
    end;
    Inc(LInput, 6);
  end;
  Result := LInput;
end;

procedure TRoqModeCodebook.WriteBlocks(const AData: TBytes; AInput, AFour: Integer);
var
  LIndex, LRepeat, LStep: Integer;
  LA, LB, LC, LD: Integer;

  procedure PutBlock4;
  begin
    // VQ2TO4: c gets the first element of each of the four rows, d every element twice and the
    // four rows again
    FVq4[LC] := FVq2[LA];
    FVq8[LD] := FVq2[LA];
    FVq8[LD + 1] := FVq2[LA];
    FVq4[LC + 1] := FVq2[LA + 1];
    FVq8[LD + 2] := FVq2[LA + 1];
    FVq8[LD + 3] := FVq2[LA + 1];
    FVq4[LC + 2] := FVq2[LB];
    FVq8[LD + 4] := FVq2[LB];
    FVq8[LD + 5] := FVq2[LB];
    FVq4[LC + 3] := FVq2[LB + 1];
    FVq8[LD + 6] := FVq2[LB + 1];
    FVq8[LD + 7] := FVq2[LB + 1];
    FVq8[LD + 8] := FVq2[LA];
    FVq8[LD + 9] := FVq2[LA];
    FVq8[LD + 10] := FVq2[LA + 1];
    FVq8[LD + 11] := FVq2[LA + 1];
    FVq8[LD + 12] := FVq2[LB];
    FVq8[LD + 13] := FVq2[LB];
    FVq8[LD + 14] := FVq2[LB + 1];
    FVq8[LD + 15] := FVq2[LB + 1];
    Inc(LC, 4);
    Inc(LD, 16);
    Inc(LA, 2);
    Inc(LB, 2);
  end;

  procedure PutBlock2;
  begin
    // VQ2TO2: the half size version, one element per row
    FVq4[LC] := FVq2[LA];
    FVq8[LD] := FVq2[LA];
    FVq8[LD + 1] := FVq2[LA];
    FVq4[LC + 1] := FVq2[LB];
    FVq8[LD + 2] := FVq2[LB];
    FVq8[LD + 3] := FVq2[LB];
    FVq8[LD + 4] := FVq2[LA];
    FVq8[LD + 5] := FVq2[LA];
    FVq8[LD + 6] := FVq2[LB];
    FVq8[LD + 7] := FVq2[LB];
    Inc(LC, 2);
    Inc(LD, 8);
    Inc(LA);
    Inc(LB);
  end;

begin
  if FMode.Half then
    LStep := 2
  else if FMode.SmoothedDouble then
    LStep := 8
  else
    LStep := 4;
  LC := 0;
  LD := 0;
  for LIndex := 0 to AFour - 1 do
  begin
    LA := AData[AInput] * LStep;
    LB := AData[AInput + 1] * LStep;
    Inc(AInput, 2);
    for LRepeat := 0 to 1 do
      if FMode.Half then
        PutBlock2
      else if FMode.SmoothedDouble then
      begin
        PutBlock4;
        PutBlock4;
      end
      else
        PutBlock4;
  end;
end;

procedure TRoqModeCodebook.Decode(const AData: TBytes; AFlags: Word);
var
  LTwo, LFour, LInput: Integer;
begin
  if AFlags = 0 then
  begin
    LTwo := 256;
    LFour := 256;
  end
  else
  begin
    LTwo := AFlags shr 8;
    if LTwo = 0 then
      LTwo := 256;
    LFour := AFlags and $FF;
  end;
  LFour := LFour * 2;
  if Length(AData) < LTwo * 6 + LFour * 2 then
    raise ERoqTruncatedException.CreateFmt(SModeCodebookTooShort,
      [Length(AData), LTwo * 6 + LFour * 2]);
  LInput := ReadVectors(AData, LTwo);
  WriteBlocks(AData, LInput, LFour);
  FLoaded := True;
end;

end.
