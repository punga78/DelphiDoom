{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the table of the sounds of Heretic (S_sfx)                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Audio.SfxTable;

interface

uses
  DelphiDoom.Audio.Sound.Intf;

type
  /// <summary>
  ///   ISfxTable on S_sfx, numsfx and MAX_NUMSFX of the sounddata.pas of Heretic (the unit exists
  ///   with this name in the folders of the four games and the project takes the one of its
  ///   game). The rules are in TSfxNumberResolver: here the
  ///   record and the loops
  /// </summary>
  TEngineSfxTable = class(TInterfacedObject, ISfxTable)
  public
    function GetCount: Integer;
    procedure SetCount(AValue: Integer);
    function Capacity: Integer;
    function NameOf(AIndex: Integer): string;
    function DefaultSfx: Integer;
    function HasDynamicSlots: Boolean;
    function FindByName(const AUpperName: string): Integer;
    function FindEmptySlot(AFirst: Integer): Integer;
    procedure Define(AIndex: Integer; const AName, ATagName: string);
  end;

implementation

uses
  sounddata,
  DelphiDoom.Audio.SoundNames;

{ TEngineSfxTable }

function TEngineSfxTable.GetCount: Integer;
begin
  Result := numsfx;
end;

procedure TEngineSfxTable.SetCount(AValue: Integer);
begin
  numsfx := AValue;
end;

function TEngineSfxTable.Capacity: Integer;
begin
  Result := MAX_NUMSFX;
end;

function TEngineSfxTable.NameOf(AIndex: Integer): string;
begin
  Result := S_sfx[AIndex].name;
end;

function TEngineSfxTable.DefaultSfx: Integer;
begin
  Result := Ord(sfx_gldhit);
end;

function TEngineSfxTable.HasDynamicSlots: Boolean;
begin
  Result := False;
end;

function TEngineSfxTable.FindByName(const AUpperName: string): Integer;
var
  LIndex: Integer;
begin
  for LIndex := 1 to numsfx - 1 do
    if TSoundNames.SfxMatches(S_sfx[LIndex].name, AUpperName) then
    begin
      Result := LIndex;
      Exit;
    end;
  Result := -1;
end;

function TEngineSfxTable.FindEmptySlot(AFirst: Integer): Integer;
var
  LIndex: Integer;
begin
  for LIndex := AFirst to numsfx - 1 do
    if S_sfx[LIndex].name = '' then
    begin
      Result := LIndex;
      Exit;
    end;
  Result := -1;
end;

procedure TEngineSfxTable.Define(AIndex: Integer; const AName, ATagName: string);
var
  LSfx: Psfxinfo_t;
begin
  LSfx := @S_sfx[AIndex];
  LSfx.name := AName;
  LSfx.singularity := False;
  LSfx.priority := 72;
  LSfx.link := nil;
  LSfx.pitch := -1;
  LSfx.volume := -1;
  LSfx.data := nil;
  LSfx.usefulness := 0;
  LSfx.lumpnum := -1; // JVAL: was = 0;
  LSfx.randomsoundlist := nil;
end;

end.
