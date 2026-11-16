{******************************************************************************}
{                                                                              }
{  DelphiDoom: heads-up display library - the factory: the composition root    }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Hud.Factory;

interface

uses
  DelphiDoom.Hud.Types, DelphiDoom.Hud.Intf, DelphiDoom.Hud.View, DelphiDoom.Hud.Layout;

type
  /// <summary>The only place that knows the classes behind the contracts of the heads-up display</summary>
  THudFactory = class
  public
    /// <summary>
    ///   The heads-up display of a game: the model that the routines HU_* call and, through the
    ///   same object, the view the drawing reads
    /// </summary>
    class procedure CreateHeadsUp(const ARules: THudRules; const AFlags: IHudFlags;
      const APlayers: IHudPlayers; const AMessages: IHudPlayerMessage;
      const ASettings: IHudSettings; const ASound: IHudChatSound; const AEcho: IHudEcho;
      out AHeadsUp: IHeadsUp; out AView: IHudView); static;
    /// <summary>A list of glyphs for the drawing to fill and to read</summary>
    class function CreateLayout: THudLayout; static;
  end;

implementation

uses
  DelphiDoom.Hud.HeadsUp;

{ THudFactory }

class procedure THudFactory.CreateHeadsUp(const ARules: THudRules; const AFlags: IHudFlags;
  const APlayers: IHudPlayers; const AMessages: IHudPlayerMessage; const ASettings: IHudSettings;
  const ASound: IHudChatSound; const AEcho: IHudEcho; out AHeadsUp: IHeadsUp; out AView: IHudView);
var
  LHeadsUp: THeadsUp;
begin
  LHeadsUp := THeadsUp.Create(ARules, AFlags, APlayers, AMessages, ASettings, ASound, AEcho);
  AHeadsUp := LHeadsUp;
  AView := LHeadsUp;
end;

class function THudFactory.CreateLayout: THudLayout;
begin
  Result := THudLayout.Create;
end;

end.
