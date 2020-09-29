Class Conduit.Model.Article Extends (%Persistent, Conduit.Model.Base) [ Owner = {_PUBLIC} ]
{

Parameter EXTENTQUERYSPEC = "slug,title";

Property title As %String(MAXLEN = 100) [ Required ];

Property slug As %String;

Index slug On slug [ Unique ];

Property body As %String [ Required ];

Property tagList As list Of %String(SQLPROJECTION = "table/column", STORAGEDEFAULT = "array");

Index tag On tagList(ELEMENTS);

Property description As %String [ Required ];

Property author As Conduit.Model.User(%JSONINCLUDE = "OUTPUTONLY");

Index author On author [ Type = bitmap ];

Relationship comment As Conduit.Model.Comment [ Cardinality = many, Inverse = article ];

Property favorited As %Boolean [ Calculated ];

Method favoritedGet() As %Boolean
{
  If ('$IsObject($Get(%user))) {
    Quit 0
  }

  Set userId = %user.id
  Set articleId = ..%Id()
  Set yes = 0
  &sql(
  SELECT count(*) INTO :yes
  FROM Conduit_Model.Favorites
  WHERE "User" = :userId AND favorites = :articleId)

  Quit yes
}

Method favoritedSet(value As %Boolean) As %Status
{
  If ('$IsObject($Get(%user))) {
    Quit $$$OK
  }

  Set userId = %user.id
  Set articleId = ..%Id()
  If value=..favorited {
    Quit $$$OK
  }

  If value {
    Do %user.favorites.Insert($this)
  }
  Else {
    Set ind = %user.favorites.FindObjectId(articleId)
    Do %user.favorites.RemoveAt(ind)
  }

  Quit %user.%Save()
}

Property favoritesCount As %Integer [ Calculated ];

Method favoritesCountGet() As %Integer
{
  Set articleId = ..%Id()
  Set count = 0
  &sql(
  SELECT COUNT(DISTINCT "User") INTO :count
  FROM Conduit_Model.Favorites
  WHERE favorites = :articleId)

  Quit count
}

Method %OnBeforeSave(insert As %Boolean = 0) As %Status
{
  $$$QuitOnError(##super(.insert))

  if (insert) {
    Set slug = ..slugify(..title)
    Do {
      Set suffix = ..generateSuffix()
    } While (..slugExists(slug _ "-" _ suffix))

    Set ..slug = slug _ "-" _ suffix
  }

	Quit $$$OK
}

ClassMethod generateSuffix(length = 6) As %String
{
  Set alphanum = "abcdefghijklmnopqrstuvwxyz0123456789"
  Set suffix = ""
  For i=1:1:length {
    Set suffix = suffix _ $Extract(alphanum, $Random(36) + 1)
  }

  Quit suffix
}

ClassMethod slugify(value) As %String
{
  Set slug = $ZConvert(value, "L")

  Set slug = $ZStrip(slug, "<>W")
  Set slug = $Translate(slug, $Char(9, 32, 160), "---")
  Set slug = $Replace(slug, "&","-and-")

  Set slug = $ZStrip(slug, "*P",, "-")
  Set slug = $ZStrip(slug, "=P")
  Set slug = ##class(%Regex.Matcher).%New("[^a-z0-9-]+", slug).ReplaceAll("")
  Quit slug
}

Query All(tag As %String = "", author As %String = "", favorited As %String = "") As %SQLQuery(ROWSPEC = "id:%Integer")
{
SELECT id
FROM Article
WHERE (1=1)
  AND (:tag IS NULL OR :tag %INLIST tagList)
  AND (:author IS NULL OR author->username = :author)
  AND (:favorited IS NULL OR id IN (
    SELECT favorites FROM Favorites WHERE "User"->username = :favorited
  ))
}

Query Feed(user As %Integer) As %SQLQuery(ROWSPEC = "id:%Integer")
{
SELECT id
FROM Conduit_Model.Article
WHERE author IN (
  SELECT followed FROM Conduit_Model.Followed
  WHERE "User" = :user
  )
}

Query AllTags() As %SQLQuery(ROWSPEC = "tag:%String")
{
SELECT DISTINCT %EXACT(tagList) tag FROM Conduit_Model.Article_tagList
}

XData Article
{
<Mapping xmlns="http://www.intersystems.com/jsonmapping">
  <Property Name="title" />
  <Property Name="slug" />
  <Property Name="createdAt" />
  <Property Name="updatedAt" />
  <Property Name="body" />
  <Property Name="tagList" />
  <Property Name="description" />
  <Property Name="author" Mapping="Profile" />
  <Property Name="favorited" />
  <Property Name="favoritesCount" />
</Mapping>
}

Storage Default
{
<Data name="ArticleDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>createdAt</Value>
</Value>
<Value name="3">
<Value>title</Value>
</Value>
<Value name="4">
<Value>slug</Value>
</Value>
<Value name="5">
<Value>body</Value>
</Value>
<Value name="6">
<Value>description</Value>
</Value>
<Value name="7">
<Value>author</Value>
</Value>
<Value name="8">
<Value>favoritesList</Value>
</Value>
<Value name="9">
<Value>updatedAt</Value>
</Value>
<Value name="10">
<Value>comment</Value>
</Value>
</Data>
<Data name="tagList">
<Attribute>tagList</Attribute>
<Structure>subnode</Structure>
<Subscript>"tagList"</Subscript>
</Data>
<DataLocation>^Conduit.Model.ArticleD</DataLocation>
<DefaultData>ArticleDefaultData</DefaultData>
<IdLocation>^Conduit.Model.ArticleD</IdLocation>
<IndexLocation>^Conduit.Model.ArticleI</IndexLocation>
<StreamLocation>^Conduit.Model.ArticleS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
