Class MyApp.Utils [ Abstract ]
{

/// App level initialization if any
ClassMethod Init() As %Status
{
	#; Do something to populate initial data
	Set tSC=..runSQL()
	Set tSC=..LoadCSV()
	Set ^ImageBuildDate=$ZDATETIME($H)
	Return $$$OK
}

ClassMethod runSQL(ByRef tVars) As %Status
{
  Set rs=##class(%ResultSet).%New("%File:FileSet") 
  Do rs.Execute("/home/irisowner/sql","*.sql")
  While(rs.Next()) { 
    Do $SYSTEM.SQL.Schema.ImportDDL(rs.Name,"/home/irisowner/import_Errors.log")
  }
  Return $$$OK
}

ClassMethod LoadCSV() As %Status
{
  Set opt={"from": {"file": {"header": true,"charset": "UTF-8"}}}.%ToJSON()

  #;Set sql="LOAD DATA FROM FILE '/home/irisowner/csv/MyApp_DB.Table1.csv' INTO MyApp_DB.Table1 USING "_opt
  Set sql="LOAD DATA FROM FILE '/home/irisowner/csv/Person.csv' INTO Person USING "_opt

  set stmt = ##class(%SQL.Statement).%New()
  Set tSC=stmt.%Prepare(sql)
  set rs = stmt.%Execute()
  if rs.%SQLCODE > 0 {
    zw rs
    Return '$$$OK
  } else {
    Return $$$OK
  }
  Return $$$OK
}

}
