{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the OpenGL context - the list of the extensions        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.OpenGl.ExtensionList;

interface

uses
  System.SysUtils,
  System.Classes,
  DUnitX.TestFramework,
  DelphiDoom.GlContext.ExtensionList;

type
  [TestFixture]
  [Category('opengl')]
  TTestOpenGlExtensionList = class(TObject)
  public
    [Test]
    procedure DovrebbeDareUnaRigaPerEstensioneInMaiuscolo;
    [Test]
    procedure DovrebbeDareUnTestoVuotoSeIlDriverNonDiceNulla;
    [Test]
    procedure DovrebbeTrovareLeEstensioniPerNomeComeFaIlMotore;
    [Test]
    procedure DovrebbeTenereIlNomeSenzaSpaziIntatto;
    [Test]
    procedure DovrebbeDareLoStessoTestoDelVecchioCicloSuUnTestoLungo;
  end;

implementation

{ TTestOpenGlExtensionList }

procedure TTestOpenGlExtensionList.DovrebbeDareUnaRigaPerEstensioneInMaiuscolo;
begin
  Assert.AreEqual('GL_ARB_MULTITEXTURE'#13#10'GL_EXT_TEXTURE3D'#13#10'WGL_EXT_SWAP_CONTROL',
    TGlExtensionList.Normalize('GL_ARB_multitexture GL_EXT_texture3D WGL_EXT_swap_control'));
end;

procedure TTestOpenGlExtensionList.DovrebbeDareUnTestoVuotoSeIlDriverNonDiceNulla;
begin
  Assert.AreEqual('', TGlExtensionList.Normalize(''));
end;

procedure TTestOpenGlExtensionList.DovrebbeTrovareLeEstensioniPerNomeComeFaIlMotore;
var
  LList: TStringList;
begin
  LList := TStringList.Create;
  try
    LList.Text := TGlExtensionList.Normalize('GL_ARB_multitexture GL_EXT_texture3D');
    Assert.AreEqual(2, LList.Count);
    Assert.IsTrue(LList.IndexOf('GL_EXT_TEXTURE3D') > -1);
    Assert.IsTrue(LList.IndexOf('GL_EXT_PALETTED_TEXTURE') = -1);
  finally
    LList.Free;
  end;
end;

procedure TTestOpenGlExtensionList.DovrebbeTenereIlNomeSenzaSpaziIntatto;
begin
  Assert.AreEqual('GL_3DFX_TEXTURE_COMPRESSION_FXT1', TGlExtensionList.Normalize('gl_3dfx_texture_compression_fxt1'));
end;

procedure TTestOpenGlExtensionList.DovrebbeDareLoStessoTestoDelVecchioCicloSuUnTestoLungo;
var
  LSource: string;
  LOld: string;
  LIndex: Integer;
begin
  LSource := '';
  for LIndex := 0 to 199 do
    LSource := LSource + 'GL_vendor_ext' + IntToStr(LIndex) + ' ';
  // the loop of gld_Init before Libs\GlContext
  LOld := '';
  for LIndex := 1 to Length(LSource) do
  begin
    if LSource[LIndex] = ' ' then
      LOld := LOld + #13#10
    else if (LSource[LIndex] >= 'a') and (LSource[LIndex] <= 'z') then
      LOld := LOld + Char(Ord(LSource[LIndex]) - 32)
    else
      LOld := LOld + LSource[LIndex];
  end;
  Assert.AreEqual(LOld, TGlExtensionList.Normalize(LSource));
end;

end.
