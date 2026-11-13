{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the heads-up display library - the keyboard maps       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Hud.KeyTables;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('hud')]
  TTestHudKeyTables = class(TObject)
  public
    [Test]
    procedure DovrebbeMaiuscolizzareLeLettereInglesi;
    [Test]
    procedure DovrebbeDareISegniDelloShiftInglese;
    [Test]
    procedure DovrebbeDareISegniDelloShiftFrancese;
    [Test]
    procedure DovrebbeTenereIControlliCosiCome;
    [Test]
    procedure DovrebbeTradurreITastiDellaTastieraFrancese;
    [Test]
    procedure DovrebbeLasciareICaratteriAltiNellaTraduzione;
    [Test]
    procedure DovrebbeDareDueTabelleDiverse;
  end;

implementation

uses
  DelphiDoom.Hud.Types, DelphiDoom.Hud.KeyTables;

{ TTestHudKeyTables }

procedure TTestHudKeyTables.DovrebbeMaiuscolizzareLeLettereInglesi;
var
  LTable: THudShiftTable;
  LLetter: Char;
begin
  LTable := THudKeyTables.ShiftTransform(False);
  for LLetter := 'a' to 'z' do
    Assert.AreEqual(Chr(Ord(LLetter) - 32), LTable[Ord(LLetter)]);
end;

procedure TTestHudKeyTables.DovrebbeDareISegniDelloShiftInglese;
var
  LTable: THudShiftTable;
begin
  LTable := THudKeyTables.ShiftTransform(False);
  Assert.AreEqual('!', LTable[Ord('1')]);
  Assert.AreEqual('@', LTable[Ord('2')]);
  Assert.AreEqual(')', LTable[Ord('0')]);
  Assert.AreEqual('<', LTable[Ord(',')]);
  Assert.AreEqual(':', LTable[Ord(';')]);
end;

procedure TTestHudKeyTables.DovrebbeDareISegniDelloShiftFrancese;
var
  LTable: THudShiftTable;
begin
  LTable := THudKeyTables.ShiftTransform(True);
  Assert.AreEqual('1', LTable[Ord('1')]);
  Assert.AreEqual('?', LTable[Ord(',')]);
  Assert.AreEqual('.', LTable[Ord(';')]);
end;

procedure TTestHudKeyTables.DovrebbeTenereIControlliCosiCome;
var
  LTable: THudShiftTable;
  LIndex: Integer;
begin
  LTable := THudKeyTables.ShiftTransform(False);
  for LIndex := 0 to 31 do
    Assert.AreEqual(Chr(LIndex), LTable[LIndex]);
  Assert.AreEqual(#127, LTable[127]);
end;

procedure TTestHudKeyTables.DovrebbeTradurreITastiDellaTastieraFrancese;
begin
  Assert.AreEqual('Q', THudKeyTables.ForeignTranslation('A'));
  Assert.AreEqual('A', THudKeyTables.ForeignTranslation('Q'));
  Assert.AreEqual('Z', THudKeyTables.ForeignTranslation('W'));
  Assert.AreEqual(',', THudKeyTables.ForeignTranslation('M'));
  Assert.AreEqual('1', THudKeyTables.ForeignTranslation('1'));
end;

procedure TTestHudKeyTables.DovrebbeLasciareICaratteriAltiNellaTraduzione;
begin
  Assert.AreEqual(Char(200), THudKeyTables.ForeignTranslation(Char(200)));
  Assert.AreEqual(Char($1041), THudKeyTables.ForeignTranslation(Char($1041)));
end;

procedure TTestHudKeyTables.DovrebbeDareDueTabelleDiverse;
var
  LEnglish: THudShiftTable;
  LFrench: THudShiftTable;
  LIndex: Integer;
  LDifferences: Integer;
begin
  LEnglish := THudKeyTables.ShiftTransform(False);
  LFrench := THudKeyTables.ShiftTransform(True);
  LDifferences := 0;
  for LIndex := 0 to HUD_SHIFT_TABLE_SIZE - 1 do
    if LEnglish[LIndex] <> LFrench[LIndex] then
      Inc(LDifferences);
  Assert.IsTrue(LDifferences > 10);
end;

end.
