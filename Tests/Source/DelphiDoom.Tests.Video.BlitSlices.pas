{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the video library - the slices of the blit threads      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Video.BlitSlices;

interface

uses
  DUnitX.TestFramework,
  DelphiDoom.Video.BlitSlices;

type
  [TestFixture]
  [Category('video')]
  TTestVideoBlitSlices = class(TObject)
  public
    [Test]
    procedure DovrebbeScegliereIlNumeroDiFettePerProcessore;
    [Test]
    procedure DovrebbeRiprodurreLeFetteDelVecchioCodiceConDueFette;
    [Test]
    procedure DovrebbeRiprodurreLeFetteDelVecchioCodiceConOttoFette;
    [Test]
    procedure DovrebbeCoprireTuttoIlFotogrammaSenzaBuchiNeSovrapposizioni;
  end;

implementation

{ TTestVideoBlitSlices }

procedure TTestVideoBlitSlices.DovrebbeScegliereIlNumeroDiFettePerProcessore;
begin
  Assert.AreEqual(2, TVideoBlitSlices.SliceCount(1));
  Assert.AreEqual(2, TVideoBlitSlices.SliceCount(2));
  Assert.AreEqual(3, TVideoBlitSlices.SliceCount(3));
  Assert.AreEqual(3, TVideoBlitSlices.SliceCount(4));
  Assert.AreEqual(4, TVideoBlitSlices.SliceCount(6));
  Assert.AreEqual(8, TVideoBlitSlices.SliceCount(7));
  Assert.AreEqual(8, TVideoBlitSlices.SliceCount(32));
end;

procedure TTestVideoBlitSlices.DovrebbeRiprodurreLeFetteDelVecchioCodiceConDueFette;
var
  LTotal: Integer;
  LFirst: TVideoBlitSlice;
  LSecond: TVideoBlitSlice;
begin
  for LTotal in [64000, 307200, 786432, 2073600] do
  begin
    LFirst := TVideoBlitSlices.Slice(LTotal, 2, 0);
    LSecond := TVideoBlitSlices.Slice(LTotal, 2, 1);
    // the text of the old I_BlitBuffer
    Assert.AreEqual(0, LFirst.Start);
    Assert.AreEqual((LTotal div 2) and not 3, LFirst.Finish);
    Assert.AreEqual(LFirst.Finish + 1, LSecond.Start);
    Assert.AreEqual(LTotal - 1, LSecond.Finish);
  end;
end;

procedure TTestVideoBlitSlices.DovrebbeRiprodurreLeFetteDelVecchioCodiceConOttoFette;
var
  LTotal: Integer;
  LIndex: Integer;
  LSlice: TVideoBlitSlice;
  LPreviousFinish: Integer;
begin
  for LTotal in [64000, 307200, 786432, 2073600] do
  begin
    LPreviousFinish := -1;
    for LIndex := 0 to 6 do
    begin
      LSlice := TVideoBlitSlices.Slice(LTotal, 8, LIndex);
      // the text of the old I_BlitBuffer: (n * W * H div 8) and not 3
      Assert.AreEqual(LPreviousFinish + 1, LSlice.Start);
      Assert.AreEqual(((LIndex + 1) * LTotal div 8) and not 3, LSlice.Finish);
      LPreviousFinish := LSlice.Finish;
    end;
    LSlice := TVideoBlitSlices.Slice(LTotal, 8, 7);
    Assert.AreEqual(LPreviousFinish + 1, LSlice.Start);
    Assert.AreEqual(LTotal - 1, LSlice.Finish);
  end;
end;

procedure TTestVideoBlitSlices.DovrebbeCoprireTuttoIlFotogrammaSenzaBuchiNeSovrapposizioni;
var
  LCount: Integer;
  LIndex: Integer;
  LSlice: TVideoBlitSlice;
  LNext: Integer;
begin
  for LCount in [2, 3, 4, 8] do
  begin
    LNext := 0;
    for LIndex := 0 to LCount - 1 do
    begin
      LSlice := TVideoBlitSlices.Slice(640 * 400, LCount, LIndex);
      Assert.AreEqual(LNext, LSlice.Start);
      LNext := LSlice.Finish + 1;
    end;
    Assert.AreEqual(640 * 400, LNext);
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestVideoBlitSlices);

end.
