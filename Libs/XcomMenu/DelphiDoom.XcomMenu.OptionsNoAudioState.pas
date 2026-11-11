{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom menu library - OptionsNoAudioState of OpenXcom (the         }
{  audio options screen when the game runs without audio)                       }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomMenu.OptionsNoAudioState;

interface

uses
  DelphiDoom.XcomEngine.State, DelphiDoom.XcomUi.Text, DelphiDoom.XcomMenu.OptionsTypes,
  DelphiDoom.XcomMenu.OptionsNavigator.Intf, DelphiDoom.XcomMenu.OptionsBaseState;

type
  /// <summary>
  ///   The audio category of the options when Options::mute is on: the buttons of the categories and a message that
  ///   says there is no audio hardware
  /// </summary>
  TXcomOptionsNoAudioState = class(TXcomOptionsBaseState)
  strict private
    FTxtError: TXcomText;
  public
    constructor Create(AHost: TXcomStateHost; AOrigin: TXcomOptionsOrigin; const ANavigator: IXcomOptionsNavigator);
  end;

implementation

uses
  DelphiDoom.XcomUi.Types;

constructor TXcomOptionsNoAudioState.Create(AHost: TXcomStateHost; AOrigin: TXcomOptionsOrigin;
  const ANavigator: IXcomOptionsNavigator);
begin
  inherited Create(AHost, AOrigin, ANavigator);
  SetCategory(FBtnAudio);
  FTxtError := TXcomText.Create(218, 136, 94, 8);
  Add(FTxtError, 'text', 'audioMenu');
  CenterAllSurfaces;
  FTxtError.SetAlign(haCenter);
  FTxtError.SetVerticalAlign(vaMiddle);
  FTxtError.SetBig;
  FTxtError.SetWordWrap(True);
  FTxtError.SetText(Tr('STR_NO_AUDIO_HARDWARE_DETECTED'));
end;

end.
