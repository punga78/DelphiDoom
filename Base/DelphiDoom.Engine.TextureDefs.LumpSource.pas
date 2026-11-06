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
  DelphiDoom.TextureDefs.Intf;

type
  /// <summary>
  ///   The bytes of PNAMES, TEXTURE1..3 and TEXTURE0 as the game has them: the lump of that name
  ///   that wins in the directory, copied out of the zone memory
  /// </summary>
  TEngineTextureLumpSource = class(TInterfacedObject, ITextureDefsLumpSource)
  public
    function TryReadLump(const AName: string; out ABytes: TBytes): Boolean;
  end;

implementation

uses
  w_wad;

{ TEngineTextureLumpSource }

function TEngineTextureLumpSource.TryReadLump(const AName: string; out ABytes: TBytes): Boolean;
var
  LLump: Integer;
  LLength: Integer;
begin
  LLump := W_CheckNumForName(AName);
  Result := LLump >= 0;
  if not Result then
  begin
    ABytes := nil;
    Exit;
  end;
  LLength := W_LumpLength(LLump);
  SetLength(ABytes, LLength);
  if LLength > 0 then
    W_ReadLump(LLump, @ABytes[0]);
end;

end.
