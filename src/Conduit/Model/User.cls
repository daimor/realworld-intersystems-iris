Class Conduit.Model.User Extends (%Persistent, Conduit.Model.Base) [ Owner = {_PUBLIC} ]
{

Parameter EXTENTQUERYSPEC = "id,username,email";

/// access_token, days to live
Parameter TOKENEXPIREDIN = {30 * 86400};

Property id As %Integer [ Calculated, SqlComputeCode = { Set {*} = {%%ID} }, SqlComputed ];

Property username As %String(MAXLEN = 20) [ Required ];

Index username On username [ Unique ];

Property email As %String(MAXLEN = 200) [ Required ];

Index email On email [ Unique ];

Property bio As %String(%JSONNULL = 1);

Property image As %String(%JSONNULL = 1, MAXLEN = 500);

Method imageGet() As %String
{
  If i%image'="" {
    Quit i%image
  }
  Quit "https://static.productionready.io/images/smiley-cyrus.jpg"
}

Property salt As %String(%JSONINCLUDE = "NONE") [ Private ];

Property password As %String(%JSONINCLUDE = "INPUTONLY") [ Private, Required ];

Method passwordSet(value As %String) As %Status
{
  Set i%salt = $system.Encryption.GenCryptRand(8)
  Set i%password = $System.Encryption.SHA1Hash(value _ i%salt)
  Quit $$$OK
}

Property followed As list Of User(SQLPROJECTION = "table/column", SQLTABLENAME = "Followed", STORAGEDEFAULT = "array");

Property following As %Boolean;

Method followingGet() As %Boolean
{
  If '$IsObject($Get(%user)) {
    Quit 0
  }

  If %user.followed.FindObjectId(..%Id()) {
    Quit 1
  }

  Quit 0
}

Method followingSet(value As %Boolean) As %Status
{
  If '$IsObject($Get(%user)) {
    Quit 0
  }

  If (..following=value) {
    Quit $$$OK
  }

  If (value) {
    Do %user.followed.Insert($this)
  }
  Else {
    Set ind = %user.followed.FindObjectId(..%Id())
    Do %user.followed.RemoveAt(ind)
  }

  Quit %user.%Save()
}

Property favorites As list Of Conduit.Model.Article(SQLPROJECTION = "table/column", SQLTABLENAME = "Favorites", STORAGEDEFAULT = "array");

Index favorites On favorites(ELEMENTS);

ClassMethod ValidateUser(email, password, Output user) As %Boolean
{
  Set user = ##class(Conduit.Model.User).emailOpen(email,, .tSC)
  Quit:$$$ISERR(tSC) 0

  Set passwordHash = $System.Encryption.SHA1Hash(password _ user.salt)

  Quit passwordHash = user.password
}

ClassMethod ValidateToken(token, Output user) As %Boolean
{
  Set alg = "HS256"
  Set JOSE("sigalg") = alg
  Set jwks = ..GetJWK(alg)
  $$$ThrowOnError(##class(%OAuth2.JWT).JWTToObject(token, jwks, jwks, .JOSE, .obj))
  if '$IsObject(obj) {
    Quit 0
  }

  Set exp = obj.exp
  Set now = ##class(%OAuth2.Utils).TimeInSeconds($ztimestamp)
  if (exp<now) {
    Quit 0
  }

  Set user = ##class(Conduit.Model.User).%OpenId(obj.id,, .tSC)
  Quit:$$$ISERR(tSC) 0

  Quit 1
}

Property token As %String(%JSONINCLUDE = "OUTPUTONLY", MAXLEN = 1000) [ Calculated ];

Method tokenGet() As %String
{
  Set obj = {
    "id": (..%Id()),
    "username": (..username),
    "exp": (##class(%OAuth2.Utils).TimeInSeconds($ztimestamp, ..#TOKENEXPIREDIN))
  }
  Set alg = "HS256"
  Set JOSE("sigalg") = alg
  Set jwks = ..GetJWK(alg)
  $$$ThrowOnError(##class(%OAuth2.JWT).ObjectToJWT(.JOSE, obj, jwks, jwks, .JWT))

  Quit JWT
}

Method %OnBeforeSave(insert As %Boolean) As %Status
{
  $$$QuitOnError(##super(.insert))

	Quit $$$OK
}

ClassMethod JWTSecret() As %String
{
  If $Data(^JWTSecret, secret) {
    Quit secret
  }

  #; No secret, yet, then generate new one

  Set secret = $system.Encryption.GenCryptRand(32)
  Set secret = $System.Encryption.Base64Encode(secret)

  Set ^JWTSecret = secret
  Quit secret
}

ClassMethod GetJWK(alg) As %String
{
  Set secret = ..JWTSecret()
  Set jwks = { "keys": [{ "alg": (alg), "k": (secret) }] }
  Quit jwks.%ToJSON()
}

XData Update
{
<Mapping xmlns="http://www.intersystems.com/jsonmapping">
  <Property Name="email" />
  <Property Name="username" IgnoreNull="1" />
  <Property Name="bio" Null="1" IgnoreNull="1" />
  <Property Name="image" Null="1" IgnoreNull="1" />
</Mapping>
}

XData User
{
<Mapping xmlns="http://www.intersystems.com/jsonmapping">
  <Property Name="id" />
  <Property Name="email" />
  <Property Name="createdAt" />
  <Property Name="updatedAt" />
  <Property Name="username" />
  <Property Name="bio" Null="1" />
  <Property Name="image" Null="1" />
  <Property Name="token" />
</Mapping>
}

XData Profile
{
<Mapping xmlns="http://www.intersystems.com/jsonmapping">
  <Property Name="username" />
  <Property Name="bio" Null="1" />
  <Property Name="image" Null="1" />
  <Property Name="following" />
</Mapping>
}

Storage Default
{
<Data name="UserDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>createdAt</Value>
</Value>
<Value name="3">
<Value>updatedAt</Value>
</Value>
<Value name="4">
<Value>username</Value>
</Value>
<Value name="5">
<Value>email</Value>
</Value>
<Value name="6">
<Value>bio</Value>
</Value>
<Value name="7">
<Value>image</Value>
</Value>
<Value name="8">
<Value>salt</Value>
</Value>
<Value name="9">
<Value>password</Value>
</Value>
<Value name="10">
<Value>following</Value>
</Value>
</Data>
<Data name="favorites">
<Attribute>favorites</Attribute>
<Structure>subnode</Structure>
<Subscript>"favorites"</Subscript>
</Data>
<Data name="followed">
<Attribute>followed</Attribute>
<Structure>subnode</Structure>
<Subscript>"followed"</Subscript>
</Data>
<DataLocation>^Conduit.Model.UserD</DataLocation>
<DefaultData>UserDefaultData</DefaultData>
<IdLocation>^Conduit.Model.UserD</IdLocation>
<IndexLocation>^Conduit.Model.UserI</IndexLocation>
<StreamLocation>^Conduit.Model.UserS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
