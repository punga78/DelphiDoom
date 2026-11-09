{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the list of the functions of a unit                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.ScriptHost.FunctionList;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('scripthost')]
  TTestScriptHostFunctionList = class(TObject)
  public
    [Test]
    procedure DovrebbeEssereVuotaAllInizio;
    [Test]
    procedure DovrebbeAggiungereIlPuntoEVirgolaSeManca;
    [Test]
    procedure DovrebbeNonAggiungereUnSecondoPuntoEVirgola;
    [Test]
    procedure DovrebbeTogliereGliSpaziAiLati;
    [Test]
    procedure DovrebbeIgnorareUnaDichiarazioneVuota;
    [Test]
    procedure DovrebbeTenereLeDichiarazioniNellOrdineDiAggiunta;
    [Test]
    procedure DovrebbeDareLaDichiarazioneDiEsportazioneUgualeAQuellaDelCompilatore;
    [Test]
    procedure DovrebbeDareLaDichiarazioneDiEsportazioneDataConUnRisultatoDiClasse;
    [Test]
    procedure DovrebbeTenereLaDichiarazioneDiEsportazioneDataSenzaTogliereGliSpazi;
  end;

implementation

uses
  DelphiDoom.ScriptHost.FunctionList;

{ TTestScriptHostFunctionList }

procedure TTestScriptHostFunctionList.DovrebbeEssereVuotaAllInizio;
var
  LList: TScriptFunctionList;
begin
  LList := TScriptFunctionList.Create('MINE');
  try
    Assert.AreEqual(0, LList.Count);
    Assert.AreEqual('', LList.Declarations);
    Assert.AreEqual('MINE', LList.ListName);
  finally
    LList.Free;
  end;
end;

procedure TTestScriptHostFunctionList.DovrebbeAggiungereIlPuntoEVirgolaSeManca;
var
  LList: TScriptFunctionList;
begin
  LList := TScriptFunctionList.Create('MINE');
  try
    LList.Add('procedure A', nil);
    Assert.AreEqual('procedure A;'#13#10, LList.Declarations);
  finally
    LList.Free;
  end;
end;

procedure TTestScriptHostFunctionList.DovrebbeNonAggiungereUnSecondoPuntoEVirgola;
var
  LList: TScriptFunctionList;
begin
  LList := TScriptFunctionList.Create('MINE');
  try
    LList.Add('procedure A;', nil);
    Assert.AreEqual('procedure A;'#13#10, LList.Declarations);
  finally
    LList.Free;
  end;
end;

procedure TTestScriptHostFunctionList.DovrebbeTogliereGliSpaziAiLati;
var
  LList: TScriptFunctionList;
begin
  LList := TScriptFunctionList.Create('MINE');
  try
    LList.Add('   function B: integer   '#9, nil);
    Assert.AreEqual('function B: integer;'#13#10, LList.Declarations);
  finally
    LList.Free;
  end;
end;

procedure TTestScriptHostFunctionList.DovrebbeIgnorareUnaDichiarazioneVuota;
var
  LList: TScriptFunctionList;
begin
  LList := TScriptFunctionList.Create('MINE');
  try
    LList.Add('', nil);
    LList.Add('   ', nil);
    LList.AddWithCustomResult('', 'X', 'Y', nil);
    Assert.AreEqual(0, LList.Count);
  finally
    LList.Free;
  end;
end;

procedure TTestScriptHostFunctionList.DovrebbeTenereLeDichiarazioniNellOrdineDiAggiunta;
var
  LList: TScriptFunctionList;
begin
  LList := TScriptFunctionList.Create('MINE');
  try
    LList.Add('procedure Z;', nil);
    LList.Add('procedure A;', nil);
    LList.Add('procedure M;', nil);
    Assert.AreEqual('procedure Z;'#13#10'procedure A;'#13#10'procedure M;'#13#10, LList.Declarations);
    Assert.AreEqual(3, LList.Count);
  finally
    LList.Free;
  end;
end;

procedure TTestScriptHostFunctionList.DovrebbeDareLaDichiarazioneDiEsportazioneUgualeAQuellaDelCompilatore;
var
  LList: TScriptFunctionList;
begin
  LList := TScriptFunctionList.Create('MINE');
  try
    LList.Add('procedure A', nil);
    Assert.AreEqual('procedure A;'#13#10, LList.Declarations);
  finally
    LList.Free;
  end;
end;

procedure TTestScriptHostFunctionList.DovrebbeDareLaDichiarazioneDiEsportazioneDataConUnRisultatoDiClasse;
var
  LList: TScriptFunctionList;
begin
  LList := TScriptFunctionList.Create('MINE');
  try
    LList.AddWithCustomResult('procedure TActor(const key: LongWord);', '!TActor',
      'function TActor(const key: LongWord): !TActor;', nil);
    Assert.AreEqual('function TActor(const key: LongWord): !TActor;'#13#10, LList.Declarations);
  finally
    LList.Free;
  end;
end;

procedure TTestScriptHostFunctionList.DovrebbeTenereLaDichiarazioneDiEsportazioneDataSenzaTogliereGliSpazi;
var
  LList: TScriptFunctionList;
begin
  LList := TScriptFunctionList.Create('MINE');
  try
    // the export declaration is the one that tools show: it is written as it is
    LList.AddWithCustomResult('procedure TActor(const key: LongWord)', '!TActor', ' function TActor ', nil);
    Assert.AreEqual(' function TActor '#13#10, LList.Declarations);
  finally
    LList.Free;
  end;
end;

end.
