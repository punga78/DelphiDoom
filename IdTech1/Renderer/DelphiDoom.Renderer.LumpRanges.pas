{******************************************************************************}
{                                                                              }
{  DelphiDoom: renderer library - the lump ranges of flats and sprites         }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of the markers of R_InitFlats and R_InitSpriteLumps of r_data.pas      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Renderer.LumpRanges;

interface

uses
  System.SysUtils, DelphiDoom.Renderer.Types, DelphiDoom.Renderer.Intf,
  DelphiDoom.Logging.Intf;

type
  /// <summary>
  ///   Finds where the flats and the sprites are in the WAD from their markers: F_START and
  ///   F_END (FF_ in the PWADs that use them), S_START and S_END (SS_ in the PWADs)
  /// </summary>
  TRendererLumpRanges = class(TInterfacedObject, IRendererLumpRanges)
  strict private
    FDirectory: IRendererLumpDirectory;
    FLog: ILog;
    function RequireFirst(const AName: string): Integer;
    function RequireLast(const AName: string): Integer;
  public
    constructor Create(const ADirectory: IRendererLumpDirectory; const ALog: ILog);
    /// <summary>The name of a lump as text: up to the first zero or the eight characters</summary>
    class function LumpNameAsText(const ALumpName: TRendererLumpName): string; static;
    function FlatRange: TRendererLumpRange;
    function SpriteRange: TRendererLumpRange;
  end;

implementation

const
  SErrorMarkerNotFound = 'W_GetNumForName(): %s not found!';
  SWarningMisplacedMarkers =
    'R_InitSpriteLumps(): WAD files have missplaced sprite markers (start=%d, end=%d)'#13#10;

{ TRendererLumpRanges }

constructor TRendererLumpRanges.Create(const ADirectory: IRendererLumpDirectory;
  const ALog: ILog);
begin
  inherited Create;
  if not Assigned(ADirectory) then
    raise EArgumentNilException.Create('ADirectory');
  if not Assigned(ALog) then
    raise EArgumentNilException.Create('ALog');
  FDirectory := ADirectory;
  FLog := ALog;
end;

class function TRendererLumpRanges.LumpNameAsText(const ALumpName: TRendererLumpName): string;
var
  LIndex: Integer;
begin
  Result := '';
  LIndex := 0;
  while (LIndex < SizeOf(ALumpName)) and (ALumpName[LIndex] <> #0) do
  begin
    Result := Result + Char(ALumpName[LIndex]);
    Inc(LIndex);
  end;
end;

function TRendererLumpRanges.RequireFirst(const AName: string): Integer;
begin
  Result := FDirectory.FirstLumpNamed(AName);
  if Result = -1 then
    raise ERendererException.Create(Format(SErrorMarkerNotFound, [AName]));
end;

function TRendererLumpRanges.RequireLast(const AName: string): Integer;
begin
  Result := FDirectory.LastLumpNamed(AName);
  if Result = -1 then
    raise ERendererException.Create(Format(SErrorMarkerNotFound, [AName]));
end;

function TRendererLumpRanges.FlatRange: TRendererLumpRange;
var
  LLump: Integer;
begin
  Result.First := RequireFirst('F_START') + 1;
  LLump := FDirectory.FirstLumpNamed('FF_START') + 1;
  if LLump > 0 then
    if LLump < Result.First then
      Result.First := LLump;
  Result.Last := RequireLast('F_END') - 1;
  LLump := FDirectory.LastLumpNamed('FF_END');
  if LLump > Result.Last then
    Result.Last := LLump;
end;

function TRendererLumpRanges.SpriteRange: TRendererLumpRange;
var
  LIndex: Integer;
  LName: string;
  LLump: Integer;
begin
  Result.First := 0;
  for LIndex := 0 to FDirectory.LumpCount - 1 do
  begin
    LName := LumpNameAsText(FDirectory.LumpName(LIndex));
    if (LName = 'S_START') or (LName = 'SS_START') then
    begin
      Result.First := LIndex + 1;
      Break;
    end;
  end;

  Result.Last := RequireLast('S_END') - 1;
  LLump := FDirectory.LastLumpNamed('SS_END');
  if LLump > 0 then
  begin
    Dec(LLump);
    if Result.Last < LLump then
      Result.Last := LLump;
  end;

  if Result.Last < Result.First then
  begin
    FLog.Warning(Format(SWarningMisplacedMarkers, [Result.First, Result.Last]));
    // the old code took the number of lumps, not the last one
    Result.Last := FDirectory.LumpCount;
  end;
end;

end.
