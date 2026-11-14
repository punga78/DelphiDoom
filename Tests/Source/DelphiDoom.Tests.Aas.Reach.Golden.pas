{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the AAS library - parity of the reachabilities with    }
{  the real C code of Quake III                                                }
{                                                                              }
{  reach_*.golden.txt are what the real be_aas_reach.c (compiled with gcc by   }
{  Tools\Verifica\122\reach) prints when it calculates again the               }
{  reachabilities of a map of OpenArena with the grapple ones. The BSP of the  }
{  game is replaced by the twins of the C tool (see Reach.Scenario): the       }
{  logic of the calculation is what is compared, not the reachabilities that   }
{  the game has. The maps are read from Reference\openarena (not in git) and   }
{  the tests are ignored if they are missing.                                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Aas.Reach.Golden;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework;

type
  [TestFixture]
  [Category('Aas')]
  TTestAasReachGolden = class
  strict private
    FDataFolder: string;
    function DataFolder: string;
    procedure Compare(const AName: string; const AFull: Boolean; const AGolden: string);
    function ReadFromPaks(const AName, AExtension: string; const APaks: array of string): TBytes;
  public
    [Test]
    procedure DovrebbeDareLeStesseRaggiungibilitaDelCPerFan;
    [Test]
    procedure DovrebbeDareLeStesseRaggiungibilitaDelCPerOaBases5;
    [Test]
    procedure DovrebbeDareLeStesseRaggiungibilitaDelCPerOaDm4;
    /// <summary>
    ///   Every map of OpenArena: the goldens of the maps are not in the repository, Make-Golden.ps1 -All writes them in
    ///   <c>goldens</c> of the folder of the tool; DELPHIDOOM_REACH_GOLDENS names it
    /// </summary>
    [Test]
    procedure DovrebbeDareLeStesseRaggiungibilitaDelCPerTutteLeMappeDiOpenArena;
  end;

implementation

uses
  System.IOUtils, System.Zip, DUnitX.Exceptions, DelphiDoom.Tests.Aas.Reach.Scenario;

const
  AAS_PAKS: array[0..2] of string = ('pak6-misc.pk3', 'pak6-patch085.pk3', 'pak6-patch088.pk3');
  BSP_PAKS: array[0..3] of string = ('pak1-maps.pk3', 'pak6-misc.pk3', 'pak6-patch085.pk3', 'pak6-patch088.pk3');

{ TTestAasReachGolden }

function TTestAasReachGolden.DataFolder: string;
begin
  if FDataFolder <> '' then
    Exit(FDataFolder);
  Result := ExpandFileName(ExtractFilePath(ParamStr(0)) + '..\..\..\..\Tests\Data\Aas\');
end;

function TTestAasReachGolden.ReadFromPaks(const AName, AExtension: string; const APaks: array of string): TBytes;
var
  LBase, LPak, LEntry: string;
  LZip: TZipFile;
begin
  LBase := GetEnvironmentVariable('DELPHIDOOM_OPENARENA');
  if (LBase <> '') and TFile.Exists(LBase) then
    LBase := TPath.GetDirectoryName(LBase);
  if (LBase = '') or not TDirectory.Exists(LBase) then
    LBase := TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)),
      '..\..\..\..\Reference\openarena\openarena-0.8.8\baseoa'));
  if not TDirectory.Exists(LBase) then
    raise ETestIgnored.Create('OpenArena non c''e'': prova ignorata');
  // the later paks replace the earlier ones (the C tool extracts them in order and keeps the last)
  Result := nil;
  for LPak in APaks do
  begin
    if not TFile.Exists(TPath.Combine(LBase, LPak)) then
      Continue;
    LZip := TZipFile.Create;
    try
      LZip.Open(TPath.Combine(LBase, LPak), zmRead);
      for LEntry in LZip.FileNames do
        if SameText(TPath.GetFileName(LEntry), AName + AExtension) then
          LZip.Read(LEntry, Result);
    finally
      LZip.Free;
    end;
  end;
  if Length(Result) = 0 then
    raise ETestIgnored.Create(AName + AExtension + ' non c''e'': prova ignorata');
end;

procedure TTestAasReachGolden.Compare(const AName: string; const AFull: Boolean; const AGolden: string);
var
  LActual, LGolden, LExpected: TStringList;
  LRunner: TAasReachScenario;
  LLine, LActualLine: string;
  LIndex: Integer;
  LAas, LBsp: TBytes;
begin
  LAas := ReadFromPaks(AName, '.aas', AAS_PAKS);
  LBsp := ReadFromPaks(AName, '.bsp', BSP_PAKS);
  LActual := TStringList.Create;
  LGolden := TStringList.Create;
  LExpected := TStringList.Create;
  try
    Assert.IsTrue(TFile.Exists(DataFolder + AGolden), AGolden + ' not found in ' + DataFolder);
    LRunner := TAasReachScenario.Create(LActual, AFull, True);
    try
      LRunner.Run(AName + '.aas', LAas, LBsp);
    finally
      LRunner.Free;
    end;
    LGolden.LoadFromFile(DataFolder + AGolden);
    // the C tool reads the file through AAS_LoadAASFile, which prints one line before the checks
    for LLine in LGolden do
      if Copy(LLine, 1, 10) <> 'P1|trying ' then
        LExpected.Add(LLine);
    if LActual.Text <> LExpected.Text then
    begin
      LActual.SaveToFile(ExtractFilePath(ParamStr(0)) + ChangeFileExt(AGolden, '') + '.actual.txt');
      for LIndex := 0 to LExpected.Count - 1 do
        if (LIndex >= LActual.Count) or (LActual[LIndex] <> LExpected[LIndex]) then
        begin
          if LIndex < LActual.Count then
            LActualLine := LActual[LIndex]
          else
            LActualLine := '(none)';
          Assert.Fail(Format('first difference at line %d: expected "%s", got "%s"',
            [LIndex + 1, LExpected[LIndex], LActualLine]));
        end;
      Assert.AreEqual<Integer>(LExpected.Count, LActual.Count, 'number of lines');
    end;
  finally
    LExpected.Free;
    LGolden.Free;
    LActual.Free;
  end;
end;

procedure TTestAasReachGolden.DovrebbeDareLeStesseRaggiungibilitaDelCPerFan;
begin
  Compare('fan', False, 'reach_fan.golden.txt');
end;

procedure TTestAasReachGolden.DovrebbeDareLeStesseRaggiungibilitaDelCPerOaBases5;
begin
  Compare('oa_bases5', False, 'reach_oa_bases5.golden.txt');
end;

procedure TTestAasReachGolden.DovrebbeDareLeStesseRaggiungibilitaDelCPerOaDm4;
begin
  Compare('oa_dm4', False, 'reach_oa_dm4.golden.txt');
end;

procedure TTestAasReachGolden.DovrebbeDareLeStesseRaggiungibilitaDelCPerTutteLeMappeDiOpenArena;
var
  LFolder, LFile, LName: string;
  LCount: Integer;
begin
  LFolder := GetEnvironmentVariable('DELPHIDOOM_REACH_GOLDENS');
  if (LFolder = '') or not TDirectory.Exists(LFolder) then
    raise ETestIgnored.Create('DELPHIDOOM_REACH_GOLDENS non c''e'': prova ignorata');
  LCount := 0;
  for LFile in TDirectory.GetFiles(LFolder, 'reach_*.golden.txt') do
  begin
    LName := TPath.GetFileName(LFile);
    LName := Copy(LName, 7, Length(LName) - 7 - Length('.golden.txt') + 1);
    FDataFolder := LFolder + PathDelim;
    Compare(LName, True, TPath.GetFileName(LFile));
    Inc(LCount);
  end;
  Assert.IsTrue(LCount > 0);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestAasReachGolden);

end.
