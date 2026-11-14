{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the map file library - the text dump that the golden   }
{  file of the real idlib has                                                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.MapFile.Dump;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, DelphiDoom.Scanner.IdDict, DelphiDoom.MapFile.Map;

type
  /// <summary>
  ///   Writes a map as the driver of the harness of the real idlib did: one line per fact, floats as
  ///   '#' and their 32 bits in hexadecimal. The format is described in Tests\Data\MapFile\README.md
  /// </summary>
  TMapDump = class
  strict private
    FOutput: TStrings;
    procedure DumpDict(const ATag: string; const ADict: TIdDict);
  public
    constructor Create(const AOutput: TStrings);
    /// <summary>The C escape of a text: backslash, \n, \r, \t and \xNN for the bytes outside 32..126</summary>
    class function Escape(const AText: AnsiString): string; static;
    /// <summary>'#' and the bits of a float, as 8 lower case digits</summary>
    class function FloatBits(const AValue: Single): string; static;
    class function Hex(const AValue: Cardinal): string; static;
    /// <summary>The bytes of a file of Tests\Data\MapFile, '' if there is none</summary>
    class function LoadData(const AName: string): AnsiString; static;
    procedure Dump(const AMap: TMapFile);
  end;

implementation

uses
  DelphiDoom.IdLib.Math.Vec4, DelphiDoom.MapFile.Types, DelphiDoom.MapFile.Primitive, DelphiDoom.MapFile.Brush,
  DelphiDoom.MapFile.BrushSide, DelphiDoom.MapFile.Patch, DelphiDoom.MapFile.Entity;

{ TMapDump }

constructor TMapDump.Create(const AOutput: TStrings);
begin
  inherited Create;
  FOutput := AOutput;
end;

class function TMapDump.Escape(const AText: AnsiString): string;
var
  LIndex: Integer;
  LCode: Byte;
begin
  Result := '';
  for LIndex := 1 to Length(AText) do
  begin
    LCode := Byte(AText[LIndex]);
    case LCode of
      Ord('\'): Result := Result + '\\';
      10: Result := Result + '\n';
      13: Result := Result + '\r';
      9: Result := Result + '\t';
    else
      if (LCode < 32) or (LCode > 126) then
        Result := Result + '\x' + IntToHex(LCode, 2)
      else
        Result := Result + Char(LCode);
    end;
  end;
end;

class function TMapDump.FloatBits(const AValue: Single): string;
begin
  Result := '#' + Hex(PCardinal(@AValue)^);
end;

class function TMapDump.Hex(const AValue: Cardinal): string;
begin
  Result := LowerCase(IntToHex(AValue, 8));
end;

class function TMapDump.LoadData(const AName: string): AnsiString;
var
  LPath: string;
  LBytes: TBytes;
begin
  Result := '';
  LPath := ExpandFileName(ExtractFilePath(ParamStr(0)) + '..\..\..\..\Tests\Data\MapFile\' + AName);
  if not FileExists(LPath) then
    Exit;
  LBytes := TFile.ReadAllBytes(LPath);
  if Length(LBytes) > 0 then
  begin
    SetLength(Result, Length(LBytes));
    Move(LBytes[0], Result[1], Length(LBytes));
  end;
end;

procedure TMapDump.DumpDict(const ATag: string; const ADict: TIdDict);
var
  LIndex: Integer;
  LKeyValue: TIdKeyValue;
begin
  for LIndex := 0 to ADict.GetNumKeyVals - 1 do
  begin
    ADict.TryGetKeyVal(LIndex, LKeyValue);
    FOutput.Add(Format('%s |%s|=|%s|', [ATag, Escape(LKeyValue.Key), Escape(LKeyValue.Value)]));
  end;
end;

procedure TMapDump.Dump(const AMap: TMapFile);
var
  LEntityIndex, LPrimitiveIndex, LSideIndex, LVertexIndex: Integer;
  LEntity: TMapEntity;
  LPrimitive: TMapPrimitive;
  LBrush: TMapBrush;
  LSide: TMapBrushSide;
  LPatch: TMapPatch;
  LVertex: TMapPatchVertex;
  LS, LT: TIdVec4;
begin
  FOutput.Add('NAME |' + Escape(AMap.Name) + '|');
  FOutput.Add('VERSION ' + FloatBits(AMap.Version));
  FOutput.Add('FILETIME ' + IntToStr(AMap.FileTime));
  FOutput.Add('HASPRIM ' + IntToStr(Ord(AMap.HasPrimitiveData)));
  FOutput.Add('GEOCRC ' + Hex(AMap.GeometryCrc));
  FOutput.Add('ENTITIES ' + IntToStr(AMap.GetNumEntities));
  for LEntityIndex := 0 to AMap.GetNumEntities - 1 do
  begin
    LEntity := AMap.GetEntity(LEntityIndex);
    FOutput.Add(Format('ENT %d keys=%d prims=%d crc=%s', [LEntityIndex, LEntity.Epairs.GetNumKeyVals,
      LEntity.GetNumPrimitives, Hex(LEntity.GetGeometryCrc)]));
    DumpDict(' KV', LEntity.Epairs);
    for LPrimitiveIndex := 0 to LEntity.GetNumPrimitives - 1 do
    begin
      LPrimitive := LEntity.GetPrimitive(LPrimitiveIndex);
      if LPrimitive.PrimitiveType = mptBrush then
      begin
        LBrush := TMapBrush(LPrimitive);
        FOutput.Add(Format(' PRIM %d brush sides=%d crc=%s', [LPrimitiveIndex, LBrush.GetNumSides,
          Hex(LBrush.GetGeometryCrc)]));
        DumpDict('  EP', LBrush.Epairs);
        for LSideIndex := 0 to LBrush.GetNumSides - 1 do
        begin
          LSide := LBrush.GetSide(LSideIndex);
          LSide.GetTextureVectors(LS, LT);
          FOutput.Add(Format('  SIDE %s %s %s %s |%s|', [FloatBits(LSide.Plane.A), FloatBits(LSide.Plane.B),
            FloatBits(LSide.Plane.C), FloatBits(LSide.Plane.D), Escape(LSide.Material)]));
          FOutput.Add(Format('  TM %s %s %s %s %s %s', [FloatBits(LSide.TextureMatrix[0].X),
            FloatBits(LSide.TextureMatrix[0].Y), FloatBits(LSide.TextureMatrix[0].Z),
            FloatBits(LSide.TextureMatrix[1].X), FloatBits(LSide.TextureMatrix[1].Y),
            FloatBits(LSide.TextureMatrix[1].Z)]));
          FOutput.Add(Format('  TV %s %s %s %s %s %s %s %s', [FloatBits(LS.X), FloatBits(LS.Y), FloatBits(LS.Z),
            FloatBits(LS.W), FloatBits(LT.X), FloatBits(LT.Y), FloatBits(LT.Z), FloatBits(LT.W)]));
        end;
      end
      else
      begin
        LPatch := TMapPatch(LPrimitive);
        FOutput.Add(Format(' PRIM %d patch w=%d h=%d hs=%d vs=%d expl=%d crc=%s |%s|', [LPrimitiveIndex,
          LPatch.Width, LPatch.Height, LPatch.HorzSubdivisions, LPatch.VertSubdivisions,
          Ord(LPatch.ExplicitlySubdivided), Hex(LPatch.GetGeometryCrc), Escape(LPatch.Material)]));
        DumpDict('  EP', LPatch.Epairs);
        for LVertexIndex := 0 to LPatch.GetNumVertices - 1 do
        begin
          LVertex := LPatch.Vertices[LVertexIndex];
          FOutput.Add(Format('  V %d %s %s %s %s %s', [LVertexIndex, FloatBits(LVertex.Position.X),
            FloatBits(LVertex.Position.Y), FloatBits(LVertex.Position.Z), FloatBits(LVertex.S),
            FloatBits(LVertex.T)]));
        end;
      end;
    end;
  end;
end;

end.
