{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TRadixLevelPart                                        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Radix.LevelPart;

interface

uses
  System.SysUtils, DUnitX.TestFramework,
  DelphiDoom.GameData.Intf, DelphiDoom.Radix.Level.Types, DelphiDoom.Tests.Radix.LevelBuilder,
  DelphiDoom.Tests.Radix.DatBuilder;

type
  [TestFixture]
  [Category('radix')]
  TTestRadixLevelPart = class(TObject)
  strict private
    FBuilder: TRadixLevelBuilder;
    FDat: TRadixDatBuilder;
    FMarks: TArray<Boolean>;
    function Run(AExtraInfo: Boolean = True): IGameWadComposer;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeFareLaMappaDiOgniLivelloCheCe;
    [Test]
    procedure DovrebbeNonFareNullaSenzaLivelli;
    [Test]
    procedure DovrebbeIgnorareUnLumpCheNonEUnLivello;
    [Test]
    procedure DovrebbeMarcareLeFlatCheISettoriUsano;
    [Test]
    procedure DovrebbeSaltareLeInformazioniExtraNelleMappeSemplici;
  end;

implementation

uses
  DelphiDoom.GameData.Factory, DelphiDoom.GameData.Types, DelphiDoom.Radix.Context, DelphiDoom.Radix.Factory,
  DelphiDoom.Radix.Level.Factory;

{ TTestRadixLevelPart }

procedure TTestRadixLevelPart.Setup;
begin
  FBuilder := TRadixLevelBuilder.Create;
  FBuilder.AddSector(0, 128, 2, 3, 10, 0);
  FBuilder.AddWall(33000, 100, 33100, 100, 0, -1, RWF_SINGLESIDED);
  FDat := TRadixDatBuilder.Create;
end;

procedure TTestRadixLevelPart.TearDown;
begin
  FDat.Free;
  FBuilder.Free;
end;

function TTestRadixLevelPart.Run(AExtraInfo: Boolean): IGameWadComposer;
var
  LContext: TRadixTranslationContext;
begin
  Result := TGameDataFactory.CreateWadComposer;
  LContext := TRadixTranslationContext.Create(TRadixFactory.OpenContainerBytes(FDat.ToBytes), Result,
    TGameDataFactory.CreatePatchBuilder(TGamePatchOptions.Radix));
  try
    LContext.SetTextureSlots(10);
    TRadixLevelFactory.CreatePart(AExtraInfo).Build(LContext);
    FMarks := Copy(LContext.MarkFlats);
  finally
    LContext.Free;
  end;
end;

procedure TTestRadixLevelPart.DovrebbeFareLaMappaDiOgniLivelloCheCe;
var
  LWad: IGameWadComposer;
begin
  FDat.Add('WorldData[1][2]', FBuilder.ToBytes);
  FDat.Add('WorldData[3][9]', FBuilder.ToBytes);
  LWad := Run;
  Assert.AreEqual(34, LWad.Count);
  Assert.AreEqual('E1M2', LWad.LumpNames[0]);
  Assert.AreEqual('E3M9', LWad.LumpNames[17]);
end;

procedure TTestRadixLevelPart.DovrebbeNonFareNullaSenzaLivelli;
begin
  FDat.Add('Other', [1, 2, 3]);
  Assert.AreEqual(0, Run.Count);
end;

procedure TTestRadixLevelPart.DovrebbeIgnorareUnLumpCheNonEUnLivello;
var
  LWad: IGameWadComposer;
begin
  FDat.Add('WorldData[1][1]', FBuilder.ToBytes);
  FDat.Add('WorldData[1][2]', TRadixDatBuilder.Pattern(300, 1));
  LWad := Run;
  Assert.AreEqual(17, LWad.Count);
  Assert.AreEqual('E1M1', LWad.LumpNames[0]);
end;

procedure TTestRadixLevelPart.DovrebbeMarcareLeFlatCheISettoriUsano;
begin
  FDat.Add('WorldData[1][1]', FBuilder.ToBytes);
  Run;
  Assert.AreEqual<Integer>(10, Length(FMarks));
  Assert.IsTrue(FMarks[3]);
  Assert.IsTrue(FMarks[4]);
  Assert.IsFalse(FMarks[1]);
  Assert.IsFalse(FMarks[5]);
end;

procedure TTestRadixLevelPart.DovrebbeSaltareLeInformazioniExtraNelleMappeSemplici;
begin
  FDat.Add('WorldData[2][3]', FBuilder.ToBytes);
  Assert.AreEqual(11, Run(False).Count);
end;

end.
