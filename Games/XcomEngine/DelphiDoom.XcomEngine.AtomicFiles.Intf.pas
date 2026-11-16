{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom engine library - replacing a file in one step (issue 186)  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomEngine.AtomicFiles.Intf;

interface

type
  /// <summary>
  ///   The second interface of an IXcomFileSystem that can write a file so that it is never seen half written: the
  ///   text goes to a temporary file and the temporary file takes the place of the real one in one step. A file system
  ///   that does not give it (a plain IXcomFileSystem) is written in place
  /// </summary>
  IXcomAtomicFiles = interface
    ['{4E7A1B52-0C93-4D68-A5F1-186000000002}']
    /// <summary>The destination (that may exist) becomes the source, and the source is gone; nothing is left half done</summary>
    procedure ReplaceFile(const ASource, ADestination: string);
    /// <summary>A copy of a file; an existing copy is replaced</summary>
    procedure CopyFile(const ASource, ADestination: string);
    /// <summary>Removes a file; a file that is not there is not an error</summary>
    procedure DeleteFile(const APath: string);
  end;

implementation

end.
