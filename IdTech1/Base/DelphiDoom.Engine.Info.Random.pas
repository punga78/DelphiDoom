//------------------------------------------------------------------------------
//
//  DelphiDoom is a source port of the game Doom and it is
//  based on original Linux Doom as published by "id Software"
//  Copyright (C) 1993-1996 by id Software, Inc.
//  Copyright (C) 2004-2022 by Jim Valavanis
//
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License
//  as published by the Free Software Foundation; either version 2
//  of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, inc., 59 Temple Place - Suite 330, Boston, MA
//  02111-1307, USA.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit DelphiDoom.Engine.Info.Random;

interface

uses
  DelphiDoom.Engine.Info.Intf,
  DelphiDoom.Info.Intf,
  DelphiDoom.Info.RandomMonsters;

type
  /// <summary>The monsters placed at random (info_rnd), on the table of the things of the game</summary>
  TEngineInfoRandom = class(TInterfacedObject, IEngineInfoRandom)
  strict private
    FMonsters: TInfoRandomMonsters;
  public
    constructor Create(const AMobjs: IInfoMobjSource; const ARules: IInfoRandomRules;
      const ARandom: IInfoRandom);
    destructor Destroy; override;
    procedure Initialize;
    procedure ShutDown;
    function SelectMonster(const AType: Integer): Integer;
    function IsMonster(const AType: Integer): Boolean;
  end;

implementation

{ TEngineInfoRandom }

constructor TEngineInfoRandom.Create(const AMobjs: IInfoMobjSource; const ARules: IInfoRandomRules;
  const ARandom: IInfoRandom);
begin
  inherited Create;
  FMonsters := TInfoRandomMonsters.Create(AMobjs, ARules, ARandom);
end;

destructor TEngineInfoRandom.Destroy;
begin
  FMonsters.Free;
  inherited Destroy;
end;

procedure TEngineInfoRandom.Initialize;
begin
  FMonsters.Initialize;
end;

procedure TEngineInfoRandom.ShutDown;
begin
  FMonsters.Shutdown;
end;

function TEngineInfoRandom.SelectMonster(const AType: Integer): Integer;
begin
  Result := FMonsters.Select(AType);
end;

function TEngineInfoRandom.IsMonster(const AType: Integer): Boolean;
begin
  Result := FMonsters.IsMonster(AType);
end;

end.
