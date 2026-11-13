{******************************************************************************}
{                                                                              }
{  DelphiDoom: parity of the Quake III sound with the C (DUnitX)               }
{                                                                              }
{  Runs the scripts of Tests\Data\Audio\Q3 (made and answered by the code of   }
{  snd_dma.c, snd_mix.c and snd_mem.c compiled with gcc: Tools\Verifica\128)   }
{  and compares every line: digests of the channels, of the loop channels, of  }
{  the DMA buffer and of the raw stream, times, volumes of S_SpatializeOrigin. }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Audio.Q3.Parity;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework;

type
  [TestFixture]
  [Category('Audio.Q3')]
  TTestQ3Parity = class
  strict private
    procedure CompareWithGolden(const AScenario: string);
  public
    [Test]
    procedure DovrebbeDareGliStessiRisultatiDelCConDmaStereo16;
    [Test]
    procedure DovrebbeDareGliStessiRisultatiDelCConDmaMono8Bit;
    [Test]
    procedure DovrebbeDareGliStessiRisultatiDelCConBloccoDiInvioPiccolo;
    [Test]
    procedure DovrebbeDareGliStessiRisultatiDelCConDmaStereo8BitEDoppler;
    [Test]
    procedure DovrebbeDareGliStessiRisultatiDelCConTuttiICanaliOccupati;
  end;

implementation

uses
  System.IOUtils, System.Generics.Collections,
  DelphiDoom.Audio.Q3.Types, DelphiDoom.Audio.Q3.Sfx, DelphiDoom.Audio.Q3.Intf,
  DelphiDoom.Audio.Q3.State, DelphiDoom.Audio.Q3.Resampler, DelphiDoom.Audio.Q3.SfxRegistry,
  DelphiDoom.Audio.Q3.Listener, DelphiDoom.Audio.Q3.ChannelPool,
  DelphiDoom.Audio.Q3.LoopSounds, DelphiDoom.Audio.Q3.RawStream, DelphiDoom.Audio.Q3.Mixer,
  DelphiDoom.Audio.Q3.Scheduler, DelphiDoom.Audio.Q3.SoundSystem,
  DelphiDoom.Tests.Audio.Q3.Fakes;

{$Q-}
{$R-}

type
  /// <summary>Runs one script on the Pascal classes and returns the lines the C driver prints</summary>
  TQ3ScriptRunner = class
  strict private
    FClockObject: TQ3FakeClock;
    FClock: IQ3SoundClock;
    FDeviceObject: TQ3FakeDevice;
    FDevice: IQ3SoundDevice;
    FState: TQ3SoundState;
    FRegistry: TQ3SfxRegistry;
    FListener: TQ3Listener;
    FPool: TQ3ChannelPool;
    FLoops: TQ3LoopSounds;
    FRaw: TQ3RawStream;
    FMixer: TQ3Mixer;
    FScheduler: TQ3Scheduler;
    FSystem: TQ3SoundSystem;
    FLcg: Cardinal;
    FOutput: TStringList;
    FOp: Integer;
    FTokens: TArray<string>;
    function Lcg: Cardinal;
    function Int(AIndex: Integer): Integer;
    function Bits(AIndex: Integer): Single;
    function Vec(AIndex: Integer): TQ3Vec3;
    function SfxIndex(ASfx: TQ3Sfx): Integer;
    function DigestChannels: string;
    function DigestLoops: string;
    function DigestDma: string;
    function DigestRaw: string;
    procedure PrintState;
    procedure Execute;
  public
    constructor Create;
    destructor Destroy; override;
    function Run(const AScript: TStrings): TStringList;
  end;

{ TQ3ScriptRunner }

constructor TQ3ScriptRunner.Create;
begin
  inherited Create;
  FClockObject := TQ3FakeClock.Create;
  FClock := FClockObject;
  FDeviceObject := TQ3FakeDevice.Create;
  FDevice := FDeviceObject;
  FState := TQ3SoundState.Create;
  FRegistry := TQ3SfxRegistry.Create(FState, nil, nil);
  FListener := TQ3Listener.Create;
  FPool := TQ3ChannelPool.Create(FState, FClock, FListener);
  FLoops := TQ3LoopSounds.Create(FState, FListener, FClock);
  FRaw := TQ3RawStream.Create(FState);
  FMixer := TQ3Mixer.Create(FState, FDevice);
  FScheduler := TQ3Scheduler.Create(FState, FDevice, FClock, FPool, FMixer,
    procedure
    begin
      FSystem.StopAllSounds;
    end);
  FSystem := TQ3SoundSystem.Create(FState, FDevice, FRegistry, FListener, FPool, FLoops, FRaw,
    FMixer, FScheduler);
  FOutput := TStringList.Create;
end;

destructor TQ3ScriptRunner.Destroy;
begin
  FOutput.Free;
  FSystem.Free;
  FScheduler.Free;
  FMixer.Free;
  FRaw.Free;
  FLoops.Free;
  FPool.Free;
  FListener.Free;
  FRegistry.Free;
  FState.Free;
  inherited Destroy;
end;

function TQ3ScriptRunner.Lcg: Cardinal;
begin
  FLcg := FLcg * 1103515245 + 12345;
  Result := FLcg shr 16;
end;

function TQ3ScriptRunner.Int(AIndex: Integer): Integer;
begin
  Result := StrToInt64(FTokens[AIndex]) and $FFFFFFFF;
end;

function TQ3ScriptRunner.Bits(AIndex: Integer): Single;
var
  LBits: Cardinal;
begin
  LBits := StrToUInt('$' + FTokens[AIndex]);
  Result := PSingle(@LBits)^;
end;

function TQ3ScriptRunner.Vec(AIndex: Integer): TQ3Vec3;
begin
  Result[0] := Bits(AIndex);
  Result[1] := Bits(AIndex + 1);
  Result[2] := Bits(AIndex + 2);
end;

function TQ3ScriptRunner.SfxIndex(ASfx: TQ3Sfx): Integer;
begin
  if ASfx = nil then
    Result := -1
  else
    Result := StrToInt(Copy(ASfx.Name, 2, MaxInt));
end;

function TQ3ScriptRunner.DigestChannels: string;
var
  LDigest: TQ3Digest;
  LIndex: Integer;
begin
  LDigest := TQ3Digest.Start;
  for LIndex := 0 to Q3_MAX_CHANNELS - 1 do
    with FState.Channels[LIndex] do
    begin
      if Sfx = nil then
        Continue;
      LDigest.AddInteger(LIndex);
      LDigest.AddInteger(AllocTime);
      LDigest.AddInteger(StartSample);
      LDigest.AddInteger(EntityNumber);
      LDigest.AddInteger(EntityChannel);
      LDigest.AddInteger(LeftVolume);
      LDigest.AddInteger(RightVolume);
      LDigest.AddInteger(MasterVolume);
      LDigest.AddInteger(Ord(FixedOrigin));
      if FixedOrigin then
      begin
        LDigest.AddSingle(Origin[0]);
        LDigest.AddSingle(Origin[1]);
        LDigest.AddSingle(Origin[2]);
      end;
      LDigest.AddInteger(SfxIndex(Sfx));
      LDigest.AddInteger(Ord(Doppler));
    end;
  Result := LDigest.ToHex;
end;

function TQ3ScriptRunner.DigestLoops: string;
var
  LDigest: TQ3Digest;
  LIndex: Integer;
begin
  LDigest := TQ3Digest.Start;
  LDigest.AddInteger(FState.NumLoopChannels);
  for LIndex := 0 to FState.NumLoopChannels - 1 do
    with FState.LoopChannels[LIndex] do
    begin
      LDigest.AddInteger(MasterVolume);
      LDigest.AddInteger(LeftVolume);
      LDigest.AddInteger(RightVolume);
      LDigest.AddInteger(SfxIndex(Sfx));
      LDigest.AddInteger(Ord(Doppler));
      LDigest.AddSingle(DopplerScale);
      LDigest.AddSingle(OldDopplerScale);
    end;
  Result := LDigest.ToHex;
end;

function TQ3ScriptRunner.DigestDma: string;
var
  LDigest: TQ3Digest;
begin
  LDigest := TQ3Digest.Start;
  LDigest.AddBytes(FDeviceObject.Buffer[0], FState.Dma.Samples * FState.Dma.SampleBits div 8);
  Result := LDigest.ToHex;
end;

function TQ3ScriptRunner.DigestRaw: string;
var
  LDigest: TQ3Digest;
begin
  LDigest := TQ3Digest.Start;
  LDigest.AddBytes(FState.RawSamples[0], SizeOf(FState.RawSamples));
  Result := LDigest.ToHex;
end;

procedure TQ3ScriptRunner.PrintState;
var
  LIndex, LActive, LDoppler: Integer;
begin
  LActive := 0;
  LDoppler := 0;
  for LIndex := 0 to Q3_MAX_CHANNELS - 1 do
    if FState.Channels[LIndex].Sfx <> nil then
      Inc(LActive);
  for LIndex := 0 to FState.NumLoopChannels - 1 do
    if FState.LoopChannels[LIndex].Doppler then
      Inc(LDoppler);
  FOutput.Add(Format('op %d chan %s loop %s active %d num %d doppler %d painted %d ' +
    'soundtime %d rawend %d', [FOp, DigestChannels, DigestLoops, LActive,
    FState.NumLoopChannels, LDoppler, FState.PaintedTime, FState.SoundTime, FState.RawEnd]));
  if GetEnvironmentVariable('Q3SND_VERBOSE') <> '' then
    for LIndex := 0 to FState.NumLoopChannels - 1 do
      with FState.LoopChannels[LIndex] do
        FOutput.Add(Format('  loop %d master %d left %d right %d sfx %d doppler %d scale %s old %s',
          [LIndex, MasterVolume, LeftVolume, RightVolume, SfxIndex(Sfx), Ord(Doppler),
          LowerCase(IntToHex(PCardinal(@DopplerScale)^, 8)),
          LowerCase(IntToHex(PCardinal(@OldDopplerScale)^, 8))]));
end;

procedure TQ3ScriptRunner.Execute;
var
  LWord: string;
  LIndex, LCount, LWidth, LChannels, LLeft, LRight: Integer;
  LData: TBytes;
  LSamples: TArray<SmallInt>;
  LOrigin: TQ3Vec3;
  LAxis: TQ3Axis;
begin
  LWord := FTokens[0];
  if LWord = 'dma' then
    FDeviceObject.Configure(Int(1), Int(2), Int(3), Int(4), Int(5))
  else if LWord = 'cvar' then
  begin
    FState.Volume := Bits(1);
    FState.MixAhead := Bits(2);
    FState.MixPreStep := Bits(3);
    FState.Doppler := Int(4);
    FState.TestSound := Int(5);
  end
  else if LWord = 'sfx' then
  begin
    LCount := Int(4);
    LWidth := Int(3);
    FLcg := Cardinal(StrToInt64(FTokens[5]));
    SetLength(LData, LCount * LWidth);
    for LIndex := 0 to High(LData) do
      LData[LIndex] := Byte(Lcg);
    LSamples := TQ3Resampler.ResampleBytes(LData, 0, LCount, Int(2), LWidth,
      FDeviceObject.Format.Speed);
    FRegistry.AddSound('s' + Int(1).ToString, LSamples, Length(LSamples));
    FOutput.Add(Format('op %d sfx %d length %d', [FOp, Int(1), Length(LSamples)]));
  end
  else if LWord = 'init' then
  begin
    FSystem.Init;
    FSystem.BeginRegistration;
    PrintState;
  end
  else if LWord = 'time' then
  begin
    FClockObject.Milliseconds := Int(1);
    FClockObject.FrameCount := Int(2);
    PrintState;
  end
  else if LWord = 'dmapos' then
  begin
    FDeviceObject.Position := Int(1);
    PrintState;
  end
  else if LWord = 'listener' then
  begin
    LOrigin := Vec(2);
    for LIndex := 0 to 8 do
      LAxis[LIndex div 3][LIndex mod 3] := Bits(5 + LIndex);
    FSystem.Respatialize(Int(1), LOrigin, LAxis, 0);
    PrintState;
  end
  else if LWord = 'entpos' then
  begin
    FSystem.UpdateEntityPosition(Int(1), Vec(2));
    PrintState;
  end
  else if LWord = 'start' then
  begin
    LOrigin := Vec(5);
    if Int(4) <> 0 then
      FSystem.StartSound(@LOrigin, Int(1), Int(2), Int(3))
    else
      FSystem.StartSound(nil, Int(1), Int(2), Int(3));
    PrintState;
  end
  else if LWord = 'local' then
  begin
    FSystem.StartLocalSound(Int(1), Int(2));
    PrintState;
  end
  else if (LWord = 'loop') or (LWord = 'rloop') then
  begin
    if LWord = 'loop' then
      FSystem.AddLoopingSound(Int(1), Vec(3), Vec(6), Int(2))
    else
      FSystem.AddRealLoopingSound(Int(1), Vec(3), Vec(6), Int(2));
    PrintState;
  end
  else if LWord = 'clearloop' then
  begin
    FSystem.ClearLoopingSounds(Int(1) <> 0);
    PrintState;
  end
  else if LWord = 'stoploop' then
  begin
    FSystem.StopLoopingSound(Int(1));
    PrintState;
  end
  else if LWord = 'raw' then
  begin
    LCount := Int(1);
    LWidth := Int(3);
    LChannels := Int(4);
    FLcg := Cardinal(StrToInt64(FTokens[5]));
    SetLength(LData, LCount * LWidth * LChannels);
    for LIndex := 0 to High(LData) do
      LData[LIndex] := Byte(Lcg);
    FSystem.RawSamples(LCount, Int(2), LWidth, LChannels, PByte(LData), Bits(6));
    PrintState;
    FOutput.Add(Format('op %d raw %s', [FOp, DigestRaw]));
  end
  else if LWord = 'spatial' then
  begin
    LOrigin := Vec(1);
    FListener.SpatializeOrigin(LOrigin, Int(4), FState.Dma.Channels, LLeft, LRight);
    FOutput.Add(Format('op %d spatial %d %d', [FOp, LLeft, LRight]));
  end
  else if LWord = 'clearbuf' then
  begin
    FSystem.ClearSoundBuffer;
    PrintState;
    FOutput.Add(Format('op %d dma %s', [FOp, DigestDma]));
  end
  else if LWord = 'update' then
  begin
    FSystem.Update;
    PrintState;
    FOutput.Add(Format('op %d dma %s', [FOp, DigestDma]));
  end
  else if LWord = 'paint' then
  begin
    FMixer.PaintChannels(FState.PaintedTime + Int(1));
    PrintState;
    FOutput.Add(Format('op %d dma %s', [FOp, DigestDma]));
  end
  else
    raise Exception.CreateFmt('Unknown script word %s', [LWord]);
end;

function TQ3ScriptRunner.Run(const AScript: TStrings): TStringList;
var
  LLine: string;
begin
  FOp := 0;
  for LLine in AScript do
  begin
    if Trim(LLine) = '' then
      Continue;
    Inc(FOp);
    FTokens := Trim(LLine).Split([' ']);
    Execute;
  end;
  Result := FOutput;
end;

{ TTestQ3Parity }

procedure TTestQ3Parity.CompareWithGolden(const AScenario: string);
var
  LScript, LGolden: TStringList;
  LRunner: TQ3ScriptRunner;
  LResult: TStringList;
  LIndex: Integer;
begin
  LScript := TStringList.Create;
  LGolden := TStringList.Create;
  LRunner := TQ3ScriptRunner.Create;
  try
    LScript.LoadFromFile(TQ3TestData.Path(AScenario + '.script.txt'));
    LGolden.LoadFromFile(TQ3TestData.Path(AScenario + '.golden.txt'));
    LResult := LRunner.Run(LScript);
    // Q3SND_DUMP=<folder> writes what the Pascal classes did, to compare it with q3snd run
    if GetEnvironmentVariable('Q3SND_DUMP') <> '' then
      LResult.SaveToFile(TPath.Combine(GetEnvironmentVariable('Q3SND_DUMP'), AScenario + '.pascal.txt'));
    for LIndex := 0 to LGolden.Count - 1 do
    begin
      if LIndex >= LResult.Count then
        Assert.Fail(Format('%s: the output ends at line %d of %d', [AScenario, LIndex + 1,
          LGolden.Count]));
      if LResult[LIndex] <> LGolden[LIndex] then
        Assert.Fail(Format('%s, line %d: expected "%s" but got "%s"', [AScenario, LIndex + 1,
          LGolden[LIndex], LResult[LIndex]]));
    end;
    Assert.AreEqual(LGolden.Count, LResult.Count, AScenario + ': extra lines');
  finally
    LRunner.Free;
    LGolden.Free;
    LScript.Free;
  end;
end;

procedure TTestQ3Parity.DovrebbeDareGliStessiRisultatiDelCConDmaStereo16;
begin
  CompareWithGolden('scenario0');
end;

procedure TTestQ3Parity.DovrebbeDareGliStessiRisultatiDelCConDmaMono8Bit;
begin
  CompareWithGolden('scenario1');
end;

procedure TTestQ3Parity.DovrebbeDareGliStessiRisultatiDelCConBloccoDiInvioPiccolo;
begin
  CompareWithGolden('scenario2');
end;

procedure TTestQ3Parity.DovrebbeDareGliStessiRisultatiDelCConDmaStereo8BitEDoppler;
begin
  CompareWithGolden('scenario3');
end;

procedure TTestQ3Parity.DovrebbeDareGliStessiRisultatiDelCConTuttiICanaliOccupati;
begin
  CompareWithGolden('scenario4');
end;

end.
