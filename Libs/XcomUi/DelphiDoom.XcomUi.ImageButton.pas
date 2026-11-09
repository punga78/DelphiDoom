{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom interface library - ImageButton of OpenXcom                 }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomUi.ImageButton;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action,
  DelphiDoom.XcomEngine.InteractiveSurface;

type
  TXcomImageButton = class;

  /// <summary>The variable that a group of image buttons shares (the ImageButton ** of the C++)</summary>
  TXcomImageButtonGroup = class
  public
    Selected: TXcomImageButton;
  end;

  /// <summary>A button whose picture is inverted around a color while it is pressed</summary>
  TXcomImageButton = class(TXcomInteractiveSurface)
  strict private
    FColor: Byte;
    FGroup: TXcomImageButtonGroup;
    FInverted: Boolean;
  protected
    procedure MousePress(AAction: TXcomAction); override;
    procedure MouseRelease(AAction: TXcomAction); override;
  public
    procedure SetColor(AColor: Byte); override;
    function GetColor: Byte; override;
    /// <summary>nil makes it a regular button; a button that is already the selected one is inverted</summary>
    procedure SetGroup(AGroup: TXcomImageButtonGroup);
    /// <summary>Inverts the button on or off explicitly and keeps track of it</summary>
    procedure Toggle(APress: Boolean);
  end;

implementation

procedure TXcomImageButton.SetColor(AColor: Byte);
begin
  FColor := AColor;
end;

function TXcomImageButton.GetColor: Byte;
begin
  Result := FColor;
end;

procedure TXcomImageButton.SetGroup(AGroup: TXcomImageButtonGroup);
begin
  FGroup := AGroup;
  if Assigned(FGroup) and (FGroup.Selected = Self) then
    Invert(Byte(FColor + 3));
end;

procedure TXcomImageButton.MousePress(AAction: TXcomAction);
begin
  if Assigned(FGroup) then
  begin
    if AAction.Details^.Button = XCOM_BUTTON_LEFT then
    begin
      if Assigned(FGroup.Selected) then
        FGroup.Selected.Invert(Byte(FGroup.Selected.GetColor + 3));
      FGroup.Selected := Self;
      Invert(Byte(FColor + 3));
    end;
  end
  else if (not FInverted) and IsButtonPressed and IsButtonHandled(AAction.Details^.Button) then
  begin
    FInverted := True;
    Invert(Byte(FColor + 3));
  end;
  inherited MousePress(AAction);
end;

procedure TXcomImageButton.MouseRelease(AAction: TXcomAction);
begin
  if FInverted and IsButtonHandled(AAction.Details^.Button) then
  begin
    FInverted := False;
    Invert(Byte(FColor + 3));
  end;
  inherited MouseRelease(AAction);
end;

procedure TXcomImageButton.Toggle(APress: Boolean);
begin
  if FInverted <> APress then
  begin
    FInverted := not FInverted;
    Invert(Byte(FColor + 3));
  end;
end;

end.
