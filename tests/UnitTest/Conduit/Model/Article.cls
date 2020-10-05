Class UnitTest.Conduit.Model.Article Extends %UnitTest.TestCase
{

/// Test for url compatible article identifier aka slug
/// generated from article's title
Method "Test slugify"()
{
  #define slugify(%s) ##class(Conduit.Model.Article).slugify(%s)
  #define check(%s,%v) $$$AssertEquals($$$slugify(%s), %v, %s_" -> "_%v)

  #; lowercase
  Do $$$check("TeSt", "test")

  #; remove non-ascii
  Do $$$check("TeSt-Тест", "test")

  #; replace diacritics
  Do $$$check("Caché", "cache")

  #; '&' letter
  Do $$$check("Caché&IRIS", "cache-and-iris")

  #; with numbers
  Do $$$check("IRIS 2020.3", "iris-20203")
}

}
