Class MyApp.impl Extends %REST.Impl [ ProcedureBlock ]
{

/// If ExposeServerExceptions is true, then details of internal errors will be exposed.
Parameter ExposeServerExceptions = 0;

ClassMethod TestGet() As %Stream.Object
{
    Do ..%SetHeader("Content-Type","application/json")
    Set results=[]
    Set cnt=0
	Set c="" For cnt=1:1 {
		Set c=$O(^log(c),-1) q:c=""
		Do results.%Push({"TimeStamp":(^log(c))})
        Quit:cnt=3
	}
	Set ret={"HostName":($SYSTEM.INetInfo.LocalHostName()),"UserName":($USERNAME),"Method":"Get","TimeStamp":($ZDATETIME($H)),"Results":(results)}
    Quit ret
}
ClassMethod TestPost() As %Stream.Object
{
    Do ..%SetHeader("Content-Type","application/json")
	Set ret={"HostName":($SYSTEM.INetInfo.LocalHostName()),"UserName":($USERNAME),"Method":"Post","TimeStamp":($ZDATETIME($H))}
	Set ^log($INCREMENT(^log))=ret.TimeStamp
    Quit ret
}

}
