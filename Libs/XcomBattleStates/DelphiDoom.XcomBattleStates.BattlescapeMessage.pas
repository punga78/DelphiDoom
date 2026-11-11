{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom battlescape states library - the message window over the    }
{  battle ("Hidden Movement", BattlescapeMessage)                               }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBattleStates.BattlescapeMessage;

interface

uses
  System.SysUtils, DelphiDoom.XcomSurface.Surface, DelphiDoom.XcomSurface.Font, DelphiDoom.XcomEngine.Types,
  DelphiDoom.XcomEngine.Language, DelphiDoom.XcomEngine.Widget, DelphiDoom.XcomEngine.State, DelphiDoom.XcomUi.Text,
  DelphiDoom.XcomUi.Window;

type
  /// <summary>
  ///   A window with a big text in the middle, drawn over the map when the player must not see what moves. Owns its
  ///   window and its text
  /// </summary>
  TXcomBattlescapeMessage = class(TXcomWidget)
  strict private
    FWindow: TXcomWindow;
    FText: TXcomText;
  protected
    procedure SetX(AValue: Integer); override;
    procedure SetY(AValue: Integer); override;
  public
    /// <param name="AState">The state that shows the message (its window takes the clock from it); not owned</param>
    constructor Create(AState: TXcomState; AWidth, AHeight: Integer; AX: Integer = 0; AY: Integer = 0);
    destructor Destroy; override;
    /// <summary>setBackground: the picture behind the text (not owned)</summary>
    procedure SetBackground(ABackground: TXcomSurface);
    procedure SetText(const AMessage: string);
    procedure InitText(ABig, ASmall: TXcomFont; ALanguage: TXcomLanguage); override;
    procedure SetPalette(AColors: PXcomColor; AFirst: Integer = 0; ACount: Integer = 256); override;
    procedure Blit(ATarget: TXcomSurface); override;
    procedure SetHeight(AHeight: Integer); override;
    procedure SetTextColor(AColor: Byte);
  end;

implementation

uses
  DelphiDoom.XcomUi.Types;

constructor TXcomBattlescapeMessage.Create(AState: TXcomState; AWidth, AHeight, AX, AY: Integer);
begin
  inherited Create(AWidth, AHeight, AX, AY);
  FWindow := TXcomWindow.Create(AState, AWidth, AHeight, AX, AY, wpNone);
  // Palette::blockOffset(0) - 1 as a Uint8
  FWindow.SetColor(255);
  FWindow.SetHighContrast(True);
  FText := TXcomText.Create(AWidth, AHeight, AX, AY);
  FText.SetColor(255);
  FText.SetAlign(haCenter);
  FText.SetVerticalAlign(vaMiddle);
  FText.SetHighContrast(True);
end;

destructor TXcomBattlescapeMessage.Destroy;
begin
  FText.Free;
  FWindow.Free;
  inherited Destroy;
end;

procedure TXcomBattlescapeMessage.SetX(AValue: Integer);
begin
  inherited SetX(AValue);
  if Assigned(FWindow) then
    FWindow.X := AValue;
  if Assigned(FText) then
    FText.X := AValue;
end;

procedure TXcomBattlescapeMessage.SetY(AValue: Integer);
begin
  inherited SetY(AValue);
  if Assigned(FWindow) then
    FWindow.Y := AValue;
  if Assigned(FText) then
    FText.Y := AValue;
end;

procedure TXcomBattlescapeMessage.SetBackground(ABackground: TXcomSurface);
begin
  FWindow.SetBackground(ABackground);
end;

procedure TXcomBattlescapeMessage.SetText(const AMessage: string);
begin
  FText.SetText(AMessage);
end;

procedure TXcomBattlescapeMessage.InitText(ABig, ASmall: TXcomFont; ALanguage: TXcomLanguage);
begin
  FText.InitText(ABig, ASmall, ALanguage);
  FText.SetBig;
end;

procedure TXcomBattlescapeMessage.SetPalette(AColors: PXcomColor; AFirst, ACount: Integer);
begin
  inherited SetPalette(AColors, AFirst, ACount);
  FWindow.SetPalette(AColors, AFirst, ACount);
  FText.SetPalette(AColors, AFirst, ACount);
end;

procedure TXcomBattlescapeMessage.Blit(ATarget: TXcomSurface);
begin
  inherited Blit(ATarget);
  FWindow.Blit(ATarget);
  FText.Blit(ATarget);
end;

procedure TXcomBattlescapeMessage.SetHeight(AHeight: Integer);
begin
  inherited SetHeight(AHeight);
  FWindow.SetHeight(AHeight);
  FText.SetHeight(AHeight);
end;

procedure TXcomBattlescapeMessage.SetTextColor(AColor: Byte);
begin
  FText.SetColor(AColor);
end;

end.
