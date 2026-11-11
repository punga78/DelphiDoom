{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom basescape library - MiniBaseView of OpenXcom (the little    }
{  maps of the bases at the top right of the basescape)                         }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBasescape.MiniBaseView;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.XcomSurface.Surface, DelphiDoom.XcomSurface.SurfaceSet,
  DelphiDoom.XcomMod.Ruleset, DelphiDoom.XcomSave.Base, DelphiDoom.XcomEngine.Action,
  DelphiDoom.XcomEngine.InteractiveSurface;

type
  /// <summary>
  ///   The eight small maps (one for each base that exists) with the selected one marked: each facility is a little
  ///   box, green when it is built and red while it is under construction. The bases and the sprites are not owned
  /// </summary>
  TXcomMiniBaseView = class(TXcomInteractiveSurface)
  public
    const
      MAX_BASES = 8;
      MINI_SIZE = 14;
  strict private
    FRuleset: TXcomRuleset;
    FBases: TObjectList<TXcomBase>;
    FTexture: TXcomSurfaceSet;
    FBase: Integer;
    FHoverBase: Integer;
    FRed: Byte;
    FGreen: Byte;
  protected
    procedure MouseOver(AAction: TXcomAction); override;
  public
    constructor Create(ARuleset: TXcomRuleset; AWidth, AHeight, AX, AY: Integer);
    procedure SetBases(ABases: TObjectList<TXcomBase>);
    procedure SetTexture(ATexture: TXcomSurfaceSet);
    procedure SetSelectedBase(ABase: Integer);
    /// <summary>The number of the base under the mouse (the last one the mouse was over)</summary>
    function HoveredBase: Integer;
    procedure SetColor(AColor: Byte); override;
    procedure SetSecondaryColor(AColor: Byte); override;
    procedure Draw; override;
  end;

implementation

uses
  System.Math, DelphiDoom.XcomMod.RuleBaseFacility, DelphiDoom.XcomSave.BaseFacility;

constructor TXcomMiniBaseView.Create(ARuleset: TXcomRuleset; AWidth, AHeight, AX, AY: Integer);
begin
  inherited Create(AWidth, AHeight, AX, AY);
  FRuleset := ARuleset;
end;

procedure TXcomMiniBaseView.SetBases(ABases: TObjectList<TXcomBase>);
begin
  FBases := ABases;
  Redraw := True;
end;

procedure TXcomMiniBaseView.SetTexture(ATexture: TXcomSurfaceSet);
begin
  FTexture := ATexture;
end;

procedure TXcomMiniBaseView.SetSelectedBase(ABase: Integer);
begin
  FBase := ABase;
  Redraw := True;
end;

function TXcomMiniBaseView.HoveredBase: Integer;
begin
  Result := FHoverBase;
end;

procedure TXcomMiniBaseView.SetColor(AColor: Byte);
begin
  FGreen := AColor;
end;

procedure TXcomMiniBaseView.SetSecondaryColor(AColor: Byte);
begin
  FRed := AColor;
end;

procedure TXcomMiniBaseView.Draw;
var
  LIndex, LColor, LSize, LX, LY: Integer;
  LFacility: TXcomBaseFacility;
  LRule: TXcomRuleBaseFacility;
  LFrame: TXcomSurface;
begin
  inherited Draw;
  for LIndex := 0 to MAX_BASES - 1 do
  begin
    if LIndex = FBase then
      DrawRect(LIndex * (MINI_SIZE + 2), 0, MINI_SIZE + 2, MINI_SIZE + 2, 1);
    LFrame := FTexture.GetFrame(41);
    LFrame.X := LIndex * (MINI_SIZE + 2);
    LFrame.Y := 0;
    LFrame.Blit(Self);
    if LIndex < FBases.Count then
      for LFacility in FBases[LIndex].Facilities do
      begin
        if LFacility.BuildTime = 0 then
          LColor := FGreen
        else
          LColor := FRed;
        LRule := FRuleset.Facilities.Find(LFacility.Rules.FacilityType);
        LSize := LRule.Size * 2;
        LX := LIndex * (MINI_SIZE + 2) + 2 + LFacility.X * 2;
        LY := 2 + LFacility.Y * 2;
        DrawRect(LX, LY, LSize, LSize, Byte(LColor + 3));
        Inc(LX);
        Inc(LY);
        Dec(LSize);
        DrawRect(LX, LY, LSize, LSize, Byte(LColor + 5));
        Dec(LX);
        Dec(LY);
        DrawRect(LX, LY, LSize, LSize, Byte(LColor + 2));
        Inc(LX);
        Inc(LY);
        Dec(LSize);
        DrawRect(LX, LY, LSize, LSize, Byte(LColor + 3));
        Dec(LX);
        Dec(LY);
        SetPixel(LX, LY, Byte(LColor + 1));
      end;
  end;
end;

procedure TXcomMiniBaseView.MouseOver(AAction: TXcomAction);
begin
  FHoverBase := Floor(AAction.RelativeXMouse / ((MINI_SIZE + 2) * AAction.XScale));
  inherited MouseOver(AAction);
end;

end.
