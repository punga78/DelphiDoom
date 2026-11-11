{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom battlescape states library - the way into a battle: the     }
{  one of a saved game that was just loaded (LoadGameState)                     }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBattleStates.Launcher;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.State, DelphiDoom.XcomBattleStates.Screens.Intf;

type
  /// <summary>Starts the screen of a battle on the game of a host</summary>
  TXcomBattleLauncher = class
  public
    /// <summary>
    ///   The battle in progress of the saved game of the host goes on: the battlescape is pushed over the states of
    ///   the host. Nothing happens when the saved game has no battle
    /// </summary>
    /// <param name="AScreens">The screens the battlescape opens; nil: the ones of the library</param>
    /// <param name="AAudio">The sounds of the battle; nil: none</param>
    class procedure Resume(AHost: TXcomStateHost; const AScreens: IXcomBattleScreens = nil;
      const AAudio: IXcomBattleAudio = nil); static;
  end;

implementation

uses
  DelphiDoom.XcomBattleStates.Session.Intf, DelphiDoom.XcomBattleStates.Factory,
  DelphiDoom.XcomBattleStates.Screens;

class procedure TXcomBattleLauncher.Resume(AHost: TXcomStateHost; const AScreens: IXcomBattleScreens;
  const AAudio: IXcomBattleAudio);
var
  LSession: IXcomBattleSession;
  LScreens: IXcomBattleScreens;
begin
  LSession := TXcomBattleFactory.LoadSession(AHost);
  if not Assigned(LSession) then
    Exit;
  LScreens := AScreens;
  if not Assigned(LScreens) then
    LScreens := TXcomBattleScreens.Create;
  AHost.PushState(TXcomBattleFactory.CreateBattlescape(AHost, LSession, LScreens, AAudio));
end;

end.
