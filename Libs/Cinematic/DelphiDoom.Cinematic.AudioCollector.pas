{******************************************************************************}
{                                                                              }
{  DelphiDoom: cinematic library - a sink that keeps the audio                 }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Cinematic.AudioCollector;

interface

uses
  DelphiDoom.Cinematic.Intf;

type
  /// <summary>
  ///   Keeps the PCM that the decoder produces, one array per audio chunk, in the order of
  ///   the file (for a caller that wants to play it later, and for the tests)
  /// </summary>
  TRoqAudioCollector = class(TInterfacedObject, IRoqAudioSink)
  strict private
    FChunks: TArray<TArray<SmallInt>>;
    FChannels: Integer;
    FSampleRate: Integer;
    function GetChunkCount: Integer;
    function GetChunk(AIndex: Integer): TArray<SmallInt>;
  public
    procedure AudioReceived(const ASamples: TArray<SmallInt>; AChannels, ASampleRate: Integer);
    /// <summary>All the samples of all the chunks one after the other</summary>
    function AllSamples: TArray<SmallInt>;
    property ChunkCount: Integer read GetChunkCount;
    property Chunks[AIndex: Integer]: TArray<SmallInt> read GetChunk;
    /// <summary>Channels and rate of the last chunk (0 if none arrived)</summary>
    property Channels: Integer read FChannels;
    property SampleRate: Integer read FSampleRate;
  end;

implementation

{ TRoqAudioCollector }

procedure TRoqAudioCollector.AudioReceived(const ASamples: TArray<SmallInt>;
  AChannels, ASampleRate: Integer);
begin
  SetLength(FChunks, Length(FChunks) + 1);
  FChunks[High(FChunks)] := ASamples;
  FChannels := AChannels;
  FSampleRate := ASampleRate;
end;

function TRoqAudioCollector.GetChunkCount: Integer;
begin
  Result := Length(FChunks);
end;

function TRoqAudioCollector.GetChunk(AIndex: Integer): TArray<SmallInt>;
begin
  Result := FChunks[AIndex];
end;

function TRoqAudioCollector.AllSamples: TArray<SmallInt>;
var
  LChunk: TArray<SmallInt>;
  LCount: Integer;
begin
  Result := nil;
  LCount := 0;
  for LChunk in FChunks do
  begin
    SetLength(Result, LCount + Length(LChunk));
    if Length(LChunk) > 0 then
      Move(LChunk[0], Result[LCount], Length(LChunk) * SizeOf(SmallInt));
    Inc(LCount, Length(LChunk));
  end;
end;

end.
