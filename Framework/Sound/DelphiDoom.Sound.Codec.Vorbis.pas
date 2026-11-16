{******************************************************************************}
{                                                                              }
{  DelphiDoom: sound decoder - Ogg Vorbis files                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Sound.Codec.Vorbis;

interface

uses
  System.SysUtils, DelphiDoom.Ogg.Types, DelphiDoom.Sound.Vorbis.Types,
  DelphiDoom.Sound.Vorbis.Info, DelphiDoom.Sound.Vorbis.Dsp;

type
  /// <summary>
  ///   Decodes the first logical stream of an Ogg file to the end, the way
  ///   libsndfile reads it: pages are taken 4096 bytes at a time, the pages of
  ///   other streams are ignored and the first page that ends a stream ends
  ///   the reading
  /// </summary>
  TVorbisFileDecoder = class
  private
    FSource: TBytes;
    FPosition: Integer;
    FSync: TOggSyncState;
    FStream: TOggStreamState;
    FPage: TOggPage;
    FPacket: TOggPacket;
    FInfo: TVorbisInfo;
    FDsp: TVorbisDsp;
    FBlock: TVorbisBlock;
    FEndOfStream: Boolean;
    function Feed: Integer;
    procedure Release;
    procedure ProcessPackets(var AData: TArray<Single>; var AFill: Int64);
  public
    constructor Create(const ASource: TBytes);
    destructor Destroy; override;
    /// <summary>
    ///   Reads the three headers; zero or SNDFILE_ERR_MALFORMED_FILE.
    ///   Afterwards Channels and Rate say what the stream is
    /// </summary>
    function ReadHeaders: Integer;
    /// <summary>
    ///   Decodes what follows the headers. AData holds the samples of the
    ///   channels one frame after the other
    /// </summary>
    procedure Decode(out AData: TArray<Single>; out AFrames: Int64);
    function Channels: Integer;
    function Rate: Integer;
  end;

implementation

uses
  DelphiDoom.Sndfile.Intf, DelphiDoom.Ogg.Sync, DelphiDoom.Ogg.Stream,
  DelphiDoom.Ogg.PageReader;

const
  // libsndfile submits the data to the Ogg layer in blocks of this size
  CHUNK_SIZE = 4096;

{ TVorbisFileDecoder }

constructor TVorbisFileDecoder.Create(const ASource: TBytes);
begin
  inherited Create;
  FSource := ASource;
  TOggSync.Init(@FSync);
end;

destructor TVorbisFileDecoder.Destroy;
begin
  Release;
  TOggSync.Clear(@FSync);
  TOggStream.Clear(@FStream);
  inherited;
end;

procedure TVorbisFileDecoder.Release;
begin
  FreeAndNil(FDsp);
  FreeAndNil(FInfo);
end;

function TVorbisFileDecoder.Feed: Integer;
var
  LBuffer: PByte;
begin
  Result := Length(FSource) - FPosition;
  if Result > CHUNK_SIZE then
    Result := CHUNK_SIZE;
  if Result < 0 then
    Result := 0;
  LBuffer := TOggSync.Buffer(@FSync, CHUNK_SIZE);
  if Result > 0 then
    Move(FSource[FPosition], LBuffer^, Result);
  TOggSync.Wrote(@FSync, Result);
  Inc(FPosition, Result);
end;

function TVorbisFileDecoder.Channels: Integer;
begin
  if FInfo = nil then
    Result := 0
  else
    Result := FInfo.Channels;
end;

function TVorbisFileDecoder.Rate: Integer;
begin
  if FInfo = nil then
    Result := 0
  else
    Result := FInfo.Rate;
end;

function TVorbisFileDecoder.ReadHeaders: Integer;
var
  LCount, LResult: Integer;
begin
  Result := SNDFILE_ERR_MALFORMED_FILE;
  FEndOfStream := False;
  Release;
  FPosition := 0;
  TOggSync.Reset(@FSync);

  // the first page holds the identification header and says the serial number
  Feed;
  if TOggSync.PageOut(@FSync, @FPage) <> 1 then
    Exit;

  TOggStream.Clear(@FStream);
  TOggStream.Init(@FStream, TOggPageReader.SerialNumber(@FPage));
  if TOggStream.PageIn(@FStream, @FPage) < 0 then
    Exit;
  if TOggStream.PacketOut(@FStream, @FPacket) <> 1 then
    Exit;

  FInfo := TVorbisInfo.Create;
  if FInfo.HeaderIn(@FPacket) < 0 then
    Exit;

  // the comments and the setup: two packets, that may span pages
  LCount := 0;
  while LCount < 2 do
  begin
    LResult := TOggSync.PageOut(@FSync, @FPage);
    if LResult = 0 then
    begin
      if Feed = 0 then
        Exit;
    end
    else if LResult = 1 then
    begin
      TOggStream.PageIn(@FStream, @FPage);
      while LCount < 2 do
      begin
        LResult := TOggStream.PacketOut(@FStream, @FPacket);
        if LResult = 0 then
          Break;
        if LResult < 0 then
          Exit;
        FInfo.HeaderIn(@FPacket);
        Inc(LCount);
      end;
    end;
  end;

  FDsp := TVorbisDsp.Create(FInfo);
  Result := SNDFILE_OK;
end;

procedure TVorbisFileDecoder.ProcessPackets(var AData: TArray<Single>;
  var AFill: Int64);
var
  LResult, LSamples, LFrame, LChannel, LChannels: Integer;
  LChannelData: PSingle;
begin
  LChannels := FInfo.Channels;
  while True do
  begin
    LResult := TOggStream.PacketOut(@FStream, @FPacket);
    if LResult = 0 then
      Break;
    // a hole in the data: there is nothing to say about it
    if LResult < 0 then
      Continue;

    if FDsp.Synthesis(@FPacket, FBlock) = 0 then
      FDsp.BlockIn(FBlock);

    LSamples := FDsp.PcmOut;
    while LSamples > 0 do
    begin
      if AFill + Int64(LSamples) * LChannels > Length(AData) then
        SetLength(AData, (AFill + Int64(LSamples) * LChannels) * 2);
      for LChannel := 0 to LChannels - 1 do
      begin
        LChannelData := FDsp.PcmChannel(LChannel);
        for LFrame := 0 to LSamples - 1 do
          AData[AFill + Int64(LFrame) * LChannels + LChannel] := PSingleArray(LChannelData)[LFrame];
      end;
      Inc(AFill, Int64(LSamples) * LChannels);
      FDsp.Read(LSamples);
      LSamples := FDsp.PcmOut;
    end;
  end;
end;

procedure TVorbisFileDecoder.Decode(out AData: TArray<Single>; out AFrames: Int64);
var
  LFill: Int64;
  LResult: Integer;
begin
  AData := nil;
  AFrames := 0;
  LFill := 0;
  if (FInfo = nil) or (FDsp = nil) or (FInfo.Channels < 1) then
    Exit;

  // the packets left from the headers first
  ProcessPackets(AData, LFill);
  if TOggPageReader.EndOfStream(@FPage) <> 0 then
    FEndOfStream := True;

  while not FEndOfStream do
  begin
    while not FEndOfStream do
    begin
      LResult := TOggSync.PageOut(@FSync, @FPage);
      // more data is needed
      if LResult = 0 then
        Break;
      // missing or corrupt data at this page: go on
      if LResult > 0 then
      begin
        TOggStream.PageIn(@FStream, @FPage);
        ProcessPackets(AData, LFill);
        if TOggPageReader.EndOfStream(@FPage) <> 0 then
          FEndOfStream := True;
      end;
    end;
    if not FEndOfStream then
      if Feed = 0 then
        FEndOfStream := True;
  end;

  AFrames := LFill div FInfo.Channels;
  SetLength(AData, LFill);
end;

end.
