{******************************************************************************}
{                                                                              }
{  DelphiDoom: declaration manager - the list and print commands of a type     }
{                                                                              }
{  Port of idListDecls_f, idPrintDecls_f, idDeclManagerLocal::ListType and     }
{  PrintType (the arguments), and of idCmdSystem::ArgCompletion_DeclName of    }
{  Doom 3 (id Software, GPL v3). Copyright (C) 1999-2011 id Software LLC, a    }
{  ZeniMax Media company.                                                      }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software). This unit is derived     }
{  from it and is therefore available under the GNU General Public License,    }
{  version 3, with the additional terms of the Doom 3 Source Code License      }
{  (see Reference\doom3\README.txt and Libs\IdLib\README.md); the repository   }
{  as a whole is GPL v2 or later.                                              }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Decl.Console.TypeCommands;

interface

uses
  System.SysUtils, DelphiDoom.IdLib.Core.Intf, DelphiDoom.IdLib.Text.CmdArgs, DelphiDoom.Console.CmdSystem.Types,
  DelphiDoom.Decl.Intf;

type
  /// <summary>
  ///   The three functions the original makes from a template for each decl type: <c>list&lt;Type&gt;</c> (with
  ///   "all" and "ever"), <c>print&lt;Type&gt;</c> (a name) and the completion of the names of that type. They are
  ///   methods of an object that knows its type, so each object serves as a command function.
  /// </summary>
  TDeclTypeCommands = class
  strict private
    FManager: IDeclManager;
    FType: Integer;
    FLog: IIdLibLog;
  public
    /// <summary>EArgumentNilException when the manager is nil; the log may be nil</summary>
    constructor Create(const AManager: IDeclManager; const AType: Integer; const ALog: IIdLibLog = nil);
    /// <summary>
    ///   idListDecls_f: "all" lists every decl, "ever" the ones referenced at least once, anything else the ones
    ///   referenced now (the words are compared without regard to case)
    /// </summary>
    procedure List(const AArgs: TIdCmdArgs);
    /// <summary>idPrintDecls_f: "print&lt;Type&gt; &lt;name&gt;"; without a name it says how to use the command</summary>
    procedure Print(const AArgs: TIdCmdArgs);
    /// <summary>ArgCompletion_DeclName: "command name" for each decl of the type, without parsing them</summary>
    procedure CompleteName(const AArgs: TIdCmdArgs; const ACallback: TCmdCompletionCallback);
    property DeclType: Integer read FType;
  end;

implementation

uses
  DelphiDoom.IdLib.Text.Strings, DelphiDoom.Decl.Types;

const
  SNilManager = 'TDeclTypeCommands.Create: the manager is nil';
  SPrintUsage = 'USAGE: Print<decl type> <decl name> [type specific parms]'#10;

{ TDeclTypeCommands }

constructor TDeclTypeCommands.Create(const AManager: IDeclManager; const AType: Integer; const ALog: IIdLibLog);
begin
  inherited Create;
  if not Assigned(AManager) then
    raise EArgumentNilException.Create(SNilManager);
  FManager := AManager;
  FType := AType;
  FLog := ALog;
end;

procedure TDeclTypeCommands.List(const AArgs: TIdCmdArgs);
var
  LMode: TDeclListMode;
begin
  if TIdStrings.Icmp(AArgs.Argv(1), 'all') = 0 then
    LMode := dlmAll
  else if TIdStrings.Icmp(AArgs.Argv(1), 'ever') = 0 then
    LMode := dlmEver
  else
    LMode := dlmCurrent;
  FManager.ListType(FType, LMode);
end;

procedure TDeclTypeCommands.Print(const AArgs: TIdCmdArgs);
begin
  // individual decl types may use additional command parameters
  if AArgs.Argc < 2 then
  begin
    if Assigned(FLog) then
      FLog.Printf(SPrintUsage);
    Exit;
  end;
  FManager.PrintType(FType, AArgs.Argv(1));
end;

procedure TDeclTypeCommands.CompleteName(const AArgs: TIdCmdArgs; const ACallback: TCmdCompletionCallback);
var
  LIndex: Integer;
  LDecl: IDecl;
begin
  for LIndex := 0 to FManager.GetNumDecls(FType) - 1 do
  begin
    LDecl := FManager.DeclByIndex(FType, LIndex, False);
    ACallback(AArgs.Argv(0) + ' ' + LDecl.GetName);
  end;
end;

end.
