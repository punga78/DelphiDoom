{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TPngProvider                                           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Png.Provider;

interface

uses
  System.SysUtils, DUnitX.TestFramework;

type
  [TestFixture]
  [Category('png')]
  TTestPngProvider = class(TObject)
  private
    function MakePixels(AWidth, AHeight: Integer): TBytes;
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
  DelphiDoom.Png.Intf, DelphiDoom.Png.Client, DelphiDoom.Png.Engine,
  DelphiDoom.Png.Provider, DelphiDoom.Zlib.Provider;

{ TTestPngProvider }

procedure TTestPngProvider.Setup;
begin
  TPngProvider.Release;
  TZlibProvider.Release;
end;

procedure TTestPngProvider.TearDown;
begin
  TPngProvider.Release;
  TZlibProvider.Release;
end;

function TTestPngProvider.MakePixels(AWidth, AHeight: Integer): TBytes;
var
  LIndex: Integer;
begin
  SetLength(Result, AWidth * AHeight * 4);
  for LIndex := 0 to High(Result) do
    Result[LIndex] := Byte(LIndex * 5 + 1);
end;

procedure TTestPngProvider.TestClientWorksWithoutTheDll;
var
  LImage: TPngImage;
begin
  LImage := TPngProvider.Client.Decode(
    TPngProvider.Client.Encode(MakePixels(6, 4), 6, 4, DDPNG_FORMAT_BGRA));
  Assert.AreEqual(6, LImage.Info.Width);
  Assert.AreEqual(4, LImage.Info.Height);
  Assert.AreEqual(6 * 4 * 4, Length(LImage.Pixels));
end;

procedure TTestPngProvider.TestClientIsShared;
begin
  Assert.AreSame(TObject(TPngProvider.Client), TObject(TPngProvider.Client));
end;

procedure TTestPngProvider.TestUseReplacesTheImplementation;
begin
  TPngProvider.Client;
  // The old client is freed by Use: a new one works on the engine passed in
  TPngProvider.Use(TPngEngine.Create(TZlibProvider.Zlib));
  Assert.AreEqual(4, TPngProvider.Client.GetInfo(
    TPngProvider.Client.Encode(MakePixels(6, 4), 6, 4)).Height);
end;

procedure TTestPngProvider.TestReleaseThenClientCreatesANewOne;
begin
  TPngProvider.Client;
  TPngProvider.Release;
  Assert.AreEqual(4, TPngProvider.Client.GetInfo(
    TPngProvider.Client.Encode(MakePixels(6, 4), 6, 4)).Height);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestPngProvider);

end.
