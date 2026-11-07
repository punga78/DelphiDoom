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
//  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
//  02111-1307, USA.
//
//  DESCRIPTION:
//    Base model class (Abstract) and the services of Libs\Models that the
//    models of the engine use (the reader of MD2 files, the lists of commands)
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit mdl_base;

interface

uses
  SysUtils,
  d_delphi,
  DelphiDoom.Models.Intf;

type
  TBaseModel = class(TObject)
  protected
  public
    constructor Create(const name: string;
      const xoffset, yoffset, zoffset: float;
      const xscale, yscale, zscale: float;
      const additionalframes: TDStringList); virtual;
    destructor Destroy; override;
    procedure Draw(const frm1, frm2: integer; const offset: float); virtual; abstract;
    procedure DrawSimple(const frm: integer); virtual; abstract;
  end;

//==============================================================================
//
// MDL_ConfigureModels
//
// The composition root gives the services of Libs\Models: the reader of MD2
// files and the way to make an empty list of commands of a procedural model.
//
//==============================================================================
procedure MDL_ConfigureModels(const AMd2Parser: IMd2Parser;
  const ACommandStreams: TFunc<IModelCommandStream>);

//==============================================================================
//
// MDL_Md2Parser
//
//==============================================================================
function MDL_Md2Parser: IMd2Parser;

//==============================================================================
//
// MDL_NewCommandStream
//
//==============================================================================
function MDL_NewCommandStream: IModelCommandStream;

implementation

uses
  i_system;

var
  md2_parser: IMd2Parser = nil;
  command_streams: TFunc<IModelCommandStream> = nil;

//==============================================================================
//
// MDL_ConfigureModels
//
//==============================================================================
procedure MDL_ConfigureModels(const AMd2Parser: IMd2Parser;
  const ACommandStreams: TFunc<IModelCommandStream>);
begin
  md2_parser := AMd2Parser;
  command_streams := ACommandStreams;
end;

//==============================================================================
//
// MDL_Md2Parser
//
//==============================================================================
function MDL_Md2Parser: IMd2Parser;
begin
  if not Assigned(md2_parser) then
    I_Error('MDL_Md2Parser(): the models are not configured (call ComposeEngine first)');
  Result := md2_parser;
end;

//==============================================================================
//
// MDL_NewCommandStream
//
//==============================================================================
function MDL_NewCommandStream: IModelCommandStream;
begin
  if not Assigned(command_streams) then
    I_Error('MDL_NewCommandStream(): the models are not configured (call ComposeEngine first)');
  Result := command_streams();
end;

//==============================================================================
//
// TBaseModel.Create
//
//==============================================================================
constructor TBaseModel.Create(const name: string;
  const xoffset, yoffset, zoffset: float;
  const xscale, yscale, zscale: float;
  const additionalframes: TDStringList);
begin
  Inherited Create;
end;

//==============================================================================
//
// TBaseModel.Destroy
//
//==============================================================================
destructor TBaseModel.Destroy;
begin
  Inherited;
end;

end.
