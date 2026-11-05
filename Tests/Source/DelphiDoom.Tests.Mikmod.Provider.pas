{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TMikModProvider                                        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Mikmod.Provider;

interface

uses
  System.SysUtils, DUnitX.TestFramework;

type
  [TestFixture]
  [Category('mikmod')]
  TTestMikModProvider = class(TObject)
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
    procedure TestPlayingWithoutInitializeRaises;
  end;

implementation

uses
  DelphiDoom.Mikmod.Intf, DelphiDoom.Mikmod.TrackerEngine, DelphiDoom.Mikmod.Provider;

{ TTestMikModProvider }

procedure TTestMikModProvider.Setup;
begin
  TMikModProvider.Release;
end;

procedure TTestMikModProvider.TearDown;
begin
  TMikModProvider.Release;
end;

procedure TTestMikModProvider.TestClientWorksWithoutTheDll;
begin
  // No audio device is opened: the client just reports it is not initialised
  Assert.IsFalse(TMikModProvider.Client.IsInitialized);
end;

procedure TTestMikModProvider.TestClientIsShared;
begin
  Assert.AreSame(TObject(TMikModProvider.Client),
    TObject(TMikModProvider.Client));
end;

procedure TTestMikModProvider.TestUseReplacesTheImplementation;
begin
  TMikModProvider.Client;
  // The old client is freed by Use: a new one works on the engine passed in
  TMikModProvider.Use(TTrackerMikModEngine.Create);
  Assert.IsFalse(TMikModProvider.Client.IsInitialized);
end;

procedure TTestMikModProvider.TestReleaseThenClientCreatesANewOne;
begin
  TMikModProvider.Client;
  TMikModProvider.Release;
  Assert.IsFalse(TMikModProvider.Client.IsInitialized);
end;

procedure TTestMikModProvider.TestPlayingWithoutInitializeRaises;
begin
  Assert.WillRaise(
    procedure
    begin
      TMikModProvider.Client.Play(True);
    end, EMikModException);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestMikModProvider);

end.
