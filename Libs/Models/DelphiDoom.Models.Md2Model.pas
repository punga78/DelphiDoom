{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - the data of an MD2 model                    }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Md2Model;

interface

uses
  System.SysUtils,
  DelphiDoom.Models.Types,
  DelphiDoom.Models.Intf;

type
  /// <summary>
  ///   The frames of an MD2 model in memory (the old fields of TMD2Model without the OpenGL
  ///   display lists, that belong to the renderer). Every frame is its own array, so the pointer
  ///   to the vertexes of a frame does not move when other frames are added.
  /// </summary>
  TMd2Model = class(TInterfacedObject, IMd2Model)
  strict private
    type
      TFrameGroup = record
        Name: string;
        StartFrame: Integer;
        EndFrame: Integer;
      end;
  strict private
    FFrames: TArray<TArray<TModelVertex>>;
    FTexCoords: TArray<TModelTexCoord>;
    FGroups: TArray<TFrameGroup>;
    FVertexCount: Integer;
  public
    /// <summary>
    ///   The frames, the texture points and the name of the group of each frame (the same for
    ///   the frames of an animation: a frame that has the name of the previous ones extends its group)
    /// </summary>
    constructor Create(const AFrames: TArray<TArray<TModelVertex>>;
      const ATexCoords: TArray<TModelTexCoord>; const AGroupNames: TArray<string>);
    function GetFrameCount: Integer;
    function GetVertexCount: Integer;
    function GetFrameVertices(const AFrame: Integer): PModelVertex;
    function GetTexCoords: PModelTexCoord;
    function GetGroupCount: Integer;
    function GetGroupName(const AIndex: Integer): string;
    function GetGroupStartFrame(const AIndex: Integer): Integer;
    function GetGroupEndFrame(const AIndex: Integer): Integer;
    function FindGroup(const AName: string): Integer;
    function MergeFrames(const AOther: IMd2Model): Boolean;
  end;

implementation

{ TMd2Model }

constructor TMd2Model.Create(const AFrames: TArray<TArray<TModelVertex>>;
  const ATexCoords: TArray<TModelTexCoord>; const AGroupNames: TArray<string>);
var
  LFrame, LGroup: Integer;
begin
  inherited Create;
  FFrames := AFrames;
  FTexCoords := ATexCoords;
  if Length(AFrames) > 0 then
    FVertexCount := Length(AFrames[0]);
  for LFrame := 0 to High(AGroupNames) do
  begin
    LGroup := FindGroup(AGroupNames[LFrame]);
    if LGroup < 0 then
    begin
      SetLength(FGroups, Length(FGroups) + 1);
      FGroups[High(FGroups)].Name := AGroupNames[LFrame];
      FGroups[High(FGroups)].StartFrame := LFrame;
      FGroups[High(FGroups)].EndFrame := LFrame;
    end
    else
      FGroups[LGroup].EndFrame := LFrame;
  end;
end;

function TMd2Model.GetFrameCount: Integer;
begin
  Result := Length(FFrames);
end;

function TMd2Model.GetVertexCount: Integer;
begin
  Result := FVertexCount;
end;

function TMd2Model.GetFrameVertices(const AFrame: Integer): PModelVertex;
begin
  if (AFrame < 0) or (AFrame >= Length(FFrames)) then
    raise EModelsException.CreateFmt(SModelsInvalidFrame, [AFrame]);
  if FVertexCount = 0 then
    Result := nil
  else
    Result := @FFrames[AFrame][0];
end;

function TMd2Model.GetTexCoords: PModelTexCoord;
begin
  if Length(FTexCoords) = 0 then
    Result := nil
  else
    Result := @FTexCoords[0];
end;

function TMd2Model.GetGroupCount: Integer;
begin
  Result := Length(FGroups);
end;

function TMd2Model.GetGroupName(const AIndex: Integer): string;
begin
  if (AIndex >= 0) and (AIndex < Length(FGroups)) then
    Result := FGroups[AIndex].Name
  else
    Result := '';
end;

function TMd2Model.GetGroupStartFrame(const AIndex: Integer): Integer;
begin
  if (AIndex >= 0) and (AIndex < Length(FGroups)) then
    Result := FGroups[AIndex].StartFrame
  else
    Result := -1;
end;

function TMd2Model.GetGroupEndFrame(const AIndex: Integer): Integer;
begin
  if (AIndex >= 0) and (AIndex < Length(FGroups)) then
    Result := FGroups[AIndex].EndFrame
  else
    Result := -1;
end;

function TMd2Model.FindGroup(const AName: string): Integer;
var
  LIndex: Integer;
begin
  // the case does not count (the old list of names compared with AnsiCompareText)
  for LIndex := 0 to High(FGroups) do
    if AnsiCompareText(FGroups[LIndex].Name, AName) = 0 then
    begin
      Result := LIndex;
      Exit;
    end;
  Result := -1;
end;

function TMd2Model.MergeFrames(const AOther: IMd2Model): Boolean;
var
  LIndex, LOldFrameCount, LNewIndex: Integer;
begin
  Result := False;
  if not Assigned(AOther) then
    Exit;
  if AOther.VertexCount <> FVertexCount then
    Exit;

  LOldFrameCount := Length(FFrames);

  // the groups of the other model are added as they are, even with a name that is already here
  for LIndex := 0 to AOther.GroupCount - 1 do
  begin
    SetLength(FGroups, Length(FGroups) + 1);
    FGroups[High(FGroups)].Name := AOther.GetGroupName(LIndex);
    FGroups[High(FGroups)].StartFrame := AOther.GetGroupStartFrame(LIndex) + LOldFrameCount;
    FGroups[High(FGroups)].EndFrame := AOther.GetGroupEndFrame(LIndex) + LOldFrameCount;
  end;

  SetLength(FFrames, LOldFrameCount + AOther.FrameCount);
  for LIndex := 0 to AOther.FrameCount - 1 do
  begin
    LNewIndex := LOldFrameCount + LIndex;
    SetLength(FFrames[LNewIndex], FVertexCount);
    if FVertexCount > 0 then
      Move(AOther.GetFrameVertices(LIndex)^, FFrames[LNewIndex][0],
        FVertexCount * SizeOf(TModelVertex));
  end;
  Result := True;
end;

end.
