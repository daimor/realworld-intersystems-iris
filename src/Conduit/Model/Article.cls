Class Conduit.Model.Article Extends (%Persistent, Conduit.Model.Base) [ Owner = {_PUBLIC} ]
{

Parameter EXTENTQUERYSPEC = "slug,title";

/// Title
Property title As %String(MAXLEN = 100) [ Required ];

/// Unique URL-compatible identifier generated from title
Property slug As %String [ SqlComputeCode = {
Set slug = ..slugify({title})
Do {
  Set suffix = ..generateSuffix()
} While (..slugExists(slug _ "-" _ suffix))

Set {*} = slug _ "-" _ suffix
}, SqlComputed, SqlComputeOnChange = title ];

Index slug On slug [ Unique ];

/// Body
Property body As %String(MAXLEN = 2000) [ Required ];

/// Tag List
Property tagList As list Of %String(SQLPROJECTION = "table/column", STORAGEDEFAULT = "array");

Index tag On tagList(ELEMENTS);

/// Description
Property description As %String [ Required ];

/// Link to Author
Property author As Conduit.Model.User(%JSONINCLUDE = "OUTPUTONLY");

Index author On author [ Type = bitmap ];

/// Comments
Relationship comment As Conduit.Model.Comment [ Cardinality = many, Inverse = article ];

/// Is Favorited by logged user
Property favorited As %Boolean [ Calculated ];

/// Check if favorited by logged user
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
  If SQLCODE'=0 Quit 0

  Quit yes
}

/// Favor this article by logged user
Method favoritedSet(value As %Boolean) As %Status
{
  If ('$IsObject($Get(%user))) {
    Quit $$$OK
  }

  Set articleId = ..%Id()
  If value=..favorited {
    Quit $$$OK
  }

  If value {
    Do %user.favorites.Insert($This)
  }
  Else {
    Set ind = %user.favorites.FindObjectId(articleId)
    Do %user.favorites.RemoveAt(ind)
  }

  Quit %user.%Save()
}

/// Favorites counter
Property favoritesCount As %Integer [ Calculated ];

/// Returns amount of users favorited this article
Method favoritesCountGet() As %Integer
{
  Set articleId = ..%Id()
  Set count = 0
  &sql(
  SELECT COUNT(DISTINCT "User") INTO :count
  FROM Conduit_Model.Favorites
  WHERE favorites = :articleId)
  If SQLCODE'=0 Quit 0

  Quit count
}

/// Generate rundom suffix used for slug
ClassMethod generateSuffix(length = 6) As %String
{
  Set alphanum = "abcdefghijklmnopqrstuvwxyz0123456789"
  Set suffix = ""
  For i=1:1:length {
    Set suffix = suffix _ $Extract(alphanum, $Random(36) + 1)
  }

  Quit suffix
}

/// Generate URL compatible identifier
ClassMethod slugify(value) As %String
{
  Set slug = $ZConvert(value, "L")

  Set slug = $ZStrip(slug, "<>W")

  #; replace whitespaces
  Set slug = $Translate(slug, $Char(9, 32, 160), "---")
  #; replace diacritics, and some punctuation
  Set slug = $Translate(slug,
          "ãàáäâẽèéëêìíïîõòóöôùúüûñç·/_,:;",
          "aaaaaeeeeeiiiiooooouuuunc------")

  Set slug = $Replace(slug, "&","-and-")

  Set slug = $ZStrip(slug, "*P",, "-")
  Set slug = ##class(%Regex.Matcher).%New("[^a-z0-9-]+", slug).ReplaceAll("")
  Set slug = $ZStrip(slug, "<>=P")
  Quit slug
}

/// List ID of the articles by filters if specified
///   tag - search by tag
///   author - search by author
///   favorited - show by favorited flag
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

/// List of articles from followed users by provided user
///   user - owner of feed
Query Feed(user As %Integer) As %SQLQuery(ROWSPEC = "id:%Integer")
{
SELECT id
FROM Conduit_Model.Article
WHERE author IN (
  SELECT followed FROM Conduit_Model.Followed
  WHERE "User" = :user
  )
}

/// Disctinct list of tags
Query AllTags() As %SQLQuery(ROWSPEC = "tag:%String")
{
SELECT DISTINCT %EXACT(tagList) tag FROM Conduit_Model.Article_tagList
}

/// JSON export
XData Article [ XMLNamespace = "http://www.intersystems.com/jsonmapping" ]
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
