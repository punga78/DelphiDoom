{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom engine library - the sounds of the widgets played through   }
{  the host of the states (GEO.CAT, the constants buttonPress and windowPopup)  }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomEngine.HostUiSounds;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.State, DelphiDoom.XcomEngine.UiSounds.Intf;

type
  /// <summary>Gives a number from 0 to ACount - 1 (RNG::seedless: not the generator of the game)</summary>
  TXcomUiRandom = reference to function(ACount: Integer): Integer;

  /// <summary>
  ///   IXcomUiSounds over a host: Mod::loadExtraResources takes the sounds from GEO.CAT at the indexes
  ///   Mod::BUTTON_PRESS (constant buttonPress, 0) and Mod::WINDOW_POPUP (constant windowPopup, 1, 2, 3), and
  ///   they play at the volume of the interface. The host is not owned and must outlive this object
  /// </summary>
  TXcomHostUiSounds = class(TInterfacedObject, IXcomUiSounds)
  strict private
    FHost: TXcomStateHost;
    FRandom: TXcomUiRandom;
  public
    /// <summary>Without ARandom the popup sound is chosen with System.Random</summary>
    constructor Create(AHost: TXcomStateHost; const ARandom: TXcomUiRandom = nil);
    procedure PlayButtonPress;
    procedure PlayWindowPopup;
  end;

const
  XCOM_UI_SOUND_SET = 'GEO.CAT';
  XCOM_CONSTANT_BUTTON_PRESS = 'buttonPress';
  /// <summary>The three numbers of the list windowPopup of the constants are kept as windowPopup.0 .. windowPopup.2</summary>
  XCOM_CONSTANT_WINDOW_POPUP = 'windowPopup.';
  XCOM_WINDOW_POPUP_SOUNDS = 3;

implementation

constructor TXcomHostUiSounds.Create(AHost: TXcomStateHost; const ARandom: TXcomUiRandom);
begin
  inherited Create;
  FHost := AHost;
  FRandom := ARandom;
end;

procedure TXcomHostUiSounds.PlayButtonPress;
begin
  if FHost.Resources = nil then
    Exit;
  FHost.PlaySound(XCOM_UI_SOUND_SET, FHost.Resources.Constant(XCOM_CONSTANT_BUTTON_PRESS, 0), True);
end;

procedure TXcomHostUiSounds.PlayWindowPopup;
var
  LSound: Integer;
begin
  if FHost.Resources = nil then
    Exit;
  if Assigned(FRandom) then
    LSound := FRandom(XCOM_WINDOW_POPUP_SOUNDS)
  else
    LSound := Random(XCOM_WINDOW_POPUP_SOUNDS);
  FHost.PlaySound(XCOM_UI_SOUND_SET,
    FHost.Resources.Constant(XCOM_CONSTANT_WINDOW_POPUP + IntToStr(LSound), LSound + 1), True);
end;

end.
