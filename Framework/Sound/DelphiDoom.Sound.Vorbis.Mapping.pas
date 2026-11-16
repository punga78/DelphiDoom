{******************************************************************************}
{                                                                              }
{  DelphiDoom: sound decoder - Vorbis, the mapping of channels (type 0)        }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{  Derived from libvorbis by the Xiph.Org Foundation (BSD licence)             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Sound.Vorbis.Mapping;

interface

uses
  System.SysUtils, DelphiDoom.Ogg.Types, DelphiDoom.Sound.Vorbis.Types,
  DelphiDoom.Sound.Vorbis.Codebook, DelphiDoom.Sound.Vorbis.Floor1,
  DelphiDoom.Sound.Vorbis.Residue, DelphiDoom.Sound.Vorbis.Mdct;

{$POINTERMATH ON}

type
  /// <summary>
  ///   How the channels of a mode are coded: which floor and residue each of
  ///   them uses and which pairs are coupled (magnitude and angle). Decoding a
  ///   packet is done here, from the floors to the samples of the block
  /// </summary>
  TVorbisMapping = class
  private
    FSubmaps: Integer;
    FChannelMux: array[0..255] of Integer;
    FFloorSubmap: array[0..15] of Integer;
    FResidueSubmap: array[0..15] of Integer;
    FCouplingSteps: Integer;
    FCouplingMag: array[0..255] of Integer;
    FCouplingAng: array[0..255] of Integer;
  public
    /// <summary>
    ///   Reads a mapping of the setup header; nil when it is damaged. The
    ///   counts are those of the floors and the residues read before it
    /// </summary>
    class function Unpack(const AOpb: POggPackBuffer; AChannels, AFloorCount,
      AResidueCount: Integer): TVorbisMapping; static;
    /// <summary>
    ///   Turns the packet in ABlock.Opb into the samples of the block (before
    ///   they are windowed): ABlock.Pcm holds the PcmEnd values of each channel
    /// </summary>
    procedure Inverse(var ABlock: TVorbisBlock; AChannels: Integer;
      const AFloors: TArray<TVorbisFloor1>; const AResidues: TArray<TVorbisResidue>;
      const ABooks: TArray<TVorbisCodebook>; const AMdct: TVorbisMdct);
  end;

implementation

uses
  DelphiDoom.Ogg.BitPacker;

{ TVorbisMapping }

class function TVorbisMapping.Unpack(const AOpb: POggPackBuffer; AChannels,
  AFloorCount, AResidueCount: Integer): TVorbisMapping;
var
  LMapping: TVorbisMapping;
  LI, LB, LTestM, LTestA: Integer;

  function Fail: TVorbisMapping;
  begin
    LMapping.Free;
    Result := nil;
  end;

begin
  LMapping := TVorbisMapping.Create;
  if AChannels <= 0 then
    Exit(Fail);

  LB := TOggBitPacker.Read(AOpb, 1);
  if LB < 0 then
    Exit(Fail);
  if LB <> 0 then
  begin
    LMapping.FSubmaps := TOggBitPacker.Read(AOpb, 4) + 1;
    if LMapping.FSubmaps <= 0 then
      Exit(Fail);
  end
  else
    LMapping.FSubmaps := 1;

  LB := TOggBitPacker.Read(AOpb, 1);
  if LB < 0 then
    Exit(Fail);
  if LB <> 0 then
  begin
    LMapping.FCouplingSteps := TOggBitPacker.Read(AOpb, 8) + 1;
    if LMapping.FCouplingSteps <= 0 then
      Exit(Fail);
    for LI := 0 to LMapping.FCouplingSteps - 1 do
    begin
      LTestM := TOggBitPacker.Read(AOpb, OvIlog(Cardinal(AChannels - 1)));
      LMapping.FCouplingMag[LI] := LTestM;
      LTestA := TOggBitPacker.Read(AOpb, OvIlog(Cardinal(AChannels - 1)));
      LMapping.FCouplingAng[LI] := LTestA;

      if (LTestM < 0) or (LTestA < 0) or (LTestM = LTestA) or
         (LTestM >= AChannels) or (LTestA >= AChannels) then
        Exit(Fail);
    end;
  end;

  // two reserved bits
  if TOggBitPacker.Read(AOpb, 2) <> 0 then
    Exit(Fail);

  if LMapping.FSubmaps > 1 then
    for LI := 0 to AChannels - 1 do
    begin
      LMapping.FChannelMux[LI] := TOggBitPacker.Read(AOpb, 4);
      if (LMapping.FChannelMux[LI] >= LMapping.FSubmaps) or (LMapping.FChannelMux[LI] < 0) then
        Exit(Fail);
    end;

  for LI := 0 to LMapping.FSubmaps - 1 do
  begin
    // the submap of the time domain is not used
    TOggBitPacker.Read(AOpb, 8);
    LMapping.FFloorSubmap[LI] := TOggBitPacker.Read(AOpb, 8);
    if (LMapping.FFloorSubmap[LI] >= AFloorCount) or (LMapping.FFloorSubmap[LI] < 0) then
      Exit(Fail);
    LMapping.FResidueSubmap[LI] := TOggBitPacker.Read(AOpb, 8);
    if (LMapping.FResidueSubmap[LI] >= AResidueCount) or (LMapping.FResidueSubmap[LI] < 0) then
      Exit(Fail);
  end;

  Result := LMapping;
end;

procedure TVorbisMapping.Inverse(var ABlock: TVorbisBlock; AChannels: Integer;
  const AFloors: TArray<TVorbisFloor1>; const AResidues: TArray<TVorbisResidue>;
  const ABooks: TArray<TVorbisCodebook>; const AMdct: TVorbisMdct);
var
  LN, LI, LJ, LInBundle: Integer;
  LNonZero: TArray<Boolean>;
  LMemo: TArray<TArray<Integer>>;
  LBundle: TArray<PSingle>;
  LZeroBundle: TArray<Boolean>;
  LPcmM, LPcmA: PSingle;
  LMag, LAng: Single;
begin
  LN := ABlock.PcmEnd;
  SetLength(LNonZero, AChannels);
  SetLength(LMemo, AChannels);
  SetLength(LBundle, AChannels);
  SetLength(LZeroBundle, AChannels);

  // recover the spectral envelope; it is kept in the vector of the samples
  for LI := 0 to AChannels - 1 do
  begin
    LMemo[LI] := AFloors[FFloorSubmap[FChannelMux[LI]]].Inverse1(@ABlock.Opb, ABooks);
    LNonZero[LI] := LMemo[LI] <> nil;
    FillChar(ABlock.Pcm[LI][0], (LN div 2) * SizeOf(Single), 0);
  end;

  // channel coupling can make a silent channel not silent
  for LI := 0 to FCouplingSteps - 1 do
    if LNonZero[FCouplingMag[LI]] or LNonZero[FCouplingAng[LI]] then
    begin
      LNonZero[FCouplingMag[LI]] := True;
      LNonZero[FCouplingAng[LI]] := True;
    end;

  // recover the residue into the working vectors
  for LI := 0 to FSubmaps - 1 do
  begin
    LInBundle := 0;
    for LJ := 0 to AChannels - 1 do
      if FChannelMux[LJ] = LI then
      begin
        LZeroBundle[LInBundle] := LNonZero[LJ];
        LBundle[LInBundle] := @ABlock.Pcm[LJ][0];
        Inc(LInBundle);
      end;
    AResidues[FResidueSubmap[LI]].Inverse(@ABlock.Opb, LN, LBundle, LZeroBundle, LInBundle);
  end;

  // channel coupling
  for LI := FCouplingSteps - 1 downto 0 do
  begin
    LPcmM := @ABlock.Pcm[FCouplingMag[LI]][0];
    LPcmA := @ABlock.Pcm[FCouplingAng[LI]][0];
    for LJ := 0 to LN div 2 - 1 do
    begin
      LMag := LPcmM[LJ];
      LAng := LPcmA[LJ];
      if LMag > 0 then
      begin
        if LAng > 0 then
        begin
          LPcmM[LJ] := LMag;
          LPcmA[LJ] := LMag - LAng;
        end
        else
        begin
          LPcmA[LJ] := LMag;
          LPcmM[LJ] := LMag + LAng;
        end;
      end
      else if LAng > 0 then
      begin
        LPcmM[LJ] := LMag;
        LPcmA[LJ] := LMag + LAng;
      end
      else
      begin
        LPcmA[LJ] := LMag;
        LPcmM[LJ] := LMag - LAng;
      end;
    end;
  end;

  // compute and apply the spectral envelope
  for LI := 0 to AChannels - 1 do
    AFloors[FFloorSubmap[FChannelMux[LI]]].Inverse2(LMemo[LI], @ABlock.Pcm[LI][0], LN div 2);

  // back to the time domain
  for LI := 0 to AChannels - 1 do
    AMdct.Backward(@ABlock.Pcm[LI][0]);
end;

end.
