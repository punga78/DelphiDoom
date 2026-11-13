{******************************************************************************}
{                                                                              }
{  DelphiDoom: declaration manager - the console commands                      }
{                                                                              }
{  Port of the commands that idDeclManagerLocal::Init adds (listDecls,         }
{  reloadDecls, touch, list<Type> and print<Type>) and of ListDecls_f,         }
{  ReloadDecls_f and TouchDecl_f of framework\DeclManager.cpp (id Software,    }
{  GPL v3). Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.  }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software). This unit is derived     }
{  from it and is therefore available under the GNU General Public License,    }
{  version 3, with the additional terms of the Doom 3 Source Code License      }
{  (see Reference\doom3\README.txt and Libs\IdLib\README.md); the repository    }
{  as a whole is GPL v2 or later.                                              }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Decl.Console.Commands;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.IdLib.Core.Intf, DelphiDoom.IdLib.Text.CmdArgs,
  DelphiDoom.Console.CmdSystem.Types, DelphiDoom.Console.CmdSystem.Intf, DelphiDoom.Console.CmdSystem.Completions,
  DelphiDoom.Decl.Intf, DelphiDoom.Decl.Console.Intf, DelphiDoom.Decl.Console.TypeCommands;

type
  /// <summary>
  ///   Registers the console commands of the declaration manager in a command system (<c>ICmdCommands</c>, the
  ///   <c>idCmdSystem</c> profile of <c>Libs\Console</c>), in the order of <c>idDeclManagerLocal::Init</c>:
  ///   <c>listDecls</c>, <c>reloadDecls</c>, <c>touch</c>, the <c>list&lt;Type&gt;</c> commands and the
  ///   <c>print&lt;Type&gt;</c> commands, all <c>CMD_FL_SYSTEM</c>. The object owns the helpers the commands
  ///   call and must live as long as the commands do. Not ported: <c>listHuffmanFrequencies</c> (the manager does
  ///   not compress the text of the decls).
  /// </summary>
  TDeclConsoleCommands = class
  strict private
    FManager: IDeclManager;
    FCommands: ICmdCommands;
    FLog: IIdLibLog;
    FSoundMute: IDeclSoundMute;
    FTypeCommands: TObjectList<TDeclTypeCommands>;
    FListCompletion: TCmdCompletions;
    procedure Print(const AText: string);
    procedure AddTypeCommands(const AType: Integer);
  public
    /// <summary>
    ///   EArgumentNilException when the manager or the command system is nil; the log and the sound may be nil
    ///   (without sound nothing is muted while the decls reload)
    /// </summary>
    constructor Create(const AManager: IDeclManager; const ACommands: ICmdCommands; const ALog: IIdLibLog = nil;
      const ASoundMute: IDeclSoundMute = nil);
    destructor Destroy; override;
    /// <summary>The body of the commands of <c>idDeclManagerLocal::Init</c>: adds them to the command system</summary>
    procedure Register;
    /// <summary>
    ///   ListDecls_f: the size and the number of decls of each type, then the totals. Needs <c>IDeclStatistics</c>
    ///   from the manager (the manager of this library has it); without it the command says nothing
    /// </summary>
    procedure ListDecls(const AArgs: TIdCmdArgs);
    /// <summary>ReloadDecls_f: "all" reloads every file, anything else the files that changed; never purges</summary>
    procedure ReloadDecls(const AArgs: TIdCmdArgs);
    /// <summary>TouchDecl_f: <c>touch &lt;type&gt; &lt;name&gt;</c> finds the decl (parsing it and marking it referenced)</summary>
    procedure Touch(const AArgs: TIdCmdArgs);
  end;

implementation

uses
  DelphiDoom.IdLib.Text.Strings, DelphiDoom.Decl.Types, DelphiDoom.Decl.Statistics.Intf;

type
  /// <summary>One list/print pair of the registration: the number of the type and the suffix of the command</summary>
  TTypeCommandName = record
    TypeId: Integer;
    ListName: AnsiString;
    ListDescription: AnsiString;
    PrintName: AnsiString;
    PrintDescription: AnsiString;
  end;

const
  SNilManager = 'TDeclConsoleCommands.Create: the manager is nil';
  SNilCommands = 'TDeclConsoleCommands.Create: the command system is nil';
  // the order of the registrations of the original (the descriptions are copied as they are, typos included)
  TYPE_COMMANDS: array[0..11] of TTypeCommandName = (
    (TypeId: DECL_TABLE; ListName: 'listTables'; ListDescription: 'lists tables';
      PrintName: 'printTable'; PrintDescription: 'prints a table'),
    (TypeId: DECL_MATERIAL; ListName: 'listMaterials'; ListDescription: 'lists materials';
      PrintName: 'printMaterial'; PrintDescription: 'prints a material'),
    (TypeId: DECL_SKIN; ListName: 'listSkins'; ListDescription: 'lists skins';
      PrintName: 'printSkin'; PrintDescription: 'prints a skin'),
    (TypeId: DECL_SOUND; ListName: 'listSoundShaders'; ListDescription: 'lists sound shaders';
      PrintName: 'printSoundShader'; PrintDescription: 'prints a sound shader'),
    (TypeId: DECL_ENTITYDEF; ListName: 'listEntityDefs'; ListDescription: 'lists entity defs';
      PrintName: 'printEntityDef'; PrintDescription: 'prints an entity def'),
    (TypeId: DECL_FX; ListName: 'listFX'; ListDescription: 'lists FX systems';
      PrintName: 'printFX'; PrintDescription: 'prints an FX system'),
    (TypeId: DECL_PARTICLE; ListName: 'listParticles'; ListDescription: 'lists particle systems';
      PrintName: 'printParticle'; PrintDescription: 'prints a particle system'),
    (TypeId: DECL_AF; ListName: 'listAF'; ListDescription: 'lists articulated figures';
      PrintName: 'printAF'; PrintDescription: 'prints an articulated figure'),
    (TypeId: DECL_PDA; ListName: 'listPDAs'; ListDescription: 'lists PDAs';
      PrintName: 'printPDA'; PrintDescription: 'prints an PDA'),
    (TypeId: DECL_EMAIL; ListName: 'listEmails'; ListDescription: 'lists Emails';
      PrintName: 'printEmail'; PrintDescription: 'prints an Email'),
    (TypeId: DECL_VIDEO; ListName: 'listVideos'; ListDescription: 'lists Videos';
      PrintName: 'printVideo'; PrintDescription: 'prints a Audio'),
    (TypeId: DECL_AUDIO; ListName: 'listAudios'; ListDescription: 'lists Audios';
      PrintName: 'printAudio'; PrintDescription: 'prints an Video')
  );

{ TDeclConsoleCommands }

constructor TDeclConsoleCommands.Create(const AManager: IDeclManager; const ACommands: ICmdCommands;
  const ALog: IIdLibLog; const ASoundMute: IDeclSoundMute);
begin
  inherited Create;
  if not Assigned(AManager) then
    raise EArgumentNilException.Create(SNilManager);
  if not Assigned(ACommands) then
    raise EArgumentNilException.Create(SNilCommands);
  FManager := AManager;
  FCommands := ACommands;
  FLog := ALog;
  FSoundMute := ASoundMute;
  FTypeCommands := TObjectList<TDeclTypeCommands>.Create(True);
  // listDeclStrings
  FListCompletion := TCmdCompletions.Create(['current', 'all', 'ever']);
end;

destructor TDeclConsoleCommands.Destroy;
begin
  FListCompletion.Free;
  FTypeCommands.Free;
  inherited Destroy;
end;

procedure TDeclConsoleCommands.Print(const AText: string);
begin
  if Assigned(FLog) then
    FLog.Printf(AText);
end;

procedure TDeclConsoleCommands.AddTypeCommands(const AType: Integer);
begin
  FTypeCommands.Add(TDeclTypeCommands.Create(FManager, AType, FLog));
end;

procedure TDeclConsoleCommands.Register;
var
  LIndex: Integer;
begin
  FCommands.AddCommand('listDecls', ListDecls, CMD_FL_SYSTEM, 'lists all decls');
  FCommands.AddCommand('reloadDecls', ReloadDecls, CMD_FL_SYSTEM, 'reloads decls');
  FCommands.AddCommand('touch', Touch, CMD_FL_SYSTEM, 'touches a decl');
  for LIndex := Low(TYPE_COMMANDS) to High(TYPE_COMMANDS) do
  begin
    AddTypeCommands(TYPE_COMMANDS[LIndex].TypeId);
    FCommands.AddCommand(TYPE_COMMANDS[LIndex].ListName, FTypeCommands.Last.List, CMD_FL_SYSTEM,
      TYPE_COMMANDS[LIndex].ListDescription, FListCompletion.CompleteString);
  end;
  for LIndex := Low(TYPE_COMMANDS) to High(TYPE_COMMANDS) do
    FCommands.AddCommand(TYPE_COMMANDS[LIndex].PrintName, FTypeCommands[LIndex].Print, CMD_FL_SYSTEM,
      TYPE_COMMANDS[LIndex].PrintDescription, FTypeCommands[LIndex].CompleteName);
end;

procedure TDeclConsoleCommands.ListDecls(const AArgs: TIdCmdArgs);
var
  LStatistics: IDeclStatistics;
  LType, LNumber, LSize: Integer;
  LTotalDecls, LTotalText, LTotalStructs: Int64;
begin
  if not Supports(FManager, IDeclStatistics, LStatistics) then
    Exit;
  LTotalDecls := 0;
  LTotalStructs := 0;
  for LType := 0 to LStatistics.GetTypeSlotCount - 1 do
  begin
    if not LStatistics.IsTypeRegistered(LType) then
      Continue;
    LNumber := FManager.GetNumDecls(LType);
    Inc(LTotalDecls, LNumber);
    LSize := Integer(LStatistics.GetTypeSize(LType));
    Inc(LTotalStructs, LSize);
    Print(Format('%4dk %4d %s'#10, [LSize shr 10, LNumber, string(FManager.GetRegistry.GetDeclNameFromType(LType))]));
  end;
  LTotalText := LStatistics.GetLoadedFilesSize;
  Print(Format('%d total decls is %d decl files'#10, [LTotalDecls, LStatistics.GetLoadedFileCount]));
  Print(Format('%dKB in text, %dKB in structures'#10, [Integer(LTotalText shr 10), Integer(LTotalStructs shr 10)]));
end;

procedure TDeclConsoleCommands.ReloadDecls(const AArgs: TIdCmdArgs);
var
  LForce: Boolean;
begin
  LForce := TIdStrings.Icmp(AArgs.Argv(1), 'all') = 0;
  if LForce then
    Print('reloading all decl files:'#10)
  else
    Print('reloading changed decl files:'#10);
  if Assigned(FSoundMute) then
    FSoundMute.SetMute(True);
  try
    FManager.Reload(LForce);
  finally
    if Assigned(FSoundMute) then
      FSoundMute.SetMute(False);
  end;
end;

procedure TDeclConsoleCommands.Touch(const AArgs: TIdCmdArgs);
var
  LStatistics: IDeclStatistics;
  LRegistry: IDeclRegistry;
  LType, LSlot: Integer;
  LNames: string;
begin
  LRegistry := FManager.GetRegistry;
  if AArgs.Argc <> 3 then
  begin
    Print('usage: touch <type> <name>'#10);
    LNames := '';
    if Supports(FManager, IDeclStatistics, LStatistics) then
      for LSlot := 0 to LStatistics.GetTypeSlotCount - 1 do
        if LStatistics.IsTypeRegistered(LSlot) then
          LNames := LNames + string(LRegistry.GetDeclNameFromType(LSlot)) + ' ';
    Print('valid types: ' + LNames + #10);
    Exit;
  end;
  LType := LRegistry.GetDeclTypeFromName(AArgs.Argv(1));
  if LType >= DECL_MAX_TYPES then
  begin
    Print(Format('unknown decl type ''%s'''#10, [string(AArgs.Argv(1))]));
    Exit;
  end;
  if FManager.FindType(LType, AArgs.Argv(2), False) = nil then
    Print(Format('%s ''%s'' not found'#10, [string(LRegistry.GetDeclNameFromType(LType)), string(AArgs.Argv(2))]));
end;

end.
