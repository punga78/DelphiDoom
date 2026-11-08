{******************************************************************************}
{                                                                              }
{  DelphiDoom: renderer library - the column lookup of a texture               }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of R_GenerateLookup of r_data.pas (from R_GenerateLookup of            }
{  r_data.c of Linux Doom)                                                     }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Renderer.TextureLookup;

interface

uses
  System.SysUtils, DelphiDoom.Renderer.Types, DelphiDoom.Renderer.Intf,
  DelphiDoom.Logging.Intf;

type
  /// <summary>
  ///   Counts how many patches cover each column of a texture and, from that, where the
  ///   renderer finds the column: in the only patch that has it, or in the composite block
  ///   that is built when a column is covered by more than one patch (or the texture is made
  ///   of several patches)
  /// </summary>
  TRendererTextureLookup = class(TInterfacedObject, IRendererTextureLookup)
  strict private
    FPatchSource: IRendererPatchSource;
    FLog: ILog;
    procedure CountColumns(const ATexture: TRendererTextureInfo; var AColumnLump,
      AColumnOffset, APatchCount, APostCount: TArray<Integer>);
    function BuildCompositeOfPatches(const ATexture: TRendererTextureInfo;
      const APatchCount, APostCount: TArray<Integer>; var AColumnLump,
      AColumnOffset: TArray<Integer>): Integer;
    function BuildSinglePatch(const ATexture: TRendererTextureInfo;
      const APatchCount: TArray<Integer>; var AColumnLump,
      AColumnOffset: TArray<Integer>): Integer;
  public
    constructor Create(const APatchSource: IRendererPatchSource; const ALog: ILog);
    function Build(const ATexture: TRendererTextureInfo; var AColumnLump,
      AColumnOffset: TArray<Integer>): Integer;
  end;

implementation

const
  SColumnTablesTooShort = 'The column tables are shorter than the texture';
  SNegativeWidth = 'The texture has a negative width';
  SWarningColumnWithoutPatchOfComposite =
    'R_GenerateLookup(): column (%d) without a patch (%s, column=%d)'#13#10;
  SWarningColumnWithoutPatch = 'R_GenerateLookup(): column (%d) without a patch (%s)'#13#10;
  SWarningTextureTooBig = 'R_GenerateLookup(): texture %d is > 64k'#13#10;

{ TRendererTextureLookup }

constructor TRendererTextureLookup.Create(const APatchSource: IRendererPatchSource;
  const ALog: ILog);
begin
  inherited Create;
  if not Assigned(APatchSource) then
    raise EArgumentNilException.Create('APatchSource');
  if not Assigned(ALog) then
    raise EArgumentNilException.Create('ALog');
  FPatchSource := APatchSource;
  FLog := ALog;
end;

procedure TRendererTextureLookup.CountColumns(const ATexture: TRendererTextureInfo;
  var AColumnLump, AColumnOffset, APatchCount, APostCount: TArray<Integer>);
var
  LPatchIndex: Integer;
  LLump: Integer;
  LPatch: IRendererPatchColumns;
  LX: Integer;
  LStartX: Integer;
  LEndX: Integer;
  LOffset: Integer;
  LPosts: Integer;
begin
  for LPatchIndex := 0 to High(ATexture.Patches) do
  begin
    LLump := ATexture.Patches[LPatchIndex].Lump;
    LPatch := FPatchSource.Open(LLump);
    if not Assigned(LPatch) then
      Continue;

    LStartX := ATexture.Patches[LPatchIndex].OriginX;
    LEndX := LStartX + LPatch.Width;
    if LStartX < 0 then
      LX := 0
    else
      LX := LStartX;
    if LEndX > ATexture.Width then
      LEndX := ATexture.Width;

    while LX < LEndX do
    begin
      LPatch.Column(LX - LStartX, LOffset, LPosts);
      APostCount[LX] := APostCount[LX] + LPosts;
      APatchCount[LX] := APatchCount[LX] + 1;
      AColumnLump[LX] := LLump;
      AColumnOffset[LX] := LOffset + 3;
      Inc(LX);
    end;
    // the patch goes back to the cache before the next one is opened
    LPatch := nil;
  end;
end;

function TRendererTextureLookup.BuildCompositeOfPatches(const ATexture: TRendererTextureInfo;
  const APatchCount, APostCount: TArray<Integer>; var AColumnLump,
  AColumnOffset: TArray<Integer>): Integer;
var
  LX: Integer;
begin
  // every column goes to the composite block: its posts and the pixels of the whole height
  Result := 0;
  for LX := 0 to ATexture.Width - 1 do
  begin
    if APatchCount[LX] <= 0 then
    begin
      FLog.DevWarning(Format(SWarningColumnWithoutPatchOfComposite,
        [LX, ATexture.Name, LX]));
      AColumnLump[LX] := RENDERER_COLUMN_WITHOUT_PATCH;
    end
    else
    begin
      AColumnLump[LX] := RENDERER_COLUMN_COMPOSITE;
      AColumnOffset[LX] := Result + 3;
      Result := Result + 4 * APostCount[LX] + 1;
    end;
    Result := Result + ATexture.Height;
  end;
end;

function TRendererTextureLookup.BuildSinglePatch(const ATexture: TRendererTextureInfo;
  const APatchCount: TArray<Integer>; var AColumnLump,
  AColumnOffset: TArray<Integer>): Integer;
var
  LX: Integer;
begin
  // a column of a single patch stays in the patch: only the columns that two patches cover
  // (never here: kept as the old code) need a block of the height of the texture
  Result := 0;
  for LX := 0 to ATexture.Width - 1 do
  begin
    if APatchCount[LX] = 0 then
    begin
      FLog.DevWarning(Format(SWarningColumnWithoutPatch, [LX, ATexture.Name]));
      AColumnLump[LX] := RENDERER_COLUMN_WITHOUT_PATCH;
    end
    else if APatchCount[LX] > 1 then
    begin
      AColumnLump[LX] := RENDERER_COLUMN_COMPOSITE;
      AColumnOffset[LX] := Result;

      if Result > RENDERER_COMPOSITE_LIMIT - ATexture.Height then
        FLog.DevWarning(Format(SWarningTextureTooBig, [ATexture.Number]));

      Result := Result + ATexture.Height;
    end;
  end;
end;

function TRendererTextureLookup.Build(const ATexture: TRendererTextureInfo; var AColumnLump,
  AColumnOffset: TArray<Integer>): Integer;
var
  LPatchCount: TArray<Integer>;
  LPostCount: TArray<Integer>;
begin
  if ATexture.Width < 0 then
    raise ERendererException.Create(SNegativeWidth);
  if (Length(AColumnLump) < ATexture.Width) or (Length(AColumnOffset) < ATexture.Width) then
    raise ERendererException.Create(SColumnTablesTooShort);

  // dynamic arrays start with zeros
  SetLength(LPatchCount, ATexture.Width);
  SetLength(LPostCount, ATexture.Width);

  // Count the number of columns that are covered by more than one patch.
  // Fill in the lump / offset, so columns with only a single patch are all done.
  CountColumns(ATexture, AColumnLump, AColumnOffset, LPatchCount, LPostCount);

  if Length(ATexture.Patches) > 1 then
    Result := BuildCompositeOfPatches(ATexture, LPatchCount, LPostCount, AColumnLump,
      AColumnOffset)
  else
    Result := BuildSinglePatch(ATexture, LPatchCount, AColumnLump, AColumnOffset);

  if Result > RENDERER_COMPOSITE_LIMIT - ATexture.Height then
    FLog.DevWarning(Format(SWarningTextureTooBig, [ATexture.Number]));
end;

end.
