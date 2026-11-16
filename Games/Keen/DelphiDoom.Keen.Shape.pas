{******************************************************************************}
{                                                                              }
{  DelphiDoom: keen library - a full screen picture (an ILBM of Deluxe Paint)   }
{  Port of Commander Keen in Keen Dreams (id Software), GPL v2 or later:        }
{  struct Shape and BitMapHeader of kd_def.h, the ILBM part of LoadLIBShape of  }
{  soft.c, UnpackEGAShapeToScreen and MoveGfxDst of gelib.c                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.Shape;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Keen.Types, DelphiDoom.Keen.Intf;

type
  /// <summary>struct Shape: the header of the bitmap, the bytes of a row and the body (rows of planes, packed or not)</summary>
  TKeenShape = record
    Width: Word;
    Height: Word;
    X: Word;
    Y: Word;
    /// <summary>The planes of a pixel (4 for the 16 colors of the EGA)</summary>
    Depth: Byte;
    Transparent: Byte;
    /// <summary>0 for plain rows, another number for ByteRun1 (PackBits)</summary>
    Compression: Byte;
    Pad: Byte;
    /// <summary>BPR: (Width + 7) div 8</summary>
    BytesPerRow: Integer;
    Data: TBytes;
  end;

  /// <summary>
  ///   The title picture of the game. It is an IFF file (FORM ILBM, numbers with the high byte first) with the
  ///   chunks BMHD and BODY; the others (the palette, the things of the paint program) are skipped. It is
  ///   unpacked straight into the planes of the video memory: for each row, each plane in turn
  /// </summary>
  TKeenShapeReader = class
  public
    /// <summary>LoadLIBShape after the file was expanded: what is not such a picture is an EKeenDataException</summary>
    class function Parse(const AIff: TBytes): TKeenShape; static;
    /// <summary>
    ///   UnpackEGAShapeToScreen: the picture at the pixel (AStartX, AStartY) of the page at DisplayOfs. A row is
    ///   padded to an even number of bytes in the file and the pad byte is not drawn. A run that goes past the end
    ///   of its row, or data that end early, are an EKeenDataException (the C goes on in the memory)
    /// </summary>
    class procedure UnpackToScreen(const AVideo: IKeenVideo; const AShape: TKeenShape; AStartX, AStartY: Integer); static;
    /// <summary>MoveGfxDst: the buffer page and the display page both start at the pixel (AX, AY) of the memory</summary>
    class procedure MoveGfxDst(const AVideo: IKeenVideo; AX, AY: Integer); static;
  end;

implementation

{ TKeenShapeReader }

class function TKeenShapeReader.Parse(const AIff: TBytes): TKeenShape;
var
  LPosition: Integer;
  LChunkLength: Cardinal;
  LPadded: Int64;
  LFoundHeader: Boolean;

  function IsChunk(AAt: Integer; const AName: AnsiString): Boolean;
  begin
    Result := (AAt >= 0) and (AAt + 4 <= Length(AIff)) and (AIff[AAt] = Ord(AName[1])) and
      (AIff[AAt + 1] = Ord(AName[2])) and (AIff[AAt + 2] = Ord(AName[3])) and (AIff[AAt + 3] = Ord(AName[4]));
  end;

  function BigLong(AAt: Integer): Cardinal;
  begin
    if AAt + 4 > Length(AIff) then
      raise EKeenDataException.CreateFmt(SKeenShapeBad, ['the file is cut']);
    Result := (Cardinal(AIff[AAt]) shl 24) or (Cardinal(AIff[AAt + 1]) shl 16) or (Cardinal(AIff[AAt + 2]) shl 8) or
      Cardinal(AIff[AAt + 3]);
  end;

  function BigWord(AAt: Integer): Word;
  begin
    Result := Word((Word(AIff[AAt]) shl 8) or AIff[AAt + 1]);
  end;

begin
  Result := Default(TKeenShape);
  if not IsChunk(0, 'FORM') then
    raise EKeenDataException.CreateFmt(SKeenShapeBad, ['no FORM']);
  if not IsChunk(8, 'ILBM') then
    raise EKeenDataException.CreateFmt(SKeenShapeBad, ['no ILBM']);
  LPosition := 12;
  LFoundHeader := False;
  while LPosition + 8 <= Length(AIff) do
  begin
    LChunkLength := BigLong(LPosition + 4);
    // a chunk is padded to an even length
    LPadded := (Int64(LChunkLength) + 1) and not Int64(1);
    if IsChunk(LPosition, 'BMHD') then
    begin
      if LPosition + 8 + 12 > Length(AIff) then
        raise EKeenDataException.CreateFmt(SKeenShapeBad, ['the BMHD chunk is cut']);
      Result.Width := BigWord(LPosition + 8);
      Result.Height := BigWord(LPosition + 10);
      Result.X := BigWord(LPosition + 12);
      Result.Y := BigWord(LPosition + 14);
      Result.Depth := AIff[LPosition + 16];
      Result.Transparent := AIff[LPosition + 17];
      Result.Compression := AIff[LPosition + 18];
      Result.Pad := AIff[LPosition + 19];
      LFoundHeader := True;
    end
    else if IsChunk(LPosition, 'BODY') then
    begin
      if not LFoundHeader then
        raise EKeenDataException.CreateFmt(SKeenShapeBad, ['the BODY comes before the BMHD']);
      if Int64(LPosition) + 8 + LChunkLength > Length(AIff) then
        raise EKeenDataException.CreateFmt(SKeenShapeBad, ['the BODY chunk is cut']);
      Result.BytesPerRow := (Result.Width + 7) shr 3;
      Result.Data := Copy(AIff, LPosition + 8, LChunkLength);
      Exit;
    end;
    if Int64(LPosition) + 8 + LPadded > MaxInt then
      Break;
    Inc(LPosition, 8 + LPadded);
  end;
  raise EKeenDataException.CreateFmt(SKeenShapeBad, ['no BODY']);
end;

class procedure TKeenShapeReader.MoveGfxDst(const AVideo: IKeenVideo; AX, AY: Integer);
var
  LAddress: Integer;
begin
  LAddress := (AY * AVideo.LineWidth + AX div 8) and $FFFF;
  AVideo.BufferOfs := LAddress;
  AVideo.DisplayOfs := LAddress;
end;

class procedure TKeenShapeReader.UnpackToScreen(const AVideo: IKeenVideo; const AShape: TKeenShape;
  AStartX, AStartY: Integer);
var
  LMemory: IKeenEgaMemory;
  LNotWordAligned: Boolean;
  LSource: Integer;
  LRow: Integer;
  LPlane: Integer;
  LLeft: Integer;
  LCount: Integer;
  LCode: ShortInt;
  LDest: Integer;
  LRowStart: Integer;
  LValue: Byte;

  function Next: Byte;
  begin
    if LSource >= Length(AShape.Data) then
      raise EKeenDataException.CreateFmt(SKeenShapeBad, ['the body ends before the picture']);
    Result := AShape.Data[LSource];
    Inc(LSource);
  end;

begin
  if (AShape.Depth > KEEN_EGA_PLANES) or (AShape.BytesPerRow <= 0) then
    raise EKeenDataException.CreateFmt(SKeenShapeBad, [Format('%d planes, %d bytes a row', [AShape.Depth,
      AShape.BytesPerRow])]);
  LMemory := AVideo.Memory;
  LNotWordAligned := (AShape.BytesPerRow and 1) <> 0;
  LSource := 0;
  for LRow := 0 to AShape.Height - 1 do
  begin
    LRowStart := AVideo.DisplayOfs + AVideo.YLookup(AStartY + LRow) + (AStartX shr 3);
    for LPlane := 0 to AShape.Depth - 1 do
    begin
      LDest := LRowStart;
      // the row of the file, with its pad byte
      LLeft := ((AShape.BytesPerRow + 1) shr 1) shl 1;
      while LLeft > 0 do
      begin
        if AShape.Compression <> 0 then
          LCode := ShortInt(Next)
        else
          LCode := ShortInt(LLeft - 1);
        if LCode < 0 then
        begin
          if LCode <> -128 then
          begin
            // a run: the next byte, 1 - code times
            LCount := -Integer(LCode) + 1;
            if LCount > LLeft then
              raise EKeenDataException.CreateFmt(SKeenShapeBad, ['a run goes past the end of its row']);
            Dec(LLeft, LCount);
            LValue := Next;
            if (LLeft = 0) and LNotWordAligned then
              Dec(LCount);
            while LCount > 0 do
            begin
              LMemory.WriteByte(LPlane, LDest and $FFFF, LValue);
              Inc(LDest);
              Dec(LCount);
            end;
          end
          else
            // the C counts the "do nothing" code as a byte of the row
            Dec(LLeft);
        end
        else
        begin
          // bytes as they are, code + 1 of them
          LCount := Integer(LCode) + 1;
          if LCount > LLeft then
            raise EKeenDataException.CreateFmt(SKeenShapeBad, ['a run goes past the end of its row']);
          Dec(LLeft, LCount);
          if (LLeft = 0) and LNotWordAligned then
          begin
            Dec(LCount);
            while LCount > 0 do
            begin
              LMemory.WriteByte(LPlane, LDest and $FFFF, Next);
              Inc(LDest);
              Dec(LCount);
            end;
            // the pad byte
            Next;
          end
          else
            while LCount > 0 do
            begin
              LMemory.WriteByte(LPlane, LDest and $FFFF, Next);
              Inc(LDest);
              Dec(LCount);
            end;
        end;
      end;
    end;
  end;
end;

end.
