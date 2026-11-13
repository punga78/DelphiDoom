{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TRadixSpritePart                                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Radix.SpritePart;

interface

uses
  System.SysUtils, DUnitX.TestFramework,
  DelphiDoom.GameData.Intf, DelphiDoom.Radix.SpriteList, DelphiDoom.Radix.SpritePart,
  DelphiDoom.Tests.Radix.DatBuilder;

type
  [TestFixture]
  [Category('radix')]
  TTestRadixSpritePart = class(TObject)
  strict private
    FWad: IGameWadComposer;
    FAliases: TArray<string>;
    /// <summary>A container whose ObjectBitmaps has bitmaps of 4 x 3 with these names</summary>
    function BuildContainer(const ANames: array of string): TBytes;
    procedure Run(const ANames: array of string; const AFill: TRadixSpriteFill);
    function ReadWord(const ABytes: TBytes; AOffset: Integer): Integer;
  public
    [Test]
    procedure DovrebbeNonFareNullaSeMancaObjectBitmaps;
    [Test]
    procedure DovrebbeRacchiudereGliSpriteTraSStartESEnd;
    [Test]
    procedure DovrebbeScrivereSubitoDopoSStartLaPatchGear1A0;
    [Test]
    procedure DovrebbeFareLaPatchDellaBitmapDellaVoce;
    [Test]
    procedure DovrebbeUsareGliOffsetDellaVoce;
    [Test]
    procedure DovrebbeCentrareLaPatchSeLaVoceLoChiede;
    [Test]
    procedure DovrebbeScrivereLeColonneDellaBitmapPerIlVerso;
    [Test]
    procedure DovrebbeScrivereLaPatchVuotaSeLaBitmapNonCE;
    [Test]
    procedure DovrebbeNonScrivereLAliasPerUnaBitmapCheNonCE;
    [Test]
    procedure DovrebbeScrivereLAliasDelloSprite;
    [Test]
    procedure DovrebbeCercareLaBitmapSenzaIlTrattinoBasso;
    [Test]
    procedure DovrebbeScrivereNellAliasIlNomeTrovato;
    [Test]
    procedure DovrebbeSaltareLoSpriteXR63A7;
    [Test]
    procedure DovrebbeRinominareXR63A3ComeLoSpecchio;
    [Test]
    procedure DovrebbeRinominareLeTreBitmapDuplicateDiSecondCoolant;
    [Test]
    procedure DovrebbeNumerareLaPrimaDelleDueBitmapSplashDuplicate;
    [Test]
    procedure DovrebbeScrivereSempreLAliasDelloUovo;
    [Test]
    procedure DovrebbeTagliareXR30K0A63Per62;
    [Test]
    procedure DovrebbeTagliareXR64A4A96DiAltezza;
    [Test]
    procedure DovrebbeRifiutareUnaListaNulla;
  end;

implementation

uses
  DelphiDoom.Radix.Things;

const
  BitmapWidth = 4;
  BitmapHeight = 3;

{ TTestRadixSpritePart }

function TTestRadixSpritePart.BuildContainer(const ANames: array of string): TBytes;
var
  LBuilder: TRadixDatBuilder;
  LRecords: TBytes;
  LPositions: TArray<Integer>;
  LData: TBytes;
  LIndex: Integer;
  LColumn: Integer;
  LRow: Integer;
  LName: AnsiString;
  LTable: Integer;
  LHead: TBytes;
  LOffset: Integer;
begin
  LBuilder := TRadixDatBuilder.Create;
  try
    SetLength(LPositions, Length(ANames));
    for LIndex := 0 to High(ANames) do
    begin
      // the table of the columns (offset, start, size), then the pixels of each column
      SetLength(LData, BitmapWidth * 4 + BitmapWidth * BitmapHeight);
      for LColumn := 0 to BitmapWidth - 1 do
      begin
        LOffset := BitmapWidth * 4 + LColumn * BitmapHeight;
        LData[LColumn * 4] := LOffset and $FF;
        LData[LColumn * 4 + 1] := LOffset shr 8;
        LData[LColumn * 4 + 2] := 0;
        LData[LColumn * 4 + 3] := BitmapHeight;
        for LRow := 0 to BitmapHeight - 1 do
          LData[LOffset + LRow] := LColumn * BitmapHeight + LRow + 1;
      end;
      LPositions[LIndex] := LBuilder.Add('bmp' + IntToStr(LIndex), LData);
    end;
    SetLength(LRecords, Length(ANames) * 40);
    FillChar(LRecords[0], Length(LRecords), 0);
    for LIndex := 0 to High(ANames) do
    begin
      LName := AnsiString(ANames[LIndex]);
      Move(LName[1], LRecords[LIndex * 40], Length(LName));
      Move(LPositions[LIndex], LRecords[LIndex * 40 + 32], 4);
      LRecords[LIndex * 40 + 36] := BitmapHeight;
      LRecords[LIndex * 40 + 38] := BitmapWidth;
    end;
    LTable := LBuilder.Add('BitmapRecords', LRecords);
    SetLength(LHead, 6);
    LHead[0] := Length(ANames);
    Move(LTable, LHead[2], 4);
    LBuilder.Add('ObjectBitmaps', LHead);
    Result := LBuilder.ToBytes;
  finally
    LBuilder.Free;
  end;
end;

procedure TTestRadixSpritePart.Run(const ANames: array of string; const AFill: TRadixSpriteFill);
begin
  FWad := TRadixPartRunner.Run(TRadixSpritePart.Create(AFill), BuildContainer(ANames), nil,
    FAliases);
end;

function TTestRadixSpritePart.ReadWord(const ABytes: TBytes; AOffset: Integer): Integer;
begin
  Result := PSmallInt(@ABytes[AOffset])^;
end;

procedure TTestRadixSpritePart.DovrebbeNonFareNullaSeMancaObjectBitmaps;
var
  LBuilder: TRadixDatBuilder;
begin
  LBuilder := TRadixDatBuilder.Create;
  try
    LBuilder.Add('Other', TRadixDatBuilder.Pattern(10, 1));
    FWad := TRadixPartRunner.Run(TRadixSpritePart.Create(
      procedure(const AList: TRadixSpriteList)
      begin
        AList.AddOne('Thing', 0);
      end), LBuilder.ToBytes, nil, FAliases);
  finally
    LBuilder.Free;
  end;
  Assert.AreEqual(0, FWad.Count);
  Assert.AreEqual<Integer>(0, Length(FAliases));
end;

procedure TTestRadixSpritePart.DovrebbeRacchiudereGliSpriteTraSStartESEnd;
begin
  Run(['Thing'],
    procedure(const AList: TRadixSpriteList)
    begin
      AList.AddOne('Thing', 0);
    end);
  Assert.AreEqual('S_START', FWad.LumpNames[0]);
  Assert.AreEqual('S_END', FWad.LumpNames[FWad.Count - 1]);
  Assert.AreEqual('XR00A0', FWad.LumpNames[FWad.Count - 2]);
end;

procedure TTestRadixSpritePart.DovrebbeScrivereSubitoDopoSStartLaPatchGear1A0;
begin
  Run(['Thing'],
    procedure(const AList: TRadixSpriteList)
    begin
    end);
  Assert.AreEqual(3, FWad.Count);
  Assert.AreEqual('GEAR1A0', FWad.LumpNames[1]);
  Assert.AreEqual<Integer>(2913, Length(FWad.LumpData[1]));
end;

procedure TTestRadixSpritePart.DovrebbeFareLaPatchDellaBitmapDellaVoce;
var
  LPatch: TBytes;
begin
  Run(['Thing'],
    procedure(const AList: TRadixSpriteList)
    begin
      AList.AddOne('Thing', 0);
    end);
  LPatch := FWad.LumpData[FWad.IndexOf('XR00A0')];
  Assert.AreEqual(BitmapWidth, ReadWord(LPatch, 0));
  Assert.AreEqual(BitmapHeight, ReadWord(LPatch, 2));
end;

procedure TTestRadixSpritePart.DovrebbeUsareGliOffsetDellaVoce;
var
  LPatch: TBytes;
begin
  Run(['Thing'],
    procedure(const AList: TRadixSpriteList)
    begin
      AList.AddOne('Thing', 0, 2, 3, False, False);
    end);
  LPatch := FWad.LumpData[FWad.IndexOf('XR00A0')];
  Assert.AreEqual(2, ReadWord(LPatch, 4));
  Assert.AreEqual(3, ReadWord(LPatch, 6));
end;

procedure TTestRadixSpritePart.DovrebbeCentrareLaPatchSeLaVoceLoChiede;
var
  LPatch: TBytes;
begin
  Run(['Thing'],
    procedure(const AList: TRadixSpriteList)
    begin
      AList.AddOne('Thing', 0, -255, -255, True, False);
    end);
  LPatch := FWad.LumpData[FWad.IndexOf('XR00A0')];
  Assert.AreEqual(BitmapWidth div 2, ReadWord(LPatch, 4));
  Assert.AreEqual(BitmapHeight div 2, ReadWord(LPatch, 6));
end;

procedure TTestRadixSpritePart.DovrebbeScrivereLeColonneDellaBitmapPerIlVerso;
var
  LPatch: TBytes;
  LColumn: Integer;
begin
  Run(['Thing'],
    procedure(const AList: TRadixSpriteList)
    begin
      AList.AddOne('Thing', 0);
    end);
  LPatch := FWad.LumpData[FWad.IndexOf('XR00A0')];
  // the first column: a post (top, length, a byte, the pixels), the pixels are 1, 2, 3
  LColumn := PInteger(@LPatch[8])^;
  Assert.AreEqual(3, Integer(LPatch[LColumn + 1]));
  Assert.AreEqual(1, Integer(LPatch[LColumn + 3]));
  Assert.AreEqual(3, Integer(LPatch[LColumn + 5]));
  // the second one starts with 4
  LColumn := PInteger(@LPatch[12])^;
  Assert.AreEqual(4, Integer(LPatch[LColumn + 3]));
end;

procedure TTestRadixSpritePart.DovrebbeScrivereLaPatchVuotaSeLaBitmapNonCE;
var
  LPatch: TBytes;
begin
  Run(['Thing'],
    procedure(const AList: TRadixSpriteList)
    begin
      AList.AddOne('Missing', 0);
    end);
  LPatch := FWad.LumpData[FWad.IndexOf('XR00A0')];
  // TNT1A0: 16 x 16, 88 bytes
  Assert.AreEqual<Integer>(88, Length(LPatch));
  Assert.AreEqual(16, ReadWord(LPatch, 0));
end;

procedure TTestRadixSpritePart.DovrebbeNonScrivereLAliasPerUnaBitmapCheNonCE;
begin
  Run(['Thing'],
    procedure(const AList: TRadixSpriteList)
    begin
      AList.AddOne('Missing', 1);
    end);
  Assert.AreEqual<Integer>(1, Length(FAliases));
  Assert.AreEqual('XR61A0=EG1', FAliases[0]);
end;

procedure TTestRadixSpritePart.DovrebbeScrivereLAliasDelloSprite;
begin
  Run(['Thing'],
    procedure(const AList: TRadixSpriteList)
    begin
      AList.AddOne('Thing', 2);
    end);
  Assert.AreEqual('XR02A0=Thing', FAliases[0]);
end;

procedure TTestRadixSpritePart.DovrebbeCercareLaBitmapSenzaIlTrattinoBasso;
var
  LPatch: TBytes;
begin
  Run(['Fire1'],
    procedure(const AList: TRadixSpriteList)
    begin
      AList.AddNonRotating('Fire', 0, 1);
    end);
  LPatch := FWad.LumpData[FWad.IndexOf('XR00A0')];
  Assert.AreEqual(BitmapWidth, ReadWord(LPatch, 0));
end;

procedure TTestRadixSpritePart.DovrebbeScrivereNellAliasIlNomeTrovato;
begin
  Run(['Fire1'],
    procedure(const AList: TRadixSpriteList)
    begin
      AList.AddNonRotating('Fire', 0, 1);
    end);
  // the alias has the name that was found
  Assert.AreEqual('XR00A0=Fire1', FAliases[0]);
end;

procedure TTestRadixSpritePart.DovrebbeSaltareLoSpriteXR63A7;
begin
  Run(['Thing'],
    procedure(const AList: TRadixSpriteList)
    begin
      AList.AddOne('Thing', MTRX_DOZZER, -255, -255, True, True, 'A', '7');
    end);
  Assert.AreEqual(-1, FWad.IndexOf('XR63A7'));
end;

procedure TTestRadixSpritePart.DovrebbeRinominareXR63A3ComeLoSpecchio;
var
  LPatch: TBytes;
begin
  Run(['Thing'],
    procedure(const AList: TRadixSpriteList)
    begin
      AList.AddOne('Thing', MTRX_DOZZER, 5, 6, False, False, 'A', '3');
    end);
  Assert.AreEqual(-1, FWad.IndexOf('XR63A3'));
  LPatch := FWad.LumpData[FWad.IndexOf('XR63A3A7')];
  Assert.AreEqual(5, ReadWord(LPatch, 4));
  Assert.AreEqual(77, ReadWord(LPatch, 6));
  Assert.AreEqual('XR63A3A7=Thing', FAliases[0]);
end;

procedure TTestRadixSpritePart.DovrebbeRinominareLeTreBitmapDuplicateDiSecondCoolant;
begin
  Run(['SecondCoolant1', 'SecondCoolant1', 'SecondCoolant1'],
    procedure(const AList: TRadixSpriteList)
    begin
      AList.AddNonRotating('SecondCoolant', MTRX_SECONDCOOLAND1, 3);
    end);
  Assert.AreEqual('XR44A0=SecondCoolant1', FAliases[0]);
  Assert.AreEqual('XR44B0=SecondCoolant2', FAliases[1]);
  Assert.AreEqual('XR44C0=SecondCoolant3', FAliases[2]);
end;

procedure TTestRadixSpritePart.DovrebbeNumerareLaPrimaDelleDueBitmapSplashDuplicate;
begin
  Run(['WaterSplash1', 'WaterSplash1', 'MudSplash2', 'MudSplash2'],
    procedure(const AList: TRadixSpriteList)
    begin
      AList.AddOne('WaterSplash7', MTTX_RADIXWATERSPLASH);
      AList.AddOne('WaterSplash1', MTTX_RADIXWATERSPLASH, -255, -255, True, True, 'B');
      AList.AddOne('MudSplash8', MTTX_RADIXMUDSPLASH);
    end);
  // the first WaterSplash1 became WaterSplash7, the second stayed
  Assert.AreEqual('X091A0=WaterSplash7', FAliases[0]);
  Assert.AreEqual('X091B0=WaterSplash1', FAliases[1]);
  Assert.AreEqual('X092A0=MudSplash8', FAliases[2]);
end;

procedure TTestRadixSpritePart.DovrebbeScrivereSempreLAliasDelloUovo;
begin
  Run([],
    procedure(const AList: TRadixSpriteList)
    begin
    end);
  Assert.AreEqual<Integer>(1, Length(FAliases));
  Assert.AreEqual('XR61A0=EG1', FAliases[0]);
end;

procedure TTestRadixSpritePart.DovrebbeTagliareXR30K0A63Per62;
var
  LPatch: TBytes;
begin
  Run(['Thing'],
    procedure(const AList: TRadixSpriteList)
    begin
      AList.AddOne('Thing', MTRX_ALIENFODDER, -255, -255, True, True, 'K', '0');
    end);
  LPatch := FWad.LumpData[FWad.IndexOf('XR30K0')];
  Assert.AreEqual(63, ReadWord(LPatch, 0));
  Assert.AreEqual(62, ReadWord(LPatch, 2));
end;

procedure TTestRadixSpritePart.DovrebbeTagliareXR64A4A96DiAltezza;
var
  LPatch: TBytes;
begin
  Run(['Thing'],
    procedure(const AList: TRadixSpriteList)
    begin
      AList.AddOne('Thing', MTRX_LIFT, -255, -255, True, True, 'A', '4');
    end);
  LPatch := FWad.LumpData[FWad.IndexOf('XR64A4')];
  Assert.AreEqual(BitmapWidth, ReadWord(LPatch, 0));
  Assert.AreEqual(96, ReadWord(LPatch, 2));
end;

procedure TTestRadixSpritePart.DovrebbeRifiutareUnaListaNulla;
begin
  Assert.WillRaise(
    procedure
    begin
      TRadixSpritePart.Create(nil);
    end, EArgumentNilException);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestRadixSpritePart);

end.
