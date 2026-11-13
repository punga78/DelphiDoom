{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the texts of the action parameters (DUnitX)            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.ActorDef.ParamText;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('actordef')]
  TTestActorDefParamText = class
  public
    [Test]
    procedure DovrebbeRiconoscereInteriEDecimali;
    [Test]
    procedure DovrebbeLeggereInteriEsadecimaliEConDiesis;
    [Test]
    procedure DovrebbeDareIlPredefinitoSeNonESUnNumero;
    [Test]
    procedure DovrebbeTagliareLeParoleEScartareQuelleVuote;
    [Test]
    procedure DovrebbeTogliereLeVirgoletteAgliEstremi;
    [Test]
    procedure DovrebbeTroncareUnTestoLungoComeUnaShortString;
    [Test]
    procedure DovrebbeDareGliStessiRisultatiDeiVecchiTestiSuStringheCasuali;
  end;

implementation

uses
  System.SysUtils,
  d_delphi,
  DelphiDoom.ActorDef.ParamText;

const
  Alphabet: array[0..21] of string = (
    '0', '1', '9', '-', '.', ',', 'x', '#', '0x', ' ', 'a', 'F', '"', '(', ')', '[', #9, '5', 'e', '+', '_', '7');

function RandomText: string;
var
  LIndex: Integer;
begin
  Result := '';
  for LIndex := 1 to Random(7) do
    Result := Result + Alphabet[Random(Length(Alphabet))];
end;

procedure TTestActorDefParamText.DovrebbeRiconoscereInteriEDecimali;
begin
  Assert.IsTrue(TActorDefParamText.IsInteger('-12'));
  Assert.IsFalse(TActorDefParamText.IsInteger(''));
  Assert.IsFalse(TActorDefParamText.IsInteger('1.5'));
  Assert.IsTrue(TActorDefParamText.IsFloat('1.5'));
  Assert.IsTrue(TActorDefParamText.IsFloat('1,5'));
  Assert.IsFalse(TActorDefParamText.IsFloat('1.5.5'));
  Assert.IsTrue(TActorDefParamText.IsLongWord('007'));
  Assert.IsFalse(TActorDefParamText.IsLongWord('-7'));
end;

procedure TTestActorDefParamText.DovrebbeLeggereInteriEsadecimaliEConDiesis;
begin
  Assert.AreEqual(255, TActorDefParamText.ToInteger('0xFF', 0));
  Assert.AreEqual(-255, TActorDefParamText.ToInteger('-0xFF', 0));
  Assert.AreEqual(33, TActorDefParamText.ToInteger('#33', 0));
  Assert.AreEqual(-4, TActorDefParamText.ToInteger('-4', 9));
end;

procedure TTestActorDefParamText.DovrebbeDareIlPredefinitoSeNonESUnNumero;
begin
  Assert.AreEqual(77, TActorDefParamText.ToInteger('abc', 77));
  Assert.AreEqual(Single(2.5), TActorDefParamText.ToFloat('abc', 2.5));
  Assert.AreEqual(Single(1.5), TActorDefParamText.ToFloat('1,5', 0));
end;

procedure TTestActorDefParamText.DovrebbeTagliareLeParoleEScartareQuelleVuote;
var
  LWords: TArray<string>;
begin
  LWords := TActorDefParamText.WordsToList('RANDOM (1, 2)', [' ', '(', ',', ')']);
  Assert.AreEqual(3, Length(LWords));
  Assert.AreEqual('RANDOM', LWords[0]);
  Assert.AreEqual('1', LWords[1]);
  Assert.AreEqual('2', LWords[2]);
  Assert.AreEqual(0, Length(TActorDefParamText.WordsToList('(( ))', [' ', '(', ')'])));
end;

procedure TTestActorDefParamText.DovrebbeTogliereLeVirgoletteAgliEstremi;
begin
  Assert.AreEqual('abc', TActorDefParamText.RemoveQuotes('"abc"'));
  Assert.AreEqual('abc', TActorDefParamText.RemoveQuotes('"abc'));
  Assert.AreEqual('', TActorDefParamText.RemoveQuotes('"'));
  Assert.AreEqual('', TActorDefParamText.RemoveQuotes(''));
end;

procedure TTestActorDefParamText.DovrebbeTroncareUnTestoLungoComeUnaShortString;
begin
  Assert.AreEqual(255, Length(TActorDefParamText.ToShortText(StringOfChar('z', 400))));
  Assert.AreEqual('abc', TActorDefParamText.ToShortText('abc'));
end;

procedure TTestActorDefParamText.DovrebbeDareGliStessiRisultatiDeiVecchiTestiSuStringheCasuali;
var
  LRound: Integer;
  LText: string;
  LOldList: TDStringList;
  LNewList: TArray<string>;
  LIndex: Integer;
begin
  RandSeed := 190;
  for LRound := 1 to 4000 do
  begin
    LText := RandomText;
    Assert.AreEqual(StrIsInteger(LText), TActorDefParamText.IsInteger(LText), 'IsInteger ' + LText);
    Assert.AreEqual(StrIsFloat(LText), TActorDefParamText.IsFloat(LText), 'IsFloat ' + LText);
    Assert.AreEqual(atoi(LText, 31), TActorDefParamText.ToInteger(LText, 31), 'atoi ' + LText);
    Assert.AreEqual(atoi(LText), TActorDefParamText.ToInteger(LText, 0), 'atoi0 ' + LText);
    Assert.AreEqual(atof(LText, 2.5), TActorDefParamText.ToFloat(LText, 2.5), 'atof ' + LText);
    Assert.AreEqual(RemoveQuotesFromString(LText), TActorDefParamText.RemoveQuotes(LText));
    LOldList := wordstolist(LText, [' ', #9, '(', ')', ',', '-']);
    try
      LNewList := TActorDefParamText.WordsToList(LText, [' ', #9, '(', ')', ',', '-']);
      Assert.AreEqual(LOldList.Count, Length(LNewList), 'words ' + LText);
      for LIndex := 0 to High(LNewList) do
        Assert.AreEqual(LOldList[LIndex], LNewList[LIndex], 'word ' + LText);
    finally
      LOldList.Free;
    end;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestActorDefParamText);

end.
