{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the lumps that lumpsize and lumpnum show               }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Engine.Console.LumpSource;

{$I Doom32.inc}

interface

uses
  System.SysUtils, DelphiDoom.Console.Intf, DelphiDoom.Engine.Wad.Lumps.Intf;

type
  /// <summary>The directory of the lumps of the engine (IEngineLumps) for the lump commands</summary>
  TEngineConsoleLumpSource = class(TInterfacedObject, IConsoleLumpSource)
  strict private
    FLumps: IEngineLumps;
  public
    /// <summary>EArgumentNilException if ALumps is nil</summary>
    constructor Create(const ALumps: IEngineLumps);
    function Count: Integer;
    function CheckNumForName(const AName: string): Integer;
    function LengthOf(ALump: Integer): Integer;
    function ReadBytes(ALump: Integer): TBytes;
  end;

implementation

{ TEngineConsoleLumpSource }

constructor TEngineConsoleLumpSource.Create(const ALumps: IEngineLumps);
begin
  inherited Create;
  if not Assigned(ALumps) then
    raise EArgumentNilException.Create('ALumps');
  FLumps := ALumps;
end;

function TEngineConsoleLumpSource.Count: Integer;
begin
  Result := FLumps.Count;
end;

function TEngineConsoleLumpSource.CheckNumForName(const AName: string): Integer;
begin
  Result := FLumps.CheckNumForName(AName);
end;

function TEngineConsoleLumpSource.LengthOf(ALump: Integer): Integer;
begin
  Result := FLumps.LengthOf(ALump);
end;

function TEngineConsoleLumpSource.ReadBytes(ALump: Integer): TBytes;
begin
  SetLength(Result, FLumps.LengthOf(ALump));
  if Length(Result) > 0 then
    FLumps.Read(ALump, @Result[0]);
end;

end.
