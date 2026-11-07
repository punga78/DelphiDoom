{******************************************************************************}
{                                                                              }
{  DelphiDoom: Nodes library - which lumps of a map are there                  }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Nodes.MapScanner;

interface

uses
  DelphiDoom.Nodes.Types, DelphiDoom.Nodes.Intf;

type
  /// <summary>
  ///   Looks at the lumps that follow the label of a map (the 10 of a map, 11 in Hexen) and says
  ///   where each one is. Near the end of the directory, when the map does not fit, only the
  ///   first five (six in Hexen) are looked at: those are enough to know that the map cannot be
  ///   used. A lump is taken at its first position: a map that repeats a lump keeps the first
  /// </summary>
  TNodesMapScanner = class sealed
  public
    class function Scan(const ASource: INodesLumpSource; AMapLabel: Integer;
      AHexen: Boolean): TNodesMapLayout; static;
  end;

implementation

uses
  System.SysUtils;

{ TNodesMapScanner }

class function TNodesMapScanner.Scan(const ASource: INodesLumpSource; AMapLabel: Integer;
  AHexen: Boolean): TNodesMapLayout;
var
  LFull: Integer;
  LShort: Integer;
  LLast: Integer;
  LFullScan: Boolean;
  LIndex: Integer;
  LName: string;

  procedure Take(var APosition: Integer);
  begin
    if APosition = -1 then
      APosition := LIndex;
  end;

begin
  if not Assigned(ASource) then
    raise EArgumentNilException.Create('ASource');
  Result := TNodesMapLayout.Missing;

  if AHexen then
  begin
    LFull := 11;
    LShort := 6;
  end
  else
  begin
    LFull := 10;
    LShort := 5;
  end;

  LFullScan := AMapLabel <= ASource.LumpCount - LFull;
  if LFullScan then
    LLast := LFull
  else if AMapLabel <= ASource.LumpCount - (LShort + 1) then
    LLast := LShort
  else
    Exit;

  for LIndex := 1 to LLast do
  begin
    LName := UpperCase(ASource.LumpName(AMapLabel + LIndex));
    if LName = 'THINGS' then
      Take(Result.Things)
    else if LName = 'LINEDEFS' then
      Take(Result.Linedefs)
    else if LName = 'SIDEDEFS' then
      Take(Result.Sidedefs)
    else if LName = 'VERTEXES' then
      Take(Result.Vertexes)
    else if LName = 'SECTORS' then
      Take(Result.Sectors)
    else if AHexen and (LName = 'BEHAVIOR') then
      Take(Result.Behavior)
    else if LFullScan then
    begin
      if LName = 'SEGS' then
        Take(Result.Segs)
      else if LName = 'SSECTORS' then
        Take(Result.Subsectors)
      else if LName = 'NODES' then
        Take(Result.Nodes)
      else if LName = 'REJECT' then
        Take(Result.Reject)
      else if LName = 'BLOCKMAP' then
        Take(Result.Blockmap);
    end;
  end;
end;

end.
