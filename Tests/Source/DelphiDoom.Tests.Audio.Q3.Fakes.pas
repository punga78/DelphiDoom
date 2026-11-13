{******************************************************************************}
{                                                                              }
{  DelphiDoom: fakes of the tests of the Quake III sound (Libs\Audio\Q3)       }
{                                                                              }
{  A clock and a device that the test moves by hand, a source of files in      }
{  memory and the FNV-1a digest of the golden files (Tests\Data\Audio\Q3).     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Audio.Q3.Fakes;

interface

uses
  System.SysUtils, System.Generics.Collections,
  DelphiDoom.Audio.Q3.Types, DelphiDoom.Audio.Q3.Intf;

type
  /// <summary>Com_Milliseconds and the frame counter, set by the test</summary>
  TQ3FakeClock = class(TInterfacedObject, IQ3SoundClock)
  public
    Milliseconds: Integer;
    FrameCount: Integer;
    function GetMilliseconds: Integer;
    function GetFrameCount: Integer;
  end;

  /// <summary>A DMA device in memory: nothing is played, the buffer is what the mixer wrote</summary>
  TQ3FakeDevice = class(TInterfacedObject, IQ3SoundDevice)
  public
    Format: TQ3DmaInfo;
    Buffer: TBytes;
    Position: Integer;
    BeginCount: Integer;
    SubmitCount: Integer;
    /// <summary>Sets the format and allocates a zeroed buffer</summary>
    procedure Configure(AChannels, ASamples, ASampleBits, ASpeed, ASubmissionChunk: Integer);
    function GetDma: TQ3DmaInfo;
    function GetBuffer: PByte;
    function GetPosition: Integer;
    procedure BeginPainting;
    procedure Submit;
  end;

  /// <summary>Files of sounds in memory, by name</summary>
  TQ3FakeFileSource = class(TInterfacedObject, IQ3SoundFileSource)
  public
    Files: TDictionary<string, TBytes>;
    Reads: Integer;
    constructor Create;
    destructor Destroy; override;
    function ReadFile(const AName: string; out ABytes: TBytes): Boolean;
  end;

  /// <summary>FNV-1a on 64 bits, as the harness of Tools\Verifica\128</summary>
  TQ3Digest = record
  strict private
    FHash: UInt64;
  public
    class function Start: TQ3Digest; static;
    procedure AddBytes(const ABuffer; ACount: Integer);
    procedure AddInteger(AValue: Integer);
    procedure AddSingle(AValue: Single);
    /// <summary>The sixteen hexadecimal digits, lower case, as printf %016llx</summary>
    function ToHex: string;
    property Hash: UInt64 read FHash;
  end;

  /// <summary>A WAV file in memory (PCM, 44 byte header)</summary>
  TQ3TestWav = class
  public
    class function Build(AChannels, ARate, ABits: Integer; const APayload: TBytes): TBytes; static;
    /// <summary>Mono 16 bit from samples</summary>
    class function Mono16(ARate: Integer; const ASamples: array of SmallInt): TBytes; static;
  end;

  /// <summary>Files of Tests\Data\Audio\Q3 and of OpenArena</summary>
  TQ3TestData = class
  public
    class function Path(const AFileName: string): string; static;
    /// <summary>
    ///   baseoa of OpenArena (Reference\openarena\openarena-0.8.8\baseoa), found from
    ///   DELPHIDOOM_OPENARENA or going up from the executable; empty if missing
    /// </summary>
    class function OpenArenaFolder: string; static;
  end;

implementation

uses
  System.Classes, System.IOUtils;

{$Q-}
{$R-}

{ TQ3FakeClock }

function TQ3FakeClock.GetMilliseconds: Integer;
begin
  Result := Milliseconds;
end;

function TQ3FakeClock.GetFrameCount: Integer;
begin
  Result := FrameCount;
end;

{ TQ3FakeDevice }

procedure TQ3FakeDevice.Configure(AChannels, ASamples, ASampleBits, ASpeed,
  ASubmissionChunk: Integer);
begin
  Format.Channels := AChannels;
  Format.Samples := ASamples;
  Format.SampleBits := ASampleBits;
  Format.Speed := ASpeed;
  Format.SubmissionChunk := ASubmissionChunk;
  SetLength(Buffer, ASamples * 2);
  if Length(Buffer) > 0 then
    FillChar(Buffer[0], Length(Buffer), 0);
end;

function TQ3FakeDevice.GetDma: TQ3DmaInfo;
begin
  Result := Format;
end;

function TQ3FakeDevice.GetBuffer: PByte;
begin
  if Length(Buffer) = 0 then
    Result := nil
  else
    Result := @Buffer[0];
end;

function TQ3FakeDevice.GetPosition: Integer;
begin
  Result := Position;
end;

procedure TQ3FakeDevice.BeginPainting;
begin
  Inc(BeginCount);
end;

procedure TQ3FakeDevice.Submit;
begin
  Inc(SubmitCount);
end;

{ TQ3FakeFileSource }

constructor TQ3FakeFileSource.Create;
begin
  inherited Create;
  Files := TDictionary<string, TBytes>.Create;
end;

destructor TQ3FakeFileSource.Destroy;
begin
  Files.Free;
  inherited Destroy;
end;

function TQ3FakeFileSource.ReadFile(const AName: string; out ABytes: TBytes): Boolean;
begin
  Inc(Reads);
  Result := Files.TryGetValue(AName, ABytes);
end;

{ TQ3Digest }

class function TQ3Digest.Start: TQ3Digest;
begin
  Result.FHash := UInt64($CBF29CE484222325);
end;

procedure TQ3Digest.AddBytes(const ABuffer; ACount: Integer);
var
  LPointer: PByte;
  LIndex: Integer;
begin
  LPointer := @ABuffer;
  for LIndex := 0 to ACount - 1 do
  begin
    FHash := FHash xor LPointer^;
    FHash := FHash * UInt64($100000001B3);
    Inc(LPointer);
  end;
end;

procedure TQ3Digest.AddInteger(AValue: Integer);
begin
  AddBytes(AValue, 4);
end;

procedure TQ3Digest.AddSingle(AValue: Single);
begin
  AddBytes(AValue, 4);
end;

function TQ3Digest.ToHex: string;
begin
  Result := LowerCase(IntToHex(FHash, 16));
end;

{ TQ3TestWav }

class function TQ3TestWav.Build(AChannels, ARate, ABits: Integer;
  const APayload: TBytes): TBytes;
var
  LStream: TBytesStream;

  procedure PutText(const AText: AnsiString);
  begin
    LStream.WriteBuffer(AText[1], Length(AText));
  end;

  procedure PutNumber(AValue: Cardinal; ACount: Integer);
  var
    LIndex: Integer;
    LByte: Byte;
  begin
    for LIndex := 0 to ACount - 1 do
    begin
      LByte := (AValue shr (8 * LIndex)) and $FF;
      LStream.WriteBuffer(LByte, 1);
    end;
  end;

begin
  LStream := TBytesStream.Create;
  try
    PutText('RIFF');
    PutNumber(36 + Length(APayload), 4);
    PutText('WAVEfmt ');
    PutNumber(16, 4);
    PutNumber(1, 2);
    PutNumber(AChannels, 2);
    PutNumber(ARate, 4);
    PutNumber(ARate * AChannels * ABits div 8, 4);
    PutNumber(AChannels * ABits div 8, 2);
    PutNumber(ABits, 2);
    PutText('data');
    PutNumber(Length(APayload), 4);
    if Length(APayload) > 0 then
      LStream.WriteBuffer(APayload[0], Length(APayload));
    Result := Copy(LStream.Bytes, 0, LStream.Size);
  finally
    LStream.Free;
  end;
end;

class function TQ3TestWav.Mono16(ARate: Integer; const ASamples: array of SmallInt): TBytes;
var
  LPayload: TBytes;
  LIndex: Integer;
begin
  SetLength(LPayload, Length(ASamples) * 2);
  for LIndex := 0 to High(ASamples) do
  begin
    LPayload[LIndex * 2] := Word(ASamples[LIndex]) and $FF;
    LPayload[LIndex * 2 + 1] := Word(ASamples[LIndex]) shr 8;
  end;
  Result := Build(1, ARate, 16, LPayload);
end;

{ TQ3TestData }

class function TQ3TestData.Path(const AFileName: string): string;
begin
  Result := TPath.GetFullPath(ExtractFilePath(ParamStr(0)) + '..\..\Tests\Data\Audio\Q3\' +
    AFileName);
end;

class function TQ3TestData.OpenArenaFolder: string;
const
  RELATIVE = 'Reference\openarena\openarena-0.8.8\baseoa';
var
  LFolder, LCandidate: string;
  LLevel: Integer;
begin
  Result := '';
  LFolder := GetEnvironmentVariable('DELPHIDOOM_OPENARENA');
  if (LFolder <> '') and TDirectory.Exists(LFolder) then
    Exit(LFolder);
  LFolder := ExtractFilePath(ParamStr(0));
  for LLevel := 1 to 8 do
  begin
    LCandidate := TPath.GetFullPath(LFolder + RELATIVE);
    if TDirectory.Exists(LCandidate) then
      Exit(LCandidate);
    // a worktree keeps Reference in the main checkout, three levels up from the repository
    LCandidate := TPath.GetFullPath(LFolder + '..\..\..\' + RELATIVE);
    if TDirectory.Exists(LCandidate) then
      Exit(LCandidate);
    LFolder := TPath.GetFullPath(LFolder + '..\');
  end;
end;

end.
