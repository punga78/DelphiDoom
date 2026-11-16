{******************************************************************************}
{                                                                              }
{  DelphiDoom: ide library - the pk3 file of a project                         }
{  Copyright (C) 2016-2022 by Jim Valavanis (original DD_IDE)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Ide.Pk3Builder;

interface

uses
  DelphiDoom.Ide.Intf,
  DelphiDoom.Ide.Project;

type
  /// <summary>
  ///   Packs a project in a pk3 file: every script goes in with its short file name (a compiled
  ///   script is read again from the disk), and all the actor lists are joined, one after the
  ///   other, in a lump called ACTORDEF.TXT written last
  /// </summary>
  TIdePk3Builder = class
  strict private
    FArchiveFactory: TIdeArchiveFactory;
    FLog: IIdeLog;
    FClock: IIdeClock;
  public
    constructor Create(const AArchiveFactory: TIdeArchiveFactory; const ALog: IIdeLog;
      const AClock: IIdeClock);
    /// <summary>Gives false (with a message) if the file can not be written</summary>
    function Generate(const AProject: TIdeProject; const AFileName: string): Boolean;
  end;

implementation

uses
  System.SysUtils,
  DelphiDoom.Ide.Types,
  DelphiDoom.Ide.Messages,
  DelphiDoom.Ide.ProjectItem;

{ TIdePk3Builder }

constructor TIdePk3Builder.Create(const AArchiveFactory: TIdeArchiveFactory; const ALog: IIdeLog;
  const AClock: IIdeClock);
begin
  inherited Create;
  if not Assigned(AArchiveFactory) then
    raise EArgumentNilException.Create('AArchiveFactory');
  if not Assigned(ALog) then
    raise EArgumentNilException.Create('ALog');
  if not Assigned(AClock) then
    raise EArgumentNilException.Create('AClock');
  FArchiveFactory := AArchiveFactory;
  FLog := ALog;
  FClock := AClock;
end;

function TIdePk3Builder.Generate(const AProject: TIdeProject; const AFileName: string): Boolean;
var
  LArchive: IIdeArchive;
  LActorDef: AnsiString;
  LIndex: Integer;
  LItem: TIdeProjectItem;
begin
  if not Assigned(AProject) then
    raise EArgumentNilException.Create('AProject');
  Result := True;
  try
    LArchive := FArchiveFactory();
    LActorDef := '';
    for LIndex := 0 to AProject.Count - 1 do
    begin
      LItem := AProject.Items[LIndex];
      if LItem.Kind = ikActor then
        LActorDef := LActorDef + LItem.Data + #13#10
      else
      begin
        if LItem.Kind = ikCompiledScript then
          LItem.LoadFromFile(LItem.FileName);
        LArchive.AddFile(LItem.ShortFileName, LItem.Data, FClock.Now);
      end;
    end;
    if LActorDef <> '' then
      LArchive.AddFile('ACTORDEF.TXT', LActorDef, FClock.Now);
    LArchive.SaveToFile(AFileName);
  except
    // the old code answered any failure with false and one message
    Result := False;
  end;
  if Result then
    FLog.WriteFormat(mkNormal, SCreatedPk3, [AFileName])
  else
    FLog.WriteFormat(mkError, SCannotGeneratePk3, [AFileName]);
end;

end.
