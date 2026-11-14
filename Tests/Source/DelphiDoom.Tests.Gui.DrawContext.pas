{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Gui library - the drawing and the events           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Gui.DrawContext;

interface

uses
  DUnitX.TestFramework;

type
  /// <summary>The device context, the painter and the events of the windows on cases the C++ scenarios do not reach</summary>
  [TestFixture]
  [Category('GuiDraw')]
  TTestGuiDrawContext = class
  strict private
    function Run(const AScenario: string): string;
  public
    [Test]
    procedure UnaRigaDiMilleVentiQuattroCaratteriSenzaSpaziDaUnErrore;
    [Test]
    procedure UnaRigaDiMilleVentitreCaratteriSiDisegna;
    [Test]
    procedure UnaLarghezzaNegativaNonFaGirareAVuoto;
    [Test]
    procedure UnDeviceContextSenzaInizializzazioneDaUnErrore;
    [Test]
    procedure IlCursoreLampeggiaSecondoIlNumeroDiTic;
    [Test]
    procedure IlFontCheNonSiCaricaRestaNellaListaEVaOltreIlPrimo;
    [Test]
    procedure IColoriDiInitHannoArancioneEGialloScambiati;
    [Test]
    procedure IlFormatoFissoArrotondaAlPariComePrintf;
    [Test]
    procedure IlRitaglioNonApplicaIlRettangoloZero;
    [Test]
    procedure IlBufferDiDebugDelleFinestreVieneAccumulatoEFiniscePieno;
    [Test]
    procedure UnaGuiSenzaDeviceContextNonDisegnaNulla;
    [Test]
    procedure IlMouseNonPortaIlCursoreSottoZero;
    [Test]
    procedure LeCvarDelleFinestreHannoIValoriDiPartenza;
    [Test]
    procedure IlFuzzingDelleGuiNonDaAccessViolation;
  end;

implementation

uses
  System.SysUtils, System.Classes, System.Generics.Collections, DelphiDoom.IdLib.Math.Vec4, DelphiDoom.Gui.Cvars,
  DelphiDoom.Gui.DrawContext, DelphiDoom.Gui.Rectangle, DelphiDoom.Gui.Window.Painter, DelphiDoom.Gui.Window.Types,
  DelphiDoom.Tests.Gui.DrawFakes, DelphiDoom.Tests.Gui.Harness;

function TTestGuiDrawContext.Run(const AScenario: string): string;
var
  LInput: TStringList;
  LRunner: TGuiHarnessRunner;
begin
  LInput := TStringList.Create;
  LRunner := TGuiHarnessRunner.Create;
  try
    LInput.Text := AScenario;
    LRunner.Run(LInput);
    Result := LRunner.Lines.Text;
  finally
    LRunner.Free;
    LInput.Free;
  end;
end;

procedure TTestGuiDrawContext.UnaRigaDiMilleVentiQuattroCaratteriSenzaSpaziDaUnErrore;
var
  LRaised: Boolean;
begin
  LRaised := False;
  try
    Run('@case a' + #10 + '@op dc text 0.25 0 1 1 1 1 0 0 100000 100 0 -1 0 0 ' + StringOfChar('x', 1100) + #10);
  except
    on E: EGuiDrawException do
      LRaised := True;
  end;
  Assert.IsTrue(LRaised, 'the original writes after its buffer of 1024 bytes');
end;

procedure TTestGuiDrawContext.UnaRigaDiMilleVentitreCaratteriSiDisegna;
begin
  Assert.Contains(Run('@case a' + #10 + '@op dc text 0.25 0 1 1 1 1 0 0 100000 100 0 -1 1 0 ' + StringOfChar('x', 1022) + #10),
    'T ', 'a line that fits the buffer is laid out');
end;

procedure TTestGuiDrawContext.UnaLarghezzaNegativaNonFaGirareAVuoto;
var
  LOutput: string;
begin
  // the original loops for ever (and puts the address of the text in the line breaks) when the width is negative
  try
    LOutput := Run('@case a' + #10 + '@op dc text 0.25 0 1 1 1 1 10 10 -5 100 1 -1 1 0 negative width' + #10);
    Assert.Contains(LOutput, 'T ');
  except
    on E: EGuiDrawException do
      Assert.Pass('a layout that does not advance is an error');
  end;
end;

procedure TTestGuiDrawContext.UnDeviceContextSenzaInizializzazioneDaUnErrore;
var
  LLines: TStringList;
  LContext: TGuiDrawContext;
  LRaised: Boolean;
begin
  LLines := TStringList.Create;
  LContext := TGuiDrawContext.Create(TGuiHarnessSurface.Create(LLines), TGuiHarnessMaterials.Create(LLines),
    TGuiHarnessFiles.Create, nil, nil);
  try
    LRaised := False;
    try
      LContext.MaxCharWidth(0.5);
    except
      on E: EGuiDrawException do
        LRaised := True;
    end;
    Assert.IsTrue(LRaised);
    Assert.IsFalse(LContext.Initialized);
    LRaised := False;
    try
      LContext.SetFont(0);
    except
      on E: EGuiDrawException do
        LRaised := True;
    end;
    Assert.IsTrue(LRaised);
  finally
    LContext.Free;
    LLines.Free;
  end;
end;

procedure TTestGuiDrawContext.IlCursoreLampeggiaSecondoIlNumeroDiTic;
var
  LOn, LOff: string;
begin
  LOn := Run('@case a' + #10 + '@op dc tick 0' + #10 + '@op dc text 0.5 0 1 1 1 1 0 0 300 100 1 2 0 0 abc' + #10);
  LOff := Run('@case a' + #10 + '@op dc tick 16' + #10 + '@op dc text 0.5 0 1 1 1 1 0 0 300 100 1 2 0 0 abc' + #10);
  Assert.IsTrue(Length(LOn) > Length(LOff), 'a tic number with bit 4 set hides the cursor (one picture less)');
end;

procedure TTestGuiDrawContext.IlFontCheNonSiCaricaRestaNellaListaEVaOltreIlPrimo;
var
  LOutput: string;
begin
  LOutput := Run('@case a' + #10 + '@op dc findfont fonts/missing' + #10 + '@op dc findfont fonts/missing' + #10);
  Assert.Contains(LOutput, 'F -1');
  Assert.AreEqual<Integer>(2, Length(LOutput.Split(['F -1'])) - 1, 'each request registers a new empty font');
end;

procedure TTestGuiDrawContext.IColoriDiInitHannoArancioneEGialloScambiati;
var
  LLines: TStringList;
  LContext: TGuiDrawContext;
begin
  LLines := TStringList.Create;
  LContext := TGuiDrawContext.Create(TGuiHarnessSurface.Create(LLines), TGuiHarnessMaterials.Create(LLines),
    TGuiHarnessFiles.Create, nil, nil);
  try
    Assert.AreEqual(TGuiBits.Vec4(TIdVec4.Create(0, 0, 0, 0)), TGuiBits.Vec4(LContext.ColorOrange));
    LContext.Free;
    LContext := nil;
  finally
    LContext.Free;
    LLines.Free;
  end;
  Assert.Pass('the colors are zero until Init, as the statics of the original');
end;

procedure TTestGuiDrawContext.IlFormatoFissoArrotondaAlPariComePrintf;
begin
  Assert.AreEqual('0.2', TGuiWindowPainter.FormatFixed(0.25, 1));
  Assert.AreEqual('0.3', TGuiWindowPainter.FormatFixed(0.35, 1), '0.35 is a bit below the tie in binary');
  Assert.AreEqual('0.4', TGuiWindowPainter.FormatFixed(0.375, 1));
  Assert.AreEqual('2', TGuiWindowPainter.FormatFixed(2.5, 0));
  Assert.AreEqual('4', TGuiWindowPainter.FormatFixed(3.5, 0));
  Assert.AreEqual('10', TGuiWindowPainter.FormatFixed(9.5, 0));
  Assert.AreEqual('-1.5', TGuiWindowPainter.FormatFixed(-1.5, 1));
  Assert.AreEqual('1.0', TGuiWindowPainter.FormatFixed(0.96, 1));
end;

procedure TTestGuiDrawContext.IlRitaglioNonApplicaIlRettangoloZero;
var
  LOutput: string;
begin
  // while( --c > 0 ): with one rectangle nothing is clipped
  LOutput := Run('@case a' + #10 + '@op dc clip 100 100 10 10' + #10 + '@op dc coords 0 0 50 50' + #10);
  Assert.Contains(LOutput, 'O 0 00000000 00000000 42480000 42480000');
end;

procedure TTestGuiDrawContext.IlBufferDiDebugDelleFinestreVieneAccumulatoEFiniscePieno;
var
  LScenario: string;
  LIndex: Integer;
  LRaised: Boolean;
begin
  LScenario := '@case a' + #10 + '@file d.gui' + #10 + 'windowDef Desktop {' + #10 + ' rect 0, 0, 640, 480' + #10 + '}' + #10 +
    '@op load d.gui' + #10 + '@op cvar gui_debug 2' + #10;
  for LIndex := 1 to 200 do
    LScenario := LScenario + '@op redraw ' + IntToStr(LIndex * 20) + #10;
  LRaised := False;
  try
    Run(LScenario);
  except
    on E: EGuiDrawException do
      LRaised := True;
  end;
  Assert.IsTrue(LRaised, 'the static buffer of DebugDraw of the original grows with every window without text');
end;

procedure TTestGuiDrawContext.UnaGuiSenzaDeviceContextNonDisegnaNulla;
var
  LOutput: string;
begin
  LOutput := Run('@case a' + #10 + '@file d.gui' + #10 + 'windowDef Desktop {' + #10 + ' rect 0, 0, 640, 480' + #10 + ' backcolor 1,0,0,1' + #10 + '}' +
    #10 + '@op load d.gui' + #10 + '@op cvar r_skipGuiShaders 1' + #10 + '@op redraw 10' + #10);
  Assert.IsFalse(Pos(#10 + 'Q ', LOutput) > 0);
end;

procedure TTestGuiDrawContext.IlMouseNonPortaIlCursoreSottoZero;
var
  LOutput: string;
begin
  LOutput := Run('@case a' + #10 + '@file d.gui' + #10 + 'windowDef Desktop {' + #10 + ' rect 0, 0, 640, 480' + #10 + '}' + #10 +
    '@op load d.gui' + #10 + '@op event 3 -50 -60 10' + #10);
  Assert.Contains(LOutput, 'cur=00000000 00000000');
end;

procedure TTestGuiDrawContext.LeCvarDelleFinestreHannoIValoriDiPartenza;
var
  LCvars: TGuiCvarSet;
begin
  LCvars := TGuiCvarSet.Create;
  try
    Assert.AreEqual(0, LCvars.GetInteger('gui_debug'));
    Assert.IsFalse(LCvars.GetBool('gui_edit'));
    Assert.AreEqual(Single(0.30), LCvars.GetFloat('gui_smallFontLimit'));
    Assert.IsTrue(LCvars.Exists('SYS_LANG'));
    Assert.IsFalse(LCvars.Exists('nothing'));
    LCvars.SetFloat('x', 1.5);
    Assert.AreEqual('1.500000', string(LCvars.GetString('x')));
    LCvars.SetInteger('y', 7);
    LCvars.SetBool('z', True);
    Assert.AreEqual(7, LCvars.GetInteger('y'));
    Assert.IsTrue(LCvars.GetBool('z'));
    LCvars.Register('y', '9');
    Assert.AreEqual(7, LCvars.GetInteger('y'), 'a variable that exists keeps its value');
  finally
    LCvars.Free;
  end;
end;

procedure TTestGuiDrawContext.IlFuzzingDelleGuiNonDaAccessViolation;
const
  BASE = 'windowDef Desktop {'#10'rect 0, 0, 640, 480'#10'backcolor 0.1, 0.2, 0.3, 1'#10'text "Hello"'#10 +
    'windowDef a {'#10'rect 10, 10, 100, 100'#10'background "m"'#10'rotate 20'#10'onAction { set "cmd" "x" }'#10'}'#10 +
    'windowDef b {'#10'rect 200, 10, 50, 50'#10'text "text ^1red"'#10'shadow 1'#10'}'#10'}'#10;
  PIECES: array[0..19] of string = ('{', '}', '"', ' ', #10, 'rect ', 'text ', '1e99', '-1', '0', 'time', '(', ')', ';',
    'onAction ', 'rotate ', 'visible ', 'windowDef ', 'background ', '^');
var
  LSeed, LIndex, LRuns, LKind: Integer;
  LText: string;
  LScenario: string;
  LRandom: Cardinal;

  function Next(const ARange: Integer): Integer;
  begin
    LRandom := LRandom * 1664525 + 1013904223;
    Result := Integer((LRandom shr 8) mod Cardinal(ARange));
  end;

begin
  LRuns := 0;
  for LSeed := 1 to 150 do
  begin
    LRandom := Cardinal(LSeed) * 2654435761;
    LText := BASE;
    for LIndex := 1 to 1 + Next(6) do
    begin
      LKind := Next(3);
      if (LKind = 0) and (Length(LText) > 4) then
        Delete(LText, 1 + Next(Length(LText) - 2), 1 + Next(8))
      else if LKind = 1 then
        Insert(PIECES[Next(Length(PIECES))], LText, 1 + Next(Length(LText)))
      else if Length(LText) > 4 then
        LText[1 + Next(Length(LText))] := Char(32 + Next(95));
    end;
    LScenario := '@case fuzz' + #10 + '@file f.gui' + #10 + LText + #10 + '@op load f.gui' + #10 + '@op redraw 10' + #10 +
      '@op event 3 30 30 20' + #10 + '@op event 1 187 1 30' + #10 + '@op event 1 9 1 40' + #10 + '@op event 1 187 0 50' + #10 +
      '@op frame 100' + #10 + '@op redraw 120' + #10;
    try
      Run(LScenario);
    except
      on E: EAccessViolation do
        Assert.Fail(Format('seed %d: access violation: %s', [LSeed, E.Message]));
      on E: EInvalidPointer do
        Assert.Fail(Format('seed %d: invalid pointer', [LSeed]));
      on E: ERangeError do
        Assert.Fail(Format('seed %d: range error: %s', [LSeed, E.Message]));
      on E: EListError do
        Assert.Fail(Format('seed %d: list error: %s', [LSeed, E.Message]));
      on E: EInvalidOp do
        Assert.Fail(Format('seed %d: invalid operation', [LSeed]));
      on E: EDivByZero do
        Assert.Fail(Format('seed %d: division by zero', [LSeed]));
      on E: EIntOverflow do
        Assert.Fail(Format('seed %d: integer overflow', [LSeed]));
      on E: EOverflow do
        Assert.Fail(Format('seed %d: overflow', [LSeed]));
      on E: Exception do
        Inc(LRuns);
    end;
  end;
  Assert.IsTrue(LRuns >= 0);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestGuiDrawContext);

end.
