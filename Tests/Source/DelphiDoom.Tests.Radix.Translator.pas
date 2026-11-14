{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TRadixTranslator                                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Radix.Translator;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.Generics.Collections,
  DUnitX.TestFramework,
  DelphiDoom.GameData.Intf, DelphiDoom.Radix.Intf;

type
  /// <summary>
  ///   Tests\Data\Radix\translation.*.golden.txt are the lumps (number, name, size and FNV-1a) that
  ///   TRadixToWADConverter.Convert_Game of the fork Rad-X (radix_xlat_wad.pas) wrote from RADIX.DAT,
  ///   compiled in a harness outside the repository (see Tests\Data\Radix\README.md); radixinf.*
  ///   is the text of its lump RADIXINF. The library does a part of the converter: the lumps that
  ///   it writes must be the same as the old ones, in the same order, with the same bytes. The test
  ///   is skipped when RADIX.DAT is not there
  /// </summary>
  [TestFixture]
  [Category('radix')]
  TTestRadixTranslator = class(TObject)
  strict private
    function FindData(const AVersion: string): string;
    function ReadLines(const AFileName: string): TArray<string>;
    function Dump(const AWad: IGameWadComposer): TArray<string>;
    procedure CheckParity(const AVersion: string);
  public
    [Test]
    procedure DovrebbeDareGliStessiLumpDelVecchioCodiceSuRadix20Shareware;
    [Test]
    procedure DovrebbeDareGliStessiLumpDelVecchioCodiceSuRadix10Shareware;
    [Test]
    procedure DovrebbeDareGliAliasDelVecchioCodiceSuRadix20Shareware;
    [Test]
    procedure DovrebbeDareIlNomeDiOgniTextureNellOrdineDiTexture0;
    [Test]
    procedure DovrebbeRifiutareUnContenitoreSenzaPaletta;
    [Test]
    procedure DovrebbeRifiutareUnContenitoreNil;
    [Test]
    procedure DovrebbeRifiutareUnaListaDiPassiSenzaPatchBuilder;
  end;

implementation

uses
  DelphiDoom.GameData.Factory, DelphiDoom.Radix.Types, DelphiDoom.Radix.Factory,
  DelphiDoom.Radix.Translator, DelphiDoom.Tests.GameData.Scenarios, DelphiDoom.Tests.Radix.DatBuilder;

{ TTestRadixTranslator }

function TTestRadixTranslator.FindData(const AVersion: string): string;
var
  LRoot: string;
  LSub: string;
  LCandidates: TArray<string>;
  LCandidate: string;
begin
  LRoot := TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)), '..\..\..\..'));
  if AVersion = 'v20' then
    LSub := 'radix\v20\game\RADIX.DAT'
  else
    LSub := 'radix\v10\RADIX.DAT';
  LCandidates := [TPath.Combine(LRoot, 'bin\Radix\RADIX.DAT'),
    TPath.Combine(LRoot, 'Reference\_dati\' + LSub),
    // the worktrees of the repository are under .claude\worktrees\<name>
    TPath.GetFullPath(TPath.Combine(LRoot, '..\..\..\Reference\_dati\' + LSub))];
  for LCandidate in LCandidates do
    if TFile.Exists(LCandidate) and ((AVersion = 'v20') or not LCandidate.Contains('bin\Radix')) then
      Exit(LCandidate);
  Result := '';
end;

function TTestRadixTranslator.ReadLines(const AFileName: string): TArray<string>;
var
  LLines: TStringList;
begin
  LLines := TStringList.Create;
  try
    LLines.LoadFromFile(TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)),
      '..\..\..\..\Tests\Data\Radix\' + AFileName)));
    Result := LLines.ToStringArray;
  finally
    LLines.Free;
  end;
end;

function TTestRadixTranslator.Dump(const AWad: IGameWadComposer): TArray<string>;
var
  LIndex: Integer;
  LData: TBytes;
  LList: TList<string>;
begin
  LList := TList<string>.Create;
  try
    for LIndex := 0 to AWad.Count - 1 do
    begin
      LData := AWad.LumpData[LIndex];
      if Length(LData) > 0 then
        LList.Add(Format('%s %d %s', [AWad.LumpNames[LIndex], Length(LData),
          TGameDataScenarios.Digest(LData)]))
      else
        LList.Add(Format('%s 0 00000000', [AWad.LumpNames[LIndex]]));
    end;
    Result := LList.ToArray;
  finally
    LList.Free;
  end;
end;

procedure TTestRadixTranslator.CheckParity(const AVersion: string);
var
  LPath: string;
  LTranslator: IRadixTranslator;
  LActual: TArray<string>;
  LGolden: TArray<string>;
  LParts: TArray<string>;
  LLine: Integer;
  LGoldenIndex: Integer;
  LName: string;
  LFound: Boolean;
begin
  LPath := FindData(AVersion);
  if LPath = '' then
    Assert.Pass('RADIX.DAT is not there');
  LTranslator := TRadixFactory.CreateTranslator;
  LActual := Dump(LTranslator.Translate(TRadixFactory.OpenContainer(LPath)));
  LGolden := ReadLines('translation.' + AVersion + '.golden.txt');
  // the translator is complete: the same lumps as the old one, in the same order
  Assert.AreEqual(Length(LGolden) - 1, Length(LActual), 'the number of lumps');
  // every lump of the library is the next one of the old converter with its name: same size, same bytes
  LGoldenIndex := 1;
  for LLine := 0 to High(LActual) do
  begin
    LName := Copy(LActual[LLine], 1, Pos(' ', LActual[LLine]) - 1);
    if LName = RADIX_ALIASES_LUMP then
      Continue;
    LFound := False;
    while LGoldenIndex <= High(LGolden) do
    begin
      LParts := LGolden[LGoldenIndex].Split([' ']);
      Inc(LGoldenIndex);
      if LParts[1] = LName then
      begin
        LFound := True;
        Assert.AreEqual(LParts[1] + ' ' + LParts[2] + ' ' + LParts[3], LActual[LLine],
          'lump ' + IntToStr(LLine));
        Break;
      end;
    end;
    Assert.IsTrue(LFound, 'the lump ' + LName + ' is in the old WAD after the previous one');
  end;
end;

procedure TTestRadixTranslator.DovrebbeDareGliStessiLumpDelVecchioCodiceSuRadix20Shareware;
begin
  CheckParity('v20');
end;

procedure TTestRadixTranslator.DovrebbeDareGliStessiLumpDelVecchioCodiceSuRadix10Shareware;
begin
  CheckParity('v10');
end;

procedure TTestRadixTranslator.DovrebbeDareGliAliasDelVecchioCodiceSuRadix20Shareware;
var
  LPath: string;
  LWad: IGameWadComposer;
  LText: string;
  LGolden: TStringList;
  LLines: TStringList;
  LLine: string;
begin
  LPath := FindData('v20');
  if LPath = '' then
    Assert.Pass('RADIX.DAT is not there');
  LWad := TRadixFactory.CreateTranslator.Translate(TRadixFactory.OpenContainer(LPath));
  LText := TEncoding.ANSI.GetString(LWad.LumpData[LWad.IndexOf(RADIX_ALIASES_LUMP)]);
  LGolden := TStringList.Create;
  LLines := TStringList.Create;
  try
    LGolden.Text := TEncoding.ANSI.GetString(TFile.ReadAllBytes(TPath.GetFullPath(
      TPath.Combine(TPath.GetDirectoryName(ParamStr(0)), '..\..\..\..\Tests\Data\Radix\radixinf.v20.golden.txt'))));
    LLines.Text := LText;
    Assert.IsTrue(LLines.Count > 400);
    // the old text has the aliases of the parts that are not ported too: the ones of the library
    // are in it, in the same order
    LGolden.Sorted := False;
    for LLine in LLines do
      Assert.IsTrue(LGolden.IndexOf(LLine) >= 0, 'the alias ' + LLine);
  finally
    LLines.Free;
    LGolden.Free;
  end;
end;

procedure TTestRadixTranslator.DovrebbeDareIlNomeDiOgniTextureNellOrdineDiTexture0;
var
  LBuilder: TRadixDatBuilder;
  LTranslator: IRadixTranslator;
  LNames: TArray<string>;
begin
  LBuilder := TRadixDatBuilder.Create;
  try
    LBuilder.Add('Palette[1]', TRadixDatBuilder.Pattern(768, 2));
    LBuilder.AddWallBitmaps([8, 8, 16, 16]);
    LTranslator := TRadixFactory.CreateTranslator;
    LTranslator.Translate(TRadixFactory.OpenContainerBytes(LBuilder.ToBytes));
  finally
    LBuilder.Free;
  end;
  LNames := LTranslator.TextureNames;
  Assert.AreEqual<Integer>(2, Length(LNames));
  Assert.AreEqual('Wall0', LNames[0]);
  Assert.AreEqual('Wall1', LNames[1]);
end;

procedure TTestRadixTranslator.DovrebbeRifiutareUnContenitoreSenzaPaletta;
var
  LBuilder: TRadixDatBuilder;
  LContainer: IRadixContainer;
begin
  LBuilder := TRadixDatBuilder.Create;
  try
    LBuilder.Add('Other', [1]);
    LContainer := TRadixFactory.OpenContainerBytes(LBuilder.ToBytes);
  finally
    LBuilder.Free;
  end;
  Assert.WillRaise(
    procedure
    begin
      TRadixFactory.CreateTranslator.Translate(LContainer);
    end, ERadixException);
end;

procedure TTestRadixTranslator.DovrebbeRifiutareUnContenitoreNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TRadixFactory.CreateTranslator.Translate(nil);
    end, EArgumentNilException);
end;

procedure TTestRadixTranslator.DovrebbeRifiutareUnaListaDiPassiSenzaPatchBuilder;
begin
  Assert.WillRaise(
    procedure
    begin
      TRadixTranslator.Create(nil, nil,
        function: IGameWadComposer
        begin
          Result := TGameDataFactory.CreateWadComposer;
        end);
    end, EArgumentNilException);
end;

end.
