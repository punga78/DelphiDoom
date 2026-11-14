{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the AAS library - parity of the routing with the real  }
{  C code of Quake III                                                         }
{                                                                              }
{  route_*.golden.txt are what the real be_aas_route.c and be_aas_routealt.c   }
{  (compiled with gcc by Tools\Verifica\122\route) print for the scenario.     }
{  The maps of OpenArena are read from Reference\openarena (not in git) and    }
{  the tests are ignored if they are missing.                                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Aas.Route.Golden;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework;

type
  [TestFixture]
  [Category('Aas')]
  TTestAasRouteGolden = class
  strict private
    FDataFolder: string;
    function DataFolder: string;
    procedure Compare(const AName: string; const ABytes: TBytes; const AGolden: string; const AMemoryLimit: Integer;
      const AMove: Boolean = False);
    function OpenArenaMap(const AName: string): TBytes;
  public
    [Test]
    procedure DovrebbeDareLeStesseRisposteDelCPerFan;
    [Test]
    procedure DovrebbeDareLeStesseRisposteDelCPerFanConPocaMemoria;
    [Test]
    procedure DovrebbeDareLeStesseRisposteDelCPerOaBases3;
    [Test]
    procedure DovrebbeDareLeStesseRisposteDelCPerOaBases3ConPocaMemoria;
    [Test]
    procedure DovrebbeDareLeStesseRisposteDelCPerBlitzkrieg3;
    [Test]
    procedure DovrebbeDareLeStesseRisposteDelCPerBlitzkrieg3ConPocaMemoria;
    /// <summary>
    ///   Every map of OpenArena: the goldens of the maps are not in the repository, Make-Golden.ps1 -Maps (all the
    ///   names) writes them in a folder that DELPHIDOOM_ROUTE_GOLDENS names
    /// </summary>
    [Test]
    procedure DovrebbeDareLeStesseRisposteDelCPerTutteLeMappeDiOpenArena;
    [Test]
    procedure DovrebbeDareLaStessaPrevisioneDelMovimentoPerFan;
    [Test]
    procedure DovrebbeDareLaStessaPrevisioneDelMovimentoPerOaBases3;
    [Test]
    procedure DovrebbeDareLaStessaPrevisioneDelMovimentoPerBlitzkrieg3;
    [Test]
    procedure DovrebbeDareLaStessaPrevisioneDelMovimentoPerTutteLeMappeDiOpenArena;
  end;

implementation

uses
  System.IOUtils, System.Zip, DUnitX.Exceptions, DelphiDoom.Tests.Aas.Sample, DelphiDoom.Tests.Aas.Route.Scenario,
  DelphiDoom.Tests.Aas.Move.Scenario;

const
  // 1 MB + 20000 bytes: the routing keeps at most 20000 bytes of cache (see Make-Golden.ps1)
  SMALL_LIMIT = 1048576 + 20000;
  PAKS: array[0..2] of string = ('pak6-misc.pk3', 'pak6-patch085.pk3', 'pak6-patch088.pk3');

{ TTestAasRouteGolden }

function TTestAasRouteGolden.DataFolder: string;
begin
  if FDataFolder <> '' then
    Exit(FDataFolder);
  Result := ExpandFileName(ExtractFilePath(ParamStr(0)) + '..\..\..\..\Tests\Data\Aas\');
end;

function TTestAasRouteGolden.OpenArenaMap(const AName: string): TBytes;
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
  if Length(Result) > 0 then
    Exit;
  raise ETestIgnored.Create(AName + '.aas non c''e'': prova ignorata');
end;

procedure TTestAasRouteGolden.Compare(const AName: string; const ABytes: TBytes; const AGolden: string;
  const AMemoryLimit: Integer; const AMove: Boolean);
var
  LActual, LGolden, LExpected: TStringList;
  LRunner: TAasRouteScenario;
  LMoveRunner: TAasMoveScenario;
  LLine, LActualLine: string;
  LIndex: Integer;
begin
  LActual := TStringList.Create;
  LGolden := TStringList.Create;
  LExpected := TStringList.Create;
  try
    Assert.IsTrue(TFile.Exists(DataFolder + AGolden), AGolden + ' not found in ' + DataFolder);
    if AMove then
    begin
      LMoveRunner := TAasMoveScenario.Create(LActual);
      try
        LMoveRunner.Run(AName, ABytes);
      finally
        LMoveRunner.Free;
      end;
    end
    else
    begin
      LRunner := TAasRouteScenario.Create(LActual, AMemoryLimit);
      try
        LRunner.Run(AName, ABytes);
      finally
        LRunner.Free;
      end;
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

procedure TTestAasRouteGolden.DovrebbeDareLeStesseRisposteDelCPerFan;
begin
  Compare('fan.aas', OpenArenaMap('fan'), 'route_fan.golden.txt', 0);
end;

procedure TTestAasRouteGolden.DovrebbeDareLeStesseRisposteDelCPerFanConPocaMemoria;
begin
  Compare('fan.aas', OpenArenaMap('fan'), 'route_fan_small.golden.txt', SMALL_LIMIT);
end;

procedure TTestAasRouteGolden.DovrebbeDareLeStesseRisposteDelCPerOaBases3;
begin
  Compare('oa_bases3.aas', OpenArenaMap('oa_bases3'), 'route_oa_bases3.golden.txt', 0);
end;

procedure TTestAasRouteGolden.DovrebbeDareLeStesseRisposteDelCPerOaBases3ConPocaMemoria;
begin
  Compare('oa_bases3.aas', OpenArenaMap('oa_bases3'), 'route_oa_bases3_small.golden.txt', SMALL_LIMIT);
end;

procedure TTestAasRouteGolden.DovrebbeDareLeStesseRisposteDelCPerBlitzkrieg3;
begin
  Compare('blitzkrieg3.aas', OpenArenaMap('blitzkrieg3'), 'route_blitzkrieg3.golden.txt', 0);
end;

procedure TTestAasRouteGolden.DovrebbeDareLeStesseRisposteDelCPerBlitzkrieg3ConPocaMemoria;
begin
  Compare('blitzkrieg3.aas', OpenArenaMap('blitzkrieg3'), 'route_blitzkrieg3_small.golden.txt', SMALL_LIMIT);
end;

procedure TTestAasRouteGolden.DovrebbeDareLeStesseRisposteDelCPerTutteLeMappeDiOpenArena;
var
  LFolder, LFile, LName: string;
  LCount: Integer;
begin
  LFolder := GetEnvironmentVariable('DELPHIDOOM_ROUTE_GOLDENS');
  if (LFolder = '') or not TDirectory.Exists(LFolder) then
    raise ETestIgnored.Create('DELPHIDOOM_ROUTE_GOLDENS non c''e'': prova ignorata');
  LCount := 0;
  for LFile in TDirectory.GetFiles(LFolder, 'route_*.golden.txt') do
  begin
    LName := TPath.GetFileName(LFile);
    if LName.EndsWith('_small.golden.txt') then
      Continue;
    LName := Copy(LName, 7, Length(LName) - 7 - Length('.golden.txt') + 1);
    FDataFolder := LFolder + PathDelim;
    Compare(LName + '.aas', OpenArenaMap(LName), TPath.GetFileName(LFile), 0);
    Inc(LCount);
  end;
  Assert.IsTrue(LCount > 0);
end;

procedure TTestAasRouteGolden.DovrebbeDareLaStessaPrevisioneDelMovimentoPerFan;
begin
  Compare('fan.aas', OpenArenaMap('fan'), 'move_fan.golden.txt', 0, True);
end;

procedure TTestAasRouteGolden.DovrebbeDareLaStessaPrevisioneDelMovimentoPerOaBases3;
begin
  Compare('oa_bases3.aas', OpenArenaMap('oa_bases3'), 'move_oa_bases3.golden.txt', 0, True);
end;

procedure TTestAasRouteGolden.DovrebbeDareLaStessaPrevisioneDelMovimentoPerBlitzkrieg3;
begin
  Compare('blitzkrieg3.aas', OpenArenaMap('blitzkrieg3'), 'move_blitzkrieg3.golden.txt', 0, True);
end;

procedure TTestAasRouteGolden.DovrebbeDareLaStessaPrevisioneDelMovimentoPerTutteLeMappeDiOpenArena;
var
  LFolder, LFile, LName: string;
  LCount: Integer;
begin
  LFolder := GetEnvironmentVariable('DELPHIDOOM_ROUTE_GOLDENS');
  if (LFolder = '') or not TDirectory.Exists(LFolder) then
    raise ETestIgnored.Create('DELPHIDOOM_ROUTE_GOLDENS non c''e'': prova ignorata');
  LCount := 0;
  for LFile in TDirectory.GetFiles(LFolder, 'move_*.golden.txt') do
  begin
    LName := TPath.GetFileName(LFile);
    LName := Copy(LName, 6, Length(LName) - 6 - Length('.golden.txt') + 1);
    FDataFolder := LFolder + PathDelim;
    try
      Compare(LName + '.aas', OpenArenaMap(LName), TPath.GetFileName(LFile), 0, True);
    except
      on E: EZeroDivide do
        raise Exception.Create('Map ' + LName + ': ' + E.Message);
    end;
    Inc(LCount);
  end;
  Assert.IsTrue(LCount > 0);
end;

initialization  TDUnitX.RegisterTestFixture(TTestAasRouteGolden);

end.
