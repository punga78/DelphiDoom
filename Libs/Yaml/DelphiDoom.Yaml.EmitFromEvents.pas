{******************************************************************************}
{                                                                              }
{  DelphiDoom: yaml library - emitting what the events tell (EmitFromEvents)   }
{  Port of yaml-cpp 0.7.0 (MIT, Jesse Beder): see Libs\Yaml\README.md          }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Yaml.EmitFromEvents;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  DelphiDoom.Yaml.Types,
  DelphiDoom.Yaml.Intf;

type
  /// <summary>EmitFromEvents: an event handler that writes the events to an emitter</summary>
  TYamlEmitFromEvents = class(TInterfacedObject, IYamlEventHandler)
  strict private
    type
      TState = (stWaitingForSequenceEntry, stWaitingForKey, stWaitingForValue);
  strict private
    FEmitter: IYamlEmitter;
    FStates: TStack<TState>;
    procedure BeginNode;
    procedure EmitProps(const ATag: TYamlText; AAnchor: TYamlAnchor);
  public
    constructor Create(const AEmitter: IYamlEmitter);
    destructor Destroy; override;
    procedure OnDocumentStart(const AMark: TYamlMark);
    procedure OnDocumentEnd;
    procedure OnNull(const AMark: TYamlMark; AAnchor: TYamlAnchor);
    procedure OnAlias(const AMark: TYamlMark; AAnchor: TYamlAnchor);
    procedure OnScalar(const AMark: TYamlMark; const ATag: TYamlText; AAnchor: TYamlAnchor;
      const AValue: TYamlText);
    procedure OnSequenceStart(const AMark: TYamlMark; const ATag: TYamlText; AAnchor: TYamlAnchor;
      AStyle: TYamlEmitterStyle);
    procedure OnSequenceEnd;
    procedure OnMapStart(const AMark: TYamlMark; const ATag: TYamlText; AAnchor: TYamlAnchor;
      AStyle: TYamlEmitterStyle);
    procedure OnMapEnd;
    procedure OnAnchor(const AMark: TYamlMark; const AAnchorName: TYamlText);
  end;

implementation

constructor TYamlEmitFromEvents.Create(const AEmitter: IYamlEmitter);
begin
  inherited Create;
  FEmitter := AEmitter;
  FStates := TStack<TState>.Create;
end;

destructor TYamlEmitFromEvents.Destroy;
begin
  FStates.Free;
  inherited Destroy;
end;

procedure TYamlEmitFromEvents.OnDocumentStart(const AMark: TYamlMark);
begin
end;

procedure TYamlEmitFromEvents.OnDocumentEnd;
begin
end;

procedure TYamlEmitFromEvents.OnAnchor(const AMark: TYamlMark; const AAnchorName: TYamlText);
begin
end;

procedure TYamlEmitFromEvents.OnNull(const AMark: TYamlMark; AAnchor: TYamlAnchor);
begin
  BeginNode;
  EmitProps('', AAnchor);
  FEmitter.WriteNull;
end;

procedure TYamlEmitFromEvents.OnAlias(const AMark: TYamlMark; AAnchor: TYamlAnchor);
begin
  BeginNode;
  FEmitter.WriteAlias(TYamlText(UIntToStr(AAnchor)));
end;

procedure TYamlEmitFromEvents.OnScalar(const AMark: TYamlMark; const ATag: TYamlText; AAnchor: TYamlAnchor;
  const AValue: TYamlText);
begin
  BeginNode;
  EmitProps(ATag, AAnchor);
  FEmitter.WriteString(AValue);
end;

procedure TYamlEmitFromEvents.OnSequenceStart(const AMark: TYamlMark; const ATag: TYamlText; AAnchor: TYamlAnchor;
  AStyle: TYamlEmitterStyle);
begin
  BeginNode;
  EmitProps(ATag, AAnchor);
  case AStyle of
    esBlock: FEmitter.Manip(ymBlock);
    esFlow: FEmitter.Manip(ymFlow);
  end;
  FEmitter.RestoreGlobalModifiedSettings;
  FEmitter.Manip(ymBeginSeq);
  FStates.Push(stWaitingForSequenceEntry);
end;

procedure TYamlEmitFromEvents.OnSequenceEnd;
begin
  FEmitter.Manip(ymEndSeq);
  FStates.Pop;
end;

procedure TYamlEmitFromEvents.OnMapStart(const AMark: TYamlMark; const ATag: TYamlText; AAnchor: TYamlAnchor;
  AStyle: TYamlEmitterStyle);
begin
  BeginNode;
  EmitProps(ATag, AAnchor);
  case AStyle of
    esBlock: FEmitter.Manip(ymBlock);
    esFlow: FEmitter.Manip(ymFlow);
  end;
  FEmitter.RestoreGlobalModifiedSettings;
  FEmitter.Manip(ymBeginMap);
  FStates.Push(stWaitingForKey);
end;

procedure TYamlEmitFromEvents.OnMapEnd;
begin
  FEmitter.Manip(ymEndMap);
  FStates.Pop;
end;

procedure TYamlEmitFromEvents.BeginNode;
begin
  if FStates.Count = 0 then
    Exit;
  case FStates.Peek of
    stWaitingForKey:
      begin
        FEmitter.Manip(ymKey);
        FStates.Pop;
        FStates.Push(stWaitingForValue);
      end;
    stWaitingForValue:
      begin
        FEmitter.Manip(ymValue);
        FStates.Pop;
        FStates.Push(stWaitingForKey);
      end;
  end;
end;

procedure TYamlEmitFromEvents.EmitProps(const ATag: TYamlText; AAnchor: TYamlAnchor);
begin
  if (ATag <> '') and (ATag <> '?') and (ATag <> '!') then
    FEmitter.WriteTag(etVerbatim, '', ATag);
  if AAnchor <> 0 then
    FEmitter.WriteAnchor(TYamlText(UIntToStr(AAnchor)));
end;

end.
