{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the actors, the picture aliases and the sprites of     }
{  the cars of Speed Haste                                                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Speed.ActorDefinitions;

interface

uses
  System.SysUtils, System.IOUtils, DUnitX.TestFramework, DelphiDoom.GameData.Intf;

type
  [TestFixture]
  [Category('speed')]
  TTestSpeedActorDefinitions = class(TObject)
  public
    [Test]
    procedure DovrebbeDefinireLAutoComeIlTipo241;
    [Test]
    procedure DovrebbeDareUnoStatoPerOgniAuto;
    [Test]
    procedure DovrebbeUsareLoSpriteTNT1SenzaImmagini;
    [Test]
    procedure DovrebbeUsareGliSpriteDelleAutoConLaScala;
    [Test]
    procedure DovrebbeUsareTNT1PerLeAutoSenzaImmagine;
    [Test]
    procedure DovrebbeDefinireLaPartenzaELaTelecamera;
    [Test]
    procedure DovrebbeRifiutareUnNumeroDiNomiSbagliato;
    [Test]
    procedure DovrebbeRifiutareUnNomeDiSpriteNonDiQuattroCaratteri;
  end;

  [TestFixture]
  [Category('speed')]
  TTestSpeedDoomPictureAliases = class(TObject)
  strict private
    FWad: IGameWadComposer;
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure DovrebbeDareIlTitoloEIlPausaDelGioco;
    [Test]
    procedure NonDovrebbeToccareUnNomeCheEsisteGia;
    [Test]
    procedure NonDovrebbeFareNienteSenzaLeImmaginiDelGioco;
    [Test]
    procedure DovrebbeRifiutareUnWadNil;
  end;

  [TestFixture]
  [Category('speed')]
  TTestSpeedCarSpriteBuilder = class(TObject)
  strict private
    function FindShareware: string;
  public
    [Test]
    procedure DovrebbeRifiutareGliOggettiNil;
    [Test]
    procedure NonDovrebbeDisegnareNienteSenzaPaletta;
    [Test]
    procedure DovrebbeFareICinqueLumpDiOgniAutoDelloShareware;
  end;

implementation

uses
  DelphiDoom.GameData.Factory, DelphiDoom.Models.I3d.Intf, DelphiDoom.Racing.Types,
  DelphiDoom.Speed.ActorDefinitions, DelphiDoom.Speed.DoomPictureAliases, DelphiDoom.Speed.CarSpriteBuilder,
  DelphiDoom.Speed.Intf, DelphiDoom.Speed.Factory, DelphiDoom.Tests.Speed.Fakes, DelphiDoom.Tests.Speed.JclBuilder;

function CountOf(const AText, ASubText: string): Integer;
var
  LPosition: Integer;
begin
  Result := 0;
  LPosition := Pos(ASubText, AText);
  while LPosition > 0 do
  begin
    Inc(Result);
    LPosition := Pos(ASubText, AText, LPosition + Length(ASubText));
  end;
end;

function FortyNames: TArray<string>;
var
  LIndex: Integer;
begin
  SetLength(Result, RACING_CAR_COUNT);
  for LIndex := 0 to High(Result) do
    Result[LIndex] := Format('CR%.2d', [LIndex]);
end;

{ TTestSpeedActorDefinitions }

procedure TTestSpeedActorDefinitions.DovrebbeDefinireLAutoComeIlTipo241;
begin
  Assert.IsTrue(Pos('ACTOR SpeedCar 241', TSpeedActorDefinitions.Build(nil)) > 0);
end;

procedure TTestSpeedActorDefinitions.DovrebbeDareUnoStatoPerOgniAuto;
var
  LText: string;
begin
  LText := TSpeedActorDefinitions.Build(FortyNames);
  Assert.AreEqual(RACING_CAR_COUNT, CountOf(LText, ' A -1'#13#10) - 2, 'uno per auto piu i due attori fermi');
  Assert.IsTrue(Pos('    CR00 A -1', LText) < Pos('    CR39 A -1', LText), 'nell ordine della tabella');
end;

procedure TTestSpeedActorDefinitions.DovrebbeUsareLoSpriteTNT1SenzaImmagini;
var
  LText: string;
begin
  LText := TSpeedActorDefinitions.Build(nil);
  Assert.AreEqual(RACING_CAR_COUNT + 2, CountOf(LText, 'TNT1 A -1'));
  Assert.AreEqual(0, Pos('Scale', LText));
end;

procedure TTestSpeedActorDefinitions.DovrebbeUsareGliSpriteDelleAutoConLaScala;
var
  LText: string;
begin
  LText := TSpeedActorDefinitions.Build(FortyNames);
  Assert.IsTrue(Pos('Scale 0.5', LText) > 0);
  Assert.AreEqual(2, CountOf(LText, 'TNT1 A -1'), 'solo gli attori che non si vedono');
end;

procedure TTestSpeedActorDefinitions.DovrebbeUsareTNT1PerLeAutoSenzaImmagine;
var
  LNames: TArray<string>;
  LText: string;
begin
  LNames := FortyNames;
  LNames[5] := '';
  LText := TSpeedActorDefinitions.Build(LNames);
  Assert.AreEqual(3, CountOf(LText, 'TNT1 A -1'));
  Assert.AreEqual(0, Pos('CR05', LText));
end;

procedure TTestSpeedActorDefinitions.DovrebbeDefinireLaPartenzaELaTelecamera;
var
  LText: string;
begin
  LText := TSpeedActorDefinitions.Build(nil);
  Assert.IsTrue(Pos('ACTOR SpeedRaceStart 500', LText) > 0);
  Assert.IsTrue(Pos('ACTOR SpeedCamera 242', LText) > 0);
end;

procedure TTestSpeedActorDefinitions.DovrebbeRifiutareUnNumeroDiNomiSbagliato;
begin
  Assert.WillRaise(
    procedure
    begin
      TSpeedActorDefinitions.Build(['CR00', 'CR01']);
    end, EArgumentException);
end;

procedure TTestSpeedActorDefinitions.DovrebbeRifiutareUnNomeDiSpriteNonDiQuattroCaratteri;
var
  LNames: TArray<string>;
begin
  LNames := FortyNames;
  LNames[3] := 'CAR3X';
  Assert.WillRaise(
    procedure
    begin
      TSpeedActorDefinitions.Build(LNames);
    end, EArgumentException);
end;

{ TTestSpeedDoomPictureAliases }

procedure TTestSpeedDoomPictureAliases.Setup;
begin
  FWad := TGameDataFactory.CreateWadComposer;
end;

procedure TTestSpeedDoomPictureAliases.DovrebbeDareIlTitoloEIlPausaDelGioco;
begin
  FWad.AddLump('DEMOLOGO', TBytes.Create(1, 2, 3));
  FWad.AddLump('PAUSE', TBytes.Create(4, 5));
  Assert.AreEqual(2, TSpeedDoomPictureAliases.Append(FWad));
  Assert.AreEqual<Integer>(3, Length(FWad.LumpData[FWad.IndexOf('TITLEPIC')]));
  Assert.AreEqual<Integer>(2, Length(FWad.LumpData[FWad.IndexOf('M_PAUSE')]));
end;

procedure TTestSpeedDoomPictureAliases.NonDovrebbeToccareUnNomeCheEsisteGia;
begin
  FWad.AddLump('DEMOLOGO', TBytes.Create(1, 2, 3));
  FWad.AddLump('TITLEPIC', TBytes.Create(9));
  Assert.AreEqual(0, TSpeedDoomPictureAliases.Append(FWad));
  Assert.AreEqual<Integer>(1, Length(FWad.LumpData[FWad.IndexOf('TITLEPIC')]));
end;

procedure TTestSpeedDoomPictureAliases.NonDovrebbeFareNienteSenzaLeImmaginiDelGioco;
begin
  Assert.AreEqual(0, TSpeedDoomPictureAliases.Append(FWad));
  Assert.AreEqual(0, FWad.Count);
end;

procedure TTestSpeedDoomPictureAliases.DovrebbeRifiutareUnWadNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TSpeedDoomPictureAliases.Append(nil);
    end, EArgumentNilException);
end;

{ TTestSpeedCarSpriteBuilder }

function TTestSpeedCarSpriteBuilder.FindShareware: string;
var
  LRoot: string;
  LCandidates: TArray<string>;
  LCandidate: string;
begin
  LRoot := TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)), '..\..\..\..'));
  LCandidates := [TPath.Combine(LRoot, 'bin\Speed\SPEEDH.JCL'), TPath.Combine(LRoot, 'Reference\_dati\speed\SPEEDH.JCL'),
    TPath.GetFullPath(TPath.Combine(LRoot, '..\..\..\Reference\_dati\speed\SPEEDH.JCL'))];
  for LCandidate in LCandidates do
    if TFile.Exists(LCandidate) then
      Exit(LCandidate);
  Result := '';
end;

procedure TTestSpeedCarSpriteBuilder.DovrebbeRifiutareGliOggettiNil;
var
  LBuilder: TSpeedCarSpriteBuilder;
begin
  LBuilder := TSpeedFactory.CreateCarSpriteBuilder;
  try
    Assert.WillRaise(
      procedure
      begin
        LBuilder.Build(nil, TGameDataFactory.CreateWadComposer);
      end, EArgumentNilException);
    Assert.WillRaise(
      procedure
      begin
        LBuilder.Build(TSpeedFactory.OpenContainerBytes(TJclBuilder.SyntheticGame), nil);
      end, EArgumentNilException);
  finally
    LBuilder.Free;
  end;
end;

procedure TTestSpeedCarSpriteBuilder.NonDovrebbeDisegnareNienteSenzaPaletta;
var
  LBuilder: TSpeedCarSpriteBuilder;
  LWad: IGameWadComposer;
  LNames: TArray<string>;
  LPath: string;
begin
  LPath := FindShareware;
  if LPath = '' then
  begin
    Assert.Pass('SPEEDH.JCL is not there');
    Exit;
  end;
  LBuilder := TSpeedFactory.CreateCarSpriteBuilder;
  try
    LWad := TGameDataFactory.CreateWadComposer;
    LNames := LBuilder.Build(TSpeedFactory.OpenContainer(LPath), LWad);
    Assert.AreEqual(RACING_CAR_COUNT, Length(LNames));
    Assert.AreEqual('', LNames[0]);
    Assert.AreEqual(0, LWad.Count, 'nessun lump senza PLAYPAL e COLORMAP');
  finally
    LBuilder.Free;
  end;
end;

procedure TTestSpeedCarSpriteBuilder.DovrebbeFareICinqueLumpDiOgniAutoDelloShareware;
var
  LBuilder: TSpeedCarSpriteBuilder;
  LWad: IGameWadComposer;
  LContainer: ISpeedContainer;
  LNames: TArray<string>;
  LPath, LName: string;
  LCount, LIndex: Integer;
begin
  LPath := FindShareware;
  if LPath = '' then
  begin
    Assert.Pass('SPEEDH.JCL is not there');
    Exit;
  end;
  LContainer := TSpeedFactory.OpenContainer(LPath);
  LWad := TGameDataFactory.CreateWadComposer;
  TSpeedFactory.CreateTranslator(TFakeLog.Create).Translate(LContainer, LWad);
  LBuilder := TSpeedFactory.CreateCarSpriteBuilder;
  try
    LNames := LBuilder.Build(LContainer, LWad);
  finally
    LBuilder.Free;
  end;
  LCount := 0;
  for LName in LNames do
    if LName <> '' then
      Inc(LCount);
  Assert.IsTrue(LCount > 0, 'nessuna auto disegnata');
  for LIndex := 0 to High(LNames) do
    if LNames[LIndex] <> '' then
    begin
      Assert.IsTrue(LWad.IndexOf(LNames[LIndex] + 'A1') >= 0);
      Assert.IsTrue(LWad.IndexOf(LNames[LIndex] + 'A2A8') >= 0);
      Assert.IsTrue(LWad.IndexOf(LNames[LIndex] + 'A3A7') >= 0);
      Assert.IsTrue(LWad.IndexOf(LNames[LIndex] + 'A4A6') >= 0);
      Assert.IsTrue(LWad.IndexOf(LNames[LIndex] + 'A5') >= 0);
    end;
  Assert.IsTrue(LWad.IndexOf('S_START') >= 0);
  Assert.IsTrue(LWad.IndexOf('S_END') > LWad.IndexOf('S_START'));
end;

end.
