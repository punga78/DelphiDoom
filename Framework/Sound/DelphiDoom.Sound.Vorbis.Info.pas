{******************************************************************************}
{                                                                              }
{  DelphiDoom: sound decoder - Vorbis, the headers of a stream                 }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{  Derived from libvorbis by the Xiph.Org Foundation (BSD licence)             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Sound.Vorbis.Info;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.Ogg.Types,
  DelphiDoom.Sound.Vorbis.Types, DelphiDoom.Sound.Vorbis.Codebook,
  DelphiDoom.Sound.Vorbis.Floor1, DelphiDoom.Sound.Vorbis.Residue,
  DelphiDoom.Sound.Vorbis.Mapping;

type
  /// <summary>How a block is made: its size (short or long) and the mapping it uses</summary>
  TVorbisMode = record
    BlockFlag: Integer;
    WindowType: Integer;
    TransformType: Integer;
    Mapping: Integer;
  end;

  /// <summary>
  ///   What the three headers of a Vorbis stream say: the format of the sound,
  ///   the comments (only checked) and the setup of the decoder (codebooks,
  ///   floors, residues, mappings and modes). Unlike libvorbis it keeps no
  ///   state of the decoding itself: that is TVorbisDsp
  /// </summary>
  TVorbisInfo = class
  private
    FVersion: Integer;
    FChannels: Integer;
    FRate: Integer;
    FBlockSizes: array[0..1] of Integer;
    FHasSetup: Boolean;
    FHasVendor: Boolean;
    FBooks: TArray<TVorbisCodebook>;
    FFloors: TArray<TVorbisFloor1>;
    FResidues: TArray<TVorbisResidue>;
    FMappings: TArray<TVorbisMapping>;
    FModes: TArray<TVorbisMode>;
    procedure ClearSetup;
    function UnpackInfo(const AOpb: POggPackBuffer): Integer;
    function UnpackComment(const AOpb: POggPackBuffer): Integer;
    function UnpackBooks(const AOpb: POggPackBuffer): Integer;
    function GetBlockSize(AIndex: Integer): Integer;
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>
    ///   Takes one of the three header packets, in order. Zero when it is right;
    ///   an OV_ error code otherwise (and a header that is wrong in its
    ///   contents clears what was read, as libvorbis does)
    /// </summary>
    function HeaderIn(const APacket: POggPacket): Integer;
    /// <summary>Forgets everything that was read</summary>
    procedure Clear;
    property Channels: Integer read FChannels;
    property Rate: Integer read FRate;
    property HasSetup: Boolean read FHasSetup;
    property BlockSizes[AIndex: Integer]: Integer read GetBlockSize;
    property Books: TArray<TVorbisCodebook> read FBooks;
    property Floors: TArray<TVorbisFloor1> read FFloors;
    property Residues: TArray<TVorbisResidue> read FResidues;
    property Mappings: TArray<TVorbisMapping> read FMappings;
    property Modes: TArray<TVorbisMode> read FModes;
  end;

implementation

uses
  DelphiDoom.Ogg.BitPacker;

const
  // The only types the format defines: one time hook, floors 0 and 1 (0 is not
  // supported here), residues 0 to 2, one mapping, one window and one transform
  VI_TIMEB = 1;
  VI_FLOORB = 2;
  VI_RESB = 3;
  VI_MAPB = 1;
  VI_WINDOWB = 1;

{ TVorbisInfo }

constructor TVorbisInfo.Create;
begin
  inherited Create;
  FHasSetup := True;
end;

destructor TVorbisInfo.Destroy;
begin
  ClearSetup;
  inherited;
end;

procedure TVorbisInfo.ClearSetup;
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(FBooks) do
    FBooks[LIndex].Free;
  for LIndex := 0 to High(FFloors) do
    FFloors[LIndex].Free;
  for LIndex := 0 to High(FResidues) do
    FResidues[LIndex].Free;
  for LIndex := 0 to High(FMappings) do
    FMappings[LIndex].Free;
  FBooks := nil;
  FFloors := nil;
  FResidues := nil;
  FMappings := nil;
  FModes := nil;
end;

procedure TVorbisInfo.Clear;
begin
  ClearSetup;
  FVersion := 0;
  FChannels := 0;
  FRate := 0;
  FBlockSizes[0] := 0;
  FBlockSizes[1] := 0;
  FHasSetup := False;
  FHasVendor := False;
end;

function TVorbisInfo.GetBlockSize(AIndex: Integer): Integer;
begin
  Result := FBlockSizes[AIndex];
end;

function TVorbisInfo.UnpackInfo(const AOpb: POggPackBuffer): Integer;
var
  LBits: Integer;
begin
  if not FHasSetup then
    Exit(OV_EFAULT);

  FVersion := TOggBitPacker.Read(AOpb, 32);
  if FVersion <> 0 then
    Exit(OV_EVERSION);

  FChannels := TOggBitPacker.Read(AOpb, 8);
  FRate := TOggBitPacker.Read(AOpb, 32);

  // the bit rates are of no use here
  TOggBitPacker.Read(AOpb, 32);
  TOggBitPacker.Read(AOpb, 32);
  TOggBitPacker.Read(AOpb, 32);

  LBits := TOggBitPacker.Read(AOpb, 4);
  if LBits >= 0 then
  begin
    FBlockSizes[0] := 1 shl LBits;
    LBits := TOggBitPacker.Read(AOpb, 4);
    if LBits >= 0 then
      FBlockSizes[1] := 1 shl LBits;
  end;

  if (LBits < 0) or (FRate < 1) or (FChannels < 1) or (FBlockSizes[0] < 64) or
     (FBlockSizes[1] < FBlockSizes[0]) or (FBlockSizes[1] > 8192) or
     (TOggBitPacker.Read(AOpb, 1) <> 1) then
  begin
    Clear;
    Exit(OV_EBADHEADER);
  end;
  Result := 0;
end;

function TVorbisInfo.UnpackComment(const AOpb: POggPackBuffer): Integer;
var
  LVendorLength, LCount, LIndex, LLength: Integer;

  procedure Skip(ALength: Integer);
  begin
    // read the bytes as libvorbis does: one by one, so the packet's end is the same
    while ALength > 0 do
    begin
      TOggBitPacker.Read(AOpb, 8);
      Dec(ALength);
    end;
  end;

  function Fail: Integer;
  begin
    FHasVendor := False;
    Result := OV_EBADHEADER;
  end;

begin
  LVendorLength := TOggBitPacker.Read(AOpb, 32);
  if LVendorLength < 0 then
    Exit(Fail);
  if LVendorLength > AOpb.Storage - 8 then
    Exit(Fail);
  Skip(LVendorLength);
  LCount := TOggBitPacker.Read(AOpb, 32);
  if LCount < 0 then
    Exit(Fail);
  if LCount > ((AOpb.Storage - TOggBitPacker.Bytes(AOpb)) shr 2) then
    Exit(Fail);

  for LIndex := 0 to LCount - 1 do
  begin
    LLength := TOggBitPacker.Read(AOpb, 32);
    if LLength < 0 then
      Exit(Fail);
    if LLength > AOpb.Storage - TOggBitPacker.Bytes(AOpb) then
      Exit(Fail);
    Skip(LLength);
  end;
  if TOggBitPacker.Read(AOpb, 1) <> 1 then
    Exit(Fail);

  FHasVendor := True;
  Result := 0;
end;

function TVorbisInfo.UnpackBooks(const AOpb: POggPackBuffer): Integer;
var
  LI, LCount, LTest, LType: Integer;
  LMode: TVorbisMode;

  function Fail: Integer;
  begin
    Clear;
    Result := OV_EBADHEADER;
  end;

begin
  // codebooks
  LCount := TOggBitPacker.Read(AOpb, 8) + 1;
  if LCount <= 0 then
    Exit(Fail);
  SetLength(FBooks, LCount);
  for LI := 0 to LCount - 1 do
  begin
    FBooks[LI] := TVorbisCodebook.Unpack(AOpb);
    if FBooks[LI] = nil then
    begin
      // the books after the failed one were never made
      SetLength(FBooks, LI);
      Exit(Fail);
    end;
  end;

  // time domain hooks, unused
  LCount := TOggBitPacker.Read(AOpb, 6) + 1;
  if LCount <= 0 then
    Exit(Fail);
  for LI := 0 to LCount - 1 do
  begin
    LTest := TOggBitPacker.Read(AOpb, 16);
    if (LTest < 0) or (LTest >= VI_TIMEB) then
      Exit(Fail);
  end;

  // floors
  LCount := TOggBitPacker.Read(AOpb, 6) + 1;
  if LCount <= 0 then
    Exit(Fail);
  SetLength(FFloors, LCount);
  for LI := 0 to LCount - 1 do
  begin
    LType := TOggBitPacker.Read(AOpb, 16);
    if (LType < 0) or (LType >= VI_FLOORB) then
    begin
      SetLength(FFloors, LI);
      Exit(Fail);
    end;
    // floor 0 is of the first days of the format: it is not decoded here
    if LType = 0 then
    begin
      SetLength(FFloors, LI);
      Exit(Fail);
    end;
    FFloors[LI] := TVorbisFloor1.Unpack(AOpb, Length(FBooks));
    if FFloors[LI] = nil then
    begin
      SetLength(FFloors, LI);
      Exit(Fail);
    end;
  end;

  // residues
  LCount := TOggBitPacker.Read(AOpb, 6) + 1;
  if LCount <= 0 then
    Exit(Fail);
  SetLength(FResidues, LCount);
  for LI := 0 to LCount - 1 do
  begin
    LType := TOggBitPacker.Read(AOpb, 16);
    if (LType < 0) or (LType >= VI_RESB) then
    begin
      SetLength(FResidues, LI);
      Exit(Fail);
    end;
    FResidues[LI] := TVorbisResidue.Unpack(AOpb, LType, FBooks);
    if FResidues[LI] = nil then
    begin
      SetLength(FResidues, LI);
      Exit(Fail);
    end;
  end;

  // mappings
  LCount := TOggBitPacker.Read(AOpb, 6) + 1;
  if LCount <= 0 then
    Exit(Fail);
  SetLength(FMappings, LCount);
  for LI := 0 to LCount - 1 do
  begin
    LType := TOggBitPacker.Read(AOpb, 16);
    if (LType < 0) or (LType >= VI_MAPB) then
    begin
      SetLength(FMappings, LI);
      Exit(Fail);
    end;
    FMappings[LI] := TVorbisMapping.Unpack(AOpb, FChannels, Length(FFloors), Length(FResidues));
    if FMappings[LI] = nil then
    begin
      SetLength(FMappings, LI);
      Exit(Fail);
    end;
  end;

  // modes
  LCount := TOggBitPacker.Read(AOpb, 6) + 1;
  if LCount <= 0 then
    Exit(Fail);
  SetLength(FModes, LCount);
  for LI := 0 to LCount - 1 do
  begin
    LMode.BlockFlag := TOggBitPacker.Read(AOpb, 1);
    LMode.WindowType := TOggBitPacker.Read(AOpb, 16);
    LMode.TransformType := TOggBitPacker.Read(AOpb, 16);
    LMode.Mapping := TOggBitPacker.Read(AOpb, 8);
    FModes[LI] := LMode;

    if (LMode.WindowType >= VI_WINDOWB) or (LMode.TransformType >= VI_WINDOWB) or
       (LMode.Mapping >= Length(FMappings)) or (LMode.Mapping < 0) then
      Exit(Fail);
  end;

  if TOggBitPacker.Read(AOpb, 1) <> 1 then
    Exit(Fail);
  Result := 0;
end;

function TVorbisInfo.HeaderIn(const APacket: POggPacket): Integer;
var
  LOpb: TOggPackBuffer;
  LPackType, LIndex: Integer;
  LName: array[0..5] of Byte;
begin
  if APacket = nil then
    Exit(OV_EBADHEADER);

  TOggBitPacker.ReadInit(@LOpb, APacket.Packet, APacket.Bytes);

  // which of the three headers this is, and that it is Vorbis
  LPackType := TOggBitPacker.Read(@LOpb, 8);
  for LIndex := 0 to 5 do
    LName[LIndex] := Byte(TOggBitPacker.Read(@LOpb, 8));
  if not CompareMem(@LName[0], PAnsiChar('vorbis'), 6) then
    Exit(OV_ENOTVORBIS);

  case LPackType of
    $01:
      begin
        if APacket.BeginningOfStream = 0 then
          Exit(OV_EBADHEADER);
        if FRate <> 0 then
          Exit(OV_EBADHEADER);
        Result := UnpackInfo(@LOpb);
      end;
    $03:
      begin
        if FRate = 0 then
          Exit(OV_EBADHEADER);
        if FHasVendor then
          Exit(OV_EBADHEADER);
        Result := UnpackComment(@LOpb);
      end;
    $05:
      begin
        if (FRate = 0) or not FHasVendor then
          Exit(OV_EBADHEADER);
        if not FHasSetup then
          Exit(OV_EFAULT);
        if Length(FBooks) > 0 then
          Exit(OV_EBADHEADER);
        Result := UnpackBooks(@LOpb);
      end;
  else
    Result := OV_EBADHEADER;
  end;
end;

end.
