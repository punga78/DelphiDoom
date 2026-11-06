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
//
// DESCRIPTION:
//  Defines preprocessor
//

{$I Doom32.inc}

unit sc_utils;

interface

//==============================================================================
//
// SC_Preprocess
//
// The work is done by TScriptPreprocessor (Libs\Scanner); here the engine gives it the
// files and lumps for the includes, the console variables and the palettes
//
//==============================================================================
function SC_Preprocess(const inp_text: string; const addcomment: boolean): string;

implementation

uses
  SysUtils,
  {$IFDEF DOOM}
  g_game,
  {$ENDIF}
  sc_defines,
  DelphiDoom.Engine.Scanner.CvarSetter,
  DelphiDoom.Engine.Scanner.IncludeSource,
  DelphiDoom.Engine.Scanner.Log,
  DelphiDoom.Engine.Scanner.PaletteGenerator,
  DelphiDoom.Scanner.Directive.CreatePalette,
  DelphiDoom.Scanner.Directive.CvarForce,
  DelphiDoom.Scanner.Directive.Flag,
  DelphiDoom.Scanner.Preprocessor,
  DelphiDoom.Logging.Intf,
  DelphiDoom.Scanner.Preprocessor.Intf;

//==============================================================================
//
// SC_Preprocess
//
//==============================================================================
function SC_Preprocess(const inp_text: string; const addcomment: boolean): string;
var
  logintf: ILog;
  preprocessor: TScriptPreprocessor;
  directives: TArray<IScriptDirective>;
  defines: TArray<string>;
  i: integer;
begin
  logintf := TEngineScannerLog.Create;
  {$IFDEF DOOM}
  directives := TArray<IScriptDirective>.Create(
    TFlagDirective.Create(TArray<string>.Create('VANILLA_DEMO_OFF', '#VANILLA_DEMO_OFF', '{$VANILLA_DEMO_OFF}'),
      procedure
      begin
        vanilla_demo_off := true;
      end),
    TCvarForceDirective.Create(TEngineCvarSetter.Create, logintf),
    TCreatePaletteDirective.Create(TEnginePaletteGenerator.Create, logintf));
  {$ELSE}
  directives := TArray<IScriptDirective>.Create(
    TCvarForceDirective.Create(TEngineCvarSetter.Create, logintf),
    TCreatePaletteDirective.Create(TEnginePaletteGenerator.Create, logintf));
  {$ENDIF}

  SetLength(defines, gamedefines.Count);
  for i := 0 to gamedefines.Count - 1 do
    defines[i] := gamedefines.Strings[i];

  preprocessor := TScriptPreprocessor.Create(TEngineIncludeSource.Create, directives, logintf);
  try
    result := preprocessor.Preprocess(inp_text, addcomment, defines);
  finally
    preprocessor.Free;
  end;
end;

end.