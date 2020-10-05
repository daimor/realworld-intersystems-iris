Class UnitTest.Conduit.API Extends %UnitTest.TestCase
{

Method OnBeforeOneTest() As %Status
{
  Set %request = ##class(%CSP.Request).%New()
  Set %response = ##class(%CSP.Response).%New()

  Quit $$$OK
}

Method "Test No authorized"()
{
  #; No token provided
  Do $$$AssertNotTrue(##class(Conduit.API.impl).IsAuthorized())
}

Method "Test GetCurrentuser"()
{
  Set result = ##class(Conduit.API.impl).GetCurrentUser()
  Do $$$AssertEquals(+%response.Status, 401)
}

Method "Test Login"()
{
  Set result = ##class(Conduit.API.impl).Login()
  Do $$$AssertEquals(+%response.Status, 422)
}

Method "Test CreateUser"()
{
  Set result = ##class(Conduit.API.impl).CreateUser()
  Do $$$AssertEquals(+%response.Status, 422)
}

Method "Test UpdateCurrentUser"()
{
  Set result = ##class(Conduit.API.impl).UpdateCurrentUser()
  Do $$$AssertEquals(+%response.Status, 401)
}

Method "Test FollowUserByUsername"()
{
  Set result = ##class(Conduit.API.impl).FollowUserByUsername()
  Do $$$AssertEquals(+%response.Status, 401)
}

Method "Test UnfollowUserByUsername"()
{
  Set result = ##class(Conduit.API.impl).UnfollowUserByUsername()
  Do $$$AssertEquals(+%response.Status, 401)
}

Method "Test GetArticlesFeed"()
{
  Set result = ##class(Conduit.API.impl).GetArticlesFeed()
  Do $$$AssertEquals(+%response.Status, 401)
}

Method "Test CreateArticle"()
{
  Set result = ##class(Conduit.API.impl).CreateArticle()
  Do $$$AssertEquals(+%response.Status, 401)
}

Method "Test GetArticle"()
{
  Set result = ##class(Conduit.API.impl).GetArticle()
  Do $$$AssertEquals(+%response.Status, 404)
}

Method "Test UpdateArticle"()
{
  Set result = ##class(Conduit.API.impl).UpdateArticle()
  Do $$$AssertEquals(+%response.Status, 401)
}

Method "Test DeleteArticle"()
{
  Set result = ##class(Conduit.API.impl).DeleteArticle()
  Do $$$AssertEquals(+%response.Status, 401)
}

Method "Test CreateArticleComment"()
{
  Set result = ##class(Conduit.API.impl).CreateArticleComment()
  Do $$$AssertEquals(+%response.Status, 401)
}

Method "Test DeleteArticleComment"()
{
  Set result = ##class(Conduit.API.impl).DeleteArticleComment()
  Do $$$AssertEquals(+%response.Status, 401)
}

Method "Test CreateArticleFavorite"()
{
  Set result = ##class(Conduit.API.impl).CreateArticleFavorite()
  Do $$$AssertEquals(+%response.Status, 401)
}

Method "Test DeleteArticleFavorite"()
{
  Set result = ##class(Conduit.API.impl).DeleteArticleFavorite()
  Do $$$AssertEquals(+%response.Status, 401)
}

Method "Test GetProfileByUsername"()
{
  Set result = ##class(Conduit.API.impl).GetProfileByUsername("")
  Do $$$AssertEquals(+%response.Status, 404)
}

Method "Test GetArticles"() As %Status
{
  Set result = ##class(Conduit.API.impl).GetArticles()
  Do $$$AssertEquals(+%response.Status, 200)
}

Method "Test GetArticleComments"() As %Status
{
  Set result = ##class(Conduit.API.impl).GetArticleComments("")
  Do $$$AssertEquals(+%response.Status, 200)
}

Method "Test GetTags"() As %Status
{
  Set result = ##class(Conduit.API.impl).GetTags()
  Do $$$AssertEquals(+%response.Status, 200)
}

}
