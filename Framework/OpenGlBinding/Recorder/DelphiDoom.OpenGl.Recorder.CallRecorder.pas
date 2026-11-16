{******************************************************************************}
{                                                                              }
{  DelphiDoom: OpenGL call recorder - the recorder of frames                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.OpenGl.Recorder.CallRecorder;

interface

uses
  System.Classes,
  System.SysUtils,
  DelphiDoom.OpenGl.Recorder.Intf;

type
  /// <summary>
  ///   Keeps the lines of the open frame in memory and, when the frame is closed, writes them to the
  ///   stream followed by  FRAME label calls=N sum=HEX16  (the FNV-1a of the lines, each ended by
  ///   a line feed). Discarding a frame writes nothing: the harness records every frame and keeps
  ///   only the first one of each tic.
  /// </summary>
  TGlCallRecorder = class(TInterfacedObject, IGlCallRecorder)
  strict private
    FStream: TStream;
    FLines: TStringBuilder;
    FCallCount: Integer;
    FHash: UInt64;
    FInFrame: Boolean;
    FFrameCount: Integer;
  public
    /// <summary>The recorder writes to AStream, which it does not own (the caller keeps it alive and frees it)</summary>
    constructor Create(const AStream: TStream);
    destructor Destroy; override;
    procedure BeginFrame;
    procedure EndFrame(const ALabel: string);
    procedure DiscardFrame;
    procedure Call(const ALine: string);
    function Stream: TStream;
    function FrameCount: Integer;
    function InFrame: Boolean;
  end;

implementation

uses
  DelphiDoom.OpenGl.Recorder.Fnv,
  DelphiDoom.OpenGl.Recorder.Types;

resourcestring
  SGlRecorderStreamNil = 'The recorder needs a stream to write to';
  SGlRecorderFrameOpen = 'A frame is already open';
  SGlRecorderFrameClosed = 'No frame is open';

{ TGlCallRecorder }

constructor TGlCallRecorder.Create(const AStream: TStream);
begin
  inherited Create;
  if not Assigned(AStream) then
    raise EArgumentNilException.Create(SGlRecorderStreamNil);
  FStream := AStream;
  FLines := TStringBuilder.Create;
end;

destructor TGlCallRecorder.Destroy;
begin
  FLines.Free;
  inherited Destroy;
end;

procedure TGlCallRecorder.BeginFrame;
begin
  if FInFrame then
    raise EGlRecorderException.Create(SGlRecorderFrameOpen);
  FInFrame := True;
  FCallCount := 0;
  FHash := TGlFnv.Start;
  FLines.Clear;
end;

procedure TGlCallRecorder.Call(const ALine: string);
begin
  if not FInFrame then
    Exit;
  Inc(FCallCount);
  FHash := TGlFnv.UpdateText(FHash, ALine);
  FHash := TGlFnv.UpdateText(FHash, #10);
  FLines.Append(ALine);
  FLines.Append(#10);
end;

procedure TGlCallRecorder.EndFrame(const ALabel: string);
var
  LText: AnsiString;
begin
  if not FInFrame then
    raise EGlRecorderException.Create(SGlRecorderFrameClosed);
  FLines.Append('FRAME ').Append(ALabel).Append(' calls=').Append(FCallCount).Append(' sum=')
    .Append(TGlFnv.ToHex(FHash)).Append(#10);
  // the lines are ASCII: one byte per character
  LText := AnsiString(FLines.ToString);
  if Length(LText) > 0 then
    FStream.WriteBuffer(LText[1], Length(LText));
  FLines.Clear;
  FInFrame := False;
  Inc(FFrameCount);
end;

procedure TGlCallRecorder.DiscardFrame;
begin
  if not FInFrame then
    raise EGlRecorderException.Create(SGlRecorderFrameClosed);
  FLines.Clear;
  FInFrame := False;
end;

function TGlCallRecorder.Stream: TStream;
begin
  Result := FStream;
end;

function TGlCallRecorder.FrameCount: Integer;
begin
  Result := FFrameCount;
end;

function TGlCallRecorder.InFrame: Boolean;
begin
  Result := FInFrame;
end;

end.
