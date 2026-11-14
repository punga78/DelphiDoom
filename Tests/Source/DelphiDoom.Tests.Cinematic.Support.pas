{******************************************************************************}
{                                                                              }
{  DelphiDoom: helpers of the tests of the cinematic library                   }
{                                                                              }
{  Builds small RoQ files in memory (a minimal encoder: codebook, frames made  }
{  of the codes of the format, audio) and reads the data of the parity tests   }
{  (Tests\Data\Cinematic).                                                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Cinematic.Support;

interface

uses
  System.SysUtils, System.Classes,
  DelphiDoom.Cinematic.Types,
  DelphiDoom.Cinematic.Intf;

type
  /// <summary>Makes the bytes of a RoQ file chunk by chunk</summary>
  TRoqTestBuilder = class
  strict private
    FBytes: TBytes;
    FCodes: Integer;
    FSlot: Integer;
    FWord: Integer;
    FFrame: TBytes;
    procedure Append(var ATarget: TBytes; const AData: TBytes);
  public
    constructor Create(AFramesPerSecond: Integer = 24);
    procedure Chunk(AId, AFlags: Integer; const AData: TBytes);
    procedure Info(AWidth, AHeight: Integer);
    /// <summary>A codebook of ATwo 2x2 vectors (Y0..Y3 = 10, 80, 150, 220 plus the index, Cr 100, Cb 160) and AFour 4x4 ones, all made of vector 0</summary>
    procedure Codebook(ATwo, AFour: Integer);
    /// <summary>The data of the chunk made by Codebook</summary>
    class function CodebookData(ATwo, AFour: Integer): TBytes; static;
    /// <summary>Starts the data of a frame</summary>
    procedure BeginFrame;
    /// <summary>Adds a code of two bits (0 skip, 1 motion, 2 vq, 3 split) and its bytes</summary>
    procedure Code(ACode: Integer; const APayload: array of Byte);
    /// <summary>Writes the frame with the flags of the offsets</summary>
    procedure EndFrame(AOffsetX: Integer = 0; AOffsetY: Integer = 0);
    /// <summary>Four 8x8 blocks of the macroblock 16x16 with the same vector</summary>
    procedure FullFrame16(AVector: Integer; AOffsetX: Integer = 0; AOffsetY: Integer = 0);
    function ToBytes: TBytes;
    /// <summary>The data of the frame that is being written</summary>
    function FrameBytes: TBytes;
    class function Bytes(const AValues: array of Byte): TBytes; static;
  end;

  /// <summary>Counts what arrives to an audio sink</summary>
  TRoqRecordingSink = class(TInterfacedObject, IRoqAudioSink)
  public
    Chunks: TArray<TArray<SmallInt>>;
    Channels: TArray<Integer>;
    Rates: TArray<Integer>;
    procedure AudioReceived(const ASamples: TArray<SmallInt>; AChannels, ASampleRate: Integer);
  end;

  /// <summary>Files of Tests\Data\Cinematic</summary>
  TRoqTestData = class
  public
    class function Path(const AFileName: string): string; static;
    class function ReadBytes(const AFileName: string): TBytes; static;
    class function ReadLines(const AFileName: string): TStringList; static;
    /// <summary>A file of Tests\Data\Jpeg (the JPEG files of the tests of Libs\Jpeg)</summary>
    class function ReadJpeg(const AFileName: string): TBytes; static;
  end;

function PixelsCrc(const APixels: TArray<Cardinal>): Cardinal;
function SamplesCrc(const ASamples: TArray<SmallInt>): Cardinal;

implementation

uses
  System.IOUtils,
  DelphiDoom.MathCore.Crc32,
  DelphiDoom.Cinematic.YuvConverter;

{ TRoqTestBuilder }

constructor TRoqTestBuilder.Create(AFramesPerSecond: Integer);
begin
  inherited Create;
  Append(FBytes, Bytes([$84, $10, $FF, $FF, $FF, $FF, AFramesPerSecond and $FF,
    AFramesPerSecond shr 8]));
end;

class function TRoqTestBuilder.Bytes(const AValues: array of Byte): TBytes;
var
  LIndex: Integer;
begin
  SetLength(Result, Length(AValues));
  for LIndex := 0 to High(AValues) do
    Result[LIndex] := AValues[LIndex];
end;

procedure TRoqTestBuilder.Append(var ATarget: TBytes; const AData: TBytes);
var
  LOld: Integer;
begin
  LOld := Length(ATarget);
  SetLength(ATarget, LOld + Length(AData));
  if Length(AData) > 0 then
    Move(AData[0], ATarget[LOld], Length(AData));
end;

procedure TRoqTestBuilder.Chunk(AId, AFlags: Integer; const AData: TBytes);
var
  LSize: Integer;
begin
  LSize := Length(AData);
  Append(FBytes, Bytes([AId and $FF, AId shr 8, LSize and $FF, (LSize shr 8) and $FF,
    (LSize shr 16) and $FF, (LSize shr 24) and $FF, AFlags and $FF, (AFlags shr 8) and $FF]));
  Append(FBytes, AData);
end;

procedure TRoqTestBuilder.Info(AWidth, AHeight: Integer);
begin
  Chunk(ROQ_QUAD_INFO, 0, Bytes([AWidth and $FF, AWidth shr 8, AHeight and $FF, AHeight shr 8,
    8, 0, 4, 0]));
end;

procedure TRoqTestBuilder.Codebook(ATwo, AFour: Integer);
begin
  Chunk(ROQ_CODEBOOK, (ATwo shl 8) or AFour, CodebookData(ATwo, AFour));
end;

class function TRoqTestBuilder.CodebookData(ATwo, AFour: Integer): TBytes;
var
  LData: TBytes;
  LIndex: Integer;
begin
  SetLength(LData, ATwo * 6 + AFour * 4);
  for LIndex := 0 to ATwo - 1 do
  begin
    LData[LIndex * 6] := 10 + LIndex;
    LData[LIndex * 6 + 1] := 80 + LIndex;
    LData[LIndex * 6 + 2] := 150 + LIndex;
    LData[LIndex * 6 + 3] := 220 + LIndex;
    LData[LIndex * 6 + 4] := 100;
    LData[LIndex * 6 + 5] := 160;
  end;
  // the pairs of 2x2 vectors that make the 4x4 ones: byte j is (j + j div 4) mod ATwo, so the
  // vectors differ from each other when there are two vectors or more
  for LIndex := 0 to AFour * 4 - 1 do
    LData[ATwo * 6 + LIndex] := (LIndex + LIndex div 4) mod ATwo;
  Result := LData;
end;

procedure TRoqTestBuilder.BeginFrame;
begin
  FFrame := nil;
  FCodes := 0;
end;

procedure TRoqTestBuilder.Code(ACode: Integer; const APayload: array of Byte);
var
  LIndex: Integer;
begin
  if FCodes and 7 = 0 then
  begin
    FSlot := Length(FFrame);
    SetLength(FFrame, Length(FFrame) + 2);
    FWord := 0;
  end;
  FWord := FWord or ((ACode and 3) shl (14 - 2 * (FCodes and 7)));
  FFrame[FSlot] := FWord and $FF;
  FFrame[FSlot + 1] := FWord shr 8;
  Inc(FCodes);
  for LIndex := 0 to High(APayload) do
  begin
    SetLength(FFrame, Length(FFrame) + 1);
    FFrame[High(FFrame)] := APayload[LIndex];
  end;
end;

procedure TRoqTestBuilder.EndFrame(AOffsetX, AOffsetY: Integer);
begin
  Chunk(ROQ_QUAD_VQ, ((AOffsetX and $FF) shl 8) or (AOffsetY and $FF), FFrame);
end;

procedure TRoqTestBuilder.FullFrame16(AVector, AOffsetX, AOffsetY: Integer);
var
  LBlock: Integer;
begin
  BeginFrame;
  for LBlock := 0 to 3 do
    Code(2, [AVector]);
  EndFrame(AOffsetX, AOffsetY);
end;

function TRoqTestBuilder.ToBytes: TBytes;
begin
  Result := Copy(FBytes);
end;

function TRoqTestBuilder.FrameBytes: TBytes;
begin
  Result := Copy(FFrame);
end;

{ TRoqRecordingSink }

procedure TRoqRecordingSink.AudioReceived(const ASamples: TArray<SmallInt>;
  AChannels, ASampleRate: Integer);
begin
  SetLength(Chunks, Length(Chunks) + 1);
  Chunks[High(Chunks)] := ASamples;
  SetLength(Channels, Length(Channels) + 1);
  Channels[High(Channels)] := AChannels;
  SetLength(Rates, Length(Rates) + 1);
  Rates[High(Rates)] := ASampleRate;
end;

{ TRoqTestData }

class function TRoqTestData.Path(const AFileName: string): string;
begin
  Result := TPath.GetFullPath(ExtractFilePath(ParamStr(0)) + '..\..\..\..\Tests\Data\Cinematic\' +
    AFileName);
end;

class function TRoqTestData.ReadBytes(const AFileName: string): TBytes;
begin
  Result := TFile.ReadAllBytes(Path(AFileName));
end;

class function TRoqTestData.ReadJpeg(const AFileName: string): TBytes;
begin
  Result := TFile.ReadAllBytes(TPath.GetFullPath(ExtractFilePath(ParamStr(0)) +
    '..\..\..\..\Tests\Data\Jpeg\' + AFileName));
end;

class function TRoqTestData.ReadLines(const AFileName: string): TStringList;
begin
  Result := TStringList.Create;
  try
    Result.LoadFromFile(Path(AFileName));
  except
    Result.Free;
    raise;
  end;
end;

function PixelsCrc(const APixels: TArray<Cardinal>): Cardinal;
begin
  if Length(APixels) = 0 then
    Exit(TCrc32.Calculate(Result, 0));
  Result := TCrc32.Calculate(APixels[0], Length(APixels) * SizeOf(Cardinal));
end;

function SamplesCrc(const ASamples: TArray<SmallInt>): Cardinal;
begin
  if Length(ASamples) = 0 then
    Exit(TCrc32.Calculate(Result, 0));
  Result := TCrc32.Calculate(ASamples[0], Length(ASamples) * SizeOf(SmallInt));
end;

end.
