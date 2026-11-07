{******************************************************************************}
{                                                                              }
{  DelphiDoom: platform library - the contracts                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Platform.Intf;

interface

uses
  System.SysUtils, DelphiDoom.Platform.Types;

type
  /// <summary>Whole files: read, write, append, delete, and the directories of them</summary>
  IFileStore = interface
    ['{5D2B8A41-93C7-4E1F-A6B0-72F4C1D9E835}']
    function Exists(const AName: string): Boolean;
    /// <summary>
    ///   Creates (or empties) a file and writes ALength bytes; False if the file cannot be
    ///   created or ALength is not positive
    /// </summary>
    function Write(const AName: string; ASource: Pointer; ALength: Integer): Boolean;
    /// <summary>
    ///   Adds ALength bytes at the end (the file is created if it is not there); the number of
    ///   bytes written, 0 if there was nothing to write or the write failed
    /// </summary>
    function Append(const AName: string; ASource: Pointer; ALength: Integer): Integer;
    /// <summary>All the bytes of a file; raises EPlatformException if it cannot be read</summary>
    function Read(const AName: string): TBytes;
    /// <summary>Deletes a file; False if it was not there or could not be deleted</summary>
    function Delete(const AName: string): Boolean;
    /// <summary>Makes a directory and the ones above it; True if it is there at the end</summary>
    function EnsureDirectory(const APath: string): Boolean;
  end;

  /// <summary>Where the temporary files of the program go</summary>
  ITempDirectory = interface
    ['{0C6E9B27-4A18-4D53-8F7E-B1A35D60C942}']
    /// <summary>The directory, with the trailing path delimiter; it may not exist yet</summary>
    function Directory: string;
  end;

  /// <summary>The temporary files of the program: they are deleted all together at the end</summary>
  ITempFiles = interface
    ['{E3F17A60-82B5-4C94-9D0A-58B6E24C7F13}']
    /// <summary>
    ///   The full name for a new temporary file called AName (only the file name part counts);
    ///   the directory is made and the file is remembered for DeleteAll
    /// </summary>
    function NewTempFile(const AName: string): string;
    /// <summary>Remembers a file somebody else made, to be deleted by DeleteAll</summary>
    procedure Declare(const AName: string);
    /// <summary>Deletes all the remembered files that are still there and forgets them</summary>
    procedure DeleteAll;
    function GetCount: Integer;
    function GetName(AIndex: Integer): string;
    property Count: Integer read GetCount;
    property Names[AIndex: Integer]: string read GetName;
  end;

  /// <summary>Where the version numbers of the operating system come from</summary>
  IOperatingSystemSource = interface
    ['{B4C8E1F3-6D27-49A0-85B2-3E7D90A1C654}']
    function Read: TOperatingSystemVersion;
  end;

  /// <summary>The operating system, in the words of the engine</summary>
  IOperatingSystemInfo = interface
    ['{19D5A3E7-C4B0-4F82-B6E1-7A2F08D93C45}']
    function Describe: TOperatingSystemDescription;
  end;

  /// <summary>The processor</summary>
  ICpuInfo = interface
    ['{F8A2C6D1-35E9-47B4-90D7-1B6C4E8A23F0}']
    /// <summary>Logical processors (what the engine uses to decide the threads)</summary>
    function ProcessorCount: Integer;
    function HasMmx: Boolean;
    function Has3DNow: Boolean;
  end;

  /// <summary>Facts about an executable file</summary>
  IExecutableInfo = interface
    ['{2E7B94F6-A1D3-4C08-B5E2-D90F63A71C8B}']
    /// <summary>
    ///   SizeOfImage of the PE header (32 and 64 bit files); 0 if the file cannot be read or is
    ///   not an executable
    /// </summary>
    function ImageSize(const AFileName: string): Cardinal;
    /// <summary>The FileVersion of the version resource; empty if there is none</summary>
    function FileVersion(const AFileName: string): string;
  end;

  /// <summary>The drives</summary>
  IDriveInfo = interface
    ['{6C1F8D42-9B75-4E30-A2C9-E5B7D0183F96}']
    /// <summary>True if a drive letter ('C') is a CD-ROM</summary>
    function IsCdRomDrive(ADrive: Char): Boolean;
    /// <summary>
    ///   True if the program with this path runs from a CD-ROM: the drive is the first three
    ///   characters of the path; a path that is too short has none and the current drive counts
    /// </summary>
    function IsProgramOnCdRom(const AProgramPath: string): Boolean;
  end;

  /// <summary>How the program is seen by a screen with a high pixel density</summary>
  IDisplayDpi = interface
    ['{A7D3E905-2C48-4B1F-8E6A-40F9B2C5D173}']
    /// <summary>Tells the system the program scales itself; False if it could not</summary>
    function SetAwareness: Boolean;
    /// <summary>The DPI of a window; 96 if the system cannot say</summary>
    function WindowDpi(AWindow: NativeUInt): Integer;
  end;

  /// <summary>The priority of the thread that calls it</summary>
  IThreadPriority = interface
    ['{D0B4F7A2-8E15-4C69-93A8-6F2E1C57B340}']
    /// <summary>Puts the thread at the highest priority, remembering the one it had; once</summary>
    procedure RaiseToCritical;
    /// <summary>Gives the thread the priority it had before RaiseToCritical</summary>
    procedure Restore;
  end;

  /// <summary>The services about the machine the engine runs on</summary>
  IPlatformServices = interface
    ['{83E6A1B9-47D2-4F05-BC38-9A0D5E7C2F14}']
    function GetOperatingSystem: IOperatingSystemInfo;
    function GetCpu: ICpuInfo;
    function GetExecutable: IExecutableInfo;
    function GetDrives: IDriveInfo;
    function GetDpi: IDisplayDpi;
    function GetPriority: IThreadPriority;
    property OperatingSystem: IOperatingSystemInfo read GetOperatingSystem;
    property Cpu: ICpuInfo read GetCpu;
    property Executable: IExecutableInfo read GetExecutable;
    property Drives: IDriveInfo read GetDrives;
    property Dpi: IDisplayDpi read GetDpi;
    property Priority: IThreadPriority read GetPriority;
  end;

implementation

end.
