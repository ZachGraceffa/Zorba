xquery version "3.0";

import module namespace xmldb = "http://exist-db.org/xquery/xmldb";
import module namespace oauth2 = "http://www.zachgraceffa.com/modules/oauth2/client" at "/db/apps/testing/oauth/oauth-lib";

(: getting parameters :)
let $path := request:get-parameter("state",0)
let $param-error := request:get-parameter("error",0)
let $param-code := request:get-parameter("code",0)

(: retieving service provider object :)
let $sp := oauth2:retrieve-sp($path)

(: constructing parameters object :)
let $parameters := oauth2:parameters((), "code", $param-code)

(: construct headers object for access token:)
let $header1 := oauth2:headers((), "Host", "accounts.google.com")
let $headers := oauth2:headers($header1, "Content-Type", "application/x-www-form-urlencoded")

(: getting access-token :)
let $token-data := oauth2:access-token($sp, $parameters, $headers)

(: extracting token out of post-response and formatting for protected resource call :)
let $post-decoded := tokenize($token-data, ',')
let $access-token := tokenize($post-decoded[1], '"')
let $access-token := $access-token[4]
let $token-type := tokenize($post-decoded[2], '"')
let $token-type := $token-type[4]
let $authorization := concat($token-type, " ", $access-token)

(: constructing headers object for protected-resource call :)
let $pr-header1 := oauth2:headers((), "Host", "www.spreadsheets.google.com")
let $pr-header2 := oauth2:headers($pr-header1, "GData-version", "3.0")
let $pr-header3 := oauth2:headers($pr-header2, "Content-length", "0")
let $pr-header := oauth2:headers($pr-header3, "Authorization", $authorization)

(: getting protected resource :)
let $pr := oauth2:protected-resource($sp, (), $pr-header)

return 
    if($param-error = 0)
    then
        <results>
            <location>{xmldb:store("/db/apps/ddex-transform/data", "spreadsheet-xml", $pr, "text/xml")}</location>
            <content>{$pr}</content>
        </results>
    else
        <results>
            ERROR!
        </results>
