{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the extra values of the sides of a text map            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Udmf.SideApplier;

interface

uses
  DelphiDoom.Udmf.Apply.Intf;

type
  /// <summary>Writes the extra values of the sides (offsets of each texture, flags) in sides[]</summary>
  TEngineUdmfSideApplier = class(TInterfacedObject, IUdmfMapPartApplier)
  strict private
    procedure ApplySide(const ASideIndex: Integer);
  public
    function Apply: Boolean;
  end;

implementation

uses
  r_defs,
  p_setup,
  p_udmf;

{ TEngineUdmfSideApplier }

procedure TEngineUdmfSideApplier.ApplySide(const ASideIndex: Integer);
var
  LSide: Pside_t;
  LExtra: Pextraside_t;
begin
  LSide := @sides[ASideIndex];
  LExtra := @udmfsidedefs[ASideIndex];

  LSide.textureoffset := LExtra.textureoffset;
  LSide.toptextureoffset := LExtra.toptextureoffset;
  LSide.midtextureoffset := LExtra.midtextureoffset;
  LSide.bottomtextureoffset := LExtra.bottomtextureoffset;
  LSide.rowoffset := LExtra.rowoffset;
  LSide.toprowoffset := LExtra.toprowoffset;
  LSide.midrowoffset := LExtra.midrowoffset;
  LSide.bottomrowoffset := LExtra.bottomrowoffset;
  LSide.flags := LExtra.flags;
end;

function TEngineUdmfSideApplier.Apply: Boolean;
var
  LIndex: Integer;
begin
  Result := hasudmfdata and (numudmfsidedefs = numsides);
  if not Result then
    Exit;

  for LIndex := 0 to numudmfsidedefs - 1 do
    ApplySide(LIndex);
end;

end.
