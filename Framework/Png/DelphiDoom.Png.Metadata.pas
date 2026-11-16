{******************************************************************************}
{                                                                              }
{  DelphiDoom: PNG - header, palette, transparency and offsets of an image     }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Png.Metadata;

interface

{$POINTERMATH ON}

uses
  DelphiDoom.Png.Intf, DelphiDoom.Png.Header, DelphiDoom.Png.ChunkReader;

type
  /// <summary>
  ///   The palette of an image: pixels as Cardinal, B in the lowest byte, then
  ///   G, R and A (the layout of a decoded pixel in memory)
  /// </summary>
  TPngPaletteTable = array[0..255] of Cardinal;

  /// <summary>
  ///   Collects what the chunks before (and after) the image data say about an
  ///   image: the header, the palette, the tRNS transparency and the grAb
  ///   offsets. Every inconsistency is an EPngException
  /// </summary>
  TPngMetadata = class
  private
    FHeader: TPngHeader;
    FHasHeader: Boolean;
    FPalette: TPngPaletteTable;
    FPaletteCount: Integer;
    FHasPaletteChunk: Boolean;
    FTransparency: array[0..255] of Byte;
    FTransparencyCount: Integer;
    FHasKey: Boolean;
    FKeyGray: Integer;
    FKeyRed: Integer;
    FKeyGreen: Integer;
    FKeyBlue: Integer;
    FOffsetX: Integer;
    FOffsetY: Integer;

    procedure AcceptPalette(const AChunk: TPngChunk);
    procedure AcceptTransparency(const AChunk: TPngChunk);
    procedure AcceptOffsets(const AChunk: TPngChunk);
    function SampleMask: Integer;
    function ToEightBits(ASample: Integer): Cardinal;
    function FirstTransparentPaletteEntry: Integer;
  public
    constructor Create;

    /// <summary>
    ///   Takes the IHDR chunk, which must be the first of the file
    /// </summary>
    procedure AcceptHeader(const AChunk: TPngChunk);

    /// <summary>
    ///   Takes a chunk that is not IHDR, IDAT or IEND. Before the image data
    ///   (ABeforeImage) PLTE, tRNS and grAb are read and an unknown critical
    ///   chunk raises DDPNG_ERR_UNSUPPORTED; after it only grAb is read
    /// </summary>
    procedure Accept(const AChunk: TPngChunk; ABeforeImage: Boolean);

    /// <summary>
    ///   Called when the image data starts: checks that the palette an image
    ///   needs is there and merges the transparency of the tRNS chunk into it
    /// </summary>
    procedure Resolve;

    function BuildInfo: TPngInfo;

    /// <summary>
    ///   Copies the 256 entries of the palette (DDPNG_PALETTE_BYTES bytes);
    ///   they are final after Resolve
    /// </summary>
    procedure CopyPaletteTo(ADest: Pointer);

    property Header: TPngHeader read FHeader;
    property HasKey: Boolean read FHasKey;
    property KeyGray: Integer read FKeyGray;
    property KeyRed: Integer read FKeyRed;
    property KeyGreen: Integer read FKeyGreen;
    property KeyBlue: Integer read FKeyBlue;
  end;

implementation

uses
  DelphiDoom.Png.ByteOrder;

const
  PNG_OPAQUE_BLACK = $FF000000;
  PNG_MAX_PALETTE_ENTRIES = 256;

{ TPngMetadata }

constructor TPngMetadata.Create;
var
  LIndex: Integer;
begin
  inherited Create;
  for LIndex := 0 to PNG_MAX_PALETTE_ENTRIES - 1 do
    FPalette[LIndex] := PNG_OPAQUE_BLACK;
  FillChar(FTransparency, SizeOf(FTransparency), 0);
end;

procedure TPngMetadata.AcceptHeader(const AChunk: TPngChunk);
begin
  if FHasHeader or (AChunk.ChunkType <> PNG_CHUNK_IHDR) then
    raise EPngException.CreateCode(DDPNG_ERR_DATA);
  FHeader.Parse(AChunk.Data, AChunk.Size);
  FHasHeader := True;
end;

procedure TPngMetadata.Accept(const AChunk: TPngChunk; ABeforeImage: Boolean);
begin
  if not FHasHeader then
    raise EPngException.CreateCode(DDPNG_ERR_DATA);

  case AChunk.ChunkType of
    PNG_CHUNK_GRAB:
      AcceptOffsets(AChunk);
    PNG_CHUNK_PLTE:
      if ABeforeImage then
        AcceptPalette(AChunk);
    PNG_CHUNK_TRNS:
      if ABeforeImage then
        AcceptTransparency(AChunk);
  else
    // A chunk that is not ancillary and is not one of the known ones
    if ABeforeImage and AChunk.IsCritical then
      raise EPngException.CreateCode(DDPNG_ERR_UNSUPPORTED);
  end;
end;

procedure TPngMetadata.AcceptPalette(const AChunk: TPngChunk);
var
  LIndex: Integer;
  LEntry: PByte;
begin
  if FHasPaletteChunk then
    raise EPngException.CreateCode(DDPNG_ERR_DATA);
  if (AChunk.Size = 0) or (AChunk.Size mod 3 <> 0) or
     (AChunk.Size > PNG_MAX_PALETTE_ENTRIES * 3) then
    raise EPngException.CreateCode(DDPNG_ERR_DATA);
  FHasPaletteChunk := True;

  // The chunk is only a suggestion for the other color types: not stored
  if FHeader.ColorType <> DDPNG_COLOR_PALETTE then
    Exit;

  FPaletteCount := Integer(AChunk.Size div 3);
  if FPaletteCount > (1 shl FHeader.BitDepth) then
    raise EPngException.CreateCode(DDPNG_ERR_DATA);

  for LIndex := 0 to FPaletteCount - 1 do
  begin
    LEntry := AChunk.Data + LIndex * 3;
    FPalette[LIndex] := PNG_OPAQUE_BLACK or (Cardinal(LEntry[0]) shl 16) or
      (Cardinal(LEntry[1]) shl 8) or Cardinal(LEntry[2]);
  end;
end;

procedure TPngMetadata.AcceptTransparency(const AChunk: TPngChunk);
begin
  if FHasKey or (FTransparencyCount > 0) then
    raise EPngException.CreateCode(DDPNG_ERR_DATA);

  case FHeader.ColorType of
    DDPNG_COLOR_GRAY:
      begin
        if AChunk.Size <> 2 then
          raise EPngException.CreateCode(DDPNG_ERR_DATA);
        FKeyGray := Integer(TPngByteOrder.ReadWord(AChunk.Data)) and SampleMask;
        FHasKey := True;
      end;
    DDPNG_COLOR_RGB:
      begin
        if AChunk.Size <> 6 then
          raise EPngException.CreateCode(DDPNG_ERR_DATA);
        FKeyRed := Integer(TPngByteOrder.ReadWord(AChunk.Data)) and SampleMask;
        FKeyGreen := Integer(TPngByteOrder.ReadWord(AChunk.Data + 2)) and SampleMask;
        FKeyBlue := Integer(TPngByteOrder.ReadWord(AChunk.Data + 4)) and SampleMask;
        FHasKey := True;
      end;
    DDPNG_COLOR_PALETTE:
      begin
        if AChunk.Size > PNG_MAX_PALETTE_ENTRIES then
          raise EPngException.CreateCode(DDPNG_ERR_DATA);
        FTransparencyCount := Integer(AChunk.Size);
        if FTransparencyCount > 0 then
          Move(AChunk.Data^, FTransparency[0], FTransparencyCount);
      end;
  end;
  // The color types that have an alpha channel do not use the chunk
end;

procedure TPngMetadata.AcceptOffsets(const AChunk: TPngChunk);
begin
  if AChunk.Size < 8 then
    Exit;
  // Signed 32 bit values
  FOffsetX := Integer(TPngByteOrder.ReadCardinal(AChunk.Data));
  FOffsetY := Integer(TPngByteOrder.ReadCardinal(AChunk.Data + 4));
end;

function TPngMetadata.SampleMask: Integer;
begin
  Result := (1 shl FHeader.BitDepth) - 1;
end;

function TPngMetadata.ToEightBits(ASample: Integer): Cardinal;
begin
  case FHeader.BitDepth of
    16: Result := Cardinal(ASample shr 8);
    8:  Result := Cardinal(ASample);
  else
    Result := Cardinal(ASample * 255 div SampleMask);
  end;
end;

function TPngMetadata.FirstTransparentPaletteEntry: Integer;
var
  LIndex: Integer;
begin
  Result := -1;
  for LIndex := 0 to FTransparencyCount - 1 do
    if (FTransparency[LIndex] = 0) and (LIndex < FPaletteCount) then
      Exit(LIndex);
end;

procedure TPngMetadata.Resolve;
var
  LIndex: Integer;
begin
  if FHeader.ColorType <> DDPNG_COLOR_PALETTE then
    Exit;

  if FPaletteCount = 0 then
    raise EPngException.CreateCode(DDPNG_ERR_DATA);

  // Alpha of the entries the tRNS chunk covers; the others stay opaque
  for LIndex := 0 to FTransparencyCount - 1 do
    FPalette[LIndex] := (FPalette[LIndex] and $00FFFFFF) or
      (Cardinal(FTransparency[LIndex]) shl 24);
end;

function TPngMetadata.BuildInfo: TPngInfo;
var
  LGray: Cardinal;
  LEntry: Integer;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.Width := FHeader.Width;
  Result.Height := FHeader.Height;
  Result.BitDepth := FHeader.BitDepth;
  Result.ColorType := FHeader.ColorType;
  Result.Interlaced := Ord(FHeader.Interlaced);
  Result.PaletteCount := FPaletteCount;
  Result.OffsetX := FOffsetX;
  Result.OffsetY := FOffsetY;

  case FHeader.ColorType of
    DDPNG_COLOR_GRAY_ALPHA, DDPNG_COLOR_RGBA:
      Result.HasAlpha := 1;
    DDPNG_COLOR_GRAY:
      if FHasKey then
      begin
        LGray := ToEightBits(FKeyGray);
        Result.HasAlpha := 1;
        Result.HasTransparentColor := 1;
        Result.TransparentColor := (LGray shl 16) or (LGray shl 8) or LGray;
      end;
    DDPNG_COLOR_RGB:
      if FHasKey then
      begin
        Result.HasAlpha := 1;
        Result.HasTransparentColor := 1;
        Result.TransparentColor := (ToEightBits(FKeyRed) shl 16) or
          (ToEightBits(FKeyGreen) shl 8) or ToEightBits(FKeyBlue);
      end;
    DDPNG_COLOR_PALETTE:
      begin
        LEntry := FirstTransparentPaletteEntry;
        if LEntry >= 0 then
        begin
          Result.HasTransparentColor := 1;
          Result.TransparentColor := FPalette[LEntry] and $00FFFFFF;
        end;
        // Any entry below 255 makes some pixels not opaque
        for LEntry := 0 to FTransparencyCount - 1 do
          if FTransparency[LEntry] < 255 then
            Result.HasAlpha := 1;
      end;
  end;
end;

procedure TPngMetadata.CopyPaletteTo(ADest: Pointer);
begin
  Move(FPalette, ADest^, SizeOf(FPalette));
end;

end.
