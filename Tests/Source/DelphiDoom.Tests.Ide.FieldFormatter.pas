{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the ide library - TIdeFieldFormatter                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Ide.FieldFormatter;

interface

uses
  System.Classes,
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('ide')]
  TTestIdeFieldFormatter = class(TObject)
  strict private
    FSprites: TStringList;
    FStates: TStringList;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeScrivereIlNomeDelloSprite;
    [Test]
    procedure DovrebbeScrivereLoSpriteSconosciutoInDueModi;
    [Test]
    procedure DovrebbeScrivereLaLetteraDelFotogramma;
    [Test]
    procedure DovrebbeAggiungereBrightSeCeIlBit;
    [Test]
    procedure DovrebbeScrivereIlFotogrammaSconosciutoInDueModi;
    [Test]
    procedure DovrebbeScrivereIlNomeDelloStatoSeguente;
    [Test]
    procedure DovrebbeNonTradurreLUltimoStatoComeIlVecchioCodice;
    [Test]
    procedure DovrebbeLasciareGliAltriCampi;
    [Test]
    procedure DovrebbeNonFermarsiSuUnNumeroNonValido;
  end;

implementation

uses
  DelphiDoom.Ide.FieldFormatter;

{ TTestIdeFieldFormatter }

procedure TTestIdeFieldFormatter.Setup;
begin
  FSprites := TStringList.Create;
  FSprites.CommaText := 'TROO,POSS,SPOS';
  FStates := TStringList.Create;
  FStates.CommaText := 'S_NULL,S_LIGHTDONE,S_PUNCH,S_LAST';
end;

procedure TTestIdeFieldFormatter.TearDown;
begin
  FStates.Free;
  FSprites.Free;
end;

procedure TTestIdeFieldFormatter.DovrebbeScrivereIlNomeDelloSprite;
begin
  Assert.AreEqual('POSS', TIdeFieldFormatter.ForTree('Sprite Number', '1', FSprites, FStates));
  Assert.AreEqual('POSS', TIdeFieldFormatter.ForList('Sprite Number', '1', FSprites, FStates));
end;

procedure TTestIdeFieldFormatter.DovrebbeScrivereLoSpriteSconosciutoInDueModi;
begin
  Assert.AreEqual('Unknown sprite number #09', TIdeFieldFormatter.ForTree('Sprite Number', '09', FSprites, FStates));
  Assert.AreEqual('Unknown sprite number #9', TIdeFieldFormatter.ForList('Sprite Number', '09', FSprites, FStates));
end;

procedure TTestIdeFieldFormatter.DovrebbeScrivereLaLetteraDelFotogramma;
begin
  Assert.AreEqual('A', TIdeFieldFormatter.ForTree('Sprite Subnumber', '0', FSprites, FStates));
  Assert.AreEqual('C', TIdeFieldFormatter.ForList('Sprite Subnumber', '2', FSprites, FStates));
  Assert.AreEqual(']', TIdeFieldFormatter.ForList('Sprite Subnumber', '28', FSprites, FStates));
end;

procedure TTestIdeFieldFormatter.DovrebbeAggiungereBrightSeCeIlBit;
begin
  Assert.AreEqual('B BRIGHT', TIdeFieldFormatter.ForTree('Sprite Subnumber', '32769', FSprites, FStates));
  Assert.AreEqual('B BRIGHT', TIdeFieldFormatter.ForList('Sprite Subnumber', '32769', FSprites, FStates));
end;

procedure TTestIdeFieldFormatter.DovrebbeScrivereIlFotogrammaSconosciutoInDueModi;
begin
  Assert.AreEqual('Unknown sprite subnumber #32799',
    TIdeFieldFormatter.ForTree('Sprite Subnumber', '32799', FSprites, FStates));
  // the list shows the number without the bright bit
  Assert.AreEqual('Unknown sprite subnumber #31',
    TIdeFieldFormatter.ForList('Sprite Subnumber', '32799', FSprites, FStates));
end;

procedure TTestIdeFieldFormatter.DovrebbeScrivereIlNomeDelloStatoSeguente;
begin
  Assert.AreEqual('S_PUNCH', TIdeFieldFormatter.ForTree('Next Frame', '2', FSprites, FStates));
  Assert.AreEqual('S_PUNCH', TIdeFieldFormatter.ForList('Next Frame', '2', FSprites, FStates));
end;

procedure TTestIdeFieldFormatter.DovrebbeNonTradurreLUltimoStatoComeIlVecchioCodice;
begin
  Assert.AreEqual('3', TIdeFieldFormatter.ForTree('Next Frame', '3', FSprites, FStates));
  Assert.AreEqual('99', TIdeFieldFormatter.ForList('Next Frame', '99', FSprites, FStates));
end;

procedure TTestIdeFieldFormatter.DovrebbeLasciareGliAltriCampi;
begin
  Assert.AreEqual('12', TIdeFieldFormatter.ForTree('Duration', '12', FSprites, FStates));
  Assert.AreEqual('12', TIdeFieldFormatter.ForList('Duration', '12', FSprites, FStates));
  // the names of the fields are case sensitive
  Assert.AreEqual('1', TIdeFieldFormatter.ForList('sprite number', '1', FSprites, FStates));
end;

procedure TTestIdeFieldFormatter.DovrebbeNonFermarsiSuUnNumeroNonValido;
begin
  // the old panels raised an exception here
  Assert.AreEqual('Unknown sprite number #x', TIdeFieldFormatter.ForTree('Sprite Number', 'x', FSprites, FStates));
  Assert.AreEqual('Unknown sprite subnumber #x', TIdeFieldFormatter.ForTree('Sprite Subnumber', 'x', FSprites, FStates));
end;

end.
