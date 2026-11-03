{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TXmiProvider and of TXmiClient.TryConvertToMidiFile    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Xmi.Provider;

interface

uses
  System.SysUtils, DUnitX.TestFramework;

type
  [TestFixture]
  [Category('xmi')]
  TTestXmiProvider = class(TObject)
  private
    FFileName: string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestClientWorksWithoutTheDll;
    [Test]
    procedure TestClientIsShared;
    [Test]
    procedure TestUseReplacesTheImplementation;
    [Test]
    procedure TestReleaseThenClientCreatesANewOne;
    [Test]
    procedure TestTryConvertToMidiFileWritesAMidiFile;
    [Test]
    procedure TestTryConvertToMidiFileReturnsFalseForGarbage;
    [Test]
    procedure TestTryConvertToMidiFileReturnsFalseForAnUnwritableFile;
  end;

implementation

uses
  System.IOUtils, DelphiDoom.Xmi.Intf, DelphiDoom.Xmi.Engine,
  DelphiDoom.Xmi.Provider, DelphiDoom.Tests.Xmi.Samples;

{ TTestXmiProvider }

procedure TTestXmiProvider.Setup;
begin
  TXmiProvider.Release;
  FFileName := TPath.Combine(TPath.GetTempPath, 'ddxmi_provider_test.mid');
  if TFile.Exists(FFileName) then
    TFile.Delete(FFileName);
end;

procedure TTestXmiProvider.TearDown;
begin
  TXmiProvider.Release;
  if TFile.Exists(FFileName) then
    TFile.Delete(FFileName);
end;

procedure TTestXmiProvider.TestClientWorksWithoutTheDll;
begin
  Assert.IsTrue(TXmiProvider.Client.IsXmiMusic(TXmiSamples.BuildXmi));
end;

procedure TTestXmiProvider.TestClientIsShared;
begin
  Assert.AreSame(TObject(TXmiProvider.Client), TObject(TXmiProvider.Client));
end;

procedure TTestXmiProvider.TestUseReplacesTheImplementation;
begin
  TXmiProvider.Client;
  // The old client is freed by Use: a new one works on the engine passed in
  TXmiProvider.Use(TXmiEngine.Create);
  Assert.IsTrue(TXmiProvider.Client.IsXmiMusic(TXmiSamples.BuildXmi));
end;

procedure TTestXmiProvider.TestReleaseThenClientCreatesANewOne;
begin
  TXmiProvider.Client;
  TXmiProvider.Release;
  Assert.IsTrue(TXmiProvider.Client.IsXmiMusic(TXmiSamples.BuildXmi));
end;

procedure TTestXmiProvider.TestTryConvertToMidiFileWritesAMidiFile;
var
  LSample, LWritten: TBytes;
begin
  LSample := TXmiSamples.BuildXmi;
  Assert.IsTrue(TXmiProvider.Client.TryConvertToMidiFile(Pointer(LSample),
    Length(LSample), 0, FFileName));
  LWritten := TFile.ReadAllBytes(FFileName);
  Assert.AreEqual('MThd', TXmiSamples.TagAt(LWritten, 0));
end;

procedure TTestXmiProvider.TestTryConvertToMidiFileReturnsFalseForGarbage;
var
  LGarbage: TBytes;
begin
  LGarbage := TXmiSamples.BuildGarbage(64);
  Assert.IsFalse(TXmiProvider.Client.TryConvertToMidiFile(Pointer(LGarbage),
    Length(LGarbage), 0, FFileName));
  Assert.IsFalse(TFile.Exists(FFileName));
end;

procedure TTestXmiProvider.TestTryConvertToMidiFileReturnsFalseForAnUnwritableFile;
var
  LSample: TBytes;
begin
  LSample := TXmiSamples.BuildXmi;
  Assert.IsFalse(TXmiProvider.Client.TryConvertToMidiFile(Pointer(LSample),
    Length(LSample), 0, TPath.Combine(TPath.GetTempPath, 'no_such_dir_ddxmi\x.mid')));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXmiProvider);

end.
