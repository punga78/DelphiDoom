{******************************************************************************}
{                                                                              }
{  DelphiDoom: sound decoder - Vorbis, a codebook                              }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{  Derived from libvorbis by the Xiph.Org Foundation (BSD licence)             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Sound.Vorbis.Codebook;

interface

uses
  System.SysUtils, DelphiDoom.Ogg.Types;

{$POINTERMATH ON}

type
  /// <summary>
  ///   A Huffman codebook of a Vorbis stream: read from the setup header, then
  ///   prepared for decoding. Entries are looked up the way libvorbis does it
  ///   (a table for the short codes, a bisection for the long ones), so that a
  ///   damaged stream ends where libvorbis ends
  /// </summary>
  TVorbisCodebook = class
  private
    FDim: Integer;
    FEntries: Integer;
    FMapType: Integer;
    FLengthList: TArray<Integer>;
    FQMin: Integer;
    FQDelta: Integer;
    FQQuant: Integer;
    FQSequenceP: Integer;
    FQuantList: TArray<Integer>;
    FUsedEntries: Integer;
    FValueList: TArray<Single>;
    FCodeList: TArray<Cardinal>;
    FDecIndex: TArray<Integer>;
    FDecCodeLengths: TArray<Integer>;
    FDecFirstTable: TArray<Cardinal>;
    FDecFirstTableLength: Integer;
    FDecMaxLength: Integer;
    class function BitReverse(AValue: Cardinal): Cardinal; static;
    class function Float32Unpack(AValue: Integer): Single; static;
    class function MakeWords(const ALengths: TArray<Integer>; ACount, ASparseCount: Integer): TArray<Cardinal>; static;
    function Maptype1QuantValues: Integer;
    function Unquantize(ACount: Integer; const ASparseMap: TArray<Integer>): TArray<Single>;
    function DecodePackedEntry(const AOpb: POggPackBuffer): Integer;
  public
    /// <summary>
    ///   Reads a codebook from the packet of the setup header; nil when it is
    ///   damaged
    /// </summary>
    class function Unpack(const AOpb: POggPackBuffer): TVorbisCodebook; static;
    /// <summary>Builds the tables for decoding; False when the code is not a valid prefix code</summary>
    function BuildDecoder: Boolean;
    /// <summary>The entry the next code stands for, or -1 at the end of the packet</summary>
    function Decode(const AOpb: POggPackBuffer): Integer;
    /// <summary>Adds the vectors of N values read, de-interleaved by the step of the codebook; -1 at the end</summary>
    function DecodeVectorsStep(AData: PSingle; const AOpb: POggPackBuffer; ACount: Integer): Integer;
    /// <summary>Adds the vectors of N values read one after the other; -1 at the end</summary>
    function DecodeVectors(AData: PSingle; const AOpb: POggPackBuffer; ACount: Integer): Integer;
    /// <summary>Adds the values read to the channels in turn, from AOffset / AChannels on; -1 at the end</summary>
    function DecodeInterleaved(const AData: array of PSingle; AOffset, AChannels: Integer;
      const AOpb: POggPackBuffer; ACount: Integer): Integer;
    property Dim: Integer read FDim;
    property Entries: Integer read FEntries;
    property MapType: Integer read FMapType;
  end;

implementation

uses
  System.Math, System.Generics.Collections, System.Generics.Defaults,
  DelphiDoom.Ogg.BitPacker, DelphiDoom.Sound.Vorbis.Types;

const
  VQ_FEXP_BIAS = 768;
  VQ_FMAN = 21;

type
  TWordIndex = record
    Code: Cardinal;
    Position: Integer;
  end;

{ TVorbisCodebook }

class function TVorbisCodebook.BitReverse(AValue: Cardinal): Cardinal;
begin
  AValue := ((AValue shr 16) and $0000FFFF) or ((AValue shl 16) and $FFFF0000);
  AValue := ((AValue shr 8) and $00FF00FF) or ((AValue shl 8) and $FF00FF00);
  AValue := ((AValue shr 4) and $0F0F0F0F) or ((AValue shl 4) and $F0F0F0F0);
  AValue := ((AValue shr 2) and $33333333) or ((AValue shl 2) and $CCCCCCCC);
  Result := ((AValue shr 1) and $55555555) or ((AValue shl 1) and $AAAAAAAA);
end;

class function TVorbisCodebook.Float32Unpack(AValue: Integer): Single;
var
  LMantissa: Double;
  LSign: Boolean;
  LExponent: Integer;
begin
  LMantissa := AValue and $1FFFFF;
  LSign := (Cardinal(AValue) and $80000000) <> 0;
  LExponent := Integer((Cardinal(AValue) and $7FE00000) shr VQ_FMAN);
  if LSign then
    LMantissa := -LMantissa;
  LExponent := LExponent - (VQ_FMAN - 1) - VQ_FEXP_BIAS;
  if LExponent > 63 then
    LExponent := 63;
  if LExponent < -63 then
    LExponent := -63;
  Result := Ldexp(LMantissa, LExponent);
end;

class function TVorbisCodebook.MakeWords(const ALengths: TArray<Integer>; ACount,
  ASparseCount: Integer): TArray<Cardinal>;
var
  LMarker: array[0..32] of Cardinal;
  LI, LJ, LCount, LLength, LAllocated: Integer;
  LEntry, LTemp: Cardinal;
  LResult: TArray<Cardinal>;
begin
  LCount := 0;
  if ASparseCount <> 0 then
    LAllocated := ASparseCount
  else
    LAllocated := ACount;
  SetLength(LResult, LAllocated);
  FillChar(LMarker, SizeOf(LMarker), 0);

  for LI := 0 to ACount - 1 do
  begin
    LLength := ALengths[LI];
    if LLength > 0 then
    begin
      LEntry := LMarker[LLength];

      // an overpopulated tree
      if (LLength < 32) and ((LEntry shr LLength) <> 0) then
        Exit(nil);
      LResult[LCount] := LEntry;
      Inc(LCount);

      LJ := LLength;
      while LJ > 0 do
      begin
        if (LMarker[LJ] and 1) <> 0 then
        begin
          if LJ = 1 then
            Inc(LMarker[1])
          else
            LMarker[LJ] := LMarker[LJ - 1] shl 1;
          Break;
        end;
        Inc(LMarker[LJ]);
        Dec(LJ);
      end;

      for LJ := LLength + 1 to 32 do
        if (LMarker[LJ] shr 1) = LEntry then
        begin
          LEntry := LMarker[LJ];
          LMarker[LJ] := LMarker[LJ - 1] shl 1;
        end
        else
          Break;
    end
    else if ASparseCount = 0 then
      Inc(LCount);
  end;

  // an underpopulated tree is refused, but for the single entry codebook
  if not ((LCount = 1) and (LMarker[2] = 2)) then
    for LI := 1 to 32 do
      if (LMarker[LI] and ($FFFFFFFF shr (32 - LI))) <> 0 then
        Exit(nil);

  // the packer reads the least significant bit first
  LCount := 0;
  for LI := 0 to ACount - 1 do
  begin
    LTemp := 0;
    for LJ := 0 to ALengths[LI] - 1 do
    begin
      LTemp := LTemp shl 1;
      LTemp := LTemp or ((LResult[LCount] shr LJ) and 1);
    end;
    if ASparseCount <> 0 then
    begin
      if ALengths[LI] <> 0 then
      begin
        LResult[LCount] := LTemp;
        Inc(LCount);
      end;
    end
    else
    begin
      LResult[LCount] := LTemp;
      Inc(LCount);
    end;
  end;
  Result := LResult;
end;

function TVorbisCodebook.Maptype1QuantValues: Integer;
var
  LValues, LAcc, LAcc1: Int64;
  LI: Integer;
begin
  if FEntries < 1 then
    Exit(0);
  LValues := Trunc(Power(Single(FEntries), Single(1.0) / FDim));
  if LValues < 1 then
    LValues := 1;
  while True do
  begin
    LAcc := 1;
    LAcc1 := 1;
    LI := 0;
    while LI < FDim do
    begin
      if (FEntries div LValues) < LAcc then
        Break;
      LAcc := LAcc * LValues;
      if (High(Integer) div (LValues + 1)) < LAcc1 then
        LAcc1 := High(Integer)
      else
        LAcc1 := LAcc1 * (LValues + 1);
      Inc(LI);
    end;
    if (LI >= FDim) and (LAcc <= FEntries) and (LAcc1 > FEntries) then
      Exit(Integer(LValues));
    if (LI < FDim) or (LAcc > FEntries) then
      Dec(LValues)
    else
      Inc(LValues);
  end;
end;

function TVorbisCodebook.Unquantize(ACount: Integer;
  const ASparseMap: TArray<Integer>): TArray<Single>;
var
  LJ, LK, LCount, LQuantValues, LIndexDiv, LIndex: Integer;
  LMinDelta, LDelta, LLast, LValue: Single;
  LSparse: Boolean;
begin
  Result := nil;
  if (FMapType <> 1) and (FMapType <> 2) then
    Exit;
  LSparse := ASparseMap <> nil;
  LMinDelta := Float32Unpack(FQMin);
  LDelta := Float32Unpack(FQDelta);
  SetLength(Result, ACount * FDim);
  LCount := 0;
  if FMapType = 1 then
  begin
    LQuantValues := Maptype1QuantValues;
    for LJ := 0 to FEntries - 1 do
      if (LSparse and (FLengthList[LJ] <> 0)) or not LSparse then
      begin
        LLast := 0;
        LIndexDiv := 1;
        for LK := 0 to FDim - 1 do
        begin
          LIndex := (LJ div LIndexDiv) mod LQuantValues;
          LValue := FQuantList[LIndex];
          LValue := Abs(Double(LValue)) * LDelta + LMinDelta + LLast;
          if FQSequenceP <> 0 then
            LLast := LValue;
          if LSparse then
            Result[ASparseMap[LCount] * FDim + LK] := LValue
          else
            Result[LCount * FDim + LK] := LValue;
          LIndexDiv := LIndexDiv * LQuantValues;
        end;
        Inc(LCount);
      end;
  end
  else
    for LJ := 0 to FEntries - 1 do
      if (LSparse and (FLengthList[LJ] <> 0)) or not LSparse then
      begin
        LLast := 0;
        for LK := 0 to FDim - 1 do
        begin
          LValue := FQuantList[LJ * FDim + LK];
          LValue := Abs(Double(LValue)) * LDelta + LMinDelta + LLast;
          if FQSequenceP <> 0 then
            LLast := LValue;
          if LSparse then
            Result[ASparseMap[LCount] * FDim + LK] := LValue
          else
            Result[LCount * FDim + LK] := LValue;
        end;
        Inc(LCount);
      end;
end;

class function TVorbisCodebook.Unpack(const AOpb: POggPackBuffer): TVorbisCodebook;
var
  LBook: TVorbisCodebook;
  LI, LJ, LNumber, LLength, LQuantValues: Integer;
  LUnused: Boolean;

  function Fail: TVorbisCodebook;
  begin
    LBook.Free;
    Result := nil;
  end;

begin
  LBook := TVorbisCodebook.Create;

  if TOggBitPacker.Read(AOpb, 24) <> $564342 then
    Exit(Fail);

  LBook.FDim := TOggBitPacker.Read(AOpb, 16);
  LBook.FEntries := TOggBitPacker.Read(AOpb, 24);
  if LBook.FEntries = -1 then
    Exit(Fail);

  if OvIlog(Cardinal(LBook.FDim)) + OvIlog(Cardinal(LBook.FEntries)) > 24 then
    Exit(Fail);

  case TOggBitPacker.Read(AOpb, 1) of
    0:
      begin
        LUnused := TOggBitPacker.Read(AOpb, 1) <> 0;
        if LUnused then
          LNumber := 1
        else
          LNumber := 5;
        if ((Int64(LBook.FEntries) * LNumber + 7) shr 3) > AOpb.Storage - TOggBitPacker.Bytes(AOpb) then
          Exit(Fail);
        SetLength(LBook.FLengthList, LBook.FEntries);
        if LUnused then
        begin
          for LI := 0 to LBook.FEntries - 1 do
            if TOggBitPacker.Read(AOpb, 1) <> 0 then
            begin
              LNumber := TOggBitPacker.Read(AOpb, 5);
              if LNumber = -1 then
                Exit(Fail);
              LBook.FLengthList[LI] := LNumber + 1;
            end
            else
              LBook.FLengthList[LI] := 0;
        end
        else
          for LI := 0 to LBook.FEntries - 1 do
          begin
            LNumber := TOggBitPacker.Read(AOpb, 5);
            if LNumber = -1 then
              Exit(Fail);
            LBook.FLengthList[LI] := LNumber + 1;
          end;
      end;
    1:
      begin
        LLength := TOggBitPacker.Read(AOpb, 5) + 1;
        if LLength = 0 then
          Exit(Fail);
        SetLength(LBook.FLengthList, LBook.FEntries);
        LI := 0;
        while LI < LBook.FEntries do
        begin
          LNumber := TOggBitPacker.Read(AOpb, OvIlog(Cardinal(LBook.FEntries - LI)));
          if LNumber = -1 then
            Exit(Fail);
          if (LLength > 32) or (LNumber > LBook.FEntries - LI) or
             ((LNumber > 0) and (((LNumber - 1) shr (LLength - 1)) > 1)) then
            Exit(Fail);
          for LJ := 0 to LNumber - 1 do
          begin
            LBook.FLengthList[LI] := LLength;
            Inc(LI);
          end;
          Inc(LLength);
        end;
      end;
  else
    Exit(Fail);
  end;

  LBook.FMapType := TOggBitPacker.Read(AOpb, 4);
  case LBook.FMapType of
    0:
      ;
    1, 2:
      begin
        LBook.FQMin := TOggBitPacker.Read(AOpb, 32);
        LBook.FQDelta := TOggBitPacker.Read(AOpb, 32);
        LBook.FQQuant := TOggBitPacker.Read(AOpb, 4) + 1;
        LBook.FQSequenceP := TOggBitPacker.Read(AOpb, 1);
        if LBook.FQSequenceP = -1 then
          Exit(Fail);

        LQuantValues := 0;
        if LBook.FMapType = 1 then
        begin
          if LBook.FDim <> 0 then
            LQuantValues := LBook.Maptype1QuantValues;
        end
        else
          LQuantValues := LBook.FEntries * LBook.FDim;

        if ((Int64(LQuantValues) * LBook.FQQuant + 7) shr 3) > AOpb.Storage - TOggBitPacker.Bytes(AOpb) then
          Exit(Fail);
        SetLength(LBook.FQuantList, LQuantValues);
        for LI := 0 to LQuantValues - 1 do
          LBook.FQuantList[LI] := TOggBitPacker.Read(AOpb, LBook.FQQuant);
        if (LQuantValues <> 0) and (LBook.FQuantList[LQuantValues - 1] = -1) then
          Exit(Fail);
      end;
  else
    Exit(Fail);
  end;

  Result := LBook;
end;

function TVorbisCodebook.BuildDecoder: Boolean;
var
  LI, LJ, LUsed, LTableSize, LLo, LHi, LPosition: Integer;
  LCodes: TArray<Cardinal>;
  LOrder: TArray<TWordIndex>;
  LSortIndex: TArray<Integer>;
  LOriginal, LMask, LWord: Cardinal;
  LLoValue, LHiValue: Cardinal;
begin
  Result := True;
  LUsed := 0;
  for LI := 0 to FEntries - 1 do
    if FLengthList[LI] > 0 then
      Inc(LUsed);
  FUsedEntries := LUsed;
  if LUsed = 0 then
    Exit;

  LCodes := MakeWords(FLengthList, FEntries, FUsedEntries);
  if LCodes = nil then
    Exit(False);

  SetLength(LOrder, LUsed);
  for LI := 0 to LUsed - 1 do
  begin
    LCodes[LI] := BitReverse(LCodes[LI]);
    LOrder[LI].Code := LCodes[LI];
    LOrder[LI].Position := LI;
  end;
  TArray.Sort<TWordIndex>(LOrder, TComparer<TWordIndex>.Construct(
    function(const ALeft, ARight: TWordIndex): Integer
    begin
      if ALeft.Code > ARight.Code then
        Result := 1
      else if ALeft.Code < ARight.Code then
        Result := -1
      else
        Result := 0;
    end));

  SetLength(LSortIndex, LUsed);
  for LI := 0 to LUsed - 1 do
    LSortIndex[LOrder[LI].Position] := LI;

  SetLength(FCodeList, LUsed);
  for LI := 0 to LUsed - 1 do
    FCodeList[LSortIndex[LI]] := LCodes[LI];

  FValueList := Unquantize(LUsed, LSortIndex);

  SetLength(FDecIndex, LUsed);
  LJ := 0;
  for LI := 0 to FEntries - 1 do
    if FLengthList[LI] > 0 then
    begin
      FDecIndex[LSortIndex[LJ]] := LI;
      Inc(LJ);
    end;

  SetLength(FDecCodeLengths, LUsed);
  FDecMaxLength := 0;
  LJ := 0;
  for LI := 0 to FEntries - 1 do
    if FLengthList[LI] > 0 then
    begin
      FDecCodeLengths[LSortIndex[LJ]] := FLengthList[LI];
      Inc(LJ);
      if FLengthList[LI] > FDecMaxLength then
        FDecMaxLength := FLengthList[LI];
    end;

  if (LUsed = 1) and (FDecMaxLength = 1) then
  begin
    // the single entry codebook: a one bit table that always says entry 0
    FDecFirstTableLength := 1;
    SetLength(FDecFirstTable, 2);
    FDecFirstTable[0] := 1;
    FDecFirstTable[1] := 1;
    Exit;
  end;

  FDecFirstTableLength := OvIlog(FUsedEntries) - 4;
  if FDecFirstTableLength < 5 then
    FDecFirstTableLength := 5;
  if FDecFirstTableLength > 8 then
    FDecFirstTableLength := 8;

  LTableSize := 1 shl FDecFirstTableLength;
  SetLength(FDecFirstTable, LTableSize);
  FillChar(FDecFirstTable[0], LTableSize * SizeOf(Cardinal), 0);

  for LI := 0 to LUsed - 1 do
    if FDecCodeLengths[LI] <= FDecFirstTableLength then
    begin
      LOriginal := BitReverse(FCodeList[LI]);
      for LJ := 0 to (1 shl (FDecFirstTableLength - FDecCodeLengths[LI])) - 1 do
        FDecFirstTable[LOriginal or (Cardinal(LJ) shl FDecCodeLengths[LI])] := LI + 1;
    end;

  // the entries of the table left over are hints for the search
  LMask := Cardinal($FFFFFFFE) shl (31 - FDecFirstTableLength);
  LLo := 0;
  LHi := 0;
  for LI := 0 to LTableSize - 1 do
  begin
    LWord := Cardinal(LI) shl (32 - FDecFirstTableLength);
    LPosition := Integer(BitReverse(LWord));
    if FDecFirstTable[LPosition] = 0 then
    begin
      while ((LLo + 1) < LUsed) and (FCodeList[LLo + 1] <= LWord) do
        Inc(LLo);
      while (LHi < LUsed) and (LWord >= (FCodeList[LHi] and LMask)) do
        Inc(LHi);

      // 15 bits for each hint: past that it is slower but still right
      LLoValue := LLo;
      LHiValue := LUsed - LHi;
      if LLoValue > $7FFF then
        LLoValue := $7FFF;
      if LHiValue > $7FFF then
        LHiValue := $7FFF;
      FDecFirstTable[LPosition] := $80000000 or (LLoValue shl 15) or LHiValue;
    end;
  end;
end;

function TVorbisCodebook.DecodePackedEntry(const AOpb: POggPackBuffer): Integer;
var
  LRead, LLo, LHi, LLook, LP, LTest: Integer;
  LEntry, LTestWord: Cardinal;
begin
  LRead := FDecMaxLength;
  LLook := TOggBitPacker.Look(AOpb, FDecFirstTableLength);

  if LLook >= 0 then
  begin
    LEntry := FDecFirstTable[LLook];
    if (LEntry and $80000000) <> 0 then
    begin
      LLo := (LEntry shr 15) and $7FFF;
      LHi := FUsedEntries - Integer(LEntry and $7FFF);
    end
    else
    begin
      TOggBitPacker.Advance(AOpb, FDecCodeLengths[LEntry - 1]);
      Exit(Integer(LEntry) - 1);
    end;
  end
  else
  begin
    LLo := 0;
    LHi := FUsedEntries;
  end;

  LLook := TOggBitPacker.Look(AOpb, LRead);
  while (LLook < 0) and (LRead > 1) do
  begin
    Dec(LRead);
    LLook := TOggBitPacker.Look(AOpb, LRead);
  end;
  if LLook < 0 then
    Exit(-1);

  // bisection in the ordered list of the codewords
  LTestWord := BitReverse(Cardinal(LLook));
  while LHi - LLo > 1 do
  begin
    LP := (LHi - LLo) shr 1;
    if FCodeList[LLo + LP] > LTestWord then
      LTest := 1
    else
      LTest := 0;
    LLo := LLo + (LP and (LTest - 1));
    LHi := LHi - (LP and (-LTest));
  end;

  if FDecCodeLengths[LLo] <= LRead then
  begin
    TOggBitPacker.Advance(AOpb, FDecCodeLengths[LLo]);
    Exit(LLo);
  end;

  TOggBitPacker.Advance(AOpb, LRead);
  Result := -1;
end;

function TVorbisCodebook.Decode(const AOpb: POggPackBuffer): Integer;
var
  LPacked: Integer;
begin
  if FUsedEntries > 0 then
  begin
    LPacked := DecodePackedEntry(AOpb);
    if LPacked >= 0 then
      Exit(FDecIndex[LPacked]);
  end;
  Result := -1;
end;

function TVorbisCodebook.DecodeVectorsStep(AData: PSingle;
  const AOpb: POggPackBuffer; ACount: Integer): Integer;
var
  LStep, LI, LJ, LO: Integer;
  LEntries: TArray<Integer>;
begin
  if FUsedEntries > 0 then
  begin
    LStep := ACount div FDim;
    SetLength(LEntries, LStep);
    for LI := 0 to LStep - 1 do
    begin
      LEntries[LI] := DecodePackedEntry(AOpb);
      if LEntries[LI] = -1 then
        Exit(-1);
    end;
    LO := 0;
    for LI := 0 to FDim - 1 do
    begin
      LJ := 0;
      while (LO + LJ < ACount) and (LJ < LStep) do
      begin
        AData[LO + LJ] := AData[LO + LJ] + FValueList[LEntries[LJ] * FDim + LI];
        Inc(LJ);
      end;
      Inc(LO, LStep);
    end;
  end;
  Result := 0;
end;

function TVorbisCodebook.DecodeVectors(AData: PSingle;
  const AOpb: POggPackBuffer; ACount: Integer): Integer;
var
  LI, LJ, LEntry: Integer;
begin
  if FUsedEntries > 0 then
  begin
    LI := 0;
    while LI < ACount do
    begin
      LEntry := DecodePackedEntry(AOpb);
      if LEntry = -1 then
        Exit(-1);
      LJ := 0;
      while (LI < ACount) and (LJ < FDim) do
      begin
        AData[LI] := AData[LI] + FValueList[LEntry * FDim + LJ];
        Inc(LI);
        Inc(LJ);
      end;
    end;
  end;
  Result := 0;
end;

function TVorbisCodebook.DecodeInterleaved(const AData: array of PSingle;
  AOffset, AChannels: Integer; const AOpb: POggPackBuffer; ACount: Integer): Integer;
var
  LI, LJ, LM, LEntry, LChannel: Integer;
begin
  if FUsedEntries > 0 then
  begin
    LChannel := 0;
    LM := (AOffset + ACount) div AChannels;
    LI := AOffset div AChannels;
    while LI < LM do
    begin
      LEntry := DecodePackedEntry(AOpb);
      if LEntry = -1 then
        Exit(-1);
      LJ := 0;
      while (LI < LM) and (LJ < FDim) do
      begin
        AData[LChannel][LI] := AData[LChannel][LI] + FValueList[LEntry * FDim + LJ];
        Inc(LChannel);
        if LChannel = AChannels then
        begin
          LChannel := 0;
          Inc(LI);
        end;
        Inc(LJ);
      end;
    end;
  end;
  Result := 0;
end;

end.
