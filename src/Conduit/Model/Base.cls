Class Conduit.Model.Base Extends %JSON.Adaptor [ Abstract ]
{

Property createdAt As %TimeStamp [ InitialExpression = {$ZDatetime($ZTimestamp, 3, 1, 3)} ];

Property updatedAt As %TimeStamp;

Method %OnBeforeSave(insert As %Boolean) As %Status
{
  Set tSC = $$$OK

  Set ..updatedAt = $ZDatetime($ZTimestamp, 3, 1, 3)
	Quit tSC
}

}
