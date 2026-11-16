{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - the commands of a procedural model          }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.CommandStream;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  DelphiDoom.Models.Types,
  DelphiDoom.Models.Intf;

type
  /// <summary>
  ///   The list of commands of a procedural model (the old TDDModelLoader, without the script
  ///   and the OpenGL calls). The memory is a dynamic array of 24 byte records: the binary
  ///   model (DMX) is that array with a header of two integers.
  /// </summary>
  TModelCommandStream = class(TInterfacedObject, IModelCommandStream)
  strict private
    FCommands: TArray<TModelCommand>;
    FCommandCount: Integer;
    FCurrentFrame: Integer;
    FMaxRecursionDepth: Integer;
    FRecursionDepth: Integer;
    FRecursionFrames: TList<Integer>;
    FFrames: TArray<Integer>;
    procedure PlayFrame(const AFrame: Integer; const ARenderer: IModelRenderer);
  public
    constructor Create;
    destructor Destroy; override;
    function GetCommandCount: Integer;
    function GetCommand(const AIndex: Integer): TModelCommand;
    function GetCurrentFrame: Integer;
    procedure SetCurrentFrame(const AValue: Integer);
    function GetMaxRecursionDepth: Integer;
    procedure SetMaxRecursionDepth(const AValue: Integer);
    function GetFrameCount: Integer;
    function GetFrame(const AIndex: Integer): Integer;
    procedure Clear;
    procedure AddCommand(const ACommand: Integer; const AParam0: Single = 0.0;
      const AParam1: Single = 0.0; const AParam2: Single = 0.0; const AParam3: Single = 0.0);
    procedure IdentifyFrames;
    function IndexOfFrame(const AFrame: Integer): Integer;
    function LoadFromBytes(const ABytes: TBytes): Boolean;
    function SaveToBytes: TBytes;
    procedure Play(const AFrame: Integer; const ARenderer: IModelRenderer);
  end;

implementation

uses
  System.Math;

{ TModelCommandStream }

constructor TModelCommandStream.Create;
begin
  inherited Create;
  FMaxRecursionDepth := MODEL_DEFAULT_RECURSION_DEPTH;
  FRecursionFrames := TList<Integer>.Create;
end;

destructor TModelCommandStream.Destroy;
begin
  FRecursionFrames.Free;
  inherited Destroy;
end;

function TModelCommandStream.GetCommandCount: Integer;
begin
  Result := FCommandCount;
end;

function TModelCommandStream.GetCommand(const AIndex: Integer): TModelCommand;
begin
  if (AIndex < 0) or (AIndex >= FCommandCount) then
    raise EModelsException.CreateFmt(SModelsInvalidCommand, [AIndex]);
  Result := FCommands[AIndex];
end;

function TModelCommandStream.GetCurrentFrame: Integer;
begin
  Result := FCurrentFrame;
end;

procedure TModelCommandStream.SetCurrentFrame(const AValue: Integer);
begin
  FCurrentFrame := AValue;
end;

function TModelCommandStream.GetMaxRecursionDepth: Integer;
begin
  Result := FMaxRecursionDepth;
end;

procedure TModelCommandStream.SetMaxRecursionDepth(const AValue: Integer);
begin
  FMaxRecursionDepth := AValue;
end;

function TModelCommandStream.GetFrameCount: Integer;
begin
  Result := Length(FFrames);
end;

function TModelCommandStream.GetFrame(const AIndex: Integer): Integer;
begin
  if (AIndex < 0) or (AIndex >= Length(FFrames)) then
    raise EModelsException.CreateFmt(SModelsInvalidFramePosition, [AIndex]);
  Result := FFrames[AIndex];
end;

procedure TModelCommandStream.Clear;
begin
  FCommands := nil;
  FCommandCount := 0;
  FCurrentFrame := 0;
  FRecursionDepth := 0;
  FFrames := nil;
end;

procedure TModelCommandStream.AddCommand(const ACommand: Integer; const AParam0, AParam1,
  AParam2, AParam3: Single);
begin
  if FCommandCount >= Length(FCommands) then
    SetLength(FCommands, Length(FCommands) + 16);
  FCommands[FCommandCount].Command := ACommand;
  FCommands[FCommandCount].Params[0] := AParam0;
  FCommands[FCommandCount].Params[1] := AParam1;
  FCommands[FCommandCount].Params[2] := AParam2;
  FCommands[FCommandCount].Params[3] := AParam3;
  FCommands[FCommandCount].Frame := FCurrentFrame;
  Inc(FCommandCount);
end;

procedure TModelCommandStream.IdentifyFrames;
var
  LFrames: TList<Integer>;
  LIndex, LFrame: Integer;
begin
  LFrames := TList<Integer>.Create;
  try
    for LIndex := 0 to FCommandCount - 1 do
    begin
      if not LFrames.Contains(FCommands[LIndex].Frame) then
        LFrames.Add(FCommands[LIndex].Frame);
      if FCommands[LIndex].Command = MODEL_CMD_CALLFRAME then
      begin
        LFrame := Round(FCommands[LIndex].Params[0]);
        if not LFrames.Contains(LFrame) then
          LFrames.Add(LFrame);
      end;
    end;
    LFrames.Sort;
    FFrames := LFrames.ToArray;
  finally
    LFrames.Free;
  end;
end;

function TModelCommandStream.IndexOfFrame(const AFrame: Integer): Integer;
var
  LFound: Integer;
begin
  if TArray.BinarySearch<Integer>(FFrames, AFrame, LFound) then
    Result := LFound
  else
    Result := -1;
end;

function TModelCommandStream.LoadFromBytes(const ABytes: TBytes): Boolean;
var
  LHeader, LCount: Integer;
begin
  Result := False;
  if Length(ABytes) < 2 * SizeOf(Integer) then
    raise EModelsException.CreateFmt(SModelsStreamTruncated, [Length(ABytes), 0]);
  Move(ABytes[0], LHeader, SizeOf(Integer));
  if LHeader <> DMX_MAGIC then
    Exit;
  Move(ABytes[SizeOf(Integer)], LCount, SizeOf(Integer));
  if LCount < 0 then
    Exit;
  if Int64(Length(ABytes)) < 2 * SizeOf(Integer) + Int64(LCount) * MODEL_COMMAND_SIZE then
    raise EModelsException.CreateFmt(SModelsStreamTruncated, [Length(ABytes), LCount]);
  SetLength(FCommands, LCount);
  FCommandCount := LCount;
  if LCount > 0 then
    Move(ABytes[2 * SizeOf(Integer)], FCommands[0], LCount * MODEL_COMMAND_SIZE);
  IdentifyFrames;
  Result := True;
end;

function TModelCommandStream.SaveToBytes: TBytes;
var
  LHeader: Integer;
begin
  SetLength(Result, 2 * SizeOf(Integer) + FCommandCount * MODEL_COMMAND_SIZE);
  LHeader := DMX_MAGIC;
  Move(LHeader, Result[0], SizeOf(Integer));
  Move(FCommandCount, Result[SizeOf(Integer)], SizeOf(Integer));
  if FCommandCount > 0 then
    Move(FCommands[0], Result[2 * SizeOf(Integer)], FCommandCount * MODEL_COMMAND_SIZE);
end;

procedure TModelCommandStream.Play(const AFrame: Integer; const ARenderer: IModelRenderer);
begin
  FRecursionDepth := 0;
  FRecursionFrames.Clear;
  PlayFrame(AFrame, ARenderer);
end;

procedure TModelCommandStream.PlayFrame(const AFrame: Integer; const ARenderer: IModelRenderer);
var
  LIndex, LFrameIndex: Integer;
  LCommand: PModelCommand;
begin
  if FRecursionDepth >= FMaxRecursionDepth then
    Exit;
  // a frame that is being drawn does not call itself, directly or from another
  if FRecursionFrames.Contains(AFrame) then
    Exit;
  FRecursionFrames.Add(AFrame);

  Inc(FRecursionDepth);
  for LIndex := 0 to FCommandCount - 1 do
  begin
    LCommand := @FCommands[LIndex];
    if AFrame <> LCommand.Frame then
      Continue;

    case LCommand.Command of
      MODEL_CMD_BEGIN:
        ARenderer.BeginPrimitive(Round(LCommand.Params[0]));
      MODEL_CMD_END:
        ARenderer.EndPrimitive;
      MODEL_CMD_TEXCOORD2F:
        ARenderer.TexCoord2f(LCommand.Params[0], LCommand.Params[1]);
      MODEL_CMD_VERTEX3F:
        ARenderer.Vertex3f(LCommand.Params[0], LCommand.Params[1], LCommand.Params[2]);
      MODEL_CMD_COLOR3F:
        ARenderer.Color3f(LCommand.Params[0], LCommand.Params[1], LCommand.Params[2]);
      MODEL_CMD_COLOR4F:
        ARenderer.Color4f(LCommand.Params[0], LCommand.Params[1], LCommand.Params[2],
          LCommand.Params[3]);
      MODEL_CMD_NORMAL3F:
        ARenderer.Normal3f(LCommand.Params[0], LCommand.Params[1], LCommand.Params[2]);
      MODEL_CMD_MATRIXMODE:
        ARenderer.MatrixMode(Round(LCommand.Params[0]));
      MODEL_CMD_PUSHMATRIX:
        ARenderer.PushMatrix;
      MODEL_CMD_POPMATRIX:
        ARenderer.PopMatrix;
      MODEL_CMD_TRANSLATEF:
        ARenderer.Translatef(LCommand.Params[0], LCommand.Params[1], LCommand.Params[2]);
      MODEL_CMD_ROTATEF:
        ARenderer.Rotatef(LCommand.Params[0], LCommand.Params[1], LCommand.Params[2],
          LCommand.Params[3]);
      MODEL_CMD_LOADIDENTITY:
        ARenderer.LoadIdentity;
      MODEL_CMD_SCALEF:
        ARenderer.Scalef(LCommand.Params[0], LCommand.Params[1], LCommand.Params[2]);
      MODEL_CMD_CALLFRAME:
        PlayFrame(Round(LCommand.Params[0]), ARenderer);
    end;
  end;

  LFrameIndex := FRecursionFrames.IndexOf(AFrame);
  if LFrameIndex >= 0 then
    FRecursionFrames.Delete(LFrameIndex);

  Dec(FRecursionDepth);
end;

end.
