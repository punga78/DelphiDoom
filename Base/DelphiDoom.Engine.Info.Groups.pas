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

unit DelphiDoom.Engine.Info.Groups;

interface

uses
  DelphiDoom.Engine.Info.Intf,
  DelphiDoom.Info.GroupNames;

type
  /// <summary>
  ///   The names of the infighting, projectile and splash groups. The constants are the ones of
  ///   info_common; the projectile group of the barons exists only in Doom (the old {$IFDEF DOOM})
  /// </summary>
  TEngineInfoGroups = class(TInterfacedObject, IEngineInfoGroups)
  strict private
    FInfighting: TInfoGroupNames;
    FProjectile: TInfoGroupNames;
    FSplash: TInfoGroupNames;
  public
    constructor Create;
    destructor Destroy; override;
    function InfightingToText(const AValue: Integer): string;
    function InfightingToValue(const AText: string): Integer;
    function ProjectileToText(const AValue: Integer): string;
    function ProjectileToValue(const AText: string): Integer;
    function SplashToText(const AValue: Integer): string;
    function SplashToValue(const AText: string): Integer;
  end;

implementation

uses
  DelphiDoom.Engine.Info.ConstSink,
  DelphiDoom.Engine.Info.NameList,
  DelphiDoom.Info.Intf,
  DelphiDoom.Info.Types,
  info_common;

function Fixed(const AName: string; const AValue: Integer): TInfoGroupName;
begin
  Result.Name := AName;
  Result.Value := AValue;
end;

{ TEngineInfoGroups }

constructor TEngineInfoGroups.Create;
var
  LConsts: IInfoConstSink;
begin
  inherited Create;
  LConsts := TEngineInfoConstSink.Create;
  FInfighting := TInfoGroupNames.Create('IG_', IG_INVALID,
    [Fixed('IG_DEFAULT', IG_DEFAULT), Fixed('IG_INVALID', IG_INVALID)],
    TEngineInfoNameList.Create(igkInfighting), LConsts);
  FProjectile := TInfoGroupNames.Create('PG_', PG_GROUPLESS,
{$IFDEF DOOM}
    [Fixed('PG_GROUPLESS', PG_GROUPLESS), Fixed('PG_INVALID', PG_INVALID),
     Fixed('PG_DEFAULT', PG_DEFAULT), Fixed('PG_BARON', PG_BARON)],
{$ELSE}
    [Fixed('PG_GROUPLESS', PG_GROUPLESS), Fixed('PG_INVALID', PG_INVALID),
     Fixed('PG_DEFAULT', PG_DEFAULT)],
{$ENDIF}
    TEngineInfoNameList.Create(igkProjectile), LConsts);
  FSplash := TInfoGroupNames.Create('SG_', SG_INVALID,
    [Fixed('SG_DEFAULT', SG_DEFAULT), Fixed('SG_INVALID', SG_INVALID)],
    TEngineInfoNameList.Create(igkSplash), LConsts);
end;

destructor TEngineInfoGroups.Destroy;
begin
  FSplash.Free;
  FProjectile.Free;
  FInfighting.Free;
  inherited Destroy;
end;

function TEngineInfoGroups.InfightingToText(const AValue: Integer): string;
begin
  Result := FInfighting.ToText(AValue);
end;

function TEngineInfoGroups.InfightingToValue(const AText: string): Integer;
begin
  Result := FInfighting.ToValue(AText);
end;

function TEngineInfoGroups.ProjectileToText(const AValue: Integer): string;
begin
  Result := FProjectile.ToText(AValue);
end;

function TEngineInfoGroups.ProjectileToValue(const AText: string): Integer;
begin
  Result := FProjectile.ToValue(AText);
end;

function TEngineInfoGroups.SplashToText(const AValue: Integer): string;
begin
  Result := FSplash.ToText(AValue);
end;

function TEngineInfoGroups.SplashToValue(const AText: string): Integer;
begin
  Result := FSplash.ToValue(AText);
end;

end.
