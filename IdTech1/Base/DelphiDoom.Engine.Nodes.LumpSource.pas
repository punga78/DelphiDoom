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
  DelphiDoom.Nodes.Intf,
  DelphiDoom.Engine.Wad.Lumps.Intf;

type
  /// <summary>
  ///   The lumps of the directory of the engine (w_wad) as the Nodes library asks for them: by
  ///   number, with the name as the directory has it
  /// </summary>
  TEngineNodesLumpSource = class(TInterfacedObject, INodesLumpSource)
  strict private
    FLumps: IEngineLumps;
  public
    constructor Create(const ALumps: IEngineLumps);
    function GetLumpCount: Integer;
    function LumpName(ALump: Integer): string;
    function LumpLength(ALump: Integer): Integer;
    function ReadLump(ALump: Integer): TBytes;
    function FindLump(const AName: string): Integer;
  end;

implementation

{ TEngineNodesLumpSource }

constructor TEngineNodesLumpSource.Create(const ALumps: IEngineLumps);
begin
  inherited Create;
  if not Assigned(ALumps) then
    raise EArgumentNilException.Create('ALumps');
  FLumps := ALumps;
end;

function TEngineNodesLumpSource.GetLumpCount: Integer;
begin
  Result := FLumps.Count;
end;

function TEngineNodesLumpSource.LumpName(ALump: Integer): string;
begin
  if (ALump < 0) or (ALump >= FLumps.Count) then
    Result := ''
  else
    Result := FLumps.NameOf(ALump);
end;

function TEngineNodesLumpSource.LumpLength(ALump: Integer): Integer;
begin
  Result := FLumps.LengthOf(ALump);
end;

function TEngineNodesLumpSource.ReadLump(ALump: Integer): TBytes;
var
  LLength: Integer;
begin
  LLength := FLumps.LengthOf(ALump);
  SetLength(Result, LLength);
  if LLength > 0 then
    FLumps.Read(ALump, @Result[0]);
end;

function TEngineNodesLumpSource.FindLump(const AName: string): Integer;
begin
  Result := FLumps.CheckNumForName(AName);
end;

end.
