/// Conduit API<br/>
/// Business logic class defined by OpenAPI in Conduit.API.spec<br/>
/// Updated Sep 29, 2020 14:29:43
Class Conduit.API.impl Extends %REST.Impl [ ProcedureBlock ]
{

/// If ExposeServerExceptions is true, then details of internal errors will be exposed.
Parameter ExposeServerExceptions = 0;

ClassMethod IsAuthorized(Output user As Conduit.Model.User, optional As %Boolean = 0) As %Boolean
{
  Kill %user
  Set token = $Piece(%request.GetCgiEnv("HTTP_AUTHORIZATION"), " ", 2, *)
  If token = "", optional {
    Return 1
  }

  Try {
    If '##class(Conduit.Model.User).ValidateToken(token, .user) {
      Return 0
    }
    Set %user = user
    Return 1
  }
  Catch (ex) {
  }
  Return 0
}

ClassMethod outputObject(kind As %String, object As %JSON.Adaptor, mapping As %String) As %String
{
  $$$ThrowOnError(object.%JSONExportToString(.output, .mapping))
  Quit "{ """ _ kind _ """: " _ output _ "}"
}

ClassMethod outputSQL(rs As %SQL.StatementResult, kind As %String, class As %String = "", mapping As %String, limit As %Integer = 20, offset As %Integer = 0) As %DynamicObject
{
  If rs.%SQLCODE'="0" {
    Do ..%SetStatusCode(500)
    Return {
      "errors": {
        "body": [
          (rs.%Message)
        ]
      }
    }
  }

  Set list = []
  Set count = 0
  Set end = offset + limit


  While rs.%Next() {
    If (class = "") {
      Do list.%Push(rs.%GetData(1))
      Continue
    }
    Set count = count + 1
    Continue:count<offset
    Continue:count>end
    Set item = $System.OBJ.OpenId(class, rs.id)
    Continue:'$IsObject(item)
    $$$ThrowOnError(item.%JSONExportToString(.output, mapping))
    Set json = {}.%FromJSON(output)
    Do list.%Push(json)
  }

  Set result = {}
  Set $Property(result, kind) = list
  Set:class'="" $Property(result, kind_ "Count") = count
  Quit result
}

ClassMethod ProcessError(ex As %Exception.AbstractException) As %DynamicObject
{
  Set errors = { }
  Do ..%SetStatusCode(422)

  If (ex.%IsA("%Library.DynamicObject")) {
    Set errors = ex
  }
  ElseIf (ex.Code=9405) {
    Set field = $Listget(ex.Data)
    Set $Property(errors, field) = [ "can't be blank" ]
  }
  ElseIf (ex.Code=9406) {
    Set field = $Listget(ex.Data)
    Set $Property(errors, field) = [ "is too long" ]
  }
  ElseIf (ex.Code=5808) {
    Set field = $Piece($Listget(ex.Data), ":", 2)
    Set $Property(errors, field) = [ "has already been taken" ]
  }
  ElseIf (ex.%IsA("%Exception.StatusException")) {
    Set field = $Listget(ex.Data)
    Set:field="" field = "body"
    Set $Property(errors, field) = [ (ex.DisplayString()) ]
  }
  Else {
    Set errors.body = [ (ex.DisplayString()) ]
  }

  Return { "errors": (errors) }
}

ClassMethod Process401() As %DynamicAbstractObject
{
  Do ..%SetStatusCode(401)
  Quit ""
}

ClassMethod Process404() As %DynamicAbstractObject
{
  Do ..%SetStatusCode(404)
  Quit {
    "status": "404",
    "error": "Not Found"
  }
}

/// Login for existing user<br/>
/// The method arguments hold values for:<br/>
///     body, Credentials to use<br/>
ClassMethod Login(body As %DynamicObject) As %DynamicObject
{
  Try {
    Set email = body.user.email
    Set password = body.user.password

    If ##class(Conduit.Model.User).ValidateUser(email,password, .user) {
      Return ..outputObject("user", user, "User")
    }
  }
  Catch (ex) {
    #; Don't care about a real error
    #; Return ..ProcessError(ex)
  }
  Return ..ProcessError( { "email or password": [ "is invalid" ] } )
}

/// Register a new user<br/>
/// The method arguments hold values for:<br/>
///     body, Details of the new user to register<br/>
ClassMethod CreateUser(body As %DynamicObject) As %DynamicObject
{
  Try {
    Set body = $Select(body.%IsDefined("user"): body.user, 1: body)

    Set user = ##class(Conduit.Model.User).%New()
    $$$ThrowOnError(user.%JSONImport(body))
    $$$ThrowOnError(user.%Save())
    Return ..outputObject("user", user, "User")
  }
  Catch (ex) {
    Return ..ProcessError(ex)
  }
}

/// Gets the currently logged-in user
ClassMethod GetCurrentUser() As %DynamicObject
{
  If '..IsAuthorized(.user) {
    Quit ..Process401()
  }

  Return ..outputObject("user", user, "User")
}

/// Updated user information for current user<br/>
/// The method arguments hold values for:<br/>
///     body, User details to update. At least **one** field is required.<br/>
ClassMethod UpdateCurrentUser(body As %DynamicObject) As %DynamicObject
{
  If '..IsAuthorized(.user) {
    Quit ..Process401()
  }

  Try {
    Set update = $Select(body.%IsDefined("user"): body.user, 1: body)
    #; $$$ThrowOnError(user.%JSONImport(body.user, "Update"))
    Set:update.%IsDefined("username") user.username = update.username
    Set:update.%IsDefined("email") user.email = update.email
    Set:update.%IsDefined("bio") user.bio = update.bio
    Set:update.%IsDefined("image") user.image = update.image
    Set:update.%IsDefined("password") user.password = update.password
    $$$ThrowOnError(user.%Save())
    Return ..outputObject("user", user, "User")
  }
  Catch (ex) {
    Return ..ProcessError(ex)
  }
}

/// Get a profile of a user of the system. Auth is optional<br/>
/// The method arguments hold values for:<br/>
///     username, Username of the profile to get<br/>
ClassMethod GetProfileByUsername(username As %String) As %DynamicObject
{
  If '..IsAuthorized(.user, 1) {
    Quit ..Process401()
  }

  Set user = ##class(Conduit.Model.User).usernameOpen(username,, .tSC)
  If $$$ISERR(tSC) {
    Quit ..Process404()
  }

  If (user.image="") {
    Set user.image = "https://static.productionready.io/images/smiley-cyrus.jpg"
  }

  Return ..outputObject("profile", user, "Profile")
}

/// Follow a user by username<br/>
/// The method arguments hold values for:<br/>
///     username, Username of the profile you want to follow<br/>
ClassMethod FollowUserByUsername(username As %String) As %DynamicObject
{
  If '..IsAuthorized(.user) {
    Quit ..Process401()
  }

  Set user = ##class(Conduit.Model.User).usernameOpen(username,, .tSC)
  If $$$ISERR(tSC) {
    Quit ..Process404()
  }

  try {
    Set user.following = 1
    $$$ThrowOnError(user.%Save())
  }
  Catch ex {
    Return ..ProcessError(ex)
  }

  Quit ..outputObject("profile", user, "Profile")
}

/// Unfollow a user by username<br/>
/// The method arguments hold values for:<br/>
///     username, Username of the profile you want to unfollow<br/>
ClassMethod UnfollowUserByUsername(username As %String) As %DynamicObject
{
  If '..IsAuthorized(.user) {
    Quit ..Process401()
  }

  Set user = ##class(Conduit.Model.User).usernameOpen(username,, .tSC)
  If $$$ISERR(tSC) {
    Quit ..Process404()
  }

  try {
    Set user.following = 0
    $$$ThrowOnError(user.%Save())
  }
  Catch ex {
    Return ..ProcessError(ex)
  }

  Quit ..outputObject("profile", user, "Profile")
}

/// Get most recent articles from users you follow. Use query parameters to limit. Auth is required<br/>
/// The method arguments hold values for:<br/>
///     limit, Limit number of articles returned (default is 20)<br/>
///     offset, Offset/skip number of articles (default is 0)<br/>
ClassMethod GetArticlesFeed(limit As %Integer, offset As %Integer) As %DynamicObject
{
  Set limit = +$Get(limit, 20)
  Set offset = +$Get(offset, 0)

  If '..IsAuthorized(.user) {
    Quit ..Process401()
  }

  Set rs = ##class(Conduit.Model.Article).FeedFunc(user.id)
  Quit ..outputSQL(rs, "articles", "Conduit.Model.Article", "Article", limit, offset)
}

/// Get most recent articles globally. Use query parameters to filter results. Auth is optional<br/>
/// The method arguments hold values for:<br/>
///     tag, Filter by tag<br/>
///     author, Filter by author (username)<br/>
///     favorited, Filter by favorites of a user (username)<br/>
///     limit, Limit number of articles returned (default is 20)<br/>
///     offset, Offset/skip number of articles (default is 0)<br/>
ClassMethod GetArticles(tag As %String, author As %String, favorited As %String, limit As %Integer, offset As %Integer) As %DynamicObject
{
  Set tag = $Get(tag, "")
  Set author = $Get(author, "")
  Set favorited = $Get(favorited, "")
  Set limit = +$Get(limit, 20)
  Set offset = +$Get(offset, 0)

  If '..IsAuthorized(.user, 1) {
    Quit ..Process401()
  }

  try {
    Set rs = ##class(Conduit.Model.Article).AllFunc(tag, author, favorited)
    Return ..outputSQL(rs, "articles", "Conduit.Model.Article", "Article", limit, offset)
  }
  Catch ex {
    Return ..ProcessError(ex)
  }
}

/// Create an article. Auth is required<br/>
/// The method arguments hold values for:<br/>
///     body, Article to create<br/>
ClassMethod CreateArticle(body As %DynamicObject) As %DynamicObject
{
  If '..IsAuthorized(.user) {
    Quit ..Process401()
  }

  Try {
    Set body = $Select(body.%IsDefined("article"): body.article, 1: body)

    Set article = ##class(Conduit.Model.Article).%New()
    $$$ThrowOnError(article.%JSONImport(body))
    Set article.author = user
    $$$ThrowOnError(article.%Save())
    Return ..outputObject("article", article, "Article")
  }
  Catch (ex) {
    Return ..ProcessError(ex)
  }
}

/// Get an article. Auth not required<br/>
/// The method arguments hold values for:<br/>
///     slug, Slug of the article to get<br/>
ClassMethod GetArticle(slug As %String) As %DynamicObject
{
  If '..IsAuthorized(.user, 1) {
    Quit ..Process401()
  }

  Set article = ##class(Conduit.Model.Article).slugOpen(slug,, .tSC)
  If $$$ISERR(tSC) {
    Quit ..Process404()
  }

  Return ..outputObject("article", article, "Article")
}

/// Update an article. Auth is required<br/>
/// The method arguments hold values for:<br/>
///     slug, Slug of the article to update<br/>
///     body, Article to update<br/>
ClassMethod UpdateArticle(slug As %String, body As %DynamicObject) As %DynamicObject
{
  If '..IsAuthorized(.user) {
    Quit ..Process401()
  }

  Try {
    Set update = $Select(body.%IsDefined("article"): body.article, 1: article)

    Set article = ##class(Conduit.Model.Article).slugOpen(slug,, .tSC)
    If $$$ISERR(tSC) {
      Return ..Process404()
    }
    Set:update.%IsDefined("title") article.title = update.title
    Set:update.%IsDefined("description") article.description = update.description
    Set:update.%IsDefined("body") article.body = update.body
    $$$ThrowOnError(article.%Save())

    Return ..outputObject("article", article, "Article")
  }
  Catch (ex) {
    Return ..ProcessError(ex)
  }
}

/// Delete an article. Auth is required<br/>
/// The method arguments hold values for:<br/>
///     slug, Slug of the article to delete<br/>
ClassMethod DeleteArticle(slug As %String) As %DynamicObject
{
  If '..IsAuthorized(.user) {
    Quit ..Process401()
  }

  Set article = ##class(Conduit.Model.Article).slugOpen(slug,, .tSC)
  If $$$ISERR(tSC) {
    Quit ..Process404()
  }

  Try {
    $$$ThrowOnError(##class(Conduit.Model.Article).%DeleteId(article.%Id()))
  }
  Catch (ex) {
    Return ..ProcessError(ex)
  }

  Quit {}
}

/// Get the comments for an article. Auth is optional<br/>
/// The method arguments hold values for:<br/>
///     slug, Slug of the article that you want to get comments for<br/>
ClassMethod GetArticleComments(slug As %String) As %DynamicObject
{
  If '..IsAuthorized(.user, 1) {
    Quit ..Process401()
  }

  Set rs = ##class(Conduit.Model.Comment).AllFunc(slug)

  Quit ..outputSQL(rs, "comments", "Conduit.Model.Comment", "Comment")
}

/// Create a comment for an article. Auth is required<br/>
/// The method arguments hold values for:<br/>
///     slug, Slug of the article that you want to create a comment for<br/>
///     body, Comment you want to create<br/>
ClassMethod CreateArticleComment(slug As %String, body As %DynamicObject) As %DynamicObject
{
  If '..IsAuthorized(.user) {
    Quit ..Process401()
  }

  Set article = ##class(Conduit.Model.Article).slugOpen(slug,, .tSC)
  If $$$ISERR(tSC) {
    Quit ..Process404()
  }

  Try {
    Set body = $Select(body.%IsDefined("comment"): body.comment, 1: body)

    Set comment = ##class(Conduit.Model.Comment).%New()
    Set comment.author = user
    Set comment.article = article
    $$$ThrowOnError(comment.%JSONImport(body))
    $$$ThrowOnError(comment.%Save())
  }
  Catch (ex) {
    Return ..ProcessError(ex)
  }

  Quit ..outputObject("comment", comment, "Comment")
}

/// Delete a comment for an article. Auth is required<br/>
/// The method arguments hold values for:<br/>
///     slug, Slug of the article that you want to delete a comment for<br/>
///     id, ID of the comment you want to delete<br/>
ClassMethod DeleteArticleComment(slug As %String, id As %Integer) As %DynamicObject
{
  If '..IsAuthorized(.user) {
    Quit ..Process401()
  }

  Set article = ##class(Conduit.Model.Article).slugOpen(slug,, .tSC)
  If $$$ISERR(tSC) {
    Quit ..Process404()
  }

  Set comment = ##class(Conduit.Model.Comment).%OpenId(id,, .tSC)
  If $$$ISERR(tSC) {
    Quit ..Process404()
  }

  If comment.article'=article {
    Quit ..Process404()
  }

  try {
    $$$ThrowOnError(##class(Conduit.Model.Comment).%DeleteId(id))
  }
  Catch ex {
    Return ..ProcessError(ex)
  }

  Quit {}
}

/// Favorite an article. Auth is required<br/>
/// The method arguments hold values for:<br/>
///     slug, Slug of the article that you want to favorite<br/>
ClassMethod CreateArticleFavorite(slug As %String) As %DynamicObject
{
  If '..IsAuthorized(.user) {
    Quit ..Process401()
  }

  Set article = ##class(Conduit.Model.Article).slugOpen(slug,, .tSC)
  If $$$ISERR(tSC) {
    Quit ..Process404()
  }

  Try {
    Set article.favorited = 1
    $$$ThrowOnError(article.%Save())

    Return ..outputObject("article", article, "Article")
  }
  Catch (ex) {
    Return ..ProcessError(ex)
  }

  Quit ""
}

/// Unfavorite an article. Auth is required<br/>
/// The method arguments hold values for:<br/>
///     slug, Slug of the article that you want to unfavorite<br/>
ClassMethod DeleteArticleFavorite(slug As %String) As %DynamicObject
{
  If '..IsAuthorized(.user) {
    Quit ..Process401()
  }

  Set article = ##class(Conduit.Model.Article).slugOpen(slug,, .tSC)
  If $$$ISERR(tSC) {
    Quit ..Process404()
  }

  Try {
    Set article.favorited = 0
    $$$ThrowOnError(article.%Save())

    Return ..outputObject("article", article, "Article")
  }
  Catch (ex) {
    Return ..ProcessError(ex)
  }

  Quit ""
}

/// Get tags. Auth not required
ClassMethod GetTags() As %DynamicObject
{
  If '..IsAuthorized(.user, 1) {
    Quit ..Process401()
  }

  Set rs = ##class(Conduit.Model.Article).AllTagsFunc()

  Quit ..outputSQL(rs, "tags")
}

}
