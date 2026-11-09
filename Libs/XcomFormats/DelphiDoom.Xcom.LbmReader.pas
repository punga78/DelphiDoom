{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom formats library - .LBM files (IFF PBM and ILBM)            }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit. It follows the     }
{  behaviour of SDL_image 1.2.12 (IMG_LoadLBM_RW), the loader that OpenXcom    }
{  uses for the battlescape palettes of TFTD (UFOGRAPH\D0..D3.LBM)             }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Xcom.LbmReader;

interface

uses
  System.SysUtils, DelphiDoom.Xcom.Types, DelphiDoom.Xcom.Palette, DelphiDoom.Xcom.Image, DelphiDoom.Xcom.Intf;

type
  /// <summary>
  ///   IMG_LoadLBM_RW: an IFF file of type PBM (chunky, 8 planes) or ILBM (bit planes, 1 to 8) with the chunks
  ///   BMHD, CMAP and BODY (no compression or ByteRun1). Like SDL_image the width of the picture is rounded up
  ///   to a multiple of 16, and a PBM row has that many bytes. The palette has 1 shl planes colors (256 when
  ///   the file has no CMAP); the colors that the CMAP does not have are black. What SDL_image refuses (24 bit pictures, a CMAP of more than 256 colors, a PBM that
  ///   is not 8 planes, a missing chunk, a body that is too short) is EXcomDataException
  /// </summary>
  TXcomLbmReader = class(TInterfacedObject, IXcomLbmReader)
  public
    function Read(const ABytes: TBytes): TXcomLbmPicture;
  end;

implementation

uses
  System.Math;

const
  CHUNK_HEADER_BYTES = 8;
  FORM_HEADER_BYTES = 12;
  BMHD_BYTES = 20;

type
  TLbmCursor = record
    Bytes: TBytes;
    Position: Integer;
    function Remaining: Integer;
    function ReadByte: Byte;
    function ReadWord: Integer;
    function ReadCardinal: Cardinal;
    function ReadId: AnsiString;
  end;

{ TLbmCursor }

function TLbmCursor.Remaining: Integer;
begin
  Result := Length(Bytes) - Position;
end;

function TLbmCursor.ReadByte: Byte;
begin
  if Remaining < 1 then
    raise EXcomDataException.CreateFmt(SXcomLbmTooShort, [Position]);
  Result := Bytes[Position];
  Inc(Position);
end;

function TLbmCursor.ReadWord: Integer;
begin
  Result := ReadByte shl 8;
  Result := Result or ReadByte;
end;

function TLbmCursor.ReadCardinal: Cardinal;
begin
  Result := Cardinal(ReadWord) shl 16;
  Result := Result or Cardinal(ReadWord);
end;

function TLbmCursor.ReadId: AnsiString;
var
  LIndex: Integer;
begin
  SetLength(Result, 4);
  for LIndex := 1 to 4 do
    Result[LIndex] := AnsiChar(ReadByte);
end;

type
  TLbmHeader = record
    Width: Integer;
    Height: Integer;
    Planes: Integer;
    Masking: Integer;
    Compression: Integer;
    Transparent: Integer;
  end;

procedure DecodeRow(var ACursor: TLbmCursor; var ARow: TBytes; ACount, ACompression: Integer);
var
  LFilled: Integer;
  LControl: Integer;
  LLength: Integer;
  LValue: Byte;
begin
  if ACompression = 0 then
  begin
    if ACursor.Remaining < ACount then
      raise EXcomDataException.CreateFmt(SXcomLbmTooShort, [ACursor.Position]);
    Move(ACursor.Bytes[ACursor.Position], ARow[0], ACount);
    Inc(ACursor.Position, ACount);
    Exit;
  end;
  LFilled := 0;
  while LFilled < ACount do
  begin
    LControl := ACursor.ReadByte;
    if LControl < 128 then
    begin
      LLength := LControl + 1;
      while LLength > 0 do
      begin
        LValue := ACursor.ReadByte;
        if LFilled < ACount then
          ARow[LFilled] := LValue;
        Inc(LFilled);
        Dec(LLength);
      end;
    end
    else if LControl > 128 then
    begin
      LLength := 257 - LControl;
      LValue := ACursor.ReadByte;
      while LLength > 0 do
      begin
        if LFilled < ACount then
          ARow[LFilled] := LValue;
        Inc(LFilled);
        Dec(LLength);
      end;
    end;
  end;
end;

{ TXcomLbmReader }

function TXcomLbmReader.Read(const ABytes: TBytes): TXcomLbmPicture;
var
  LCursor: TLbmCursor;
  LId: AnsiString;
  LType: AnsiString;
  LSize: Cardinal;
  LNext: Integer;
  LIsPbm: Boolean;
  LHeader: TLbmHeader;
  LHasHeader: Boolean;
  LColorCount: Integer;
  LColorMap: TBytes;
  LHasMap: Boolean;
  LWidth: Integer;
  LStride: Integer;
  LPlaneCount: Integer;
  LRow: TBytes;
  LY, LX, LPlane, LPaletteCount: Integer;
  LValue: Integer;
  LIndex: Integer;
  LSource: Integer;
begin
  LCursor.Bytes := ABytes;
  LCursor.Position := 0;
  LId := LCursor.ReadId;
  LCursor.ReadCardinal;
  LType := LCursor.ReadId;
  if LId <> 'FORM' then
    raise EXcomDataException.Create(SXcomLbmNotIff);
  LIsPbm := LType = 'PBM ';
  if not LIsPbm and (LType <> 'ILBM') then
    raise EXcomDataException.Create(SXcomLbmNotIff);
  FillChar(LHeader, SizeOf(LHeader), 0);
  LHasHeader := False;
  LHasMap := False;
  LColorCount := 0;
  repeat
    LId := LCursor.ReadId;
    LSize := LCursor.ReadCardinal;
    if LId = 'BODY' then
      Break;
    if LSize > Cardinal(LCursor.Remaining) then
      raise EXcomDataException.CreateFmt(SXcomLbmTooShort, [LCursor.Position]);
    LNext := LCursor.Position + Integer(LSize) + Integer(LSize and 1);
    if LId = 'BMHD' then
    begin
      if LSize < BMHD_BYTES then
        raise EXcomDataException.CreateFmt(SXcomLbmTooShort, [LCursor.Position]);
      LHeader.Width := LCursor.ReadWord;
      LHeader.Height := LCursor.ReadWord;
      LCursor.ReadWord;
      LCursor.ReadWord;
      LHeader.Planes := LCursor.ReadByte;
      LHeader.Masking := LCursor.ReadByte;
      LHeader.Compression := LCursor.ReadByte;
      LCursor.ReadByte;
      LHeader.Transparent := LCursor.ReadWord;
      LHasHeader := True;
    end
    else if LId = 'CMAP' then
    begin
      LColorCount := LSize div 3;
      if LColorCount > XCOM_PALETTE_COLORS then
        raise EXcomDataException.CreateFmt(SXcomLbmTooManyColors, [LColorCount]);
      SetLength(LColorMap, LColorCount * 3);
      if LColorCount > 0 then
        Move(LCursor.Bytes[LCursor.Position], LColorMap[0], LColorCount * 3);
      LHasMap := True;
    end;
    LCursor.Position := Min(LNext, Length(ABytes));
  until False;
  if not LHasHeader then
    raise EXcomDataException.Create(SXcomLbmNoHeader);
  if (LHeader.Planes < 1) or (LHeader.Planes > 8) or (LIsPbm and (LHeader.Planes <> 8)) or
    (LIsPbm and (LHeader.Masking = 1)) or (LHeader.Compression > 1) or (LHeader.Width = 0) or
    (LHeader.Height = 0) then
    raise EXcomDataException.CreateFmt(SXcomLbmUnsupported, [LHeader.Planes, LHeader.Masking, LHeader.Compression]);
  LWidth := (LHeader.Width + 15) and not 15;
  Result.Image := TXcomImage.Create(LWidth, LHeader.Height);
  if LIsPbm then
  begin
    LStride := LWidth;
    LPlaneCount := 1;
  end
  else
  begin
    LStride := ((LHeader.Width + 15) div 16) * 2;
    LPlaneCount := LHeader.Planes;
    if LHeader.Masking = 1 then
      Inc(LPlaneCount);
  end;
  SetLength(LRow, LStride);
  for LY := 0 to LHeader.Height - 1 do
  begin
    if LIsPbm then
    begin
      DecodeRow(LCursor, LRow, LStride, LHeader.Compression);
      Move(LRow[0], Result.Image.Pixels[LY * LWidth], LWidth);
    end
    else
      for LPlane := 0 to LPlaneCount - 1 do
      begin
        DecodeRow(LCursor, LRow, LStride, LHeader.Compression);
        // SDL_image takes the mask plane as one more bit plane (and the bit 8 of a 9th plane is lost)
        if LPlane < 8 then
          for LX := 0 to LWidth - 1 do
          begin
            LValue := (LRow[LX shr 3] shr (7 - (LX and 7))) and 1;
            Result.Image.Pixels[LY * LWidth + LX] :=
              Result.Image.Pixels[LY * LWidth + LX] or Byte(LValue shl LPlane);
          end;
      end;
  end;
  if LHasMap then
    LPaletteCount := 1 shl LHeader.Planes
  else
    LPaletteCount := XCOM_PALETTE_COLORS;
  Result.Image.Palette := TXcomPalette.Create(LPaletteCount);
  for LIndex := 0 to LPaletteCount - 1 do
  begin
    Result.Image.Palette.Colors[LIndex].Alpha := 255;
    // an ILBM that has fewer colors than 2^planes repeats them; a PBM leaves the rest black
    if (LIndex < LColorCount) or (not LIsPbm and (LColorCount > 0)) then
    begin
      LSource := LIndex mod LColorCount;
      Result.Image.Palette.Colors[LIndex].Red := LColorMap[LSource * 3];
      Result.Image.Palette.Colors[LIndex].Green := LColorMap[LSource * 3 + 1];
      Result.Image.Palette.Colors[LIndex].Blue := LColorMap[LSource * 3 + 2];
    end;
  end;
  Result.Image.HasPalette := True;
  Result.HasColorKey := LHeader.Masking = 2;
  if Result.HasColorKey then
    Result.ColorKey := LHeader.Transparent
  else
    Result.ColorKey := 0;
end;

end.
