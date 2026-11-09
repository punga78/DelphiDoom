{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TGameWadComposer                                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.GameData.WadComposer;

interface

uses
  System.SysUtils, DUnitX.TestFramework,
  DelphiDoom.GameData.Intf;

type
  [TestFixture]
  [Category('gamedata')]
  TTestGameDataWadComposer = class(TObject)
  strict private
    FComposer: IGameWadComposer;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeParitireVuoto;
    [Test]
    procedure DovrebbeAggiungereUnLumpEDareIlSuoIndice;
    [Test]
    procedure DovrebbeMettereIlNomeInMaiuscolo;
    [Test]
    procedure DovrebbeAggiungereUnMarcatoreVuoto;
    [Test]
    procedure DovrebbeScrivereIlTestoConUnByteAlCarattere;
    [Test]
    procedure DovrebbeTagliareICaratteriOltre255NelTesto;
    [Test]
    procedure DovrebbeRifiutareUnNomeDiNoveCaratteri;
    [Test]
    procedure DovrebbeRifiutareUnNomeVuoto;
    [Test]
    procedure DovrebbeTrovareUnLumpPerNome;
    [Test]
    procedure DovrebbeDareUnPwadCheLaLibreriaDeiWadSaLeggere;
    [Test]
    procedure DovrebbeRifiutareUnBuilderNil;
  end;

implementation

uses
  DelphiDoom.GameData.Types, DelphiDoom.GameData.WadComposer, DelphiDoom.GameData.Factory,
  DelphiDoom.Wad.Factory, DelphiDoom.Wad.Intf, DelphiDoom.Wad.Types;

{ TTestGameDataWadComposer }

procedure TTestGameDataWadComposer.Setup;
begin
  FComposer := TGameDataFactory.CreateWadComposer;
end;

procedure TTestGameDataWadComposer.TearDown;
begin
  FComposer := nil;
end;

procedure TTestGameDataWadComposer.DovrebbeParitireVuoto;
begin
  Assert.AreEqual(0, FComposer.Count);
end;

procedure TTestGameDataWadComposer.DovrebbeAggiungereUnLumpEDareIlSuoIndice;
begin
  Assert.AreEqual(0, FComposer.AddLump('PLAYPAL', TBytes.Create(1, 2, 3)));
  Assert.AreEqual(1, FComposer.AddLump('COLORMAP', TBytes.Create(4)));
  Assert.AreEqual(2, FComposer.Count);
  Assert.AreEqual('COLORMAP', FComposer.LumpNames[1]);
  Assert.AreEqual<Byte>(3, FComposer.LumpData[0][2]);
end;

procedure TTestGameDataWadComposer.DovrebbeMettereIlNomeInMaiuscolo;
begin
  FComposer.AddLump('wall1', TBytes.Create(1));
  Assert.AreEqual('WALL1', FComposer.LumpNames[0]);
end;

procedure TTestGameDataWadComposer.DovrebbeAggiungereUnMarcatoreVuoto;
begin
  FComposer.AddMarker('S_START');
  Assert.AreEqual(0, Length(FComposer.LumpData[0]));
end;

procedure TTestGameDataWadComposer.DovrebbeScrivereIlTestoConUnByteAlCarattere;
var
  LData: TBytes;
begin
  FComposer.AddText('SNDINFO', 'ab'#13#10);
  LData := FComposer.LumpData[0];
  Assert.AreEqual(4, Length(LData));
  Assert.AreEqual<Byte>(Ord('a'), LData[0]);
  Assert.AreEqual<Byte>(13, LData[2]);
  Assert.AreEqual<Byte>(10, LData[3]);
end;

procedure TTestGameDataWadComposer.DovrebbeTagliareICaratteriOltre255NelTesto;
begin
  FComposer.AddText('TEXT', #$0141);
  Assert.AreEqual<Byte>($41, FComposer.LumpData[0][0]);
end;

procedure TTestGameDataWadComposer.DovrebbeRifiutareUnNomeDiNoveCaratteri;
begin
  Assert.WillRaise(
    procedure
    begin
      FComposer.AddLump('ABCDEFGHI', nil);
    end, EGameDataException);
end;

procedure TTestGameDataWadComposer.DovrebbeRifiutareUnNomeVuoto;
begin
  Assert.WillRaise(
    procedure
    begin
      FComposer.AddMarker('');
    end, EGameDataException);
end;

procedure TTestGameDataWadComposer.DovrebbeTrovareUnLumpPerNome;
begin
  FComposer.AddMarker('F_START');
  FComposer.AddLump('FLAT0001', TBytes.Create(1));
  Assert.AreEqual(1, FComposer.IndexOf('flat0001'));
  Assert.AreEqual(-1, FComposer.IndexOf('NOPE'));
end;

procedure TTestGameDataWadComposer.DovrebbeDareUnPwadCheLaLibreriaDeiWadSaLeggere;
var
  LSource: IWadSource;
begin
  FComposer.AddLump('PLAYPAL', TBytes.Create(9, 8, 7));
  FComposer.AddMarker('F_END');
  LSource := TWadFactory.OpenBytes('composed', FComposer.ToBytes);
  Assert.AreEqual(2, LSource.Count);
  Assert.AreEqual('PLAYPAL', LSource.Entries[0].Name);
  Assert.AreEqual<Byte>(8, LSource.ReadEntry(0)[1]);
  Assert.AreEqual<Integer>(0, LSource.Entries[1].Size);
end;

procedure TTestGameDataWadComposer.DovrebbeRifiutareUnBuilderNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TGameWadComposer.Create(nil);
    end, EArgumentNilException);
end;

end.
