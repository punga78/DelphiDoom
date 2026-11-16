{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the AAS library - parity of the clustering and of the  }
{  optimizer with the real C code of Quake III                                 }
{                                                                              }
{  cluster_*.golden.txt are what the real be_aas_cluster.c and                 }
{  be_aas_optimize.c (compiled with gcc by Tools\Verifica\122\cluster) print   }
{  for the scenario. The maps of OpenArena are read from Reference\openarena   }
{  (not in git) and the tests are ignored if they are missing.                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Aas.Cluster.Golden;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework;

type
  [TestFixture]
  [Category('Aas')]
  TTestAasClusterGolden = class
  strict private
    FDataFolder: string;
    function DataFolder: string;
    procedure Compare(const AName: string; const ABytes: TBytes; const AGolden: string);
    function OpenArenaMap(const AName: string): TBytes;
  public
    [Test]
    procedure DovrebbeDareLeStesseRisposteDelCPerIlMondoDiProva0;
    [Test]
    procedure DovrebbeDareLeStesseRisposteDelCPerIlMondoDiProva1;
    [Test]
    procedure DovrebbeDareLeStesseRisposteDelCPerFan;
    [Test]
    procedure DovrebbeDareLeStesseRisposteDelCPerOaBases3;
    [Test]
    procedure DovrebbeDareLeStesseRisposteDelCPerBlitzkrieg3;
    /// <summary>
    ///   Every map of OpenArena: the goldens of the maps are not in the repository; the loop of the C tool over the 71
    ///   files (see IdTech4\Aas\README.md) writes them in a folder that DELPHIDOOM_CLUSTER_GOLDENS names
    /// </summary>
    [Test]
    procedure DovrebbeDareLeStesseRisposteDelCPerTutteLeMappeDiOpenArena;
  end;

implementation

uses
  System.IOUtils, System.Zip, DUnitX.Exceptions, DelphiDoom.Tests.Aas.Sample, DelphiDoom.Tests.Aas.Cluster.Scenario;

const
  PAKS: array[0..2] of string = ('pak6-misc.pk3', 'pak6-patch085.pk3', 'pak6-patch088.pk3');

{ TTestAasClusterGolden }

function TTestAasClusterGolden.DataFolder: string;
begin
  if FDataFolder <> '' then
    Exit(FDataFolder);
  Result := ExpandFileName(ExtractFilePath(ParamStr(0)) + '..\..\..\..\Tests\Data\Aas\');
end;

function TTestAasClusterGolden.OpenArenaMap(const AName: string): TBytes;
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
  // the later paks replace the earlier ones
  Result := nil;
  for LPak in PAKS do
  begin
    if not TFile.Exists(TPath.Combine(LBase, LPak)) then
      Continue;
    LZip := TZipFile.Create;
    try
      LZip.Open(TPath.Combine(LBase, LPak), zmRead);
      for LEntry in LZip.FileNames do
        if SameText(TPath.GetFileName(LEntry), AName + '.aas') then
          LZip.Read(LEntry, Result);
    finally
      LZip.Free;
    end;
  end;
  if Length(Result) = 0 then
    raise ETestIgnored.Create(AName + '.aas non c''e'': prova ignorata');
end;

procedure TTestAasClusterGolden.Compare(const AName: string; const ABytes: TBytes; const AGolden: string);
var
  LActual, LGolden, LExpected: TStringList;
  LRunner: TAasClusterScenario;
  LLine, LActualLine: string;
  LIndex: Integer;
begin
  LActual := TStringList.Create;
  LGolden := TStringList.Create;
  LExpected := TStringList.Create;
  try
    Assert.IsTrue(TFile.Exists(DataFolder + AGolden), AGolden + ' not found in ' + DataFolder);
    LRunner := TAasClusterScenario.Create(LActual);
    try
      LRunner.Run(AName, ABytes);
    finally
      LRunner.Free;
    end;
    LGolden.LoadFromFile(DataFolder + AGolden);
    // AAS_LoadAASFile prints one line before it reads: the C tool loads six times, the scenario reads from memory
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

procedure TTestAasClusterGolden.DovrebbeDareLeStesseRisposteDelCPerIlMondoDiProva0;
begin
  Compare('sample0.aas', TAasSample.Bytes(0), 'cluster_sample0.golden.txt');
end;

procedure TTestAasClusterGolden.DovrebbeDareLeStesseRisposteDelCPerIlMondoDiProva1;
begin
  Compare('sample1.aas', TAasSample.Bytes(1), 'cluster_sample1.golden.txt');
end;

procedure TTestAasClusterGolden.DovrebbeDareLeStesseRisposteDelCPerFan;
begin
  Compare('fan.aas', OpenArenaMap('fan'), 'cluster_fan.golden.txt');
end;

procedure TTestAasClusterGolden.DovrebbeDareLeStesseRisposteDelCPerOaBases3;
begin
  Compare('oa_bases3.aas', OpenArenaMap('oa_bases3'), 'cluster_oa_bases3.golden.txt');
end;

procedure TTestAasClusterGolden.DovrebbeDareLeStesseRisposteDelCPerBlitzkrieg3;
begin
  Compare('blitzkrieg3.aas', OpenArenaMap('blitzkrieg3'), 'cluster_blitzkrieg3.golden.txt');
end;

procedure TTestAasClusterGolden.DovrebbeDareLeStesseRisposteDelCPerTutteLeMappeDiOpenArena;
var
  LFolder, LFile, LName: string;
  LCount: Integer;
begin
  LFolder := GetEnvironmentVariable('DELPHIDOOM_CLUSTER_GOLDENS');
  if (LFolder = '') or not TDirectory.Exists(LFolder) then
    raise ETestIgnored.Create('DELPHIDOOM_CLUSTER_GOLDENS non c''e'': prova ignorata');
  LCount := 0;
  FDataFolder := LFolder + PathDelim;
  try
    for LFile in TDirectory.GetFiles(LFolder, 'cluster_*.golden.txt') do
    begin
      LName := TPath.GetFileName(LFile);
      LName := Copy(LName, 9, Length(LName) - 9 - Length('.golden.txt') + 1);
      if LName.StartsWith('sample') then
        Continue;
      Compare(LName + '.aas', OpenArenaMap(LName), TPath.GetFileName(LFile));
      Inc(LCount);
    end;
  finally
    FDataFolder := '';
  end;
  Assert.IsTrue(LCount > 0);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestAasClusterGolden);

end.
