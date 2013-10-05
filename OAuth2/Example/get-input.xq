xquery version "3.0";

import module namespace oauth2 = "http://www.zachgraceffa.com/modules/oauth2/client" at "/db/apps/testing/oauth/oauth-lib";

(: creating protected resource url :)
let $spreadsheet-url := request:get-parameter("spreadsheet_url",0)
let $key := substring-after(substring-before($spreadsheet-url, "&amp;"), 'key=')
let $protected-resource-url := concat("https://spreadsheets.google.com/feeds/cells/", $key, "/1/private/full?min-row=1&amp;max-row=1")

(: some preliminary storage things :)
let $path := "/db/apps/oauth2/with-lib"
let $name := "storage"
let $state := concat($path, "/", $name)

(: Creating service provider object :)
let $sp := oauth2:service-provider("xxxxxxxxxxxxxxxxx", (:client id:)
                                   "xxxxxxxxxxxx", (:<<client secret :)  
                                   xs:anyURI("https://accounts.google.com/o/oauth2/auth?"),(:auth-grant url:)
                                   xs:anyURI("https://xxxxxxxxx.us-west-2.compute.amazonaws.com:8443/exist/apps/ddex-transform/token"), (:<<auth-grant redirect uri:)
                                   "code", (:<<response type:)
                                   $state, (:<<location of sp:)
                                   "https://spreadsheets.google.com/feeds", (:<<scope:)
                                    "force", (:<<approval prompt:)
                                   (), (: access type, if empty defaults to "online" :)
                                   xs:anyURI("https://accounts.google.com/o/oauth2/token"), (:access token url:)
                                   xs:anyURI("https://xxxxxxxxx.us-west-2.compute.amazonaws.com:8443/exist/apps/ddex-transform/token"), (:access token redirect url:)
                                   "authorization_code", (:<<grant type:) 
                                   $protected-resource-url)(:url of spreadsheet :)

(: storing sp object for retrieval after redirect :)
let $actual-state := oauth2:store-data($name, $path, $sp, $key)

(: sending authorization grant :)
return
    if($state = $actual-state)
    then
        oauth2:authorization-grant($sp, ())
    else
        <Error name="File Storage Error">
            <storage-location-stored>
                {$state}
            </storage-location-stored>
            <actual-storage-location>
                {$actual-state}
            </actual-storage-location>
        </Error>
