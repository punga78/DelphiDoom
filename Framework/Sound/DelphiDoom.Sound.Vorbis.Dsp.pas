{******************************************************************************}
{                                                                              }
{  DelphiDoom: sound decoder - Vorbis, from packets to samples                 }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)             }
{  Derived from libvorbis by the Xiph.Org Foundation (BSD licence)             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Sound.Vorbis.Dsp;

interface

uses
  System.SysUtils, DelphiDoom.Ogg.Types, DelphiDoom.Sound.Vorbis.Types,
  DelphiDoom.Sound.Vorbis.Info, DelphiDoom.Sound.Vorbis.Mdct;

{$POINTERMATH ON}

type
  /// <summary>
  ///   The state of the decoding of a stream: the packets become blocks
  ///   (Synthesis), the blocks are windowed and overlapped into the samples
  ///   (BlockIn) and the samples are taken out (PcmOut, Read). The pending
  ///   samples sit in a buffer of two halves, as in libvorbis
  /// </summary>
  TVorbisDsp = class
  private
    FInfo: TVorbisInfo;
    FMdct: array[0..1] of TVorbisMdct;
    FWindow: array[0..1] of Integer;
    FModeBits: Integer;
    FPcm: TArray<TArray<Single>>;
    FPcmStorage: Integer;
    FCenterW: Integer;
    FPcmCurrent: Integer;
    FPcmReturned: Integer;
    FW: Integer;
    FLW: Integer;
    FNW: Integer;
    FGranulePosition: Int64;
    FSequence: Int64;
    FEndOfStream: Integer;
    FSampleCount: Int64;
    FReady: Boolean;
    procedure Restart;
  public
    /// <summary>
    ///   Prepares the decoding with the setup of AInfo (which must stay alive);
    ///   Ready tells whether it could
    /// </summary>
    constructor Create(const AInfo: TVorbisInfo);
    destructor Destroy; override;
    /// <summary>Decodes a packet into ABlock; zero, or an OV_ error code</summary>
    function Synthesis(const APacket: POggPacket; var ABlock: TVorbisBlock): Integer;
    /// <summary>Overlaps the block with the previous one and makes its samples available</summary>
    function BlockIn(const ABlock: TVorbisBlock): Integer;
    /// <summary>How many samples are available</summary>
    function PcmOut: Integer;
    /// <summary>The first sample available of a channel</summary>
    function PcmChannel(AChannel: Integer): PSingle;
    /// <summary>Takes ACount samples out of those available</summary>
    function Read(ACount: Integer): Integer;
    property Ready: Boolean read FReady;
  end;

implementation

uses
  DelphiDoom.Ogg.BitPacker, DelphiDoom.Sound.Vorbis.WindowTables;

{ TVorbisDsp }

constructor TVorbisDsp.Create(const AInfo: TVorbisInfo);
var
  LIndex, LChannel: Integer;
begin
  inherited Create;
  FInfo := AInfo;
  if (not AInfo.HasSetup) or (Length(AInfo.Modes) <= 0) or (AInfo.BlockSizes[0] < 64) or
     (AInfo.BlockSizes[1] < AInfo.BlockSizes[0]) then
    Exit;

  FModeBits := OvIlog(Cardinal(Length(AInfo.Modes) - 1));
  FMdct[0] := TVorbisMdct.Create(AInfo.BlockSizes[0]);
  FMdct[1] := TVorbisMdct.Create(AInfo.BlockSizes[1]);
  FWindow[0] := OvIlog(Cardinal(AInfo.BlockSizes[0])) - 7;
  FWindow[1] := OvIlog(Cardinal(AInfo.BlockSizes[1])) - 7;

  // the codebooks become decoders; a code that is not a prefix code ends it
  for LIndex := 0 to High(AInfo.Books) do
    if not AInfo.Books[LIndex].BuildDecoder then
      Exit;
  for LIndex := 0 to High(AInfo.Residues) do
    AInfo.Residues[LIndex].Look(AInfo.Books);

  FPcmStorage := AInfo.BlockSizes[1];
  SetLength(FPcm, AInfo.Channels);
  for LChannel := 0 to AInfo.Channels - 1 do
    SetLength(FPcm[LChannel], FPcmStorage);

  FW := 0;
  FLW := 0;
  Restart;
  FReady := True;
end;

destructor TVorbisDsp.Destroy;
begin
  FMdct[0].Free;
  FMdct[1].Free;
  inherited;
end;

procedure TVorbisDsp.Restart;
begin
  FCenterW := FInfo.BlockSizes[1] shr 1;
  FPcmCurrent := FCenterW;
  FPcmReturned := -1;
  FGranulePosition := -1;
  FSequence := -1;
  FEndOfStream := 0;
  FSampleCount := -1;
end;

function TVorbisDsp.Synthesis(const APacket: POggPacket;
  var ABlock: TVorbisBlock): Integer;
var
  LMode, LChannel: Integer;
begin
  if not FReady then
    Exit(OV_EBADPACKET);

  TOggBitPacker.ReadInit(@ABlock.Opb, APacket.Packet, APacket.Bytes);

  // is it a packet of audio?
  if TOggBitPacker.Read(@ABlock.Opb, 1) <> 0 then
    Exit(OV_ENOTAUDIO);

  // the mode, and with it the window before and after
  LMode := TOggBitPacker.Read(@ABlock.Opb, FModeBits);
  if LMode = -1 then
    Exit(OV_EBADPACKET);
  ABlock.Mode := LMode;
  if LMode >= Length(FInfo.Modes) then
    Exit(OV_EBADPACKET);

  ABlock.W := FInfo.Modes[LMode].BlockFlag;
  if ABlock.W <> 0 then
  begin
    ABlock.LW := TOggBitPacker.Read(@ABlock.Opb, 1);
    ABlock.NW := TOggBitPacker.Read(@ABlock.Opb, 1);
    if ABlock.NW = -1 then
      Exit(OV_EBADPACKET);
  end
  else
  begin
    ABlock.LW := 0;
    ABlock.NW := 0;
  end;

  ABlock.GranulePosition := APacket.GranulePosition;
  ABlock.Sequence := APacket.PacketNumber;
  ABlock.EndOfStream := APacket.EndOfStream;

  ABlock.PcmEnd := FInfo.BlockSizes[ABlock.W];
  if Length(ABlock.Pcm) <> FInfo.Channels then
    SetLength(ABlock.Pcm, FInfo.Channels);
  for LChannel := 0 to FInfo.Channels - 1 do
    if Length(ABlock.Pcm[LChannel]) <> ABlock.PcmEnd then
      SetLength(ABlock.Pcm[LChannel], ABlock.PcmEnd);

  FInfo.Mappings[FInfo.Modes[LMode].Mapping].Inverse(ABlock, FInfo.Channels,
    FInfo.Floors, FInfo.Residues, FInfo.Books, FMdct[ABlock.W]);
  Result := 0;
end;

function TVorbisDsp.BlockIn(const ABlock: TVorbisBlock): Integer;
var
  LN, LN0, LN1, LThisCenter, LPrevCenter, LJ, LI, LExtra: Integer;
  LWindow: PSingleArray;
  LPcm, LP: PSingle;
begin
  if (FPcmCurrent > FPcmReturned) and (FPcmReturned <> -1) then
    Exit(OV_EINVAL);

  FLW := FW;
  FW := ABlock.W;
  FNW := -1;

  if (FSequence = -1) or (FSequence + 1 <> ABlock.Sequence) then
  begin
    // out of sequence: the count is lost
    FGranulePosition := -1;
    FSampleCount := -1;
  end;
  FSequence := ABlock.Sequence;

  if Length(ABlock.Pcm) > 0 then
  begin
    LN := FInfo.BlockSizes[FW] shr 1;
    LN0 := FInfo.BlockSizes[0] shr 1;
    LN1 := FInfo.BlockSizes[1] shr 1;

    if FCenterW <> 0 then
    begin
      LThisCenter := LN1;
      LPrevCenter := 0;
    end
    else
    begin
      LThisCenter := 0;
      LPrevCenter := LN1;
    end;

    // the buffer is a double buffer: a new block is not taken until the old
    // one has been shifted out
    for LJ := 0 to FInfo.Channels - 1 do
    begin
      // the overlap/add section
      if FLW <> 0 then
      begin
        if FW <> 0 then
        begin
          // large/large
          LWindow := VorbisWindow(FWindow[1]);
          LPcm := @FPcm[LJ][LPrevCenter];
          LP := @ABlock.Pcm[LJ][0];
          for LI := 0 to LN1 - 1 do
            LPcm[LI] := LPcm[LI] * LWindow[LN1 - LI - 1] + LP[LI] * LWindow[LI];
        end
        else
        begin
          // large/small
          LWindow := VorbisWindow(FWindow[0]);
          LPcm := @FPcm[LJ][LPrevCenter + LN1 div 2 - LN0 div 2];
          LP := @ABlock.Pcm[LJ][0];
          for LI := 0 to LN0 - 1 do
            LPcm[LI] := LPcm[LI] * LWindow[LN0 - LI - 1] + LP[LI] * LWindow[LI];
        end;
      end
      else if FW <> 0 then
      begin
        // small/large
        LWindow := VorbisWindow(FWindow[0]);
        LPcm := @FPcm[LJ][LPrevCenter];
        LP := @ABlock.Pcm[LJ][LN1 div 2 - LN0 div 2];
        LI := 0;
        while LI < LN0 do
        begin
          LPcm[LI] := LPcm[LI] * LWindow[LN0 - LI - 1] + LP[LI] * LWindow[LI];
          Inc(LI);
        end;
        while LI < LN1 div 2 + LN0 div 2 do
        begin
          LPcm[LI] := LP[LI];
          Inc(LI);
        end;
      end
      else
      begin
        // small/small
        LWindow := VorbisWindow(FWindow[0]);
        LPcm := @FPcm[LJ][LPrevCenter];
        LP := @ABlock.Pcm[LJ][0];
        for LI := 0 to LN0 - 1 do
          LPcm[LI] := LPcm[LI] * LWindow[LN0 - LI - 1] + LP[LI] * LWindow[LI];
      end;

      // the copy section
      LPcm := @FPcm[LJ][LThisCenter];
      LP := @ABlock.Pcm[LJ][LN];
      for LI := 0 to LN - 1 do
        LPcm[LI] := LP[LI];
    end;

    if FCenterW <> 0 then
      FCenterW := 0
    else
      FCenterW := LN1;

    // the first packet is told by pcm_returned being -1: otherwise a short or
    // long first block would make a difference
    if FPcmReturned = -1 then
    begin
      FPcmReturned := LThisCenter;
      FPcmCurrent := LThisCenter;
    end
    else
    begin
      FPcmReturned := LPrevCenter;
      FPcmCurrent := LPrevCenter + (FInfo.BlockSizes[FLW] div 4 + FInfo.BlockSizes[FW] div 4);
    end;
  end;

  // track the number of the sample, to cut the end of the last packet
  if FSampleCount = -1 then
    FSampleCount := 0
  else
    Inc(FSampleCount, FInfo.BlockSizes[FLW] div 4 + FInfo.BlockSizes[FW] div 4);

  if FGranulePosition = -1 then
  begin
    if ABlock.GranulePosition <> -1 then
    begin
      FGranulePosition := ABlock.GranulePosition;

      // a short page?
      if FSampleCount > FGranulePosition then
      begin
        LExtra := Integer(FSampleCount - ABlock.GranulePosition);
        if LExtra < 0 then
          LExtra := 0;

        if ABlock.EndOfStream <> 0 then
        begin
          // the end is cut; not more than there is
          if LExtra > FPcmCurrent - FPcmReturned then
            LExtra := FPcmCurrent - FPcmReturned;
          Dec(FPcmCurrent, LExtra);
        end
        else
        begin
          // the beginning is cut
          Inc(FPcmReturned, LExtra);
          if FPcmReturned > FPcmCurrent then
            FPcmReturned := FPcmCurrent;
        end;
      end;
    end;
  end
  else
  begin
    Inc(FGranulePosition, FInfo.BlockSizes[FLW] div 4 + FInfo.BlockSizes[FW] div 4);
    if (ABlock.GranulePosition <> -1) and (FGranulePosition <> ABlock.GranulePosition) then
    begin
      if FGranulePosition > ABlock.GranulePosition then
      begin
        LExtra := Integer(FGranulePosition - ABlock.GranulePosition);
        if LExtra <> 0 then
          if ABlock.EndOfStream <> 0 then
          begin
            // a partial last frame: the extra samples go
            if LExtra > FPcmCurrent - FPcmReturned then
              LExtra := FPcmCurrent - FPcmReturned;
            if LExtra < 0 then
              LExtra := 0;
            Dec(FPcmCurrent, LExtra);
          end;
      end;
      FGranulePosition := ABlock.GranulePosition;
    end;
  end;

  if ABlock.EndOfStream <> 0 then
    FEndOfStream := 1;
  Result := 0;
end;

function TVorbisDsp.PcmOut: Integer;
begin
  if (FPcmReturned > -1) and (FPcmReturned < FPcmCurrent) then
    Result := FPcmCurrent - FPcmReturned
  else
    Result := 0;
end;

function TVorbisDsp.PcmChannel(AChannel: Integer): PSingle;
begin
  Result := @FPcm[AChannel][FPcmReturned];
end;

function TVorbisDsp.Read(ACount: Integer): Integer;
begin
  if (ACount <> 0) and (FPcmReturned + ACount > FPcmCurrent) then
    Exit(OV_EINVAL);
  Inc(FPcmReturned, ACount);
  Result := 0;
end;

end.
