(*
  UWrpHttp_Client
  by Warapetch  Ruangpornvisuthi
  made in  Thailand

  Create  : 16/06/2563
  version : 0.0.0.1
  Delphi  : 10.3.3
*)

unit UWrpHttp_Client;

 interface

 uses System.SysUtils {DecodeDate},
      System.Classes {TComponent},
      System.JSON {TJsonObject} ,

      // {IdHTTP and ...}
      IdIOHandler, IdIOHandlerSocket,
      IdIOHandlerStack, IdSSL, IdSSLOpenSSL,
      IdBaseComponent, IdComponent,
      IdTCPConnection, IdTCPClient,
      IdHTTP, IdIntercept,
      IdInterceptThrottler ,
      IdIOHandlerStream ,
      // IdMultipartFormData {Multipart/Form-Data} ,
      IdGlobal,
      IdGlobalProtocols {FileSize} ,
      IdCookieManager {Cookie},
      IdURI     {IdURI} ,
      DateUtils {TTimeZone} ,
      Web.HTTPApp ,HTTPUtil,
      IdHeaderList

      {$IFDEF MSWINDOWS}
      ,Vcl.Dialogs {ShowMessage}
      ,Vcl.ExtCtrls {TImage}
      ,Vcl.Imaging.jpeg
      ,ShellAPI {ShellExecute}
      {$ENDIF}

      {$IFDEF ANDROID}
      ,FMX.Types, FMX.Controls, FMX.Objects,FMX.Dialogs
      {$ENDIF}
      ;


 Type
    TWrpProcCallBack  = reference to procedure (ResponseText : String);
    TWrpResponseEvent = procedure (Response : IdHTTP.TIdHTTPResponse;ResponseText,ReponseRawHeaderText : String) of Object;
    TWrpSendEvent     = procedure (Sender : TIdHTTP) of Object;

    TWrpHttp_Client = Class(TIdHTTP)

    private
      FHttp_Host: String;
      FHttp_URL: String;
      FHttp_UserAgent: String;

      FOnHostResponse   : TWrpResponseEvent;
      FOnBeforeSendToHost : TWrpSendEvent;
      FOnInitializeSelf : TNotifyEvent;

      function GetAbout: String;
      procedure SetHttp_Host(const Value: String);
      procedure SetHttp_URL(const Value: String);
      procedure SetHttp_UserAgent(const Value: String);
      procedure Initilize_HttpClient;
      procedure DoOnHeadersAvailable(Sender: TObject; AHeaders: TIdHeaderList; var VContinue: Boolean);

    protected
       FLAST_ERROR  : String;
       FIdIntercept : TIdConnectionIntercept;
       FIdOpenSSL   : TIdSSLIOHandlerSocketOpenSSL;
       FIdCookie    : TIdCookieManager;

       FJSONObjResponse : TJSONObject;

       procedure DoOnHostResponse(Response : IdHTTP.TIdHTTPResponse;ResponseText,ReponseRawHeaderText : String);virtual;
       function DoSendToHost(URL : String;Params : TStream;ProcCallBack : TWrpProcCallBack = NIL) : IdHTTP.TIdHTTPResponse;Overload;virtual;
       function DoSendToHost(URL : String;Params : TStringlist;ProcCallBack : TWrpProcCallBack = NIL): IdHTTP.TIdHTTPResponse;Overload;virtual;
    public
       Constructor Create(AOwner : TComponent); virtual;
       Destructor Destroy; Override;

       function LastError : String;
       function SendToHost2(URL: String;ProcCallBack : TWrpProcCallBack = NIL): IdHTTP.TIdHTTPResponse;
       function SendToHost(URL: String;ProcCallBack : TWrpProcCallBack = NIL): IdHTTP.TIdHTTPResponse;Overload;
       function SendToHost(URL : String;Params : TStringlist;ProcCallBack : TWrpProcCallBack = NIL) : IdHTTP.TIdHTTPResponse; Overload;
       function SendToHost(URL : String;Params : TStream;ProcCallBack : TWrpProcCallBack = NIL) : IdHTTP.TIdHTTPResponse; Overload;
       //function SendFormToHttp(URL: String;Params: TIdMultipartFormDataStream): Boolean;

    published
       property About      : String read GetAbout;
       property Http_Host   : String read FHttp_Host write SetHttp_Host;
       property Http_URL    : String read FHttp_URL  write SetHttp_URL;
       property Http_UserAgent  : String read FHttp_UserAgent write SetHttp_UserAgent;

       // Event
       property OnHttpResponse    : TWrpResponseEvent    read FOnHostResponse       write FOnHostResponse;
       property OnBeforeSendToHost  : TWrpSendEvent        read FOnBeforeSendToHost     write FOnBeforeSendToHost;
      // property OnBeforeSendToHostForm : TWrpSendEvent     read FOnBeforeSendToHostForm write FOnBeforeSendToHostForm;
       property OnInitializeSelf  : TNotifyEvent         read FOnInitializeSelf     write FOnInitializeSelf;
 end;

const
   FAbout = 'API Common 0.0.1@ 15/06/2563 '+#13#10+
            'วรเพชร  เรืองพรวิสุทธิ์'+#13#10+
            'Supported : Win32 , Android '+#13#10+
            'last update : 15/06/2563 18:00';


procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Warapetch', [TWrpHttp_Client]);
end;

constructor TWrpHttp_Client.Create(AOwner: TComponent);
begin
  inherited;

  FHttp_Host := '127.0.0.1';
  FHttp_URL  := 'http://127.0.0.1/API';
  FHttp_UserAgent := 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/57.0.2987.133 Safari/537.36';

  Initilize_HttpClient;

  OnHeadersAvailable := DoOnHeadersAvailable;
end;

destructor TWrpHttp_Client.Destroy;
begin
  if FJSONObjResponse <> NIL then
     FJSONObjResponse.Free;

  FreeAndNil(FIdCookie);
  FreeAndNil(FIdIntercept);
  FreeAndNil(FIdOpenSSL);

  inherited;
end;

procedure TWrpHttp_Client.Initilize_HttpClient;
begin
    // Default value
    Request.ContentType := 'application/json';
    Request.Method      := 'post';
    Request.Host        := FHttp_Host;
    // User Agent :: Need Up To Date
    Request.UserAgent   := FHttp_UserAgent;

    // Intercept
    FIdIntercept := TIdConnectionIntercept.Create(NIL);

    // IOHandler
    FIdOpenSSL   := TIdSSLIOHandlerSocketOpenSSL.Create(NIL);
    FIdOpenSSL.Intercept := FIdIntercept;

    Intercept := FIdIntercept;
    IOHandler := FIdOpenSSL;
    //IOHandler.DefStringEncoding := IndyTextEncoding_UTF8;
    //IdGlobal.GIdDefaultTextEncoding := encUTF8;
    //IndyTextEncoding_OSDefault := IndyTextEncoding_UTF8;

    // Cookie
    FIdCookie := TIdCookieManager.Create(nil);
    CookieManager := FIdCookie;
    AllowCookies  := true;

    FIdOpenSSL.SSLOptions.Method := sslvSSLv23;
end;

function TWrpHttp_Client.LastError: String;
begin
  Result := FLAST_ERROR;
end;

function TWrpHttp_Client.SendToHost(URL : String;ProcCallBack : TWrpProcCallBack = NIL) : IdHTTP.TIdHTTPResponse;
begin
  Result := DoSendToHost(URL,TStringlist(NIL),ProcCallBack);
end;

function TWrpHttp_Client.SendToHost(URL : String;Params : TStringlist;ProcCallBack : TWrpProcCallBack = NIL) : IdHTTP.TIdHTTPResponse;
begin
  Result := DoSendToHost(URL,Params,ProcCallBack);
end;

function TWrpHttp_Client.SendToHost(URL : String;Params : TStream;ProcCallBack : TWrpProcCallBack = NIL) : IdHTTP.TIdHTTPResponse;
begin
  Result := DoSendToHost(URL,Params,ProcCallBack);
end;

function TWrpHttp_Client.SendToHost2(URL: String;
  ProcCallBack: TWrpProcCallBack = NIL): IdHTTP.TIdHTTPResponse;
begin
  Result := DoSendToHost(URL,TStringlist(NIL),ProcCallBack);
end;

function TWrpHttp_Client.DoSendToHost(URL: String; Params: TStringlist;ProcCallBack : TWrpProcCallBack = NIL): IdHTTP.TIdHTTPResponse;
var sResponseText : UTF8String;

begin
   Result := NIL;
   FLAST_ERROR := '';

   if URL = '' then
      URL := FHttp_URL;

   // Event
   if Assigned(FOnBeforeSendToHost) then
      FOnBeforeSendToHost(Self);

   Try
       Try
           if LowerCase(Request.Method) = 'post' then
              // POST
              //----------------------------------------------------------------
              sResponseText := Post( TIdURI.URLEncode(URL) , Params)
              //----------------------------------------------------------------
           else
           begin
              // Not Need
              // Request.Charset := 'UTF-8'; // Default
              // Request.ContentEncoding     := 'UTF-8';
              // IOHandler.DefStringEncoding := IndyTextEncoding_UTF8;
              // GET
              //----------------------------------------------------------------
              sResponseText :=  Get( TIdURI.URLEncode(URL) , []) ;

              if Assigned(ProcCallBack) then
                 ProcCallBack(sResponseText);
              //----------------------------------------------------------------
           end;

       Except
          On E:Exception do
             begin
                sResponseText := ''+E.Message;
                FLAST_ERROR   := sResponseText;
             end;
       End;

      // Result
      //-------------------------------------------------------
      Result := Response;
      //-------------------------------------------------------

      DoOnHostResponse(Response,sResponseText,Response.RawHeaders.Text);

   Except
   End;
end;

function TWrpHttp_Client.DoSendToHost(URL: String; Params: TStream;ProcCallBack : TWrpProcCallBack = NIL): IdHTTP.TIdHTTPResponse;
var sResponseText : String;
begin
   Result := NIL;
   FLAST_ERROR := '';

   if URL = '' then
      URL := FHttp_URL;

   // Event
   if Assigned(FOnBeforeSendToHost) then
      FOnBeforeSendToHost(Self);

   Try
       Try
           if LowerCase(Request.Method) = 'post' then
              // POST
              //----------------------------------------------------------------
              sResponseText := Post( TIdURI.URLEncode(URL) , Params)
              //----------------------------------------------------------------
           else
           begin
              // GET
              //----------------------------------------------------------------
              sResponseText := Get( TIdURI.URLEncode(URL) , []);

              if Assigned(ProcCallBack) then
                 ProcCallBack(sResponseText);

              //----------------------------------------------------------------
           end;

       Except
          On E:Exception do
             begin
                sResponseText := ''+E.Message;
                FLAST_ERROR   := sResponseText;
             end;
       End;

      // Result
      //-------------------------------------------------------
      Result := Response;
      //-------------------------------------------------------

      DoOnHostResponse(Response,sResponseText,Response.RawHeaders.Text);

   Except
   End;
end;
                                                                       // IdHeaderList
procedure TWrpHttp_Client.DoOnHeadersAvailable(Sender: TObject; AHeaders: TIdHeaderList; var VContinue: Boolean);
var Response: TIdHTTPResponse;
begin

    Response := TIdHTTP(Sender).Response;

    if IsHeaderMediaType(Response.ContentType, 'application/json') and (Response.Charset = '') then
       Response.Charset := 'UTF-8';

    VContinue := True;
end;

{function TWrpHttp_Client.SendFormToHttp(URL : String;Params : TIdMultipartFormDataStream) : Boolean;
var sResponseText , sHeaderText : String;
begin
   Result := False;

   if URL = '' then
      URL := FHttp_URL;

   //Event
   if Assigned(FOnBeforeSendToHostForm) then
      FOnBeforeSendToHostForm(Self);

   Try
       Try
           if LowerCase(Request.Method) = 'post' then
              // POST
              //----------------------------------------------------------------
              sResponseText := Post( TIdURI.URLEncode(URL) , Params)
              //----------------------------------------------------------------

       Except
          On E:Exception do
             begin
                sResponseText := ''+E.Message;
                FLAST_ERROR   := sResponseText;
             end;
       End;

      // Result
      //-------------------------------------------------------
      Result := (ResponseCode = 200);
      //-------------------------------------------------------

      DoOnHostResponse(Response,sResponseText,Response.RawHeaders.Text);

   Except
   End;
end; }

procedure TWrpHttp_Client.DoOnHostResponse(Response : IdHTTP.TIdHTTPResponse;
    ResponseText,ReponseRawHeaderText : String);
begin
   if Assigned(FOnHostResponse) then
      FOnHostResponse(Response,ResponseText,ReponseRawHeaderText);
end;

procedure TWrpHttp_Client.SetHttp_Host(const Value: String);
begin
  FHttp_Host := Value;
end;

procedure TWrpHttp_Client.SetHttp_URL(const Value: String);
begin
  FHttp_URL := Value;
end;

procedure TWrpHttp_Client.SetHttp_UserAgent(const Value: String);
begin
  FHttp_UserAgent := Value;
end;

function TWrpHttp_Client.GetAbout: String;
begin
   Result := FAbout;
end;

end.
