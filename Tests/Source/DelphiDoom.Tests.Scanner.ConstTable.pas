{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the table of the named constants (DUnitX)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Scanner.ConstTable;

interface

uses
  DUnitX.TestFramework,
  DelphiDoom.Scanner.ConstTable;

type
  [TestFixture]
  [Category('scanner')]
  TTestScannerConstTable = class
  strict private
    FTable: TScannerConstTable;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeAggiungereELeggereUnaCostante;
    [Test]
    procedure DovrebbeIgnorareMaiuscoleEBlankDelNome;
    [Test]
    procedure DovrebbeRifiutareUnNomeVuoto;
    [Test]
    procedure DovrebbeRifiutareUnNomeRipetutoELasciareIlValoreVecchio;
    [Test]
    procedure DovrebbeDareFalsoPerUnNomeCheManca;
    [Test]
    procedure DovrebbeContareLeCostanti;
    [Test]
    procedure DovrebbeDareGliStessiRisultatiDelVecchioCodiceSuOperazioniCasuali;
  end;

implementation

uses
  System.SysUtils,
  d_delphi,
  DelphiDoom.Tests.InfoTables.LegacyTokens;

procedure TTestScannerConstTable.Setup;
begin
  FTable := TScannerConstTable.Create;
end;

procedure TTestScannerConstTable.TearDown;
begin
  FTable.Free;
end;

procedure TTestScannerConstTable.DovrebbeAggiungereELeggereUnaCostante;
var
  LValue: Integer;
begin
  Assert.AreEqual(carAdded, FTable.Add('AAPTR_TARGET', 7));
  Assert.IsTrue(FTable.TryGet('AAPTR_TARGET', LValue));
  Assert.AreEqual(7, LValue);
end;

procedure TTestScannerConstTable.DovrebbeIgnorareMaiuscoleEBlankDelNome;
var
  LValue: Integer;
begin
  FTable.Add('  c_arg1 ', 3);
  Assert.IsTrue(FTable.TryGet('C_ARG1', LValue));
  Assert.AreEqual(3, LValue);
  Assert.IsTrue(FTable.TryGet(' c_Arg1', LValue));
end;

procedure TTestScannerConstTable.DovrebbeRifiutareUnNomeVuoto;
begin
  Assert.AreEqual(carEmptyName, FTable.Add('   ', 1));
  Assert.AreEqual(0, FTable.Count);
end;

procedure TTestScannerConstTable.DovrebbeRifiutareUnNomeRipetutoELasciareIlValoreVecchio;
var
  LValue: Integer;
begin
  FTable.Add('X', 1);
  Assert.AreEqual(carDuplicate, FTable.Add('x', 2));
  FTable.TryGet('X', LValue);
  Assert.AreEqual(1, LValue);
end;

procedure TTestScannerConstTable.DovrebbeDareFalsoPerUnNomeCheManca;
var
  LValue: Integer;
begin
  LValue := 99;
  Assert.IsFalse(FTable.TryGet('NOPE', LValue));
  Assert.IsFalse(FTable.TryGet('', LValue));
end;

procedure TTestScannerConstTable.DovrebbeContareLeCostanti;
begin
  FTable.Add('A', 1);
  FTable.Add('B', 2);
  FTable.Add('A', 3);
  Assert.AreEqual(2, FTable.Count);
end;

procedure TTestScannerConstTable.DovrebbeDareGliStessiRisultatiDelVecchioCodiceSuOperazioniCasuali;
const
  Names: array[0..9] of string = ('AB', 'ab', ' ab ', 'C_ARG1', 'c_arg1', '', '  ', 'ZZ', 'Zz9', 'é');
var
  LStep: Integer;
  LName: string;
  LNewValue: Integer;
  LOldValue: Integer;
  LOldResult: Boolean;
  LNewResult: Boolean;
  LAddResult: TScannerConstAddResult;
begin
  RandSeed := 187;
  Legacy_InitConsts;
  try
    for LStep := 1 to 4000 do
    begin
      LName := Names[Random(Length(Names))];
      if Random(2) = 0 then
        LName := LName + IntToStr(Random(40));
      if Random(2) = 0 then
      begin
        LOldResult := Legacy_AddConst(LName, LStep);
        LAddResult := FTable.Add(LName, LStep);
        Assert.AreEqual(LOldResult, LAddResult = carAdded, 'add ' + LName);
      end
      else
      begin
        LOldValue := -5;
        LNewValue := -5;
        LOldResult := Legacy_GetConst(LName, LOldValue);
        LNewResult := FTable.TryGet(LName, LNewValue);
        Assert.AreEqual(LOldResult, LNewResult, 'get ' + LName);
        if LOldResult then
          Assert.AreEqual(LOldValue, LNewValue, 'value ' + LName);
      end;
    end;
    Assert.IsTrue(LegacyConstWarnings.Count > 0);
  finally
    Legacy_ShutDownConsts;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestScannerConstTable);

end.
