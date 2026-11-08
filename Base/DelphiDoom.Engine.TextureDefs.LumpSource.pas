{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the lumps of the texture definitions                   }
{  Copyright (C) 2004-2023 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Engine.TextureDefs.LumpSource;

interface

uses
  System.SysUtils,
  DelphiDoom.TextureDefs.Intf,
  DelphiDoom.Engine.Wad.Lumps.Intf;

type
  /// <summary>
  ///   The bytes of PNAMES, TEXTURE1..3 and TEXTURE0 as the game has them: the lump of that name
  ///   that wins in the directory, copied out of the zone memory
  /// </summary>
  TEngineTextureLumpSource = class(TInterfacedObject, ITextureDefsLumpSource)
  strict private
    FLumps: IEngineLumps;
  public
    constructor Create(const ALumps: IEngineLumps);
    function TryReadLump(const AName: string; out ABytes: TBytes): Boolean;
  end;

implementation

{ TEngineTextureLumpSource }

constructor TEngineTextureLumpSource.Create(const ALumps: IEngineLumps);
begin
  inherited Create;
  if not Assigned(ALumps) then
    raise EArgumentNilException.Create('ALumps');
  FLumps := ALumps;
end;

function TEngineTextureLumpSource.TryReadLump(const AName: string; out ABytes: TBytes): Boolean;
var
  LLump: Integer;
  LLength: Integer;
begin
  LLump := FLumps.CheckNumForName(AName);
  Result := LLump >= 0;
  if not Result then
  begin
    ABytes := nil;
    Exit;
  end;
  LLength := FLumps.LengthOf(LLump);
  SetLength(ABytes, LLength);
  if LLength > 0 then
    FLumps.Read(LLump, @ABytes[0]);
end;

end.
