{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TMp3Provider                                           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Mp3.Provider;

interface

uses
  System.SysUtils, DUnitX.TestFramework;

type
  [TestFixture]
  [Category('mp3')]
  TTestMp3Provider = class(TObject)
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestMp3WorksWithoutTheDll;
    [Test]
    procedure TestMp3IsShared;
    [Test]
    procedure TestUseReplacesTheImplementation;
    [Test]
    procedure TestReleaseThenMp3CreatesANewOne;
    [Test]
    procedure TestEveryClientHasItsOwnDecoder;
  end;

implementation

uses
  DelphiDoom.Mp3.Intf, DelphiDoom.Mp3.Engine, DelphiDoom.Mp3.Client,
  DelphiDoom.Mp3.Provider;

{ TTestMp3Provider }

procedure TTestMp3Provider.Setup;
begin
  TMp3Provider.Release;
end;

procedure TTestMp3Provider.TearDown;
begin
  TMp3Provider.Release;
end;

procedure TTestMp3Provider.TestMp3WorksWithoutTheDll;
var
  LClient: TMp3Client;
begin
  LClient := TMp3Client.Create(TMp3Provider.Mp3);
  try
    Assert.AreEqual(Cardinal(0), LClient.PendingSize);
  finally
    LClient.Free;
  end;
end;

procedure TTestMp3Provider.TestMp3IsShared;
begin
  Assert.IsTrue(TMp3Provider.Mp3 = TMp3Provider.Mp3);
end;

procedure TTestMp3Provider.TestUseReplacesTheImplementation;
var
  LReplacement: IMp3;
begin
  LReplacement := TMp3Engine.Create;
  TMp3Provider.Use(LReplacement);
  Assert.IsTrue(TMp3Provider.Mp3 = LReplacement);
end;

procedure TTestMp3Provider.TestReleaseThenMp3CreatesANewOne;
var
  LMp3: IMp3;
begin
  TMp3Provider.Mp3;
  TMp3Provider.Release;
  LMp3 := TMp3Provider.Mp3;
  Assert.IsTrue(Assigned(LMp3));
end;

procedure TTestMp3Provider.TestEveryClientHasItsOwnDecoder;
var
  LFirst, LSecond: TMp3Client;
begin
  LFirst := TMp3Client.Create(TMp3Provider.Mp3);
  LSecond := TMp3Client.Create(TMp3Provider.Mp3);
  try
    LFirst.Feed(TBytes.Create(1, 2, 3));
    Assert.AreEqual(Cardinal(0), LSecond.PendingSize);
  finally
    LSecond.Free;
    LFirst.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestMp3Provider);

end.

