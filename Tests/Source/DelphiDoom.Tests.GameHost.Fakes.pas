{******************************************************************************}
{                                                                              }
{  DelphiDoom: fakes of the tests of the game host library                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.GameHost.Fakes;

interface

uses
  System.Generics.Collections, DelphiDoom.GameHost.Types, DelphiDoom.GameHost.Events.Intf;

type
  /// <summary>A sink that keeps the events it is given, in order</summary>
  TFakeEventSink = class(TInterfacedObject, IGameHostEventSink)
  strict private
    FEvents: TList<TGameHostEvent>;
    function GetCount: Integer;
    function GetEvent(AIndex: Integer): TGameHostEvent;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Post(const AEvent: TGameHostEvent);
    property Count: Integer read GetCount;
    property Events[AIndex: Integer]: TGameHostEvent read GetEvent; default;
  end;

  /// <summary>A keyboard that answers what the test says and remembers what it was asked</summary>
  TFakeKeyboard = class(TInterfacedObject, IGameHostKeyboard)
  public
    Held: TGameHostModifiers;
    Typed: Cardinal;
    AskedKey: Cardinal;
    AskedScanCode: Cardinal;
    CharacterCalls: Integer;
    function Modifiers: TGameHostModifiers;
    function CharacterOf(AVirtualKey: Cardinal; AScanCode: Cardinal): Cardinal;
  end;

implementation

{ TFakeEventSink }

constructor TFakeEventSink.Create;
begin
  inherited Create;
  FEvents := TList<TGameHostEvent>.Create;
end;

destructor TFakeEventSink.Destroy;
begin
  FEvents.Free;
  inherited Destroy;
end;

procedure TFakeEventSink.Post(const AEvent: TGameHostEvent);
begin
  FEvents.Add(AEvent);
end;

function TFakeEventSink.GetCount: Integer;
begin
  Result := FEvents.Count;
end;

function TFakeEventSink.GetEvent(AIndex: Integer): TGameHostEvent;
begin
  Result := FEvents[AIndex];
end;

{ TFakeKeyboard }

function TFakeKeyboard.Modifiers: TGameHostModifiers;
begin
  Result := Held;
end;

function TFakeKeyboard.CharacterOf(AVirtualKey: Cardinal; AScanCode: Cardinal): Cardinal;
begin
  Inc(CharacterCalls);
  AskedKey := AVirtualKey;
  AskedScanCode := AScanCode;
  Result := Typed;
end;

end.
