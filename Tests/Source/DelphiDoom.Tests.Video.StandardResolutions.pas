{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the video library - the standard resolutions            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Video.StandardResolutions;

interface

uses
  DUnitX.TestFramework,
  DelphiDoom.Video.StandardResolutions;

type
  [TestFixture]
  [Category('video')]
  TTestVideoStandardResolutions = class(TObject)
  public
    [Test]
    procedure DovrebbeAvereLeUndiciRisoluzioniDelVecchioElenco;
    [Test]
    procedure DovrebbeDare400x300PartendoDalPiuPiccolo;
    [Test]
    procedure DovrebbeRiprodurreIlCicloDelVecchioCodiceSuTuttiIFormati;
    [Test]
    procedure DovrebbeLasciareLaMisuraSeNessunaRisoluzioneLaContiene;
  end;

implementation

const
  OLD_COUNT = 11;
  OLD_TABLE: array[0..OLD_COUNT - 1, 0..1] of Integer = (
    (1920, 1080), (1366, 768), (1280, 1024), (1280, 800), (1024, 768), (800, 600), (640, 480), (600, 400),
    (512, 384), (400, 300), (320, 200)
  );

// The loop of I_ChangeFullScreen as it was in i_video, copied
procedure OldChoose(var AWidth, AHeight: Integer);
var
  LIndex: Integer;
begin
  LIndex := 0;
  while LIndex < OLD_COUNT - 1 do
  begin
    if (AWidth <= OLD_TABLE[LIndex, 0]) and (AHeight <= OLD_TABLE[LIndex, 1]) and
       (AWidth >= OLD_TABLE[LIndex + 1, 0]) then
    begin
      AWidth := OLD_TABLE[LIndex, 0];
      AHeight := OLD_TABLE[LIndex, 1];
      Break;
    end;
    Inc(LIndex);
  end;
end;

{ TTestVideoStandardResolutions }

procedure TTestVideoStandardResolutions.DovrebbeAvereLeUndiciRisoluzioniDelVecchioElenco;
var
  LIndex: Integer;
begin
  Assert.AreEqual(OLD_COUNT, TVideoStandardResolutions.Count);
  for LIndex := 0 to OLD_COUNT - 1 do
  begin
    Assert.AreEqual(OLD_TABLE[LIndex, 0], TVideoStandardResolutions.WidthOf(LIndex));
    Assert.AreEqual(OLD_TABLE[LIndex, 1], TVideoStandardResolutions.HeightOf(LIndex));
  end;
end;

// The old rule always ends here: kept as it was (the plan, 12.11)
procedure TTestVideoStandardResolutions.DovrebbeDare400x300PartendoDalPiuPiccolo;
var
  LWidth: Integer;
  LHeight: Integer;
begin
  LWidth := 320;
  LHeight := 200;
  TVideoStandardResolutions.Choose(LWidth, LHeight);
  Assert.AreEqual(400, LWidth);
  Assert.AreEqual(300, LHeight);
end;

procedure TTestVideoStandardResolutions.DovrebbeRiprodurreIlCicloDelVecchioCodiceSuTuttiIFormati;
var
  LWidth: Integer;
  LHeight: Integer;
  LOldWidth: Integer;
  LOldHeight: Integer;
  LNewWidth: Integer;
  LNewHeight: Integer;
begin
  LWidth := 100;
  while LWidth <= 2200 do
  begin
    LHeight := 100;
    while LHeight <= 1300 do
    begin
      LOldWidth := LWidth;
      LOldHeight := LHeight;
      OldChoose(LOldWidth, LOldHeight);
      LNewWidth := LWidth;
      LNewHeight := LHeight;
      TVideoStandardResolutions.Choose(LNewWidth, LNewHeight);
      Assert.AreEqual(LOldWidth, LNewWidth);
      Assert.AreEqual(LOldHeight, LNewHeight);
      Inc(LHeight, 37);
    end;
    Inc(LWidth, 29);
  end;
end;

procedure TTestVideoStandardResolutions.DovrebbeLasciareLaMisuraSeNessunaRisoluzioneLaContiene;
var
  LWidth: Integer;
  LHeight: Integer;
begin
  LWidth := 3000;
  LHeight := 2000;
  TVideoStandardResolutions.Choose(LWidth, LHeight);
  Assert.AreEqual(3000, LWidth);
  Assert.AreEqual(2000, LHeight);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestVideoStandardResolutions);

end.
