{******************************************************************************}
{                                                                              }
{  DelphiDoom: palette library - the gamma ramps                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Palette.GammaTables;

interface

uses
  System.SysUtils, DelphiDoom.Palette.Types, DelphiDoom.Palette.Intf;

type
  /// <summary>The five gamma ramps of the game (gammatable of v_video.pas)</summary>
  TGammaTables = class(TInterfacedObject, IGammaTables)
  public
    function LevelCount: Integer;
    function Table(ALevel: Integer): TBytes;
  end;

implementation

uses
  DelphiDoom.Palette.GammaData;

{ TGammaTables }

function TGammaTables.LevelCount: Integer;
begin
  Result := GAMMA_LEVEL_COUNT;
end;

function TGammaTables.Table(ALevel: Integer): TBytes;
begin
  if (ALevel < 0) or (ALevel >= GAMMA_LEVEL_COUNT) then
    raise EPaletteException.CreateFmt(SGammaLevelInvalid, [ALevel]);
  SetLength(Result, 256);
  Move(GAMMA_DATA[ALevel, 0], Result[0], 256);
end;

end.
