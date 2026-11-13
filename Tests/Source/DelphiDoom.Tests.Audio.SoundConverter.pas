{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TSoundConverter and of TSndfileProvider                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Audio.SoundConverter;

interface

uses
  System.SysUtils, DUnitX.TestFramework;

type
  [TestFixture]
  [Category('audio')]
  TTestSoundConverter = class(TObject)
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestProviderWorksWithoutTheDll;
    [Test]
    procedure TestProviderClientIsShared;
    [Test]
    procedure TestProviderUseReplacesTheImplementation;
    [Test]
    procedure TestProviderReleaseThenClientCreatesANewOne;
    [Test]
    procedure TestProviderUsesTheRegisteredFactory;
    [Test]
    procedure TestProviderWithoutFactoryRaises;
    [Test]
    procedure TestWavIsConvertedToAnEquivalentWav;
    [Test]
    procedure TestConvertedWavKeepsTheSampleRate;
    [Test]
    procedure TestNormalizeRaisesTheLevel;
    [Test]
    procedure TestGarbageRaises;
    [Test]
    procedure TestEmptyDataRaises;
  end;

implementation

uses
  DelphiDoom.Sndfile.Intf, DelphiDoom.Sndfile.Factory.Intf,
  DelphiDoom.Sound.Factory, DelphiDoom.Sound.EngineFactory,
  DelphiDoom.Sndfile.Provider, DelphiDoom.Audio.SoundConverter,
  DelphiDoom.Audio.WavBuilder, DelphiDoom.Tests.Sndfile.Wav;

type
  // fake: counts the engines it is asked for
  TCountingFactory = class(TInterfacedObject, ISndfileFactory)
  public
    Count: Integer;
    function CreateEngine: ISndfile;
  end;

function TCountingFactory.CreateEngine: ISndfile;
begin
  Inc(Count);
  Result := TSoundFactory.CreateEngine;
end;

{ TTestSoundConverter }

procedure TTestSoundConverter.Setup;
begin
  TSndfileProvider.Release;
end;

procedure TTestSoundConverter.TearDown;
begin
  TSndfileProvider.Release;
end;

procedure TTestSoundConverter.TestProviderWorksWithoutTheDll;
begin
  Assert.IsTrue(TSndfileProvider.Client.Version <> '');
end;

procedure TTestSoundConverter.TestProviderClientIsShared;
begin
  Assert.AreSame(TObject(TSndfileProvider.Client),
    TObject(TSndfileProvider.Client));
end;

procedure TTestSoundConverter.TestProviderUseReplacesTheImplementation;
begin
  TSndfileProvider.Client;
  // The old client is freed by Use: a new one works on the engine passed in
  TSndfileProvider.Use(TSoundFactory.CreateEngine);
  Assert.IsTrue(TSndfileProvider.Client.Version <> '');
end;

procedure TTestSoundConverter.TestProviderReleaseThenClientCreatesANewOne;
begin
  TSndfileProvider.Client;
  TSndfileProvider.Release;
  Assert.IsTrue(TSndfileProvider.Client.Version <> '');
end;

procedure TTestSoundConverter.TestProviderUsesTheRegisteredFactory;
var
  LFactory: TCountingFactory;
  LHolder: ISndfileFactory;
begin
  LFactory := TCountingFactory.Create;
  LHolder := LFactory;
  try
    TSndfileProvider.UseFactory(LHolder);
    Assert.IsTrue(TSndfileProvider.Client.Version <> '');
    Assert.AreEqual(1, LFactory.Count);
  finally
    TSndfileProvider.UseFactory(TSoundEngineFactory.Create);
  end;
end;

procedure TTestSoundConverter.TestProviderWithoutFactoryRaises;
begin
  TSndfileProvider.UseFactory(nil);
  try
    Assert.WillRaise(
      procedure
      begin
        TSndfileProvider.Client;
      end,
      ESndfileException);
  finally
    TSndfileProvider.UseFactory(TSoundEngineFactory.Create);
  end;
end;

procedure TTestSoundConverter.TestWavIsConvertedToAnEquivalentWav;
var
  LSource, LWav: TBytes;
begin
  LSource := TSndfileTestWav.MakeSawtooth(1000, 11025);
  LWav := TSoundConverter.ToWav(Pointer(LSource), Length(LSource), False);
  Assert.AreEqual<Integer>(WAV_HEADER_SIZE + 1000 * 2, Length(LWav));
  // The samples are the ones of the source, in the same order
  Assert.AreEqual(Integer(TSndfileTestWav.SawtoothAt(10)),
    Integer(SmallInt(LWav[WAV_HEADER_SIZE + 20] or
      (LWav[WAV_HEADER_SIZE + 21] shl 8))));
end;

procedure TTestSoundConverter.TestConvertedWavKeepsTheSampleRate;
var
  LSource, LWav: TBytes;
begin
  LSource := TSndfileTestWav.MakeSawtooth(100, 22050);
  LWav := TSoundConverter.ToWav(Pointer(LSource), Length(LSource), False);
  Assert.AreEqual(22050, Integer(LWav[24] or (LWav[25] shl 8) or
    (LWav[26] shl 16)));
end;

procedure TTestSoundConverter.TestNormalizeRaisesTheLevel;
var
  LSource, LWav: TBytes;
  LIndex: Integer;
  LPeak: Integer;
  LSample: Integer;
begin
  LSource := TSndfileTestWav.MakeSawtooth(1000, 11025);
  LWav := TSoundConverter.ToWav(Pointer(LSource), Length(LSource), True);
  LPeak := 0;
  for LIndex := 0 to 999 do
  begin
    LSample := Abs(Integer(SmallInt(LWav[WAV_HEADER_SIZE + LIndex * 2] or
      (LWav[WAV_HEADER_SIZE + LIndex * 2 + 1] shl 8))));
    if LSample > LPeak then
      LPeak := LSample;
  end;
  Assert.IsTrue(LPeak >= 32000, 'the loudest sample is close to the full scale');
end;

procedure TTestSoundConverter.TestGarbageRaises;
var
  LGarbage: TBytes;
  LIndex: Integer;
begin
  SetLength(LGarbage, 256);
  for LIndex := 0 to High(LGarbage) do
    LGarbage[LIndex] := Byte(LIndex * 7 + 3);
  Assert.WillRaise(
    procedure
    begin
      TSoundConverter.ToWav(Pointer(LGarbage), Length(LGarbage), False);
    end, ESndfileException);
end;

procedure TTestSoundConverter.TestEmptyDataRaises;
begin
  Assert.WillRaise(
    procedure
    begin
      TSoundConverter.ToWav(nil, 0, False);
    end, ESndfileException);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestSoundConverter);

end.
