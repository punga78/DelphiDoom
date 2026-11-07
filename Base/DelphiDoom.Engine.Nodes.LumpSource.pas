{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the lumps of the WAD directory for the Nodes library   }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Engine.Nodes.LumpSource;

interface

uses
  System.SysUtils,
  DelphiDoom.Nodes.Intf;

type
  /// <summary>
  ///   The lumps of the directory of the engine (w_wad) as the Nodes library asks for them: by
  ///   number, with the name as the directory has it
  /// </summary>
  TEngineNodesLumpSource = class(TInterfacedObject, INodesLumpSource)
  public
    function GetLumpCount: Integer;
    function LumpName(ALump: Integer): string;
    function LumpLength(ALump: Integer): Integer;
    function ReadLump(ALump: Integer): TBytes;
    function FindLump(const AName: string): Integer;
  end;

implementation

uses
  d_delphi,
  w_wad;

{ TEngineNodesLumpSource }

function TEngineNodesLumpSource.GetLumpCount: Integer;
begin
  Result := W_NumLumps;
end;

function TEngineNodesLumpSource.LumpName(ALump: Integer): string;
begin
  if (ALump < 0) or (ALump >= W_NumLumps) then
    Result := ''
  else
    Result := char8tostring(W_GetNameForNum(ALump));
end;

function TEngineNodesLumpSource.LumpLength(ALump: Integer): Integer;
begin
  Result := W_LumpLength(ALump);
end;

function TEngineNodesLumpSource.ReadLump(ALump: Integer): TBytes;
var
  LLength: Integer;
begin
  LLength := W_LumpLength(ALump);
  SetLength(Result, LLength);
  if LLength > 0 then
    W_ReadLump(ALump, @Result[0]);
end;

function TEngineNodesLumpSource.FindLump(const AName: string): Integer;
begin
  Result := W_CheckNumForName(AName);
end;

end.
