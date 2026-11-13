{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TTextureFormats                                        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Texture.Formats;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Texture.Types, DelphiDoom.Texture.Image,
  DelphiDoom.Texture.Intf, DelphiDoom.Texture.Formats;

type
  [TestFixture]
  [Category('texture')]
  TTestTextureFormats = class(TObject)
  private
    FFormats: ITextureFormats;
  public
    [Setup]
    procedure Setup;

    [Test]
    procedure DovrebbeTrovareIlDecoderDiUnaEstensione;
    [Test]
    procedure DovrebbeNonDistinguereLeMaiuscole;
    [Test]
    procedure DovrebbeTrovareUnDecoderChePiuRecenteContieneIlTesto;
    [Test]
    procedure DovrebbeDareNilPerUnaEstensioneSconosciuta;
    [Test]
    procedure DovrebbeDareNilPerUnaEstensioneVuota;
    [Test]
    procedure DovrebbeDireSeUnaEstensioneEEsattamenteQuellaDiUnDecoder;
    [Test]
    procedure DovrebbeDareLeEstensioniNellOrdineDiRegistrazione;
    [Test]
    procedure DovrebbeDecodificareConIlDecoderTrovato;
    [Test]
    procedure DovrebbeDareFalseSenzaDecoder;
    [Test]
    procedure DovrebbeRifiutareUnDecoderNil;
  end;

implementation

type
  TNamedDecoder = class(TInterfacedObject, ITextureDecoder)
  strict private
    FExtension: string;
  public
    Decoded: Integer;
    constructor Create(const AExtension: string);
    function GetExtension: string;
    function Decode(const ASource: TBytes; const AImage: TTextureImage): Boolean;
  end;

constructor TNamedDecoder.Create(const AExtension: string);
begin
  inherited Create;
  FExtension := AExtension;
end;

function TNamedDecoder.GetExtension: string;
begin
  Result := FExtension;
end;

function TNamedDecoder.Decode(const ASource: TBytes; const AImage: TTextureImage): Boolean;
begin
  Inc(Decoded);
  Result := Length(ASource) > 0;
end;

procedure TTestTextureFormats.Setup;
var
  LDecoders: TArray<ITextureDecoder>;
begin
  SetLength(LDecoders, 4);
  LDecoders[0] := TNamedDecoder.Create('.PNG');
  LDecoders[1] := TNamedDecoder.Create('.PNGSPRITE');
  LDecoders[2] := TNamedDecoder.Create('.JPG');
  LDecoders[3] := TNamedDecoder.Create('.JPEG');
  FFormats := TTextureFormats.Create(LDecoders);
end;

procedure TTestTextureFormats.DovrebbeTrovareIlDecoderDiUnaEstensione;
begin
  Assert.AreEqual('.JPG', FFormats.FindDecoder('.JPG').Extension, 'dovrebbe trovare .JPG');
  Assert.AreEqual('.JPEG', FFormats.FindDecoder('.JPEG').Extension, 'dovrebbe trovare .JPEG');
  Assert.AreEqual('.PNGSPRITE', FFormats.FindDecoder('.PNGSPRITE').Extension, 'dovrebbe trovare .PNGSPRITE');
end;

procedure TTestTextureFormats.DovrebbeNonDistinguereLeMaiuscole;
begin
  Assert.AreEqual('.JPG', FFormats.FindDecoder('.jpg').Extension, 'dovrebbe trovare .jpg');
end;

procedure TTestTextureFormats.DovrebbeTrovareUnDecoderChePiuRecenteContieneIlTesto;
begin
  // as the old list: '.PNG' is inside of '.PNGSPRITE', which was added after it, so it is found first
  Assert.AreEqual('.PNGSPRITE', FFormats.FindDecoder('.PNG').Extension, 'dovrebbe dare il decoder piu'' recente');
  Assert.AreEqual('.JPEG', FFormats.FindDecoder('.JP').Extension, 'dovrebbe dare quello che contiene il testo');
  Assert.AreEqual('.PNGSPRITE', FFormats.FindDecoder('.P').Extension, 'dovrebbe dare l''ultimo dei decoder che lo contengono');
end;

procedure TTestTextureFormats.DovrebbeDareNilPerUnaEstensioneSconosciuta;
begin
  Assert.IsNull(FFormats.FindDecoder('.XYZ'), 'dovrebbe dare nil');
end;

procedure TTestTextureFormats.DovrebbeDareNilPerUnaEstensioneVuota;
begin
  Assert.IsNull(FFormats.FindDecoder(''), 'dovrebbe dare nil per il testo vuoto');
end;

procedure TTestTextureFormats.DovrebbeDireSeUnaEstensioneEEsattamenteQuellaDiUnDecoder;
begin
  Assert.IsTrue(FFormats.IsKnownExtension('.PNG'), 'dovrebbe conoscere .PNG');
  Assert.IsTrue(FFormats.IsKnownExtension('.jpeg'), 'dovrebbe conoscere .jpeg senza badare alle maiuscole');
  Assert.IsFalse(FFormats.IsKnownExtension('.JP'), 'non dovrebbe conoscere un pezzo di estensione');
  Assert.IsFalse(FFormats.IsKnownExtension('PNG'), 'non dovrebbe conoscere un''estensione senza punto');
end;

procedure TTestTextureFormats.DovrebbeDareLeEstensioniNellOrdineDiRegistrazione;
var
  LExtensions: TArray<string>;
begin
  LExtensions := FFormats.Extensions;
  Assert.AreEqual<Integer>(4, Length(LExtensions), 'dovrebbe dare 4 estensioni');
  Assert.AreEqual('.PNG', LExtensions[0], 'dovrebbe cominciare da .PNG');
  Assert.AreEqual('.JPEG', LExtensions[3], 'dovrebbe finire con .JPEG');
end;

procedure TTestTextureFormats.DovrebbeDecodificareConIlDecoderTrovato;
var
  LImage: TTextureImage;
begin
  LImage := TTextureImage.Create;
  try
    Assert.IsTrue(FFormats.Decode('.JPG', TBytes.Create(1), LImage), 'dovrebbe dare il risultato del decoder');
    Assert.IsFalse(FFormats.Decode('.JPG', nil, LImage), 'dovrebbe dare false quando il decoder lo da');
  finally
    LImage.Free;
  end;
end;

procedure TTestTextureFormats.DovrebbeDareFalseSenzaDecoder;
var
  LImage: TTextureImage;
begin
  LImage := TTextureImage.Create;
  try
    Assert.IsFalse(FFormats.Decode('.XYZ', TBytes.Create(1), LImage), 'dovrebbe dare false');
  finally
    LImage.Free;
  end;
end;

procedure TTestTextureFormats.DovrebbeRifiutareUnDecoderNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TTextureFormats.Create(TArray<ITextureDecoder>.Create(TNamedDecoder.Create('.A'), nil));
    end, EArgumentNilException, 'dovrebbe rifiutare un decoder nil');
end;

end.
