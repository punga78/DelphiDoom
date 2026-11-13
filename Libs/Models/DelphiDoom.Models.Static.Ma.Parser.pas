{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - static models: the Maya ASCII (MA) parser   }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software): renderer\Model_ma.cpp    }
{  (MA_Parse and the functions it calls). Copyright (C) 1999-2011 id Software  }
{  LLC, a ZeniMax Media company. This unit is derived from the Doom 3 GPL      }
{  source code and is therefore available under the GNU General Public         }
{  License, version 3, with the additional terms of the Doom 3 Source Code     }
{  License (see README.md of Libs\IdLib); the repository as a whole is GPL v2  }
{  or later.                                                                   }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Static.Ma.Parser;

{$Q-}
{$R-}

interface

uses
  System.SysUtils,
  DelphiDoom.Scanner.IdParser,
  DelphiDoom.IdLib.Math.Vec3,
  DelphiDoom.IdLib.Text.Token,
  DelphiDoom.Models.Static.Types,
  DelphiDoom.Models.Static.Ase.Types,
  DelphiDoom.Models.Static.Ma.Types;

type
  /// <summary>
  ///   Reads the text of a Maya ASCII file (MA_Parse): transforms, meshes (vertexes, edges,
  ///   normals, faces, colours, texture coordinates), file and material nodes and the
  ///   connections between them; at the end the materials are resolved and the transforms of
  ///   the parents are applied to the vertexes. The problems of the original (idException) are
  ///   EStaticModelException. The scanner is the preprocessing idParser, as in the original
  ///   (flag LEXFL_NOSTRINGCONCAT). Coordinates change from Y up (Maya) to Z up as the original
  ///   does.
  /// </summary>
  TMaParser = class
  strict private
    FResolver: TStaticPathResolver;
    FModel: TMaModel;
    FCurrent: TMaObject;
    FParser: TIdParser;
    FFileName: AnsiString;
    function IsNodeComplete(const AToken: TIdToken): Boolean;
    procedure ReadNodeHeader(out AName, AParent: AnsiString);
    procedure ReadAttribHeader(out AName: AnsiString; out ASize: Integer);
    function ReadHeaderIndex(const AName: AnsiString; const AHeaderType, ASkip: AnsiString;
      out AMin, AMax: Integer): Boolean;
    procedure ReadVec3(out AVector: TIdVec3);
    procedure SkipTypeToken(const AType: AnsiString);
    procedure CheckRange(const AWhat: string; const AMin, AMax, ACount: Integer);
    procedure ParseTransform;
    procedure ParseVertex(const AName: AnsiString; const ASize: Integer);
    procedure ParseVertexTransforms(const AName: AnsiString; ASize: Integer);
    procedure ParseEdge(const AName: AnsiString; const ASize: Integer);
    procedure ParseNormal(const AName: AnsiString; const ASize: Integer);
    procedure ParseFace(const AName: AnsiString; const ASize: Integer);
    procedure ParseColor(const AName: AnsiString; const ASize: Integer);
    procedure ParseTVert(const AName: AnsiString; const ASize: Integer);
    function QuickIsVertShared(const AFace, AVert: Integer): Boolean;
    procedure GetSharedFace(const AFace, AVert: Integer; out ASharedFace, ASharedVert: Integer);
    procedure ParseMesh;
    procedure ParseFileNode;
    procedure ParseMaterialNode;
    procedure ParseCreateNode;
    function AddMaterial(const AMaterialName: AnsiString): Integer;
    procedure ParseConnectAttr;
    procedure ApplyTransformation;
  public
    /// <summary>The resolver is OSPathToRelativePath for the paths of the pictures (nil keeps the path)</summary>
    constructor Create(const AResolver: TStaticPathResolver = nil);
    /// <summary>The model is the caller's to free</summary>
    function Parse(const AText: AnsiString; const AFileName: AnsiString): TMaModel;
  end;

implementation

uses
  DelphiDoom.IdLib.Math.Math,
  DelphiDoom.IdLib.Text.Types;

function Icmp(const AToken: TIdToken; const AText: AnsiString): Boolean;
begin
  Result := CompareText(string(AToken.Text), string(AText)) = 0;
end;

function Contains(const AText, ASub: AnsiString): Boolean;
begin
  Result := Pos(string(ASub), string(AText)) > 0;
end;

{ TMaParser }

constructor TMaParser.Create(const AResolver: TStaticPathResolver);
begin
  inherited Create;
  FResolver := AResolver;
end;

function TMaParser.IsNodeComplete(const AToken: TIdToken): Boolean;
begin
  Result := Icmp(AToken, 'createNode') or Icmp(AToken, 'connectAttr') or Icmp(AToken, 'select');
end;

procedure TMaParser.ReadNodeHeader(out AName, AParent: AnsiString);
var
  LToken: TIdToken;
begin
  AName := '';
  AParent := '';
  LToken := TIdToken.Create;
  while FParser.ReadToken(LToken) do
    if Icmp(LToken, '-') then
    begin
      FParser.ReadToken(LToken);
      if Icmp(LToken, 'n') then
      begin
        FParser.ReadToken(LToken);
        AName := LToken.Text;
      end
      else if Icmp(LToken, 'p') then
      begin
        FParser.ReadToken(LToken);
        AParent := LToken.Text;
      end;
    end
    else if Icmp(LToken, ';') then
      Break;
end;

function TMaParser.ReadHeaderIndex(const AName: AnsiString; const AHeaderType, ASkip: AnsiString;
  out AMin, AMax: Integer): Boolean;
var
  LMini: TIdParser;
  LToken: TIdToken;
begin
  AMin := 0;
  AMax := 0;
  LMini := TIdParser.Create;
  try
    LToken := TIdToken.Create;
    LMini.LoadMemory(AName, Length(AName), AHeaderType);
    if ASkip <> '' then
      LMini.SkipUntilString(ASkip);
    if not LMini.SkipUntilString('[') then
      Exit(False);
    AMin := LMini.ParseInt;
    LMini.ReadToken(LToken);
    if Icmp(LToken, ']') then
      AMax := AMin
    else
      AMax := LMini.ParseInt;
    Result := True;
  finally
    LMini.Free;
  end;
end;

procedure TMaParser.ReadAttribHeader(out AName: AnsiString; out ASize: Integer);
var
  LToken: TIdToken;
begin
  ASize := 0;
  LToken := TIdToken.Create;
  FParser.ReadToken(LToken);
  if Icmp(LToken, '-') then
  begin
    FParser.ReadToken(LToken);
    if Icmp(LToken, 's') then
    begin
      ASize := FParser.ParseInt;
      FParser.ReadToken(LToken);
    end;
  end;
  AName := LToken.Text;
end;

procedure TMaParser.ReadVec3(out AVector: TIdVec3);
begin
  if not FParser.SkipUntilString('double3') then
    raise EStaticModelException.CreateAtLine(Format(SMaInvalidVec3, [string(FFileName)]), 0);
  // we need to flip y and z because of the maya coordinate system
  AVector.X := FParser.ParseFloat;
  AVector.Z := FParser.ParseFloat;
  AVector.Y := FParser.ParseFloat;
end;

procedure TMaParser.SkipTypeToken(const AType: AnsiString);
var
  LToken, LSecond: TIdToken;
begin
  LToken := TIdToken.Create;
  LSecond := TIdToken.Create;
  FParser.ReadToken(LToken);
  if Icmp(LToken, '-') then
  begin
    FParser.ReadToken(LSecond);
    if Icmp(LSecond, 'type') then
      FParser.SkipUntilString(AType)
    else
    begin
      FParser.UnreadToken(LSecond);
      FParser.UnreadToken(LToken);
    end;
  end
  else
    FParser.UnreadToken(LToken);
end;

procedure TMaParser.CheckRange(const AWhat: string; const AMin, AMax, ACount: Integer);
var
  LValue: Integer;
begin
  if (AMin < 0) or (AMax >= ACount) then
  begin
    if AMin < 0 then
      LValue := AMin
    else
      LValue := AMax;
    raise EStaticModelException.CreateAtLine(Format(SMaIndexRange, [string(FFileName), AWhat, LValue, ACount]), 0);
  end;
end;

procedure TMaParser.ParseTransform;
var
  LName, LParent: AnsiString;
  LTransform: TMaTransform;
  LToken: TIdToken;
  LVector: TIdVec3;
begin
  LTransform := FModel.Own(TMaTransform.Create);
  LTransform.Scale := TIdVec3.Create(1, 1, 1);
  ReadNodeHeader(LName, LParent);
  LToken := TIdToken.Create;
  while FParser.ReadToken(LToken) do
  begin
    if IsNodeComplete(LToken) then
    begin
      FParser.UnreadToken(LToken);
      Break;
    end;
    if Icmp(LToken, 'setAttr') then
    begin
      FParser.ReadToken(LToken);
      if Icmp(LToken, '.t') then
      begin
        ReadVec3(LVector);
        LTransform.Translate := LVector;
        LTransform.Translate.Y := LTransform.Translate.Y * -1;
      end
      else if Icmp(LToken, '.r') then
      begin
        ReadVec3(LVector);
        LTransform.Rotate := LVector;
      end
      else if Icmp(LToken, '.s') then
      begin
        ReadVec3(LVector);
        LTransform.Scale := LVector;
      end
      else
        FParser.SkipRestOfLine;
    end;
  end;
  if (LParent <> '') and FModel.Transforms.ContainsKey(LParent) then
    LTransform.Parent := FModel.Transforms[LParent];
  FModel.Transforms.AddOrSetValue(LName, LTransform);
end;

procedure TMaParser.ParseVertex(const AName: AnsiString; const ASize: Integer);
var
  LMin, LMax, LIndex: Integer;
begin
  // allocate enough space for all the verts if this is the first attribute for vertexes
  if not FCurrent.Mesh.HasVertexes then
  begin
    SetLength(FCurrent.Mesh.Vertexes, ASize);
    FCurrent.Mesh.HasVertexes := True;
  end;
  if not ReadHeaderIndex(AName, 'VertexHeader', '', LMin, LMax) then
    Exit;
  CheckRange('vertex', LMin, LMax, Length(FCurrent.Mesh.Vertexes));
  for LIndex := LMin to LMax do
  begin
    FCurrent.Mesh.Vertexes[LIndex].X := FParser.ParseFloat;
    FCurrent.Mesh.Vertexes[LIndex].Z := FParser.ParseFloat;
    FCurrent.Mesh.Vertexes[LIndex].Y := -FParser.ParseFloat;
  end;
end;

procedure TMaParser.ParseVertexTransforms(const AName: AnsiString; ASize: Integer);
var
  LMin, LMax, LIndex: Integer;
begin
  if not FCurrent.Mesh.HasVertTransforms then
  begin
    if ASize = 0 then
      ASize := 1;
    SetLength(FCurrent.Mesh.VertTransforms, ASize);
    FCurrent.Mesh.NextVertTransformIndex := 0;
    FCurrent.Mesh.HasVertTransforms := True;
  end;
  if not ReadHeaderIndex(AName, 'VertexTransformHeader', '', LMin, LMax) then
    Exit;
  SkipTypeToken('float3');
  CheckRange('vertex transform', FCurrent.Mesh.NextVertTransformIndex,
    FCurrent.Mesh.NextVertTransformIndex + (LMax - LMin), Length(FCurrent.Mesh.VertTransforms));
  for LIndex := LMin to LMax do
  begin
    with FCurrent.Mesh do
    begin
      VertTransforms[NextVertTransformIndex].X := FParser.ParseFloat;
      VertTransforms[NextVertTransformIndex].Z := FParser.ParseFloat;
      VertTransforms[NextVertTransformIndex].Y := -FParser.ParseFloat;
      // w holds the vert index
      VertTransforms[NextVertTransformIndex].W := LIndex;
      Inc(NextVertTransformIndex);
    end;
  end;
end;

procedure TMaParser.ParseEdge(const AName: AnsiString; const ASize: Integer);
var
  LMin, LMax, LIndex: Integer;
begin
  if not FCurrent.Mesh.HasEdges then
  begin
    SetLength(FCurrent.Mesh.Edges, ASize);
    FCurrent.Mesh.HasEdges := True;
  end;
  if not ReadHeaderIndex(AName, 'EdgeHeader', '', LMin, LMax) then
    Exit;
  CheckRange('edge', LMin, LMax, Length(FCurrent.Mesh.Edges));
  for LIndex := LMin to LMax do
  begin
    FCurrent.Mesh.Edges[LIndex].X := FParser.ParseFloat;
    FCurrent.Mesh.Edges[LIndex].Y := FParser.ParseFloat;
    FCurrent.Mesh.Edges[LIndex].Z := FParser.ParseFloat;
  end;
end;

procedure TMaParser.ParseNormal(const AName: AnsiString; const ASize: Integer);
var
  LMin, LMax, LIndex: Integer;
begin
  if not FCurrent.Mesh.HasNormals then
  begin
    SetLength(FCurrent.Mesh.Normals, ASize);
    FCurrent.Mesh.HasNormals := True;
  end;
  if not ReadHeaderIndex(AName, 'NormalHeader', '', LMin, LMax) then
    Exit;
  SkipTypeToken('float3');
  CheckRange('normal', LMin, LMax, Length(FCurrent.Mesh.Normals));
  for LIndex := LMin to LMax do
  begin
    FCurrent.Mesh.Normals[LIndex].X := FParser.ParseFloat;
    // adjust the normals for the change in coordinate systems
    FCurrent.Mesh.Normals[LIndex].Z := FParser.ParseFloat;
    FCurrent.Mesh.Normals[LIndex].Y := -FParser.ParseFloat;
    FCurrent.Mesh.Normals[LIndex].Normalize;
  end;
  FCurrent.Mesh.NormalsParsed := True;
  FCurrent.Mesh.NextNormal := 0;
end;

procedure TMaParser.ParseFace(const AName: AnsiString; const ASize: Integer);
var
  LMin, LMax, LCurrent, LCount, LCorner: Integer;
  LToken: TIdToken;

  procedure Need(const AMessage: string);
  begin
    if LCount <> 3 then
      raise EStaticModelException.CreateAtLine(Format(AMessage, [string(FFileName)]), 0);
  end;

  procedure InFace;
  begin
    if (LCurrent < 0) or (LCurrent >= Length(FCurrent.Mesh.Faces)) then
      raise EStaticModelException.CreateAtLine(Format(SMaIndexRange,
        [string(FFileName), 'face', LCurrent, Length(FCurrent.Mesh.Faces)]), 0);
  end;

begin
  if not FCurrent.Mesh.HasFaces then
  begin
    SetLength(FCurrent.Mesh.Faces, ASize);
    FCurrent.Mesh.HasFaces := True;
  end;
  if not ReadHeaderIndex(AName, 'FaceHeader', '', LMin, LMax) then
    Exit;
  LToken := TIdToken.Create;
  LCurrent := LMin - 1;
  while FParser.ReadToken(LToken) do
  begin
    if IsNodeComplete(LToken) then
    begin
      FParser.UnreadToken(LToken);
      Break;
    end;
    if Icmp(LToken, 'f') then
    begin
      LCount := FParser.ParseInt;
      Need(SMaNotTriangle);
      // a new face always starts with an "f" token
      Inc(LCurrent);
      InFace;
      // the edges are not reordered until later: the normal processing assumes the original order
      for LCorner := 0 to 2 do
        FCurrent.Mesh.Faces[LCurrent].Edge[LCorner] := FParser.ParseInt;
      for LCorner := 0 to 2 do
        FCurrent.Mesh.Faces[LCurrent].VertexColors[LCorner] := -1;
    end
    else if Icmp(LToken, 'mu') then
    begin
      FParser.ParseInt;
      LCount := FParser.ParseInt;
      Need(SMaInvalidTexCoords);
      InFace;
      for LCorner := 0 to 2 do
        FCurrent.Mesh.Faces[LCurrent].TVertexNum[LCorner] := FParser.ParseInt;
    end
    else if Icmp(LToken, 'mf') then
    begin
      LCount := FParser.ParseInt;
      Need(SMaInvalidTexCoords);
      InFace;
      for LCorner := 0 to 2 do
        FCurrent.Mesh.Faces[LCurrent].TVertexNum[LCorner] := FParser.ParseInt;
    end
    else if Icmp(LToken, 'fc') then
    begin
      LCount := FParser.ParseInt;
      Need(SMaInvalidColor);
      InFace;
      for LCorner := 0 to 2 do
        FCurrent.Mesh.Faces[LCurrent].VertexColors[LCorner] := FParser.ParseInt;
    end;
  end;
end;

procedure TMaParser.ParseColor(const AName: AnsiString; const ASize: Integer);
var
  LMin, LMax, LIndex, LComponent: Integer;
begin
  if not FCurrent.Mesh.HasColors then
  begin
    SetLength(FCurrent.Mesh.Colors, ASize * 4);
    FCurrent.Mesh.HasColors := True;
  end;
  if not ReadHeaderIndex(AName, 'ColorHeader', '', LMin, LMax) then
    Exit;
  CheckRange('color', LMin, LMax, Length(FCurrent.Mesh.Colors) div 4);
  for LIndex := LMin to LMax do
    for LComponent := 0 to 3 do
      FCurrent.Mesh.Colors[LIndex * 4 + LComponent] := Byte(Trunc(FParser.ParseFloat * 255));
end;

procedure TMaParser.ParseTVert(const AName: AnsiString; const ASize: Integer);
var
  LMin, LMax, LIndex: Integer;
begin
  // this is not the texture coordinates: it is just the name, so ignore it
  if Contains(AName, 'uvsn') then
    Exit;
  if not FCurrent.Mesh.HasTVertexes then
  begin
    SetLength(FCurrent.Mesh.TVertexes, ASize);
    FCurrent.Mesh.HasTVertexes := True;
  end;
  if not ReadHeaderIndex(AName, 'TextureCoordHeader', 'uvsp', LMin, LMax) then
    Exit;
  SkipTypeToken('float2');
  CheckRange('texture coordinate', LMin, LMax, Length(FCurrent.Mesh.TVertexes));
  for LIndex := LMin to LMax do
  begin
    FCurrent.Mesh.TVertexes[LIndex].X := FParser.ParseFloat;
    FCurrent.Mesh.TVertexes[LIndex].Y := 1.0 - FParser.ParseFloat;
  end;
end;

function TMaParser.QuickIsVertShared(const AFace, AVert: Integer): Boolean;
var
  LVertNum, LEdgeIndex, LEdge: Integer;
begin
  LVertNum := FCurrent.Mesh.Faces[AFace].VertexNum[AVert];
  for LEdgeIndex := 0 to 2 do
  begin
    LEdge := FCurrent.Mesh.Faces[AFace].Edge[LEdgeIndex];
    if LEdge < 0 then
      LEdge := Abs(LEdge) - 1;
    if (FCurrent.Mesh.Edges[LEdge].Z = 1) and
      ((FCurrent.Mesh.Edges[LEdge].X = LVertNum) or (FCurrent.Mesh.Edges[LEdge].Y = LVertNum)) then
      Exit(True);
  end;
  Result := False;
end;

procedure TMaParser.GetSharedFace(const AFace, AVert: Integer; out ASharedFace, ASharedVert: Integer);
var
  LVertNum, LEdgeIndex, LEdge, LFace, LCorner: Integer;
begin
  LVertNum := FCurrent.Mesh.Faces[AFace].VertexNum[AVert];
  ASharedFace := -1;
  ASharedVert := -1;
  // find a shared edge on this face that contains the specified vert
  for LEdgeIndex := 0 to 2 do
  begin
    LEdge := FCurrent.Mesh.Faces[AFace].Edge[LEdgeIndex];
    if LEdge < 0 then
      LEdge := Abs(LEdge) - 1;
    if (FCurrent.Mesh.Edges[LEdge].Z = 1) and
      ((FCurrent.Mesh.Edges[LEdge].X = LVertNum) or (FCurrent.Mesh.Edges[LEdge].Y = LVertNum)) then
      for LFace := 0 to AFace - 1 do
        for LCorner := 0 to 2 do
          if FCurrent.Mesh.Faces[LFace].VertexNum[LCorner] = LVertNum then
          begin
            ASharedFace := LFace;
            ASharedVert := LCorner;
            // the original breaks out of the inner loop only
            Break;
          end;
    if ASharedFace <> -1 then
      Break;
  end;
end;

procedure TMaParser.ParseMesh;
var
  LName, LParent, LAttribName: AnsiString;
  LAttribSize, LFace, LCorner, LSharedFace, LSharedVert, LEdge, LTemp, LIndex: Integer;
  LToken: TIdToken;
  LTempVec: TIdVec3;
begin
  FCurrent := TMaObject.Create;
  FModel.Objects.Add(FCurrent);
  FCurrent.MaterialRef := -1;
  ReadNodeHeader(LName, LParent);
  // find my parent
  if (LParent <> '') and FModel.Transforms.ContainsKey(LParent) then
    FCurrent.Mesh.Transform := FModel.Transforms[LParent];
  FCurrent.Name := LName;
  LToken := TIdToken.Create;
  while FParser.ReadToken(LToken) do
  begin
    if IsNodeComplete(LToken) then
    begin
      FParser.UnreadToken(LToken);
      Break;
    end;
    if Icmp(LToken, 'setAttr') then
    begin
      ReadAttribHeader(LAttribName, LAttribSize);
      if Contains(LAttribName, '.vt') then
        ParseVertex(LAttribName, LAttribSize)
      else if Contains(LAttribName, '.ed') then
        ParseEdge(LAttribName, LAttribSize)
      else if Contains(LAttribName, '.pt') then
        ParseVertexTransforms(LAttribName, LAttribSize)
      else if Contains(LAttribName, '.n') then
        ParseNormal(LAttribName, LAttribSize)
      else if Contains(LAttribName, '.fc') then
        ParseFace(LAttribName, LAttribSize)
      else if Contains(LAttribName, '.clr') then
        ParseColor(LAttribName, LAttribSize)
      else if Contains(LAttribName, '.uvst') then
        ParseTVert(LAttribName, LAttribSize)
      else
        FParser.SkipRestOfLine;
    end;
  end;

  with FCurrent.Mesh do
  begin
    // get the verts from the edge
    for LFace := 0 to High(Faces) do
      for LCorner := 0 to 2 do
      begin
        LEdge := Faces[LFace].Edge[LCorner];
        if LEdge < 0 then
        begin
          LEdge := Abs(LEdge) - 1;
          CheckRange('edge', LEdge, LEdge, Length(Edges));
          Faces[LFace].VertexNum[LCorner] := Trunc(Edges[LEdge].Y);
        end
        else
        begin
          CheckRange('edge', LEdge, LEdge, Length(Edges));
          Faces[LFace].VertexNum[LCorner] := Trunc(Edges[LEdge].X);
        end;
      end;

    // get the normals
    if NormalsParsed then
      for LFace := 0 to High(Faces) do
        for LCorner := 0 to 2 do
        begin
          // is this vertex shared
          LSharedFace := -1;
          LSharedVert := -1;
          if QuickIsVertShared(LFace, LCorner) then
            GetSharedFace(LFace, LCorner, LSharedFace, LSharedVert);
          if LSharedFace <> -1 then
            // get the normal from the share
            Faces[LFace].VertexNormals[LCorner] := Faces[LSharedFace].VertexNormals[LSharedVert]
          else
          begin
            // the vertex is not shared so get the next normal
            if NextNormal >= Length(Normals) then
              // we are using more normals than exist
              raise EStaticModelException.CreateAtLine(Format(SMaInvalidNormals, [string(FFileName)]), 0);
            Faces[LFace].VertexNormals[LCorner] := Normals[NextNormal];
            Inc(NextNormal);
          end;
        end;

    // now that the normals are good, reorder the verts to make the tris face the right way
    for LFace := 0 to High(Faces) do
    begin
      LTemp := Faces[LFace].VertexNum[1];
      Faces[LFace].VertexNum[1] := Faces[LFace].VertexNum[2];
      Faces[LFace].VertexNum[2] := LTemp;
      LTempVec := Faces[LFace].VertexNormals[1];
      Faces[LFace].VertexNormals[1] := Faces[LFace].VertexNormals[2];
      Faces[LFace].VertexNormals[2] := LTempVec;
      LTemp := Faces[LFace].TVertexNum[1];
      Faces[LFace].TVertexNum[1] := Faces[LFace].TVertexNum[2];
      Faces[LFace].TVertexNum[2] := LTemp;
      LTemp := Faces[LFace].VertexColors[1];
      Faces[LFace].VertexColors[1] := Faces[LFace].VertexColors[2];
      Faces[LFace].VertexColors[2] := LTemp;
    end;

    // now apply the pt transformations
    for LIndex := 0 to Length(VertTransforms) - 1 do
    begin
      CheckRange('vertex', Trunc(VertTransforms[LIndex].W), Trunc(VertTransforms[LIndex].W), Length(Vertexes));
      Vertexes[Trunc(VertTransforms[LIndex].W)] := Vertexes[Trunc(VertTransforms[LIndex].W)] +
        TIdVec3.Create(VertTransforms[LIndex].X, VertTransforms[LIndex].Y, VertTransforms[LIndex].Z);
    end;
  end;
end;

procedure TMaParser.ParseFileNode;
var
  LName, LParent, LAttribName: AnsiString;
  LAttribSize: Integer;
  LToken: TIdToken;
  LNode: TMaFileNode;
begin
  ReadNodeHeader(LName, LParent);
  LToken := TIdToken.Create;
  while FParser.ReadToken(LToken) do
  begin
    if IsNodeComplete(LToken) then
    begin
      FParser.UnreadToken(LToken);
      Break;
    end;
    if Icmp(LToken, 'setAttr') then
    begin
      ReadAttribHeader(LAttribName, LAttribSize);
      if Contains(LAttribName, '.ftn') then
      begin
        FParser.SkipUntilString('string');
        FParser.ReadToken(LToken);
        if Icmp(LToken, '(') then
          FParser.ReadToken(LToken);
        LNode := FModel.Own(TMaFileNode.Create);
        LNode.Name := LName;
        LNode.Path := LToken.Text;
        FModel.FileNodes.AddOrSetValue(LNode.Name, LNode);
      end
      else
        FParser.SkipRestOfLine;
    end;
  end;
end;

procedure TMaParser.ParseMaterialNode;
var
  LName, LParent: AnsiString;
  LNode: TMaMaterialNode;
begin
  ReadNodeHeader(LName, LParent);
  LNode := FModel.Own(TMaMaterialNode.Create);
  LNode.Name := LName;
  FModel.MaterialNodes.AddOrSetValue(LNode.Name, LNode);
end;

procedure TMaParser.ParseCreateNode;
var
  LToken: TIdToken;
begin
  LToken := TIdToken.Create;
  FParser.ReadToken(LToken);
  if Icmp(LToken, 'transform') then
    ParseTransform
  else if Icmp(LToken, 'mesh') then
    ParseMesh
  else if Icmp(LToken, 'file') then
    ParseFileNode
  else if Icmp(LToken, 'shadingEngine') or Icmp(LToken, 'lambert') or Icmp(LToken, 'phong') or
    Icmp(LToken, 'blinn') then
    ParseMaterialNode;
end;

function TMaParser.AddMaterial(const AMaterialName: AnsiString): Integer;
var
  LNode: TMaMaterialNode;
  LPath: AnsiString;
begin
  Result := -1;
  if not FModel.MaterialNodes.TryGetValue(AMaterialName, LNode) then
    Exit;
  // iterate down the tree until we get a file
  while Assigned(LNode) and not Assigned(LNode.FileNode) do
    LNode := LNode.Child;
  if Assigned(LNode) and Assigned(LNode.FileNode) then
  begin
    // remove the OS stuff
    LPath := LNode.FileNode.Path;
    if Assigned(FResolver) then
      LPath := FResolver(LPath);
    FModel.Materials.Add(LPath);
    Result := FModel.Materials.Count - 1;
  end;
end;

procedure TMaParser.ParseConnectAttr;
var
  LToken: TIdToken;
  LTemp, LSrcName, LSrcType, LDestName, LDestType: AnsiString;
  LDot, LIndex: Integer;
  LMaterial, LDestNode: TMaMaterialNode;
  LFileNode: TMaFileNode;
begin
  LToken := TIdToken.Create;
  FParser.ReadToken(LToken);
  LTemp := LToken.Text;
  LDot := Pos('.', string(LTemp));
  if LDot = 0 then
    raise EStaticModelException.CreateAtLine(Format(SMaInvalidConnect, [string(FFileName)]), 0);
  LSrcName := Copy(LTemp, 1, LDot - 1);
  LSrcType := Copy(LTemp, LDot + 1, MaxInt);
  FParser.ReadToken(LToken);
  LTemp := LToken.Text;
  LDot := Pos('.', string(LTemp));
  if LDot = 0 then
    raise EStaticModelException.CreateAtLine(Format(SMaInvalidConnect, [string(FFileName)]), 0);
  LDestName := Copy(LTemp, 1, LDot - 1);
  LDestType := Copy(LTemp, LDot + 1, MaxInt);

  if Contains(LSrcType, 'oc') then
  begin
    // is this attribute a material node attribute
    if FModel.MaterialNodes.TryGetValue(LSrcName, LMaterial) then
      if FModel.MaterialNodes.TryGetValue(LDestName, LDestNode) then
        LDestNode.Child := LMaterial;
    // is this attribute a file node
    if FModel.FileNodes.TryGetValue(LSrcName, LFileNode) then
      if FModel.MaterialNodes.TryGetValue(LDestName, LDestNode) then
        LDestNode.FileNode := LFileNode;
  end;
  if Contains(LSrcType, 'iog') then
    // is this an attribute for one of our meshes
    for LIndex := 0 to FModel.Objects.Count - 1 do
      if FModel.Objects[LIndex].Name = LSrcName then
      begin
        FModel.Objects[LIndex].MaterialName := LDestName;
        Break;
      end;
end;

procedure TMaParser.ApplyTransformation;
var
  LObject, LVertex: Integer;
  LMesh: ^TMaMesh;
  LTransform: TMaTransform;
  LSin, LCos, X, Y, Z, NX, NY, NZ: Single;
  LRotateX, LRotateY, LRotateZ: Boolean;
  LRotX, LRotY, LRotZ: Single;
begin
  for LObject := 0 to FModel.Objects.Count - 1 do
  begin
    LMesh := @FModel.Objects[LObject].Mesh;
    LTransform := LMesh^.Transform;
    while Assigned(LTransform) do
    begin
      LRotateX := Abs(LTransform.Rotate.X) > 0.0;
      LRotateY := Abs(LTransform.Rotate.Y) > 0.0;
      LRotateZ := Abs(LTransform.Rotate.Z) > 0.0;
      LRotX := 0;
      LRotY := 0;
      LRotZ := 0;
      if LRotateX then
        LRotX := (-LTransform.Rotate.X) * ID_DEG2RAD;
      if LRotateY then
        LRotY := LTransform.Rotate.Y * ID_DEG2RAD;
      if LRotateZ then
        LRotZ := (-LTransform.Rotate.Z) * ID_DEG2RAD;
      // apply the transformation to each vert
      for LVertex := 0 to High(LMesh^.Vertexes) do
      begin
        X := LMesh^.Vertexes[LVertex].X;
        Y := LMesh^.Vertexes[LVertex].Y;
        Z := LMesh^.Vertexes[LVertex].Z;
        // scale
        NX := LTransform.Scale.X * X + 0 * Y + 0 * Z + 0;
        NY := 0 * X + LTransform.Scale.Y * Y + 0 * Z + 0;
        NZ := 0 * X + 0 * Y + LTransform.Scale.Z * Z + 0;
        X := NX;
        Y := NY;
        Z := NZ;
        // x rotation
        LSin := TIdMath.Sin(LRotX);
        LCos := TIdMath.Cos(LRotX);
        if not LRotateX then
        begin
          LSin := 0;
          LCos := 1;
        end;
        NX := 1 * X + 0 * Y + 0 * Z + 0;
        NY := 0 * X + LCos * Y + LSin * Z + 0;
        NZ := 0 * X + (-LSin) * Y + LCos * Z + 0;
        X := NX;
        Y := NY;
        Z := NZ;
        // z rotation
        LSin := TIdMath.Sin(LRotZ);
        LCos := TIdMath.Cos(LRotZ);
        if not LRotateZ then
        begin
          LSin := 0;
          LCos := 1;
        end;
        NX := LCos * X + LSin * Y + 0 * Z + 0;
        NY := (-LSin) * X + LCos * Y + 0 * Z + 0;
        NZ := 0 * X + 0 * Y + 1 * Z + 0;
        X := NX;
        Y := NY;
        Z := NZ;
        // y rotation
        LSin := TIdMath.Sin(LRotY);
        LCos := TIdMath.Cos(LRotY);
        if not LRotateY then
        begin
          LSin := 0;
          LCos := 1;
        end;
        NX := LCos * X + 0 * Y + (-LSin) * Z + 0;
        NY := 0 * X + 1 * Y + 0 * Z + 0;
        NZ := LSin * X + 0 * Y + LCos * Z + 0;
        LMesh^.Vertexes[LVertex].X := NX + LTransform.Translate.X;
        LMesh^.Vertexes[LVertex].Y := NY + LTransform.Translate.Y;
        LMesh^.Vertexes[LVertex].Z := NZ + LTransform.Translate.Z;
      end;
      LTransform := LTransform.Parent;
    end;
  end;
end;

function TMaParser.Parse(const AText: AnsiString; const AFileName: AnsiString): TMaModel;
var
  LToken: TIdToken;
  LIndex: Integer;
begin
  FFileName := AFileName;
  FModel := TMaModel.Create;
  Result := FModel;
  FCurrent := nil;
  FParser := TIdParser.Create(LEXFL_NOSTRINGCONCAT);
  try
    try
      FParser.LoadMemory(AText, Length(AText), AFileName);
      LToken := TIdToken.Create;
      while FParser.ReadToken(LToken) do
        if Icmp(LToken, 'createNode') then
          ParseCreateNode
        else if Icmp(LToken, 'connectAttr') then
          ParseConnectAttr;
      // resolve the materials
      for LIndex := 0 to FModel.Objects.Count - 1 do
        FModel.Objects[LIndex].MaterialRef := AddMaterial(FModel.Objects[LIndex].MaterialName);
      ApplyTransformation;
    except
      FreeAndNil(FModel);
      raise;
    end;
  finally
    FreeAndNil(FParser);
  end;
  Result := FModel;
end;

end.
