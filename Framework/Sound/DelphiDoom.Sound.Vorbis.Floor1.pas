{******************************************************************************}
{                                                                              }
{  DelphiDoom: sound decoder - Vorbis, floor type 1                            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{  Derived from libvorbis by the Xiph.Org Foundation (BSD licence)             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Sound.Vorbis.Floor1;

interface

uses
  System.SysUtils, DelphiDoom.Ogg.Types, DelphiDoom.Sound.Vorbis.Types,
  DelphiDoom.Sound.Vorbis.Codebook;

{$POINTERMATH ON}

type
  /// <summary>
  ///   The spectral envelope of a channel, as a piecewise linear curve in dB
  ///   (floor type 1). The older floor type 0 is not supported
  /// </summary>
  TVorbisFloor1 = class
  private
    const
      MAX_POSTS = 63;
    var
      FPartitions: Integer;
      FPartitionClass: array[0..30] of Integer;
      FClassDim: array[0..15] of Integer;
      FClassSubs: array[0..15] of Integer;
      FClassBook: array[0..15] of Integer;
      FClassSubbook: array[0..15, 0..7] of Integer;
      FMult: Integer;
      FPostList: array[0..MAX_POSTS + 1] of Integer;
      FForwardIndex: array[0..MAX_POSTS + 1] of Integer;
      FHiNeighbor: array[0..MAX_POSTS - 1] of Integer;
      FLoNeighbor: array[0..MAX_POSTS - 1] of Integer;
      FPosts: Integer;
      FQuantQ: Integer;
    procedure Prepare;
    class function RenderPoint(AX0, AX1, AY0, AY1, AX: Integer): Integer; static;
    class procedure RenderLine(AN, AX0, AX1, AY0, AY1: Integer; AOut: PSingle); static;
  public
    /// <summary>
    ///   Reads the floor from the setup header; nil when it is damaged.
    ///   ABookCount is how many codebooks the stream has
    /// </summary>
    class function Unpack(const AOpb: POggPackBuffer; ABookCount: Integer): TVorbisFloor1; static;
    /// <summary>
    ///   Reads from the packet the amplitudes of the posts of the floor. Nil
    ///   when the channel is silent or the packet ends
    /// </summary>
    function Inverse1(const AOpb: POggPackBuffer; const ABooks: TArray<TVorbisCodebook>): TArray<Integer>;
    /// <summary>
    ///   Multiplies AOut (ASize values) by the curve of the posts that Inverse1
    ///   gave; without them the curve is silence. True when there was a curve
    /// </summary>
    function Inverse2(const AMemo: TArray<Integer>; AOut: PSingle; ASize: Integer): Boolean;
  end;

implementation

uses
  System.Generics.Collections, System.Generics.Defaults, DelphiDoom.Ogg.BitPacker;

const
  FLOOR1_FROM_DB: array[0..255] of Single = (
    1.0649863e-07, 1.1341951e-07, 1.2079015e-07, 1.2863978e-07,
    1.3699951e-07, 1.4590251e-07, 1.5538408e-07, 1.6548181e-07,
    1.7623575e-07, 1.8768855e-07, 1.9988561e-07, 2.128753e-07,
    2.2670913e-07, 2.4144197e-07, 2.5713223e-07, 2.7384213e-07,
    2.9163793e-07, 3.1059021e-07, 3.3077411e-07, 3.5226968e-07,
    3.7516214e-07, 3.9954229e-07, 4.2550680e-07, 4.5315863e-07,
    4.8260743e-07, 5.1396998e-07, 5.4737065e-07, 5.8294187e-07,
    6.2082472e-07, 6.6116941e-07, 7.0413592e-07, 7.4989464e-07,
    7.9862701e-07, 8.5052630e-07, 9.0579828e-07, 9.6466216e-07,
    1.0273513e-06, 1.0941144e-06, 1.1652161e-06, 1.2409384e-06,
    1.3215816e-06, 1.4074654e-06, 1.4989305e-06, 1.5963394e-06,
    1.7000785e-06, 1.8105592e-06, 1.9282195e-06, 2.0535261e-06,
    2.1869758e-06, 2.3290978e-06, 2.4804557e-06, 2.6416497e-06,
    2.8133190e-06, 2.9961443e-06, 3.1908506e-06, 3.3982101e-06,
    3.6190449e-06, 3.8542308e-06, 4.1047004e-06, 4.3714470e-06,
    4.6555282e-06, 4.9580707e-06, 5.2802740e-06, 5.6234160e-06,
    5.9888572e-06, 6.3780469e-06, 6.7925283e-06, 7.2339451e-06,
    7.7040476e-06, 8.2047000e-06, 8.7378876e-06, 9.3057248e-06,
    9.9104632e-06, 1.0554501e-05, 1.1240392e-05, 1.1970856e-05,
    1.2748789e-05, 1.3577278e-05, 1.4459606e-05, 1.5399272e-05,
    1.6400004e-05, 1.7465768e-05, 1.8600792e-05, 1.9809576e-05,
    2.1096914e-05, 2.2467911e-05, 2.3928002e-05, 2.5482978e-05,
    2.7139006e-05, 2.8902651e-05, 3.0780908e-05, 3.2781225e-05,
    3.4911534e-05, 3.7180282e-05, 3.9596466e-05, 4.2169667e-05,
    4.4910090e-05, 4.7828601e-05, 5.0936773e-05, 5.4246931e-05,
    5.7772202e-05, 6.1526565e-05, 6.5524908e-05, 6.9783085e-05,
    7.4317983e-05, 7.9147585e-05, 8.4291040e-05, 8.9768747e-05,
    9.5602426e-05, 0.00010181521, 0.00010843174, 0.00011547824,
    0.00012298267, 0.00013097477, 0.00013948625, 0.00014855085,
    0.00015820453, 0.00016848555, 0.00017943469, 0.00019109536,
    0.00020351382, 0.00021673929, 0.00023082423, 0.00024582449,
    0.00026179955, 0.00027881276, 0.00029693158, 0.00031622787,
    0.00033677814, 0.00035866388, 0.00038197188, 0.00040679456,
    0.00043323036, 0.00046138411, 0.00049136745, 0.00052329927,
    0.00055730621, 0.00059352311, 0.00063209358, 0.00067317058,
    0.00071691700, 0.00076350630, 0.00081312324, 0.00086596457,
    0.00092223983, 0.00098217216, 0.0010459992, 0.0011139742,
    0.0011863665, 0.0012634633, 0.0013455702, 0.0014330129,
    0.0015261382, 0.0016253153, 0.0017309374, 0.0018434235,
    0.0019632195, 0.0020908006, 0.0022266726, 0.0023713743,
    0.0025254795, 0.0026895994, 0.0028643847, 0.0030505286,
    0.0032487691, 0.0034598925, 0.0036847358, 0.0039241906,
    0.0041792066, 0.0044507950, 0.0047400328, 0.0050480668,
    0.0053761186, 0.0057254891, 0.0060975636, 0.0064938176,
    0.0069158225, 0.0073652516, 0.0078438871, 0.0083536271,
    0.0088964928, 0.009474637, 0.010090352, 0.010746080,
    0.011444421, 0.012188144, 0.012980198, 0.013823725,
    0.014722068, 0.015678791, 0.016697687, 0.017782797,
    0.018938423, 0.020169149, 0.021479854, 0.022875735,
    0.024362330, 0.025945531, 0.027631618, 0.029427276,
    0.031339626, 0.033376252, 0.035545228, 0.037855157,
    0.040315199, 0.042935108, 0.045725273, 0.048696758,
    0.051861348, 0.055231591, 0.058820850, 0.062643361,
    0.066714279, 0.071049749, 0.075666962, 0.080584227,
    0.085821044, 0.091398179, 0.097337747, 0.10366330,
    0.11039993, 0.11757434, 0.12521498, 0.13335215,
    0.14201813, 0.15124727, 0.16107617, 0.17154380,
    0.18269168, 0.19456402, 0.20720788, 0.22067342,
    0.23501402, 0.25028656, 0.26655159, 0.28387361,
    0.30232132, 0.32196786, 0.34289114, 0.36517414,
    0.38890521, 0.41417847, 0.44109412, 0.46975890,
    0.50028648, 0.53279791, 0.56742212, 0.60429640,
    0.64356699, 0.68538959, 0.72993007, 0.77736504,
    0.82788260, 0.88168307, 0.9389798, 1
  );

{ TVorbisFloor1 }

class function TVorbisFloor1.Unpack(const AOpb: POggPackBuffer;
  ABookCount: Integer): TVorbisFloor1;
var
  LFloor: TVorbisFloor1;
  LJ, LK, LCount, LMaxClass, LRangeBits, LValue: Integer;
  LSorted: TArray<Integer>;

  function Fail: TVorbisFloor1;
  begin
    LFloor.Free;
    Result := nil;
  end;

begin
  LFloor := TVorbisFloor1.Create;
  LCount := 0;
  LMaxClass := -1;

  LFloor.FPartitions := TOggBitPacker.Read(AOpb, 5);
  for LJ := 0 to LFloor.FPartitions - 1 do
  begin
    LFloor.FPartitionClass[LJ] := TOggBitPacker.Read(AOpb, 4);
    if LFloor.FPartitionClass[LJ] < 0 then
      Exit(Fail);
    if LMaxClass < LFloor.FPartitionClass[LJ] then
      LMaxClass := LFloor.FPartitionClass[LJ];
  end;

  for LJ := 0 to LMaxClass do
  begin
    LFloor.FClassDim[LJ] := TOggBitPacker.Read(AOpb, 3) + 1;
    LFloor.FClassSubs[LJ] := TOggBitPacker.Read(AOpb, 2);
    if LFloor.FClassSubs[LJ] < 0 then
      Exit(Fail);
    if LFloor.FClassSubs[LJ] <> 0 then
      LFloor.FClassBook[LJ] := TOggBitPacker.Read(AOpb, 8);
    if (LFloor.FClassBook[LJ] < 0) or (LFloor.FClassBook[LJ] >= ABookCount) then
      Exit(Fail);
    for LK := 0 to (1 shl LFloor.FClassSubs[LJ]) - 1 do
    begin
      LFloor.FClassSubbook[LJ][LK] := TOggBitPacker.Read(AOpb, 8) - 1;
      if (LFloor.FClassSubbook[LJ][LK] < -1) or (LFloor.FClassSubbook[LJ][LK] >= ABookCount) then
        Exit(Fail);
    end;
  end;

  LFloor.FMult := TOggBitPacker.Read(AOpb, 2) + 1;
  LRangeBits := TOggBitPacker.Read(AOpb, 4);
  if LRangeBits < 0 then
    Exit(Fail);

  LK := 0;
  for LJ := 0 to LFloor.FPartitions - 1 do
  begin
    Inc(LCount, LFloor.FClassDim[LFloor.FPartitionClass[LJ]]);
    if LCount > MAX_POSTS then
      Exit(Fail);
    while LK < LCount do
    begin
      LValue := TOggBitPacker.Read(AOpb, LRangeBits);
      LFloor.FPostList[LK + 2] := LValue;
      if (LValue < 0) or (LValue >= (1 shl LRangeBits)) then
        Exit(Fail);
      Inc(LK);
    end;
  end;
  LFloor.FPostList[0] := 0;
  LFloor.FPostList[1] := 1 shl LRangeBits;

  // a repeated value in the list of the posts would make a segment of no length
  SetLength(LSorted, LCount + 2);
  for LJ := 0 to LCount + 1 do
    LSorted[LJ] := LFloor.FPostList[LJ];
  TArray.Sort<Integer>(LSorted);
  for LJ := 1 to LCount + 1 do
    if LSorted[LJ - 1] = LSorted[LJ] then
      Exit(Fail);

  LFloor.Prepare;
  Result := LFloor;
end;

procedure TVorbisFloor1.Prepare;
var
  LI, LJ, LN, LLo, LHi, LLx, LHx, LCurrentX, LX: Integer;
  LIndex: TArray<Integer>;
begin
  LN := 0;
  for LI := 0 to FPartitions - 1 do
    Inc(LN, FClassDim[FPartitionClass[LI]]);
  Inc(LN, 2);
  FPosts := LN;

  // the posts in the order of their position
  SetLength(LIndex, LN);
  for LI := 0 to LN - 1 do
    LIndex[LI] := LI;
  TArray.Sort<Integer>(LIndex, TComparer<Integer>.Construct(
    function(const ALeft, ARight: Integer): Integer
    begin
      Result := FPostList[ALeft] - FPostList[ARight];
    end));
  for LI := 0 to LN - 1 do
    FForwardIndex[LI] := LIndex[LI];

  case FMult of
    1: FQuantQ := 256;
    2: FQuantQ := 128;
    3: FQuantQ := 86;
    4: FQuantQ := 64;
  end;

  // the neighbours of each post, the nearest already decoded ones
  for LI := 0 to LN - 3 do
  begin
    LLo := 0;
    LHi := 1;
    LLx := 0;
    LHx := FPostList[1];
    LCurrentX := FPostList[LI + 2];
    for LJ := 0 to LI + 1 do
    begin
      LX := FPostList[LJ];
      if (LX > LLx) and (LX < LCurrentX) then
      begin
        LLo := LJ;
        LLx := LX;
      end;
      if (LX < LHx) and (LX > LCurrentX) then
      begin
        LHi := LJ;
        LHx := LX;
      end;
    end;
    FLoNeighbor[LI] := LLo;
    FHiNeighbor[LI] := LHi;
  end;
end;

class function TVorbisFloor1.RenderPoint(AX0, AX1, AY0, AY1, AX: Integer): Integer;
var
  LDy, LAdx, LAdy, LErr, LOff: Integer;
begin
  AY0 := AY0 and $7FFF;
  AY1 := AY1 and $7FFF;
  LDy := AY1 - AY0;
  LAdx := AX1 - AX0;
  LAdy := Abs(LDy);
  LErr := LAdy * (AX - AX0);
  LOff := LErr div LAdx;
  if LDy < 0 then
    Result := AY0 - LOff
  else
    Result := AY0 + LOff;
end;

class procedure TVorbisFloor1.RenderLine(AN, AX0, AX1, AY0, AY1: Integer;
  AOut: PSingle);
var
  LDy, LAdx, LAdy, LBase, LSy, LX, LY, LErr: Integer;
begin
  LDy := AY1 - AY0;
  LAdx := AX1 - AX0;
  LAdy := Abs(LDy);
  LBase := LDy div LAdx;
  if LDy < 0 then
    LSy := LBase - 1
  else
    LSy := LBase + 1;
  LX := AX0;
  LY := AY0;
  LErr := 0;

  Dec(LAdy, Abs(LBase * LAdx));

  if AN > AX1 then
    AN := AX1;

  if LX < AN then
    AOut[LX] := AOut[LX] * FLOOR1_FROM_DB[LY];

  Inc(LX);
  while LX < AN do
  begin
    LErr := LErr + LAdy;
    if LErr >= LAdx then
    begin
      Dec(LErr, LAdx);
      Inc(LY, LSy);
    end
    else
      Inc(LY, LBase);
    AOut[LX] := AOut[LX] * FLOOR1_FROM_DB[LY];
    Inc(LX);
  end;
end;

function TVorbisFloor1.Inverse1(const AOpb: POggPackBuffer;
  const ABooks: TArray<TVorbisCodebook>): TArray<Integer>;
var
  LFitValue: TArray<Integer>;
  LI, LJ, LK, LClass, LDim, LSubBits, LSub, LCval, LBook, LPredicted, LHiRoom,
  LLoRoom, LRoom, LVal: Integer;
begin
  Result := nil;
  if TOggBitPacker.Read(AOpb, 1) <> 1 then
    Exit;

  SetLength(LFitValue, FPosts);
  LFitValue[0] := TOggBitPacker.Read(AOpb, OvIlog(Cardinal(FQuantQ - 1)));
  LFitValue[1] := TOggBitPacker.Read(AOpb, OvIlog(Cardinal(FQuantQ - 1)));

  LJ := 2;
  for LI := 0 to FPartitions - 1 do
  begin
    LClass := FPartitionClass[LI];
    LDim := FClassDim[LClass];
    LSubBits := FClassSubs[LClass];
    LSub := 1 shl LSubBits;
    LCval := 0;

    if LSubBits <> 0 then
    begin
      LCval := ABooks[FClassBook[LClass]].Decode(AOpb);
      if LCval = -1 then
        Exit;
    end;

    for LK := 0 to LDim - 1 do
    begin
      LBook := FClassSubbook[LClass][LCval and (LSub - 1)];
      LCval := LCval shr LSubBits;
      if LBook >= 0 then
      begin
        LFitValue[LJ + LK] := ABooks[LBook].Decode(AOpb);
        if LFitValue[LJ + LK] = -1 then
          Exit;
      end
      else
        LFitValue[LJ + LK] := 0;
    end;
    Inc(LJ, LDim);
  end;

  // the values are the difference from a line between the neighbours
  for LI := 2 to FPosts - 1 do
  begin
    LPredicted := RenderPoint(FPostList[FLoNeighbor[LI - 2]], FPostList[FHiNeighbor[LI - 2]],
      LFitValue[FLoNeighbor[LI - 2]], LFitValue[FHiNeighbor[LI - 2]], FPostList[LI]);
    LHiRoom := FQuantQ - LPredicted;
    LLoRoom := LPredicted;
    if LHiRoom < LLoRoom then
      LRoom := LHiRoom shl 1
    else
      LRoom := LLoRoom shl 1;
    LVal := LFitValue[LI];

    if LVal <> 0 then
    begin
      if LVal >= LRoom then
      begin
        if LHiRoom > LLoRoom then
          LVal := LVal - LLoRoom
        else
          LVal := -1 - (LVal - LHiRoom);
      end
      else if (LVal and 1) <> 0 then
        LVal := -((LVal + 1) shr 1)
      else
        LVal := LVal shr 1;

      LFitValue[LI] := (LVal + LPredicted) and $7FFF;
      LFitValue[FLoNeighbor[LI - 2]] := LFitValue[FLoNeighbor[LI - 2]] and $7FFF;
      LFitValue[FHiNeighbor[LI - 2]] := LFitValue[FHiNeighbor[LI - 2]] and $7FFF;
    end
    else
      LFitValue[LI] := LPredicted or $8000;
  end;

  Result := LFitValue;
end;

function TVorbisFloor1.Inverse2(const AMemo: TArray<Integer>; AOut: PSingle;
  ASize: Integer): Boolean;
var
  LJ, LHx, LLx, LLy, LHy, LCurrent: Integer;
begin
  if AMemo <> nil then
  begin
    LHx := 0;
    LLx := 0;
    LLy := AMemo[0] * FMult;
    if LLy < 0 then
      LLy := 0
    else if LLy > 255 then
      LLy := 255;

    for LJ := 1 to FPosts - 1 do
    begin
      LCurrent := FForwardIndex[LJ];
      LHy := AMemo[LCurrent] and $7FFF;
      if LHy = AMemo[LCurrent] then
      begin
        LHx := FPostList[LCurrent];
        LHy := LHy * FMult;
        if LHy < 0 then
          LHy := 0
        else if LHy > 255 then
          LHy := 255;

        RenderLine(ASize, LLx, LHx, LLy, LHy, AOut);

        LLx := LHx;
        LLy := LHy;
      end;
    end;
    for LJ := LHx to ASize - 1 do
      AOut[LJ] := AOut[LJ] * FLOOR1_FROM_DB[LLy];
    Exit(True);
  end;
  FillChar(AOut^, ASize * SizeOf(Single), 0);
  Result := False;
end;

end.