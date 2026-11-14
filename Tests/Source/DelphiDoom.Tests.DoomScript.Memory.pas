{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the Doom script library - TDoomScriptMemory       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.DoomScript.Memory;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.DoomScript.Types, DelphiDoom.Tests.DoomScript.Support;

type
  [TestFixture]
  [Category('DoomScript')]
  TTestDoomScriptMemory = class
  private
    FCell: array[0..DS_MAX_STRING_LEN - 1] of Byte;
    procedure Fill(const AValue: Byte);
    function CountZerosFrom(const AIndex: Integer): Integer;
  public
    [Test]
    procedure DovrebbeCopiareIlTestoERiempireDiZeri;
    [Test]
    procedure DovrebbeTroncareIlTestoLungoA127Caratteri;
    [Test]
    procedure DovrebbeFermarsiAlPrimoZeroDelTesto;
    [Test]
    procedure DovrebbeRispettareLaDimensioneData;
    [Test]
    procedure DovrebbeCopiareIlTestoVuoto;
    [Test]
    procedure DovrebbeLeggereFinoAlTerminatore;
    [Test]
    procedure DovrebbeLeggereAlPiu127CaratteriSenzaTerminatore;
    [Test]
    procedure DovrebbeAccodareIlTesto;
    [Test]
    procedure DovrebbeTroncareLAccodamentoAllaFineDellaCella;
    [Test]
    procedure DovrebbeDareErroreSeLaCellaNonHaTerminatore;
  end;

implementation

procedure TTestDoomScriptMemory.Fill(const AValue: Byte);
begin
  FillChar(FCell, SizeOf(FCell), AValue);
end;

function TTestDoomScriptMemory.CountZerosFrom(const AIndex: Integer): Integer;
var
  LIndex: Integer;
begin
  Result := 0;
  for LIndex := AIndex to DS_MAX_STRING_LEN - 1 do
    if FCell[LIndex] = 0 then
      Inc(Result);
end;

procedure TTestDoomScriptMemory.DovrebbeCopiareIlTestoERiempireDiZeri;
begin
  Fill($FF);
  TDoomScriptMemory.CopyString(@FCell[0], 'abc');
  Assert.AreEqual(Ord('a'), Integer(FCell[0]));
  Assert.AreEqual(Ord('c'), Integer(FCell[2]));
  // as strncpy does, the rest of the cell is zero
  Assert.AreEqual(DS_MAX_STRING_LEN - 3, CountZerosFrom(3));
end;

procedure TTestDoomScriptMemory.DovrebbeTroncareIlTestoLungoA127Caratteri;
var
  LText: AnsiString;
begin
  Fill($FF);
  LText := StringOfChar(AnsiChar('x'), 200);
  TDoomScriptMemory.CopyString(@FCell[0], LText);
  Assert.AreEqual(Ord('x'), Integer(FCell[126]));
  Assert.AreEqual(0, Integer(FCell[127]));
  Assert.AreEqual<Integer>(127, Length(TDoomScriptMemory.ReadString(@FCell[0])));
end;

procedure TTestDoomScriptMemory.DovrebbeFermarsiAlPrimoZeroDelTesto;
begin
  Fill($FF);
  TDoomScriptMemory.CopyString(@FCell[0], 'ab'#0'cd');
  Assert.AreEqual('ab', string(TDoomScriptMemory.ReadString(@FCell[0])));
  Assert.AreEqual(DS_MAX_STRING_LEN - 2, CountZerosFrom(2));
end;

procedure TTestDoomScriptMemory.DovrebbeRispettareLaDimensioneData;
begin
  Fill($FF);
  TDoomScriptMemory.CopyString(@FCell[0], 'abcdef', 4);
  Assert.AreEqual(Ord('c'), Integer(FCell[2]));
  Assert.AreEqual(0, Integer(FCell[3]));
  Assert.AreEqual($FF, Integer(FCell[4]));
  // nothing is written for a size that is not positive
  Fill($EE);
  TDoomScriptMemory.CopyString(@FCell[0], 'abc', 0);
  Assert.AreEqual($EE, Integer(FCell[0]));
end;

procedure TTestDoomScriptMemory.DovrebbeCopiareIlTestoVuoto;
begin
  Fill($FF);
  TDoomScriptMemory.CopyString(@FCell[0], '');
  Assert.AreEqual(DS_MAX_STRING_LEN, CountZerosFrom(0));
  Assert.AreEqual('', string(TDoomScriptMemory.ReadString(@FCell[0])));
end;

procedure TTestDoomScriptMemory.DovrebbeLeggereFinoAlTerminatore;
begin
  Fill(Ord('z'));
  FCell[0] := Ord('h');
  FCell[1] := Ord('i');
  FCell[2] := 0;
  Assert.AreEqual('hi', string(TDoomScriptMemory.ReadString(@FCell[0])));
end;

procedure TTestDoomScriptMemory.DovrebbeLeggereAlPiu127CaratteriSenzaTerminatore;
begin
  Fill(Ord('z'));
  Assert.AreEqual<Integer>(DS_MAX_STRING_LEN - 1, Length(TDoomScriptMemory.ReadString(@FCell[0])));
  Assert.AreEqual<Integer>(9, Length(TDoomScriptMemory.ReadString(@FCell[0], 10)));
end;

procedure TTestDoomScriptMemory.DovrebbeAccodareIlTesto;
begin
  Fill($FF);
  TDoomScriptMemory.CopyString(@FCell[0], 'abc');
  TDoomScriptMemory.AppendString(@FCell[0], 'def');
  Assert.AreEqual('abcdef', string(TDoomScriptMemory.ReadString(@FCell[0])));
  Assert.AreEqual(DS_MAX_STRING_LEN - 6, CountZerosFrom(6));
end;

procedure TTestDoomScriptMemory.DovrebbeTroncareLAccodamentoAllaFineDellaCella;
var
  LText: AnsiString;
begin
  Fill($FF);
  TDoomScriptMemory.CopyString(@FCell[0], StringOfChar(AnsiChar('a'), 120));
  TDoomScriptMemory.AppendString(@FCell[0], StringOfChar(AnsiChar('b'), 20));
  LText := TDoomScriptMemory.ReadString(@FCell[0]);
  Assert.AreEqual<Integer>(127, Length(LText));
  Assert.AreEqual('b', string(AnsiString(LText[127])));
  Assert.AreEqual(0, Integer(FCell[127]));
  // a full cell takes nothing more
  TDoomScriptMemory.AppendString(@FCell[0], 'c');
  Assert.AreEqual<Integer>(127, Length(TDoomScriptMemory.ReadString(@FCell[0])));
end;

procedure TTestDoomScriptMemory.DovrebbeDareErroreSeLaCellaNonHaTerminatore;
begin
  Fill(Ord('z'));
  TDoomScriptTestSupport.ExpectError(
    procedure
    begin
      TDoomScriptMemory.AppendString(@FCell[0], 'x');
    end, EDoomScriptError, 'idStr::Append: already overflowed');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestDoomScriptMemory);

end.
