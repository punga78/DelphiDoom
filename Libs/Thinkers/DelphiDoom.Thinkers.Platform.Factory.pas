{******************************************************************************}
{                                                                              }
{  DelphiDoom: thinkers library - the factory of the platforms                 }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Thinkers.Platform.Factory;

interface

uses
  DelphiDoom.MathCore.Intf,
  DelphiDoom.Thinkers.Platform.Types,
  DelphiDoom.Thinkers.Platform.Intf;

type
  /// <summary>The only place that knows the classes behind the interfaces of the platforms</summary>
  TPlatFactory = class
  public
    /// <summary>The classic platforms of a game, with the rules of the game</summary>
    class function CreateMachine(AGame: TPlatGame; const AHost: IPlatHost;
      const ASurroundings: IPlatSurroundings; const ARandom: IGameRandom): IPlatMachine; static;
    /// <summary>The scripted platforms (the same in every game)</summary>
    class function CreateUdmfMachine(const AHost: IPlatHost; const ASurroundings: IPlatSurroundings;
      const ARandom: IGameRandom): IUdmfPlatMachine; static;
  end;

implementation

uses
  DelphiDoom.Thinkers.Platform.Games,
  DelphiDoom.Thinkers.Platform.Machine,
  DelphiDoom.Thinkers.Platform.UdmfMachine;

{ TPlatFactory }

class function TPlatFactory.CreateMachine(AGame: TPlatGame; const AHost: IPlatHost;
  const ASurroundings: IPlatSurroundings; const ARandom: IGameRandom): IPlatMachine;
begin
  Result := TPlatMachine.Create(AHost, ASurroundings, ARandom, TPlatGames.ProfileOf(AGame));
end;

class function TPlatFactory.CreateUdmfMachine(const AHost: IPlatHost;
  const ASurroundings: IPlatSurroundings; const ARandom: IGameRandom): IUdmfPlatMachine;
begin
  Result := TUdmfPlatMachine.Create(AHost, ASurroundings, ARandom);
end;

end.
