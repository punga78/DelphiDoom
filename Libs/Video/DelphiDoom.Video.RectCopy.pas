{******************************************************************************}
{                                                                              }
{  DelphiDoom: video library - the rows of the copy of a rectangle              }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Video.RectCopy;

// The loops are the ones of V_CopyRect8, V_CopyRect8_MT, V_CopyRect32 and V_CopyRect32_MT of
// v_video, that were four copies: here one per depth, with the interleaving of the rows of
// the threads as a parameter. The fixed point arithmetic wraps on purpose: {$Q-} {$R-}
{$Q-}
{$R-}

interface

type
  /// <summary>
  ///   What a copy of a rectangle to a bigger screen needs: the two screens (pitches in
  ///   pixels), where the rectangle goes and the steps of the source position (16.16 fixed point)
  /// </summary>
  TVideoRectCopyParams = record
    /// <summary>The first byte of the source screen (8 bit pixels)</summary>
    Source: PByte;
    /// <summary>The first byte (8 bit) or pixel (32 bit) of the destination screen</summary>
    Destination: Pointer;
    SourcePitch: Integer;
    DestinationPitch: Integer;
    SourceX: Integer;
    DestinationX: Integer;
    DestinationY: Integer;
    DestinationWidth: Integer;
    DestinationHeight: Integer;
    /// <summary>Position of the first source row, 16.16</summary>
    FracY: Integer;
    FracYStep: Integer;
    /// <summary>Step of the source column for the generic stretch, 16.16</summary>
    FracXStep: Integer;
    /// <summary>The thread: only the rows whose number mod IndexCount is Index are drawn (IndexCount 1: all)</summary>
    Index: Integer;
    IndexCount: Integer;
  end;

  /// <summary>
  ///   Static loops that copy a rectangle of an 8 bit screen to a screen of the same size
  ///   multiplied by an integer (expansion of each pixel), or to a screen of any size (stretch
  ///   with the nearest pixel). Plain pointers, no calls inside the loops
  /// </summary>
  TVideoRectCopy = class sealed
  public
    /// <summary>
    ///   Expands every pixel AFactor times (2, 4, 6, 8 or 12) into an 8 bit screen through two
    ///   tables of 256 patterns (a word and a long word); false (and nothing drawn) for another factor
    /// </summary>
    class function ExpandRows8(const AFactor: Integer; const AParams: TVideoRectCopyParams;
      const AToWord, AToLong: PLongWord): Boolean; static;
    /// <summary>The same for a 32 bit screen through the palette (factors 2, 4, 5, 6, 8 or 12)</summary>
    class function ExpandRows32(const AFactor: Integer; const AParams: TVideoRectCopyParams;
      const APalette: PLongWord): Boolean; static;
    /// <summary>Copies stretching the width to DestinationWidth (nearest pixel), 8 bit</summary>
    class procedure StretchRows8(const AParams: TVideoRectCopyParams); static;
    /// <summary>Copies stretching the width to DestinationWidth (nearest pixel), 32 bit through the palette</summary>
    class procedure StretchRows32(const AParams: TVideoRectCopyParams; const APalette: PLongWord); static;
    /// <summary>
    ///   As StretchRows8 but a pixel that is 0 leaves the destination as it is (a masked picture)
    /// </summary>
    class procedure StretchRowsTransparent8(const AParams: TVideoRectCopyParams); static;
    /// <summary>
    ///   Copies AHeight rows of AWidth pixels one to one, skipping the pixels that are 0; only the
    ///   rows whose countdown number (AHeight, AHeight - 1, ...) mod ACount is AIndex (ACount 1: all)
    /// </summary>
    class procedure CopyRowsTransparent8(const ASource, ADestination: PByte; const ASourcePitch,
      ADestinationPitch, AWidth, AHeight, AIndex, ACount: Integer); static;
    /// <summary>
    ///   As StretchRows32 but a pixel that is 0 leaves the destination as it is, and four source
    ///   pixels that are all 0 are skipped at once (the masked picture of a 32 bit screen)
    /// </summary>
    class procedure StretchRowsTransparent32(const AParams: TVideoRectCopyParams; const APalette: PLongWord); static;
  end;

implementation

const
  FRACBITS = 16;
  FRACUNIT = 1 shl FRACBITS;

type
  TTwoLongWords = record
    First: LongWord;
    Second: LongWord;
  end;

  PLongWordRow = ^TLongWordRow;
  TLongWordRow = array[0..255] of LongWord;

  PByteRow = ^TByteRow;
  TByteRow = array[0..MaxInt div 2 - 1] of Byte;

  PLongWordRow4 = ^TLongWordRow4;
  TLongWordRow4 = array[0..MaxInt div 8 - 1] of LongWord;

{ TVideoRectCopy }

class function TVideoRectCopy.ExpandRows8(const AFactor: Integer; const AParams: TVideoRectCopyParams;
  const AToWord, AToLong: PLongWord): Boolean;
var
  LRow: Integer;
  LCol: Integer;
  LDestinationWidth: Integer;
  LFracY: Integer;
  LDestination: PByte;
  LSource: PByte;
  LValue: Byte;
  LLong: LongWord;
begin
  Result := True;
  LDestinationWidth := AParams.DestinationWidth;
  LFracY := AParams.FracY;
  case AFactor of
    2:
      begin
        LDestinationWidth := LDestinationWidth div 2;
        for LRow := AParams.DestinationY to AParams.DestinationY + AParams.DestinationHeight - 1 do
        begin
          if (AParams.IndexCount = 1) or (LRow mod AParams.IndexCount = AParams.Index) then
          begin
            LDestination := PByte(NativeInt(AParams.Destination) + AParams.DestinationPitch * LRow + AParams.DestinationX);
            LSource := PByte(NativeInt(AParams.Source) + AParams.SourcePitch * (LFracY div FRACUNIT) + AParams.SourceX);
            LCol := 0;
            while LCol < LDestinationWidth do
            begin
              LValue := PByteRow(LSource)[LCol];
              PWord(LDestination)^ := Word(PLongWordRow(AToWord)[LValue]);
              Inc(LDestination, 2);
              Inc(LCol);
            end;
          end;
          LFracY := LFracY + AParams.FracYStep;
        end;
      end;
    4:
      begin
        LDestinationWidth := LDestinationWidth div 4;
        for LRow := AParams.DestinationY to AParams.DestinationY + AParams.DestinationHeight - 1 do
        begin
          if (AParams.IndexCount = 1) or (LRow mod AParams.IndexCount = AParams.Index) then
          begin
            LDestination := PByte(NativeInt(AParams.Destination) + AParams.DestinationPitch * LRow + AParams.DestinationX);
            LSource := PByte(NativeInt(AParams.Source) + AParams.SourcePitch * (LFracY div FRACUNIT) + AParams.SourceX);
            LCol := 0;
            while LCol < LDestinationWidth do
            begin
              LValue := PByteRow(LSource)[LCol];
              PLongWord(LDestination)^ := PLongWordRow(AToLong)[LValue];
              Inc(LDestination, 4);
              Inc(LCol);
            end;
          end;
          LFracY := LFracY + AParams.FracYStep;
        end;
      end;
    6:
      begin
        LDestinationWidth := LDestinationWidth div 6;
        for LRow := AParams.DestinationY to AParams.DestinationY + AParams.DestinationHeight - 1 do
        begin
          if (AParams.IndexCount = 1) or (LRow mod AParams.IndexCount = AParams.Index) then
          begin
            LDestination := PByte(NativeInt(AParams.Destination) + AParams.DestinationPitch * LRow + AParams.DestinationX);
            LSource := PByte(NativeInt(AParams.Source) + AParams.SourcePitch * (LFracY div FRACUNIT) + AParams.SourceX);
            LCol := 0;
            while LCol < LDestinationWidth do
            begin
              LValue := PByteRow(LSource)[LCol];
              PLongWord(LDestination)^ := PLongWordRow(AToLong)[LValue];
              Inc(LDestination, 4);
              PWord(LDestination)^ := Word(PLongWordRow(AToWord)[LValue]);
              Inc(LDestination, 2);
              Inc(LCol);
            end;
          end;
          LFracY := LFracY + AParams.FracYStep;
        end;
      end;
    8:
      begin
        LDestinationWidth := LDestinationWidth div 8;
        for LRow := AParams.DestinationY to AParams.DestinationY + AParams.DestinationHeight - 1 do
        begin
          if (AParams.IndexCount = 1) or (LRow mod AParams.IndexCount = AParams.Index) then
          begin
            LDestination := PByte(NativeInt(AParams.Destination) + AParams.DestinationPitch * LRow + AParams.DestinationX);
            LSource := PByte(NativeInt(AParams.Source) + AParams.SourcePitch * (LFracY div FRACUNIT) + AParams.SourceX);
            LCol := 0;
            while LCol < LDestinationWidth do
            begin
              LValue := PByteRow(LSource)[LCol];
              LLong := PLongWordRow(AToLong)[LValue];
              PLongWord(LDestination)^ := LLong;
              Inc(LDestination, 4);
              PLongWord(LDestination)^ := LLong;
              Inc(LDestination, 4);
              Inc(LCol);
            end;
          end;
          LFracY := LFracY + AParams.FracYStep;
        end;
      end;
    12:
      begin
        LDestinationWidth := LDestinationWidth div 12;
        for LRow := AParams.DestinationY to AParams.DestinationY + AParams.DestinationHeight - 1 do
        begin
          if (AParams.IndexCount = 1) or (LRow mod AParams.IndexCount = AParams.Index) then
          begin
            LDestination := PByte(NativeInt(AParams.Destination) + AParams.DestinationPitch * LRow + AParams.DestinationX);
            LSource := PByte(NativeInt(AParams.Source) + AParams.SourcePitch * (LFracY div FRACUNIT) + AParams.SourceX);
            LCol := 0;
            while LCol < LDestinationWidth do
            begin
              LValue := PByteRow(LSource)[LCol];
              LLong := PLongWordRow(AToLong)[LValue];
              PLongWord(LDestination)^ := LLong;
              Inc(LDestination, 4);
              PLongWord(LDestination)^ := LLong;
              Inc(LDestination, 4);
              PLongWord(LDestination)^ := LLong;
              Inc(LDestination, 4);
              Inc(LCol);
            end;
          end;
          LFracY := LFracY + AParams.FracYStep;
        end;
      end;
  else
    Result := False;
  end;
end;

class function TVideoRectCopy.ExpandRows32(const AFactor: Integer; const AParams: TVideoRectCopyParams;
  const APalette: PLongWord): Boolean;
var
  LRow: Integer;
  LCol: Integer;
  LDestinationWidth: Integer;
  LFracY: Integer;
  LDestination: PLongWord;
  LSource: PByte;
  LColor: LongWord;
  LPair: TTwoLongWords;
begin
  Result := True;
  LDestinationWidth := AParams.DestinationWidth;
  LFracY := AParams.FracY;
  case AFactor of
    2:
      begin
        LDestinationWidth := LDestinationWidth div 2;
        for LRow := AParams.DestinationY to AParams.DestinationY + AParams.DestinationHeight - 1 do
        begin
          if (AParams.IndexCount = 1) or (LRow mod AParams.IndexCount = AParams.Index) then
          begin
            LDestination := PLongWord(NativeInt(AParams.Destination) + (AParams.DestinationPitch * LRow + AParams.DestinationX) * SizeOf(LongWord));
            LSource := PByte(NativeInt(AParams.Source) + AParams.SourcePitch * (LFracY div FRACUNIT) + AParams.SourceX);
            LCol := 0;
            while LCol < LDestinationWidth do
            begin
              LColor := PLongWordRow(APalette)[PByteRow(LSource)[LCol]];
              LDestination^ := LColor;
              Inc(LDestination);
              LDestination^ := LColor;
              Inc(LDestination);
              Inc(LCol);
            end;
          end;
          LFracY := LFracY + AParams.FracYStep;
        end;
      end;
    4:
      begin
        LDestinationWidth := LDestinationWidth div 4;
        for LRow := AParams.DestinationY to AParams.DestinationY + AParams.DestinationHeight - 1 do
        begin
          if (AParams.IndexCount = 1) or (LRow mod AParams.IndexCount = AParams.Index) then
          begin
            LDestination := PLongWord(NativeInt(AParams.Destination) + (AParams.DestinationPitch * LRow + AParams.DestinationX) * SizeOf(LongWord));
            LSource := PByte(NativeInt(AParams.Source) + AParams.SourcePitch * (LFracY div FRACUNIT) + AParams.SourceX);
            LCol := 0;
            while LCol < LDestinationWidth do
            begin
              LPair.First := PLongWordRow(APalette)[PByteRow(LSource)[LCol]];
              LPair.Second := LPair.First;
              PInt64(LDestination)^ := PInt64(@LPair)^;
              Inc(LDestination, 2);
              PInt64(LDestination)^ := PInt64(@LPair)^;
              Inc(LDestination, 2);
              Inc(LCol);
            end;
          end;
          LFracY := LFracY + AParams.FracYStep;
        end;
      end;
    5:
      begin
        LDestinationWidth := LDestinationWidth div 5;
        for LRow := AParams.DestinationY to AParams.DestinationY + AParams.DestinationHeight - 1 do
        begin
          if (AParams.IndexCount = 1) or (LRow mod AParams.IndexCount = AParams.Index) then
          begin
            LDestination := PLongWord(NativeInt(AParams.Destination) + (AParams.DestinationPitch * LRow + AParams.DestinationX) * SizeOf(LongWord));
            LSource := PByte(NativeInt(AParams.Source) + AParams.SourcePitch * (LFracY div FRACUNIT) + AParams.SourceX);
            LCol := 0;
            while LCol < LDestinationWidth do
            begin
              LPair.First := PLongWordRow(APalette)[PByteRow(LSource)[LCol]];
              LPair.Second := LPair.First;
              PInt64(LDestination)^ := PInt64(@LPair)^;
              Inc(LDestination, 2);
              PInt64(LDestination)^ := PInt64(@LPair)^;
              Inc(LDestination, 2);
              LDestination^ := LPair.First;
              Inc(LDestination);
              Inc(LCol);
            end;
          end;
          LFracY := LFracY + AParams.FracYStep;
        end;
      end;
    6:
      begin
        LDestinationWidth := LDestinationWidth div 6;
        for LRow := AParams.DestinationY to AParams.DestinationY + AParams.DestinationHeight - 1 do
        begin
          if (AParams.IndexCount = 1) or (LRow mod AParams.IndexCount = AParams.Index) then
          begin
            LDestination := PLongWord(NativeInt(AParams.Destination) + (AParams.DestinationPitch * LRow + AParams.DestinationX) * SizeOf(LongWord));
            LSource := PByte(NativeInt(AParams.Source) + AParams.SourcePitch * (LFracY div FRACUNIT) + AParams.SourceX);
            LCol := 0;
            while LCol < LDestinationWidth do
            begin
              LPair.First := PLongWordRow(APalette)[PByteRow(LSource)[LCol]];
              LPair.Second := LPair.First;
              PInt64(LDestination)^ := PInt64(@LPair)^;
              Inc(LDestination, 2);
              PInt64(LDestination)^ := PInt64(@LPair)^;
              Inc(LDestination, 2);
              PInt64(LDestination)^ := PInt64(@LPair)^;
              Inc(LDestination, 2);
              Inc(LCol);
            end;
          end;
          LFracY := LFracY + AParams.FracYStep;
        end;
      end;
    8:
      begin
        LDestinationWidth := LDestinationWidth div 8;
        for LRow := AParams.DestinationY to AParams.DestinationY + AParams.DestinationHeight - 1 do
        begin
          if (AParams.IndexCount = 1) or (LRow mod AParams.IndexCount = AParams.Index) then
          begin
            LDestination := PLongWord(NativeInt(AParams.Destination) + (AParams.DestinationPitch * LRow + AParams.DestinationX) * SizeOf(LongWord));
            LSource := PByte(NativeInt(AParams.Source) + AParams.SourcePitch * (LFracY div FRACUNIT) + AParams.SourceX);
            LCol := 0;
            while LCol < LDestinationWidth do
            begin
              LPair.First := PLongWordRow(APalette)[PByteRow(LSource)[LCol]];
              LPair.Second := LPair.First;
              PInt64(LDestination)^ := PInt64(@LPair)^;
              Inc(LDestination, 2);
              PInt64(LDestination)^ := PInt64(@LPair)^;
              Inc(LDestination, 2);
              PInt64(LDestination)^ := PInt64(@LPair)^;
              Inc(LDestination, 2);
              PInt64(LDestination)^ := PInt64(@LPair)^;
              Inc(LDestination, 2);
              Inc(LCol);
            end;
          end;
          LFracY := LFracY + AParams.FracYStep;
        end;
      end;
    12:
      begin
        LDestinationWidth := LDestinationWidth div 12;
        for LRow := AParams.DestinationY to AParams.DestinationY + AParams.DestinationHeight - 1 do
        begin
          if (AParams.IndexCount = 1) or (LRow mod AParams.IndexCount = AParams.Index) then
          begin
            LDestination := PLongWord(NativeInt(AParams.Destination) + (AParams.DestinationPitch * LRow + AParams.DestinationX) * SizeOf(LongWord));
            LSource := PByte(NativeInt(AParams.Source) + AParams.SourcePitch * (LFracY div FRACUNIT) + AParams.SourceX);
            LCol := 0;
            while LCol < LDestinationWidth do
            begin
              LPair.First := PLongWordRow(APalette)[PByteRow(LSource)[LCol]];
              LPair.Second := LPair.First;
              PInt64(LDestination)^ := PInt64(@LPair)^;
              Inc(LDestination, 2);
              PInt64(LDestination)^ := PInt64(@LPair)^;
              Inc(LDestination, 2);
              PInt64(LDestination)^ := PInt64(@LPair)^;
              Inc(LDestination, 2);
              PInt64(LDestination)^ := PInt64(@LPair)^;
              Inc(LDestination, 2);
              PInt64(LDestination)^ := PInt64(@LPair)^;
              Inc(LDestination, 2);
              PInt64(LDestination)^ := PInt64(@LPair)^;
              Inc(LDestination, 2);
              Inc(LCol);
            end;
          end;
          LFracY := LFracY + AParams.FracYStep;
        end;
      end;
  else
    Result := False;
  end;
end;

class procedure TVideoRectCopy.StretchRows8(const AParams: TVideoRectCopyParams);
var
  LRow: Integer;
  LCol: Integer;
  LFracX: Integer;
  LFracY: Integer;
  LFracXStep: Integer;
  LDestination: PByte;
  LSource: PByte;
begin
  LFracXStep := AParams.FracXStep;
  LFracY := AParams.FracY;
  for LRow := AParams.DestinationY to AParams.DestinationY + AParams.DestinationHeight - 1 do
  begin
    if (AParams.IndexCount = 1) or (LRow mod AParams.IndexCount = AParams.Index) then
    begin
      LFracX := 0;
      LDestination := PByte(NativeInt(AParams.Destination) + AParams.DestinationPitch * LRow + AParams.DestinationX);
      LSource := PByte(NativeInt(AParams.Source) + AParams.SourcePitch * (LFracY div FRACUNIT) + AParams.SourceX);
      for LCol := 0 to AParams.DestinationWidth - 1 do
      begin
        LDestination^ := PByteRow(LSource)[LongWord(LFracX) shr FRACBITS];
        Inc(LDestination);
        LFracX := LFracX + LFracXStep;
      end;
    end;
    LFracY := LFracY + AParams.FracYStep;
  end;
end;

class procedure TVideoRectCopy.StretchRows32(const AParams: TVideoRectCopyParams; const APalette: PLongWord);
var
  LRow: Integer;
  LCol: Integer;
  LFracX: Integer;
  LFracY: Integer;
  LFracXStep: Integer;
  LDestination: PLongWord;
  LSource: PByte;
begin
  LFracXStep := AParams.FracXStep;
  LFracY := AParams.FracY;
  for LRow := AParams.DestinationY to AParams.DestinationY + AParams.DestinationHeight - 1 do
  begin
    if (AParams.IndexCount = 1) or (LRow mod AParams.IndexCount = AParams.Index) then
    begin
      LFracX := 0;
      LDestination := PLongWord(NativeInt(AParams.Destination) + (AParams.DestinationPitch * LRow + AParams.DestinationX) * SizeOf(LongWord));
      LSource := PByte(NativeInt(AParams.Source) + AParams.SourcePitch * (LFracY div FRACUNIT) + AParams.SourceX);
      for LCol := 0 to AParams.DestinationWidth - 1 do
      begin
        LDestination^ := PLongWordRow(APalette)[PByteRow(LSource)[LongWord(LFracX) shr FRACBITS]];
        Inc(LDestination);
        LFracX := LFracX + LFracXStep;
      end;
    end;
    LFracY := LFracY + AParams.FracYStep;
  end;
end;
class procedure TVideoRectCopy.StretchRowsTransparent8(const AParams: TVideoRectCopyParams);
var
  LRow: Integer;
  LCol: Integer;
  LFracX: Integer;
  LFracY: Integer;
  LFracXStep: Integer;
  LDestination: PByteRow;
  LSource: PByteRow;
  LPixel: Byte;
begin
  LFracXStep := AParams.FracXStep;
  LFracY := AParams.FracY;
  for LRow := AParams.DestinationY to AParams.DestinationY + AParams.DestinationHeight - 1 do
  begin
    if (AParams.IndexCount = 1) or (LRow mod AParams.IndexCount = AParams.Index) then
    begin
      LFracX := 0;
      LDestination := PByteRow(NativeInt(AParams.Destination) + AParams.DestinationPitch * LRow + AParams.DestinationX);
      LSource := PByteRow(NativeInt(AParams.Source) + AParams.SourcePitch * (LFracY div FRACUNIT) + AParams.SourceX);
      for LCol := 0 to AParams.DestinationWidth - 1 do
      begin
        LPixel := LSource[LongWord(LFracX) shr FRACBITS];
        if LPixel <> 0 then
          LDestination[LCol] := LPixel;
        LFracX := LFracX + LFracXStep;
      end;
    end;
    LFracY := LFracY + AParams.FracYStep;
  end;
end;

class procedure TVideoRectCopy.CopyRowsTransparent8(const ASource, ADestination: PByte; const ASourcePitch,
  ADestinationPitch, AWidth, AHeight, AIndex, ACount: Integer);
var
  LCol: Integer;
  LHeight: Integer;
  LSource: PByteRow;
  LDestination: PByteRow;
  LPixel: Byte;
begin
  LSource := PByteRow(ASource);
  LDestination := PByteRow(ADestination);
  LHeight := AHeight;
  while LHeight > 0 do
  begin
    if (ACount = 1) or (LHeight mod ACount = AIndex) then
    begin
      for LCol := 0 to AWidth - 1 do
      begin
        LPixel := LSource[LCol];
        if LPixel <> 0 then
          LDestination[LCol] := LPixel;
      end;
    end;
    LSource := PByteRow(NativeInt(LSource) + ASourcePitch);
    LDestination := PByteRow(NativeInt(LDestination) + ADestinationPitch);
    Dec(LHeight);
  end;
end;

class procedure TVideoRectCopy.StretchRowsTransparent32(const AParams: TVideoRectCopyParams;
  const APalette: PLongWord);
var
  LRow: Integer;
  LCol: Integer;
  LFracX: Integer;
  LFracY: Integer;
  LFracXStep: Integer;
  LFracXStep4: Integer;
  LWidth: Integer;
  LTail: Integer;
  LDestination: PLongWordRow4;
  LSource: PByteRow;
  LPixel: Byte;
  LGroup: PLongWord;
begin
  LTail := AParams.DestinationWidth and $3;
  LWidth := AParams.DestinationWidth - LTail;
  LFracXStep4 := 4 * AParams.FracXStep;
  LFracXStep := AParams.FracXStep;
  LFracY := AParams.FracY;
  for LRow := AParams.DestinationY to AParams.DestinationY + AParams.DestinationHeight - 1 do
  begin
    if (AParams.IndexCount = 1) or (LRow mod AParams.IndexCount = AParams.Index) then
    begin
      LFracX := 0;
      LDestination := PLongWordRow4(NativeInt(AParams.Destination) +
        (AParams.DestinationPitch * LRow + AParams.DestinationX) * SizeOf(LongWord));
      LSource := PByteRow(NativeInt(AParams.Source) + AParams.SourcePitch * (LFracY div FRACUNIT) + AParams.SourceX);
      LCol := 0;
      while LCol < LWidth do
      begin
        LGroup := PLongWord(@LSource[LongWord(LFracX) shr FRACBITS]);
        if LGroup^ = 0 then
        begin
          Inc(LCol, 4);
          LFracX := LFracX + LFracXStep4;
        end
        else
        begin
          LPixel := PByte(LGroup)^;
          if LPixel <> 0 then
            LDestination[LCol] := PLongWordRow(APalette)[LPixel];
          Inc(LCol);
          LFracX := LFracX + LFracXStep;
        end;
      end;

      for LCol := LWidth to LWidth + LTail - 1 do
      begin
        LPixel := LSource[LongWord(LFracX) shr FRACBITS];
        if LPixel <> 0 then
          LDestination[LCol] := PLongWordRow(APalette)[LPixel];
        LFracX := LFracX + LFracXStep;
      end;
    end;
    LFracY := LFracY + AParams.FracYStep;
  end;
end;
end.
