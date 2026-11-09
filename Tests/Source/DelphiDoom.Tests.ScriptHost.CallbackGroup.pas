{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the groups made by a procedure                         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.ScriptHost.CallbackGroup;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.ScriptHost.Intf,
  DelphiDoom.Tests.ScriptHost.Fakes;

type
  [TestFixture]
  [Category('scripthost')]
  TTestScriptHostCallbackGroup = class(TObject)
  public
    [Test]
    procedure DovrebbeDareIlNomeDellaUnit;
    [Test]
    procedure DovrebbeChiamareLaProceduraConLaTabella;
    [Test]
    procedure DovrebbeDareErroreSeLaProceduraEnil;
  end;

implementation

uses
  DelphiDoom.ScriptHost.CallbackGroup,
  DelphiDoom.ScriptHost.Factory;

{ TTestScriptHostCallbackGroup }

procedure TTestScriptHostCallbackGroup.DovrebbeDareIlNomeDellaUnit;
var
  LGroup: IScriptFunctionGroup;
begin
  LGroup := TScriptHostFactory.CreateCallbackGroup('PS_GAME',
    procedure(const ATable: IScriptFunctionTable)
    begin
    end);
  Assert.AreEqual('PS_GAME', LGroup.UnitName);
end;

procedure TTestScriptHostCallbackGroup.DovrebbeChiamareLaProceduraConLaTabella;
var
  LGroup: IScriptFunctionGroup;
  LTable: TFakeFunctionTable;
  LTableRef: IScriptFunctionTable;
begin
  LGroup := TScriptHostFactory.CreateCallbackGroup('PS_GAME',
    procedure(const ATable: IScriptFunctionTable)
    begin
      ATable.Add('procedure One;', nil);
      ATable.Add('procedure Two;', nil);
    end);
  LTable := TFakeFunctionTable.Create;
  LTableRef := LTable;
  LGroup.Describe(LTableRef);
  Assert.AreEqual(2, LTable.Declarations.Count);
  Assert.AreEqual('procedure Two;', LTable.Declarations[1]);
end;

procedure TTestScriptHostCallbackGroup.DovrebbeDareErroreSeLaProceduraEnil;
begin
  Assert.WillRaise(
    procedure
    begin
      TScriptCallbackGroup.Create('PS_GAME', nil);
    end, EArgumentNilException);
end;

end.
