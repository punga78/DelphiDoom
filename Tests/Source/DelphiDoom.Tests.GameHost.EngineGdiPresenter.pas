{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the engine - the frame of the software renderer on GDI  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.GameHost.EngineGdiPresenter;

interface

uses
  Winapi.Windows, System.Types, System.SysUtils, DUnitX.TestFramework,
  DelphiDoom.Engine.Video.FramePresenter.Intf, DelphiDoom.Engine.Video.GdiPresenter;

type
  [TestFixture]
  [Category('gamehost')]
  TTestEngineGdiPresenter = class(TObject)
  public
    [Test]
    procedure DovrebbeRifiutareUnaFinestraNulla;
    [Test]
    procedure DovrebbeNonFareNienteSenzaFinestra;
    [Test]
    procedure DovrebbeLeggereLaFinestraAOgniFotogramma;
    [Test]
    procedure DovrebbeDisegnareInUnaFinestraVera;
  end;

implementation

{ TTestEngineGdiPresenter }

procedure TTestEngineGdiPresenter.DovrebbeRifiutareUnaFinestraNulla;
begin
  Assert.WillRaise(
    procedure
    begin
      TEngineGdiFramePresenter.Create(nil);
    end, EArgumentNilException);
end;

procedure TTestEngineGdiPresenter.DovrebbeNonFareNienteSenzaFinestra;
var
  LPresenter: IEngineFramePresenter;
  LFrame: array[0..3] of Cardinal;
begin
  LPresenter := TEngineGdiFramePresenter.Create(
    function: THandle
    begin
      Result := 0;
    end);
  LPresenter.Present(@LFrame[0], 2, 2, TRect.Create(0, 0, 2, 2), 1);
  Assert.Pass;
end;

procedure TTestEngineGdiPresenter.DovrebbeLeggereLaFinestraAOgniFotogramma;
var
  LPresenter: IEngineFramePresenter;
  LFrame: array[0..3] of Cardinal;
  LCalls: Integer;
begin
  LCalls := 0;
  LPresenter := TEngineGdiFramePresenter.Create(
    function: THandle
    begin
      Inc(LCalls);
      Result := 0;
    end);
  LPresenter.Present(@LFrame[0], 2, 2, TRect.Create(0, 0, 2, 2), 3);
  LPresenter.Present(@LFrame[0], 2, 2, TRect.Create(0, 0, 2, 2), 1);
  Assert.AreEqual<Integer>(2, LCalls);
end;

procedure TTestEngineGdiPresenter.DovrebbeDisegnareInUnaFinestraVera;
var
  LWindow: HWND;
  LPresenter: IEngineFramePresenter;
  LFrame: array[0..3] of Cardinal;
begin
  // a hidden window of the system (the class STATIC): the frame goes to its device context without errors
  LWindow := CreateWindowEx(0, 'STATIC', nil, WS_POPUP, 0, 0, 8, 8, 0, 0, HInstance, nil);
  if LWindow = 0 then
  begin
    Assert.Pass;
    Exit;
  end;
  try
    LPresenter := TEngineGdiFramePresenter.Create(
      function: THandle
      begin
        Result := LWindow;
      end);
    LPresenter.Present(@LFrame[0], 2, 2, TRect.Create(0, 0, 8, 8), 2);
    Assert.Pass;
  finally
    DestroyWindow(LWindow);
  end;
end;

end.
