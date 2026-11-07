{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TJpegRowRenderer                                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Jpeg.RowRenderer;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Jpeg.ComponentBuffers,
  DelphiDoom.Jpeg.Frame, DelphiDoom.Jpeg.RowRenderer;

type
  [TestFixture]
  [Category('jpeg')]
  TTestJpegRowRenderer = class(TObject)
  private
    FFrame: TJpegFrame;
    FBuffers: TArray<TJpegComponentBuffers>;
    FRenderer: TJpegRowRenderer;
    procedure Prepare(AWidth, AHeight: Integer; const AHorizontal, AVertical: array of Integer);
    procedure FillPlane(AComponent: Integer; ARow: Integer; AValue: Byte);
    function Render(ARow: Integer): TBytes;
  public
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestComponentsOfTheSizeOfTheImageAreUsedAsTheyAre;
    [Test]
    procedure TestChromaOfHalfTheSizeIsRepeatedForTwoRowsWhenTheImageIsNarrow;
    [Test]
    procedure TestFlatChromaStaysFlatWithTheSmoothFilter;
    [Test]
    procedure TestFlatLumaOnTheLastRowOfAnOddHeightIsUsed;
    [Test]
    procedure TestSamplingFactorsThatDoNotDivideAreRefused;
  end;

implementation

uses
  DelphiDoom.Jpeg.ColorConverter, DelphiDoom.Jpeg.ColorConverterFactory,
  DelphiDoom.Jpeg.Types;

{ TTestJpegRowRenderer }

procedure TTestJpegRowRenderer.TearDown;
var
  LIndex: Integer;
begin
  FreeAndNil(FRenderer);
  for LIndex := 0 to High(FBuffers) do
    FBuffers[LIndex].Free;
  FBuffers := nil;
  FreeAndNil(FFrame);
end;

procedure TTestJpegRowRenderer.Prepare(AWidth, AHeight: Integer; const AHorizontal,
  AVertical: array of Integer);
var
  LIndex: Integer;
  LComponent: PJpegComponentInfo;
begin
  TearDown;
  FFrame := TJpegFrame.Create;
  FFrame.StartOfImage;
  FFrame.SetFrameHeader(AWidth, AHeight, 8, 3, False, False);
  for LIndex := 0 to 2 do
  begin
    FFrame.ComponentByIndex[LIndex]^.Id := LIndex + 1;
    FFrame.ComponentByIndex[LIndex]^.Horizontal := AHorizontal[LIndex];
    FFrame.ComponentByIndex[LIndex]^.Vertical := AVertical[LIndex];
  end;
  FFrame.Scan^.ComponentCount := 3;
  FFrame.PrepareGeometry;
  FFrame.ChooseColorSpace;

  SetLength(FBuffers, 3);
  for LIndex := 0 to 2 do
  begin
    LComponent := FFrame.ComponentByIndex[LIndex];
    FBuffers[LIndex] := TJpegComponentBuffers.Create(LComponent^.WidthInBlocks,
      LComponent^.HeightInBlocks);
    FBuffers[LIndex].AllocatePlane;
    FBuffers[LIndex].FillPlane(128);
  end;
end;

procedure TTestJpegRowRenderer.FillPlane(AComponent: Integer; ARow: Integer; AValue: Byte);
begin
  FillChar(FBuffers[AComponent].PlaneRow(ARow)^, FBuffers[AComponent].PlaneStride, AValue);
end;

function TTestJpegRowRenderer.Render(ARow: Integer): TBytes;
begin
  if not Assigned(FRenderer) then
    FRenderer := TJpegRowRenderer.Create(FFrame, FBuffers,
      TJpegColorConverterFactory.Select(FFrame));
  SetLength(Result, FFrame.ImageWidth * 3 + 16);
  FRenderer.RenderRow(ARow, @Result[0]);
end;

procedure TTestJpegRowRenderer.TestComponentsOfTheSizeOfTheImageAreUsedAsTheyAre;
var
  LRow: TBytes;
begin
  Prepare(4, 2, [1, 1, 1], [1, 1, 1]);
  FillPlane(0, 0, 10);
  FillPlane(0, 1, 200);
  LRow := Render(0);
  // Neutral chroma: gray, blue = green = red = luma
  Assert.AreEqual(10, Integer(LRow[0]));
  Assert.AreEqual(10, Integer(LRow[5]));
  Assert.AreEqual(10, Integer(LRow[11]));
  LRow := Render(1);
  Assert.AreEqual(200, Integer(LRow[0]));
  Assert.AreEqual(200, Integer(LRow[11]));
end;

procedure TTestJpegRowRenderer.TestChromaOfHalfTheSizeIsRepeatedForTwoRowsWhenTheImageIsNarrow;
var
  LRow: TBytes;
begin
  // 4 x 4 pixels at 4:2:0: the chroma has 2 x 2 samples, which is too narrow
  // for the smooth filter, so each sample is repeated; two rows share a row
  Prepare(4, 4, [2, 1, 1], [2, 1, 1]);
  FillPlane(2, 0, 200);
  FillPlane(2, 1, 50);
  Assert.IsTrue(Render(0)[2] > 128, 'Row 0: red');
  Assert.IsTrue(Render(1)[2] > 128, 'Row 1: red');
  Assert.IsTrue(Render(2)[2] < 128, 'Row 2: red');
  Assert.IsTrue(Render(3)[2] < 128, 'Row 3: red');
  LRow := Render(0);
  Assert.AreEqual(Integer(LRow[2]), Integer(LRow[5]), 'Two pixels share a sample');
  Assert.AreEqual(Integer(LRow[2]), Integer(Render(1)[2]), 'Two rows share a sample');
end;

procedure TTestJpegRowRenderer.TestFlatChromaStaysFlatWithTheSmoothFilter;
var
  LRow: TBytes;
  LColumn: Integer;
  LRed: Integer;
begin
  // 8 x 4 at 4:2:0: the chroma is 4 samples wide, so the filter is used
  Prepare(8, 4, [2, 1, 1], [2, 1, 1]);
  FillPlane(2, 0, 180);
  FillPlane(2, 1, 180);
  LRed := Render(0)[2];
  for LColumn := 0 to 7 do
  begin
    LRow := Render(LColumn mod 4);
    Assert.AreEqual(LRed, Integer(LRow[LColumn * 3 + 2]));
  end;
end;

procedure TTestJpegRowRenderer.TestFlatLumaOnTheLastRowOfAnOddHeightIsUsed;
var
  LRow: TBytes;
begin
  // 10 rows at 4:2:0: the chroma has 5; the last row of the image needs the
  // row after the fifth of the chroma, which does not exist: the fifth is
  // used again
  Prepare(8, 10, [2, 1, 1], [2, 1, 1]);
  FillPlane(0, 9, 99);
  LRow := Render(9);
  Assert.AreEqual(99, Integer(LRow[0]));
end;

procedure TTestJpegRowRenderer.TestSamplingFactorsThatDoNotDivideAreRefused;
var
  LRaised: Boolean;
begin
  Prepare(8, 8, [3, 2, 1], [1, 1, 1]);
  LRaised := False;
  try
    Render(0);
  except
    on E: EJpegDecodeException do
    begin
      LRaised := True;
      Assert.AreEqual(Ord(jdeFractionalSampling), Ord(E.Error));
    end;
  end;
  Assert.IsTrue(LRaised);
end;

end.
