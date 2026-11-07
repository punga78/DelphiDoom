{******************************************************************************}
{                                                                              }
{  DelphiDoom: ide library - the texts written in the message list             }
{  Copyright (C) 2016-2022 by Jim Valavanis (original DD_IDE)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Ide.Messages;

interface

const
  SCannotCreateFile = 'Can not create file "%s"'#13#10;
  SCannotReadFile = 'Can not read file "%s"'#13#10;
  SCannotWriteFile = 'Can not write file "%s"'#13#10;
  SLoadingFile = 'Loading "%s"'#13#10;
  SSavingFile = 'Saving "%s"'#13#10;
  SCannotAccessPath = 'Can not access path "%s"'#13#10;
  SUnknownGameType = 'Unknown game type "%s"'#13#10;
  SCannotGeneratePk3 = 'Can not generate file "%s"'#13#10;
  SCreatedPk3 = 'Created PK3 file "%s"'#13#10;
  SRenameAlreadyInProject =
    'TIDEProject.ExecRename(): Can not rename "%s" to "%s". "%s" already in project'#13#10;
  SRenameReplaced = 'File "%s" replaced with existing file "%s"'#13#10;
  SRenameSavePending = 'Please save "%s" before replacing it with file "%s"'#13#10;
  SRenameSavedAs = 'File "%s" saved in new file "%s"'#13#10;
  SDisassembling = 'Disassembling %s compiled script "%s"';
  SCompiling = 'Compiling %s script "%s"';
  SCompileSuccessful = 'Compile successful';
  SSearchNotFound = '"%s" not found'#13#10;

implementation

end.
