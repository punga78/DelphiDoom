{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom geoscape library - the rotate and zoom buttons that the     }
{  screens over the globe add (SelectDestinationState, BuildNewBaseState...)    }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomGeoscape.GlobeControls;

interface

uses
  DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.State,
  DelphiDoom.XcomEngine.InteractiveSurface, DelphiDoom.XcomGeoscape.Globe;

type
  /// <summary>
  ///   The six invisible buttons over the picture of the globe controls (rotate left, right, up, down, zoom in and
  ///   out, with their keys): they are created and added to a state, which owns them; the globe is not owned
  /// </summary>
  TXcomGlobeControls = class
  strict private
    FGlobe: TXcomGlobe;
    procedure Hold(ASurface: TXcomInteractiveSurface; AKey: Integer; const APress, ARelease: TXcomActionHandler);
  public
    /// <param name="AState">The state that owns the buttons</param>
    /// <param name="AGlobe">The globe they move (not owned)</param>
    constructor Create(AState: TXcomState; AGlobe: TXcomGlobe; ADX, ADY: Integer);
  end;

implementation

uses
  DelphiDoom.XcomGeoscape.Keys;

{ TXcomGlobeControls }

constructor TXcomGlobeControls.Create(AState: TXcomState; AGlobe: TXcomGlobe; ADX, ADY: Integer);
var
  LLeft, LRight, LUp, LDown, LZoomIn, LZoomOut: TXcomInteractiveSurface;
begin
  inherited Create;
  FGlobe := AGlobe;
  LLeft := TXcomInteractiveSurface.Create(12, 10, 259 + ADX * 2, 176 + ADY);
  LRight := TXcomInteractiveSurface.Create(12, 10, 283 + ADX * 2, 176 + ADY);
  LUp := TXcomInteractiveSurface.Create(13, 12, 271 + ADX * 2, 162 + ADY);
  LDown := TXcomInteractiveSurface.Create(13, 12, 271 + ADX * 2, 187 + ADY);
  LZoomIn := TXcomInteractiveSurface.Create(23, 23, 295 + ADX * 2, 156 + ADY);
  LZoomOut := TXcomInteractiveSurface.Create(13, 17, 300 + ADX * 2, 182 + ADY);
  AState.Add(LLeft);
  AState.Add(LRight);
  AState.Add(LUp);
  AState.Add(LDown);
  AState.Add(LZoomIn);
  AState.Add(LZoomOut);
  Hold(LLeft, KEY_GEO_LEFT,
    procedure(AAction: TXcomAction)
    begin
      FGlobe.RotateLeft;
    end,
    procedure(AAction: TXcomAction)
    begin
      FGlobe.RotateStopLon;
    end);
  Hold(LRight, KEY_GEO_RIGHT,
    procedure(AAction: TXcomAction)
    begin
      FGlobe.RotateRight;
    end,
    procedure(AAction: TXcomAction)
    begin
      FGlobe.RotateStopLon;
    end);
  Hold(LUp, KEY_GEO_UP,
    procedure(AAction: TXcomAction)
    begin
      FGlobe.RotateUp;
    end,
    procedure(AAction: TXcomAction)
    begin
      FGlobe.RotateStopLat;
    end);
  Hold(LDown, KEY_GEO_DOWN,
    procedure(AAction: TXcomAction)
    begin
      FGlobe.RotateDown;
    end,
    procedure(AAction: TXcomAction)
    begin
      FGlobe.RotateStopLat;
    end);
  LZoomIn.OnMouseClick(
    procedure(AAction: TXcomAction)
    begin
      FGlobe.ZoomIn;
    end, XCOM_BUTTON_LEFT);
  LZoomIn.OnMouseClick(
    procedure(AAction: TXcomAction)
    begin
      FGlobe.ZoomMax;
    end, XCOM_BUTTON_RIGHT);
  LZoomIn.OnKeyboardPress(
    procedure(AAction: TXcomAction)
    begin
      FGlobe.ZoomIn;
    end, KEY_GEO_ZOOM_IN);
  LZoomOut.OnMouseClick(
    procedure(AAction: TXcomAction)
    begin
      FGlobe.ZoomOut;
    end, XCOM_BUTTON_LEFT);
  LZoomOut.OnMouseClick(
    procedure(AAction: TXcomAction)
    begin
      FGlobe.ZoomMin;
    end, XCOM_BUTTON_RIGHT);
  LZoomOut.OnKeyboardPress(
    procedure(AAction: TXcomAction)
    begin
      FGlobe.ZoomOut;
    end, KEY_GEO_ZOOM_OUT);
end;

procedure TXcomGlobeControls.Hold(ASurface: TXcomInteractiveSurface; AKey: Integer; const APress,
  ARelease: TXcomActionHandler);
begin
  ASurface.OnMousePress(APress);
  ASurface.OnMouseRelease(ARelease);
  ASurface.OnKeyboardPress(APress, AKey);
  ASurface.OnKeyboardRelease(ARelease, AKey);
  // the rotate buttons of the "classic" style
  ASurface.SetListButton;
end;

end.
