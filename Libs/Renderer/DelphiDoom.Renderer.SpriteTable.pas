{******************************************************************************}
{                                                                              }
{  DelphiDoom: renderer library - the table of the sprite headers              }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of the scan of R_InitSpriteLumps of r_data.pas                         }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Renderer.SpriteTable;

interface

uses
  System.SysUtils, DelphiDoom.Renderer.Types, DelphiDoom.Renderer.Intf;

type
  /// <summary>
  ///   Reads the width and the offsets of every sprite lump once, so that the renderer
  ///   knows the size of a sprite without caching it completely
  /// </summary>
  TRendererSpriteTableBuilder = class(TInterfacedObject, IRendererSpriteTableBuilder)
  strict private
    FDirectory: IRendererLumpDirectory;
    FHeaders: IRendererSpriteHeaders;
  public
    constructor Create(const ADirectory: IRendererLumpDirectory;
      const AHeaders: IRendererSpriteHeaders);
    function Build(const ARange: TRendererLumpRange): TRendererSpriteTable;
  end;

implementation

uses
  DelphiDoom.Renderer.LumpRanges;

// as in the engine: the header values times FRACUNIT are 32 bit integers that wrap around
{$Q-}
{$R-}

{ TRendererSpriteTableBuilder }

constructor TRendererSpriteTableBuilder.Create(const ADirectory: IRendererLumpDirectory;
  const AHeaders: IRendererSpriteHeaders);
begin
  inherited Create;
  if not Assigned(ADirectory) then
    raise EArgumentNilException.Create('ADirectory');
  if not Assigned(AHeaders) then
    raise EArgumentNilException.Create('AHeaders');
  FDirectory := ADirectory;
  FHeaders := AHeaders;
end;

function TRendererSpriteTableBuilder.Build(const ARange: TRendererLumpRange): TRendererSpriteTable;
var
  LCount: Integer;
  LIndex: Integer;
  LInSection: Boolean;
  LName: string;
  LWidth: Integer;
  LLeftOffset: Integer;
  LTopOffset: Integer;
begin
  LCount := ARange.Last - ARange.First + 1;
  if LCount < 0 then
    LCount := 0;
  SetLength(Result.Width, LCount);
  SetLength(Result.LeftOffset, LCount);
  SetLength(Result.TopOffset, LCount);
  SetLength(Result.Present, LCount);

  LInSection := True;
  for LIndex := 0 to LCount - 1 do
  begin
    Result.Width[LIndex] := 0;
    Result.LeftOffset[LIndex] := 0;
    Result.TopOffset[LIndex] := 0;
    Result.Present[LIndex] := False;
    LName := TRendererLumpRanges.LumpNameAsText(FDirectory.LumpName(ARange.First + LIndex));
    if (LName = 'SS_START') or (LName = 'S_START') then
      LInSection := True
    else if (LName = 'SS_END') or (LName = 'S_END') then
      LInSection := False
    else if LInSection then
    begin
      FHeaders.Header(ARange.First + LIndex, LWidth, LLeftOffset, LTopOffset);
      Result.Width[LIndex] := LWidth * RENDERER_FRACUNIT;
      Result.LeftOffset[LIndex] := LLeftOffset * RENDERER_FRACUNIT;
      Result.TopOffset[LIndex] := LTopOffset * RENDERER_FRACUNIT;
      Result.Present[LIndex] := True;
    end;
  end;
end;

end.
