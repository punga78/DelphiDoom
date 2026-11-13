{******************************************************************************}
{                                                                              }
{  DelphiDoom: declaration manager - the interfaces                            }
{                                                                              }
{  Port of the declaration manager of Doom 3 (id Software, GPL v3):            }
{  framework\DeclManager.h. Copyright (C) 1999-2011 id Software LLC, a         }
{  ZeniMax Media company.                                                      }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Decl.Intf;

interface

uses
  System.SysUtils, DelphiDoom.IdLib.Core.Intf, DelphiDoom.Decl.Types;

type
  IDecl = interface;
  IDeclFinder = interface;

  /// <summary>
  ///   What the manager keeps for one declaration (idDeclBase): name, type, state, where the text came from,
  ///   the text itself. The defaults of the overridable calls (<c>SetDefaultText</c>, <c>DefaultDefinition</c>,
  ///   <c>Parse</c>, <c>FreeData</c>, <c>Size</c>, <c>List</c>, <c>Print</c>) are the ones of idDeclLocal.
  ///   Implemented by the manager only (no reference count: the manager owns it).
  /// </summary>
  IDeclBase = interface
    ['{5E0C1A52-7B1E-4C0B-9D4B-4C6E3D0A0002}']
    function GetName: AnsiString;
    function GetDeclType: Integer;
    function GetState: TDeclState;
    /// <summary>True if the decl was created because no explicit text was found (it belongs to the implicit file)</summary>
    function IsImplicit: Boolean;
    /// <summary>False only for a decl found with <c>DeclByIndex(.., False)</c> that has not been parsed</summary>
    function IsValid: Boolean;
    /// <summary>Sets the state back to unparsed (the next <c>EnsureNotPurged</c> parses it again)</summary>
    procedure Invalidate;
    procedure Reload;
    procedure EnsureNotPurged;
    /// <summary>The index in the list of its type; it never changes</summary>
    function GetIndex: Integer;
    function GetLineNum: Integer;
    function GetFileName: AnsiString;
    function GetText: AnsiString;
    function GetTextLength: Integer;
    procedure SetText(const AText: AnsiString);
    /// <summary>Writes the text of the decl in its source file (the editors); false with a warning if it cannot</summary>
    function ReplaceSourceFileText: Boolean;
    function SourceFileChanged: Boolean;
    /// <summary>Frees the data and loads the default definition of the type</summary>
    procedure MakeDefault;
    function EverReferenced: Boolean;
    function SetDefaultText: Boolean;
    function DefaultDefinition: AnsiString;
    function Parse(const AText: AnsiString): Boolean;
    procedure FreeData;
    function Size: NativeInt;
    procedure List;
    procedure Print;
    /// <summary>The manager, for a decl that refers to others while it parses</summary>
    function GetFinder: IDeclFinder;
    /// <summary>Where warnings go (may be nil)</summary>
    function GetLog: IIdLibLog;
  end;

  /// <summary>
  ///   A declaration (idDecl): the object of one type, <c>TDeclSkin</c> and the others. It is owned by the
  ///   manager (the manager keeps a reference for its whole life), the one you get is valid while the manager
  ///   is alive. Ask for the type specific interface with <c>Supports(Decl, IDeclSkin, Skin)</c>.
  /// </summary>
  IDecl = interface(IDeclBase)
    ['{5E0C1A52-7B1E-4C0B-9D4B-4C6E3D0A0003}']
    /// <summary>Called once by the manager before anything else</summary>
    procedure SetBase(const ABase: IDeclBase);
  end;

  /// <summary>How the manager makes the declaration objects of a type (the <c>allocator</c> of RegisterDeclType)</summary>
  TDeclAllocator = reference to function: IDecl;

  /// <summary>A registered type: its name in the files ("skin"), its number and its allocator</summary>
  IDeclType = interface
    ['{5E0C1A52-7B1E-4C0B-9D4B-4C6E3D0A0004}']
    function GetTypeName: AnsiString;
    function GetTypeId: Integer;
    function CreateDecl: IDecl;
  end;

  /// <summary>What a declaration needs to find another one while it parses</summary>
  IDeclFinder = interface
    ['{5E0C1A52-7B1E-4C0B-9D4B-4C6E3D0A0005}']
    /// <summary>
    ///   The decl, parsed (a parse on demand). With <c>AMakeDefault</c> a default decl is created if there is no
    ///   explicit one, without it nil is returned. An empty name is "_emptyName". A type that was never
    ///   registered is an <c>EDeclException</c>.
    /// </summary>
    function FindType(const AType: Integer; const AName: AnsiString; const AMakeDefault: Boolean = True): IDecl;
    /// <summary>Like FindType but the decl is not parsed and not marked as referenced</summary>
    function FindDeclWithoutParsing(const AType: Integer; const AName: AnsiString;
      const AMakeDefault: Boolean = True): IDecl;
    function GetNumDecls(const AType: Integer): Integer;
    /// <summary>Walks the list of a type; without <c>AForceParse</c> the decl is not parsed</summary>
    function DeclByIndex(const AType, AIndex: Integer; const AForceParse: Boolean = True): IDecl;
  end;

  /// <summary>
  ///   What a library needs to plug its declaration types in (#101 effects, #102 materials, #112 sound shaders,
  ///   #119 Quake III shaders): <c>RegisterDeclType</c> and <c>RegisterDeclFolder</c>.
  /// </summary>
  IDeclRegistry = interface
    ['{5E0C1A52-7B1E-4C0B-9D4B-4C6E3D0A0006}']
    /// <summary>Registers a type; a type number already in use is a warning and the call is ignored</summary>
    procedure RegisterDeclType(const ATypeName: AnsiString; const AType: Integer;
      const AAllocator: TDeclAllocator); overload;
    procedure RegisterDeclType(const AType: IDeclType); overload;
    /// <summary>
    ///   Registers a folder and loads every file with the extension in it, each file becoming decls of the types
    ///   named inside it (or of <c>ADefaultType</c> for a file of nameless decls)
    /// </summary>
    procedure RegisterDeclFolder(const AFolder, AExtension: AnsiString; const ADefaultType: Integer);
    function GetNumDeclTypes: Integer;
    function GetDeclNameFromType(const AType: Integer): AnsiString;
    /// <summary>The number of a type name (ignoring case), DECL_MAX_TYPES if there is none</summary>
    function GetDeclTypeFromName(const ATypeName: AnsiString): Integer;
  end;

  /// <summary>The manager (idDeclManager): the registry, the finder and the life of the declarations</summary>
  IDeclManager = interface(IDeclFinder)
    ['{5E0C1A52-7B1E-4C0B-9D4B-4C6E3D0A0007}']
    function GetRegistry: IDeclRegistry;
    /// <summary>Reloads the files whose time changed (all of them if <c>AForce</c>); never purges</summary>
    procedure Reload(const AForce: Boolean);
    procedure ReloadFile(const AFileName: AnsiString; const AForce: Boolean);
    /// <summary>Starts a level: every decl not parsed outside a level load is purged (it parses again on the next find)</summary>
    procedure BeginLevelLoad;
    procedure EndLevelLoad;
    /// <summary>A checksum of the text of all the explicit decls (PDAs and their parts and implicit decls excluded)</summary>
    function GetChecksum: Integer;
    /// <summary>What <c>decl_show</c> prints: 1 parses, 2 also references (to the log)</summary>
    procedure SetShowLevel(const ALevel: Integer);
    /// <summary>list* commands: writes to the log</summary>
    procedure ListType(const AType: Integer; const AMode: TDeclListMode);
    /// <summary>print* commands: writes to the log the text and the data of one decl</summary>
    procedure PrintType(const AType: Integer; const AName: AnsiString);
    /// <summary>Creates a decl with the default text of its type in a file (the editors)</summary>
    function CreateNewDecl(const AType: Integer; const AName, AFileName: AnsiString): IDecl;
    function RenameDecl(const AType: Integer; const AOldName, ANewName: AnsiString): Boolean;
    /// <summary>The "touch type name" lines of the decls used in this level</summary>
    function WritePrecacheCommands: AnsiString;
  end;

implementation

end.
