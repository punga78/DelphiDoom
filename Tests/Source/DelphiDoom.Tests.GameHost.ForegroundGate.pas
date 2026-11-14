{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the game host library - the gate of the window in the   }
{  foreground                                                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.GameHost.ForegroundGate;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Input.Intf, DelphiDoom.GameHost.Events.Intf,
  DelphiDoom.GameHost.ForegroundGate, DelphiDoom.Tests.GameHost.WindowMouse;

type
  [TestFixture]
  [Category('gamehost')]
  TTestGameHostForegroundGate = class(TObject)
  public
    [Test]
    procedure DovrebbeEssereApertaSoloConLaFinestraInPrimoPiano;
    [Test]
    procedure DovrebbeEssereChiusaSenzaFinestra;
    [Test]
    procedure DovrebbeRifiutareUnaAreaNulla;
  end;

implementation

procedure TTestGameHostForegroundGate.DovrebbeEssereApertaSoloConLaFinestraInPrimoPiano;
var
  LArea: TFakeWindowArea;
  LAreaKeeper: IGameHostCursorArea;
  LGate: IInputGate;
begin
  LArea := TFakeWindowArea.Create;
  LAreaKeeper := LArea;
  LArea.HasWindow := True;
  LArea.Foreground := True;
  LGate := TGameHostForegroundGate.Create(LAreaKeeper);
  Assert.IsTrue(LGate.IsInputAllowed);
  LArea.Foreground := False;
  Assert.IsFalse(LGate.IsInputAllowed);
end;

procedure TTestGameHostForegroundGate.DovrebbeEssereChiusaSenzaFinestra;
var
  LArea: TFakeWindowArea;
  LAreaKeeper: IGameHostCursorArea;
begin
  LArea := TFakeWindowArea.Create;
  LAreaKeeper := LArea;
  LArea.Foreground := True;
  Assert.IsFalse((TGameHostForegroundGate.Create(LAreaKeeper) as IInputGate).IsInputAllowed);
end;

procedure TTestGameHostForegroundGate.DovrebbeRifiutareUnaAreaNulla;
var
  LNone: IGameHostCursorArea;
begin
  LNone := nil;
  Assert.WillRaise(
    procedure
    begin
      TGameHostForegroundGate.Create(LNone).Free;
    end, EArgumentNilException);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestGameHostForegroundGate);

end.
