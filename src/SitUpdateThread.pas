{ *********************************************************************** }
{                                                                         }
{ Sit Update Thread v1.3                                                  }
{                                                                         }
{ Copyright (c) 2011-2012 P.Meisberger (PM Code Works)                    }
{                                                                         }
{ *********************************************************************** }

unit SitUpdateThread;

interface

uses
  Classes, IdException, IdBaseComponent, IdComponent, IdTCPConnection,
  IdTCPClient, IdHTTP;

type
  TOnWorkBeginEvent = procedure(Sender: TThread; const AWorkCountMax: Integer) of object;
  TOnWorkEvent = procedure(Sender: TThread; const AWorkCount: Integer) of object;
  TOnFinish = procedure(Sender: TObject; AResponseCode: Integer) of object;
  TOnError = procedure(Sender: TThread) of object;

  TDownloadThread = class(TThread)
  private
    HTTP: TIdHTTP;
    FOnWorkBegin: TOnWorkBeginEvent;
    FOnWork: TOnWorkEvent;
    FOnFinish: TOnFinish;
    FOnError: TOnError;
    FWorkCountMax, FWorkCount, FResponseCode: integer;
    FFileName, FUrl: string;
    FStream: TFileStream;
    {Sync Events: }
    procedure DoNotifyOnWorkBegin;
    procedure DoNotifyOnWork;
    procedure DoNotifyOnFinish;
    procedure DoNotifyOnError;
  protected
    procedure Execute; override;
  public
    constructor Create;
    destructor Destroy; override;
    procedure InternalOnWorkBegin(Sender: TObject; AWorkMode: TWorkMode;
      const AWorkCountMax: Integer);
    procedure InternalOnWork(Sender: TObject; AWorkMode: TWorkMode;
      const AWorkCount: Integer);
    procedure OnCanceling(Sender: TObject);
    procedure OnContinue(Sender: TObject);
    procedure OnExit(Sender: TObject);
    { external Events:}
    property OnWorkBegin: TOnWorkBeginEvent read FOnWorkBegin write FOnWorkBegin;
    property OnWork: TOnWorkEvent read FOnWork write FOnWork;
    property OnFinish: TOnFinish read FOnFinish write FOnFinish;
    property OnError: TOnError read FOnError write FOnError;
    property FileName: string read FFileName write FFileName;
    property Url: string read FUrl write FUrl;
  end;

implementation

uses SitUpdate;


constructor TDownloadThread.Create;
begin
  inherited Create(true);                 //Super Konstruktor Aufruf
  FreeOnTerminate := true;                //Thread beendet sich selbst
  Form3.OnCancel := OnCanceling;          //Abbruch-Event verkn�pfen
  Form3.OnContinue := OnContinue;         //Weiter-Event verkn�pfen
  Form3.OnExit := OnExit;                 //Beenden-Event verkn�pfen
  HTTP := TIdHTTP.Create(nil);            //HTTP-Komponente dynamisch erstellen

  with HTTP do
    begin                                 //HTTP-Events umleiten
    OnWorkBegin := InternalOnWorkBegin;
    OnWork := InternalOnWork;
    end;  //of begin
end;


destructor TDownloadThread.Destroy;                                  //freigeben
begin
  HTTP.Free;
  inherited Destroy;
end;


procedure TDownloadThread.Execute;                            //Datei downloaden
begin
  try
    FStream := TFileStream.Create(FFileName, fmCreate);    //Dateiname

    if not Terminated then
       try
         HTTP.Get(FUrl, FStream);                          //Downloaden und speichern
         FResponseCode := HTTP.ResponseCode;

       except
         FStream.Free;
         Synchronize(DoNotifyOnError);                     //Fehlerfall-Event
         Exit;
       end;  //of except

  except
    Exit;
  end;  //of finally

  FStream.Free;
  Synchronize(DoNotifyOnFinish);
end;

{ Thread Events }
procedure TDownloadThread.InternalOnWorkBegin(Sender: TObject; AWorkMode: TWorkMode;
  const AWorkCountMax: Integer);
begin
  FWorkCountMax := AWorkCountMax;
  Synchronize(DoNotifyOnWorkBegin);
end;


procedure TDownloadThread.InternalOnWork(Sender: TObject; AWorkMode: TWorkMode;
  const AWorkCount: Integer);
begin
  FWorkCount := AWorkCount;
  Synchronize(DoNotifyOnWork);
end;

{ Threadsteuerung }
procedure TDownloadThread.OnCanceling(Sender: TObject);              //pausieren
begin
  Suspended := true;
end;


procedure TDownloadThread.OnContinue(Sender: TObject);              //fortsetzen
begin
  Suspended := false;
end;


procedure TDownloadThread.OnExit(Sender: TObject);                     //beenden
begin
  FStream.Free;
  Terminate;
end;

{ Sync Events }
procedure TDownloadThread.DoNotifyOnWorkBegin;          //Sync OnWorkBegin-Event
begin
  if Assigned(OnWorkBegin) then
     OnWorkBegin(Self, FWorkCountMax);
end;


procedure TDownloadThread.DoNotifyOnWork;                    //Sync OnWork-Event
begin
  if Assigned(OnWork) then
     OnWork(Self, FWorkCount);
end;


procedure TDownloadThread.DoNotifyOnFinish;                //Sync OnFinish-Event
begin
  if Assigned(OnFinish) then
     OnFinish(Self, FResponseCode);
end;


procedure TDownloadThread.DoNotifyOnError;                  //Sync OnError-Event
begin
  if Assigned(OnError) then
     OnError(Self);
end;

end.
