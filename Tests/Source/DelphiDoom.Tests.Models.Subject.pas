{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the 3D models library - the new classes as subject     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Models.Subject;

interface

uses
  System.SysUtils,
  DelphiDoom.Models.Types,
  DelphiDoom.Models.Intf,
  DelphiDoom.Tests.Models.Scenarios;

type
  /// <summary>The classes of the library, asked by the scenarios of parity</summary>
  TModelsSubject = class(TInterfacedObject, IModelsSubject)
  strict private
    FParser: IMd2Parser;
    FStream: IModelCommandStream;
    class procedure DumpModel(const AModel: IMd2Model; out ADump: TMd2Dump); static;
  public
    constructor Create;
    function LoadMd2(const ABytes: TBytes; const APlacement: TModelPlacement;
      out ADump: TMd2Dump): Boolean;
    function MergeMd2(const AFirst, ASecond: TBytes; const APlacement: TModelPlacement;
      out ADump: TMd2Dump): Boolean;
    function GroupName(const AFrameName: string): string;
    procedure StreamReset;
    procedure StreamAdd(const ACommand: Integer; const AParam0, AParam1, AParam2, AParam3: Single);
    procedure StreamSetFrame(const AFrame: Integer);
    procedure StreamIdentify;
    function StreamFrameCount: Integer;
    function StreamFrame(const AIndex: Integer): Integer;
    function StreamIndexOf(const AFrame: Integer): Integer;
    function StreamSave: TBytes;
    function StreamLoad(const ABytes: TBytes): Boolean;
    function StreamCommandCount: Integer;
    function StreamPlay(const AFrame, AMaxDepth: Integer): string;
  end;

implementation

uses
  DelphiDoom.Models.Factory,
  DelphiDoom.Models.Md2Parser;

{ TModelsSubject }

constructor TModelsSubject.Create;
begin
  inherited Create;
  FParser := TModelsFactory.CreateMd2Parser;
  FStream := TModelsFactory.CreateCommandStream;
end;

class procedure TModelsSubject.DumpModel(const AModel: IMd2Model; out ADump: TMd2Dump);
var
  LFrame, LIndex, LTarget: Integer;
  LVertex: PModelVertex;
  LTexCoord: PModelTexCoord;
begin
  ADump.FrameCount := AModel.FrameCount;
  ADump.VertexCount := AModel.VertexCount;
  SetLength(ADump.Vertices, AModel.FrameCount * AModel.VertexCount * 3);
  LTarget := 0;
  for LFrame := 0 to AModel.FrameCount - 1 do
  begin
    LVertex := AModel.GetFrameVertices(LFrame);
    for LIndex := 0 to AModel.VertexCount - 1 do
    begin
      ADump.Vertices[LTarget] := LVertex^.X;
      ADump.Vertices[LTarget + 1] := LVertex^.Y;
      ADump.Vertices[LTarget + 2] := LVertex^.Z;
      Inc(LTarget, 3);
      Inc(LVertex);
    end;
  end;
  SetLength(ADump.TexCoords, AModel.VertexCount * 2);
  LTexCoord := AModel.GetTexCoords;
  for LIndex := 0 to AModel.VertexCount - 1 do
  begin
    ADump.TexCoords[LIndex * 2] := LTexCoord^.U;
    ADump.TexCoords[LIndex * 2 + 1] := LTexCoord^.V;
    Inc(LTexCoord);
  end;
  SetLength(ADump.GroupNames, AModel.GroupCount);
  SetLength(ADump.GroupStarts, AModel.GroupCount);
  SetLength(ADump.GroupEnds, AModel.GroupCount);
  for LIndex := 0 to AModel.GroupCount - 1 do
  begin
    ADump.GroupNames[LIndex] := AModel.GetGroupName(LIndex);
    ADump.GroupStarts[LIndex] := AModel.GetGroupStartFrame(LIndex);
    ADump.GroupEnds[LIndex] := AModel.GetGroupEndFrame(LIndex);
  end;
end;

function TModelsSubject.LoadMd2(const ABytes: TBytes; const APlacement: TModelPlacement;
  out ADump: TMd2Dump): Boolean;
begin
  DumpModel(FParser.Parse(ABytes, APlacement), ADump);
  Result := True;
end;

function TModelsSubject.MergeMd2(const AFirst, ASecond: TBytes; const APlacement: TModelPlacement;
  out ADump: TMd2Dump): Boolean;
var
  LModel: IMd2Model;
begin
  LModel := FParser.Parse(AFirst, APlacement);
  Result := LModel.MergeFrames(FParser.Parse(ASecond, APlacement));
  DumpModel(LModel, ADump);
end;

function TModelsSubject.GroupName(const AFrameName: string): string;
begin
  Result := TMd2Parser.GroupNameOf(AFrameName);
end;

procedure TModelsSubject.StreamReset;
begin
  FStream := TModelsFactory.CreateCommandStream;
end;

procedure TModelsSubject.StreamAdd(const ACommand: Integer; const AParam0, AParam1, AParam2,
  AParam3: Single);
begin
  FStream.AddCommand(ACommand, AParam0, AParam1, AParam2, AParam3);
end;

procedure TModelsSubject.StreamSetFrame(const AFrame: Integer);
begin
  FStream.CurrentFrame := AFrame;
  FStream.AddCommand(MODEL_CMD_SETFRAME, AFrame);
end;

procedure TModelsSubject.StreamIdentify;
begin
  FStream.IdentifyFrames;
end;

function TModelsSubject.StreamFrameCount: Integer;
begin
  Result := FStream.FrameCount;
end;

function TModelsSubject.StreamFrame(const AIndex: Integer): Integer;
begin
  Result := FStream.Frames[AIndex];
end;

function TModelsSubject.StreamIndexOf(const AFrame: Integer): Integer;
begin
  Result := FStream.IndexOfFrame(AFrame);
end;

function TModelsSubject.StreamSave: TBytes;
begin
  Result := FStream.SaveToBytes;
end;

function TModelsSubject.StreamLoad(const ABytes: TBytes): Boolean;
begin
  Result := FStream.LoadFromBytes(ABytes);
end;

function TModelsSubject.StreamCommandCount: Integer;
begin
  Result := FStream.CommandCount;
end;

function TModelsSubject.StreamPlay(const AFrame, AMaxDepth: Integer): string;
var
  LRecorder: TModelEventRecorder;
  LRenderer: IModelRenderer;
begin
  FStream.MaxRecursionDepth := AMaxDepth;
  LRecorder := TModelEventRecorder.Create;
  LRenderer := LRecorder;
  FStream.Play(AFrame, LRenderer);
  Result := LRecorder.ToHex;
end;

end.
