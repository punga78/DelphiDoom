{******************************************************************************}
{                                                                              }
{  DelphiDoom: tools core library - constants and the exception                 }
{  Copyright (C) 2021-2022 by Jim Valavanis (original ENDEDIT, DD_FONT, DD_VOXEL) }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tools.Types;

interface

uses
  System.SysUtils;

const
  /// <summary>
  ///   Snapshots kept by the undo of a document: the limit that the old tools really had (their
  ///   stack was created with 1000 although the manager declared a default of 10)
  /// </summary>
  TOOLS_UNDO_LIMIT = 1000;
  /// <summary>Entries of the recent files list (the menu of the old tools had ten items)</summary>
  TOOLS_RECENT_FILES_LIMIT = 10;
  /// <summary>The longest file name that a menu shows without shortening it</summary>
  TOOLS_SHORT_NAME_LIMIT = 30;
  /// <summary>Suffix of the backup copy of a file that is about to be overwritten</summary>
  TOOLS_BACKUP_SUFFIX = '_bak';

resourcestring
  SToolsBadLimit = 'Tools: the limit must not be negative, not %d';
  SToolsBadIndex = 'Tools: the index %d is out of range (count %d)';
  SToolsBadProgressTotal = 'Tools: the total of a progress must not be negative, not %d';

type
  /// <summary>A wrong argument given to a class of the tools core library</summary>
  EToolsException = class(Exception);

implementation

end.
