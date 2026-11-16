{******************************************************************************}
{                                                                              }
{  DelphiDoom: console library - the registry of the commands                  }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Console.CommandRegistry;

interface

uses
  System.Generics.Collections, DelphiDoom.Console.Types, DelphiDoom.Console.Intf;

type
  /// <summary>The commands on a dictionary; the names are kept in upper case (old C_AddCmd)</summary>
  TCommandRegistry = class(TInterfacedObject, ICommandRegistry)
  private
    FHandlers: TDictionary<string, TConsoleCommandHandler>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Add(const AName: string; const AHandler: TConsoleCommandHandler);
    function Find(const AName: string; out AHandler: TConsoleCommandHandler): Boolean;
    function Contains(const AName: string): Boolean;
    function Names: TArray<string>;
  end;

implementation

uses
  System.SysUtils, System.Generics.Defaults, DelphiDoom.Console.Text;

resourcestring
  SCommandWithoutHandler = 'The command "%s" has no handler';

const
  ALIAS_SEPARATOR = ',';

{ TCommandRegistry }

constructor TCommandRegistry.Create;
begin
  inherited Create;
  FHandlers := TDictionary<string, TConsoleCommandHandler>.Create;
end;

destructor TCommandRegistry.Destroy;
begin
  FHandlers.Free;
  inherited Destroy;
end;

procedure TCommandRegistry.Add(const AName: string; const AHandler: TConsoleCommandHandler);
var
  LFirst: string;
  LRest: string;
begin
  if AName = '' then
    Exit;
  if not Assigned(AHandler) then
    raise EConsoleException.CreateFmt(SCommandWithoutHandler, [AName]);

  if Pos(ALIAS_SEPARATOR, AName) = 0 then
    FHandlers.AddOrSetValue(TConsoleText.UpperCase(AName), AHandler)
  else
  begin
    TConsoleText.Split(AName, ALIAS_SEPARATOR, LFirst, LRest);
    Add(LFirst, AHandler);
    Add(LRest, AHandler);
  end;
end;

function TCommandRegistry.Find(const AName: string; out AHandler: TConsoleCommandHandler): Boolean;
begin
  Result := FHandlers.TryGetValue(TConsoleText.UpperCase(AName), AHandler);
end;

function TCommandRegistry.Contains(const AName: string): Boolean;
begin
  Result := FHandlers.ContainsKey(TConsoleText.UpperCase(AName));
end;

function TCommandRegistry.Names: TArray<string>;
begin
  Result := FHandlers.Keys.ToArray;
  TArray.Sort<string>(Result, TComparer<string>.Construct(
    function(const ALeft, ARight: string): Integer
    begin
      Result := CompareStr(ALeft, ARight);
    end));
end;

end.
