{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the cheat sequencereader                              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Console.CheatSequenceReader;

interface

uses
  System.SysUtils, DUnitX.TestFramework;

type
  [TestFixture]
  [Category('console')]
  TTestCheatSequenceReader = class(TObject)
  public
    [Test]
    procedure TestStopsAtTheEndMarkWithoutTakingIt;
    [Test]
    procedure TestTakesTheFirstByteWhateverItIs;
    [Test]
    procedure TestMissingEndMarkIsAnError;
    [Test]
    procedure TestEmptyArrayIsAnError;
  end;

implementation

uses
  DelphiDoom.Console.Types, DelphiDoom.Console.CheatSequenceReader, DelphiDoom.Tests.Console.CheatData;

{ TTestCheatSequenceReader }

procedure TTestCheatSequenceReader.TestStopsAtTheEndMarkWithoutTakingIt;
var
  LSequence: AnsiString;
begin
  LSequence := TCheatSequenceReader.FromBytes(IDDQD);
  Assert.AreEqual(5, Length(LSequence), 'dovrebbe fermarsi prima del segno di fine');
  Assert.AreEqual(Integer($B2), Integer(Ord(LSequence[1])));
  Assert.AreEqual(Integer($26), Integer(Ord(LSequence[5])));
end;

procedure TTestCheatSequenceReader.TestTakesTheFirstByteWhateverItIs;
var
  LSequence: AnsiString;
begin
  LSequence := TCheatSequenceReader.FromBytes([$FF, $FF]);
  Assert.AreEqual(1, Length(LSequence), 'dovrebbe prendere sempre il primo byte');
end;

procedure TTestCheatSequenceReader.TestMissingEndMarkIsAnError;
begin
  Assert.WillRaise(
    procedure
    begin
      TCheatSequenceReader.FromBytes([$B2, $26]);
    end,
    EConsoleException, 'dovrebbe rifiutare una sequenza senza segno di fine');
end;

procedure TTestCheatSequenceReader.TestEmptyArrayIsAnError;
begin
  Assert.WillRaise(
    procedure
    begin
      TCheatSequenceReader.FromBytes([]);
    end,
    EConsoleException, 'dovrebbe rifiutare un array vuoto');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestCheatSequenceReader);

end.
