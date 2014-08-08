{ *********************************************************************** }
{                                                                         }
{ PM Code Works Cross Plattform Update Thread v2.1                        }
{                                                                         }
{ Copyright (c) 2011-2014 Philipp Meisberger (PM Code Works)              }
{                                                                         }
{ *********************************************************************** }

unit DownloadThread;

interface

uses
  Classes, SysUtils, IdException, IdComponent, IdHTTP;

type
  { Thread events }
  TOnDownloadStartEvent = procedure(Sender: TThread;
    const AFileSize: {$IFDEF MSWINDOWS}Integer{$ELSE}Int64{$ENDIF}) of object;
  TOnDownloadingEvent = procedure(Sender: TThread;
    const ADownloadSize: {$IFDEF MSWINDOWS}Integer{$ELSE}Int64{$ENDIF}) of object;
  TOnDownloadFinishEvent = procedure(Sender: TThread) of object;
  TOnDownloadCancelEvent = procedure(Sender: TThread) of object;
  TOnDownloadErrorEvent = procedure(Sender: TThread; AResponseCode: Integer) of object;

  { TDownloadThread }
  TDownloadThread = class(TThread)
  private
    FHttp: TIdHTTP;
    FOnStart: TOnDownloadStartEvent;
    FOnDownloading: TOnDownloadingEvent;
    FOnFinish: TOnDownloadFinishEvent;
    FOnError: TOnDownloadErrorEvent;
    FOnCancel: TOnDownloadCancelEvent;
    FFileSize, FDownloadSize: {$IFDEF MSWINDOWS}Integer{$ELSE}Int64{$ENDIF};
    FResponseCode: Integer;
    FFileName, FUrl: string;
    { Synchronized events }
    procedure DoNotifyOnCancel;
    procedure DoNotifyOnDownloading;
    procedure DoNotifyOnError;
    procedure DoNotifyOnFinish;
    procedure DoNotifyOnStart;
  protected
    procedure Execute; override;
  public
    constructor Create(const AUrl, AFileName: string; AAllowOverwrite: Boolean = False;
      ACreateSuspended: Boolean = True);
    destructor Destroy; override;
    procedure Downloading(Sender: TObject; AWorkMode: TWorkMode;
      const ADownloadSize: {$IFDEF MSWINDOWS}Integer{$ELSE}Int64{$ENDIF});
    procedure DownloadStart(Sender: TObject; AWorkMode: TWorkMode;
      const AFileSize: {$IFDEF MSWINDOWS}Integer{$ELSE}Int64{$ENDIF});
    function GetUniqueFileName(const AFileName: string): string;
    procedure OnUserCancel(Sender: TObject);
    { Externalized events }
    property OnCancel: TOnDownloadCancelEvent read FOnCancel write FOnCancel;
    property OnDownloading: TOnDownloadingEvent read FOnDownloading write FOnDownloading;
    property OnError: TOnDownloadErrorEvent read FOnError write FOnError;
    property OnFinish: TOnDownloadFinishEvent read FOnFinish write FOnFinish;
    property OnStart: TOnDownloadStartEvent read FOnStart write FOnStart;
  end;

implementation

{ TDownloadThread }

{ public TDownloadThread.Create

  Constructor for creating a TDownloadThread instance. }

constructor TDownloadThread.Create(const AUrl, AFileName: string;
  AAllowOverwrite: Boolean = False; ACreateSuspended: Boolean = True);
begin
  inherited Create(ACreateSuspended);
  FreeOnTerminate := True;

  // Rename file if already exists?
  if AAllowOverwrite then
     FFileName := AFileName
  else
     FFileName := GetUniqueFileName(AFileName);

  FUrl := AUrl;
  FResponseCode := 0;
  
  // Init IdHTTP component dynamically
  FHttp := TIdHTTP.Create(nil);
  
  // Link HTTP events
  with FHttp do
  begin
  {$IFDEF MSWINDOWS}
    OnWorkBegin := DownloadStart;
    OnWork := Downloading;
  {$ELSE}
    OnWorkBegin := @DownloadStart;
    OnWork := @Downloading;
  {$ENDIF}
  end;  //of begin
end;

{ public TDownloadThread.Destroy

  Destructor for destroying a TDownloadThread instance. }

destructor TDownloadThread.Destroy;
begin
  FHttp.Free;
  inherited Destroy;
end;

{ protected TDownloadThread.Execute

  Thread main method that downloads a file from an HTTP source. }
  
procedure TDownloadThread.Execute;
var
  FileStream: TFileStream;

begin
  try
    // Init file stream
    FileStream := TFileStream.Create(FFileName, fmCreate);

    // Try to download file
    try
      FHttp.Get(FUrl, FileStream);

    finally
      FileStream.Free;
      FResponseCode := FHttp.ResponseCode;
    end;  //of try

    // Check if download was successful?
    if (FResponseCode = 200) then
    {$IFDEF MSWINDOWS}
      Synchronize(DoNotifyOnFinish);
    {$ELSE}
      Synchronize(@DoNotifyOnFinish);
    {$ENDIF}       

  except
    on E: EAbort do
    begin
      DeleteFile(FFileName);

    {$IFDEF MSWINDOWS}
      Synchronize(DoNotifyOnCancel);
    {$ELSE}
      Synchronize(@DoNotifyOnCancel);
    {$ENDIF}
    end;  //of begin

    on E: Exception do
    begin
      DeleteFile(FFileName);

    {$IFDEF MSWINDOWS}
      Synchronize(DoNotifyOnError);
    {$ELSE}
      Synchronize(@DoNotifyOnError);
    {$ENDIF}
    end;  //of begin
  end;  //of try
end;

{ public TDownloadThread.DownloadStart

  Event that is called by TIdHttp when download starts. }

procedure TDownloadThread.DownloadStart(Sender: TObject; AWorkMode: TWorkMode;
  const AFileSize: {$IFDEF MSWINDOWS}Integer{$ELSE}Int64{$ENDIF});
begin
  // Convert Byte into Kilobyte (KB = Byte/1024)
  FFileSize := AFileSize div 1024;

  {$IFDEF MSWINDOWS}
    Synchronize(DoNotifyOnStart);
  {$ELSE}
    Synchronize(@DoNotifyOnStart);
  {$ENDIF}
end;

{ public TDownloadThread.Downloading

  Event that is called by TIdHttp while download is in progress. }

procedure TDownloadThread.Downloading(Sender: TObject; AWorkMode: TWorkMode;
  const ADownloadSize: {$IFDEF MSWINDOWS}Integer{$ELSE}Int64{$ENDIF});
begin
  if (not Self.Terminated) then
  begin
    // Convert Byte into Kilobyte (KB = Byte/1024)
    FDownloadSize := ADownloadSize div 1024;

  {$IFDEF MSWINDOWS}
    Synchronize(DoNotifyOnDownloading);
  {$ELSE}
    Synchronize(@DoNotifyOnDownloading);
  {$ENDIF}
  end  //of begin
  else
    Abort;
end;

{ public TDownloadThread.GetUniqueFileName

  Returns an unique file name to be sure downloading to an non-existing file. }

function TDownloadThread.GetUniqueFileName(const AFileName: string): string;
var
  i: Word;
  RawName, FilePath, NewFileName, Ext: string;

begin
  NewFileName := AFileName;
  Ext := ExtractFileExt(AFileName);
  FilePath := ExtractFilePath(NewFileName);
  RawName := ExtractFileName(NewFileName);
  RawName := Copy(RawName, 0, Length(RawName) - 4);
  i := 1;

  while FileExists(NewFileName) do
  begin
    NewFileName := FilePath + RawName +' ('+ IntToStr(i) +')'+ Ext;
    Inc(i);
  end;  //of while

  result := NewFileName;
end;

{ public TDownloadThread.OnUserCancel

  Cancels downloading file if user clicks "cancel". }

procedure TDownloadThread.OnUserCancel(Sender: TObject);
begin
  Terminate;
end;

{ private TDownloadThread.DoNotifyOnCancel

  Synchronizable event method that is called when download has been canceled
  by user. }

procedure TDownloadThread.DoNotifyOnCancel;
begin
  if Assigned(OnCancel) then
    OnCancel(Self);
end;

{ private TDownloadThread.DoNotifyOnDownloading

  Synchronizable event method that is called when download is in progress. }
  
procedure TDownloadThread.DoNotifyOnDownloading;
begin
  if Assigned(OnDownloading) then
    OnDownloading(Self, FDownloadSize);
end;

{ private TDownloadThread.DoNotifyOnError

  Synchronizable event method that is called when an error occurs while download
  is in progress. }
  
procedure TDownloadThread.DoNotifyOnError;                  
begin
  if Assigned(OnError) then
    OnError(Self, FResponseCode);
end;

{ private TDownloadThread.DoNotifyOnFinish

  Synchronizable event method that is called when download is finished. }
  
procedure TDownloadThread.DoNotifyOnFinish;                
begin
  if Assigned(OnFinish) then
    OnFinish(Self);
end;


{ private TDownloadThread.DoNotifyOnStart

  Synchronizable event method that is called when download starts. }
  
procedure TDownloadThread.DoNotifyOnStart;
begin
  if Assigned(OnStart) then
    OnStart(Self, FFileSize);
end;

end.