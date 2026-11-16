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

unit DelphiDoom.Engine.Info.Things;

interface

uses
  DelphiDoom.Engine.Info.Intf,
  DelphiDoom.Info.DoomedNumbers,
  DelphiDoom.Info.Intf,
  DelphiDoom.Info.MobjAliases,
  DelphiDoom.Info.MobjLookup;

type
  /// <summary>
  ///   The searches on the table of the things: by editor number, by name and by ancestor. It
  ///   keeps the table of editor numbers and the aliases between Initialize and ShutDown, as
  ///   info_common did with its two variables
  /// </summary>
  TEngineInfoThings = class(TInterfacedObject, IEngineInfoThings, IInfoThingNames)
  strict private
    FTables: IInfoMobjSource;
    FAliases: TInfoMobjAliases;
    FLookup: TInfoMobjLookup;
    FDoomed: TInfoDoomedNumbers;
    function Lookup: TInfoMobjLookup;
    function Doomed: TInfoDoomedNumbers;
  public
    constructor Create(const ATables: IInfoMobjSource);
    destructor Destroy; override;
    procedure Initialize;
    procedure ShutDown;
    function ThingForDoomedNumber(const ADoomedNum: Integer): Integer;
    function ThingForName(const AName: string): Integer;
    function NumForName(const AName: string): Integer;
    function AddAlias(const AAlias1, AAlias2: string): Boolean;
    function RootOf(const AIndex: Integer): Integer;
  end;

implementation

uses
  System.SysUtils,
  info_h;

{ TEngineInfoThings }

constructor TEngineInfoThings.Create(const ATables: IInfoMobjSource);
begin
  inherited Create;
  if not Assigned(ATables) then
    raise EArgumentNilException.Create('ATables');
  FTables := ATables;
end;

destructor TEngineInfoThings.Destroy;
begin
  ShutDown;
  inherited Destroy;
end;

function TEngineInfoThings.Lookup: TInfoMobjLookup;
begin
  if FLookup = nil then
    FLookup := TInfoMobjLookup.Create(FTables, FAliases, MOBJINFONAMESIZE);
  Result := FLookup;
end;

function TEngineInfoThings.Doomed: TInfoDoomedNumbers;
begin
  // without Initialize the old code searched the table without remembering the answers
  if FDoomed = nil then
    FDoomed := TInfoDoomedNumbers.Create(FTables);
  Result := FDoomed;
end;

procedure TEngineInfoThings.Initialize;
begin
  if FDoomed = nil then
    FDoomed := TInfoDoomedNumbers.Create(FTables);
  if FAliases = nil then
  begin
    // the lookup holds the aliases: it is made again
    FreeAndNil(FLookup);
    FAliases := TInfoMobjAliases.Create;
  end;
end;

procedure TEngineInfoThings.ShutDown;
begin
  FreeAndNil(FLookup);
  FreeAndNil(FDoomed);
  FreeAndNil(FAliases);
end;

function TEngineInfoThings.ThingForDoomedNumber(const ADoomedNum: Integer): Integer;
begin
  Result := Doomed.ThingForNumber(ADoomedNum);
end;

function TEngineInfoThings.ThingForName(const AName: string): Integer;
begin
  Result := Lookup.NumForName(AName);
end;

function TEngineInfoThings.NumForName(const AName: string): Integer;
begin
  Result := Lookup.NumForName(AName);
end;

function TEngineInfoThings.AddAlias(const AAlias1, AAlias2: string): Boolean;
var
  LFirst: Integer;
  LSecond: Integer;
begin
  if FAliases = nil then
    Exit(False);
  LFirst := ThingForName(AAlias1);
  if LFirst >= 0 then
    FAliases.Add(AAlias2, LFirst);
  LSecond := ThingForName(AAlias2);
  if LSecond >= 0 then
    FAliases.Add(AAlias1, LSecond);
  Result := (LFirst >= 0) or (LSecond >= 0);
end;

function TEngineInfoThings.RootOf(const AIndex: Integer): Integer;
begin
  Result := Lookup.RootOf(AIndex);
end;

end.
