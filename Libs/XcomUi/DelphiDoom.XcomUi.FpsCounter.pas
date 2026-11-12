{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom interface library - FpsCounter of OpenXcom                  }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomUi.FpsCounter;

interface

uses
  DelphiDoom.Clock.Intf,
  System.SysUtils, System.Math, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Intf,
  DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.Timer, DelphiDoom.XcomEngine.InteractiveSurface,
  DelphiDoom.XcomUi.NumberText;

type
  /// <summary>The frames per second in the corner, shown or hidden with a key (F7 by default)</summary>
  TXcomFpsCounter = class(TXcomInteractiveSurface)
  strict private
    FText: TXcomNumberText;
    FTimer: TXcomTimer;
    FFrames: Integer;
    FToggleKey: Integer;
    procedure Update;
  public
    constructor Create(const AClock: IClock; AWidth, AHeight, AX, AY: Integer; AVisible: Boolean;
      AToggleKey: Integer);
    destructor Destroy; override;
    procedure SetPalette(AColors: PXcomColor; AFirst: Integer = 0; ACount: Integer = 256); override;
    procedure SetColor(AColor: Byte); override;
    procedure Handle(AAction: TXcomAction); override;
    procedure Think; override;
    procedure Draw; override;
    procedure FrameAdded; override;
  end;

implementation

constructor TXcomFpsCounter.Create(const AClock: IClock; AWidth, AHeight, AX, AY: Integer; AVisible: Boolean;
  AToggleKey: Integer);
begin
  inherited Create(AWidth, AHeight, AX, AY);
  Visible := AVisible;
  FToggleKey := AToggleKey;
  FTimer := TXcomTimer.Create(AClock, 1000);
  FTimer.OnTimerSurface(
    procedure
    begin
      Update;
    end);
  FTimer.Start;
  FText := TXcomNumberText.Create(AWidth, AHeight, AX, AY);
end;

destructor TXcomFpsCounter.Destroy;
begin
  FText.Free;
  FTimer.Free;
  inherited Destroy;
end;

procedure TXcomFpsCounter.SetPalette(AColors: PXcomColor; AFirst, ACount: Integer);
begin
  inherited SetPalette(AColors, AFirst, ACount);
  FText.SetPalette(AColors, AFirst, ACount);
end;

procedure TXcomFpsCounter.SetColor(AColor: Byte);
begin
  FText.SetColor(AColor);
end;

procedure TXcomFpsCounter.Handle(AAction: TXcomAction);
begin
  if (AAction.Details^.Kind = ekKeyDown) and (AAction.Details^.Key = FToggleKey) then
    Visible := not Visible;
end;

procedure TXcomFpsCounter.Think;
begin
  FTimer.Think(False, True);
end;

procedure TXcomFpsCounter.Update;
var
  LTime: Cardinal;
begin
  LTime := FTimer.Time;
  if LTime = 0 then
    FText.SetValue(0)
  else
    FText.SetValue(Cardinal(Floor(FFrames / LTime * 1000)));
  FFrames := 0;
  Redraw := True;
end;

procedure TXcomFpsCounter.Draw;
begin
  inherited Draw;
  FText.Blit(Self);
end;

procedure TXcomFpsCounter.FrameAdded;
begin
  Inc(FFrames);
end;

end.
