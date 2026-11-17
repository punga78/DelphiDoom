{******************************************************************************}
{                                                                              }
{  DelphiDoom: Doom 3 game library - the classes of the game (idClass statics) }
{                                                                              }
{  Port of Doom 3 (id Software): game\gamesys\Class.cpp (the static            }
{  functions and data of idClass, the registration part of idTypeInfo).        }
{  Based on the Doom 3 GPL Source Code (id Software).                          }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3 or (at your       }
{  option) any later version, with the additional terms of the Doom 3 Source   }
{  Code License (Reference\doom3\COPYING.txt: preservation of legal notices    }
{  and trademarks, no use of the licensors' names for publicity, warranty      }
{  disclaimer). The repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.D3Game.ClassSystem;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.IdLib.Containers.Hierarchy,
  DelphiDoom.DoomScript.Types, DelphiDoom.DoomScript.EventDef, DelphiDoom.DoomScript.EventRegistry,
  DelphiDoom.D3Game.Intf,
  DelphiDoom.D3Game.ClassBase;

type
  /// <summary>
  ///   The classes of the game, by name and by number (the static members of <c>idClass</c>: <c>typelist</c>,
  ///   <c>types</c>, <c>typenums</c>, <c>typeNumBits</c>, <c>classHierarchy</c>). A class is declared in any order
  ///   (a subclass may come before its superclass, as the static initialization of the original allows); <c>Init</c>
  ///   builds the event tables and numbers the classes along the hierarchy so that <c>IsType</c> is a range test.
  ///   The system owns the class descriptions and declares <c>idClass</c> itself, with its two events (<c>remove</c> and
  ///   <c>&lt;immediateremove&gt;</c>), in the event registry it is given.
  /// </summary>
  TD3ClassSystem = class
  strict private
    FPrinter: ID3GamePrinter;
    FEvents: TDoomScriptEventRegistry;
    FEventPoster: ID3EventPoster;
    FEventRemove: TDoomScriptEventDef;
    FEventSafeRemove: TDoomScriptEventDef;
    FTypeList: TObjectList<TD3TypeInfo>;
    FClassHierarchy: TIdHierarchy<TD3TypeInfo>;
    FTypes: TList<TD3TypeInfo>;
    FTypeNums: TList<TD3TypeInfo>;
    FInitialized: Boolean;
    FTypeNumBits: Integer;
    FEventCallbackMemory: Integer;
    procedure DeclareBaseClass;
  public
    /// <param name="AEvents">the registry that numbers the events (<c>idEventDef::NumEventCommands</c>)</param>
    /// <param name="AEventPoster">where the <c>remove</c> event of <c>idClass</c> posts the immediate one; may be nil</param>
    constructor Create(const APrinter: ID3GamePrinter; const AEvents: TDoomScriptEventRegistry;
      const AEventPoster: ID3EventPoster);
    destructor Destroy; override;
    /// <summary>
    ///   CLASS_DECLARATION / ABSTRACT_DECLARATION (idTypeInfo::idTypeInfo): links the class into the sorted list of
    ///   all the classes, takes the subclasses that were declared before it. Raises EArgumentException for a name that
    ///   is taken. Add the <c>EVENT</c> lines with <c>AddEvent</c> of the result before <c>Init</c>.
    /// </summary>
    /// <param name="AFactory">nil for an abstract class</param>
    function Declare(const AClassName, ASuperclassName: AnsiString; const AFactory: TD3InstanceFactory;
      const ASpawn: TD3SpawnProc; const AAbstract: Boolean = False): TD3TypeInfo;
    /// <summary>
    ///   idClass::Init: the event tables of all the classes, the numbering along the hierarchy, the lists by name and by
    ///   number. Prints the same lines as the original; does nothing the second time (until <c>Shutdown</c>).
    /// </summary>
    procedure Init;
    /// <summary>idClass::Shutdown: the event tables are freed and the numbers forgotten; the classes stay declared</summary>
    procedure Shutdown;
    /// <summary>
    ///   idClass::GetClass: nil if no class has that name (case sensitive); a binary search once initialized, a walk
    ///   through the list before
    /// </summary>
    function GetClass(const AName: AnsiString): TD3TypeInfo;
    /// <summary>idClass::GetType( int ): nil for a number that is not a class; before <c>Init</c> the first class with that number</summary>
    function GetType(const ANumber: Integer): TD3TypeInfo;
    /// <summary>idClass::CreateInstance( name ): nil if there is no such class</summary>
    function CreateInstance(const AName: AnsiString): TD3Class;
    /// <summary>idClass::ListClasses_f: the table of classes to the printer</summary>
    procedure ListClasses;
    /// <summary>The number of the classes in the sorted list (the declared ones)</summary>
    function DeclaredCount: Integer;
    /// <summary>One declared class by its place in the sorted list (alphabetical, case sensitive)</summary>
    function DeclaredClass(const AIndex: Integer): TD3TypeInfo;
    /// <summary>idClass::GetNumTypes</summary>
    function NumTypes: Integer;
    property Initialized: Boolean read FInitialized;
    /// <summary>idClass::GetTypeNumBits</summary>
    property TypeNumBits: Integer read FTypeNumBits;
    /// <summary>The events of <c>idClass</c>: EV_Remove (immediate) and EV_SafeRemove</summary>
    property EventRemove: TDoomScriptEventDef read FEventRemove;
    property EventSafeRemove: TDoomScriptEventDef read FEventSafeRemove;
  end;

implementation

uses
  DelphiDoom.IdLib.Text.Strings, DelphiDoom.IdLib.Math.Math, DelphiDoom.D3Game.Types;

const
  SClassDeclaredTwice = 'TD3ClassSystem: class ''%s'' declared twice';
  SInitializing = 'Initializing class hierarchy'#10;
  SAlreadyInitialized = '...already initialized'#10;
  SInitialized = '...%d classes, %d bytes for event callbacks'#10;
  SListHeader = '%-24s %-24s %-6s %-6s'#10;
  SListRule = '----------------------------------------------------------------------'#10;
  SListRow = '%-24s %-24s %6d %6d'#10;
  SListFooter = '...%d classes';

constructor TD3ClassSystem.Create(const APrinter: ID3GamePrinter; const AEvents: TDoomScriptEventRegistry;
  const AEventPoster: ID3EventPoster);
begin
  inherited Create;
  FPrinter := APrinter;
  FEvents := AEvents;
  FEventPoster := AEventPoster;
  FTypeList := TObjectList<TD3TypeInfo>.Create(True);
  FClassHierarchy := TIdHierarchy<TD3TypeInfo>.Create;
  FTypes := TList<TD3TypeInfo>.Create;
  FTypeNums := TList<TD3TypeInfo>.Create;
  DeclareBaseClass;
end;

destructor TD3ClassSystem.Destroy;
begin
  FTypeNums.Free;
  FTypes.Free;
  FTypeList.Free;
  FClassHierarchy.Free;
  inherited Destroy;
end;

procedure TD3ClassSystem.DeclareBaseClass;
var
  LPoster: ID3EventPoster;
  LRemove: TDoomScriptEventDef;
  LType: TD3TypeInfo;
begin
  // const idEventDef EV_Remove( "<immediateremove>", NULL ); const idEventDef EV_SafeRemove( "remove", NULL );
  FEventRemove := FEvents.Define('<immediateremove>');
  FEventSafeRemove := FEvents.Define('remove');
  LPoster := FEventPoster;
  LRemove := FEventRemove;
  // ABSTRACT_DECLARATION( NULL, idClass )
  LType := Declare(D3_CLASS_NAME, D3_NO_SUPERCLASS, nil, TD3Class.SpawnClass, True);
  // EVENT( EV_Remove, idClass::Event_Remove ): delete this
  LType.AddEvent(FEventRemove,
    procedure(const ATarget: TD3Class; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    begin
      ATarget.Free;
    end);
  // EVENT( EV_SafeRemove, idClass::Event_SafeRemove ): forces the remove to be done at a safe time
  LType.AddEvent(FEventSafeRemove,
    procedure(const ATarget: TD3Class; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    begin
      if Assigned(LPoster) then
        LPoster.PostEventMS(ATarget, LRemove, 0);
    end);
end;

function TD3ClassSystem.Declare(const AClassName, ASuperclassName: AnsiString; const AFactory: TD3InstanceFactory;
  const ASpawn: TD3SpawnProc; const AAbstract: Boolean): TD3TypeInfo;
var
  LOther: TD3TypeInfo;
  LIndex: Integer;
begin
  if Assigned(GetClass(AClassName)) then
    raise EArgumentException.CreateFmt(SClassDeclaredTwice, [string(AClassName)]);
  Result := TD3TypeInfo.Create(AClassName, ASuperclassName, AFactory, ASpawn, AAbstract, FPrinter);
  Result.Super := GetClass(ASuperclassName);

  // check if any subclasses were initialized before their superclass
  for LOther in FTypeList do
    if (not Assigned(LOther.Super)) and (TIdStrings.Cmp(LOther.SuperclassName, AClassName) = 0) and
      (TIdStrings.Cmp(LOther.Name, D3_CLASS_NAME) <> 0) then
      LOther.Super := Result;

  // insert sorted
  LIndex := 0;
  while (LIndex < FTypeList.Count) and (TIdStrings.Cmp(AClassName, FTypeList[LIndex].Name) >= 0) do
    Inc(LIndex);
  FTypeList.Insert(LIndex, Result);
end;

procedure TD3ClassSystem.Init;
var
  LType: TD3TypeInfo;
  LNumber: Integer;
  LIndex: Integer;
begin
  FPrinter.Printf(SInitializing);
  if FInitialized then
  begin
    FPrinter.Printf(SAlreadyInitialized);
    Exit;
  end;

  // init the event callback tables for all the classes
  for LType in FTypeList do
    LType.Init(FClassHierarchy, FEvents.Count, FEventCallbackMemory);

  // number the types according to the class hierarchy so we can quickly determine if a class
  // is a subclass of another
  LNumber := 0;
  LType := FClassHierarchy.GetNext;
  while Assigned(LType) do
  begin
    LType.TypeNum := LNumber;
    LType.LastChild := LType.LastChild + LNumber;
    LType := LType.Node.GetNext;
    Inc(LNumber);
  end;

  // number of bits needed to send types over network
  FTypeNumBits := TIdMath.BitsForInteger(LNumber);

  // create a list of the types so we can do quick lookups: one list in alphabetical order, one in typenum order
  FTypes.Count := LNumber;
  FTypeNums.Count := LNumber;
  LIndex := 0;
  for LType in FTypeList do
  begin
    // the original writes past its lists if a class is not in the hierarchy; here such a class is left out
    if LIndex < LNumber then
      FTypes[LIndex] := LType;
    if (LType.TypeNum >= 0) and (LType.TypeNum < LNumber) then
      FTypeNums[LType.TypeNum] := LType;
    Inc(LIndex);
  end;

  FInitialized := True;
  FPrinter.Printf(AnsiString(Format(SInitialized, [FTypes.Count, FEventCallbackMemory])));
end;

procedure TD3ClassSystem.Shutdown;
var
  LType: TD3TypeInfo;
begin
  for LType in FTypeList do
    LType.Shutdown;
  FTypes.Clear;
  FTypeNums.Clear;
  FInitialized := False;
end;

function TD3ClassSystem.GetClass(const AName: AnsiString): TD3TypeInfo;
var
  LOrder: Integer;
  LMid: Integer;
  LMin: Integer;
  LMax: Integer;
  LType: TD3TypeInfo;
begin
  if not FInitialized then
  begin
    // idClass::Init hasn't been called yet, so do a slow lookup
    for LType in FTypeList do
      if TIdStrings.Cmp(LType.Name, AName) = 0 then
        Exit(LType);
  end
  else
  begin
    // do a binary search through the list of types
    LMin := 0;
    LMax := FTypes.Count - 1;
    while LMin <= LMax do
    begin
      LMid := (LMin + LMax) div 2;
      LType := FTypes[LMid];
      LOrder := TIdStrings.Cmp(LType.Name, AName);
      if LOrder = 0 then
        Exit(LType)
      else if LOrder > 0 then
        LMax := LMid - 1
      else
        LMin := LMid + 1;
    end;
  end;
  Result := nil;
end;

function TD3ClassSystem.GetType(const ANumber: Integer): TD3TypeInfo;
var
  LType: TD3TypeInfo;
begin
  if not FInitialized then
  begin
    for LType in FTypeList do
      if LType.TypeNum = ANumber then
        Exit(LType);
  end
  else if (ANumber >= 0) and (ANumber < FTypes.Count) then
    Exit(FTypeNums[ANumber]);
  Result := nil;
end;

function TD3ClassSystem.CreateInstance(const AName: AnsiString): TD3Class;
var
  LType: TD3TypeInfo;
begin
  LType := GetClass(AName);
  if not Assigned(LType) then
    Exit(nil);
  Result := LType.CreateInstance;
end;

procedure TD3ClassSystem.ListClasses;
var
  LType: TD3TypeInfo;
begin
  FPrinter.Printf(AnsiString(Format(SListHeader, ['Classname', 'Superclass', 'Type', 'Subclasses'])));
  FPrinter.Printf(SListRule);
  for LType in FTypes do
    FPrinter.Printf(AnsiString(Format(SListRow, [string(LType.Name), string(LType.SuperclassName),
      LType.TypeNum, LType.LastChild - LType.TypeNum])));
  FPrinter.Printf(AnsiString(Format(SListFooter, [FTypes.Count])));
end;

function TD3ClassSystem.DeclaredCount: Integer;
begin
  Result := FTypeList.Count;
end;

function TD3ClassSystem.DeclaredClass(const AIndex: Integer): TD3TypeInfo;
begin
  Result := FTypeList[AIndex];
end;

function TD3ClassSystem.NumTypes: Integer;
begin
  Result := FTypes.Count;
end;

end.
