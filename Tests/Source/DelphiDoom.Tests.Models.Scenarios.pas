{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the 3D models library - the scenarios of parity        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Models.Scenarios;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Models.Types, DelphiDoom.Models.Intf;

type
  /// <summary>An MD2 model as the scenarios see it, the same for the old code and the new one</summary>
  TMd2Dump = record
    FrameCount: Integer;
    VertexCount: Integer;
    Vertices: TArray<Single>;
    TexCoords: TArray<Single>;
    GroupNames: TArray<string>;
    GroupStarts: TArray<Integer>;
    GroupEnds: TArray<Integer>;
  end;

  /// <summary>
  ///   What a scenario asks: the new classes in the tests, a copy of the old units in the
  ///   temporary harness that made the golden files (the harness is not committed)
  /// </summary>
  IModelsSubject = interface
    function LoadMd2(const ABytes: TBytes; const APlacement: TModelPlacement;
      out ADump: TMd2Dump): Boolean;
    /// <summary>Loads two files, merges the second into the first and dumps the first</summary>
    function MergeMd2(const AFirst, ASecond: TBytes; const APlacement: TModelPlacement;
      out ADump: TMd2Dump): Boolean;
    function GroupName(const AFrameName: string): string;
    procedure StreamReset;
    procedure StreamAdd(const ACommand: Integer; const AParam0, AParam1, AParam2, AParam3: Single);
    /// <summary>What MDLS_SetFrame does: the frame of the next commands, and a command SETFRAME</summary>
    procedure StreamSetFrame(const AFrame: Integer);
    procedure StreamIdentify;
    function StreamFrameCount: Integer;
    function StreamFrame(const AIndex: Integer): Integer;
    function StreamIndexOf(const AFrame: Integer): Integer;
    function StreamSave: TBytes;
    function StreamLoad(const ABytes: TBytes): Boolean;
    function StreamCommandCount: Integer;
    /// <summary>Plays a frame to a recorder and gives the fingerprint of what the recorder got</summary>
    function StreamPlay(const AFrame, AMaxDepth: Integer): string;
  end;

  /// <summary>The renderer of the tests: records every call as numbers in a fingerprint</summary>
  TModelEventRecorder = class(TInterfacedObject, IModelRenderer)
  private
    FSink: TObject;
  public
    constructor Create;
    destructor Destroy; override;
    function ToHex: string;
    procedure BeginPrimitive(const AMode: Integer);
    procedure EndPrimitive;
    procedure TexCoord2f(const AU, AV: Single);
    procedure Vertex3f(const AX, AY, AZ: Single);
    procedure Color3f(const AR, AG, AB: Single);
    procedure Color4f(const AR, AG, AB, AA: Single);
    procedure Normal3f(const ANX, ANY, ANZ: Single);
    procedure MatrixMode(const AMode: Integer);
    procedure PushMatrix;
    procedure PopMatrix;
    procedure Translatef(const AX, AY, AZ: Single);
    procedure Rotatef(const AAngle, AX, AY, AZ: Single);
    procedure LoadIdentity;
    procedure Scalef(const AX, AY, AZ: Single);
  end;

  TModelsScenarios = class
  public
    /// <summary>Valid files of many sizes, with the placements of the renderer</summary>
    class function Md2Models(const ASubject: IModelsSubject): string; static;
    /// <summary>The names of the groups of a series of frame names</summary>
    class function GroupNames(const ASubject: IModelsSubject): string; static;
    /// <summary>Models merged with another that has one frame (the only case the old code did right)</summary>
    class function Md2Merges(const ASubject: IModelsSubject): string; static;
    /// <summary>
    ///   Series of commands with many frames and calls: frames, the file, the file read again,
    ///   and the playing of every frame with some limits of depth
    /// </summary>
    class function CommandStreams(const ASubject: IModelsSubject): string; static;
    class procedure AddDump(const AFingerprint: TObject; const ADump: TMd2Dump); static;
  end;

implementation

uses
  DelphiDoom.Tests.Models.Fingerprint, DelphiDoom.Tests.Models.Samples;

{ TModelEventRecorder }

constructor TModelEventRecorder.Create;
begin
  inherited Create;
  FSink := TFingerprint.Create;
end;

destructor TModelEventRecorder.Destroy;
begin
  FSink.Free;
  inherited Destroy;
end;

function TModelEventRecorder.ToHex: string;
begin
  Result := TFingerprint(FSink).ToHex;
end;

procedure TModelEventRecorder.BeginPrimitive(const AMode: Integer);
begin
  TFingerprint(FSink).AddInteger(100);
  TFingerprint(FSink).AddInteger(AMode);
end;

procedure TModelEventRecorder.EndPrimitive;
begin
  TFingerprint(FSink).AddInteger(101);
end;

procedure TModelEventRecorder.TexCoord2f(const AU, AV: Single);
begin
  TFingerprint(FSink).AddInteger(102);
  TFingerprint(FSink).AddSingle(AU);
  TFingerprint(FSink).AddSingle(AV);
end;

procedure TModelEventRecorder.Vertex3f(const AX, AY, AZ: Single);
begin
  TFingerprint(FSink).AddInteger(103);
  TFingerprint(FSink).AddSingle(AX);
  TFingerprint(FSink).AddSingle(AY);
  TFingerprint(FSink).AddSingle(AZ);
end;

procedure TModelEventRecorder.Color3f(const AR, AG, AB: Single);
begin
  TFingerprint(FSink).AddInteger(104);
  TFingerprint(FSink).AddSingle(AR);
  TFingerprint(FSink).AddSingle(AG);
  TFingerprint(FSink).AddSingle(AB);
end;

procedure TModelEventRecorder.Color4f(const AR, AG, AB, AA: Single);
begin
  TFingerprint(FSink).AddInteger(105);
  TFingerprint(FSink).AddSingle(AR);
  TFingerprint(FSink).AddSingle(AG);
  TFingerprint(FSink).AddSingle(AB);
  TFingerprint(FSink).AddSingle(AA);
end;

procedure TModelEventRecorder.Normal3f(const ANX, ANY, ANZ: Single);
begin
  TFingerprint(FSink).AddInteger(106);
  TFingerprint(FSink).AddSingle(ANX);
  TFingerprint(FSink).AddSingle(ANY);
  TFingerprint(FSink).AddSingle(ANZ);
end;

procedure TModelEventRecorder.MatrixMode(const AMode: Integer);
begin
  TFingerprint(FSink).AddInteger(107);
  TFingerprint(FSink).AddInteger(AMode);
end;

procedure TModelEventRecorder.PushMatrix;
begin
  TFingerprint(FSink).AddInteger(108);
end;

procedure TModelEventRecorder.PopMatrix;
begin
  TFingerprint(FSink).AddInteger(109);
end;

procedure TModelEventRecorder.Translatef(const AX, AY, AZ: Single);
begin
  TFingerprint(FSink).AddInteger(110);
  TFingerprint(FSink).AddSingle(AX);
  TFingerprint(FSink).AddSingle(AY);
  TFingerprint(FSink).AddSingle(AZ);
end;

procedure TModelEventRecorder.Rotatef(const AAngle, AX, AY, AZ: Single);
begin
  TFingerprint(FSink).AddInteger(111);
  TFingerprint(FSink).AddSingle(AAngle);
  TFingerprint(FSink).AddSingle(AX);
  TFingerprint(FSink).AddSingle(AY);
  TFingerprint(FSink).AddSingle(AZ);
end;

procedure TModelEventRecorder.LoadIdentity;
begin
  TFingerprint(FSink).AddInteger(112);
end;

procedure TModelEventRecorder.Scalef(const AX, AY, AZ: Single);
begin
  TFingerprint(FSink).AddInteger(113);
  TFingerprint(FSink).AddSingle(AX);
  TFingerprint(FSink).AddSingle(AY);
  TFingerprint(FSink).AddSingle(AZ);
end;

{ TModelsScenarios }

class procedure TModelsScenarios.AddDump(const AFingerprint: TObject; const ADump: TMd2Dump);
var
  LFingerprint: TFingerprint;
  LIndex: Integer;
begin
  LFingerprint := TFingerprint(AFingerprint);
  LFingerprint.AddInteger(ADump.FrameCount);
  LFingerprint.AddInteger(ADump.VertexCount);
  for LIndex := 0 to High(ADump.Vertices) do
    LFingerprint.AddSingle(ADump.Vertices[LIndex]);
  for LIndex := 0 to High(ADump.TexCoords) do
    LFingerprint.AddSingle(ADump.TexCoords[LIndex]);
  LFingerprint.AddInteger(Length(ADump.GroupNames));
  for LIndex := 0 to High(ADump.GroupNames) do
  begin
    LFingerprint.AddText(ADump.GroupNames[LIndex]);
    LFingerprint.AddInteger(ADump.GroupStarts[LIndex]);
    LFingerprint.AddInteger(ADump.GroupEnds[LIndex]);
  end;
end;

class function TModelsScenarios.Md2Models(const ASubject: IModelsSubject): string;
var
  LRandom: TModelsRandom;
  LFingerprint: TFingerprint;
  LNames: TArray<string>;
  LBytes: TBytes;
  LDump: TMd2Dump;
  LCase: Integer;
  LTriangles, LVertexes, LFrames, LTexturePoints: Integer;
begin
  LRandom := TModelsRandom.Create(9001);
  LFingerprint := TFingerprint.Create;
  try
    LNames := TModelsSamples.FrameNames;
    for LCase := 0 to 39 do
    begin
      LTriangles := LRandom.NextInteger(40);
      LVertexes := 3 + LRandom.NextInteger(60);
      LFrames := 1 + LRandom.NextInteger(12);
      LTexturePoints := 1 + LRandom.NextInteger(80);
      LBytes := TModelsSamples.BuildMd2(LRandom, LTriangles, LVertexes, LFrames, LTexturePoints,
        32 + LRandom.NextInteger(224), 32 + LRandom.NextInteger(224),
        [LNames[9 + LCase mod 4], LNames[10 + LCase mod 3], LNames[11 + LCase mod 2], LNames[12],
        LNames[14], LNames[17], LNames[22], LNames[23]]);
      if LCase mod 5 = 0 then
        LFingerprint.AddBoolean(ASubject.LoadMd2(LBytes, TModelsSamples.IdentityPlacement, LDump))
      else
        LFingerprint.AddBoolean(ASubject.LoadMd2(LBytes, TModelsSamples.RandomPlacement(LRandom),
          LDump));
      AddDump(LFingerprint, LDump);
    end;
    Result := LFingerprint.ToHex;
  finally
    LFingerprint.Free;
    LRandom.Free;
  end;
end;

class function TModelsScenarios.GroupNames(const ASubject: IModelsSubject): string;
var
  LFingerprint: TFingerprint;
  LNames: TArray<string>;
  LIndex: Integer;
begin
  LFingerprint := TFingerprint.Create;
  try
    LNames := TModelsSamples.FrameNames;
    for LIndex := 0 to High(LNames) do
      LFingerprint.AddText(ASubject.GroupName(LNames[LIndex]));
    Result := LFingerprint.ToHex;
  finally
    LFingerprint.Free;
  end;
end;

class function TModelsScenarios.Md2Merges(const ASubject: IModelsSubject): string;
var
  LRandom: TModelsRandom;
  LFingerprint: TFingerprint;
  LFirst, LSecond: TBytes;
  LDump: TMd2Dump;
  LCase, LTriangles, LVertexes, LFrames, LTexturePoints: Integer;
begin
  LRandom := TModelsRandom.Create(9002);
  LFingerprint := TFingerprint.Create;
  try
    for LCase := 0 to 14 do
    begin
      LTriangles := 1 + LRandom.NextInteger(20);
      LVertexes := 3 + LRandom.NextInteger(30);
      // the draws one after the other, from the left: the order of evaluation of the arguments is not
      // defined and the 64 bit compiler uses another one
      LFrames := 1 + LRandom.NextInteger(6);
      LTexturePoints := 4 + LRandom.NextInteger(20);
      LFirst := TModelsSamples.BuildMd2(LRandom, LTriangles, LVertexes, LFrames, LTexturePoints, 64, 64,
        ['stand1', 'stand2', 'run1', 'run2', 'run3']);
      // one frame in the second file, the same triangles count except in every fifth case (no merge)
      if LCase mod 5 = 4 then
        LSecond := TModelsSamples.BuildMd2(LRandom, LTriangles + 1, LVertexes, 1, 8, 64, 64,
          ['pain1'])
      else
        LSecond := TModelsSamples.BuildMd2(LRandom, LTriangles, LVertexes, 1, 8, 64, 64,
          ['pain1']);
      LFingerprint.AddBoolean(ASubject.MergeMd2(LFirst, LSecond,
        TModelsSamples.RandomPlacement(LRandom), LDump));
      AddDump(LFingerprint, LDump);
    end;
    Result := LFingerprint.ToHex;
  finally
    LFingerprint.Free;
    LRandom.Free;
  end;
end;

class function TModelsScenarios.CommandStreams(const ASubject: IModelsSubject): string;
var
  LRandom: TModelsRandom;
  LFingerprint: TFingerprint;
  LBytes: TBytes;
  LCommand, LCase, LStep, LIndex, LMaxFrame, LCount: Integer;
  LParam0, LParam1, LParam2, LParam3: Single;
begin
  LRandom := TModelsRandom.Create(9003);
  LFingerprint := TFingerprint.Create;
  try
    for LCase := 0 to 29 do
    begin
      ASubject.StreamReset;
      LMaxFrame := 0;
      LCount := 5 + LRandom.NextInteger(120);
      // the frame 0 is the first of the list (a frame that is not the first and comes before
      // the others is the defect of the old list of frames, tested apart)
      ASubject.StreamAdd(MODEL_CMD_BEGIN, 4, 0, 0, 0);
      for LStep := 1 to LCount do
      begin
        TModelsSamples.RandomCommand(LRandom, LMaxFrame, LCommand, LParam0, LParam1, LParam2,
          LParam3);
        if LCommand = MODEL_CMD_SETFRAME then
          ASubject.StreamSetFrame(Round(LParam0))
        else
          ASubject.StreamAdd(LCommand, LParam0, LParam1, LParam2, LParam3);
      end;
      ASubject.StreamIdentify;
      LFingerprint.AddInteger(ASubject.StreamCommandCount);
      LFingerprint.AddInteger(ASubject.StreamFrameCount);
      for LIndex := 0 to ASubject.StreamFrameCount - 1 do
      begin
        LFingerprint.AddInteger(ASubject.StreamFrame(LIndex));
        LFingerprint.AddInteger(ASubject.StreamIndexOf(ASubject.StreamFrame(LIndex)));
      end;
      LFingerprint.AddInteger(ASubject.StreamIndexOf(-5));
      LFingerprint.AddInteger(ASubject.StreamIndexOf(LMaxFrame + 100));

      LBytes := ASubject.StreamSave;
      LFingerprint.AddInteger(Length(LBytes));
      for LIndex := 0 to High(LBytes) do
        LFingerprint.AddInteger(LBytes[LIndex]);

      for LIndex := -1 to LMaxFrame + 1 do
      begin
        LFingerprint.AddText(ASubject.StreamPlay(LIndex, 20));
        LFingerprint.AddText(ASubject.StreamPlay(LIndex, 2));
        LFingerprint.AddText(ASubject.StreamPlay(LIndex, 0));
      end;

      // the file read again (it replaces the commands)
      ASubject.StreamReset;
      LFingerprint.AddBoolean(ASubject.StreamLoad(LBytes));
      LFingerprint.AddInteger(ASubject.StreamCommandCount);
      LFingerprint.AddInteger(ASubject.StreamFrameCount);
      for LIndex := 0 to ASubject.StreamFrameCount - 1 do
        LFingerprint.AddInteger(ASubject.StreamFrame(LIndex));
      LFingerprint.AddText(ASubject.StreamPlay(0, 20));
    end;
    Result := LFingerprint.ToHex;
  finally
    LFingerprint.Free;
    LRandom.Free;
  end;
end;

end.
