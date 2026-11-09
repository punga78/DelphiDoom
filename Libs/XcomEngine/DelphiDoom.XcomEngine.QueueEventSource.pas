{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom engine library - an event source fed by the program         }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomEngine.QueueEventSource;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Intf;

type
  /// <summary>
  ///   IXcomEventSource with a queue: the events are put in by the window procedure of the real window, or by a test
  ///   or a script of screenshots. It keeps the mouse position and the buttons that the events it gave say
  /// </summary>
  TXcomQueueEventSource = class(TInterfacedObject, IXcomEventSource)
  strict private
    FQueue: TQueue<TXcomInputEvent>;
    FMouseX: Integer;
    FMouseY: Integer;
    FButtons: Integer;
    FModifiers: Integer;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Enqueue(const AEvent: TXcomInputEvent);
    function Poll(out AEvent: TXcomInputEvent): Boolean;
    function MouseState(out AX, AY: Integer): Integer;
    function ModifierState: Integer;
    procedure SetModifiers(AModifiers: Integer);
    function Pending: Integer;
  end;

implementation

constructor TXcomQueueEventSource.Create;
begin
  inherited Create;
  FQueue := TQueue<TXcomInputEvent>.Create;
end;

destructor TXcomQueueEventSource.Destroy;
begin
  FQueue.Free;
  inherited Destroy;
end;

procedure TXcomQueueEventSource.Enqueue(const AEvent: TXcomInputEvent);
begin
  FQueue.Enqueue(AEvent);
end;

function TXcomQueueEventSource.Poll(out AEvent: TXcomInputEvent): Boolean;
begin
  Result := FQueue.Count > 0;
  if not Result then
    Exit;
  AEvent := FQueue.Dequeue;
  case AEvent.Kind of
    ekMouseMotion:
      begin
        FMouseX := AEvent.X;
        FMouseY := AEvent.Y;
      end;
    ekMouseDown:
      begin
        FMouseX := AEvent.X;
        FMouseY := AEvent.Y;
        FButtons := FButtons or (1 shl (AEvent.Button - 1));
      end;
    ekMouseUp:
      begin
        FMouseX := AEvent.X;
        FMouseY := AEvent.Y;
        FButtons := FButtons and not (1 shl (AEvent.Button - 1));
      end;
  end;
end;

function TXcomQueueEventSource.MouseState(out AX, AY: Integer): Integer;
begin
  AX := FMouseX;
  AY := FMouseY;
  Result := FButtons;
end;

function TXcomQueueEventSource.ModifierState: Integer;
begin
  Result := FModifiers;
end;

procedure TXcomQueueEventSource.SetModifiers(AModifiers: Integer);
begin
  FModifiers := AModifiers;
end;

function TXcomQueueEventSource.Pending: Integer;
begin
  Result := FQueue.Count;
end;

end.
