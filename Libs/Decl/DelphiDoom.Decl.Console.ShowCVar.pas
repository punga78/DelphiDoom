{******************************************************************************}
{                                                                              }
{  DelphiDoom: declaration manager - the decl_show variable                    }
{                                                                              }
{  Port of idDeclManagerLocal::decl_show of framework\DeclManager.cpp (id      }
{  Software, GPL v3). Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media }
{  company.                                                                    }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software). This unit is derived     }
{  from it and is therefore available under the GNU General Public License,    }
{  version 3, with the additional terms of the Doom 3 Source Code License      }
{  (see Reference\doom3\README.txt and Framework\IdLib\README.md); the repository }
{  as a whole is GPL v2 or later.                                              }
{                                                                              }
{******************************************************************************}unit DelphiDoom.Decl.Console.ShowCVar;

interface

uses
  DelphiDoom.Console.CVar.Intf, DelphiDoom.Console.CVar.Variable, DelphiDoom.Console.CmdSystem.Completions,
  DelphiDoom.Decl.Intf;

type
  /// <summary>
  ///   The console variable <c>decl_show</c> ("set to 1 to print parses, 2 to also print references", range 0..2,
  ///   <c>CVAR_SYSTEM</c>) and its link to the manager. The original reads the variable every time it prints; the
  ///   manager here has a level (<c>SetShowLevel</c>), so <c>Synchronize</c> copies the value of the variable to
  ///   the manager when the variable has been changed: the engine calls it where it applies variable changes.
  /// </summary>
  TDeclShowCVar = class
  strict private
    FManager: IDeclManager;
    FCVars: ICVarSystem;
    FCompletion: TCmdCompletions;
    FVariable: TCVar;
  public
    /// <summary>EArgumentNilException when the manager or the variable system is nil</summary>
    constructor Create(const AManager: IDeclManager; const ACVars: ICVarSystem);
    destructor Destroy; override;
    /// <summary>Registers the variable (idCVar decl_show) and gives its value to the manager</summary>
    procedure Register;
    /// <summary>Gives the value of the variable to the manager if the variable changed since the last call</summary>
    procedure Synchronize;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Console.CVar.Types;

{ TDeclShowCVar }

constructor TDeclShowCVar.Create(const AManager: IDeclManager; const ACVars: ICVarSystem);
begin
  inherited Create;
  if not Assigned(AManager) then
    raise EArgumentNilException.Create('AManager');
  if not Assigned(ACVars) then
    raise EArgumentNilException.Create('ACVars');
  FManager := AManager;
  FCVars := ACVars;
  // idCmdSystem::ArgCompletion_Integer<0,2>
  FCompletion := TCmdCompletions.Create(0, 2);
end;

destructor TDeclShowCVar.Destroy;
begin
  FCompletion.Free;
  inherited Destroy;
end;

procedure TDeclShowCVar.Register;
var
  LDefinition: TCVarDefinition;
begin
  LDefinition := TCVarDefinition.Create('decl_show', '0', CVAR_SYSTEM,
    'set to 1 to print parses, 2 to also print references', 0, 2);
  LDefinition.ValueCompletion := FCompletion.CompleteInteger;
  FVariable := FCVars.Register(LDefinition);
  FManager.SetShowLevel(FVariable.GetInteger);
  FVariable.ClearModified;
end;

procedure TDeclShowCVar.Synchronize;
begin
  if (FVariable = nil) or not FVariable.IsModified then
    Exit;
  FManager.SetShowLevel(FVariable.GetInteger);
  FVariable.ClearModified;
end;

end.