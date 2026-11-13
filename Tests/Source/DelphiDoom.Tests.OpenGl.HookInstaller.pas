{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the OpenGL call recorder - table and installer         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.OpenGl.HookInstaller;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.OpenGl.Recorder.HookTable,
  DelphiDoom.OpenGl.Recorder.Installer, DelphiDoom.OpenGl.Recorder.Intf;

type
  /// <summary>The installer with a table of fake functions: variables of the test instead of those of the binding</summary>
  [TestFixture]
  [Category('opengl')]
  TTestOpenGlHookInstaller = class(TObject)
  strict private
    FSlotA: Pointer;
    FSlotB: Pointer;
    FSlotC: Pointer;
    FTable: TGlHookTable;
    FTableIntf: IGlHookTable;
    FInstaller: TGlHookInstaller;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeSostituireLeFunzioniPresenti;
    [Test]
    procedure DovrebbeSalvareLeFunzioniOriginali;
    [Test]
    procedure DovrebbeSaltareUnaFunzioneMancante;
    [Test]
    procedure DovrebbeElencareLeFunzioniMancanti;
    [Test]
    procedure DovrebbeRimettereLeFunzioniOriginali;
    [Test]
    procedure DovrebbeLasciareUnaVariabileCambiataDaAltri;
    [Test]
    procedure DovrebbeNonRimettereUnaFunzioneMancante;
    [Test]
    procedure DovrebbeSollevareUnErroreSeSiInstallaDueVolte;
    [Test]
    procedure DovrebbePotersiRiinstallareDopoUninstall;
    [Test]
    procedure DovrebbeSollevareUnErroreSeLaTabellaEMancante;
    [Test]
    procedure DovrebbeNonFareNullaSeLaTabellaEVuota;
    [Test]
    procedure DovrebbeSollevareUnErroreSeLIndiceNonEsiste;
    [Test]
    procedure DovrebbeUsareLArrayDegliOriginaliDiChiLoDa;
  end;

implementation

uses
  DelphiDoom.OpenGl.Recorder.Types;

const
  THUNK_A = Pointer($1001);
  THUNK_B = Pointer($1002);
  THUNK_C = Pointer($1003);
  ORIGINAL_A = Pointer($2001);
  ORIGINAL_B = Pointer($2002);

{ TTestOpenGlHookInstaller }

procedure TTestOpenGlHookInstaller.Setup;
begin
  FSlotA := ORIGINAL_A;
  FSlotB := ORIGINAL_B;
  FSlotC := nil;
  FTable := TGlHookTable.Create;
  FTableIntf := FTable;
  FTable.Add('glA', @FSlotA, THUNK_A);
  FTable.Add('glB', @FSlotB, THUNK_B);
  FTable.Add('glC', @FSlotC, THUNK_C);
  FInstaller := TGlHookInstaller.Create(FTableIntf);
end;

procedure TTestOpenGlHookInstaller.TearDown;
begin
  FInstaller.Free;
  FTable := nil;
  FTableIntf := nil;
end;

procedure TTestOpenGlHookInstaller.DovrebbeSostituireLeFunzioniPresenti;
begin
  Assert.AreEqual(2, FInstaller.Install);
  Assert.IsTrue(FSlotA = THUNK_A);
  Assert.IsTrue(FSlotB = THUNK_B);
  Assert.IsTrue(FInstaller.Installed);
end;

procedure TTestOpenGlHookInstaller.DovrebbeSalvareLeFunzioniOriginali;
begin
  FInstaller.Install;
  Assert.IsTrue(FTable.Original(0) = ORIGINAL_A);
  Assert.IsTrue(FTable.Original(1) = ORIGINAL_B);
end;

procedure TTestOpenGlHookInstaller.DovrebbeSaltareUnaFunzioneMancante;
begin
  FInstaller.Install;
  Assert.IsTrue(FSlotC = nil);
end;

procedure TTestOpenGlHookInstaller.DovrebbeElencareLeFunzioniMancanti;
begin
  FInstaller.Install;
  Assert.AreEqual<Integer>(1, Length(FInstaller.Missing));
  Assert.AreEqual('glC', FInstaller.Missing[0]);
end;

procedure TTestOpenGlHookInstaller.DovrebbeRimettereLeFunzioniOriginali;
begin
  FInstaller.Install;
  FInstaller.Uninstall;
  Assert.IsTrue(FSlotA = ORIGINAL_A);
  Assert.IsTrue(FSlotB = ORIGINAL_B);
  Assert.IsFalse(FInstaller.Installed);
end;

procedure TTestOpenGlHookInstaller.DovrebbeLasciareUnaVariabileCambiataDaAltri;
begin
  FInstaller.Install;
  FSlotA := Pointer($3001);
  FInstaller.Uninstall;
  Assert.IsTrue(FSlotA = Pointer($3001));
  Assert.IsTrue(FSlotB = ORIGINAL_B);
end;

procedure TTestOpenGlHookInstaller.DovrebbeNonRimettereUnaFunzioneMancante;
begin
  FInstaller.Install;
  FInstaller.Uninstall;
  Assert.IsTrue(FSlotC = nil);
end;

procedure TTestOpenGlHookInstaller.DovrebbeSollevareUnErroreSeSiInstallaDueVolte;
begin
  FInstaller.Install;
  Assert.WillRaise(
    procedure
    begin
      FInstaller.Install;
    end, EGlRecorderException);
end;

procedure TTestOpenGlHookInstaller.DovrebbePotersiRiinstallareDopoUninstall;
begin
  FInstaller.Install;
  FInstaller.Uninstall;
  Assert.AreEqual(2, FInstaller.Install);
  Assert.IsTrue(FSlotA = THUNK_A);
end;

procedure TTestOpenGlHookInstaller.DovrebbeSollevareUnErroreSeLaTabellaEMancante;
begin
  Assert.WillRaise(
    procedure
    begin
      TGlHookInstaller.Create(nil).Free;
    end, EArgumentNilException);
end;

procedure TTestOpenGlHookInstaller.DovrebbeNonFareNullaSeLaTabellaEVuota;
var
  LEmpty: IGlHookTable;
  LInstaller: TGlHookInstaller;
begin
  LEmpty := TGlHookTable.Create;
  LInstaller := TGlHookInstaller.Create(LEmpty);
  try
    Assert.AreEqual(0, LInstaller.Install);
    Assert.AreEqual<Integer>(0, Length(LInstaller.Missing));
  finally
    LInstaller.Free;
  end;
end;

procedure TTestOpenGlHookInstaller.DovrebbeSollevareUnErroreSeLIndiceNonEsiste;
begin
  Assert.WillRaise(
    procedure
    begin
      FTable.Name(3);
    end, EGlRecorderException);
  Assert.WillRaise(
    procedure
    begin
      FTable.Slot(-1);
    end, EGlRecorderException);
  Assert.WillRaise(
    procedure
    begin
      FTable.Thunk(9);
    end, EGlRecorderException);
  Assert.WillRaise(
    procedure
    begin
      FTable.SetOriginal(9, nil);
    end, EGlRecorderException);
end;

procedure TTestOpenGlHookInstaller.DovrebbeUsareLArrayDegliOriginaliDiChiLoDa;
var
  LOriginals: array[0..1] of Pointer;
  LTable: IGlHookTable;
  LTableObject: TGlHookTable;
  LSlot: Pointer;
  LInstaller: TGlHookInstaller;
begin
  // le thunk generate leggono gli originali da un loro array: la tabella deve scriverci
  LSlot := ORIGINAL_A;
  LOriginals[0] := nil;
  LOriginals[1] := nil;
  LTableObject := TGlHookTable.Create(@LOriginals[0]);
  LTable := LTableObject;
  LTableObject.Add('glA', @LSlot, THUNK_A);
  LInstaller := TGlHookInstaller.Create(LTable);
  try
    LInstaller.Install;
    Assert.IsTrue(LOriginals[0] = ORIGINAL_A);
  finally
    LInstaller.Free;
  end;
end;

end.
