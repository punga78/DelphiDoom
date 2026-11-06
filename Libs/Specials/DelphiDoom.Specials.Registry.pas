{******************************************************************************}
{                                                                              }
{  DelphiDoom: specials library - the registry                                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Specials.Registry;

interface

uses
  System.Generics.Collections, DelphiDoom.Specials.Intf;

type
  /// <summary>The registry on a dictionary</summary>
  TSpecialRegistry = class(TInterfacedObject, ISpecialRegistry)
  private
    FHandlers: TDictionary<Integer, TSpecialHandler>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Register(ANumber: Integer; const AHandler: TSpecialHandler);
    function Contains(ANumber: Integer): Boolean;
    function Execute(const AContext: TSpecialContext): Boolean;
    function Numbers: TArray<Integer>;
  end;

implementation

uses
  System.SysUtils, System.Generics.Defaults;

resourcestring
  SSpecialAlreadyRegistered = 'The special %d is already registered';
  SSpecialWithoutHandler = 'The special %d has no handler';

{ TSpecialRegistry }

constructor TSpecialRegistry.Create;
begin
  inherited Create;
  FHandlers := TDictionary<Integer, TSpecialHandler>.Create;
end;

destructor TSpecialRegistry.Destroy;
begin
  FHandlers.Free;
  inherited Destroy;
end;

procedure TSpecialRegistry.Register(ANumber: Integer; const AHandler: TSpecialHandler);
begin
  if not Assigned(AHandler) then
    raise ESpecialRegistryException.CreateFmt(SSpecialWithoutHandler, [ANumber]);
  if FHandlers.ContainsKey(ANumber) then
    raise ESpecialRegistryException.CreateFmt(SSpecialAlreadyRegistered, [ANumber]);
  FHandlers.Add(ANumber, AHandler);
end;

function TSpecialRegistry.Contains(ANumber: Integer): Boolean;
begin
  Result := FHandlers.ContainsKey(ANumber);
end;

function TSpecialRegistry.Execute(const AContext: TSpecialContext): Boolean;
var
  LHandler: TSpecialHandler;
begin
  if FHandlers.TryGetValue(AContext.Special, LHandler) then
    Result := LHandler(AContext)
  else
    Result := False;
end;

function TSpecialRegistry.Numbers: TArray<Integer>;
begin
  Result := FHandlers.Keys.ToArray;
  TArray.Sort<Integer>(Result);
end;

end.
