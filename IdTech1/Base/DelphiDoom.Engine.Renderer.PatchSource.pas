{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the patches of the WAD for the renderer library        }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Engine.Renderer.PatchSource;

{$I Doom32.inc}

interface

uses
  System.SysUtils,
  DelphiDoom.Renderer.Intf;

type
  /// <summary>
  ///   Gives the lookup of the textures the columns of a patch of the WAD: the lump is read
  ///   from the cache of the zone memory (static while the patch is open, then back to the
  ///   cache), as R_GenerateLookup did
  /// </summary>
  TEngineRendererPatchSource = class(TInterfacedObject, IRendererPatchSource)
  public
    function Open(ALump: Integer): IRendererPatchColumns;
  end;

implementation

uses
  r_defs,
  w_wad,
  z_zone;

type
  /// <summary>An open patch: the lump in the zone memory</summary>
  TEngineRendererPatch = class(TInterfacedObject, IRendererPatchColumns)
  strict private
    FPatch: Ppatch_t;
  public
    constructor Create(APatch: Ppatch_t);
    destructor Destroy; override;
    function Width: Integer;
    procedure Column(AColumn: Integer; out AOffset, APostCount: Integer);
  end;

{ TEngineRendererPatch }

constructor TEngineRendererPatch.Create(APatch: Ppatch_t);
begin
  inherited Create;
  FPatch := APatch;
end;

destructor TEngineRendererPatch.Destroy;
begin
  Z_ChangeTag(FPatch, PU_CACHE);
  inherited Destroy;
end;

function TEngineRendererPatch.Width: Integer;
begin
  Result := FPatch.width;
end;

procedure TEngineRendererPatch.Column(AColumn: Integer; out AOffset, APostCount: Integer);
var
  LColumn: Pcolumn_t;
begin
  // the table of the offsets has one integer per column, after the header of the patch
  AOffset := PInteger(NativeInt(@FPatch.columnofs[0]) + AColumn * SizeOf(Integer))^;
  APostCount := 0;
  LColumn := Pcolumn_t(NativeInt(FPatch) + AOffset);
  while LColumn.topdelta <> $ff do
  begin
    Inc(APostCount);
    LColumn := Pcolumn_t(NativeInt(LColumn) + LColumn.length + 4);
  end;
end;

{ TEngineRendererPatchSource }

function TEngineRendererPatchSource.Open(ALump: Integer): IRendererPatchColumns;
var
  LPatch: Ppatch_t;
begin
{$IFDEF DOOM}
  // Doom marks the patches of the WAD: what is not a patch or a sprite is not read
  if (ALump < 0) or (W_LumpFlags(ALump) and (TYPE_PATCH or TYPE_SPRITE) = 0) then
  begin
    Result := nil;
    Exit;
  end;
{$ENDIF}
  LPatch := W_CacheLumpNum(ALump, PU_STATIC);
  Result := TEngineRendererPatch.Create(LPatch);
end;

end.
