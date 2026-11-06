{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Wad library - TWadLumpName                         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Wad.Name;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Wad.Types;

type
  [TestFixture]
  [Category('wad')]
  TTestWadName = class(TObject)
  public
    [Test]
    procedure TestUpperCaseIsAsciiOnly;
    [Test]
    procedure TestFromRecordStopsAtTheFirstZero;
    [Test]
    procedure TestFromRecordTakesAllEightCharacters;
    [Test]
    procedure TestToRecordPadsWithZeros;
    [Test]
    procedure TestToRecordRefusesBadNames;
    [Test]
    procedure TestIsValid;
    [Test]
    procedure TestFromFileName;
  end;

implementation

uses
  DelphiDoom.Wad.Name;

{ TTestWadName }

procedure TTestWadName.TestUpperCaseIsAsciiOnly;
begin
  Assert.AreEqual('PLAYPAL_1', TWadLumpName.UpperCase('playpal_1'));
  Assert.AreEqual(#$C0'B', TWadLumpName.UpperCase(#$C0'b'));
end;

procedure TTestWadName.TestFromRecordStopsAtTheFirstZero;
var
  LRecord: TWadDirectoryRecord;
begin
  FillChar(LRecord, SizeOf(LRecord), 0);
  LRecord.Name[0] := 'a';
  LRecord.Name[1] := 'b';
  // a non null character after the end of the name is not part of it
  LRecord.Name[4] := 'x';
  Assert.AreEqual('AB', TWadLumpName.FromRecord(LRecord));
end;

procedure TTestWadName.TestFromRecordTakesAllEightCharacters;
var
  LRecord: TWadDirectoryRecord;
begin
  Move(PAnsiChar('texture1')^, LRecord.Name, 8);
  Assert.AreEqual('TEXTURE1', TWadLumpName.FromRecord(LRecord));
end;

procedure TTestWadName.TestToRecordPadsWithZeros;
var
  LRecord: TWadDirectoryRecord;
  LIndex: Integer;
begin
  FillChar(LRecord, SizeOf(LRecord), $FF);
  TWadLumpName.ToRecord('e1m1', LRecord);
  Assert.AreEqual(Ord('E'), Integer(Ord(LRecord.Name[0])));
  Assert.AreEqual(Ord('1'), Integer(Ord(LRecord.Name[3])));
  for LIndex := 4 to 7 do
    Assert.AreEqual(0, Integer(Ord(LRecord.Name[LIndex])));
end;

procedure TTestWadName.TestToRecordRefusesBadNames;
var
  LRecord: TWadDirectoryRecord;
begin
  Assert.WillRaise(procedure begin TWadLumpName.ToRecord('', LRecord); end, EWadException);
  Assert.WillRaise(procedure begin TWadLumpName.ToRecord('NINECHARS', LRecord); end, EWadException);
  Assert.WillRaise(procedure begin TWadLumpName.ToRecord('A B', LRecord); end, EWadException);
end;

procedure TTestWadName.TestIsValid;
begin
  Assert.IsTrue(TWadLumpName.IsValid('F_START'));
  Assert.IsTrue(TWadLumpName.IsValid('X'));
  Assert.IsFalse(TWadLumpName.IsValid(''));
  Assert.IsFalse(TWadLumpName.IsValid('123456789'));
  Assert.IsFalse(TWadLumpName.IsValid('A'#0'B'));
end;

procedure TTestWadName.TestFromFileName;
begin
  Assert.AreEqual('MYSOUND', TWadLumpName.FromFileName('C:\x\mysound.wav'));
  Assert.AreEqual('LONGFILE', TWadLumpName.FromFileName('longfilename.lmp'));
end;

end.
