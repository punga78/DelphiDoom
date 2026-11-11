{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom battlescape states library - a message over the battle      }
{  that goes away by itself (InfoboxState: "... has panicked")                  }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBattleStates.InfoboxState;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.State,
  DelphiDoom.XcomEngine.Timer, DelphiDoom.XcomUi.Text, DelphiDoom.XcomUi.Frame;

type
  /// <summary>A framed message shown for two seconds, or until a key or a click</summary>
  TXcomInfoboxState = class(TXcomState)
  strict private
    FFrame: TXcomFrame;
    FText: TXcomText;
    FTimer: TXcomTimer;
    FClosed: Boolean;
    procedure Close;
  public
    /// <param name="APalette">The 256 colors of the battle (the palette of its depth)</param>
    constructor Create(AHost: TXcomStateHost; APalette: PXcomColor; const AMessage: string);
    destructor Destroy; override;
    procedure Handle(AAction: TXcomAction); override;
    procedure Think; override;
  end;

implementation

uses
  DelphiDoom.XcomUi.Types;

const
  INFOBOX_DELAY = 2000;

constructor TXcomInfoboxState.Create(AHost: TXcomStateHost; APalette: PXcomColor; const AMessage: string);
begin
  inherited Create(AHost);
  ToggleScreen;
  FFrame := TXcomFrame.Create(261, 122, 34, 10);
  FText := TXcomText.Create(251, 112, 39, 15);
  SetPalette('PAL_BATTLESCAPE', -1);
  SetPalette(APalette, 0, 256);
  Add(FFrame, 'infoBox', 'battlescape');
  Add(FText, 'infoBox', 'battlescape');
  CenterAllSurfaces;
  FFrame.SetHighContrast(True);
  FFrame.SetThickness(9);
  FText.SetAlign(haCenter);
  FText.SetVerticalAlign(vaMiddle);
  FText.SetBig;
  FText.SetWordWrap(True);
  FText.SetText(AMessage);
  FText.SetHighContrast(True);
  FTimer := TXcomTimer.Create(Host.Clock, INFOBOX_DELAY);
  FTimer.OnTimerState(Close);
  FTimer.Start;
end;

destructor TXcomInfoboxState.Destroy;
begin
  FTimer.Free;
  inherited Destroy;
end;

procedure TXcomInfoboxState.Handle(AAction: TXcomAction);
begin
  inherited Handle(AAction);
  if (AAction.Details.Kind = ekKeyDown) or (AAction.Details.Kind = ekMouseDown) then
    Close;
end;

procedure TXcomInfoboxState.Think;
begin
  FTimer.Think(True, False);
end;

procedure TXcomInfoboxState.Close;
begin
  if FClosed then
    Exit;
  FClosed := True;
  FTimer.Stop;
  Host.PopState;
end;

end.
