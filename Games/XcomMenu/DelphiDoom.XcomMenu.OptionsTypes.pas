{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom menu library - shared types of the options screens         }
{  Derived from OpenXcom (the OpenXcom Developers), available under the GNU    }
{  General Public License, version 3 or (at your option) any later version;    }
{  see Games\XcomFormats\README.md for the license of this unit                }
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
