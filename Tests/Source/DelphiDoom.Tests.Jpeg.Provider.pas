{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TJpegProvider                                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Jpeg.Provider;

interface

uses
  System.SysUtils, DUnitX.TestFramework;

type
  [TestFixture]
  [Category('jpeg')]
  TTestJpegProvider = class(TObject)
  private
    function MakeGray(AWidth, AHeight: Integer): TBytes;
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
  DelphiDoom.Jpeg.Intf, DelphiDoom.Jpeg.Engine, DelphiDoom.Jpeg.Provider;

{ TTestJpegProvider }

procedure TTestJpegProvider.Setup;
begin
  TJpegProvider.Release;
end;

procedure TTestJpegProvider.TearDown;
begin
  TJpegProvider.Release;
end;

function TTestJpegProvider.MakeGray(AWidth, AHeight: Integer): TBytes;
var
  LIndex: Integer;
begin
  SetLength(Result, AWidth * AHeight);
  for LIndex := 0 to High(Result) do
    Result[LIndex] := Byte(LIndex * 3);
end;

procedure TTestJpegProvider.TestClientWorksWithoutTheDll;
var
  LStream: TBytes;
  LInfo: TJpegInfo;
begin
  LStream := TJpegProvider.Client.Encode(MakeGray(16, 8), 16, 8, 1);
  LInfo := TJpegProvider.Client.GetInfo(LStream);
  Assert.AreEqual(16, LInfo.Width);
  Assert.AreEqual(8, LInfo.Height);
  Assert.AreEqual(1, LInfo.Components);
end;

procedure TTestJpegProvider.TestClientIsShared;
begin
  Assert.AreSame(TObject(TJpegProvider.Client), TObject(TJpegProvider.Client));
end;

procedure TTestJpegProvider.TestUseReplacesTheImplementation;
begin
  TJpegProvider.Client;
  // The old client is freed by Use: a new one works on the engine passed in
  TJpegProvider.Use(TJpegEngine.Create);
  Assert.AreEqual(8, TJpegProvider.Client.GetInfo(
    TJpegProvider.Client.Encode(MakeGray(16, 8), 16, 8, 1)).Height);
end;

procedure TTestJpegProvider.TestReleaseThenClientCreatesANewOne;
begin
  TJpegProvider.Client;
  TJpegProvider.Release;
  Assert.AreEqual(8, TJpegProvider.Client.GetInfo(
    TJpegProvider.Client.Encode(MakeGray(16, 8), 16, 8, 1)).Height);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestJpegProvider);

end.
