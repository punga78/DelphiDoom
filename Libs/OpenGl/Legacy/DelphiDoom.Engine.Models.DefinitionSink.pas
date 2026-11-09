//------------------------------------------------------------------------------
//
//  DelphiDoom: Engine - the registry of the models for MODELDEF
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

unit DelphiDoom.Engine.Models.DefinitionSink;

interface

uses
  DelphiDoom.Models.Definition.Types,
  DelphiDoom.Models.Definition.Intf;

type
  /// <summary>
  ///   What the parser of MODELDEF gives to the registry of the renderer (gl_models): the models
  ///   (which load the file), the textures and the states of the game that show them
  /// </summary>
  TEngineModelDefinitionSink = class(TInterfacedObject, IModelDefinitionSink)
  public
    function AddModel(const AItem: TModelDefinitionItem): Integer;
    function AddTexture(const AName: string): Integer;
    procedure AddState(const AState: TModelDefinitionState);
  end;

implementation

uses
  d_delphi,
  gl_models;

{ TEngineModelDefinitionSink }

function TEngineModelDefinitionSink.AddModel(const AItem: TModelDefinitionItem): Integer;
var
  LItem: modelmanageritem_t;
  LIndex: Integer;
begin
  LItem.name := AItem.Name;
  LItem.proc := AItem.Proc;
  LItem.xoffset := AItem.XOffset;
  LItem.yoffset := AItem.YOffset;
  LItem.zoffset := AItem.ZOffset;
  LItem.xscale := AItem.XScale;
  LItem.yscale := AItem.YScale;
  LItem.zscale := AItem.ZScale;
  LItem.model := nil;
  LItem.framemerge := TDStringList.Create;
  try
    for LIndex := 0 to High(AItem.FrameMerge) do
      LItem.framemerge.Add(AItem.FrameMerge[LIndex]);
    Result := gld_AddModel(LItem);
  finally
    LItem.framemerge.Free;
  end;
end;

function TEngineModelDefinitionSink.AddTexture(const AName: string): Integer;
begin
  Result := gld_AddModelTexture(AName);
end;

procedure TEngineModelDefinitionSink.AddState(const AState: TModelDefinitionState);
var
  LState: modelstate_t;
begin
  LState.modelidx := AState.ModelIndex;
  LState.texture := AState.Texture;
  LState.startframe := AState.StartFrame;
  LState.endframe := AState.EndFrame;
  LState.nextframe := AState.NextFrame;
  LState.state := AState.State;
  LState.transparency := AState.Transparency;
  gld_AddModelState(LState);
end;

end.
