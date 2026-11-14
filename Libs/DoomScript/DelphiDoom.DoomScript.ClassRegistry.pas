{******************************************************************************}
{                                                                              }
{  DelphiDoom: Doom script (id Tech 4) - TDoomScriptClassRegistry              }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software): game\gamesys\Class.cpp   }
{  (the list of idTypeInfo, idClass::GetClass). Copyright (C) 1999-2011 id     }
{  Software LLC, a ZeniMax Media company.                                      }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3 or later, with    }
{  the additional terms of the Doom 3 Source Code License (see README.md of    }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.DoomScript.ClassRegistry;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.DoomScript.Types, DelphiDoom.DoomScript.ClassInfo;

type
  /// <summary>
  ///   The classes of the host that receive events, by name (the list of idTypeInfo of the original). The
  ///   registry owns the class descriptions. The host declares its classes here (as CLASS_DECLARATION did)
  ///   and adds the handlers of the events to them.
  /// </summary>
  TDoomScriptClassRegistry = class
  strict private
    FClasses: TObjectList<TDoomScriptClassInfo>;
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>
    ///   Declares a class; the superclass must already be declared ('' for none). Raises EDoomScriptError
    ///   if the name is taken or the superclass is unknown.
    /// </summary>
    function Declare(const AName: AnsiString; const ASuperName: AnsiString = ''): TDoomScriptClassInfo;
    /// <summary>idClass::GetClass: nil if there is no class with this name (case sensitive)</summary>
    function GetClass(const AName: AnsiString): TDoomScriptClassInfo;
  end;

implementation

const
  SClassDeclaredTwice = 'TDoomScriptClassRegistry: class ''%s'' declared twice';
  SUnknownSuperclass = 'TDoomScriptClassRegistry: unknown superclass ''%s'' of class ''%s''';

constructor TDoomScriptClassRegistry.Create;
begin
  inherited Create;
  FClasses := TObjectList<TDoomScriptClassInfo>.Create(True);
end;

destructor TDoomScriptClassRegistry.Destroy;
begin
  FClasses.Free;
  inherited;
end;

function TDoomScriptClassRegistry.GetClass(const AName: AnsiString): TDoomScriptClassInfo;
var
  LIndex: Integer;
begin
  for LIndex := 0 to FClasses.Count - 1 do
    if FClasses[LIndex].Name = AName then
      Exit(FClasses[LIndex]);
  Result := nil;
end;

function TDoomScriptClassRegistry.Declare(const AName, ASuperName: AnsiString): TDoomScriptClassInfo;
var
  LSuper: TDoomScriptClassInfo;
begin
  if Assigned(GetClass(AName)) then
    raise EDoomScriptError.CreateFmt(SClassDeclaredTwice, [string(AName)]);
  LSuper := nil;
  if ASuperName <> '' then
  begin
    LSuper := GetClass(ASuperName);
    if not Assigned(LSuper) then
      raise EDoomScriptError.CreateFmt(SUnknownSuperclass, [string(ASuperName), string(AName)]);
  end;
  Result := TDoomScriptClassInfo.Create(AName, LSuper);
  FClasses.Add(Result);
end;

end.
