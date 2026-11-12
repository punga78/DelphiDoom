{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the keen library - the windows, the printing and   }
{  the line editor of the user manager; the fades                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Keen.UserWindows;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Keen.Types, DelphiDoom.Keen.UserTypes, DelphiDoom.Keen.Intf,
  DelphiDoom.Keen.UserIntf, DelphiDoom.Tests.Keen.UiWorld;

type
  [TestFixture]
  [Category('keen')]
  [Category('keen-user')]
  TTestKeenUserWindows = class(TObject)
  strict private
    FWorld: TKeenUiWorld;
    procedure Make(const AScript: string);
  public
    [TearDown]
    procedure TearDown;

    [Test]
    procedure UnaFinestraDovrebbeAvereMisureInCaratteriEFondoBianco;
    [Test]
    procedure UnaFinestraCentrataDovrebbeStareInMezzoAlloSchermo;
    [Test]
    procedure LaStampaDovrebbeAvanzareEAndareACapo;
    [Test]
    procedure IlNumeroDovrebbeEssereStampatoInDecimale;
    [Test]
    procedure LaStampaCentrataDovrebbeMettereIlTestoInMezzo;
    [Test]
    procedure LaRigaCentrataDovrebbeScendereDiUnaRiga;
    [Test]
    procedure UnaRigaCentrataTroppoLargaDovrebbeDareEccezione;
    [Test]
    procedure SalvareERipristinareDovrebberoRidareLaFinestra;
    [Test]
    procedure PulireDovrebbeRiportareLaStampaAllInizio;
    [Test]
    procedure LEditorDovrebbeDareIlTestoBattuto;
    [Test]
    procedure LEditorDovrebbeLasciareIlBufferConEscape;
    [Test]
    procedure LEditorDovrebbeCancellareEInserire;
    [Test]
    procedure LEditorDovrebbeRispettareIlNumeroMassimoDiCaratteri;
    [Test]
    procedure LEditorDovrebbeRispettareLaLarghezzaMassima;
    [Test]
    procedure LEditorDovrebbeIgnorareEscapeSeNonAmmesso;
    [Test]
    procedure LEditorDovrebbePartireDalTestoPredefinito;
    [Test]
    procedure DovrebbeRifiutareIParametriNulli;
  end;

  [TestFixture]
  [Category('keen')]
  [Category('keen-user')]
  TTestKeenFader = class(TObject)
  public
    [Test]
    procedure IRegistriPredefinitiDovrebberoEssereIColoriDelGioco;
    [Test]
    procedure LaDissolvenzaDovrebbeFinireAlNeroInQuattroPassiDaSeiTic;
    [Test]
    procedure IlRitornoDovrebbeFinireAiColoriDelGioco;
    [Test]
    procedure IlBiancoDovrebbeSalireEScendere;
    [Test]
    procedure IColoriDeiRegistriDovrebberoEssereQuelliDellaEga;
    [Test]
    procedure DovrebbeRifiutareUnLivelloCheNonEsiste;
  end;

implementation

uses
  DelphiDoom.Keen.UserWindows, DelphiDoom.Keen.Fader, DelphiDoom.Keen.EgaPalette, DelphiDoom.Keen.ManualClock;

{ TTestKeenUserWindows }

procedure TTestKeenUserWindows.Make(const AScript: string);
begin
  FWorld := TKeenUiWorld.Create(nil, AScript);
end;

procedure TTestKeenUserWindows.TearDown;
begin
  FreeAndNil(FWorld);
end;

procedure TTestKeenUserWindows.UnaFinestraDovrebbeAvereMisureInCaratteriEFondoBianco;
var
  LWindow: TKeenWindowRec;
begin
  Make('');
  FWorld.Windows.DrawWindow(10, 5, 20, 8);
  LWindow := FWorld.Windows.Window;
  Assert.AreEqual(80, LWindow.X);
  Assert.AreEqual(40, LWindow.Y);
  Assert.AreEqual(160, LWindow.W);
  Assert.AreEqual(64, LWindow.H);
  Assert.AreEqual(80, FWorld.Windows.PrintX);
  Assert.AreEqual(40, FWorld.Windows.PrintY);
  FWorld.Buffered.UpdateScreen;
  Assert.AreEqual(KEEN_WHITE, Integer(FWorld.DisplayPixel(80, 40)));
  Assert.AreEqual(KEEN_WHITE, Integer(FWorld.DisplayPixel(239, 103)));
  Assert.AreEqual(0, Integer(FWorld.DisplayPixel(60, 20)), 'outside the frame');
end;

procedure TTestKeenUserWindows.UnaFinestraCentrataDovrebbeStareInMezzoAlloSchermo;
var
  LWindow: TKeenWindowRec;
begin
  Make('');
  FWorld.Windows.CenterWindow(20, 8);
  LWindow := FWorld.Windows.Window;
  // (40 - 20) / 2 = 10 characters from the left, (25 - 8) / 2 = 8 from the top
  Assert.AreEqual(80, LWindow.X);
  Assert.AreEqual(64, LWindow.Y);
end;

procedure TTestKeenUserWindows.LaStampaDovrebbeAvanzareEAndareACapo;
begin
  Make('');
  FWorld.Windows.DrawWindow(4, 4, 30, 10);
  FWorld.Windows.Print('ab');
  Assert.AreEqual(32 + TUiFakeGraphics.CharWidth(Ord('a')) + TUiFakeGraphics.CharWidth(Ord('b')),
    FWorld.Windows.PrintX);
  Assert.AreEqual(32, FWorld.Windows.PrintY);
  FWorld.Windows.Print('c'#10'd');
  Assert.AreEqual(32 + TUiFakeGraphics.CharWidth(Ord('d')), FWorld.Windows.PrintX, 'a line feed goes to the left of the window');
  Assert.AreEqual(32 + UI_FONT_HEIGHT, FWorld.Windows.PrintY);
  FWorld.Windows.Print(#10#10);
  Assert.AreEqual(32, FWorld.Windows.PrintX);
  Assert.AreEqual(32 + 3 * UI_FONT_HEIGHT, FWorld.Windows.PrintY);
end;

procedure TTestKeenUserWindows.IlNumeroDovrebbeEssereStampatoInDecimale;
var
  LWidth: Integer;
  LHeight: Integer;
begin
  Make('');
  FWorld.Windows.DrawWindow(4, 4, 30, 10);
  FWorld.Windows.PrintUnsigned(4000000000);
  FWorld.Buffered.MeasureString('4000000000', LWidth, LHeight);
  Assert.AreEqual(32 + LWidth, FWorld.Windows.PrintX);
  FWorld.Windows.PrintX := 32;
  FWorld.Windows.PrintSigned(-12);
  FWorld.Buffered.MeasureString('-12', LWidth, LHeight);
  Assert.AreEqual(32 + LWidth, FWorld.Windows.PrintX);
end;

procedure TTestKeenUserWindows.LaStampaCentrataDovrebbeMettereIlTestoInMezzo;
var
  LWidth: Integer;
  LHeight: Integer;
  LStart: Integer;
begin
  Make('');
  FWorld.Windows.DrawWindow(5, 5, 20, 4);
  FWorld.Buffered.MeasureString('PAUSED', LWidth, LHeight);
  FWorld.Windows.PrintCentered('PAUSED');
  // px moved from the left edge of the centered text by its width (and by the bits before it, as the assembler does)
  LStart := 40 + ((160 - LWidth) div 2);
  Assert.AreEqual(LStart + (LStart and 7) + LWidth, FWorld.Buffered.Px);
  Assert.AreEqual(40 + ((32 - LHeight) div 2), FWorld.Buffered.Py);
  // the place of the next print is not touched
  Assert.AreEqual(40, FWorld.Windows.PrintX);
end;

procedure TTestKeenUserWindows.LaRigaCentrataDovrebbeScendereDiUnaRiga;
begin
  Make('');
  FWorld.Windows.DrawWindow(5, 5, 20, 8);
  FWorld.Windows.CPrint('one'#10'two');
  Assert.AreEqual(40 + 2 * UI_FONT_HEIGHT, FWorld.Windows.PrintY);
  FWorld.Windows.CPrintLine('three');
  Assert.AreEqual(40 + 3 * UI_FONT_HEIGHT, FWorld.Windows.PrintY);
end;

procedure TTestKeenUserWindows.UnaRigaCentrataTroppoLargaDovrebbeDareEccezione;
begin
  Make('');
  FWorld.Windows.DrawWindow(5, 5, 2, 2);
  Assert.WillRaise(procedure begin FWorld.Windows.CPrintLine('a line that is wider'); end, EKeenException);
end;

procedure TTestKeenUserWindows.SalvareERipristinareDovrebberoRidareLaFinestra;
var
  LSaved: TKeenWindowRec;
begin
  Make('');
  FWorld.Windows.DrawWindow(5, 5, 20, 8);
  FWorld.Windows.Print('xx');
  LSaved := FWorld.Windows.SaveWindow;
  FWorld.Windows.DrawWindow(1, 1, 3, 3);
  FWorld.Windows.RestoreWindow(LSaved);
  Assert.AreEqual(40, FWorld.Windows.Window.X);
  Assert.AreEqual(160, FWorld.Windows.Window.W);
  Assert.AreEqual(LSaved.PX, FWorld.Windows.PrintX);
  LSaved.X := LSaved.X + 8;
  LSaved.W := LSaved.W - 8;
  FWorld.Windows.SetWindow(LSaved);
  Assert.AreEqual(48, FWorld.Windows.Window.X);
  Assert.AreEqual(152, FWorld.Windows.Window.W);
end;

procedure TTestKeenUserWindows.PulireDovrebbeRiportareLaStampaAllInizio;
begin
  Make('');
  FWorld.Windows.DrawWindow(5, 5, 20, 8);
  FWorld.Windows.Print('text'#10'more');
  FWorld.Buffered.UpdateScreen;
  FWorld.Windows.ClearWindow;
  FWorld.Buffered.UpdateScreen;
  Assert.AreEqual(40, FWorld.Windows.PrintX);
  Assert.AreEqual(40, FWorld.Windows.PrintY);
  Assert.AreEqual(KEEN_WHITE, Integer(FWorld.DisplayPixel(41, 41)));
end;

procedure TTestKeenUserWindows.LEditorDovrebbeDareIlTestoBattuto;
var
  LText: AnsiString;
begin
  Make('wait 5'#10'type keen 7'#10'press enter');
  FWorld.Windows.DrawWindow(5, 5, 30, 4);
  LText := 'old';
  Assert.IsTrue(FWorld.Windows.LineInput(40, 40, LText, '', True, 20, 0));
  Assert.AreEqual(AnsiString('keen 7'), LText);
  Assert.AreEqual(0, Integer(FWorld.Input.LastScan), 'the keys are cleared at the end');
end;

procedure TTestKeenUserWindows.LEditorDovrebbeLasciareIlBufferConEscape;
var
  LText: AnsiString;
  LBefore: Cardinal;
begin
  Make('wait 5'#10'type abc'#10'press esc');
  FWorld.Windows.DrawWindow(5, 5, 30, 4);
  FWorld.Buffered.UpdateScreen;
  LBefore := FWorld.ScreenHash;
  LText := 'old';
  Assert.IsFalse(FWorld.Windows.LineInput(40, 40, LText, '', True, 20, 0));
  Assert.AreEqual(AnsiString('old'), LText);
  Assert.AreEqual(LBefore, FWorld.ScreenHash, 'what was typed is XORed away');
end;

procedure TTestKeenUserWindows.LEditorDovrebbeCancellareEInserire;
var
  LText: AnsiString;
begin
  // "abc", backspace takes the c, left and delete take the b, home and x put an x in front
  Make('wait 5'#10'type abc'#10'press backspace'#10'press left'#10'press del'#10'press home'#10'type x'#10 +
    'press end'#10'type z'#10'press enter');
  FWorld.Windows.DrawWindow(5, 5, 30, 4);
  LText := '';
  Assert.IsTrue(FWorld.Windows.LineInput(40, 40, LText, '', True, 20, 0));
  Assert.AreEqual(AnsiString('xaz'), LText);
end;

procedure TTestKeenUserWindows.LEditorDovrebbeRispettareIlNumeroMassimoDiCaratteri;
var
  LText: AnsiString;
begin
  Make('wait 5'#10'type abcdef'#10'press enter');
  FWorld.Windows.DrawWindow(5, 5, 30, 4);
  LText := '';
  Assert.IsTrue(FWorld.Windows.LineInput(40, 40, LText, '', True, 3, 0));
  Assert.AreEqual(AnsiString('abc'), LText);
end;

procedure TTestKeenUserWindows.LEditorDovrebbeRispettareLaLarghezzaMassima;
var
  LText: AnsiString;
  LWidth: Integer;
  LHeight: Integer;
begin
  Make('wait 5'#10'type mmmmmmmmmm'#10'press enter');
  FWorld.Windows.DrawWindow(5, 5, 30, 4);
  LText := '';
  Assert.IsTrue(FWorld.Windows.LineInput(40, 40, LText, '', True, 0, 20));
  // a character is taken while the text is narrower than the limit
  FWorld.Buffered.MeasureString(Copy(LText, 1, Length(LText) - 1), LWidth, LHeight);
  Assert.IsTrue(LWidth < 20);
  FWorld.Buffered.MeasureString(LText, LWidth, LHeight);
  Assert.IsTrue(LWidth >= 20);
end;

procedure TTestKeenUserWindows.LEditorDovrebbeIgnorareEscapeSeNonAmmesso;
var
  LText: AnsiString;
begin
  Make('wait 5'#10'type a'#10'press esc'#10'type b'#10'press enter');
  FWorld.Windows.DrawWindow(5, 5, 30, 4);
  LText := '';
  Assert.IsTrue(FWorld.Windows.LineInput(40, 40, LText, '', False, 0, 0));
  Assert.AreEqual(AnsiString('ab'), LText);
end;

procedure TTestKeenUserWindows.LEditorDovrebbePartireDalTestoPredefinito;
var
  LText: AnsiString;
begin
  Make('wait 5'#10'type 2'#10'press enter');
  FWorld.Windows.DrawWindow(5, 5, 30, 4);
  LText := '';
  Assert.IsTrue(FWorld.Windows.LineInput(40, 40, LText, 'save', True, 0, 0));
  Assert.AreEqual(AnsiString('save2'), LText);
end;

procedure TTestKeenUserWindows.DovrebbeRifiutareIParametriNulli;
begin
  Make('');
  Assert.WillRaise(procedure begin TKeenUserWindows.Create(nil, FWorld.Input, FWorld.Clock); end,
    EArgumentNilException);
  Assert.WillRaise(procedure begin TKeenUserWindows.Create(FWorld.Buffered, nil, FWorld.Clock); end,
    EArgumentNilException);
  Assert.WillRaise(procedure begin TKeenUserWindows.Create(FWorld.Buffered, FWorld.Input, nil); end,
    EArgumentNilException);
end;

{ TTestKeenFader }

procedure TTestKeenFader.IRegistriPredefinitiDovrebberoEssereIColoriDelGioco;
var
  LFader: IKeenFader;
  LRegisters: TKeenPaletteRegisters;
  LIndex: Integer;
begin
  LFader := TKeenFader.Create(TKeenManualClock.Create(1));
  LRegisters := LFader.Registers;
  Assert.IsFalse(LFader.IsFaded);
  // the 16 colors of the picture are the 16 of the EGA monitor
  for LIndex := 0 to 15 do
    Assert.AreEqual(TKeenEgaPalette.Color(LIndex), TKeenFader.RegisterColor(LRegisters[LIndex]),
      'color ' + IntToStr(LIndex));
end;

procedure TTestKeenFader.LaDissolvenzaDovrebbeFinireAlNeroInQuattroPassiDaSeiTic;
var
  LClock: IKeenClock;
  LFader: IKeenFader;
  LRegisters: TKeenPaletteRegisters;
  LIndex: Integer;
begin
  LClock := TKeenManualClock.Create(1);
  LFader := TKeenFader.Create(LClock);
  LFader.FadeOut;
  Assert.AreEqual(4 * KEEN_FADE_STEP_TICS, LClock.TimeCount);
  Assert.IsTrue(LFader.IsFaded);
  LRegisters := LFader.Registers;
  for LIndex := 0 to 15 do
    Assert.AreEqual(0, Integer(LRegisters[LIndex]));
end;

procedure TTestKeenFader.IlRitornoDovrebbeFinireAiColoriDelGioco;
var
  LClock: IKeenClock;
  LFader: IKeenFader;
begin
  LClock := TKeenManualClock.Create(1);
  LFader := TKeenFader.Create(LClock);
  LFader.FadeOut;
  LFader.FadeIn;
  Assert.AreEqual(8 * KEEN_FADE_STEP_TICS, LClock.TimeCount);
  Assert.IsFalse(LFader.IsFaded);
  Assert.AreEqual($1F, Integer(LFader.Registers[15]));
  Assert.AreEqual(1, Integer(LFader.Registers[1]));
  // without a fade
  LFader.FadeOut;
  LFader.SetDefaultColors;
  Assert.IsFalse(LFader.IsFaded);
  Assert.AreEqual(12 * KEEN_FADE_STEP_TICS, LClock.TimeCount, 'the default colors do not wait');
  Assert.AreEqual($18, Integer(LFader.Registers[8]));
end;

procedure TTestKeenFader.IlBiancoDovrebbeSalireEScendere;
var
  LFader: IKeenFader;
  LIndex: Integer;
begin
  LFader := TKeenFader.Create(TKeenManualClock.Create(1));
  LFader.FadeUp;
  Assert.IsTrue(LFader.IsFaded);
  for LIndex := 0 to 15 do
    Assert.AreEqual($1F, Integer(LFader.Registers[LIndex]));
  LFader.FadeDown;
  Assert.IsFalse(LFader.IsFaded);
  Assert.AreEqual(0, Integer(LFader.Registers[0]));
end;

procedure TTestKeenFader.IColoriDeiRegistriDovrebberoEssereQuelliDellaEga;
begin
  Assert.AreEqual(Cardinal($000000), TKeenFader.RegisterColor(0));
  Assert.AreEqual(Cardinal($AA5500), TKeenFader.RegisterColor(6), 'brown, not dark yellow');
  Assert.AreEqual(Cardinal($AAAAAA), TKeenFader.RegisterColor(7));
  Assert.AreEqual(Cardinal($555555), TKeenFader.RegisterColor($18));
  Assert.AreEqual(Cardinal($FFFF55), TKeenFader.RegisterColor($1E));
  Assert.AreEqual(Cardinal($FFFFFF), TKeenFader.RegisterColor($1F));
  // the middle level of a fade: the light colors show as the dark ones
  Assert.AreEqual(1, Integer(TKeenFader.LevelRegisters(1)[9]));
  Assert.AreEqual(0, Integer(TKeenFader.LevelRegisters(2)[7]));
end;

procedure TTestKeenFader.DovrebbeRifiutareUnLivelloCheNonEsiste;
begin
  Assert.WillRaise(procedure begin TKeenFader.LevelRegisters(6); end, EArgumentOutOfRangeException);
  Assert.WillRaise(procedure begin TKeenFader.LevelRegisters(-1); end, EArgumentOutOfRangeException);
  Assert.WillRaise(procedure begin TKeenFader.Create(nil); end, EArgumentNilException);
end;

end.
