{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the parity library - memory that starts at zero        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Parity.MemoryZeroing;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.Parity.MemoryZeroing;

type
  [TestFixture]
  [Category('parity')]
  TTestParityMemoryZeroing = class(TObject)
  public
    [TearDown]
    procedure TearDown;

    [Test]
    procedure NonDovrebbeEssereInstallatoDiPartenza;
    [Test]
    procedure DovrebbeEssereInstallatoDopoInstall;
    [Test]
    procedure InstallDueVolteNonDovrebbeFarNulla;
    [Test]
    procedure UnBloccoRiusatoDovrebbePartireDaZero;
    [Test]
    procedure UnBloccoGrandeDovrebbePartireDaZero;
    [Test]
    procedure UninstallDovrebbeRimettereIlGestoreDiPrima;
    [Test]
    procedure LaMemoriaDataPrimaDiInstallDovrebbeRestareValida;
  end;

implementation

procedure TTestParityMemoryZeroing.TearDown;
begin
  TParityMemoryZeroing.Uninstall;
end;

procedure TTestParityMemoryZeroing.NonDovrebbeEssereInstallatoDiPartenza;
begin
  Assert.IsFalse(TParityMemoryZeroing.IsInstalled);
end;

procedure TTestParityMemoryZeroing.DovrebbeEssereInstallatoDopoInstall;
begin
  TParityMemoryZeroing.Install;
  Assert.IsTrue(TParityMemoryZeroing.IsInstalled);
end;

procedure TTestParityMemoryZeroing.InstallDueVolteNonDovrebbeFarNulla;
begin
  TParityMemoryZeroing.Install;
  TParityMemoryZeroing.Install;
  TParityMemoryZeroing.Uninstall;
  Assert.IsFalse(TParityMemoryZeroing.IsInstalled);
end;

procedure TTestParityMemoryZeroing.UnBloccoRiusatoDovrebbePartireDaZero;
var
  LBlock: PByte;
  LIndex: Integer;
  LRound: Integer;
begin
  TParityMemoryZeroing.Install;
  // a block that held other numbers comes back: the allocator reuses blocks of the same size
  for LRound := 1 to 50 do
  begin
    GetMem(LBlock, 300);
    for LIndex := 0 to 299 do
      LBlock[LIndex] := $AB;
    FreeMem(LBlock);
    GetMem(LBlock, 300);
    try
      for LIndex := 0 to 299 do
        Assert.AreEqual(Byte(0), LBlock[LIndex], 'byte ' + IntToStr(LIndex));
    finally
      FreeMem(LBlock);
    end;
  end;
end;

procedure TTestParityMemoryZeroing.UnBloccoGrandeDovrebbePartireDaZero;
var
  LBlock: PByte;
  LIndex: Integer;
begin
  TParityMemoryZeroing.Install;
  GetMem(LBlock, 1024 * 1024);
  try
    for LIndex := 0 to 1024 * 1024 - 1 do
      if LBlock[LIndex] <> 0 then
        Assert.Fail('byte ' + IntToStr(LIndex));
  finally
    FreeMem(LBlock);
  end;
  Assert.Pass;
end;

procedure TTestParityMemoryZeroing.UninstallDovrebbeRimettereIlGestoreDiPrima;
var
  LBefore: TMemoryManagerEx;
  LAfter: TMemoryManagerEx;
begin
  GetMemoryManager(LBefore);
  TParityMemoryZeroing.Install;
  TParityMemoryZeroing.Uninstall;
  GetMemoryManager(LAfter);
  Assert.IsTrue(@LBefore.GetMem = @LAfter.GetMem);
end;

procedure TTestParityMemoryZeroing.LaMemoriaDataPrimaDiInstallDovrebbeRestareValida;
var
  LBlock: PByte;
begin
  GetMem(LBlock, 100);
  LBlock[0] := 7;
  TParityMemoryZeroing.Install;
  try
    LBlock[1] := 8;
    Assert.AreEqual(Byte(7), LBlock[0]);
  finally
    FreeMem(LBlock);
  end;
end;

end.
