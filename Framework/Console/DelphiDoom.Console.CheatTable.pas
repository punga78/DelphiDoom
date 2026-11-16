{******************************************************************************}
{                                                                              }
{  DelphiDoom: console library - the table of the cheats                       }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Console.CheatTable;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.Console.CheatSequence;

type
  /// <summary>
  ///   The cheats of a game, tried in the order they were added: it is the chain of "else if
  ///   check_cheat(...)" of the status bar. The first cheat that is acquired stops the chain,
  ///   so the cheats after it do not see the key
  /// </summary>
  TCheatTable = class
  private
    type
      TEntry = record
        Name: string;
        Sequence: TCheatSequence;
        Enabled: TFunc<Boolean>;
      end;
  private
    FEntries: TList<TEntry>;
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>
    ///   AEnabled tells whether the cheat is active now (the Doom 2 cheat of noclip is not the
    ///   Doom 1 one); it may be nil. The name must be unique
    /// </summary>
    procedure Add(const AName: string; const ASequence: AnsiString; const AEnabled: TFunc<Boolean>);
    /// <summary>The cheat of that name, to read its parameter. Nil if there is not</summary>
    function Find(const AName: string): TCheatSequence;
    /// <summary>
    ///   Gives the key to the cheats. AAcquired is the name of the one that was completed, or
    ///   empty. Gives true if a cheat took the key (pending or acquired): the game must not use it
    /// </summary>
    function Feed(AKey: Integer; out AAcquired: string): Boolean;
    /// <summary>All the cheats start again</summary>
    procedure Reset;
  end;

implementation

uses
  DelphiDoom.Console.Types;

{ TCheatTable }

constructor TCheatTable.Create;
begin
  inherited Create;
  FEntries := TList<TEntry>.Create;
end;

destructor TCheatTable.Destroy;
var
  LEntry: TEntry;
begin
  for LEntry in FEntries do
    LEntry.Sequence.Free;
  FEntries.Free;
  inherited Destroy;
end;

procedure TCheatTable.Add(const AName: string; const ASequence: AnsiString;
  const AEnabled: TFunc<Boolean>);
var
  LEntry: TEntry;
begin
  if Assigned(Find(AName)) then
    raise EConsoleException.CreateFmt('The cheat "%s" is already in the table', [AName]);
  LEntry.Name := AName;
  LEntry.Sequence := TCheatSequence.Create(ASequence);
  LEntry.Enabled := AEnabled;
  FEntries.Add(LEntry);
end;

function TCheatTable.Find(const AName: string): TCheatSequence;
var
  LEntry: TEntry;
begin
  for LEntry in FEntries do
    if SameText(LEntry.Name, AName) then
      Exit(LEntry.Sequence);
  Result := nil;
end;

function TCheatTable.Feed(AKey: Integer; out AAcquired: string): Boolean;
var
  LEntry: TEntry;
  LStatus: TCheatStatus;
begin
  AAcquired := '';
  Result := False;
  for LEntry in FEntries do
  begin
    if Assigned(LEntry.Enabled) and not LEntry.Enabled() then
      Continue;
    LStatus := LEntry.Sequence.Check(AKey);
    if LStatus in [csPending, csAcquired] then
      Result := True;
    if LStatus = csAcquired then
    begin
      AAcquired := LEntry.Name;
      Exit;
    end;
  end;
end;

procedure TCheatTable.Reset;
var
  LEntry: TEntry;
begin
  for LEntry in FEntries do
    LEntry.Sequence.Reset;
end;

end.
