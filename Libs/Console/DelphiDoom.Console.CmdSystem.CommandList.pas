{******************************************************************************}
{                                                                              }
{  DelphiDoom: console library - idTech 4 command system, the list of commands }
{                                                                              }
{  Port of Doom 3 (id Software, GPL v3): framework\CmdSystem.cpp              }
{  (commandDef_t and the list of idCmdSystemLocal).                            }
{  Based on the Doom 3 GPL Source Code (id Software).                          }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Console.CmdSystem.CommandList;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.IdLib.Core.Intf,
  DelphiDoom.Console.CmdSystem.Types;

type
  /// <summary>commandDef_t</summary>
  TCmdDefinition = class
  strict private
    FName: AnsiString;
    FFunction: TCmdFunction;
    FArgCompletion: TCmdArgCompletion;
    FFlags: Integer;
    FDescription: AnsiString;
  public
    constructor Create(const AName: AnsiString; const AFunction: TCmdFunction; const AArgCompletion: TCmdArgCompletion;
      const AFlags: Integer; const ADescription: AnsiString);
    property Name: AnsiString read FName;
    property CommandFunction: TCmdFunction read FFunction;
    property ArgCompletion: TCmdArgCompletion read FArgCompletion;
    property Flags: Integer read FFlags;
    property Description: AnsiString read FDescription;
  end;

  /// <summary>
  ///   The singly linked list of commands of idCmdSystemLocal, kept as an array (index 0 is the
  ///   head). A command that is executed moves to the head, so the order is that of use.
  ///   Nothing here is thread safe.
  /// </summary>
  TCmdCommandList = class
  strict private
    FLog: IIdLibLog;
    FDefinitions: TObjectList<TCmdDefinition>;
  public
    /// <summary>The log is optional (nil: silent)</summary>
    constructor Create(const ALog: IIdLibLog = nil);
    destructor Destroy; override;
    /// <summary>idCmdSystemLocal::AddCommand</summary>
    procedure Add(const AName: AnsiString; const AFunction: TCmdFunction; const AFlags: Integer;
      const ADescription: AnsiString; const AArgCompletion: TCmdArgCompletion);
    /// <summary>idCmdSystemLocal::RemoveCommand (the name is compared with case)</summary>
    procedure Remove(const AName: AnsiString);
    /// <summary>idCmdSystemLocal::RemoveFlaggedCommands</summary>
    procedure RemoveFlagged(const AFlags: Integer);
    /// <summary>
    ///   The command called AName (not case sensitive), moved to the head of the list; nil if
    ///   there is none. The loop of ExecuteTokenizedString
    /// </summary>
    function FindAndPromote(const AName: AnsiString): TCmdDefinition;
    /// <summary>The first command with a completion function and the name AName (not case sensitive)</summary>
    function FindWithCompletion(const AName: AnsiString): TCmdDefinition;
    function Count: Integer;
    function Item(const AIndex: Integer): TCmdDefinition;
    procedure Clear;
  end;

implementation

uses
  DelphiDoom.IdLib.Text.Strings;

function SameFunction(const A, B: TCmdFunction): Boolean;
begin
  Result := (TMethod(A).Code = TMethod(B).Code) and (TMethod(A).Data = TMethod(B).Data);
end;

{ TCmdDefinition }

constructor TCmdDefinition.Create(const AName: AnsiString; const AFunction: TCmdFunction;
  const AArgCompletion: TCmdArgCompletion; const AFlags: Integer; const ADescription: AnsiString);
begin
  inherited Create;
  FName := AName;
  FFunction := AFunction;
  FArgCompletion := AArgCompletion;
  FFlags := AFlags;
  FDescription := ADescription;
end;

{ TCmdCommandList }

constructor TCmdCommandList.Create(const ALog: IIdLibLog);
begin
  inherited Create;
  FLog := ALog;
  FDefinitions := TObjectList<TCmdDefinition>.Create(True);
end;

destructor TCmdCommandList.Destroy;
begin
  FDefinitions.Free;
  inherited Destroy;
end;

procedure TCmdCommandList.Add(const AName: AnsiString; const AFunction: TCmdFunction; const AFlags: Integer;
  const ADescription: AnsiString; const AArgCompletion: TCmdArgCompletion);
var
  LIndex: Integer;
begin
  // fail if the command already exists
  for LIndex := 0 to FDefinitions.Count - 1 do
    if TIdStrings.Cmp(AName, FDefinitions[LIndex].Name) = 0 then
    begin
      if not SameFunction(AFunction, FDefinitions[LIndex].CommandFunction) then
        if Assigned(FLog) then
          FLog.Printf('idCmdSystemLocal::AddCommand: ' + string(AName) + ' already defined'#10);
      Exit;
    end;
  FDefinitions.Insert(0, TCmdDefinition.Create(AName, AFunction, AArgCompletion, AFlags, ADescription));
end;

procedure TCmdCommandList.Remove(const AName: AnsiString);
var
  LIndex: Integer;
begin
  for LIndex := 0 to FDefinitions.Count - 1 do
    if TIdStrings.Cmp(AName, FDefinitions[LIndex].Name) = 0 then
    begin
      FDefinitions.Delete(LIndex);
      Exit;
    end;
end;

procedure TCmdCommandList.RemoveFlagged(const AFlags: Integer);
var
  LIndex: Integer;
begin
  for LIndex := FDefinitions.Count - 1 downto 0 do
    if (FDefinitions[LIndex].Flags and AFlags) <> 0 then
      FDefinitions.Delete(LIndex);
end;

function TCmdCommandList.FindAndPromote(const AName: AnsiString): TCmdDefinition;
var
  LIndex: Integer;
begin
  for LIndex := 0 to FDefinitions.Count - 1 do
    if TIdStrings.Icmp(AName, FDefinitions[LIndex].Name) = 0 then
    begin
      Result := FDefinitions[LIndex];
      if LIndex > 0 then
      begin
        FDefinitions.OwnsObjects := False;
        try
          FDefinitions.Delete(LIndex);
          FDefinitions.Insert(0, Result);
        finally
          FDefinitions.OwnsObjects := True;
        end;
      end;
      Exit;
    end;
  Result := nil;
end;

function TCmdCommandList.FindWithCompletion(const AName: AnsiString): TCmdDefinition;
var
  LIndex: Integer;
begin
  for LIndex := 0 to FDefinitions.Count - 1 do
  begin
    if not Assigned(FDefinitions[LIndex].ArgCompletion) then
      Continue;
    if TIdStrings.Icmp(AName, FDefinitions[LIndex].Name) = 0 then
      Exit(FDefinitions[LIndex]);
  end;
  Result := nil;
end;

function TCmdCommandList.Count: Integer;
begin
  Result := FDefinitions.Count;
end;

function TCmdCommandList.Item(const AIndex: Integer): TCmdDefinition;
begin
  Result := FDefinitions[AIndex];
end;

procedure TCmdCommandList.Clear;
begin
  FDefinitions.Clear;
end;

end.
