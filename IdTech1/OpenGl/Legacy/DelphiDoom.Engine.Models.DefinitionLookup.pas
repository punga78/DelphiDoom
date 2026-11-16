//------------------------------------------------------------------------------
//
//  DelphiDoom: Engine - the states of the game for MODELDEF
//  Copyright (C) 2004-2022 by Jim Valavanis
//
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License
//  as published by the Free Software Foundation; either version 2
//  of the License, or (at your option) any later version.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit DelphiDoom.Engine.Models.DefinitionLookup;

interface

uses
  DelphiDoom.Models.Definition.Intf;

type
  /// <summary>The state names (statenames) as the game has them</summary>
  TEngineModelDefinitionLookup = class(TInterfacedObject, IModelDefinitionLookup)
  public
    function FindState(const AName: string): Integer;
  end;

implementation

uses
  sc_states;

{ TEngineModelDefinitionLookup }

function TEngineModelDefinitionLookup.FindState(const AName: string): Integer;
begin
  Result := statenames.IndexOfToken(AName);
end;

end.
