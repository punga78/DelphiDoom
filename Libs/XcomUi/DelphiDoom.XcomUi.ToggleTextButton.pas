{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom interface library - ToggleTextButton of OpenXcom            }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomUi.ToggleTextButton;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action, DelphiDoom.XcomUi.TextButton;

type
  /// <summary>
  ///   A button that stays pressed until it is pressed again (with the left or the right button). It uses a group of
  ///   its own with itself as the selected button, the trick of the C++ that makes TextButton draw it pressed
  /// </summary>
  TXcomToggleTextButton = class(TXcomTextButton)
  strict private
    FPressed: Boolean;
    FOriginalColor: Integer;
    FInvertedColor: Integer;
    FFakeGroup: TXcomButtonGroup;
  protected
    procedure MousePress(AAction: TXcomAction); override;
  public
    constructor Create(AWidth, AHeight: Integer; AX: Integer = 0; AY: Integer = 0);
    destructor Destroy; override;
    procedure SetPressed(APressed: Boolean);
    function GetPressed: Boolean;
    procedure SetColor(AColor: Byte); override;
    /// <summary>With an inverted color the button is drawn in it, and the surface is inverted around it while pressed</summary>
    procedure SetInvertColor(AColor: Byte);
    procedure Draw; override;
  end;

implementation

constructor TXcomToggleTextButton.Create(AWidth, AHeight, AX, AY: Integer);
begin
  inherited Create(AWidth, AHeight, AX, AY);
  FOriginalColor := -1;
  FInvertedColor := -1;
  FFakeGroup := TXcomButtonGroup.Create;
  inherited SetGroup(FFakeGroup);
end;

destructor TXcomToggleTextButton.Destroy;
begin
  inherited SetGroup(nil);
  FFakeGroup.Free;
  inherited Destroy;
end;

procedure TXcomToggleTextButton.MousePress(AAction: TXcomAction);
begin
  if (AAction.Details^.Button = XCOM_BUTTON_LEFT) or (AAction.Details^.Button = XCOM_BUTTON_RIGHT) then
  begin
    SetPressed(not FPressed);
  end;
  // skip the code of TextButton: it would set the group
  InteractiveMousePress(AAction);
  Draw;
end;

procedure TXcomToggleTextButton.SetPressed(APressed: Boolean);
begin
  FPressed := APressed;
  if FPressed then
    FFakeGroup.Selected := Self
  else
    FFakeGroup.Selected := nil;
  if FPressed and (FInvertedColor > -1) then
    inherited SetColor(Byte(FInvertedColor))
  else
    inherited SetColor(Byte(FOriginalColor));
  Redraw := True;
end;

function TXcomToggleTextButton.GetPressed: Boolean;
begin
  Result := FPressed;
end;

procedure TXcomToggleTextButton.SetColor(AColor: Byte);
begin
  FOriginalColor := AColor;
  inherited SetColor(AColor);
end;

procedure TXcomToggleTextButton.SetInvertColor(AColor: Byte);
begin
  FInvertedColor := AColor;
  FFakeGroup.Selected := nil;
  Redraw := True;
end;

procedure TXcomToggleTextButton.Draw;
begin
  if FInvertedColor > -1 then
    FFakeGroup.Selected := nil;
  inherited Draw;
  if (FInvertedColor > -1) and FPressed then
    Invert(Byte(FInvertedColor + 4));
end;

end.
