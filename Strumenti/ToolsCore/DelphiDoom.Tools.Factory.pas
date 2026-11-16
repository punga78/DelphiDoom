{******************************************************************************}
{                                                                              }
{  DelphiDoom: tools core library - the factory: the composition root           }
{  Copyright (C) 2021-2022 by Jim Valavanis (original ENDEDIT, DD_FONT, DD_VOXEL) }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tools.Factory;

interface

uses
  DelphiDoom.Tools.Intf;

type
  /// <summary>The only place that knows the classes behind the interfaces of the tools core library</summary>
  TToolsFactory = class
  public
    /// <param name="ALimit">Snapshots kept for the undo; 0 means no limit</param>
    class function CreateUndoHistory(ALimit: Integer): IToolUndoHistory; static;
    class function CreateRecentFiles(ALimit: Integer): IRecentFiles; static;
    class function CreateSettings(const AFileSystem: IToolFileSystem;
      const APath: string): ISettingsStore; static;
    /// <param name="AObserver">Who is told of the progress; may be nil</param>
    class function CreateProgressReporter(const AObserver: IProgressObserver): IProgressReporter; static;
    class function CreateFileBackup(const AFileSystem: IToolFileSystem): IToolFileBackup; static;
  end;

implementation

uses
  DelphiDoom.Tools.UndoHistory,
  DelphiDoom.Tools.RecentFiles,
  DelphiDoom.Tools.SettingsStore,
  DelphiDoom.Tools.ProgressReporter,
  DelphiDoom.Tools.FileBackup;

{ TToolsFactory }

class function TToolsFactory.CreateUndoHistory(ALimit: Integer): IToolUndoHistory;
begin
  Result := TToolUndoHistory.Create(ALimit);
end;

class function TToolsFactory.CreateRecentFiles(ALimit: Integer): IRecentFiles;
begin
  Result := TRecentFiles.Create(ALimit);
end;

class function TToolsFactory.CreateSettings(const AFileSystem: IToolFileSystem;
  const APath: string): ISettingsStore;
begin
  Result := TSettingsStore.Create(AFileSystem, APath);
end;

class function TToolsFactory.CreateProgressReporter(const AObserver: IProgressObserver): IProgressReporter;
begin
  Result := TProgressReporter.Create(AObserver);
end;

class function TToolsFactory.CreateFileBackup(const AFileSystem: IToolFileSystem): IToolFileBackup;
begin
  Result := TToolFileBackup.Create(AFileSystem);
end;

end.
