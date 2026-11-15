{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - the pieces of the debug drawing       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.DebugRender;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.War.Render.Types, DelphiDoom.War.Render.Blitter,
  DelphiDoom.War.Render.Transform, DelphiDoom.War.Text.CFormat, DelphiDoom.War.Text.Intf,
  DelphiDoom.War.Ui.DebugRender, DelphiDoom.War.Ui.Types, DelphiDoom.War.Ui.Intf, DelphiDoom.War.MapUi.DebugArrow,
  DelphiDoom.War.Render.ColorList.Data;

type
  /// <summary>The small parts of the flags of the debug drawing that the parity scripts do not isolate</summary>
  [TestFixture]
  [Category('war')]
  TTestWarDebugRender = class(TObject)
  public
    /// <summary>The values of SDL_snprintf("%.1f") of the real SDL3 (the same as the C library: exact halves to the even decimal)</summary>
    [Test]
    [TestCase('un quarto', '0.25,0.2')]
    [TestCase('tre quarti', '0.75,0.8')]
    [TestCase('uno e un quarto', '1.25,1.2')]
    [TestCase('due e un quarto', '2.25,2.2')]
    [TestCase('un decimo', '0.05,0.1')]
    [TestCase('otto decimi', '0.85,0.8')]
    [TestCase('meta'' di una unita''', '2.5,2.5')]
    [TestCase('un valore con piu'' decimali', '157.0390625,157.0')]
    [TestCase('si arrotonda in su', '99.95,100.0')]
    [TestCase('un mezzo grande', '123456.75,123456.8')]
    [TestCase('negativo che arrotonda a zero', '-0.04,-0.0')]
    [TestCase('negativo con un quarto', '-0.25,-0.2')]
    [TestCase('trentacinque centesimi', '0.35,0.3')]
    [TestCase('quarantacinque centesimi', '0.45,0.5')]
    [TestCase('zero', '0,0.0')]
    [TestCase('un numero molto grande', '10000000000,10000000000.0')]
    [TestCase('un numero minuscolo', '1E-5,0.0')]
    procedure DovrebbeScrivereUnDecimaleComePrintf(const AValue, AExpected: string);
    [Test]
    procedure DovrebbeRiempireIlTestoACaratteriAllaDestra;
    [Test]
    procedure DovrebbeDireIlFlagFontAlRenderDeiTesti;
    [Test]
    procedure DovrebbeDisegnareLaPuntaConDueTrattiIndietro;
    [Test]
    procedure DovrebbeAvereOttantacinqueColoriOpachiNellaLista;
  end;

implementation

{ TTestWarDebugRender }

procedure TTestWarDebugRender.DovrebbeScrivereUnDecimaleComePrintf(const AValue, AExpected: string);
begin
  Assert.AreEqual(AExpected, string(TWarCFormat.Fixed1(StrToFloat(AValue, TFormatSettings.Invariant))));
end;

procedure TTestWarDebugRender.DovrebbeRiempireIlTestoACaratteriAllaDestra;
begin
  Assert.AreEqual('IDLE      ', string(TWarCFormat.PadRight('IDLE', 10)));
  Assert.AreEqual('DELIVERYMAN', string(TWarCFormat.PadRight('DELIVERYMAN', 10)));
end;

procedure TTestWarDebugRender.DovrebbeDireIlFlagFontAlRenderDeiTesti;
var
  LFlags: IWarDebugRender;
  LText: IWarTextDebug;
begin
  LFlags := TWarDebugRender.Create;
  Assert.IsTrue(Supports(LFlags, IWarTextDebug, LText));
  Assert.IsFalse(LText.IsFontOutlineOn);
  LFlags.Flag[wdrFont] := True;
  Assert.IsTrue(LText.IsFontOutlineOn);
  LFlags.Flag[wdrFont] := False;
  Assert.IsFalse(LText.IsFontOutlineOn);
end;

procedure TTestWarDebugRender.DovrebbeDisegnareLaPuntaConDueTrattiIndietro;
var
  LBlitter: TWarImageBlitter;
  LTransform: TWarRenderTransform;
  LBlack: TWarRgba;
  LWhite: TWarRgba;
  LX: Integer;
  LY: Integer;
  LCount: Integer;
begin
  LBlitter := TWarImageBlitter.Create(40, 40);
  LTransform := TWarRenderTransform.Create(LBlitter);
  try
    LBlack.R := 0;
    LBlack.G := 0;
    LBlack.B := 0;
    LBlack.A := 255;
    LBlitter.Clear(LBlack);
    LWhite := LBlack;
    LWhite.R := 255;
    LWhite.G := 255;
    LWhite.B := 255;
    // an arrow that goes to the east (angle 0): the strokes go back at 30 degrees, three pixels long, up and down
    TWarDebugArrow.DrawHead(LTransform, 20, 20, TWarDebugArrow.AngleOf(1, 0), LWhite);
    LCount := 0;
    for LY := 0 to 39 do
      for LX := 0 to 39 do
        if LBlitter.Pixels[(LY * 40 + LX) * 4] = 255 then
        begin
          Inc(LCount);
          Assert.IsTrue(LX <= 20, 'la punta va indietro');
        end;
    Assert.IsTrue(LCount >= 6, 'due tratti di almeno tre pixel');
    Assert.AreEqual(255, Integer(LBlitter.Pixels[(20 * 40 + 20) * 4]), 'il punto della freccia');
    Assert.AreEqual(Single(0), TWarDebugArrow.AngleOf(1, 0));
  finally
    LTransform.Free;
    LBlitter.Free;
  end;
end;

procedure TTestWarDebugRender.DovrebbeAvereOttantacinqueColoriOpachiNellaLista;
var
  LIndex: Integer;
begin
  Assert.AreEqual(85, WAR_COLOR_LIST_COUNT);
  for LIndex := 0 to WAR_COLOR_LIST_COUNT - 1 do
    Assert.AreEqual(255, Integer(WAR_COLOR_LIST[LIndex].A));
  // the first is 0xE52B50 (Amaranth) as in the C
  Assert.AreEqual(229, Integer(WAR_COLOR_LIST[0].R));
  Assert.AreEqual(43, Integer(WAR_COLOR_LIST[0].G));
  Assert.AreEqual(80, Integer(WAR_COLOR_LIST[0].B));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestWarDebugRender);

end.
