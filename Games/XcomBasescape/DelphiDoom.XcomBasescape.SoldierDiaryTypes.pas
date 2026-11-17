{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom basescape library - the types that the screens of the      }
{  soldier diary share Derived from OpenXcom (the OpenXcom Developers),        }
{  available under the GNU General Public License, version 3 or (at your       }
{  option) any later version; see Games\XcomFormats\README.md for the license  }
{  of this unit                                                                }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBasescape.SoldierDiaryTypes;

interface

type
  /// <summary>SoldierDiaryDisplay: what the performance screen shows (combat, missions or awards)</summary>
  TXcomDiaryDisplay = (ddKills, ddMissions, ddCommendations);

  /// <summary>
  ///   What a diary screen tells the one that opened it when the player changes soldier (the C++ passes the
  ///   opening state and calls setSoldierId on it)
  /// </summary>
  TXcomSoldierIdChanged = reference to procedure(ASoldierId: Integer);

implementation

end.
