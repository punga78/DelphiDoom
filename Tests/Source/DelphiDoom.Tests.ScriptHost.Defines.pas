{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the defines of the preprocessor of the scripts         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.ScriptHost.Defines;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('scripthost')]
  TTestScriptHostDefines = class(TObject)
  private
    function Joined(const ADefines: TArray<string>): string;
  public
    [Test]
    procedure DovrebbeDareIlNomeDelGiocoInMaiuscoloPerPrimo;
    [Test]
    procedure DovrebbeDareLeSeiCombinazioniDiDoomNellOrdineDelVecchioCodice;
    [Test]
    procedure DovrebbeDareLeSeiCombinazioniDiHereticNellOrdineDelVecchioCodice;
    [Test]
    procedure DovrebbeDareLeSeiCombinazioniDiHexenNellOrdineDelVecchioCodice;
    [Test]
    procedure DovrebbeDareLeSeiCombinazioniDiStrifeNellOrdineDelVecchioCodice;
    [Test]
    procedure DovrebbeAggiungereDebugEDevparmDopoIlNomeEPrimaDelleCombinazioni;
    [Test]
    procedure DovrebbeAggiungereOpenglPerUltimo;
    [Test]
    procedure DovrebbeDareUnaCombinazioneDelGiocoPerOgniAltroGioco;
    [Test]
    procedure DovrebbeUsareIlNomeDelGiocoDelMotoreAncheSeIlProfiloEDiUnAltro;
  end;

implementation

uses
  System.SysUtils,
  DelphiDoom.ScriptHost.Defines,
  DelphiDoom.ScriptHost.Types;

function TTestScriptHostDefines.Joined(const ADefines: TArray<string>): string;
begin
  Result := string.Join(',', ADefines);
end;

procedure TTestScriptHostDefines.DovrebbeDareIlNomeDelGiocoInMaiuscoloPerPrimo;
begin
  Assert.AreEqual('DOOM', TScriptDefines.ForGame('Doom', sgDoom, False, False, False)[0]);
  Assert.AreEqual('HERETIC', TScriptDefines.ForGame('heretic', sgHeretic, False, False, False)[0]);
end;

procedure TTestScriptHostDefines.DovrebbeDareLeSeiCombinazioniDiDoomNellOrdineDelVecchioCodice;
begin
  Assert.AreEqual('DOOM,DOOM_OR_HERETIC,DOOM_OR_HEXEN,DOOM_OR_STRIFE,HERETIC_OR_DOOM,HEXEN_OR_DOOM,STRIFE_OR_DOOM',
    Joined(TScriptDefines.ForGame('Doom', sgDoom, False, False, False)));
end;

procedure TTestScriptHostDefines.DovrebbeDareLeSeiCombinazioniDiHereticNellOrdineDelVecchioCodice;
begin
  Assert.AreEqual('HERETIC,HERETIC_OR_DOOM,HERETIC_OR_HEXEN,HERETIC_OR_STRIFE,DOOM_OR_HERETIC,HEXEN_OR_HERETIC,' +
    'STRIFE_OR_HERETIC', Joined(TScriptDefines.ForGame('Heretic', sgHeretic, False, False, False)));
end;

procedure TTestScriptHostDefines.DovrebbeDareLeSeiCombinazioniDiHexenNellOrdineDelVecchioCodice;
begin
  Assert.AreEqual('HEXEN,HEXEN_OR_DOOM,HEXEN_OR_HERETIC,HEXEN_OR_STRIFE,DOOM_OR_HEXEN,HERETIC_OR_HEXEN,' +
    'STRIFE_OR_HEXEN', Joined(TScriptDefines.ForGame('Hexen', sgHexen, False, False, False)));
end;

procedure TTestScriptHostDefines.DovrebbeDareLeSeiCombinazioniDiStrifeNellOrdineDelVecchioCodice;
begin
  Assert.AreEqual('STRIFE,STRIFE_OR_DOOM,STRIFE_OR_HERETIC,STRIFE_OR_HEXEN,DOOM_OR_STRIFE,HERETIC_OR_STRIFE,' +
    'HEXEN_OR_STRIFE', Joined(TScriptDefines.ForGame('Strife', sgStrife, False, False, False)));
end;

procedure TTestScriptHostDefines.DovrebbeAggiungereDebugEDevparmDopoIlNomeEPrimaDelleCombinazioni;
begin
  Assert.AreEqual('DOOM,DEBUG,DEVPARM,DOOM_OR_HERETIC',
    string.Join(',', Copy(TScriptDefines.ForGame('Doom', sgDoom, True, True, False), 0, 4)));
  Assert.AreEqual('DOOM,DEVPARM,DOOM_OR_HERETIC',
    string.Join(',', Copy(TScriptDefines.ForGame('Doom', sgDoom, False, True, False), 0, 3)));
end;

procedure TTestScriptHostDefines.DovrebbeAggiungereOpenglPerUltimo;
var
  LDefines: TArray<string>;
begin
  LDefines := TScriptDefines.ForGame('Doom', sgDoom, False, False, True);
  Assert.AreEqual('OPENGL', LDefines[High(LDefines)]);
  Assert.AreEqual<Integer>(8, Length(LDefines));
end;

procedure TTestScriptHostDefines.DovrebbeDareUnaCombinazioneDelGiocoPerOgniAltroGioco;
var
  LGame: TScriptGame;
  LDefines: TArray<string>;
  LDefine: string;
  LCount: Integer;
begin
  for LGame := Low(TScriptGame) to High(TScriptGame) do
  begin
    LDefines := TScriptDefines.ForGame('X', LGame, False, False, False);
    Assert.AreEqual<Integer>(7, Length(LDefines));
    LCount := 0;
    for LDefine in LDefines do
      if LDefine.EndsWith('_OR_DOOM') or LDefine.EndsWith('_OR_HERETIC') or LDefine.EndsWith('_OR_HEXEN') or
         LDefine.EndsWith('_OR_STRIFE') then
        Inc(LCount);
    Assert.AreEqual(6, LCount);
  end;
end;

procedure TTestScriptHostDefines.DovrebbeUsareIlNomeDelGiocoDelMotoreAncheSeIlProfiloEDiUnAltro;
begin
  // Radix runs with the profile of Doom: its scripts test RADIX and DOOM_OR_HERETIC
  Assert.AreEqual('RADIX,DOOM_OR_HERETIC', string.Join(',', Copy(TScriptDefines.ForGame('Radix', sgDoom, False, False, False), 0, 2)));
end;

end.
