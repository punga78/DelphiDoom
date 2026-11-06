{******************************************************************************}
{                                                                              }
{  DelphiDoom: Dehacked library - the factory: the composition root            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Dehacked.Factory;

interface

uses
  DelphiDoom.Logging.Intf, DelphiDoom.Dehacked.Intf, DelphiDoom.Dehacked.Games;

type
  /// <summary>The only place that knows the classes behind the Dehacked contracts</summary>
  TDehackedFactory = class
  public
    /// <summary>The parser of the patches of a game</summary>
    /// <param name="ALog">May be nil</param>
    class function CreateParser(AGame: TDehackedGame; const ALog: ILog): IDehackedParser; overload; static;
    /// <summary>A parser on any profile (a different game, or one for the tests)</summary>
    class function CreateParser(const AProfile: IDehackedProfile): IDehackedParser; overload; static;
  end;

implementation

uses
  DelphiDoom.Dehacked.Parser;

{ TDehackedFactory }

class function TDehackedFactory.CreateParser(AGame: TDehackedGame; const ALog: ILog): IDehackedParser;
begin
  Result := TDehackedParser.Create(TDehackedGames.CreateProfile(AGame, ALog));
end;

class function TDehackedFactory.CreateParser(const AProfile: IDehackedProfile): IDehackedParser;
begin
  Result := TDehackedParser.Create(AProfile);
end;

end.
