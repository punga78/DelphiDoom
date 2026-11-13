{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom battlescape states library - a line of the menu of the      }
{  actions of an item (ActionMenuItem)                                          }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBattleStates.ActionMenuItem;

interface

uses
  System.SysUtils, DelphiDoom.XcomSurface.Surface, DelphiDoom.XcomSurface.Font, DelphiDoom.XcomBattleStates.OffsetBlit, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action,
  DelphiDoom.XcomEngine.Language, DelphiDoom.XcomEngine.InteractiveSurface, DelphiDoom.XcomEngine.RuleInterface,
  DelphiDoom.XcomUi.Text, DelphiDoom.XcomUi.Frame;

type
  /// <summary>
  ///   A line of the popup menu of the actions of a weapon: a frame with the name of the action, its accuracy and
  ///   its cost in time units; the frame is highlighted while the mouse is over it. Owns its frame and its texts
  /// </summary>
  TXcomActionMenuItem = class(TXcomInteractiveSurface)
  strict private
    FHighlighted: Boolean;
    FActionType: Integer;
    FTimeUnits: Integer;
    FHighlightModifier: Integer;
    FFrame: TXcomFrame;
    FTxtDescription: TXcomText;
    FTxtAccuracy: TXcomText;
    FTxtTimeUnits: TXcomText;
    function NewText(AWidth, AX: Integer; AColor: Byte; ABig, ASmall: TXcomFont; ALanguage: TXcomLanguage): TXcomText;
  protected
    procedure MouseIn(AAction: TXcomAction); override;
    procedure MouseOut(AAction: TXcomAction); override;
  public
    /// <param name="AId">The line, from the bottom: each one is 40 pixels above the one before</param>
    /// <param name="AElement">The element "actionMenu" of the interface of the battlescape (colors, TFTD mode)</param>
    /// <param name="AX">Left of the panel of the icons</param>
    /// <param name="AY">Top of the first line</param>
    constructor Create(AId: Integer; const AElement: TXcomInterfaceElement; ABig, ASmall: TXcomFont;
      ALanguage: TXcomLanguage; AX, AY: Integer);
    destructor Destroy; override;
    /// <summary>setAction: the action of the line, its texts and its cost</summary>
    procedure SetAction(AActionType: Integer; const ADescription, AAccuracy, ATimeUnits: string;
      ATimeUnitsCost: Integer);
    procedure SetPalette(AColors: PXcomColor; AFirst: Integer = 0; ACount: Integer = 256); override;
    /// <summary>draw: the frame and the texts over it (the surface is not cleared first, as in OpenXcom)</summary>
    procedure Draw; override;
    /// <summary>The line, then its texts on the same target</summary>
    procedure Blit(ATarget: TXcomSurface); override;
    /// <summary>getAction: BA_*</summary>
    property ActionType: Integer read FActionType;
    /// <summary>getTUs</summary>
    property TimeUnits: Integer read FTimeUnits;
    /// <summary>The mouse is over the line</summary>
    property Highlighted: Boolean read FHighlighted;
  end;

implementation

uses
  DelphiDoom.XcomBattle.Types;

constructor TXcomActionMenuItem.Create(AId: Integer; const AElement: TXcomInterfaceElement; ABig, ASmall: TXcomFont;
  ALanguage: TXcomLanguage; AX, AY: Integer);
begin
  inherited Create(272, 40, AX + 24, AY - (AId * 40));
  FActionType := BA_NONE;
  if AElement.TftdMode then
    FHighlightModifier := 12
  else
    FHighlightModifier := 3;
  FFrame := TXcomFrame.Create(Width, Height, 0, 0);
  FFrame.SetHighContrast(True);
  FFrame.SetColor(Byte(AElement.Border and $FF));
  FFrame.SetSecondaryColor(Byte(AElement.Color2 and $FF));
  FFrame.SetThickness(8);
  FTxtDescription := NewText(200, 10, Byte(AElement.Color and $FF), ABig, ASmall, ALanguage);
  FTxtAccuracy := NewText(100, 140, Byte(AElement.Color and $FF), ABig, ASmall, ALanguage);
  FTxtTimeUnits := NewText(80, 210, Byte(AElement.Color and $FF), ABig, ASmall, ALanguage);
end;

destructor TXcomActionMenuItem.Destroy;
begin
  FTxtTimeUnits.Free;
  FTxtAccuracy.Free;
  FTxtDescription.Free;
  FFrame.Free;
  inherited Destroy;
end;

function TXcomActionMenuItem.NewText(AWidth, AX: Integer; AColor: Byte; ABig, ASmall: TXcomFont;
  ALanguage: TXcomLanguage): TXcomText;
begin
  Result := TXcomText.Create(AWidth, 20, AX, 13);
  Result.InitText(ABig, ASmall, ALanguage);
  Result.SetBig;
  Result.SetHighContrast(True);
  Result.SetColor(AColor);
end;

procedure TXcomActionMenuItem.SetAction(AActionType: Integer; const ADescription, AAccuracy, ATimeUnits: string;
  ATimeUnitsCost: Integer);
begin
  FActionType := AActionType;
  FTxtDescription.SetText(ADescription);
  FTxtAccuracy.SetText(AAccuracy);
  FTxtTimeUnits.SetText(ATimeUnits);
  FTimeUnits := ATimeUnitsCost;
  Redraw := True;
end;

procedure TXcomActionMenuItem.SetPalette(AColors: PXcomColor; AFirst, ACount: Integer);
begin
  inherited SetPalette(AColors, AFirst, ACount);
  FFrame.SetPalette(AColors, AFirst, ACount);
  FTxtDescription.SetPalette(AColors, AFirst, ACount);
  FTxtAccuracy.SetPalette(AColors, AFirst, ACount);
  FTxtTimeUnits.SetPalette(AColors, AFirst, ACount);
end;

procedure TXcomActionMenuItem.Draw;
begin
  // only the frame: the texts go on the target by Blit (issue 188)
  FFrame.Blit(Self);
end;

procedure TXcomActionMenuItem.Blit(ATarget: TXcomSurface);
begin
  inherited Blit(ATarget);
  // the texts are copied on the target itself, over the frame, so that their ink is left on the screen
  if Visible and not Hidden then
  begin
    TXcomOffsetBlit.Blit(FTxtDescription, ATarget, X, Y);
    TXcomOffsetBlit.Blit(FTxtAccuracy, ATarget, X, Y);
    TXcomOffsetBlit.Blit(FTxtTimeUnits, ATarget, X, Y);
  end;
end;

procedure TXcomActionMenuItem.MouseIn(AAction: TXcomAction);
begin
  FHighlighted := True;
  // a Uint8 in the C++: the color wraps
  FFrame.SetSecondaryColor(Byte((FFrame.GetSecondaryColor - FHighlightModifier) and $FF));
  Draw;
  inherited MouseIn(AAction);
end;

procedure TXcomActionMenuItem.MouseOut(AAction: TXcomAction);
begin
  FHighlighted := False;
  FFrame.SetSecondaryColor(Byte((FFrame.GetSecondaryColor + FHighlightModifier) and $FF));
  Draw;
  inherited MouseOut(AAction);
end;

end.
