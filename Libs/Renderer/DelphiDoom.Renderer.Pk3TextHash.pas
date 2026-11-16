{******************************************************************************}
{                                                                              }
{  DelphiDoom: renderer library - the hash of the names of a PK3               }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of Hash of r_pk3textures.pas                                           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Renderer.Pk3TextHash;

interface

uses
  System.SysUtils, DelphiDoom.Renderer.Intf;

type
  /// <summary>
  ///   The number in the name of the cache files of the textures of a PK3: it changes when the
  ///   list of the images changes, so the cache is made again
  /// </summary>
  TRendererPk3TextHash = class(TInterfacedObject, IRendererPk3TextHash)
  public
    function Compute(const AText: string): Integer;
  end;

implementation

// the hash wraps around, as it did: the names of the cache files of the users depend on it
{$Q-}
{$R-}

{ TRendererPk3TextHash }

function TRendererPk3TextHash.Compute(const AText: string): Integer;
var
  LIndex: Integer;
begin
  if Length(AText) = 0 then
    Exit(0);
  // each character counts as a byte (the old code assigned it to a Byte)
  Result := 5381 * 33 + Byte(Ord(AText[1]) and $FF);
  for LIndex := 2 to Length(AText) do
    Result := Result * 33 + Byte(Ord(AText[LIndex]) and $FF);
end;

end.
