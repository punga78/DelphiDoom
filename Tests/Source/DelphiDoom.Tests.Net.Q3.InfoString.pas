{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the info strings of Quake III (DUnitX)                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Net.Q3.InfoString;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, DUnitX.TestFramework,
  DelphiDoom.Net.Q3.Types, DelphiDoom.Net.Q3.InfoString, DelphiDoom.Tests.Net.Q3Fakes;

type
  /// <summary>
  ///   The info strings: unit tests and parity with the real Info_* functions of q_shared.c, whose output is in
  ///   Tests\Data\Net\q3info-golden.txt (Tools\Verifica\121\build-info.sh)
  /// </summary>
  [TestFixture]
  [Category('net')]
  TTestQ3InfoString = class
  strict private
    FLog: TFakeQ3Log;
    FLogIntf: IInterface;
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure DovrebbeDareIlValoreDiUnaChiave;
    [Test]
    procedure DovrebbeIgnorareLeMaiuscoleNellaRicerca;
    [Test]
    procedure DovrebbeDareVuotoSeLaChiaveManca;
    [Test]
    procedure DovrebbeAccettareUnaStringaSenzaBackslashIniziale;
    [Test]
    procedure DovrebbeDareVuotoSeLaStringaFinisceNellaChiave;
    [Test]
    procedure DovrebbeFermarsiAlPrimoNul;
    [Test]
    procedure DovrebbeSegnalareUnaStringaTroppoLunga;
    [Test]
    procedure DovrebbeRimuovereUnaChiaveConConfrontoEsatto;
    [Test]
    procedure DovrebbeNonRimuovereUnaChiaveConBackslash;
    [Test]
    procedure DovrebbeMettereLaCoppiaNuovaInTestaNellaVersioneNormale;
    [Test]
    procedure DovrebbeMettereLaCoppiaNuovaInCodaNellaVersioneBig;
    [Test]
    procedure DovrebbeSostituireUnaChiaveEsistente;
    [Test]
    procedure DovrebbeRimuovereLaChiaveSeIlValoreEVuoto;
    [Test]
    procedure DovrebbeRifiutareCaratteriNonValidiEAvvisare;
    [Test]
    procedure DovrebbeRifiutareUnaCoppiaCheNonEntra;
    [Test]
    procedure DovrebbeAvvisareIlTroncamentoDiComSprintf;
    [Test]
    procedure DovrebbeValidareLaStringa;
    [Test]
    procedure DovrebbeScorrereLeCoppie;
    [Test]
    procedure DovrebbeDareLoStessoDelCPerOgniChiamataDelGolden;
  end;

implementation

function Decode(const AText: string): AnsiString;
var
  LPieces: TArray<string>;
  LPiece: string;
  LIndex: Integer;
  LChar: AnsiChar;
  LCount: Integer;
  LSeparator: Integer;
begin
  Result := '';
  if AText = '-' then
    Exit;
  LPieces := AText.Split(['.']);
  for LPiece in LPieces do
    if (LPiece <> '') and (LPiece[1] = 'r') then
    begin
      LSeparator := Pos('x', LPiece);
      LChar := AnsiChar(StrToInt('$' + Copy(LPiece, 2, LSeparator - 2)));
      LCount := StrToInt(Copy(LPiece, LSeparator + 1, MaxInt));
      Result := Result + AnsiString(StringOfChar(Char(LChar), LCount));
    end
    else
      for LIndex := 0 to Length(LPiece) div 2 - 1 do
        Result := Result + AnsiChar(StrToInt('$' + Copy(LPiece, LIndex * 2 + 1, 2)));
end;

function FieldOf(const AFields: TArray<string>; const APrefix: string): string;
var
  LField: string;
begin
  for LField in AFields do
    if LField.StartsWith(APrefix) then
      Exit(Copy(LField, Length(APrefix) + 1, MaxInt));
  Result := '';
end;

{ TTestQ3InfoString }

procedure TTestQ3InfoString.Setup;
begin
  FLog := TFakeQ3Log.Create;
  FLogIntf := FLog;
end;

procedure TTestQ3InfoString.DovrebbeDareIlValoreDiUnaChiave;
begin
  Assert.AreEqual(AnsiString('25000'), TQ3InfoString.ValueForKey('\name\Luca\rate\25000', 'rate'));
  Assert.AreEqual(AnsiString('Luca'), TQ3InfoString.ValueForKey('\name\Luca\rate\25000', 'name'));
end;

procedure TTestQ3InfoString.DovrebbeIgnorareLeMaiuscoleNellaRicerca;
begin
  Assert.AreEqual(AnsiString('1'), TQ3InfoString.ValueForKey('\Name\1', 'nAME'));
end;

procedure TTestQ3InfoString.DovrebbeDareVuotoSeLaChiaveManca;
begin
  Assert.AreEqual(AnsiString(''), TQ3InfoString.ValueForKey('\a\1', 'b'));
  Assert.AreEqual(AnsiString(''), TQ3InfoString.ValueForKey('', 'b'));
end;

procedure TTestQ3InfoString.DovrebbeAccettareUnaStringaSenzaBackslashIniziale;
begin
  Assert.AreEqual(AnsiString('1'), TQ3InfoString.ValueForKey('a\1\b\2', 'a'));
end;

procedure TTestQ3InfoString.DovrebbeDareVuotoSeLaStringaFinisceNellaChiave;
begin
  Assert.AreEqual(AnsiString(''), TQ3InfoString.ValueForKey('\a\1\b', 'b'));
end;

procedure TTestQ3InfoString.DovrebbeFermarsiAlPrimoNul;
begin
  Assert.AreEqual(AnsiString(''), TQ3InfoString.ValueForKey('\a\1' + #0 + '\b\2', 'b'));
end;

procedure TTestQ3InfoString.DovrebbeSegnalareUnaStringaTroppoLunga;
var
  LInfo: AnsiString;
begin
  LInfo := '\a\' + AnsiString(StringOfChar('x', Q3_BIG_INFO_STRING));
  Assert.WillRaise(
    procedure
    begin
      TQ3InfoString.ValueForKey(LInfo, 'a');
    end,
    EQ3InfoStringException);
  Assert.WillRaise(
    procedure
    var
      LCopy: AnsiString;
    begin
      LCopy := '\a\' + AnsiString(StringOfChar('x', Q3_MAX_INFO_STRING));
      TQ3InfoString.RemoveKey(LCopy, 'a');
    end,
    EQ3InfoStringException);
end;

procedure TTestQ3InfoString.DovrebbeRimuovereUnaChiaveConConfrontoEsatto;
var
  LInfo: AnsiString;
begin
  LInfo := '\a\1\A\2\b\3';
  TQ3InfoString.RemoveKey(LInfo, 'A');
  Assert.AreEqual(AnsiString('\a\1\b\3'), LInfo);
end;

procedure TTestQ3InfoString.DovrebbeNonRimuovereUnaChiaveConBackslash;
var
  LInfo: AnsiString;
begin
  LInfo := '\a\1';
  TQ3InfoString.RemoveKey(LInfo, 'a\1');
  Assert.AreEqual(AnsiString('\a\1'), LInfo);
end;

procedure TTestQ3InfoString.DovrebbeMettereLaCoppiaNuovaInTestaNellaVersioneNormale;
var
  LInfo: AnsiString;
begin
  LInfo := '\a\1';
  Assert.IsTrue(TQ3InfoString.SetValueForKey(LInfo, 'b', '2'));
  Assert.AreEqual(AnsiString('\b\2\a\1'), LInfo);
end;

procedure TTestQ3InfoString.DovrebbeMettereLaCoppiaNuovaInCodaNellaVersioneBig;
var
  LInfo: AnsiString;
begin
  LInfo := '\a\1';
  Assert.IsTrue(TQ3InfoString.SetValueForKey(LInfo, 'b', '2', True));
  Assert.AreEqual(AnsiString('\a\1\b\2'), LInfo);
end;

procedure TTestQ3InfoString.DovrebbeSostituireUnaChiaveEsistente;
var
  LInfo: AnsiString;
begin
  LInfo := '\a\1\b\2';
  TQ3InfoString.SetValueForKey(LInfo, 'a', '9');
  Assert.AreEqual(AnsiString('\a\9\b\2'), LInfo);
end;

procedure TTestQ3InfoString.DovrebbeRimuovereLaChiaveSeIlValoreEVuoto;
var
  LInfo: AnsiString;
begin
  LInfo := '\a\1\b\2';
  Assert.IsTrue(TQ3InfoString.SetValueForKey(LInfo, 'a', ''));
  Assert.AreEqual(AnsiString('\b\2'), LInfo);
end;

procedure TTestQ3InfoString.DovrebbeRifiutareCaratteriNonValidiEAvvisare;
var
  LInfo: AnsiString;
begin
  LInfo := '\a\1';
  Assert.IsFalse(TQ3InfoString.SetValueForKey(LInfo, 'b', 'x\y', False, FLog));
  Assert.IsFalse(TQ3InfoString.SetValueForKey(LInfo, 'b;', 'x', False, FLog));
  Assert.IsFalse(TQ3InfoString.SetValueForKey(LInfo, 'b', 'x"', False, FLog));
  Assert.IsFalse(TQ3InfoString.SetValueForKey(LInfo, 'b', 'x"'));
  Assert.AreEqual(AnsiString('\a\1'), LInfo);
  Assert.AreEqual(3, FLog.Infos.Count);
  Assert.AreEqual(SQ3InfoStringBackslash, FLog.Infos[0]);
  Assert.AreEqual(SQ3InfoStringSemicolon, FLog.Infos[1]);
  Assert.AreEqual(SQ3InfoStringQuote, FLog.Infos[2]);
end;

procedure TTestQ3InfoString.DovrebbeRifiutareUnaCoppiaCheNonEntra;
var
  LInfo: AnsiString;
begin
  LInfo := '\a\' + AnsiString(StringOfChar('x', 1020));
  Assert.IsFalse(TQ3InfoString.SetValueForKey(LInfo, 'kk', 'value', False, FLog));
  Assert.AreEqual(SQ3InfoStringExceeded, FLog.Infos[0]);
  LInfo := '\a\' + AnsiString(StringOfChar('x', 8185));
  Assert.IsFalse(TQ3InfoString.SetValueForKey(LInfo, 'kk', 'value', True, FLog));
  Assert.AreEqual(SQ3InfoStringBigExceeded, FLog.Infos[1]);
end;

procedure TTestQ3InfoString.DovrebbeAvvisareIlTroncamentoDiComSprintf;
var
  LInfo: AnsiString;
begin
  LInfo := '';
  TQ3InfoString.SetValueForKey(LInfo, 'k', AnsiString(StringOfChar('z', 1030)), False, FLog);
  Assert.AreEqual(Format(SQ3InfoStringSprintfOverflow, [1033, 1024]), FLog.Infos[0]);
  Assert.AreEqual(1023, Length(LInfo));
end;

procedure TTestQ3InfoString.DovrebbeValidareLaStringa;
begin
  Assert.IsTrue(TQ3InfoString.Validate('\a\1'));
  Assert.IsFalse(TQ3InfoString.Validate('\a\1;'));
  Assert.IsFalse(TQ3InfoString.Validate('\a\"1'));
end;

procedure TTestQ3InfoString.DovrebbeScorrereLeCoppie;
var
  LInfo: AnsiString;
  LPosition: Integer;
  LKey, LValue: AnsiString;
begin
  LInfo := '\a\1\b\2\c';
  LPosition := 1;
  TQ3InfoString.NextPair(LInfo, LPosition, LKey, LValue);
  Assert.AreEqual(AnsiString('a'), LKey);
  Assert.AreEqual(AnsiString('1'), LValue);
  TQ3InfoString.NextPair(LInfo, LPosition, LKey, LValue);
  Assert.AreEqual(AnsiString('b'), LKey);
  Assert.AreEqual(AnsiString('2'), LValue);
  TQ3InfoString.NextPair(LInfo, LPosition, LKey, LValue);
  Assert.AreEqual(AnsiString('c'), LKey);
  Assert.AreEqual(AnsiString(''), LValue);
  Assert.AreEqual(Length(LInfo) + 1, LPosition);
end;

procedure TTestQ3InfoString.DovrebbeDareLoStessoDelCPerOgniChiamataDelGolden;
var
  LLines: TArray<string>;
  LLine: string;
  LFields: TArray<string>;
  LOperation: string;
  LInfo: AnsiString;
  LExpected: AnsiString;
  LExpectedError: Boolean;
  LActualError: Boolean;
  LPrints: AnsiString;
  LActualPrints: string;
  LResult: AnsiString;
  LPosition, LPairs: Integer;
  LKey, LValue: AnsiString;
  LExpectedPairs: TArray<string>;
  LPair: TArray<string>;
  LCount: Integer;
  LText: string;
begin
  LLines := TFile.ReadAllLines(TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)),
    '..\..\Tests\Data\Net\q3info-golden.txt')));
  Assert.IsTrue(Length(LLines) > 1000, 'golden troppo corto');
  LCount := 0;
  for LLine in LLines do
  begin
    LFields := LLine.Split([' ']);
    LOperation := LFields[0];
    LInfo := Decode(LFields[1]);
    LExpectedError := FieldOf(LFields, 'err=') = '1';
    LActualError := False;
    FLog.Clear;
    if LOperation = 'validate' then
      Assert.AreEqual(FieldOf(LFields, 'result='), IntToStr(Ord(TQ3InfoString.Validate(LInfo))), LLine)
    else if LOperation = 'pairs' then
    begin
      LPosition := 1;
      LPairs := 0;
      LExpectedPairs := FieldOf(LFields, 'result=').Split([';'], TStringSplitOptions.ExcludeEmpty);
      while (LPosition <= Length(LInfo)) and (LPairs < 20) do
      begin
        TQ3InfoString.NextPair(LInfo, LPosition, LKey, LValue);
        LPair := LExpectedPairs[LPairs].Split([':']);
        Assert.AreEqual(Decode(LPair[0]), LKey, LLine);
        Assert.AreEqual(Decode(LPair[1]), LValue, LLine);
        Inc(LPairs);
      end;
      Assert.AreEqual<Integer>(Length(LExpectedPairs), LPairs, LLine);
      Assert.AreEqual(FieldOf(LFields, 'end='), IntToStr(LPosition - 1), LLine);
    end
    else
    begin
      LExpected := Decode(FieldOf(LFields, 'result='));
      LPrints := Decode(FieldOf(LFields, 'prints='));
      LResult := '';
      try
        if LOperation = 'value' then
          LResult := TQ3InfoString.ValueForKey(LInfo, Decode(LFields[2]))
        else if LOperation = 'remove' then
        begin
          LResult := LInfo;
          TQ3InfoString.RemoveKey(LResult, Decode(LFields[2]), False);
        end
        else if LOperation = 'removebig' then
        begin
          LResult := LInfo;
          TQ3InfoString.RemoveKey(LResult, Decode(LFields[2]), True);
        end
        else
        begin
          LResult := LInfo;
          TQ3InfoString.SetValueForKey(LResult, Decode(LFields[2]), Decode(LFields[3]),
            LOperation = 'setbig', FLog);
        end;
      except
        on EQ3InfoStringException do
          LActualError := True;
      end;
      LActualPrints := '';
      for LText in FLog.Infos do
        LActualPrints := LActualPrints + LText + #10;
      Assert.AreEqual(LExpectedError, LActualError, LLine);
      if LOperation = 'value' then
      begin
        if not LActualError then
          Assert.AreEqual(LExpected, LResult, LLine);
      end
      else
        Assert.AreEqual(LExpected, LResult, LLine);
      Assert.AreEqual(string(LPrints), LActualPrints, LLine);
    end;
    Inc(LCount);
  end;
  Assert.AreEqual<Integer>(Length(LLines), LCount);
end;

end.
