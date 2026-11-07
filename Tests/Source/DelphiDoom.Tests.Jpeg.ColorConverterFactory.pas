{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TJpegColorConverterFactory                             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Jpeg.ColorConverterFactory;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Jpeg.Frame;

type
  [TestFixture]
  [Category('jpeg')]
  TTestJpegColorConverterFactory = class(TObject)
  private
    FFrame: TJpegFrame;
    procedure SetUpFrame(ACount: Integer);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestGrayStaysGray;
    [Test]
    procedure TestYCbCrAndRgbGiveThreeComponents;
    [Test]
    procedure TestOtherColorSpacesCannotBeConverted;
  end;

implementation

uses
  DelphiDoom.Jpeg.ColorConverterFactory, DelphiDoom.Jpeg.Types;

{ TTestJpegColorConverterFactory }

procedure TTestJpegColorConverterFactory.Setup;
begin
  FFrame := TJpegFrame.Create;
end;

procedure TTestJpegColorConverterFactory.TearDown;
begin
  FFrame.Free;
end;

procedure TTestJpegColorConverterFactory.SetUpFrame(ACount: Integer);
var
  LIndex: Integer;
begin
  FFrame.StartOfImage;
  FFrame.SetFrameHeader(8, 8, 8, ACount, False, False);
  for LIndex := 0 to ACount - 1 do
    FFrame.ComponentByIndex[LIndex]^.Id := LIndex + 1;
  FFrame.ChooseColorSpace;
end;

procedure TTestJpegColorConverterFactory.TestGrayStaysGray;
begin
  SetUpFrame(1);
  Assert.AreEqual(1, TJpegColorConverterFactory.OutputComponentsOf(FFrame));
  Assert.AreEqual(1, TJpegColorConverterFactory.Select(FFrame).OutputComponents);
end;

procedure TTestJpegColorConverterFactory.TestYCbCrAndRgbGiveThreeComponents;
begin
  SetUpFrame(3);
  Assert.AreEqual(3, TJpegColorConverterFactory.OutputComponentsOf(FFrame));
  Assert.AreEqual(3, TJpegColorConverterFactory.Select(FFrame).OutputComponents);
  FFrame.SawAdobe := True;
  FFrame.AdobeTransform := 0;
  FFrame.ChooseColorSpace;
  Assert.AreEqual(3, TJpegColorConverterFactory.Select(FFrame).OutputComponents);
end;

procedure TTestJpegColorConverterFactory.TestOtherColorSpacesCannotBeConverted;
var
  LCount: Integer;
  LRaised: Boolean;
begin
  for LCount in [2, 4] do
  begin
    SetUpFrame(LCount);
    LRaised := False;
    try
      TJpegColorConverterFactory.Select(FFrame);
    except
      on E: EJpegDecodeException do
      begin
        LRaised := True;
        Assert.AreEqual(Ord(jdeColorConversion), Ord(E.Error));
      end;
    end;
    Assert.IsTrue(LRaised, 'Components: ' + IntToStr(LCount));
  end;
end;

end.
