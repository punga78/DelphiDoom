{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the UDMF library - parity with the old converter        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Udmf.Parity;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, DUnitX.TestFramework, DelphiDoom.Udmf.Types,
  DelphiDoom.Udmf.Intf, DelphiDoom.Logging.Intf, DelphiDoom.Logging.Recorder;

type
  /// <summary>
  ///   The wads in Tests\Data\Udmf\{Doom,Heretic,Hexen,Strife} were made by the old converter
  ///   (TUDMFManager of p_udmf.pas) built for each game, on the texts in Tests\Data\Udmf. The
  ///   new one has to write the same records in every lump. Two things are not the same on
  ///   purpose: the lump NSPACE (the old code wrote two bytes for each character of the
  ///   namespace and said one) and the names of 9 or more characters (the old code stopped the
  ///   game)
  /// </summary>
  [TestFixture]
  [Category('udmf')]
  TTestUdmfParity = class(TObject)
  private
    FRecorder: TLogRecorder;
    FSink: ILogSink;
    function DataPath(const AFileName: string): string;
    function ReadText(const AName: string): string;
    function ReadLumps(const AFileName: string): TArray<TUdmfLump>;
    function WarningsOf(const AText: string): TArray<string>;
    function GoldenWarnings(const AFileName: string): TArray<string>;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    [TestCase('doom empty', 'Doom,empty')]
    [TestCase('doom unknown_namespace', 'Doom,unknown_namespace')]
    [TestCase('doom square_doom', 'Doom,square_doom')]
    [TestCase('doom square_heretic', 'Doom,square_heretic')]
    [TestCase('doom square_hexen', 'Doom,square_hexen')]
    [TestCase('doom square_strife', 'Doom,square_strife')]
    [TestCase('doom square_zdoomtranslated', 'Doom,square_zdoomtranslated')]
    [TestCase('doom things', 'Doom,things')]
    [TestCase('doom lines', 'Doom,lines')]
    [TestCase('doom sides', 'Doom,sides')]
    [TestCase('doom vertexes', 'Doom,vertexes')]
    [TestCase('doom sectors', 'Doom,sectors')]
    [TestCase('doom comments', 'Doom,comments')]
    [TestCase('doom numbers', 'Doom,numbers')]
    [TestCase('heretic empty', 'Heretic,empty')]
    [TestCase('heretic unknown_namespace', 'Heretic,unknown_namespace')]
    [TestCase('heretic square_doom', 'Heretic,square_doom')]
    [TestCase('heretic square_heretic', 'Heretic,square_heretic')]
    [TestCase('heretic square_hexen', 'Heretic,square_hexen')]
    [TestCase('heretic square_strife', 'Heretic,square_strife')]
    [TestCase('heretic square_zdoomtranslated', 'Heretic,square_zdoomtranslated')]
    [TestCase('heretic things', 'Heretic,things')]
    [TestCase('heretic lines', 'Heretic,lines')]
    [TestCase('heretic sides', 'Heretic,sides')]
    [TestCase('heretic vertexes', 'Heretic,vertexes')]
    [TestCase('heretic sectors', 'Heretic,sectors')]
    [TestCase('heretic comments', 'Heretic,comments')]
    [TestCase('heretic numbers', 'Heretic,numbers')]
    [TestCase('hexen empty', 'Hexen,empty')]
    [TestCase('hexen unknown_namespace', 'Hexen,unknown_namespace')]
    [TestCase('hexen square_doom', 'Hexen,square_doom')]
    [TestCase('hexen square_heretic', 'Hexen,square_heretic')]
    [TestCase('hexen square_hexen', 'Hexen,square_hexen')]
    [TestCase('hexen square_strife', 'Hexen,square_strife')]
    [TestCase('hexen square_zdoomtranslated', 'Hexen,square_zdoomtranslated')]
    [TestCase('hexen things', 'Hexen,things')]
    [TestCase('hexen lines', 'Hexen,lines')]
    [TestCase('hexen sides', 'Hexen,sides')]
    [TestCase('hexen vertexes', 'Hexen,vertexes')]
    [TestCase('hexen sectors', 'Hexen,sectors')]
    [TestCase('hexen comments', 'Hexen,comments')]
    [TestCase('hexen numbers', 'Hexen,numbers')]
    [TestCase('strife empty', 'Strife,empty')]
    [TestCase('strife unknown_namespace', 'Strife,unknown_namespace')]
    [TestCase('strife square_doom', 'Strife,square_doom')]
    [TestCase('strife square_heretic', 'Strife,square_heretic')]
    [TestCase('strife square_hexen', 'Strife,square_hexen')]
    [TestCase('strife square_strife', 'Strife,square_strife')]
    [TestCase('strife square_zdoomtranslated', 'Strife,square_zdoomtranslated')]
    [TestCase('strife things', 'Strife,things')]
    [TestCase('strife lines', 'Strife,lines')]
    [TestCase('strife sides', 'Strife,sides')]
    [TestCase('strife vertexes', 'Strife,vertexes')]
    [TestCase('strife sectors', 'Strife,sectors')]
    [TestCase('strife comments', 'Strife,comments')]
    [TestCase('strife numbers', 'Strife,numbers')]
    procedure TestSameLumpsAsTheOldConverter(const AGame, ASample: string);
  end;

implementation

uses
  DelphiDoom.Udmf.Games, DelphiDoom.Udmf.Factory, DelphiDoom.Logging.Types,
  DelphiDoom.Logging.Factory, DelphiDoom.Tests.Udmf.Sounds;

{ TTestUdmfParity }

procedure TTestUdmfParity.Setup;
begin
  FRecorder := TLogRecorder.Create;
  FSink := FRecorder;
end;

procedure TTestUdmfParity.TearDown;
begin
  FSink := nil;
  FRecorder := nil;
end;

function TTestUdmfParity.DataPath(const AFileName: string): string;
begin
  Result := TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)),
    '..\..\Tests\Data\Udmf\' + AFileName));
end;

function TTestUdmfParity.ReadText(const AName: string): string;
var
  LList: TStringList;
begin
  // the old converter was given the text of a TStringList: the lines end in CR LF
  LList := TStringList.Create;
  try
    LList.LoadFromFile(DataPath(AName + '.txt'));
    Result := LList.Text;
  finally
    LList.Free;
  end;
end;

function TTestUdmfParity.ReadLumps(const AFileName: string): TArray<TUdmfLump>;
var
  LBytes: TBytes;
  LCount: Integer;
  LTable: Integer;
  LIndex: Integer;
  LEntry: Integer;
  LPosition: Integer;
  LSize: Integer;
  LName: string;
  LChar: Integer;
begin
  LBytes := TFile.ReadAllBytes(AFileName);
  LCount := PInteger(@LBytes[4])^;
  LTable := PInteger(@LBytes[8])^;
  SetLength(Result, LCount);
  for LIndex := 0 to LCount - 1 do
  begin
    LEntry := LTable + LIndex * 16;
    LPosition := PInteger(@LBytes[LEntry])^;
    LSize := PInteger(@LBytes[LEntry + 4])^;
    LName := '';
    for LChar := 0 to 7 do
      if LBytes[LEntry + 8 + LChar] <> 0 then
        LName := LName + Char(LBytes[LEntry + 8 + LChar]);
    Result[LIndex].Name := LName;
    Result[LIndex].Data := Copy(LBytes, LPosition, LSize);
  end;
end;

function TTestUdmfParity.WarningsOf(const AText: string): TArray<string>;
var
  LLines: TArray<string>;
  LLine: string;
  LPrefix: string;
begin
  // the warnings that the two converters have in common, one for each line of the log
  Result := nil;
  LPrefix := 'I_Warning: ';
  LLines := AText.Split([#13#10], TStringSplitOptions.ExcludeEmpty);
  for LLine in LLines do
    if Pos(LPrefix + 'TUDMFManager.LoadFromString()', LLine) = 1 then
    begin
      SetLength(Result, Length(Result) + 1);
      Result[High(Result)] := Copy(LLine, Length(LPrefix) + 1, MaxInt);
    end;
end;

function TTestUdmfParity.GoldenWarnings(const AFileName: string): TArray<string>;
var
  LLines: TArray<string>;
  LLine: string;
begin
  Result := nil;
  LLines := TFile.ReadAllText(AFileName, TEncoding.ANSI).Split([#13#10], TStringSplitOptions.ExcludeEmpty);
  for LLine in LLines do
    if Pos('TUDMFManager.LoadFromString()', LLine) = 1 then
    begin
      SetLength(Result, Length(Result) + 1);
      Result[High(Result)] := LLine;
    end;
end;

procedure TTestUdmfParity.TestSameLumpsAsTheOldConverter(const AGame, ASample: string);
var
  LGame: TUdmfGame;
  LConverter: IUdmfConverter;
  LMap: IUdmfConvertedMap;
  LExpected: TArray<TUdmfLump>;
  LActual: TArray<TUdmfLump>;
  LIndex: Integer;
  LGoldenWarnings: TArray<string>;
  LOurWarnings: TArray<string>;
  LWarning: Integer;
  LBase: string;
begin
  LBase := AGame + '\' + ASample;
  Assert.IsTrue(TUdmfGames.TryFromName(AGame, LGame), 'the game ' + AGame);
  LConverter := TUdmfFactory.CreateConverter(LGame, TFakeSounds.Create,
    TLogFactory.CreateLog(TArray<ILogSink>.Create(FSink), nil));
  LMap := LConverter.Convert(ReadText(ASample));
  LActual := LMap.GetLumps('MAP01', nil, nil);
  LExpected := ReadLumps(DataPath(LBase + '.wad'));

  Assert.AreEqual(Length(LExpected), Length(LActual), 'the number of lumps of ' + LBase);
  for LIndex := 0 to High(LExpected) do
  begin
    Assert.AreEqual(LExpected[LIndex].Name, LActual[LIndex].Name,
      'the name of the lump ' + IntToStr(LIndex));
    if LActual[LIndex].Name = MLN_NSPACE then
      Continue;
    Assert.AreEqual(Length(LExpected[LIndex].Data), Length(LActual[LIndex].Data),
      'the size of ' + LActual[LIndex].Name + ' in ' + LBase);
    if Length(LExpected[LIndex].Data) > 0 then
      Assert.IsTrue(CompareMem(@LExpected[LIndex].Data[0], @LActual[LIndex].Data[0],
        Length(LExpected[LIndex].Data)), 'the bytes of ' + LActual[LIndex].Name + ' in ' + LBase);
  end;

  LGoldenWarnings := GoldenWarnings(DataPath(LBase + '.wad.txt'));
  LOurWarnings := WarningsOf(FRecorder.TextOf(TLogChannel.ErrorFile));
  Assert.AreEqual(Length(LGoldenWarnings), Length(LOurWarnings),
    'the number of warnings of ' + LBase);
  for LWarning := 0 to High(LGoldenWarnings) do
    Assert.AreEqual(LGoldenWarnings[LWarning], LOurWarnings[LWarning]);
end;

end.
