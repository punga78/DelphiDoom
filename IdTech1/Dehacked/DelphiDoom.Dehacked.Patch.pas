{******************************************************************************}
{                                                                              }
{  DelphiDoom: Dehacked library - a patch                                      }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Dehacked.Patch;

interface

uses
  System.Generics.Collections, DelphiDoom.Dehacked.Section, DelphiDoom.Dehacked.Intf;

type
  /// <summary>The blocks of a patch, which owns them</summary>
  TDehackedPatch = class(TInterfacedObject, IDehackedPatch)
  private
    FSections: TObjectList<TDehackedSection>;
    FDoomVersion: Integer;
    FPatchFormat: Integer;
    FHasSignature: Boolean;
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>The patch owns the section</summary>
    procedure Add(ASection: TDehackedSection);
    procedure SetHeader(ADoomVersion, APatchFormat: Integer; AHasSignature: Boolean);
    function SectionCount: Integer;
    function Section(AIndex: Integer): TDehackedSection;
    function DoomVersion: Integer;
    function PatchFormat: Integer;
    function HasSignature: Boolean;
  end;

implementation

{ TDehackedPatch }

constructor TDehackedPatch.Create;
begin
  inherited Create;
  FSections := TObjectList<TDehackedSection>.Create(True);
  FDoomVersion := -1;
  FPatchFormat := -1;
end;

destructor TDehackedPatch.Destroy;
begin
  FSections.Free;
  inherited Destroy;
end;

procedure TDehackedPatch.Add(ASection: TDehackedSection);
begin
  FSections.Add(ASection);
end;

procedure TDehackedPatch.SetHeader(ADoomVersion, APatchFormat: Integer; AHasSignature: Boolean);
begin
  FDoomVersion := ADoomVersion;
  FPatchFormat := APatchFormat;
  FHasSignature := AHasSignature;
end;

function TDehackedPatch.SectionCount: Integer;
begin
  Result := FSections.Count;
end;

function TDehackedPatch.Section(AIndex: Integer): TDehackedSection;
begin
  Result := FSections[AIndex];
end;

function TDehackedPatch.DoomVersion: Integer;
begin
  Result := FDoomVersion;
end;

function TDehackedPatch.PatchFormat: Integer;
begin
  Result := FPatchFormat;
end;

function TDehackedPatch.HasSignature: Boolean;
begin
  Result := FHasSignature;
end;

end.
