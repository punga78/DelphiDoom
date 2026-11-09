{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom interface library - Bar of OpenXcom                         }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomUi.Bar;

interface

uses
  System.SysUtils, DelphiDoom.XcomSurface.Types, DelphiDoom.XcomEngine.Widget, DelphiDoom.XcomUi.Math;

type
  /// <summary>A bordered bar filled according to two values (a maximum, a current value and a second one)</summary>
  TXcomBar = class(TXcomWidget)
  strict private
    FColor: Byte;
    FColor2: Byte;
    FBorderColor: Byte;
    FScale: Double;
    FMax: Double;
    FValue: Double;
    FValue2: Double;
    FSecondOnTop: Boolean;
  public
    constructor Create(AWidth, AHeight: Integer; AX: Integer = 0; AY: Integer = 0);
    procedure SetColor(AColor: Byte); override;
    function GetColor: Byte; override;
    procedure SetSecondaryColor(AColor: Byte); override;
    function GetSecondaryColor: Byte;
    procedure SetBorderColor(AColor: Byte); override;
    procedure SetScale(AScale: Double);
    function GetScale: Double;
    procedure SetMax(AMax: Double);
    function GetMax: Double;
    /// <summary>A negative value is stored as 0</summary>
    procedure SetValue(AValue: Double);
    function GetValue: Double;
    procedure SetValue2(AValue: Double);
    function GetValue2: Double;
    procedure SetSecondValueOnTop(AOnTop: Boolean);
    procedure Draw; override;
  end;

implementation

constructor TXcomBar.Create(AWidth, AHeight, AX, AY: Integer);
begin
  inherited Create(AWidth, AHeight, AX, AY);
  FSecondOnTop := True;
end;

procedure TXcomBar.SetColor(AColor: Byte);
begin
  FColor := AColor;
  Redraw := True;
end;

function TXcomBar.GetColor: Byte;
begin
  Result := FColor;
end;

procedure TXcomBar.SetSecondaryColor(AColor: Byte);
begin
  FColor2 := AColor;
  Redraw := True;
end;

function TXcomBar.GetSecondaryColor: Byte;
begin
  Result := FColor2;
end;

procedure TXcomBar.SetBorderColor(AColor: Byte);
begin
  FBorderColor := AColor;
end;

procedure TXcomBar.SetScale(AScale: Double);
begin
  FScale := AScale;
  Redraw := True;
end;

function TXcomBar.GetScale: Double;
begin
  Result := FScale;
end;

procedure TXcomBar.SetMax(AMax: Double);
begin
  FMax := AMax;
  Redraw := True;
end;

function TXcomBar.GetMax: Double;
begin
  Result := FMax;
end;

procedure TXcomBar.SetValue(AValue: Double);
begin
  if AValue < 0.0 then
    FValue := 0.0
  else
    FValue := AValue;
  Redraw := True;
end;

function TXcomBar.GetValue: Double;
begin
  Result := FValue;
end;

procedure TXcomBar.SetValue2(AValue: Double);
begin
  if AValue < 0.0 then
    FValue2 := 0.0
  else
    FValue2 := AValue;
  Redraw := True;
end;

function TXcomBar.GetValue2: Double;
begin
  Result := FValue2;
end;

procedure TXcomBar.SetSecondValueOnTop(AOnTop: Boolean);
begin
  FSecondOnTop := AOnTop;
end;

procedure TXcomBar.Draw;
var
  LW: Integer;
  LH: Integer;
begin
  inherited Draw;
  LW := (TXcomMath.ToWord(FScale * FMax) + 1) and $FFFF;
  LH := Height;
  if FBorderColor <> 0 then
    DrawRect(TXcomRect.Make(0, 0, LW, LH), FBorderColor)
  else
    DrawRect(TXcomRect.Make(0, 0, LW, LH), Byte(FColor + 4));
  LW := (LW - 1) and $FFFF;
  LH := (LH - 2) and $FFFF;
  DrawRect(TXcomRect.Make(0, 1, LW, LH), 0);
  if FSecondOnTop then
  begin
    DrawRect(TXcomRect.Make(0, 1, TXcomMath.ToWord(FScale * FValue), LH), FColor);
    DrawRect(TXcomRect.Make(0, 1, TXcomMath.ToWord(FScale * FValue2), LH), FColor2);
  end
  else
  begin
    DrawRect(TXcomRect.Make(0, 1, TXcomMath.ToWord(FScale * FValue2), LH), FColor2);
    DrawRect(TXcomRect.Make(0, 1, TXcomMath.ToWord(FScale * FValue), LH), FColor);
  end;
end;

end.
