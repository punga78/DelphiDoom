{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TRadixLumpGroupPart                                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Radix.LumpGroupPart;

interface

uses
  System.SysUtils, DUnitX.TestFramework,
  DelphiDoom.GameData.Intf, DelphiDoom.Radix.Context, DelphiDoom.Radix.LumpGroupPart,
  DelphiDoom.Tests.Radix.DatBuilder;

type
  [TestFixture]
  [Category('radix')]
  TTestRadixLumpGroupPart = class(TObject)
  strict private
    FBuilder: TRadixDatBuilder;
    FWad: IGameWadComposer;
    FAliases: TArray<string>;
    procedure Run(const APart: IRadixPart);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeCopiareLaMusicaDellIntroEQuellaDeiLivelli;
    [Test]
    procedure DovrebbeNonCopiareLaMusicaSenzaLIntro;
    [Test]
    procedure DovrebbeNonDareUnAliasAUnModuloMusicale;
    [Test]
    procedure DovrebbeCopiareITestiDelleMissioniConUnAlias;
    [Test]
    procedure DovrebbeCopiareIBriefingNellOrdineDegliEpisodi;
    [Test]
    procedure DovrebbeCopiareITestiDiFineEpisodio;
    [Test]
    procedure DovrebbeSaltareUnTestoCheNonCe;
  end;

implementation

{ TTestRadixLumpGroupPart }

procedure TTestRadixLumpGroupPart.Setup;
begin
  FBuilder := TRadixDatBuilder.Create;
end;

procedure TTestRadixLumpGroupPart.TearDown;
begin
  FBuilder.Free;
end;

procedure TTestRadixLumpGroupPart.Run(const APart: IRadixPart);
begin
  FWad := TRadixPartRunner.Run(APart, FBuilder.ToBytes, nil, FAliases);
end;

procedure TTestRadixLumpGroupPart.DovrebbeCopiareLaMusicaDellIntroEQuellaDeiLivelli;
begin
  FBuilder.Add('IntroMusic', [1, 2]);
  FBuilder.Add('MusicModule[1][2]', [3]);
  FBuilder.Add('MusicModule[3][9]', [4, 4, 4]);
  Run(TRadixLumpGroupPart.Music);
  Assert.AreEqual(3, FWad.Count);
  Assert.AreEqual('D_INTRO', FWad.LumpNames[0]);
  Assert.AreEqual('D_E1M2', FWad.LumpNames[1]);
  Assert.AreEqual('D_E3M9', FWad.LumpNames[2]);
  Assert.AreEqual<TBytes>([4, 4, 4], FWad.LumpData[2]);
end;

procedure TTestRadixLumpGroupPart.DovrebbeNonCopiareLaMusicaSenzaLIntro;
begin
  FBuilder.Add('MusicModule[1][1]', [3]);
  Run(TRadixLumpGroupPart.Music);
  Assert.AreEqual(0, FWad.Count);
end;

procedure TTestRadixLumpGroupPart.DovrebbeNonDareUnAliasAUnModuloMusicale;
begin
  FBuilder.Add('IntroMusic', [1]);
  Run(TRadixLumpGroupPart.Music);
  Assert.AreEqual<Integer>(0, Length(FAliases));
end;

procedure TTestRadixLumpGroupPart.DovrebbeCopiareITestiDelleMissioniConUnAlias;
begin
  FBuilder.Add('MissionText[2][5]', TEncoding.ANSI.GetBytes('Go'));
  Run(TRadixLumpGroupPart.MissionText);
  Assert.AreEqual('MNTEXT25', FWad.LumpNames[0]);
  Assert.AreEqual('MNTEXT25=MissionText[2][5]', FAliases[0]);
end;

procedure TTestRadixLumpGroupPart.DovrebbeCopiareIBriefingNellOrdineDegliEpisodi;
begin
  FBuilder.Add('MissionBrief[2][1]', [1]);
  FBuilder.Add('MissionBrief[1][9]', [2]);
  Run(TRadixLumpGroupPart.MissionBriefing);
  // the order is the one of the episodes and the missions, not the one of the container
  Assert.AreEqual('BRIEF_19', FWad.LumpNames[0]);
  Assert.AreEqual('BRIEF_21', FWad.LumpNames[1]);
end;

procedure TTestRadixLumpGroupPart.DovrebbeCopiareITestiDiFineEpisodio;
begin
  FBuilder.Add('EndEpisode3Text', [7]);
  Run(TRadixLumpGroupPart.EndText);
  Assert.AreEqual('C3TEXT', FWad.LumpNames[0]);
  Assert.AreEqual('C3TEXT=EndEpisode3Text', FAliases[0]);
end;

procedure TTestRadixLumpGroupPart.DovrebbeSaltareUnTestoCheNonCe;
begin
  Run(TRadixLumpGroupPart.EndText);
  Assert.AreEqual(0, FWad.Count);
  Assert.AreEqual<Integer>(0, Length(FAliases));
end;

end.
