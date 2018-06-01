param([string] $xmlFilePath='D:\test\edenscom_not_grouped_Dev.xml')

[xml] $xmlContent = [xml] (Get-Content -Path $xmlFilePath)

# the next line is missing in 99% of all examples I have seen

[System.Xml.XmlElement] $root = $xmlContent.get_DocumentElement()

# notice the corresponding change in the next line

[System.Xml.XmlElement] $Properties = $root.Properties

[System.Xml.XmlElement] $Property = $null

foreach($Property in $properties.ChildNodes)

{

[string] $title = $property.Title
[string] $description = $Property.Description

Write-Host (“Title={0},Description={1}” -f $title,$description)

}