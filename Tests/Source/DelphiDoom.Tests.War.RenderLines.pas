{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - the lines of the debug drawing        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.RenderLines;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.War.Render.Types, DelphiDoom.War.Render.Blitter,
  DelphiDoom.War.Render.Transform;

type
  /// <summary>wr_strokeLine and SDL_RenderLine: a line along a row or a column, with the transform of the state</summary>
  [TestFixture]
  [Category('war')]
  TTestWarRenderLines = class(TObject)
  strict private
    FBlitter: TWarImageBlitter;
    function PixelRed(AX, AY: Integer): Integer;
    function Red: TWarRgba;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeDisegnareUnaRigaConLeDueEstremita;
    [Test]
    procedure DovrebbeDisegnareUnaColonnaEInvertireLeEstremita;
    [Test]
    procedure DovrebbeTagliareLeEstremitaAdIntero;
    [Test]
    procedure DovrebbeTagliareAlBordoDellaTela;
    [Test]
    procedure DovrebbeFondereUnColoreTrasparente;
    [Test]
    procedure DovrebbeRifiutareUnaRigaObliqua;
    [Test]
    procedure DovrebbeTrasformareIPuntiConLoStatoELaScala;
    [Test]
    procedure DovrebbeRaccontareLaRigaAChiAscolta;
    [Test]
    procedure DovrebbeRifiutareUnaRigaSenzaTela;
  end;

implementation

uses
  System.Generics.Collections, DelphiDoom.War.Types;

type
  TLineTrace = class(TInterfacedObject, IWarRenderTrace)
  public
    Lines: TList<string>;
    constructor Create;
    destructor Destroy; override;
    procedure TraceBlit(const ABlit: TWarBlit);
    procedure TraceRect(const ARect: TWarRectF; const AColor: TWarRgba; AStroke: Boolean);
    procedure TraceLine(AX1, AY1, AX2, AY2: Single; const AColor: TWarRgba);
  end;

constructor TLineTrace.Create;
begin
  inherited Create;
  Lines := TList<string>.Create;
end;

destructor TLineTrace.Destroy;
begin
  Lines.Free;
  inherited Destroy;
end;

procedure TLineTrace.TraceBlit(const ABlit: TWarBlit);
begin
end;

procedure TLineTrace.TraceRect(const ARect: TWarRectF; const AColor: TWarRgba; AStroke: Boolean);
begin
end;

procedure TLineTrace.TraceLine(AX1, AY1, AX2, AY2: Single; const AColor: TWarRgba);
begin
  Lines.Add(Format('%g %g %g %g a%d', [AX1, AY1, AX2, AY2, AColor.A], TFormatSettings.Invariant));
end;

{ TTestWarRenderLines }

procedure TTestWarRenderLines.Setup;
var
  LBlack: TWarRgba;
begin
  FBlitter := TWarImageBlitter.Create(20, 10);
  LBlack.R := 0;
  LBlack.G := 0;
  LBlack.B := 0;
  LBlack.A := 255;
  FBlitter.Clear(LBlack);
end;

procedure TTestWarRenderLines.TearDown;
begin
  FBlitter.Free;
end;

function TTestWarRenderLines.PixelRed(AX, AY: Integer): Integer;
begin
  Result := FBlitter.Pixels[(AY * FBlitter.Width + AX) * 4];
end;

function TTestWarRenderLines.Red: TWarRgba;
begin
  Result.R := 255;
  Result.G := 0;
  Result.B := 0;
  Result.A := 255;
end;

procedure TTestWarRenderLines.DovrebbeDisegnareUnaRigaConLeDueEstremita;
var
  LX: Integer;
begin
  FBlitter.StrokeLine(2, 4, 7, 4, Red);
  for LX := 0 to 19 do
    if (LX >= 2) and (LX <= 7) then
      Assert.AreEqual(255, PixelRed(LX, 4), 'x ' + IntToStr(LX))
    else
      Assert.AreEqual(0, PixelRed(LX, 4), 'x ' + IntToStr(LX));
  Assert.AreEqual(0, PixelRed(4, 3));
  Assert.AreEqual(0, PixelRed(4, 5));
end;

procedure TTestWarRenderLines.DovrebbeDisegnareUnaColonnaEInvertireLeEstremita;
var
  LY: Integer;
begin
  FBlitter.StrokeLine(5, 8, 5, 2, Red);
  for LY := 0 to 9 do
    if (LY >= 2) and (LY <= 8) then
      Assert.AreEqual(255, PixelRed(5, LY), 'y ' + IntToStr(LY))
    else
      Assert.AreEqual(0, PixelRed(5, LY), 'y ' + IntToStr(LY));
  FBlitter.StrokeLine(12, 3, 9, 3, Red);
  Assert.AreEqual(255, PixelRed(9, 3));
  Assert.AreEqual(255, PixelRed(12, 3));
end;

procedure TTestWarRenderLines.DovrebbeTagliareLeEstremitaAdIntero;
begin
  // each end is the floor of the float: 3.9 is 3 and -0.5 is -1 (outside)
  FBlitter.StrokeLine(3.9, 1.7, 6.2, 1.2, Red);
  Assert.AreEqual(255, PixelRed(3, 1));
  Assert.AreEqual(255, PixelRed(6, 1));
  Assert.AreEqual(0, PixelRed(7, 1));
  FBlitter.StrokeLine(-0.5, 6, 2.5, 6, Red);
  Assert.AreEqual(255, PixelRed(0, 6));
  Assert.AreEqual(255, PixelRed(2, 6));
  Assert.AreEqual(0, PixelRed(3, 6));
end;

procedure TTestWarRenderLines.DovrebbeTagliareAlBordoDellaTela;
begin
  FBlitter.StrokeLine(-50, 2, 500, 2, Red);
  Assert.AreEqual(255, PixelRed(0, 2));
  Assert.AreEqual(255, PixelRed(19, 2));
  FBlitter.StrokeLine(8, -9, 8, 99, Red);
  Assert.AreEqual(255, PixelRed(8, 0));
  Assert.AreEqual(255, PixelRed(8, 9));
  // outside the canvas: nothing
  FBlitter.StrokeLine(0, -3, 19, -3, Red);
  FBlitter.StrokeLine(0, 30, 19, 30, Red);
  FBlitter.StrokeLine(-4, 0, -4, 9, Red);
  FBlitter.StrokeLine(40, 0, 40, 9, Red);
  Assert.AreEqual(0, PixelRed(0, 0));
  Assert.AreEqual(0, PixelRed(19, 9));
end;

procedure TTestWarRenderLines.DovrebbeFondereUnColoreTrasparente;
var
  LColor: TWarRgba;
begin
  LColor := Red;
  LColor.A := 128;
  FBlitter.StrokeLine(1, 1, 4, 1, LColor);
  // 255 * 128 / 255 = 128 over black
  Assert.AreEqual(128, PixelRed(2, 1));
end;

procedure TTestWarRenderLines.DovrebbeRifiutareUnaRigaObliqua;
begin
  Assert.WillRaise(
    procedure
    begin
      FBlitter.StrokeLine(1, 1, 5, 4, Red);
    end, EWarException);
end;

procedure TTestWarRenderLines.DovrebbeTrasformareIPuntiConLoStatoELaScala;
var
  LTransform: TWarRenderTransform;
begin
  LTransform := TWarRenderTransform.Create(FBlitter);
  try
    LTransform.Save;
    LTransform.Translate(3, 2);
    LTransform.Scale(2, 1);
    // x 1 to 3 in the units of the state: 3 + 1 * 2 = 5 to 3 + 3 * 2 = 9, on the row 2 + 1 = 3
    LTransform.StrokeLine(1, 1, 3, 1, Red);
    LTransform.Restore;
  finally
    LTransform.Free;
  end;
  Assert.AreEqual(0, PixelRed(4, 3));
  Assert.AreEqual(255, PixelRed(5, 3));
  Assert.AreEqual(255, PixelRed(9, 3));
  Assert.AreEqual(0, PixelRed(10, 3));
end;

procedure TTestWarRenderLines.DovrebbeRaccontareLaRigaAChiAscolta;
var
  LTransform: TWarRenderTransform;
  LTrace: TLineTrace;
  LRef: IWarRenderTrace;
begin
  LTrace := TLineTrace.Create;
  LRef := LTrace;
  LTransform := TWarRenderTransform.Create(FBlitter);
  try
    LTransform.Trace := LRef;
    LTransform.GlobalAlpha(0.5);
    LTransform.StrokeLine(0, 4, 10, 4, Red);
    LTransform.Trace := nil;
  finally
    LTransform.Free;
  end;
  Assert.AreEqual(1, LTrace.Lines.Count);
  // the alpha is the one of the color times the state: (u8)(255 * 0.5)
  Assert.AreEqual('0 4 10 4 a127', LTrace.Lines[0]);
end;

procedure TTestWarRenderLines.DovrebbeRifiutareUnaRigaSenzaTela;
var
  LTransform: TWarRenderTransform;
begin
  LTransform := TWarRenderTransform.Create(TList<TWarBlit>(nil));
  try
    Assert.WillRaise(
      procedure
      begin
        LTransform.StrokeLine(0, 0, 5, 0, Red);
      end, EWarException);
  finally
    LTransform.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestWarRenderLines);

end.
