{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom menu library - shared types of the options screens          }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomMenu.OptionsTypes;

interface

type
  /// <summary>OptionsOrigin: where the options screens were opened from</summary>
  TXcomOptionsOrigin = (ooMenu, ooGeoscape, ooBattlescape);

  /// <summary>The categories of the options (the buttons on the left of every options screen)</summary>
  TXcomOptionsCategory = (ocVideo, ocAudio, ocControls, ocGeoscape, ocBattlescape, ocAdvanced, ocFolders);

implementation

end.
