{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the extra values of the lines of a text map            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Udmf.LineApplier;

interface

uses
  DelphiDoom.Udmf.Apply.Intf;

type
  /// <summary>Writes the extra values of the lines (arguments, activators, more ids and, when the
  /// namespace is not the one of the game, the translation of the special) in lines[]</summary>
  TEngineUdmfLineApplier = class(TInterfacedObject, IUdmfMapPartApplier)
  strict private
    FSpecialTranslator: IUdmfLineSpecialTranslator;
    procedure ApplyLine(const ALineIndex: Integer);
  public
    constructor Create(const ASpecialTranslator: IUdmfLineSpecialTranslator);
    function Apply: Boolean;
  end;

implementation

uses
  SysUtils,
  r_defs,
  p_setup,
  p_udmf;

{ TEngineUdmfLineApplier }

constructor TEngineUdmfLineApplier.Create(const ASpecialTranslator: IUdmfLineSpecialTranslator);
begin
  inherited Create;
  if not Assigned(ASpecialTranslator) then
    raise EArgumentNilException.Create('ASpecialTranslator');
  FSpecialTranslator := ASpecialTranslator;
end;

procedure TEngineUdmfLineApplier.ApplyLine(const ALineIndex: Integer);
var
  LLine: Pline_t;
  LExtra: Pextraline_t;
begin
  LLine := @lines[ALineIndex];
  LExtra := @udmflinedefs[ALineIndex];

  {$IFNDEF HEXEN}
  LLine.arg1 := LExtra.arg1;
  LLine.arg2 := LExtra.arg2;
  LLine.arg3 := LExtra.arg3;
  LLine.arg4 := LExtra.arg4;
  LLine.arg5 := LExtra.arg5;
  LLine.activators := LExtra.activators;
  if udmflinetranslate then
    LLine.special := FSpecialTranslator.Translate(LLine.special);
  {$ENDIF}
  LLine.moreids := LExtra.moreids;
end;

function TEngineUdmfLineApplier.Apply: Boolean;
var
  LIndex: Integer;
begin
  Result := hasudmfdata and (numudmflinedefs = numlines);
  if not Result then
    Exit;

  for LIndex := 0 to numudmflinedefs - 1 do
    ApplyLine(LIndex);
end;

end.
