{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the particle and fx declarations - fakes               }
{                                                                              }
{  A base of declaration and a finder written by hand: they let one            }
{  declaration be parsed alone, with the lookups of materials, sounds and      }
{  tables answered from a list and written down (the C++ harness does the      }
{  same with a stub of the manager).                                           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Decl.EffectsSupport;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, DelphiDoom.IdLib.Core.Intf, DelphiDoom.Decl.Types,
  DelphiDoom.Decl.Intf, DelphiDoom.Decl.Base;

type
  TFakeDeclFinder = class;

  /// <summary>
  ///   What the manager gives a declaration (<c>IDeclBase</c>), reduced to a name, a text, the finder and the log;
  ///   <c>MakeDefault</c> frees the data and parses the default definition, as the manager does
  /// </summary>
  TFakeDeclBase = class(TInterfacedObject, IDeclBase)
  strict private
    FName: AnsiString;
    FType: Integer;
    FText: AnsiString;
    FReplaced: Boolean;
    FRecursion: Integer;
    FSelf: TDecl;
    [weak] FFinder: IDeclFinder;
    FLog: IIdLibLog;
  public
    constructor Create(const AType: Integer; const AName: AnsiString; const ASelf: TDecl;
      const AFinder: IDeclFinder; const ALog: IIdLibLog);
    function GetName: AnsiString;
    function GetDeclType: Integer;
    function GetState: TDeclState;
    function IsImplicit: Boolean;
    function IsValid: Boolean;
    procedure Invalidate;
    procedure Reload;
    procedure EnsureNotPurged;
    function GetIndex: Integer;
    function GetLineNum: Integer;
    function GetFileName: AnsiString;
    function GetText: AnsiString;
    function GetTextLength: Integer;
    procedure SetText(const AText: AnsiString);
    function ReplaceSourceFileText: Boolean;
    function SourceFileChanged: Boolean;
    procedure MakeDefault;
    function EverReferenced: Boolean;
    function SetDefaultText: Boolean;
    function DefaultDefinition: AnsiString;
    function Parse(const AText: AnsiString): Boolean;
    procedure FreeData;
    function Size: NativeInt;
    procedure List;
    procedure Print;
    function GetFinder: IDeclFinder;
    function GetLog: IIdLibLog;
    property Replaced: Boolean read FReplaced;
  end;

  /// <summary>
  ///   Finds the declarations that were registered (<c>Add</c>) and makes a bare one for any other name when it is
  ///   asked to; every call is written down as <c>F type name make</c>, as the C++ harness writes it
  /// </summary>
  TFakeDeclFinder = class(TInterfacedObject, IDeclFinder)
  strict private
    FDecls: TDictionary<string, IDecl>;
    FLines: TStrings;
    FLog: IIdLibLog;
    FTrace: Boolean;
    class function Key(const AType: Integer; const AName: AnsiString): string; static;
  public
    constructor Create(const ALines: TStrings; const ALog: IIdLibLog);
    destructor Destroy; override;
    function FindType(const AType: Integer; const AName: AnsiString; const AMakeDefault: Boolean = True): IDecl;
    function FindDeclWithoutParsing(const AType: Integer; const AName: AnsiString;
      const AMakeDefault: Boolean = True): IDecl;
    function GetNumDecls(const AType: Integer): Integer;
    function DeclByIndex(const AType, AIndex: Integer; const AForceParse: Boolean = True): IDecl;
    procedure Add(const AType: Integer; const AName: AnsiString; const ADecl: IDecl);
    procedure Clear;
    property Trace: Boolean read FTrace write FTrace;
  end;

  /// <summary>A declaration that is only a name (a material, a sound shader, an entity def)</summary>
  TFakeBareDecl = class(TDecl)
  end;

  /// <summary>Gives a declaration its base, as the manager does when it creates it</summary>
  TFakeDeclMaker = class sealed
  public
    /// <summary>Attaches a <c>TFakeDeclBase</c> to <c>ADecl</c> and returns it</summary>
    class function Attach(const ADecl: TDecl; const AType: Integer; const AName: AnsiString;
      const AFinder: IDeclFinder; const ALog: IIdLibLog): TFakeDeclBase; static;
  end;

implementation

{ TFakeDeclBase }

constructor TFakeDeclBase.Create(const AType: Integer; const AName: AnsiString; const ASelf: TDecl;
  const AFinder: IDeclFinder; const ALog: IIdLibLog);
begin
  inherited Create;
  FType := AType;
  FName := AName;
  FSelf := ASelf;
  FFinder := AFinder;
  FLog := ALog;
end;

function TFakeDeclBase.GetName: AnsiString;
begin
  Result := FName;
end;

function TFakeDeclBase.GetDeclType: Integer;
begin
  Result := FType;
end;

function TFakeDeclBase.GetState: TDeclState;
begin
  Result := dsParsed;
end;

function TFakeDeclBase.IsImplicit: Boolean;
begin
  Result := False;
end;

function TFakeDeclBase.IsValid: Boolean;
begin
  Result := True;
end;

procedure TFakeDeclBase.Invalidate;
begin
end;

procedure TFakeDeclBase.Reload;
begin
end;

procedure TFakeDeclBase.EnsureNotPurged;
begin
end;

function TFakeDeclBase.GetIndex: Integer;
begin
  Result := 0;
end;

function TFakeDeclBase.GetLineNum: Integer;
begin
  Result := 1;
end;

function TFakeDeclBase.GetFileName: AnsiString;
begin
  Result := 'test.decl';
end;

function TFakeDeclBase.GetText: AnsiString;
begin
  Result := FText;
end;

function TFakeDeclBase.GetTextLength: Integer;
begin
  Result := Length(FText);
end;

procedure TFakeDeclBase.SetText(const AText: AnsiString);
begin
  FText := AText;
end;

function TFakeDeclBase.ReplaceSourceFileText: Boolean;
begin
  FReplaced := True;
  Result := True;
end;

function TFakeDeclBase.SourceFileChanged: Boolean;
begin
  Result := False;
end;

procedure TFakeDeclBase.MakeDefault;
begin
  Inc(FRecursion);
  try
    if FRecursion > 100 then
      raise EDeclException.Create('recursion');
    FSelf.FreeData;
    FSelf.Parse(FSelf.DefaultDefinition);
  finally
    Dec(FRecursion);
  end;
end;

function TFakeDeclBase.EverReferenced: Boolean;
begin
  Result := True;
end;

function TFakeDeclBase.SetDefaultText: Boolean;
begin
  Result := False;
end;

function TFakeDeclBase.DefaultDefinition: AnsiString;
begin
  Result := '{ }';
end;

function TFakeDeclBase.Parse(const AText: AnsiString): Boolean;
begin
  Result := True;
end;

procedure TFakeDeclBase.FreeData;
begin
end;

function TFakeDeclBase.Size: NativeInt;
begin
  Result := 0;
end;

procedure TFakeDeclBase.List;
begin
end;

procedure TFakeDeclBase.Print;
begin
end;

function TFakeDeclBase.GetFinder: IDeclFinder;
begin
  Result := FFinder;
end;

function TFakeDeclBase.GetLog: IIdLibLog;
begin
  Result := FLog;
end;

{ TFakeDeclFinder }

constructor TFakeDeclFinder.Create(const ALines: TStrings; const ALog: IIdLibLog);
begin
  inherited Create;
  FDecls := TDictionary<string, IDecl>.Create;
  FLines := ALines;
  FLog := ALog;
  FTrace := True;
end;

destructor TFakeDeclFinder.Destroy;
begin
  FDecls.Free;
  inherited Destroy;
end;

class function TFakeDeclFinder.Key(const AType: Integer; const AName: AnsiString): string;
begin
  Result := IntToStr(AType) + ':' + LowerCase(string(AName));
end;

procedure TFakeDeclFinder.Add(const AType: Integer; const AName: AnsiString; const ADecl: IDecl);
begin
  FDecls.AddOrSetValue(Key(AType, AName), ADecl);
end;

procedure TFakeDeclFinder.Clear;
begin
  FDecls.Clear;
end;

function TFakeDeclFinder.FindType(const AType: Integer; const AName: AnsiString; const AMakeDefault: Boolean): IDecl;
var
  LDecl: TFakeBareDecl;
begin
  if FTrace and Assigned(FLines) then
    FLines.Add(Format('F %d %s %d', [AType, string(AName), Ord(AMakeDefault)]));
  if FDecls.TryGetValue(Key(AType, AName), Result) then
    Exit;
  if not AMakeDefault then
    Exit(nil);
  LDecl := TFakeBareDecl.Create;
  Result := LDecl;
  TFakeDeclMaker.Attach(LDecl, AType, AName, Self, FLog);
  FDecls.Add(Key(AType, AName), Result);
end;

function TFakeDeclFinder.FindDeclWithoutParsing(const AType: Integer; const AName: AnsiString;
  const AMakeDefault: Boolean): IDecl;
begin
  Result := FindType(AType, AName, AMakeDefault);
end;

function TFakeDeclFinder.GetNumDecls(const AType: Integer): Integer;
begin
  Result := 0;
end;

function TFakeDeclFinder.DeclByIndex(const AType, AIndex: Integer; const AForceParse: Boolean): IDecl;
begin
  Result := nil;
end;

{ TFakeDeclMaker }

class function TFakeDeclMaker.Attach(const ADecl: TDecl; const AType: Integer; const AName: AnsiString;
  const AFinder: IDeclFinder; const ALog: IIdLibLog): TFakeDeclBase;
begin
  Result := TFakeDeclBase.Create(AType, AName, ADecl, AFinder, ALog);
  ADecl.SetBase(Result);
end;

end.
