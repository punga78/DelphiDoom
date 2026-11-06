{******************************************************************************}
{                                                                              }
{  DelphiDoom: math core library - the factory: the composition root           }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MathCore.Factory;

interface

uses
  DelphiDoom.MathCore.Intf;

type
  /// <summary>The only place that knows the classes behind the interfaces of the math core</summary>
  TMathCoreFactory = class
  public
    /// <summary>The random of the game, with the runtime generator for the unpredictable numbers</summary>
    class function CreateGameRandom: IGameRandom; overload; static;
    /// <summary>The random of the game on any source of unpredictable numbers (a fake one, in the tests)</summary>
    class function CreateGameRandom(const AEntropy: IEntropySource): IGameRandom; overload; static;
    /// <summary>An empty table of hashes of texts</summary>
    class function CreateStringHashTable: IStringHashTable; static;
  end;

implementation

uses
  DelphiDoom.MathCore.GameRandom, DelphiDoom.MathCore.StringHashTable,
  DelphiDoom.MathCore.SystemEntropySource;

{ TMathCoreFactory }

class function TMathCoreFactory.CreateGameRandom: IGameRandom;
begin
  Result := TGameRandom.Create(TSystemEntropySource.Create(True));
end;

class function TMathCoreFactory.CreateGameRandom(const AEntropy: IEntropySource): IGameRandom;
begin
  Result := TGameRandom.Create(AEntropy);
end;

class function TMathCoreFactory.CreateStringHashTable: IStringHashTable;
begin
  Result := TStringHashTable.Create;
end;

end.
