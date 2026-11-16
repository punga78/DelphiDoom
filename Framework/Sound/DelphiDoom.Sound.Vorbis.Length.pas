{******************************************************************************}
{                                                                              }
{  DelphiDoom: sound decoder - Vorbis, the length of an Ogg file               }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Sound.Vorbis.Length;

interface

uses
  System.SysUtils;

type
  /// <summary>
  ///   Counts the frames of an Ogg file the way libsndfile does, by walking
  ///   its pages: the length of each logical stream is the granule position of
  ///   its last page, and the lengths of chained streams are added. The audio
  ///   itself is not decoded
  /// </summary>
  TVorbisLength = class
  public
    class function Count(const ASource: TBytes): Int64; static;
  end;

implementation

uses
  System.Generics.Collections, DelphiDoom.Ogg.Types, DelphiDoom.Ogg.Sync,
  DelphiDoom.Ogg.Stream, DelphiDoom.Ogg.PageReader, DelphiDoom.Sound.Vorbis.Info;

const
  READ_SIZE = 4096;
  BUFFER_SIZE = 4500;

type
  /// <summary>What is known of one logical stream of the file</summary>
  TStreamProcessor = class
  public
    IsIllegal: Boolean;
    ShownIllegal: Boolean;
    IsNew: Boolean;
    Ended: Boolean;
    Serial: Integer;
    Stream: TOggStreamState;
    Info: TVorbisInfo;
    LastGranulePosition: Int64;
    DoneHeaders: Integer;
    destructor Destroy; override;
    /// <summary>Adds the length of the stream to ATotal and forgets the headers</summary>
    procedure Finish(var ATotal: Int64);
  end;

  TStreamSet = class
  public
    Streams: TObjectList<TStreamProcessor>;
    InHeaders: Boolean;
    constructor Create;
    destructor Destroy; override;
    function OpenCount: Integer;
    /// <summary>The processor of the stream of a page; a new one for a stream not seen yet. Nil when its first packet is not whole</summary>
    function Find(const APage: POggPage): TStreamProcessor;
  end;

{ TStreamProcessor }

destructor TStreamProcessor.Destroy;
begin
  TOggStream.Clear(@Stream);
  Info.Free;
  inherited;
end;

procedure TStreamProcessor.Finish(var ATotal: Int64);
begin
  Inc(ATotal, LastGranulePosition);
  FreeAndNil(Info);
end;

{ TStreamSet }

constructor TStreamSet.Create;
begin
  inherited Create;
  Streams := TObjectList<TStreamProcessor>.Create(True);
end;

destructor TStreamSet.Destroy;
begin
  Streams.Free;
  inherited;
end;

function TStreamSet.OpenCount: Integer;
var
  LStream: TStreamProcessor;
begin
  Result := 0;
  for LStream in Streams do
    if not LStream.Ended then
      Inc(Result);
end;

function TStreamSet.Find(const APage: POggPage): TStreamProcessor;
var
  LSerial: Integer;
  LStream: TStreamProcessor;
  LInvalid: Boolean;
  LPacket: TOggPacket;
  LResult: Integer;
begin
  LSerial := TOggPageReader.SerialNumber(APage);

  for LStream in Streams do
    if LSerial = LStream.Serial then
    begin
      InHeaders := False;
      // a stream that has ended cannot go on
      if LStream.Ended then
      begin
        LStream.IsIllegal := True;
        Exit(LStream);
      end;
      LStream.IsNew := False;
      LStream.Ended := TOggPageReader.EndOfStream(APage) <> 0;
      LStream.Serial := LSerial;
      Exit(LStream);
    end;

  // streams are open and the headers are done: this cannot be a new one
  LInvalid := (OpenCount > 0) and not InHeaders;
  InHeaders := True;

  LStream := TStreamProcessor.Create;
  Streams.Add(LStream);
  LStream.IsNew := True;
  LStream.IsIllegal := LInvalid;

  // the header page is gone through twice, and that is right
  TOggStream.Init(@LStream.Stream, LSerial);
  TOggStream.PageIn(@LStream.Stream, APage);
  LResult := TOggStream.PacketOut(@LStream.Stream, @LPacket);
  if LResult <= 0 then
    Exit(nil);
  if (LPacket.Bytes >= 7) and CompareMem(LPacket.Packet, PAnsiChar(#1'vorbis'), 7) then
  begin
    LStream.LastGranulePosition := 0;
    LStream.Info := TVorbisInfo.Create;
  end;
  TOggStream.PacketOut(@LStream.Stream, @LPacket);

  // ready for the processing
  TOggStream.Clear(@LStream.Stream);
  TOggStream.Init(@LStream.Stream, LSerial);

  LStream.Ended := TOggPageReader.EndOfStream(APage) <> 0;
  LStream.Serial := LSerial;
  Result := LStream;
end;

{ TVorbisLength }

class function TVorbisLength.Count(const ASource: TBytes): Int64;
var
  LSync: TOggSyncState;
  LPage: TOggPage;
  LPosition: Integer;
  LSet: TStreamSet;
  LProcessor: TStreamProcessor;
  LPacket: TOggPacket;
  LHeader: Boolean;
  LGranule: Int64;
  LStream: TStreamProcessor;

  // Next page of the file; False at the end of the data
  function NextPage: Boolean;
  var
    LBuffer: PByte;
    LBytes: Integer;
  begin
    while TOggSync.PageOut(@LSync, @LPage) <= 0 do
    begin
      LBuffer := TOggSync.Buffer(@LSync, BUFFER_SIZE);
      LBytes := Length(ASource) - LPosition;
      if LBytes > READ_SIZE then
        LBytes := READ_SIZE;
      if LBytes <= 0 then
      begin
        TOggSync.Wrote(@LSync, 0);
        Exit(False);
      end;
      Move(ASource[LPosition], LBuffer^, LBytes);
      Inc(LPosition, LBytes);
      TOggSync.Wrote(@LSync, LBytes);
    end;
    Result := True;
  end;

begin
  Result := 0;
  LPosition := 0;
  TOggSync.Init(@LSync);
  LSet := TStreamSet.Create;
  try
    while NextPage do
    begin
      LProcessor := LSet.Find(@LPage);
      if LProcessor = nil then
      begin
        Result := 0;
        Break;
      end;

      if LProcessor.IsIllegal and not LProcessor.ShownIllegal then
      begin
        LProcessor.ShownIllegal := True;
        // a new stream: the page is gone through all the same
        if not LProcessor.IsNew then
          Continue;
      end;

      if not LProcessor.IsIllegal then
      begin
        TOggStream.PageIn(@LProcessor.Stream, @LPage);
        LHeader := LProcessor.DoneHeaders < 3;

        while TOggStream.PacketOut(@LProcessor.Stream, @LPacket) > 0 do
          if LProcessor.DoneHeaders < 3 then
          begin
            if LProcessor.Info = nil then
              Continue;
            if LProcessor.Info.HeaderIn(@LPacket) < 0 then
              Continue;
            Inc(LProcessor.DoneHeaders);
          end;

        if not LHeader then
        begin
          LGranule := TOggPageReader.GranulePosition(@LPage);
          if LGranule > 0 then
            LProcessor.LastGranulePosition := LGranule;
        end;
        if LProcessor.Ended then
        begin
          LProcessor.Finish(Result);
          LProcessor.IsIllegal := True;
        end;
      end;
    end;

    // the streams that did not end count too
    for LStream in LSet.Streams do
      if not LStream.Ended then
        LStream.Finish(Result);
  finally
    LSet.Free;
    TOggSync.Clear(@LSync);
  end;
end;

end.
