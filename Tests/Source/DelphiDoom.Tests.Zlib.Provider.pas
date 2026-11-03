{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TZlibProvider                                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Zlib.Provider;

interface

uses
  System.SysUtils, DUnitX.TestFramework;

type
  [TestFixture]
  [Category('zlib')]
  TTestZlibProvider = class(TObject)
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
  end;

implementation

uses
  DelphiDoom.Zlib.Intf, DelphiDoom.Zlib.Engine, DelphiDoom.Zlib.Provider;

{ TTestZlibProvider }

procedure TTestZlibProvider.Setup;
begin
  TZlibProvider.Release;
end;

procedure TTestZlibProvider.TearDown;
begin
  TZlibProvider.Release;
end;

procedure TTestZlibProvider.TestClientWorksWithoutTheDll;
var
  LSource, LRestored: TBytes;
begin
  LSource := TEncoding.ASCII.GetBytes('aaaaaaaaaabbbbbbbbbbcccccccccc');
  LRestored := TZlibProvider.Client.Uncompress(
    TZlibProvider.Client.Compress(LSource));
  Assert.AreEqual(Length(LSource), Length(LRestored));
  Assert.AreEqualMemory(Pointer(LSource), Pointer(LRestored), Length(LSource));
end;

procedure TTestZlibProvider.TestClientIsShared;
begin
  Assert.AreSame(TObject(TZlibProvider.Client), TObject(TZlibProvider.Client));
end;

procedure TTestZlibProvider.TestUseReplacesTheImplementation;
var
  LFirst: TObject;
begin
  LFirst := TZlibProvider.Client;
  TZlibProvider.Use(TZlibEngine.Create);
  Assert.AreNotSame(LFirst, TObject(TZlibProvider.Client));
  Assert.AreEqual('1.2.8', TZlibProvider.Client.Version);
end;

procedure TTestZlibProvider.TestReleaseThenClientCreatesANewOne;
begin
  TZlibProvider.Client;
  TZlibProvider.Release;
  Assert.AreEqual('1.2.8', TZlibProvider.Client.Version);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestZlibProvider);

end.
