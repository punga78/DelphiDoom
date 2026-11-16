{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the directory of the lumps for the renderer library    }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Engine.Renderer.LumpDirectory;

{$I Doom32.inc}

interface

uses
  DelphiDoom.Renderer.Types,
  DelphiDoom.Renderer.Intf;

type
  /// <summary>The lumps of the WAD of the engine (w_wad), for the ranges of flats and sprites</summary>
  TEngineRendererLumpDirectory = class(TInterfacedObject, IRendererLumpDirectory)
  public
    function LumpCount: Integer;
    function LumpName(ALump: Integer): TRendererLumpName;
    function FirstLumpNamed(const AName: string): Integer;
    function LastLumpNamed(const AName: string): Integer;
  end;

implementation

uses
  w_wad;

{ TEngineRendererLumpDirectory }

function TEngineRendererLumpDirectory.LumpCount: Integer;
begin
  Result := W_NumLumps;
end;

function TEngineRendererLumpDirectory.LumpName(ALump: Integer): TRendererLumpName;
var
  LName: char8_t;
begin
  LName := W_GetNameForNum(ALump);
  Move(LName, Result, SizeOf(Result));
end;

function TEngineRendererLumpDirectory.FirstLumpNamed(const AName: string): Integer;
begin
  Result := W_CheckFirstNumForName(AName);
end;

function TEngineRendererLumpDirectory.LastLumpNamed(const AName: string): Integer;
begin
  Result := W_CheckNumForName(AName);
end;

end.
