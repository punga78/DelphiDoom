{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom engine library - the sounds of the widgets of the           }
{  interface (the static TextButton::soundPress and Window::soundPopup of       }
{  OpenXcom)                                                                    }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomEngine.UiSounds.Intf;

interface

type
  /// <summary>
  ///   What a widget asks to make its sound. The C++ keeps the sounds in static members that Mod fills when the
  ///   data is loaded; here a state gives this to the widgets it adds
  /// </summary>
  IXcomUiSounds = interface
    ['{5D0E3A91-7C46-4B28-9F1D-A6B37E20C854}']
    /// <summary>TextButton::soundPress->play: the click of a button</summary>
    procedure PlayButtonPress;
    /// <summary>Window::soundPopup[RNG::seedless(0, 2)]->play: one of the three sounds of a window that opens</summary>
    procedure PlayWindowPopup;
  end;

implementation

end.
