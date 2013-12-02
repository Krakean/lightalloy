///////////////////////////////////////////////////////////////////////////////
// Light Alloy                           Copyright(c) 2006-2013, Vortex Team //
//---------------------------------------------------------------------------//
// Filename                                                                  //
// Description.                                                              //
// ---------------                                                           //
// Author : Dmitry «Vortex» Koteroff                                         //
// E-mail : vortex@light-alloy.ru                                            //
// WWW    : http://light-alloy.ru                                            //
//---------------------------------------------------------------------------//
//   Date    Ver   Who  Comment                                              //
// --------  ---   ---  -------                                              //
// 09.11.07  1.0   VtX  Created                                              //
///////////////////////////////////////////////////////////////////////////////

unit stFile;

// -----------------------------------------------------------------------------

interface

uses
  SysUtils;

type

  vtCustomFile = class
  private
    { Private declarations }
    FFileName  : String;
    FFileMode  : Byte;
    FReady     : Boolean;
    FOverwrite : Boolean;
    FErrorCode : Integer;
    procedure GetErrorCode;
    procedure Open; virtual; abstract;
    procedure Close; virtual; abstract;
  public
    { Public declarations }
    constructor Create(const FileName: String; const Mode: Byte = fmOpenRead; const Overwrite: Boolean = False);
    destructor Destroy; override;
    function EOF: Boolean; virtual; abstract;
    property Ready     : Boolean read FReady;
    property ErrorCode : Integer read FErrorCode;
  end;

  vtFile = class(vtCustomFile)
  private
    { Private declarations }
    FFile        : File;
    FTransferred : Integer;
    procedure Open; override;
    procedure Close; override;
  public
    { Public declarations }
    function Read(var Buf; Count: Integer): Boolean;
    function Write(const Buf; Count: Integer): Boolean;
    function Seek(N: LongInt): Boolean;
    function Position: LongInt;
    function Truncate: Boolean;
    function Size: Integer;
    function EOF: Boolean; override;
    property Transferred: Integer read FTransferred;
  end;

// -----------------------------------------------------------------------------

implementation

// -----------------------------------------------------------------------------

{ vtCustomFile }

// -----------------------------------------------------------------------------

constructor vtCustomFile.Create(const FileName: String; const Mode: Byte = fmOpenRead; const Overwrite: Boolean = False);
begin
  FFileName  := FileName;
  FFileMode  := FileMode;
  FReady     := False;
  FOverwrite := Overwrite;
  FErrorCode := 0;
  FileMode   := Mode;
  Open;
end;

// -----------------------------------------------------------------------------

destructor vtCustomFile.Destroy;
begin
  Close;
  FileMode := FFileMode;
  inherited Destroy;
end;

// -----------------------------------------------------------------------------

procedure vtCustomFile.GetErrorCode;
begin
  FErrorCode := IOResult;
end;

// -----------------------------------------------------------------------------

{ vtFile }

// -----------------------------------------------------------------------------

procedure vtFile.Open;
begin
  if (FFileName <> '') and FileExists(FFileName) then
  begin
    AssignFile(FFile, FFileName);
    {$I-}Reset(FFile, 1);{$I+}
    GetErrorCode;
    if FErrorCode = 0 then FReady := True;
  end;
end;

// -----------------------------------------------------------------------------

procedure vtFile.Close;
begin
  if FReady then {$I-}CloseFile(FFile);{$I+}
end;

// -----------------------------------------------------------------------------

function vtFile.Read(var Buf; Count: Integer): Boolean;
begin
  if FReady then
  begin
    {$I-}BlockRead(FFile, Buf, Count, FTransferred);{$I+}
    GetErrorCode;
    Result := (FErrorCode = 0);
  end
  else
    Result := False;
end;

// -----------------------------------------------------------------------------

function vtFile.Write(const Buf; Count: Integer): Boolean;
begin
  if FReady then
  begin
    {$I-}BlockWrite(FFile, Buf, Count, FTransferred);{$I+}
    GetErrorCode;
    Result := (FErrorCode = 0);
  end
  else
    Result := False;
end;

// -----------------------------------------------------------------------------

function vtFile.Seek(N: LongInt): Boolean;
begin
  if FReady then
  begin
    {$I-}System.Seek(FFile, N);{$I+}
    GetErrorCode;
    Result := (FErrorCode = 0);
  end
  else
    Result := False;
end;

// -----------------------------------------------------------------------------

function vtFile.Position: LongInt;
begin
  if FReady then
  begin
    {$I-}Result := FilePos(FFile);{$I+}
    GetErrorCode;
  end
  else
    Result := 0;
end;

// -----------------------------------------------------------------------------

function vtFile.Truncate: Boolean;
begin
  if FReady then
  begin
    {$I-}System.Truncate(FFile);{$I+}
    GetErrorCode;
    Result := (FErrorCode = 0);
  end
  else
    Result := False;
end;

// -----------------------------------------------------------------------------

function vtFile.Size: Integer;
begin
  if FReady then
  begin
    {$I-}Result := FileSize(FFile);{$I+}
    GetErrorCode;
  end
  else
    Result := 0;
end;

// -----------------------------------------------------------------------------

function vtFile.EOF: Boolean;
begin
  if FReady then
  begin
    {$I-}Result := System.EOF(FFile);{$I+}
    GetErrorCode;
  end
  else
    Result := False;
end;

// -----------------------------------------------------------------------------

end.
