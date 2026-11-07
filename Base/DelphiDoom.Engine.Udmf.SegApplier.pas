{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the fake contrast of the segs of a text map            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Udmf.SegApplier;

interface

uses
  DelphiDoom.Udmf.Apply.Intf;

type
  /// <summary>Gives each seg that is not a miniseg its fake contrast in segs[]</summary>
  TEngineUdmfSegApplier = class(TInterfacedObject, IUdmfMapPartApplier)
  strict private
    FFakeContrast: IUdmfFakeContrast;
    procedure ApplySeg(const ASegIndex: Integer);
  public
    constructor Create(const AFakeContrast: IUdmfFakeContrast);
    function Apply: Boolean;
  end;

implementation

uses
  SysUtils,
  r_defs,
  p_setup,
  p_udmf;

{ TEngineUdmfSegApplier }

constructor TEngineUdmfSegApplier.Create(const AFakeContrast: IUdmfFakeContrast);
begin
  inherited Create;
  if not Assigned(AFakeContrast) then
    raise EArgumentNilException.Create('AFakeContrast');
  FFakeContrast := AFakeContrast;
end;

procedure TEngineUdmfSegApplier.ApplySeg(const ASegIndex: Integer);
var
  LSeg: Pseg_t;
begin
  LSeg := @segs[ASegIndex];
  if LSeg.miniseg then
    Exit;

  LSeg.fakecontrastlight := FFakeContrast.Calculate(
    LSeg.sidedef.flags and SDF_NOFAKECONTRAST <> 0,
    LSeg.v1.x, LSeg.v1.y, LSeg.v2.x, LSeg.v2.y);
end;

function TEngineUdmfSegApplier.Apply: Boolean;
var
  LIndex: Integer;
begin
  Result := hasudmfdata;
  if not Result then
    Exit;

  for LIndex := 0 to numsegs - 1 do
    ApplySeg(LIndex);
end;

end.
