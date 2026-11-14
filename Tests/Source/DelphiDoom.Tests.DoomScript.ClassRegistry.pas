{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the Doom script library - TDoomScriptClassRegistry}
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.DoomScript.ClassRegistry;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.DoomScript.Types, DelphiDoom.DoomScript.ClassInfo,
  DelphiDoom.DoomScript.ClassRegistry, DelphiDoom.Tests.DoomScript.Support;

type
  [TestFixture]
  [Category('DoomScript')]
  TTestDoomScriptClassRegistry = class
  private
    FRegistry: TDoomScriptClassRegistry;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeDichiarareUnaClasseELaSuaSottoclasse;
    [Test]
    procedure DovrebbeCercarePerNomeConLeMaiuscole;
    [Test]
    procedure DovrebbeRifiutareUnaClasseDichiarataDueVolte;
    [Test]
    procedure DovrebbeRifiutareUnaSuperclasseSconosciuta;
  end;

implementation

procedure TTestDoomScriptClassRegistry.Setup;
begin
  FRegistry := TDoomScriptClassRegistry.Create;
end;

procedure TTestDoomScriptClassRegistry.TearDown;
begin
  FRegistry.Free;
end;

procedure TTestDoomScriptClassRegistry.DovrebbeDichiarareUnaClasseELaSuaSottoclasse;
var
  LRoot: TDoomScriptClassInfo;
  LChild: TDoomScriptClassInfo;
begin
  LRoot := FRegistry.Declare('idClass');
  LChild := FRegistry.Declare('idEntity', 'idClass');
  Assert.IsNull(LRoot.Super);
  Assert.AreSame(LRoot, LChild.Super);
  Assert.AreEqual('idEntity', string(LChild.Name));
  Assert.AreSame(LChild, FRegistry.GetClass('idEntity'));
  Assert.AreSame(LRoot, FRegistry.GetClass('idClass'));
end;

procedure TTestDoomScriptClassRegistry.DovrebbeCercarePerNomeConLeMaiuscole;
begin
  FRegistry.Declare('idClass');
  Assert.IsNull(FRegistry.GetClass('idclass'));
  Assert.IsNull(FRegistry.GetClass('nothing'));
  Assert.IsNull(FRegistry.GetClass(''));
end;

procedure TTestDoomScriptClassRegistry.DovrebbeRifiutareUnaClasseDichiarataDueVolte;
begin
  FRegistry.Declare('a');
  TDoomScriptTestSupport.ExpectError(
    procedure
    begin
      FRegistry.Declare('a');
    end, EDoomScriptError, 'TDoomScriptClassRegistry: class ''a'' declared twice');
end;

procedure TTestDoomScriptClassRegistry.DovrebbeRifiutareUnaSuperclasseSconosciuta;
begin
  TDoomScriptTestSupport.ExpectError(
    procedure
    begin
      FRegistry.Declare('b', 'x');
    end, EDoomScriptError, 'TDoomScriptClassRegistry: unknown superclass ''x'' of class ''b''');
  Assert.IsNull(FRegistry.GetClass('b'));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestDoomScriptClassRegistry);

end.
