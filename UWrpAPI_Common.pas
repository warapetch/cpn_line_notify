(*
  UWrpAPI
  by Warapetch  Ruangpornvisuthi
  made in  Thailand

  Create  : 16/06/2563
  version : 0.0.0.1
  Delphi  : 10.3.3
*)

unit UWrpAPI_Common;

 interface

 uses System.SysUtils {DecodeDate},
      System.Classes {TComponent},
      System.JSON {TJsonObject} ,
      System.IOUtils,

      // {IdHTTP and ...}
      IdIOHandler, IdIOHandlerSocket,
      IdIOHandlerStack, IdSSL, IdSSLOpenSSL,
      IdBaseComponent, IdComponent,
      IdTCPConnection, IdTCPClient,
      IdHTTP, IdIntercept,
      IdInterceptThrottler ,
      IdIOHandlerStream ,
      IdHeaderList ,
      IdMultipartFormData {Multipart/Form-Data} ,

    {$IF Defined(IOS) and Defined(CPUARM)}
     IdSSLOpenSSLHeaders_Static,
    {$ELSE}
     IdSSLOpenSSLHeaders,
    {$ENDIF}

      IdGlobalProtocols {FileSize} ,
      IdCookieManager {Cookie},
      IdURI     {IdURI} ,
      DateUtils {TTimeZone} ,
      Web.HTTPApp ,HTTPUtil
      ,System.Threading
      ,System.Net.HttpClient

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
    TWrpProcCallBack    = reference to procedure (Response : IdHTTP.TIdHTTPResponse;ResponseText,ReponseRawHeaderText : String);
    TWrpResponseEvent   = procedure (Response : IdHTTP.TIdHTTPResponse;ResponseText,ReponseRawHeaderText : String) of Object;
    TWrpResponseEXEvent = procedure (Response : IdHTTP.TIdHTTPResponse;AHeaders: TIdHeaderList) of Object;
    TWrpSendEvent       = procedure (Sender : TIdHTTP) of Object;

    TWrpAPI = Class(TIdHTTP)

    private
      FAPI_Host: String;
      FAPI_UserAgent: String;
      FOnHostResponse   : TWrpResponseEvent;
      FOnBeforeSendAPI : TWrpSendEvent;
      FOnInitializeAPI : TNotifyEvent;
      FOnTrackHostResponse: TWrpResponseEXEvent;
      FModeRedirect: Boolean;

      function  GetAbout: String;
      procedure SetAPI_Host(const Value: String);
      procedure SetAPI_UserAgent(const Value: String);
      procedure Initilize_HttpClient;
      procedure DoOnHeadersAvailable(Sender: TObject; AHeaders: TIdHeaderList; var VContinue: Boolean);
      procedure SetModeRedirect(const Value: Boolean);

    protected
       FLAST_ERROR  : String;
       FIdIntercept : TIdConnectionIntercept;
       FIdOpenSSL   : TIdSSLIOHandlerSocketOpenSSL;
       FIdCookie    : TIdCookieManager;
       FObjDataResponse : TJSONObject;

       function DoOnSendToHost(EndpointURL : String;Params : TStream    ;
                        ProcAfterGet_CallBack : TWrpProcCallBack = NIL): IdHTTP.TIdHTTPResponse;Overload;virtual;
       function DoOnSendToHost(EndpointURL : String;Params : TStringlist;
                        ProcAfterGet_CallBack : TWrpProcCallBack = NIL): IdHTTP.TIdHTTPResponse;Overload;virtual;

    public
       Constructor Create(AOwner : TComponent); virtual;
       Destructor Destroy; Override;
       procedure Loaded; Override;

       function LastError : String;
       function GetHost_ResponseInfo(URL: String) : TIdHTTPResponse;

       function SendToHost(EndpointURL: String):  IdHTTP.TIdHTTPResponse;Overload;
       function SendToHost(EndpointURL : String;Params : TStringlist) :  IdHTTP.TIdHTTPResponse; Overload;
       function SendToHost(EndpointURL : String;Params : TStream) :  IdHTTP.TIdHTTPResponse; Overload;


       function SendToHostAndCallBack(EndpointURL: String;
                    ProcAfterGet_CallBack : TWrpProcCallBack = NIL): IdHTTP.TIdHTTPResponse;Overload;
       function SendToHostAndCallBack(EndpointURL: String;Params : TStringlist;ProcAfterGet_CallBack:
                    TWrpProcCallBack): IdHTTP.TIdHTTPResponse; Overload;
       function SendToHostAndCallBack(EndpointURL: String;
                    Params : TStream;ProcAfterGet_CallBack: TWrpProcCallBack): IdHTTP.TIdHTTPResponse;Overload;

       function SendImageFilesToHost(ContentType ,EndpointURL : String;ImageFileNames : TStringList) : Boolean;

       procedure DownloadStream(URL : String;var Data : TMemoryStream);
       procedure DownloadAndSaveToFile(URL, FileName: String);
       procedure DownloadVideoParallel(URL : String;FileName : String);

       procedure DoOnHostResponse(Response : IdHTTP.TIdHTTPResponse;ResponseText,ReponseRawHeaderText : String);virtual;
       procedure DoOnTrackHostResponse(Response : IdHTTP.TIdHTTPResponse;AHeaders: TIdHeaderList);virtual;

    published
       property About          : String read GetAbout;
       property API_Host       : String read FAPI_Host      write SetAPI_Host;
       property API_UserAgent  : String read FAPI_UserAgent write SetAPI_UserAgent;
       property ModeRedirect   : Boolean read FModeRedirect write SetModeRedirect default false;

       // Event
       property OnHostResponse   : TWrpResponseEvent    read FOnHostResponse      write FOnHostResponse;
       property OnTrackHostResponse : TWrpResponseEXEvent  read FOnTrackHostResponse    write FOnTrackHostResponse;
       property OnBeforeSendAPI  : TWrpSendEvent        read FOnBeforeSendAPI     write FOnBeforeSendAPI;
       property OnInitializeAPI  : TNotifyEvent         read FOnInitializeAPI     write FOnInitializeAPI;
 end;

const
   FAbout = 'API Common 0.0.2@ 15/09/2563 '+#13#10+
            'วรเพชร  เรืองพรวิสุทธิ์'+#13#10+
            'Supported : Win32 , Android '+#13#10+
            'last update : 15/09/2563 18:00';


procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Warapetch', [TWrpAPI]);
end;

constructor TWrpAPI.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  FAPI_Host      := '127.0.0.1';
  FAPI_UserAgent := 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/57.0.2987.133 Safari/537.36';
  FModeRedirect  := False;

  Initilize_HttpClient;

  OnHeadersAvailable := DoOnHeadersAvailable;
end;
                                                                       // IdHeaderList
procedure TWrpAPI.DoOnHeadersAvailable(Sender: TObject; AHeaders : TIdHeaderList; var VContinue: Boolean);
var Response: TIdHTTPResponse;
begin
    // Get
    Response := TIdHTTP(Sender).Response;

    // Track
    DoOnTrackHostResponse(TIdHTTP(Sender).Response,AHeaders);

    if IsHeaderMediaType(Response.ContentType, 'application/json') and (Response.Charset = '') then
       begin
          Response.Charset := 'UTF-8';
          // Response.ContentEncoding := 'UTF-8';
       end;

    VContinue := True;
end;

destructor TWrpAPI.Destroy;
begin
  if FObjDataResponse <> NIL then
     FObjDataResponse.Free;

  FreeAndNil(FIdCookie);
  FreeAndNil(FIdIntercept);
  FreeAndNil(FIdOpenSSL);

  inherited;
end;

procedure TWrpAPI.Initilize_HttpClient;
begin
    FModeRedirect  := False;

    // Default value
    Request.ContentType := 'application/json';
    Request.Method      := 'get';
    Request.Host        := FAPI_Host;

    // User Agent :: Need Up To Date
    // Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/57.0.2987.133 Safari/537.36
    Request.UserAgent   := FAPI_UserAgent;

//    if FStandAlone then
       begin

            // Intercept
            FIdIntercept := TIdConnectionIntercept.Create(Self);

            // IOHandler
            FIdOpenSSL   := TIdSSLIOHandlerSocketOpenSSL.Create(Self);
            FIdOpenSSL.Intercept := FIdIntercept;

            Intercept := FIdIntercept;
            IOHandler := FIdOpenSSL;

            // Cookie
            FIdCookie := TIdCookieManager.Create(Self);
            CookieManager := FIdCookie;
            AllowCookies  := true;

        // OpenSSL //-------------------------------------------------------------------------
            FIdOpenSSL.SSLOptions.Method := sslvSSLv23;

            {$IFDEF ANDROID}
                var Path := IncludeTrailingPathDelimiter(System.IOUtils.TPath.GetDocumentsPath());
                {$IFDEF CPU64BITS}
                    Path := Path+'libssl64';
                {$ELSE}
                    Path := Path+'libssl32';
                {$ENDIF}
                IdOpenSSLSetLibPath(Path);
            {$ENDIF}

            {$IF Defined(IOS) and not Defined(CPUARM)}
            // IdOpenSSLSetLibPath('/usr/lib/');
            {$ENDIF}
        // OpenSSL //-------------------------------------------------------------------------

    end;
end;

function TWrpAPI.LastError: String;
begin
  Result := FLAST_ERROR;
end;

procedure TWrpAPI.Loaded;
begin
  inherited;

  FAPI_Host := '127.0.0.1';
  FAPI_UserAgent := 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/57.0.2987.133 Safari/537.36';

  Initilize_HttpClient;
  OnHeadersAvailable := DoOnHeadersAvailable;


end;

function TWrpAPI.SendToHost(EndpointURL : String) :  IdHTTP.TIdHTTPResponse;
begin
  Result := DoOnSendToHost(EndpointURL,TStringlist(NIL));
end;

function TWrpAPI.SendToHost(EndpointURL : String;Params : TStringlist) :  IdHTTP.TIdHTTPResponse;
begin
  Result := DoOnSendToHost(EndpointURL,Params);
end;

function TWrpAPI.SendToHostAndCallBack(EndpointURL: String; ProcAfterGet_CallBack: TWrpProcCallBack): IdHTTP.TIdHTTPResponse;
begin
  Result := DoOnSendToHost(EndpointURL,TStringlist(NIL),ProcAfterGet_CallBack);
end;

function TWrpAPI.SendToHostAndCallBack(EndpointURL: String;Params : TStream;ProcAfterGet_CallBack: TWrpProcCallBack): IdHTTP.TIdHTTPResponse;
begin
  Result := DoOnSendToHost(EndpointURL,Params,ProcAfterGet_CallBack);
end;

function TWrpAPI.SendToHostAndCallBack(EndpointURL: String;Params : TStringlist;ProcAfterGet_CallBack: TWrpProcCallBack): IdHTTP.TIdHTTPResponse;
begin
  Result := DoOnSendToHost(EndpointURL,Params,ProcAfterGet_CallBack);
end;

function TWrpAPI.SendToHost(EndpointURL : String;Params : TStream) :  IdHTTP.TIdHTTPResponse;
begin
  Result := DoOnSendToHost(EndpointURL,Params);
end;

function TWrpAPI.SendImageFilesToHost(ContentType , EndpointURL : String;ImageFileNames : TStringList) : Boolean;
var
    TmpParams  : TIdMultipartFormDataStream;
    sResponse ,sHeaderText : String;
  I: Integer;

begin
   Result := False;

   for I := 0 to ImageFileNames.Count-1 do
        begin
           try
                // Multipart / Form-Data
               if ContentType = '' then
                  Request.ContentType   := 'multipart/form-data'
               else
               Request.ContentType   := ContentType;

               Request.Destination   := 'attachment; filename='+ExtractFileName( ImageFileNames[I] );
               Request.ContentLength := FileSizeByName( ImageFileNames[I] );

               Request.Expires       := 0;
               Request.CacheControl  := 'must-revalidate';
               Request.Pragma        := 'public';
               Request.CharSet       := 'UTF-8';

               Request.Host          := API_Host;


               //Parameter "multipart/form-data"
               TmpParams  := TIdMultipartFormDataStream.Create;

               // Make Message to UTF-8 8bit
               // Message [option]
               //TmpParams.AddFormField('image','#'+IntToStr(I+1),'utf-8').ContentTransfer := '8bit';

               // Add file for Upload
               TmpParams.AddFile('imageFile',ImageFileNames[I]); // <<--- Add file Stream <<---

               Try
               // Post Image
               sResponse := Post( TIdURI.URLEncode(EndpointURL),TmpParams );

               Except
                   On E:Exception do
                      sResponse := E.Message;
               End;

               // Result
               Result := (ResponseCode = 200);

           finally
               TmpParams.Free;

               DoOnHostResponse(Response,sResponse,Response.RawHeaders.Text);
           end;
        end;
end;

function TWrpAPI.DoOnSendToHost(EndpointURL : String; Params: TStringlist;ProcAfterGet_CallBack : TWrpProcCallBack = NIL):  IdHTTP.TIdHTTPResponse;
var sResponseText , sHeaderText : String;
begin
   FLAST_ERROR := '';

   AllowCookies     := True;
   HandleRedirects  := False;
   HTTPOptions      := [hoForceEncodeParams];

   if Assigned(FOnBeforeSendAPI) then
      FOnBeforeSendAPI(Self);

   Try
       Try
           if LowerCase(Request.Method) = 'post' then
              // POST
              //----------------------------------------------------------------
              sResponseText := Post( TIdURI.URLEncode(EndpointURL) , Params)
              //----------------------------------------------------------------
           else
           begin
              // GET
              //----------------------------------------------------------------
              if FModeRedirect then
                 begin
                    AllowCookies     := True;
                    HandleRedirects  := True;
                    if RedirectMaximum <= 15 then  // Base = 15
                       RedirectMaximum  := 50;
                    HTTPOptions      := [hoForceEncodeParams];
                 end;

              sResponseText := Get( TIdURI.URLEncode(EndpointURL) , []);

              if Assigned(ProcAfterGet_CallBack) then
                 ProcAfterGet_CallBack(Response,sResponseText,Response.RawHeaders.Text);

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
      Result := Self.Response;
      //-------------------------------------------------------

      DoOnHostResponse(Response,sResponseText,Response.RawHeaders.Text);

   Except
   End;
end;

function TWrpAPI.DoOnSendToHost(EndpointURL : String; Params: TStream;ProcAfterGet_CallBack : TWrpProcCallBack = NIL):  IdHTTP.TIdHTTPResponse;
var sResponseText , sHeaderText : String;
begin
   FLAST_ERROR := '';
   AllowCookies     := True;
   HandleRedirects  := False;
   HTTPOptions      := [hoForceEncodeParams];

   if Assigned(FOnBeforeSendAPI) then
      FOnBeforeSendAPI(Self);

   Try
       Try
           if LowerCase(Request.Method) = 'post' then
              // POST
              //----------------------------------------------------------------
              sResponseText := Post( TIdURI.URLEncode(EndpointURL) , Params)
              //----------------------------------------------------------------
           else
           begin
              // GET
              //----------------------------------------------------------------
              if FModeRedirect then
                 begin
                    AllowCookies     := True;
                    HandleRedirects  := True;
                    if RedirectMaximum <= 15 then  // Base = 15
                       RedirectMaximum  := 50;
                    HTTPOptions      := [hoForceEncodeParams];
                 end;

              sResponseText := Get( TIdURI.URLEncode(EndpointURL) , []);

              if Assigned(ProcAfterGet_CallBack) then
                 ProcAfterGet_CallBack(Response,sResponseText,Response.RawHeaders.Text);

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
      Result := Self.Response;
      //-------------------------------------------------------

      DoOnHostResponse(Response,sResponseText,Response.RawHeaders.Text);

   Except
   End;
end;

function TWrpAPI.GetHost_ResponseInfo(URL : String) : TIdHTTPResponse;
var tmpHttp : TIdHTTP;
begin
    tmpHttp := TIdHTTP.Create(NIL);
    tmpHttp.Head(URL);
    Result := tmpHttp.Response;
    FreeAndNil(tmpHttp);
end;

procedure TWrpAPI.DownloadAndSaveToFile(URL , FileName : String);
var tmpMS : TMemoryStream;
    sFileExt,sContentType : String;
begin
    tmpMS   := TMemoryStream.Create;
    try
        // Get // Download
        Get(Url, tmpMS);

        try
            tmpMS.Position := 0;
            tmpMS.SaveToFile(FileName+'.'+sFileExt);
        except
        end;

    finally
        tmpMS.Free;
    end;
end;

procedure TWrpAPI.DownloadStream(URL : String;var Data : TMemoryStream);
begin
    try
        Get(Url, Data);
        Data.Position := 0;
    finally
    end;
end;

procedure TWrpAPI.DownloadVideoParallel(URL : String;FileName : String);
var iSize: Integer;
const
  //csUrl = 'http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4';
  //csFile = 'D:\fromline\temp.mp4';
  ciSlice = 10;
begin
  TParallel.&For(0, ciSlice - 1,                // System.Threading.TParallel
     procedure (iIndex: Integer)
     var
       iPartSize, iStart, iEnd: Int64;
       oClient   : THTTPClient; // System.Net.HttpClient
       oFile     : TFileStream;
       LResponse : IHTTPResponse; // System.Net.HttpClient
     begin
       // find out which block I should actually download
       iPartSize := iSize div ciSlice;
       iStart := iPartSize * iIndex;
       iEnd := iPartSize * (iIndex + 1);
       if iIndex = ciSlice - 1 then  // for the last block a small correction
          iEnd := iSize;

        oClient := THTTPClient.Create;
        try
          oFile := TFileStream.Create(FileName, fmOpenWrite or fmCreate or fmShareDenyNone);
          try
            oFile.Seek(iStart, soBeginning); // set in place in the file
            LResponse := oClient.GetRange(Url, iStart, iEnd - 1, oFile); // get it!
          finally
            oFile.Free;
          end;
        finally
          oClient.Free;
        end;
     end
  );
end;

procedure TWrpAPI.DoOnHostResponse(Response : IdHTTP.TIdHTTPResponse;ResponseText,ReponseRawHeaderText : String);
begin
   if Assigned(FOnHostResponse) then
      FOnHostResponse(Response,ResponseText,ReponseRawHeaderText);
end;

procedure TWrpAPI.DoOnTrackHostResponse(Response: IdHTTP.TIdHTTPResponse;AHeaders: TIdHeaderList);
begin
   if Assigned(FOnTrackHostResponse) then
      FOnTrackHostResponse(Response,AHeaders);
end;

procedure TWrpAPI.SetAPI_Host(const Value: String);
begin
  FAPI_Host := Value;
end;

procedure TWrpAPI.SetAPI_UserAgent(const Value: String);
begin
  FAPI_UserAgent := Value;
end;

procedure TWrpAPI.SetModeRedirect(const Value: Boolean);
begin
  FModeRedirect := Value;
end;

//procedure TWrpAPI.SetStandAlone(const Value: Boolean);
//begin
//  FStandAlone := Value;
//end;

function TWrpAPI.GetAbout: String;
begin
   Result := FAbout;
end;

end.
