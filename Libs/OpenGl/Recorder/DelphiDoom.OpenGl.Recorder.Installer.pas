{******************************************************************************}
{                                                                              }
{  DelphiDoom: OpenGL call recorder - installs the thunks                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.OpenGl.Recorder.Installer;

interface

uses
  DelphiDoom.OpenGl.Recorder.Intf;

type
  /// <summary>
  ///   Puts the thunks of a table in the variables of the binding and takes them away again. A
  ///   function whose variable is nil (the driver does not have it: a GL extension) is not hooked
  ///   and its name goes to Missing, so that the harness can say what the recording does not cover.
  /// </summary>
  TGlHookInstaller = class
  strict private
    FTable: IGlHookTable;
    FInstalled: Boolean;
    FMissing: TArray<string>;
    FHooked: TArray<Boolean>;
    FOriginals: TArray<Pointer>;
  public
    constructor Create(const ATable: IGlHookTable);
    /// <summary>Replaces every function that the driver gave; the number of functions replaced</summary>
    function Install: Integer;
    /// <summary>Puts the original functions back</summary>
    procedure Uninstall;
    /// <summary>The functions that were not replaced because their variable was nil</summary>
    property Missing: TArray<string> read FMissing;
    property Installed: Boolean read FInstalled;
  end;

implementation

uses
  System.SysUtils,
  DelphiDoom.OpenGl.Recorder.Types;

resourcestring
  SGlInstallerTableNil = 'The installer needs a table of functions';
  SGlInstallerAlready = 'The thunks are already installed';

{ TGlHookInstaller }

constructor TGlHookInstaller.Create(const ATable: IGlHookTable);
begin
  inherited Create;
  if not Assigned(ATable) then
    raise EArgumentNilException.Create(SGlInstallerTableNil);
  FTable := ATable;
end;

function TGlHookInstaller.Install: Integer;
var
  LIndex: Integer;
  LSlot: PPointer;
begin
  if FInstalled then
    raise EGlRecorderException.Create(SGlInstallerAlready);
  Result := 0;
  FMissing := nil;
  SetLength(FHooked, FTable.Count);
  SetLength(FOriginals, FTable.Count);
  for LIndex := 0 to FTable.Count - 1 do
  begin
    LSlot := FTable.Slot(LIndex);
    FHooked[LIndex] := False;
    FOriginals[LIndex] := LSlot^;
    if LSlot^ = nil then
    begin
      SetLength(FMissing, Length(FMissing) + 1);
      FMissing[High(FMissing)] := FTable.Name(LIndex);
      Continue;
    end;
    FTable.SetOriginal(LIndex, LSlot^);
    LSlot^ := FTable.Thunk(LIndex);
    FHooked[LIndex] := True;
    Inc(Result);
  end;
  FInstalled := True;
end;

procedure TGlHookInstaller.Uninstall;
var
  LIndex: Integer;
begin
  if not FInstalled then
    Exit;
  // a variable that somebody else changed after the install is left as it is
  for LIndex := 0 to FTable.Count - 1 do
    if FHooked[LIndex] and (FTable.Slot(LIndex)^ = FTable.Thunk(LIndex)) then
      FTable.Slot(LIndex)^ := FOriginals[LIndex];
  FInstalled := False;
end;

end.
