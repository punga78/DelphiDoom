{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom battlescape states library - the warning that fades away    }
{  on the panel of the battlescape (WarningMessage)                             }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBattleStates.WarningMessage;

interface

uses
  DelphiDoom.Clock.Intf,
  System.SysUtils, DelphiDoom.XcomSurface.Font, DelphiDoom.XcomSurface.Surface, DelphiDoom.XcomBattleStates.OffsetBlit, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Intf,
  DelphiDoom.XcomEngine.Language, DelphiDoom.XcomEngine.Widget, DelphiDoom.XcomEngine.Timer, DelphiDoom.XcomUi.Text;

type
  /// <summary>
  ///   A red box with a text in the middle that shows a warning ("Not enough time units!") and fades away in 24
  ///   steps of 50 ms. Owns its text and its timer
  /// </summary>
  TXcomWarningMessage = class(TXcomWidget)
  strict private
    FText: TXcomText;
    FTimer: TXcomTimer;
    FColor: Byte;
    FFade: Byte;
    procedure Fade;
  public
    constructor Create(const AClock: IClock; AWidth, AHeight: Integer; AX: Integer = 0; AY: Integer = 0);
    destructor Destroy; override;
    /// <summary>setColor: the first color of the fading background</summary>
    procedure SetColor(AColor: Byte); override;
    /// <summary>setTextColor</summary>
    procedure SetTextColor(AColor: Byte);
    procedure InitText(ABig, ASmall: TXcomFont; ALanguage: TXcomLanguage); override;
    procedure SetPalette(AColors: PXcomColor; AFirst: Integer = 0; ACount: Integer = 256); override;
    /// <summary>showMessage: shows the text and starts the fading</summary>
    procedure ShowMessage(const AMessage: string);
    procedure Think; override;
    procedure Draw; override;
    /// <summary>The box, then its text on the same target</summary>
    procedure Blit(ATarget: TXcomSurface); override;
    /// <summary>The text shown (for the tests)</summary>
    function Text: string;
  end;

implementation

uses
  DelphiDoom.XcomUi.Types;

constructor TXcomWarningMessage.Create(const AClock: IClock; AWidth, AHeight, AX, AY: Integer);
begin
  inherited Create(AWidth, AHeight, AX, AY);
  FText := TXcomText.Create(AWidth, AHeight, 0, 0);
  FText.SetHighContrast(True);
  FText.SetAlign(haCenter);
  FText.SetVerticalAlign(vaMiddle);
  FText.SetWordWrap(True);
  FTimer := TXcomTimer.Create(AClock, 50);
  FTimer.OnTimerSurface(Fade);
  Visible := False;
end;

destructor TXcomWarningMessage.Destroy;
begin
  FTimer.Free;
  FText.Free;
  inherited Destroy;
end;

procedure TXcomWarningMessage.SetColor(AColor: Byte);
begin
  FColor := AColor;
end;

procedure TXcomWarningMessage.SetTextColor(AColor: Byte);
begin
  FText.SetColor(AColor);
end;

procedure TXcomWarningMessage.InitText(ABig, ASmall: TXcomFont; ALanguage: TXcomLanguage);
begin
  FText.InitText(ABig, ASmall, ALanguage);
end;

procedure TXcomWarningMessage.SetPalette(AColors: PXcomColor; AFirst, ACount: Integer);
begin
  inherited SetPalette(AColors, AFirst, ACount);
  FText.SetPalette(AColors, AFirst, ACount);
end;

procedure TXcomWarningMessage.ShowMessage(const AMessage: string);
begin
  FText.SetText(AMessage);
  FFade := 0;
  Redraw := True;
  Visible := True;
  FTimer.Start;
end;

function TXcomWarningMessage.Text: string;
begin
  Result := FText.GetText;
end;

procedure TXcomWarningMessage.Think;
begin
  FTimer.Think(False, True);
end;

procedure TXcomWarningMessage.Fade;
begin
  Inc(FFade);
  Redraw := True;
  if FFade = 24 then
  begin
    Visible := False;
    FTimer.Stop;
  end;
end;

procedure TXcomWarningMessage.Draw;
var
  LShade: Integer;
begin
  inherited Draw;
  if FFade > 12 then
    LShade := 12
  else
    LShade := FFade;
  // only the box: the text goes on the target by Blit (issue 188)
  DrawRect(0, 0, Width, Height, Byte(FColor + LShade));
end;

procedure TXcomWarningMessage.Blit(ATarget: TXcomSurface);
begin
  inherited Blit(ATarget);
  // the text is placed in the box and copied on the target itself, so that its ink is left there (a text drawn
  // inside the box would reach the screen as a picture of the game)
  if Visible and not Hidden then
    TXcomOffsetBlit.Blit(FText, ATarget, X, Y);
end;

end.
