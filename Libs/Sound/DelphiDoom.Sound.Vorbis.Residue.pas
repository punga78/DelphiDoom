{******************************************************************************}
{                                                                              }
{  DelphiDoom: sound decoder - Vorbis, the residue (types 0, 1 and 2)          }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{  Derived from libvorbis by the Xiph.Org Foundation (BSD licence)             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Sound.Vorbis.Residue;

interface

uses
  System.SysUtils, DelphiDoom.Ogg.Types, DelphiDoom.Sound.Vorbis.Types,
  DelphiDoom.Sound.Vorbis.Codebook;

{$POINTERMATH ON}

type
  /// <summary>
  ///   What is left of the spectrum once the floor is taken out, coded in
  ///   partitions with the codebooks of the setup. The three types differ in
  ///   how the vectors of a codebook are laid over the channels
  /// </summary>
  TVorbisResidue = class
  private
    FKind: Integer;
    FBegin: Integer;
    FEnd: Integer;
    FGrouping: Integer;
    FPartitions: Integer;
    FGroupBook: Integer;
    FSecondStages: array[0..63] of Integer;
    FBookList: array[0..511] of Integer;
    FPartVals: Integer;
    FStages: Integer;
    FPhraseBook: TVorbisCodebook;
    FPartBooks: TArray<TArray<TVorbisCodebook>>;
    FDecodeMap: TArray<TArray<Integer>>;
    class function CountBits(AValue: Cardinal): Integer; static;
    procedure InverseTypes01(const AOpb: POggPackBuffer; APcmEnd: Integer;
      const AIn: array of PSingle; AChannels: Integer);
    procedure InverseType2(const AOpb: POggPackBuffer; APcmEnd: Integer;
      const AIn: array of PSingle; const ANonZero: array of Boolean; AChannels: Integer);
  public
    /// <summary>
    ///   Reads a residue of AKind (0, 1 or 2) from the setup header; nil when
    ///   it is damaged. The codebooks are those read before it
    /// </summary>
    class function Unpack(const AOpb: POggPackBuffer; AKind: Integer;
      const ABooks: TArray<TVorbisCodebook>): TVorbisResidue; static;
    /// <summary>Ties the residue to the codebooks once they are ready for decoding</summary>
    procedure Look(const ABooks: TArray<TVorbisCodebook>);
    /// <summary>
    ///   Adds the residue of the packet to the spectra in AIn (each of
    ///   APcmEnd / 2 values); the channels that ANonZero marks as silent get
    ///   nothing. A packet that ends early just stops the work
    /// </summary>
    procedure Inverse(const AOpb: POggPackBuffer; APcmEnd: Integer;
      const AIn: array of PSingle; const ANonZero: array of Boolean; AChannels: Integer);
  end;

implementation

uses
  DelphiDoom.Ogg.BitPacker;

{ TVorbisResidue }

class function TVorbisResidue.CountBits(AValue: Cardinal): Integer;
begin
  Result := 0;
  while AValue <> 0 do
  begin
    Inc(Result, Integer(AValue and 1));
    AValue := AValue shr 1;
  end;
end;

class function TVorbisResidue.Unpack(const AOpb: POggPackBuffer; AKind: Integer;
  const ABooks: TArray<TVorbisCodebook>): TVorbisResidue;
var
  LResidue: TVorbisResidue;
  LJ, LAcc, LCascade, LFlag, LC, LBook, LEntries, LDim, LPartVals: Integer;

  function Fail: TVorbisResidue;
  begin
    LResidue.Free;
    Result := nil;
  end;

begin
  LResidue := TVorbisResidue.Create;
  LResidue.FKind := AKind;
  LAcc := 0;

  LResidue.FBegin := TOggBitPacker.Read(AOpb, 24);
  LResidue.FEnd := TOggBitPacker.Read(AOpb, 24);
  LResidue.FGrouping := TOggBitPacker.Read(AOpb, 24) + 1;
  LResidue.FPartitions := TOggBitPacker.Read(AOpb, 6) + 1;
  LResidue.FGroupBook := TOggBitPacker.Read(AOpb, 8);

  if LResidue.FGroupBook < 0 then
    Exit(Fail);
  // the packet ended: libvorbis would divide by these
  if (LResidue.FGrouping < 1) or (LResidue.FPartitions < 1) then
    Exit(Fail);

  for LJ := 0 to LResidue.FPartitions - 1 do
  begin
    LCascade := TOggBitPacker.Read(AOpb, 3);
    LFlag := TOggBitPacker.Read(AOpb, 1);
    if LFlag < 0 then
      Exit(Fail);
    if LFlag <> 0 then
    begin
      LC := TOggBitPacker.Read(AOpb, 5);
      if LC < 0 then
        Exit(Fail);
      LCascade := LCascade or (LC shl 3);
    end;
    LResidue.FSecondStages[LJ] := LCascade;
    Inc(LAcc, CountBits(Cardinal(LCascade)));
  end;
  for LJ := 0 to LAcc - 1 do
  begin
    LBook := TOggBitPacker.Read(AOpb, 8);
    if LBook < 0 then
      Exit(Fail);
    LResidue.FBookList[LJ] := LBook;
  end;

  if LResidue.FGroupBook >= Length(ABooks) then
    Exit(Fail);
  for LJ := 0 to LAcc - 1 do
  begin
    if LResidue.FBookList[LJ] >= Length(ABooks) then
      Exit(Fail);
    if ABooks[LResidue.FBookList[LJ]].MapType = 0 then
      Exit(Fail);
  end;

  // the group book must not promise more partitions than it has entries
  LEntries := ABooks[LResidue.FGroupBook].Entries;
  LDim := ABooks[LResidue.FGroupBook].Dim;
  LPartVals := 1;
  if LDim < 1 then
    Exit(Fail);
  while LDim > 0 do
  begin
    LPartVals := LPartVals * LResidue.FPartitions;
    if LPartVals > LEntries then
      Exit(Fail);
    Dec(LDim);
  end;
  LResidue.FPartVals := LPartVals;

  Result := LResidue;
end;

procedure TVorbisResidue.Look(const ABooks: TArray<TVorbisCodebook>);
var
  LJ, LK, LAcc, LDim, LStages, LPartVals, LMult, LVal, LDeco: Integer;
begin
  LAcc := 0;
  FStages := 0;
  FPhraseBook := ABooks[FGroupBook];
  LDim := FPhraseBook.Dim;

  SetLength(FPartBooks, FPartitions);
  for LJ := 0 to FPartitions - 1 do
  begin
    LStages := OvIlog(Cardinal(FSecondStages[LJ]));
    if LStages <> 0 then
    begin
      if LStages > FStages then
        FStages := LStages;
      SetLength(FPartBooks[LJ], LStages);
      for LK := 0 to LStages - 1 do
        if (FSecondStages[LJ] and (1 shl LK)) <> 0 then
        begin
          FPartBooks[LJ][LK] := ABooks[FBookList[LAcc]];
          Inc(LAcc);
        end;
    end;
  end;

  LPartVals := 1;
  for LJ := 0 to LDim - 1 do
    LPartVals := LPartVals * FPartitions;
  SetLength(FDecodeMap, LPartVals);
  for LJ := 0 to LPartVals - 1 do
  begin
    LVal := LJ;
    LMult := LPartVals div FPartitions;
    SetLength(FDecodeMap[LJ], LDim);
    for LK := 0 to LDim - 1 do
    begin
      LDeco := LVal div LMult;
      Dec(LVal, LDeco * LMult);
      LMult := LMult div FPartitions;
      FDecodeMap[LJ][LK] := LDeco;
    end;
  end;
end;

procedure TVorbisResidue.InverseTypes01(const AOpb: POggPackBuffer;
  APcmEnd: Integer; const AIn: array of PSingle; AChannels: Integer);
var
  LSamplesPerPartition, LPartitionsPerWord, LMax, LEnd, LN, LPartVals,
  LPartWords, LS, LI, LL, LJ, LK, LTemp, LOffset, LClass: Integer;
  LPartWord: TArray<TArray<Integer>>;
  LBook: TVorbisCodebook;
  LData: PSingle;
  LStatus: Integer;
begin
  LSamplesPerPartition := FGrouping;
  LPartitionsPerWord := FPhraseBook.Dim;
  LMax := APcmEnd shr 1;
  if FEnd < LMax then
    LEnd := FEnd
  else
    LEnd := LMax;
  LN := LEnd - FBegin;
  if LN <= 0 then
    Exit;

  LPartVals := LN div LSamplesPerPartition;
  LPartWords := (LPartVals + LPartitionsPerWord - 1) div LPartitionsPerWord;
  SetLength(LPartWord, AChannels);
  for LJ := 0 to AChannels - 1 do
    SetLength(LPartWord[LJ], LPartWords);

  for LS := 0 to FStages - 1 do
  begin
    LI := 0;
    LL := 0;
    while LI < LPartVals do
    begin
      if LS = 0 then
        // the partition word of each channel
        for LJ := 0 to AChannels - 1 do
        begin
          LTemp := FPhraseBook.Decode(AOpb);
          if (LTemp = -1) or (LTemp >= FPartVals) then
            Exit;
          LPartWord[LJ][LL] := LTemp;
        end;

      // the values of the partitions of the word
      LK := 0;
      while (LK < LPartitionsPerWord) and (LI < LPartVals) do
      begin
        for LJ := 0 to AChannels - 1 do
        begin
          LOffset := FBegin + LI * LSamplesPerPartition;
          LClass := FDecodeMap[LPartWord[LJ][LL]][LK];
          if (FSecondStages[LClass] and (1 shl LS)) <> 0 then
          begin
            LBook := FPartBooks[LClass][LS];
            if LBook <> nil then
            begin
              LData := AIn[LJ] + LOffset;
              if FKind = 0 then
                LStatus := LBook.DecodeVectorsStep(LData, AOpb, LSamplesPerPartition)
              else
                LStatus := LBook.DecodeVectors(LData, AOpb, LSamplesPerPartition);
              if LStatus = -1 then
                Exit;
            end;
          end;
        end;
        Inc(LK);
        Inc(LI);
      end;
      Inc(LL);
    end;
  end;
end;

procedure TVorbisResidue.InverseType2(const AOpb: POggPackBuffer;
  APcmEnd: Integer; const AIn: array of PSingle; const ANonZero: array of Boolean;
  AChannels: Integer);
var
  LSamplesPerPartition, LPartitionsPerWord, LMax, LEnd, LN, LPartVals,
  LPartWords, LS, LI, LL, LK, LTemp, LClass: Integer;
  LPartWord: TArray<Integer>;
  LBook: TVorbisCodebook;
  LAny: Boolean;
begin
  LSamplesPerPartition := FGrouping;
  LPartitionsPerWord := FPhraseBook.Dim;
  LMax := (APcmEnd * AChannels) shr 1;
  if FEnd < LMax then
    LEnd := FEnd
  else
    LEnd := LMax;
  LN := LEnd - FBegin;
  if LN <= 0 then
    Exit;

  LPartVals := LN div LSamplesPerPartition;
  LPartWords := (LPartVals + LPartitionsPerWord - 1) div LPartitionsPerWord;
  SetLength(LPartWord, LPartWords);

  LAny := False;
  for LI := 0 to AChannels - 1 do
    if ANonZero[LI] then
    begin
      LAny := True;
      Break;
    end;
  if not LAny then
    Exit;

  for LS := 0 to FStages - 1 do
  begin
    LI := 0;
    LL := 0;
    while LI < LPartVals do
    begin
      if LS = 0 then
      begin
        LTemp := FPhraseBook.Decode(AOpb);
        if (LTemp = -1) or (LTemp >= FPartVals) then
          Exit;
        LPartWord[LL] := LTemp;
      end;

      LK := 0;
      while (LK < LPartitionsPerWord) and (LI < LPartVals) do
      begin
        LClass := FDecodeMap[LPartWord[LL]][LK];
        if (FSecondStages[LClass] and (1 shl LS)) <> 0 then
        begin
          LBook := FPartBooks[LClass][LS];
          if LBook <> nil then
            if LBook.DecodeInterleaved(AIn, LI * LSamplesPerPartition + FBegin, AChannels,
              AOpb, LSamplesPerPartition) = -1 then
              Exit;
        end;
        Inc(LK);
        Inc(LI);
      end;
      Inc(LL);
    end;
  end;
end;

procedure TVorbisResidue.Inverse(const AOpb: POggPackBuffer; APcmEnd: Integer;
  const AIn: array of PSingle; const ANonZero: array of Boolean; AChannels: Integer);
var
  LI, LUsed: Integer;
  LCompact: TArray<PSingle>;
begin
  if FKind = 2 then
  begin
    InverseType2(AOpb, APcmEnd, AIn, ANonZero, AChannels);
    Exit;
  end;

  // the silent channels are left out
  SetLength(LCompact, AChannels);
  LUsed := 0;
  for LI := 0 to AChannels - 1 do
    if ANonZero[LI] then
    begin
      LCompact[LUsed] := AIn[LI];
      Inc(LUsed);
    end;
  if LUsed > 0 then
    InverseTypes01(AOpb, APcmEnd, LCompact, LUsed);
end;

end.
