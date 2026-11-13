{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Gui library - the expressions of a window          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Gui.Expressions;

interface

uses
  DUnitX.TestFramework, DelphiDoom.Tests.Gui.WindowFakes;

type
  [TestFixture]
  [Category('GuiWindow')]
  TTestGuiExpressions = class
  strict private
    FWorld: TGuiWindowWorld;
    procedure Start(const AText: AnsiString; const ATables: IInterface = nil);
  public
    [TearDown]
    procedure TearDown;
    [Test]
    procedure AritmeticaEPrecedenza;
    [Test]
    procedure ParentesiENumeriNegativi;
    [Test]
    procedure ILConfrontiDanno0o1;
    [Test]
    procedure LeCondizioniEFannoIlCorto;
    [Test]
    procedure IlCondizionaleSceglieIlRamo;
    [Test]
    procedure ModuloIntero;
    [Test]
    procedure ModuloPerZeroDivideUno;
    [Test]
    procedure DivisioneProZeroTienePrimoOperandoEAvvisa;
    [Test]
    procedure UnaVariabileDelGuiSiLeggeDopoUpdate;
    [Test]
    procedure UnNomeDefinitoDopoSiRisolveConFixup;
    [Test]
    procedure UnaTabellaSiLeggeConIndice;
    [Test]
    procedure LaPrimaCostanteHaUnSegnapostoNelRegistroZero;
    [Test]
    procedure LeCostantiUgualiSonoCondivise;
    [Test]
    procedure IlTempoDelRegistroZeroEIlTempoDelGui;
    [Test]
    procedure ILimitiDeiRegistriDannoUnAvviso;
    [Test]
    procedure IlRamoElseComplessoDelCondizionaleValeZeroDifettoDelC;
  end;

implementation

uses
  System.SysUtils, System.Classes, DelphiDoom.Gui.Window, DelphiDoom.Gui.Regs.Store, DelphiDoom.Gui.Regs.Types,
  DelphiDoom.IdLib.Core.Intf, DelphiDoom.Gui.Regs.Intf;

function Floats(const AValues: array of Single): TArray<Single>;
var
  LIndex: Integer;
begin
  SetLength(Result, Length(AValues));
  for LIndex := 0 to High(AValues) do
    Result[LIndex] := AValues[LIndex];
end;

procedure TTestGuiExpressions.Start(const AText: AnsiString; const ATables: IInterface);
var
  LTables: IGuiTables;
begin
  FreeAndNil(FWorld);
  LTables := nil;
  if Assigned(ATables) then
    Supports(ATables, IGuiTables, LTables);
  FWorld := TGuiWindowWorld.Create(LTables);
  FWorld.Load(AText);
end;

procedure TTestGuiExpressions.TearDown;
begin
  FreeAndNil(FWorld);
end;

procedure TTestGuiExpressions.AritmeticaEPrecedenza;
begin
  Start('windowDef Desktop { rect 0, 0, time / 10, 20 + 5 * 2 }');
  Assert.AreEqual(Single(0.0), FWorld.UserInterface.Desktop.Rect.Value.W);
  FWorld.UserInterface.RunFrame(100);
  Assert.AreEqual(Single(10.0), FWorld.UserInterface.Desktop.Rect.Value.W);
  Assert.AreEqual(Single(30.0), FWorld.UserInterface.Desktop.Rect.Value.H);
end;

procedure TTestGuiExpressions.ParentesiENumeriNegativi;
begin
  Start('windowDef Desktop { rect -3, 0, (2 + 3) * 4, 10 - 4 - 3 }');
  FWorld.UserInterface.RunFrame(100);
  Assert.AreEqual(Single(-3.0), FWorld.UserInterface.Desktop.Rect.Value.X);
  Assert.AreEqual(Single(20.0), FWorld.UserInterface.Desktop.Rect.Value.W);
  // the operators of one priority group to the right: 10 - (4 - 3)
  Assert.AreEqual(Single(9.0), FWorld.UserInterface.Desktop.Rect.Value.H);
end;

procedure TTestGuiExpressions.ILConfrontiDanno0o1;
begin
  Start('windowDef Desktop { rect time > 50, time >= 100, time < 100, time != 100 }');
  FWorld.UserInterface.RunFrame(100);
  Assert.AreEqual(Single(1.0), FWorld.UserInterface.Desktop.Rect.Value.X);
  Assert.AreEqual(Single(1.0), FWorld.UserInterface.Desktop.Rect.Value.Y);
  Assert.AreEqual(Single(0.0), FWorld.UserInterface.Desktop.Rect.Value.W);
  Assert.AreEqual(Single(0.0), FWorld.UserInterface.Desktop.Rect.Value.H);
end;

procedure TTestGuiExpressions.LeCondizioniEFannoIlCorto;
begin
  Start('windowDef Desktop { visible time >= 100 && time < 200 }');
  Assert.IsFalse(FWorld.UserInterface.Desktop.Visible.Value);
  FWorld.UserInterface.RunFrame(100);
  Assert.IsTrue(FWorld.UserInterface.Desktop.Visible.Value);
  FWorld.UserInterface.RunFrame(200);
  Assert.IsFalse(FWorld.UserInterface.Desktop.Visible.Value);
end;

procedure TTestGuiExpressions.IlCondizionaleSceglieIlRamo;
begin
  Start('windowDef Desktop { backcolor 1, 0, 0, time > 50 ? 1 : 0.5 }');
  FWorld.UserInterface.RunFrame(40);
  Assert.AreEqual(Single(0.5), FWorld.UserInterface.Desktop.BackColor.Value.W);
  FWorld.UserInterface.RunFrame(100);
  Assert.AreEqual(Single(1.0), FWorld.UserInterface.Desktop.BackColor.Value.W);
end;

procedure TTestGuiExpressions.ModuloIntero;
begin
  Start('windowDef Desktop { rect 0, 0, 17 % 5, 0 }');
  FWorld.UserInterface.RunFrame(100);
  Assert.AreEqual(Single(2.0), FWorld.UserInterface.Desktop.Rect.Value.W);
end;

procedure TTestGuiExpressions.ModuloPerZeroDivideUno;
begin
  Start('windowDef Desktop { rect 0, 0, 17 % 0, 0 }');
  FWorld.UserInterface.RunFrame(100);
  Assert.AreEqual(Single(0.0), FWorld.UserInterface.Desktop.Rect.Value.W);
end;

procedure TTestGuiExpressions.DivisioneProZeroTienePrimoOperandoEAvvisa;
begin
  Start('windowDef Desktop { rect 0, 0, 5 / 0, 0 }');
  FWorld.UserInterface.RunFrame(100);
  Assert.AreEqual(Single(5.0), FWorld.UserInterface.Desktop.Rect.Value.W);
  Assert.IsTrue(FWorld.Lines.IndexOf('W: Divide by zero in window ''Desktop'' in test.gui') >= 0);
end;

procedure TTestGuiExpressions.UnaVariabileDelGuiSiLeggeDopoUpdate;
begin
  FreeAndNil(FWorld);
  FWorld := TGuiWindowWorld.Create;
  FWorld.Load('windowDef Desktop { rect 0, 0, "gui::width", 10 }');
  Assert.IsTrue(FWorld.UserInterface.Desktop.UpdateVarCount > 0);
  FWorld.UserInterface.SetStateString('width', '42');
  FWorld.UserInterface.RunFrame(100);
  Assert.AreEqual(Single(42.0), FWorld.UserInterface.Desktop.Rect.Value.W);
  FWorld.UserInterface.SetStateString('width', '7');
  FWorld.UserInterface.RunFrame(200);
  Assert.AreEqual(Single(7.0), FWorld.UserInterface.Desktop.Rect.Value.W);
end;

procedure TTestGuiExpressions.UnNomeDefinitoDopoSiRisolveConFixup;
begin
  Start('windowDef Desktop { rect 0, 0, later * 2, 0 float later 4 }');
  FWorld.UserInterface.RunFrame(100);
  Assert.AreEqual(Single(8.0), FWorld.UserInterface.Desktop.Rect.Value.W);
  Assert.AreEqual(1, FWorld.UserInterface.Desktop.DefinedVarCount);
end;

procedure TTestGuiExpressions.UnaTabellaSiLeggeConIndice;
begin
  Start('windowDef Desktop { rect 0, 0, sinus[time / 50], 0 }',
    TGuiWindowFakeTables.Create('sinus', Floats([10, 20, 30])));
  FWorld.UserInterface.RunFrame(100);
  Assert.AreEqual(Single(30.0), FWorld.UserInterface.Desktop.Rect.Value.W);
  FWorld.UserInterface.RunFrame(50);
  // the time went back by less than the minimum step: nothing runs
  Assert.AreEqual(Single(30.0), FWorld.UserInterface.Desktop.Rect.Value.W);
end;

procedure TTestGuiExpressions.LaPrimaCostanteHaUnSegnapostoNelRegistroZero;
begin
  Start('windowDef Desktop { rect 0, 0, 5, 0 }');
  // register 0 is the time: the first constant is preceded by a filler
  Assert.AreEqual(Single(-9999999.0), FWorld.UserInterface.Desktop.Store.RegisterValue[0]);
  Assert.AreEqual(Single(0.0), FWorld.UserInterface.Desktop.Store.RegisterValue[1]);
end;

procedure TTestGuiExpressions.LeCostantiUgualiSonoCondivise;
begin
  Start('windowDef Desktop { rect 3, 3, 3, 3 }');
  // one filler and one constant
  Assert.AreEqual(2, FWorld.UserInterface.Desktop.Store.RegisterCount);
  Assert.AreEqual(0, FWorld.UserInterface.Desktop.Store.OpCount);
end;

procedure TTestGuiExpressions.IlTempoDelRegistroZeroEIlTempoDelGui;
begin
  Start('windowDef Desktop { rect time, time + 1, 0, 0 }');
  FWorld.UserInterface.RunFrame(160);
  Assert.AreEqual(Single(160.0), FWorld.UserInterface.Desktop.Rect.Value.X);
  Assert.AreEqual(Single(161.0), FWorld.UserInterface.Desktop.Rect.Value.Y);
end;

procedure TTestGuiExpressions.ILimitiDeiRegistriDannoUnAvviso;
var
  LStore: TGuiExpressionStore;
  LLines: TStringList;
  LIndex: Integer;
  LRegister: Integer;
begin
  LLines := TStringList.Create;
  try
    LStore := TGuiExpressionStore.Create('limit.gui', TGuiWindowFakeLog.Create(LLines));
    try
      for LIndex := 1 to GUI_MAX_EXPRESSION_REGISTERS + 5 do
        LRegister := LStore.ExpressionConstant(LIndex);
      Assert.AreEqual(0, LRegister);
      Assert.AreEqual(GUI_MAX_EXPRESSION_REGISTERS, LStore.RegisterCount);
      Assert.IsTrue(LLines.Count > 0);
      Assert.AreEqual('W: expressionConstant: gui limit.gui hit MAX_EXPRESSION_REGISTERS', LLines[0]);
    finally
      LStore.Free;
    end;
  finally
    LLines.Free;
  end;
end;

procedure TTestGuiExpressions.IlRamoElseComplessoDelCondizionaleValeZeroDifettoDelC;
begin
  // defect of the original, kept: the operation of the conditional comes before the operations of the else
  // branch and every evaluation clears the temporaries, so an else branch that is not a constant or a variable reads 0
  Start('windowDef Desktop { rect 0, 0, time > 1000 ? 1 : 2 + 3 * 4 - 5 + 6 + 7 + 8 + 9, 0 }');
  FWorld.UserInterface.RunFrame(100);
  Assert.AreEqual(Single(0.0), FWorld.UserInterface.Desktop.Rect.Value.W);
  // a constant else branch does work
  Start('windowDef Desktop { rect 0, 0, time > 1000 ? 1 : 7, 0 }');
  FWorld.UserInterface.RunFrame(100);
  Assert.AreEqual(Single(7.0), FWorld.UserInterface.Desktop.Rect.Value.W);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestGuiExpressions);

end.
