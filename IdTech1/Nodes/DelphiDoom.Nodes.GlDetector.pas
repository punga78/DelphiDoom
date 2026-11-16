{******************************************************************************}
{                                                                              }
{  DelphiDoom: Nodes library - version of the GL nodes of a map                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Nodes.GlDetector;

interface

uses
  DelphiDoom.Nodes.Intf;

type
  /// <summary>
  ///   Reads the magic number of GL_VERT (and of GL_SEGS for V2 and V3) of the four GL lumps that
  ///   follow a label. A map has GL nodes only if the four lumps are there with their names
  /// </summary>
  TNodesGlDetector = class(TInterfacedObject, INodesGlDetector)
  strict private
    FSource: INodesLumpSource;
    function MagicOf(ALump: Integer): Cardinal;
  public
    constructor Create(const ASource: INodesLumpSource);
    function DetectVersion(ABaseLump: Integer): Integer;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Nodes.Types;

{ TNodesGlDetector }

constructor TNodesGlDetector.Create(const ASource: INodesLumpSource);
begin
  inherited Create;
  if not Assigned(ASource) then
    raise EArgumentNilException.Create('ASource');
  FSource := ASource;
end;

function TNodesGlDetector.MagicOf(ALump: Integer): Cardinal;
var
  LBytes: TBytes;
begin
  // a lump shorter than four bytes has no magic number (the old code read what followed it)
  Result := 0;
  if FSource.LumpLength(ALump) >= SizeOf(Cardinal) then
  begin
    LBytes := FSource.ReadLump(ALump);
    Move(LBytes[0], Result, SizeOf(Result));
  end;
end;

function TNodesGlDetector.DetectVersion(ABaseLump: Integer): Integer;
var
  LVertMagic: Cardinal;
begin
  Result := 0;
  if (ABaseLump < 0) or (ABaseLump + 4 > FSource.LumpCount) then
    Exit;

  if not SameText(FSource.LumpName(ABaseLump + 1), NODES_LUMP_GL_VERT) or
     not SameText(FSource.LumpName(ABaseLump + 2), NODES_LUMP_GL_SEGS) or
     not SameText(FSource.LumpName(ABaseLump + 3), NODES_LUMP_GL_SSECT) or
     not SameText(FSource.LumpName(ABaseLump + 4), NODES_LUMP_GL_NODES) then
    Exit;

  LVertMagic := MagicOf(ABaseLump + 1);
  if LVertMagic = NODES_GL_MAGIC_V2 then
  begin
    if MagicOf(ABaseLump + 2) = NODES_GL_MAGIC_V3 then
      Result := 3
    else
      Result := 2;
  end
  else if LVertMagic = NODES_GL_MAGIC_V4 then
    Result := 4
  else if LVertMagic = NODES_GL_MAGIC_V5 then
    Result := 5;
end;

end.
