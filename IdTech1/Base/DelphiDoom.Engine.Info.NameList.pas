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

unit DelphiDoom.Engine.Info.NameList;

interface

uses
  DelphiDoom.Info.Intf;

type
  /// <summary>Which of the lists of group names of deh_main a TEngineInfoNameList reads</summary>
  TEngineInfoGroupKind = (igkInfighting, igkProjectile, igkSplash);

  /// <summary>
  ///   One of the lists of group names of deh_main (infighting_groups, projectile_groups,
  ///   splash_groups) for the library. The list is read when it is asked: DEH_Init makes it
  ///   after the engine is composed
  /// </summary>
  TEngineInfoNameList = class(TInterfacedObject, IInfoNameList)
  strict private
    FKind: TEngineInfoGroupKind;
    function List: TObject;
  public
    constructor Create(const AKind: TEngineInfoGroupKind);
    function Count: Integer;
    function Name(const AIndex: Integer): string;
    function IndexOf(const AName: string): Integer;
    function Add(const AName: string): Integer;
  end;

implementation

uses
  d_delphi,
  deh_main;

{ TEngineInfoNameList }

constructor TEngineInfoNameList.Create(const AKind: TEngineInfoGroupKind);
begin
  inherited Create;
  FKind := AKind;
end;

function TEngineInfoNameList.List: TObject;
begin
  case FKind of
    igkInfighting: Result := infighting_groups;
    igkProjectile: Result := projectile_groups;
  else
    Result := splash_groups;
  end;
end;

function TEngineInfoNameList.Count: Integer;
begin
  if List = nil then
    Result := 0
  else
    Result := TDTextList(List).Count;
end;

function TEngineInfoNameList.Name(const AIndex: Integer): string;
begin
  Result := TDTextList(List).Strings[AIndex];
end;

function TEngineInfoNameList.IndexOf(const AName: string): Integer;
begin
  Result := TDTextList(List).IndexOf(AName);
end;

function TEngineInfoNameList.Add(const AName: string): Integer;
begin
  Result := TDTextList(List).Add(AName);
end;

end.
