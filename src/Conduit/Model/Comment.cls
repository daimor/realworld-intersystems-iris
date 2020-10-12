Class Conduit.Model.Comment Extends (%Persistent, Conduit.Model.Base) [ Owner = {_PUBLIC} ]
{

Property id As %Integer [ Calculated, SqlComputeCode = { Set {*} = {%%ID} }, SqlComputed ];

Property body As %String(MAXLEN = 1000) [ Required ];

Property author As Conduit.Model.User(%JSONINCLUDE = "OUTPUTONLY");

Relationship article As Conduit.Model.Article [ Cardinality = one, Inverse = comment, OnDelete = cascade ];

XData Comment [ XMLNamespace = "http://www.intersystems.com/jsonmapping" ]
{
<Mapping xmlns="http://www.intersystems.com/jsonmapping">
  <Property Name="id" />
  <Property Name="createdAt" />
  <Property Name="updatedAt" />
  <Property Name="body" />
  <Property Name="author" Mapping="Profile" />
</Mapping>
}

Query All(slug As %String = "") As %SQLQuery(ROWSPEC = "id:%Integer")
{
SELECT id
FROM Comment
WHERE article->slug = :slug
}

Storage Default
{
<Data name="CommentDefaultData">
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
<Value>body</Value>
</Value>
<Value name="5">
<Value>author</Value>
</Value>
<Value name="6">
<Value>article</Value>
</Value>
</Data>
<DataLocation>^Conduit.Model.CommentD</DataLocation>
<DefaultData>CommentDefaultData</DefaultData>
<IdLocation>^Conduit.Model.CommentD</IdLocation>
<IndexLocation>^Conduit.Model.CommentI</IndexLocation>
<StreamLocation>^Conduit.Model.CommentS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
