{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TRadixLumpAliases                                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Radix.LumpAliases;

interface

uses
  System.SysUtils, DUnitX.TestFramework,
  DelphiDoom.Radix.Intf;

type
  [TestFixture]
  [Category('radix')]
  TTestRadixLumpAliases = class(TObject)
  strict private
    FAliases: IRadixLumpAliases;
    function Resolve(const AName: string): string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeEssereVuotaAllInizio;
    [Test]
    procedure DovrebbeDareIlLumpDiUnNomeDiRadix;
    [Test]
    procedure DovrebbeConfrontareINomiSenzaMaiuscole;
    [Test]
    procedure DovrebbeTenereLUltimaRigaSeUnNomeERipetuto;
    [Test]
    procedure DovrebbeTenereIlPrimoTestoSeUnNomeEInDueTesti;
    [Test]
    procedure DovrebbeSaltareLeRigheSenzaUgualeOVuote;
    [Test]
    procedure DovrebbeScartareIRiferimentiAiLumpCheNonCiSono;
    [Test]
    procedure DovrebbePassareAllaRigaPrimaSeLUltimaHaUnLumpCheNonCe;
    [Test]
    procedure DovrebbeLeggereLeRigheConIFineRigaDiDosEDiUnix;
    [Test]
    procedure DovrebbeTenereINomiConParentesiECancelletti;
    [Test]
    procedure DovrebbeDareFalsoPerUnNomeCheNonCe;
    [Test]
    procedure DovrebbeLeggereLaTabellaVeraDellaVersione2;
  end;

implementation

uses
  System.Classes, System.IOUtils,
  DelphiDoom.Radix.Factory, DelphiDoom.Tests.Shared.Skip;

{ TTestRadixLumpAliases }

procedure TTestRadixLumpAliases.Setup;
begin
  FAliases := TRadixFactory.CreateLumpAliases;
end;

procedure TTestRadixLumpAliases.TearDown;
begin
  FAliases := nil;
end;

function TTestRadixLumpAliases.Resolve(const AName: string): string;
begin
  if not FAliases.TryResolve(AName, Result) then
    Result := '<none>';
end;

procedure TTestRadixLumpAliases.DovrebbeEssereVuotaAllInizio;
begin
  Assert.AreEqual(0, FAliases.Count);
  Assert.AreEqual('<none>', Resolve('MainMenu'));
end;

procedure TTestRadixLumpAliases.DovrebbeDareIlLumpDiUnNomeDiRadix;
begin
  FAliases.AddText('RADIX025=MainMenu'#13#10'RADIX026=MainMenuButton1'#13#10, nil);
  Assert.AreEqual(2, FAliases.Count);
  Assert.AreEqual('RADIX025', Resolve('MainMenu'));
  Assert.AreEqual('RADIX026', Resolve('MainMenuButton1'));
end;

procedure TTestRadixLumpAliases.DovrebbeConfrontareINomiSenzaMaiuscole;
begin
  FAliases.AddText('M_BRIEF=BriefScreen', nil);
  Assert.AreEqual('M_BRIEF', Resolve('BRIEFSCREEN'));
  Assert.AreEqual('M_BRIEF', Resolve('briefscreen'));
  Assert.AreEqual('M_BRIEF', Resolve(' BriefScreen '));
end;

procedure TTestRadixLumpAliases.DovrebbeTenereLUltimaRigaSeUnNomeERipetuto;
begin
  // the old code read the lines from the last and looked for the first it had added
  FAliases.AddText('RADIX001=Arrow'#13#10'RADIX002=Arrow'#13#10, nil);
  Assert.AreEqual(1, FAliases.Count);
  Assert.AreEqual('RADIX002', Resolve('Arrow'));
end;

procedure TTestRadixLumpAliases.DovrebbeTenereIlPrimoTestoSeUnNomeEInDueTesti;
begin
  FAliases.AddText('RADIX001=Arrow', nil);
  FAliases.AddText('RADIX009=Arrow'#13#10'RADIX010=Other', nil);
  Assert.AreEqual('RADIX001', Resolve('Arrow'));
  Assert.AreEqual('RADIX010', Resolve('Other'));
end;

procedure TTestRadixLumpAliases.DovrebbeSaltareLeRigheSenzaUgualeOVuote;
begin
  FAliases.AddText(#13#10'no separator'#13#10'=NoLump'#13#10'NONAME='#13#10'RADIX003=Good'#13#10, nil);
  Assert.AreEqual(1, FAliases.Count);
  Assert.AreEqual('RADIX003', Resolve('Good'));
end;

procedure TTestRadixLumpAliases.DovrebbeScartareIRiferimentiAiLumpCheNonCiSono;
begin
  FAliases.AddText('RADIX001=Here'#13#10'RADIX002=Missing',
    function(const ALumpName: string): Boolean
    begin
      Result := ALumpName = 'RADIX001';
    end);
  Assert.AreEqual(1, FAliases.Count);
  Assert.AreEqual('RADIX001', Resolve('Here'));
  Assert.AreEqual('<none>', Resolve('Missing'));
end;

procedure TTestRadixLumpAliases.DovrebbePassareAllaRigaPrimaSeLUltimaHaUnLumpCheNonCe;
begin
  FAliases.AddText('RADIX001=Arrow'#13#10'RADIX002=Arrow',
    function(const ALumpName: string): Boolean
    begin
      Result := ALumpName = 'RADIX001';
    end);
  Assert.AreEqual('RADIX001', Resolve('Arrow'));
end;

procedure TTestRadixLumpAliases.DovrebbeLeggereLeRigheConIFineRigaDiDosEDiUnix;
begin
  FAliases.AddText('A1=One'#10'A2=Two'#13#10'A3=Three', nil);
  Assert.AreEqual('A1', Resolve('One'));
  Assert.AreEqual('A2', Resolve('Two'));
  Assert.AreEqual('A3', Resolve('Three'));
end;

procedure TTestRadixLumpAliases.DovrebbeTenereINomiConParentesiECancelletti;
begin
  FAliases.AddText('RDXW0001=StreakedMetalPlate2_#1#2#3'#13#10'OBJ11PRI=MissionPrimary[1][1]', nil);
  Assert.AreEqual('RDXW0001', Resolve('StreakedMetalPlate2_#1#2#3'));
  Assert.AreEqual('OBJ11PRI', Resolve('MissionPrimary[1][1]'));
end;

procedure TTestRadixLumpAliases.DovrebbeDareFalsoPerUnNomeCheNonCe;
var
  LLump: string;
begin
  FAliases.AddText('RADIX025=MainMenu', nil);
  Assert.IsFalse(FAliases.TryResolve('MainMenu2', LLump));
  Assert.IsFalse(FAliases.TryResolve('', LLump));
end;

procedure TTestRadixLumpAliases.DovrebbeLeggereLaTabellaVeraDellaVersione2;
var
  LPath: string;
begin
  // the text of RADIXINF that the old translator wrote for the 2.0 shareware (it is in the repository)
  LPath := TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)),
    '..\..\..\..\Tests\Data\Radix\radixinf.v20.golden.txt'));
  if not TFile.Exists(LPath) then
  begin
    TTestSkip.Ignore('radixinf.v20.golden.txt non c''e'' accanto ai test: ' + LPath);
    Exit;
  end;
  FAliases.AddText(TFile.ReadAllText(LPath, TEncoding.ANSI), nil);
  Assert.AreEqual('RADIX025', Resolve('MainMenu'));
  Assert.AreEqual('RADIX001', Resolve('SelectSkill'));
  Assert.AreEqual('M_BRIEF', Resolve('BriefScreen'));
  Assert.AreEqual('M_RADIX', Resolve('DemoDecal'));
  Assert.AreEqual('RDXW0001', Resolve('StreakedMetalPlate2_#1#2#3'));
end;

end.
