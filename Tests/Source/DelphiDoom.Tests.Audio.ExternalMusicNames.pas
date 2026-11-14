{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TExternalMusicNames                                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Audio.ExternalMusicNames;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Audio.ExternalMusicNames,
  DelphiDoom.Tests.Audio.OldMusicNames;

type
  [TestFixture]
  [Category('audio')]
  TTestAudioExternalMusicNames = class(TObject)
  private
    function Joined(const ANames: TArray<string>): string;
  public
    [Test]
    procedure DovrebbeDareLaListaDelVecchioCodiceSuNomiCasuali;
    [Test]
    procedure DovrebbeProvarePrimaIlNomeDellaMappa;
    [Test]
    procedure DovrebbeSaltareLaMappaSenzaNome;
    [Test]
    procedure DovrebbeAggiungereGliAliasInMaiuscolo;
    [Test]
    procedure NonDovrebbeUsareGliAliasPerHereticEHexen;
    [Test]
    [TestCase('vuoto', ';', ';')]
    [TestCase('uno', 'intro;INTRO', ';')]
    [TestCase('spazi e virgole', 'e1m1, e2m2  runnin;E1M1|E2M2|RUNNIN', ';')]
    [TestCase('solo separatori', ', ,,;', ';')]
    [TestCase('solo le lettere cambiano', 'd_e1-m1.x;D_E1-M1.X', ';')]
    procedure DovrebbeSpezzareGliAlias(const AAlias, AExpected: string);
    [Test]
    procedure DovrebbeFermarsiAlCarattereZeroDiUnAlias;
  end;

implementation

{ TTestAudioExternalMusicNames }

function TTestAudioExternalMusicNames.Joined(const ANames: TArray<string>): string;
begin
  Result := string.Join('|', ANames);
end;

procedure TTestAudioExternalMusicNames.DovrebbeDareLaListaDelVecchioCodiceSuNomiCasuali;
const
  CASES = 20000;
  // letters, digits, the two separators, a line break and a zero: what an alias could hold
  ALPHABET: string = 'abcXYZ019_-.  ,,' + #13#10 + #0;
var
  LCase: Integer;
  LSeed: Cardinal;
  LMapName, LName, LAlias: string;
  LHereticOrHexen: Boolean;
  LOld, LNew: string;

  function Next(ARange: Integer): Integer;
  begin
{$Q-}
    LSeed := LSeed * 1664525 + 1013904223;
{$Q+}
    Result := Integer((LSeed shr 8) mod Cardinal(ARange));
  end;

  function RandomText(AMaxLength: Integer; const AAlphabet: string): string;
  var
    LIndex: Integer;
  begin
    SetLength(Result, Next(AMaxLength + 1));
    for LIndex := 1 to Length(Result) do
      Result[LIndex] := AAlphabet[1 + Next(Length(AAlphabet))];
  end;

begin
  LSeed := 20261114;
  for LCase := 1 to CASES do
  begin
    LMapName := RandomText(6, 'e1m2MAP0');
    LName := RandomText(6, 'abcdefINTRO');
    LAlias := RandomText(24, ALPHABET);
    LHereticOrHexen := Next(3) = 0;
    LOld := Joined(TOldMusicNames.FileNames(LMapName, LName, LAlias, LHereticOrHexen));
    if LHereticOrHexen then
      LNew := Joined(TExternalMusicNames.Candidates(LMapName, LName, '', 'MUS_', False))
    else
      LNew := Joined(TExternalMusicNames.Candidates(LMapName, LName, LAlias, 'd_', True));
    if LOld <> LNew then
      Assert.AreEqual(LOld, LNew, Format('caso %d: mappa "%s" nome "%s" alias di %d caratteri',
        [LCase, LMapName, LName, Length(LAlias)]));
  end;
  Assert.Pass;
end;

procedure TTestAudioExternalMusicNames.DovrebbeProvarePrimaIlNomeDellaMappa;
begin
  Assert.AreEqual('E1M1.mp3|d_E1M1.mp3|e1m1.mp3|d_e1m1.mp3',
    Joined(TExternalMusicNames.Candidates('E1M1', 'e1m1', '', 'd_', True)));
end;

procedure TTestAudioExternalMusicNames.DovrebbeSaltareLaMappaSenzaNome;
begin
  Assert.AreEqual('intro.mp3|d_intro.mp3',
    Joined(TExternalMusicNames.Candidates('', 'intro', '', 'd_', True)));
end;

procedure TTestAudioExternalMusicNames.DovrebbeAggiungereGliAliasInMaiuscolo;
begin
  Assert.AreEqual('runnin.mp3|d_runnin.mp3|MAP01.mp3|d_MAP01.mp3|TRACK2.mp3|d_TRACK2.mp3',
    Joined(TExternalMusicNames.Candidates('', 'runnin', 'map01, track2', 'd_', True)));
end;

procedure TTestAudioExternalMusicNames.NonDovrebbeUsareGliAliasPerHereticEHexen;
begin
  Assert.AreEqual('E1M1.mp3|MUS_E1M1.mp3|e1m1.mp3|MUS_e1m1.mp3',
    Joined(TExternalMusicNames.Candidates('E1M1', 'e1m1', 'altro', 'MUS_', False)));
end;

procedure TTestAudioExternalMusicNames.DovrebbeSpezzareGliAlias(const AAlias, AExpected: string);
begin
  Assert.AreEqual(AExpected, Joined(TExternalMusicNames.AliasList(AAlias)));
end;

procedure TTestAudioExternalMusicNames.DovrebbeFermarsiAlCarattereZeroDiUnAlias;
begin
  // the old list was filled as a text, which ends at the first zero
  Assert.AreEqual('UNO|DU', Joined(TExternalMusicNames.AliasList('uno du' + #0 + 'e tre')));
end;

end.
