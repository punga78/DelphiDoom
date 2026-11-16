{******************************************************************************}
{                                                                              }
{  DelphiDoom: cinematic library - the codebook of the vectors of RoQ          }
{                                                                              }
{  Port of decodeCodeBook (the 32 bit pixels, full size case) of the RoQ       }
{  decoder of Quake III Arena (cl_cin.c, GPL v2 or later, Copyright (C)        }
{  1999-2005 Id Software, Inc.) and of Doom 3 (Cinematic.cpp, GPL v3 with the  }
{  additional terms of the Doom 3 Source Code License, Copyright (C)           }
{  1999-2011 id Software LLC). Based on the Doom 3 GPL Source Code.            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Cinematic.Codebook;

{$Q-}
{$R-}

interface

uses
  System.SysUtils,
  DelphiDoom.Cinematic.YuvConverter;

const
  /// <summary>Entries of every table of the codebook (an index is a byte)</summary>
  ROQ_CODEBOOK_ENTRIES = 256;
  /// <summary>Pixels of a 2x2, 4x4 and 8x8 vector</summary>
  ROQ_VECTOR2_PIXELS = 4;
  ROQ_VECTOR4_PIXELS = 16;
  ROQ_VECTOR8_PIXELS = 64;

type
  /// <summary>
  ///   The vectors of a RoQ file: 2x2 ones from the colors in the chunk, and 4x4 and 8x8 ones
  ///   that are built from them (vq2, vq4 and vq8 of the original). A new chunk replaces the
  ///   entries it has and leaves the others as they were, as the original does
  /// </summary>
  TRoqCodebook = class
  strict private
    FConverter: TRoqYuvConverter;
    FVq2: TArray<Cardinal>;
    FVq4: TArray<Cardinal>;
    FVq8: TArray<Cardinal>;
    FLoaded: Boolean;
  public
    /// <param name="AConverter">Gives the colors; it stays the property of the caller</param>
    constructor Create(const AConverter: TRoqYuvConverter);
    /// <summary>Decodes a chunk of ROQ_CODEBOOK: AFlags is the number of 2x2 vectors (high byte, 0 = 256) and 4x4 vectors (low byte)</summary>
    procedure Decode(const AData: TBytes; AFlags: Word);
    /// <summary>Forgets everything (the start of a file)</summary>
    procedure Clear;
    /// <summary>False until a chunk has been decoded</summary>
    property Loaded: Boolean read FLoaded;
    /// <summary>The 2x2 vectors, 4 pixels each, row by row</summary>
    property Vq2: TArray<Cardinal> read FVq2;
    /// <summary>The 4x4 vectors, 16 pixels each</summary>
    property Vq4: TArray<Cardinal> read FVq4;
    /// <summary>The 8x8 vectors, 64 pixels each</summary>
    property Vq8: TArray<Cardinal> read FVq8;
  end;

implementation

uses
  DelphiDoom.Cinematic.Types;

resourcestring
  SCodebookTooShort = 'The codebook chunk has %d bytes but %d are needed';

{ TRoqCodebook }

constructor TRoqCodebook.Create(const AConverter: TRoqYuvConverter);
begin
  inherited Create;
  FConverter := AConverter;
  Clear;
end;

procedure TRoqCodebook.Clear;
begin
  FVq2 := nil;
  FVq4 := nil;
  FVq8 := nil;
  SetLength(FVq2, ROQ_CODEBOOK_ENTRIES * ROQ_VECTOR2_PIXELS);
  SetLength(FVq4, ROQ_CODEBOOK_ENTRIES * ROQ_VECTOR4_PIXELS);
  SetLength(FVq8, ROQ_CODEBOOK_ENTRIES * ROQ_VECTOR8_PIXELS);
  FLoaded := False;
end;

procedure TRoqCodebook.Decode(const AData: TBytes; AFlags: Word);
var
  LTwo, LFour, LIndex, LRepeat, LInput, LOutput: Integer;
  LY0, LY1, LY2, LY3, LCr, LCb: Integer;
  LA, LB, LC, LD: Integer;

  procedure PutBlock;
  begin
    // VQ2TO4: LA and LB point at two 2x2 vectors; LC gets 4 pixels (the top row of A, the
    // top row of B, the bottom rows) and LD gets the same rows doubled on both axes
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
    raise ERoqTruncatedException.CreateFmt(SCodebookTooShort,
      [Length(AData), LTwo * 6 + LFour * 2]);
  LInput := 0;
  for LIndex := 0 to LTwo - 1 do
  begin
    LY0 := AData[LInput];
    LY1 := AData[LInput + 1];
    LY2 := AData[LInput + 2];
    LY3 := AData[LInput + 3];
    LCr := AData[LInput + 4];
    LCb := AData[LInput + 5];
    Inc(LInput, 6);
    LOutput := LIndex * ROQ_VECTOR2_PIXELS;
    FVq2[LOutput] := FConverter.ToPixel(LY0, LCr, LCb);
    FVq2[LOutput + 1] := FConverter.ToPixel(LY1, LCr, LCb);
    FVq2[LOutput + 2] := FConverter.ToPixel(LY2, LCr, LCb);
    FVq2[LOutput + 3] := FConverter.ToPixel(LY3, LCr, LCb);
  end;
  LC := 0;
  LD := 0;
  for LIndex := 0 to LFour - 1 do
  begin
    LA := AData[LInput] * ROQ_VECTOR2_PIXELS;
    LB := AData[LInput + 1] * ROQ_VECTOR2_PIXELS;
    Inc(LInput, 2);
    for LRepeat := 0 to 1 do
      PutBlock;
  end;
  FLoaded := True;
end;

end.
