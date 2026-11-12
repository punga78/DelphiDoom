{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom interface library - ArrowButton of OpenXcom                 }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomUi.ArrowButton;

interface

uses
  DelphiDoom.Clock.Intf,
  System.SysUtils, DelphiDoom.XcomSurface.Types, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Intf,
  DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.Timer, DelphiDoom.XcomUi.Types,
  DelphiDoom.XcomUi.ScrollableList, DelphiDoom.XcomUi.ImageButton;

type
  /// <summary>
  ///   A button with an arrow on it. When it is tied to a list it scrolls it: while the left button is down every
  ///   50 ms, to the end with the right button, by the wheel with the wheel
  /// </summary>
  TXcomArrowButton = class(TXcomImageButton)
  strict private
    FShape: TXcomArrowShape;
    FList: IXcomScrollableList;
    FTimer: TXcomTimer;
    procedure Scroll;
    procedure Fill(AX, AY, AWidth, AHeight: Integer; AColor: Integer);
  protected
    procedure MousePress(AAction: TXcomAction); override;
    procedure MouseRelease(AAction: TXcomAction); override;
    procedure MouseClick(AAction: TXcomAction); override;
  public
    constructor Create(const AClock: IClock; AShape: TXcomArrowShape; AWidth, AHeight: Integer; AX: Integer = 0;
      AY: Integer = 0);
    destructor Destroy; override;
    function IsButtonHandled(AButton: Integer = 0): Boolean; override;
    procedure SetColor(AColor: Byte); override;
    procedure SetShape(AShape: TXcomArrowShape);
    /// <summary>The list this button scrolls (not owned)</summary>
    procedure SetTextList(const AList: IXcomScrollableList);
    procedure Think; override;
    procedure Draw; override;
  end;

implementation

constructor TXcomArrowButton.Create(const AClock: IClock; AShape: TXcomArrowShape; AWidth, AHeight, AX,
  AY: Integer);
begin
  inherited Create(AWidth, AHeight, AX, AY);
  FShape := AShape;
  FTimer := TXcomTimer.Create(AClock, 50);
  FTimer.OnTimerSurface(
    procedure
    begin
      Scroll;
    end);
end;

destructor TXcomArrowButton.Destroy;
begin
  FTimer.Free;
  inherited Destroy;
end;

function TXcomArrowButton.IsButtonHandled(AButton: Integer): Boolean;
begin
  if Assigned(FList) then
    Result := (AButton = XCOM_BUTTON_LEFT) or (AButton = XCOM_BUTTON_RIGHT)
  else
    Result := inherited IsButtonHandled(AButton);
end;

procedure TXcomArrowButton.SetColor(AColor: Byte);
begin
  inherited SetColor(AColor);
  Redraw := True;
end;

procedure TXcomArrowButton.SetShape(AShape: TXcomArrowShape);
begin
  FShape := AShape;
  Redraw := True;
end;

procedure TXcomArrowButton.SetTextList(const AList: IXcomScrollableList);
begin
  FList := AList;
end;

procedure TXcomArrowButton.Fill(AX, AY, AWidth, AHeight: Integer; AColor: Integer);
begin
  DrawRect(TXcomRect.Make(AX, AY, AWidth, AHeight), Byte(AColor));
end;

procedure TXcomArrowButton.Draw;
var
  LColor: Integer;
  LBase: Integer;
  LX: Integer;
  LY: Integer;
  LW: Integer;
  LH: Integer;
begin
  inherited Draw;
  LColor := GetColor;
  LW := Width - 1;
  LH := Height - 1;
  Fill(0, 0, LW, LH, LColor + 2);
  Fill(1, 1, LW, LH, LColor + 5);
  Fill(1, 1, LW - 1, LH - 1, LColor + 4);
  SetPixel(0, 0, Byte(LColor + 1));
  SetPixel(0, Height - 1, Byte(LColor + 4));
  SetPixel(Width - 1, 0, Byte(LColor + 4));
  LBase := LColor + 1;
  case FShape of
    arBigUp:
      begin
        Fill(5, 8, 3, 3, LBase);
        LX := 2;
        LY := 7;
        LW := 9;
        while LW > 1 do
        begin
          Fill(LX, LY, LW, 1, LBase);
          Inc(LX);
          Dec(LY);
          Dec(LW, 2);
        end;
        Fill(LX, LY, LW, 1, LBase);
      end;
    arBigDown:
      begin
        Fill(5, 3, 3, 3, LBase);
        LX := 2;
        LY := 6;
        LW := 9;
        while LW > 1 do
        begin
          Fill(LX, LY, LW, 1, LBase);
          Inc(LX);
          Inc(LY);
          Dec(LW, 2);
        end;
        Fill(LX, LY, LW, 1, LBase);
      end;
    arSmallUp:
      begin
        LX := 1;
        LY := 5;
        LW := 9;
        while LW > 1 do
        begin
          Fill(LX, LY, LW, 1, LBase + 2);
          Inc(LX);
          Dec(LY);
          Dec(LW, 2);
        end;
        Fill(LX, LY, LW, 1, LBase + 2);
        LX := 2;
        LY := 5;
        LW := 7;
        while LW > 1 do
        begin
          Fill(LX, LY, LW, 1, LBase);
          Inc(LX);
          Dec(LY);
          Dec(LW, 2);
        end;
        Fill(LX, LY, LW, 1, LBase);
      end;
    arSmallDown:
      begin
        LX := 1;
        LY := 2;
        LW := 9;
        while LW > 1 do
        begin
          Fill(LX, LY, LW, 1, LBase + 2);
          Inc(LX);
          Inc(LY);
          Dec(LW, 2);
        end;
        Fill(LX, LY, LW, 1, LBase + 2);
        LX := 2;
        LY := 2;
        LW := 7;
        while LW > 1 do
        begin
          Fill(LX, LY, LW, 1, LBase);
          Inc(LX);
          Inc(LY);
          Dec(LW, 2);
        end;
        Fill(LX, LY, LW, 1, LBase);
      end;
    arSmallLeft:
      begin
        LX := 2;
        LY := 4;
        LH := 1;
        while LH < 5 do
        begin
          Fill(LX, LY, 2, LH, LBase + 2);
          Inc(LX, 2);
          Dec(LY);
          Inc(LH, 2);
        end;
        Fill(LX, LY, 1, LH, LBase + 2);
        LX := 3;
        LY := 4;
        LH := 1;
        while LH < 5 do
        begin
          Fill(LX, LY, 2, LH, LBase);
          Inc(LX, 2);
          Dec(LY);
          Inc(LH, 2);
        end;
        Fill(LX, LY, 1, LH, LBase);
      end;
    arSmallRight:
      begin
        LX := 7;
        LY := 4;
        LH := 1;
        while LH < 5 do
        begin
          Fill(LX, LY, 2, LH, LBase + 2);
          Dec(LX, 2);
          Dec(LY);
          Inc(LH, 2);
        end;
        Inc(LX);
        Fill(LX, LY, 1, LH, LBase + 2);
        LX := 6;
        LY := 4;
        LH := 1;
        while LH < 5 do
        begin
          Fill(LX, LY, 2, LH, LBase);
          Dec(LX, 2);
          Dec(LY);
          Inc(LH, 2);
        end;
        Inc(LX);
        Fill(LX, LY, 1, LH, LBase);
      end;
  end;
end;

procedure TXcomArrowButton.Think;
begin
  FTimer.Think(False, True);
end;

procedure TXcomArrowButton.Scroll;
begin
  if not Assigned(FList) then
    Exit;
  if FShape = arBigUp then
    FList.ScrollUp(False)
  else if FShape = arBigDown then
    FList.ScrollDown(False);
end;

procedure TXcomArrowButton.MousePress(AAction: TXcomAction);
begin
  inherited MousePress(AAction);
  if Assigned(FList) then
  begin
    if AAction.Details^.Button = XCOM_BUTTON_LEFT then
      FTimer.Start
    else if AAction.Details^.Button = XCOM_BUTTON_WHEELUP then
      FList.ScrollUp(False, True)
    else if AAction.Details^.Button = XCOM_BUTTON_WHEELDOWN then
      FList.ScrollDown(False, True);
  end;
end;

procedure TXcomArrowButton.MouseRelease(AAction: TXcomAction);
begin
  inherited MouseRelease(AAction);
  if Assigned(FList) and (AAction.Details^.Button = XCOM_BUTTON_LEFT) then
    FTimer.Stop;
end;

procedure TXcomArrowButton.MouseClick(AAction: TXcomAction);
begin
  inherited MouseClick(AAction);
  if Assigned(FList) and (AAction.Details^.Button = XCOM_BUTTON_RIGHT) then
  begin
    if FShape = arBigUp then
      FList.ScrollUp(True)
    else if FShape = arBigDown then
      FList.ScrollDown(True);
  end;
end;

end.
