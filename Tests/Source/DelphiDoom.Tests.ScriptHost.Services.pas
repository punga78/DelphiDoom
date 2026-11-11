{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the services of the compiler and the interpreter       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.ScriptHost.Services;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.ScriptHost.Classes.Intf,
  DelphiDoom.ScriptHost.Constants.Intf,
  DelphiDoom.ScriptHost.Intf,
  DelphiDoom.ScriptHost.Services.Intf,
  DelphiDoom.ScriptHost.Source.Intf;

type
  [TestFixture]
  [Category('scripthost')]
  TTestScriptHostServices = class(TObject)
  private
    FRegistry: IScriptFunctionRegistry;
    FClasses: IScriptClassCatalog;
    FConstants: IScriptConstantProvider;
    FSources: IScriptSourceProvider;
    function Make(const ADefines: TFunc<TArray<string>>): IScriptHostServices;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeDareLeParti;
    [Test]
    procedure DovrebbeDareIlGiocoEIlNome;
    [Test]
    procedure DovrebbeDareDefineUgualiAQuelliDati;
    [Test]
    procedure DovrebbeChiedereIDefineAOgniChiamata;
    [Test]
    procedure DovrebbeDareErroreSeUnaParteEnil;
    [Test]
    procedure DovrebbeLeggereUnFileDalProvider;
  end;

implementation

uses
  DelphiDoom.ScriptHost.Factory,
  DelphiDoom.ScriptHost.Services,
  DelphiDoom.ScriptHost.Types,
  DelphiDoom.Tests.ScriptHost.ConstantFakes;

type
  /// <summary>A provider of files with one file</summary>
  TFakeSourceProvider = class(TInterfacedObject, IScriptSourceProvider)
  public
    function ReadText(const AFileName: string): string;
  end;

function TFakeSourceProvider.ReadText(const AFileName: string): string;
begin
  if SameText(AFileName, 'INC.DDSCRIPT') then
    Result := 'var a: integer;'
  else
    Result := '';
end;

function TTestScriptHostServices.Make(const ADefines: TFunc<TArray<string>>): IScriptHostServices;
begin
  Result := TScriptHostServices.Create(FRegistry, FClasses, FConstants, FSources, 'Radix', sgDoom, ADefines);
end;

procedure TTestScriptHostServices.Setup;
begin
  FRegistry := TScriptHostFactory.CreateRegistry;
  FClasses := TScriptHostFactory.CreateClassCatalog(sgHexen);
  FConstants := TFakeConstantProvider.Create(['A']);
  FSources := TFakeSourceProvider.Create;
end;

procedure TTestScriptHostServices.TearDown;
begin
  FSources := nil;
  FConstants := nil;
  FClasses := nil;
  FRegistry := nil;
end;

procedure TTestScriptHostServices.DovrebbeDareLeParti;
var
  LServices: IScriptHostServices;
begin
  LServices := Make(nil);
  Assert.IsTrue(LServices.Registry = FRegistry);
  Assert.IsTrue(LServices.Classes = FClasses);
  Assert.IsTrue(LServices.Constants = FConstants);
  Assert.IsTrue(LServices.Sources = FSources);
end;

procedure TTestScriptHostServices.DovrebbeDareIlGiocoEIlNome;
var
  LServices: IScriptHostServices;
begin
  LServices := Make(nil);
  // the name of the engine (Radix) and the game of its functions (Doom) are two things
  Assert.AreEqual('Radix', LServices.GameName);
  Assert.AreEqual(Ord(sgDoom), Ord(LServices.Game));
end;

procedure TTestScriptHostServices.DovrebbeDareDefineUgualiAQuelliDati;
var
  LServices: IScriptHostServices;
begin
  LServices := Make(function: TArray<string> begin Result := ['RADIX', 'DEVPARM']; end);
  Assert.AreEqual('RADIX,DEVPARM', string.Join(',', LServices.Defines));
end;

procedure TTestScriptHostServices.DovrebbeChiedereIDefineAOgniChiamata;
var
  LServices: IScriptHostServices;
  LDevParm: Boolean;
begin
  // the engine learns -devparm after it was composed: the defines are not read when the services are made
  LDevParm := False;
  LServices := Make(
    function: TArray<string>
    begin
      if LDevParm then
        Result := ['A', 'DEVPARM']
      else
        Result := ['A'];
    end);
  Assert.AreEqual('A', string.Join(',', LServices.Defines));
  LDevParm := True;
  Assert.AreEqual('A,DEVPARM', string.Join(',', LServices.Defines));
end;

procedure TTestScriptHostServices.DovrebbeDareErroreSeUnaParteEnil;
begin
  Assert.WillRaise(
    procedure
    begin
      TScriptHostServices.Create(nil, FClasses, FConstants, FSources, 'Doom', sgDoom, nil);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TScriptHostServices.Create(FRegistry, nil, FConstants, FSources, 'Doom', sgDoom, nil);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TScriptHostServices.Create(FRegistry, FClasses, nil, FSources, 'Doom', sgDoom, nil);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TScriptHostServices.Create(FRegistry, FClasses, FConstants, nil, 'Doom', sgDoom, nil);
    end, EArgumentNilException);
end;

procedure TTestScriptHostServices.DovrebbeLeggereUnFileDalProvider;
begin
  Assert.AreEqual('var a: integer;', Make(nil).Sources.ReadText('inc.ddscript'));
  Assert.AreEqual('', Make(nil).Sources.ReadText('missing.ddscript'));
end;

end.
