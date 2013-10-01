xquery version "3.0";
(:
 : Licensed under the Apache License, Version 2.0 (the "License");
 : you may not use this file except in compliance with the License.
 : You may obtain a copy of the License at
 :
 : http://www.apache.org/licenses/LICENSE-2.0
 :
 : Unless required by applicable law or agreed to in writing, software
 : distributed under the License is distributed on an "AS IS" BASIS,
 : WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 : See the License for the specific language governing permissions and
 : limitations under the License.
:)


(:~
 : This module was created to provide the user of this module, the "client," access to a user's, the "user,"    
 : protected resources stored by a third-party, the "service-provider," through the IETF standard 
 : OAuth2 (oauth.net/2/). The user of this module does not have to be familiar with the OAuth2 standard in 
 : order to use it.
 : 
 : The general flow of use for this module is as follows:
 : -Create a Service-Provider instance
 : -Add any additional parameters and/or headers as needed using the parameters function
 : -Store the Service-Provider instance and any other data as needed through the store-data function.
 : -Redirect the user by calling the authorization-grant function
 :      -It is recommended to pass the location of the stored resources through the "state" parameter
 : -Retrieve stored service provider instance and other-data if applicable using appropriate functions
 : -Extract "code" parameter from URL query body and use it to create a parameter
 : -Use retrieved data to obtain an access token using the "access-token" function
 : -Parse out the access token and use it to obtain the protected resource using the "protected-resource function"
 :) 

(:
 : @author Zach Graceffa
 : zachgraceffa@gmail.com
 : I am open to any criticisms or contributions :-)
:)

module namespace oauth2 = "http://www.zachgraceffa.com/modules/oauth2/client";

declare namespace response = "http://exist-db.org/xquery/response";
import module namespace httpclient = "http://exist-db.org/xquery/httpclient";
import module namespace util="http://exist-db.org/xquery/util";
import module namespace xmldb = "http://exist-db.org/xquery/xmldb";

(:~
 : The "service-provider" function is used to store all of the data required in the OAuth2 process. Cardinality of
 : the arguments of this function reflect the requirements of the OAuth2 requirements, exactly, as stated in its
 : spec (http://tools.ietf.org/html/rfc6749). Thus, this module should be compatible with any OAuth2 
 : implementation. 
 : If the OAuth2 implementation you are using requires additional information, it can be added using the 
 : "parameters" and "headers" functions respectively.
 :)
declare function oauth2:service-provider($client-id as xs:string, $client-secret as xs:string, $auth-grant-url as xs:anyURI, $auth-grant-redirect-uri as xs:anyURI, $response-type as xs:string, $state as xs:string?, $scope as xs:string?, $approval-prompt as xs:string?, $access-type as xs:string?, $access-token-url as xs:anyURI, $access-token-redirect-uri as xs:anyURI, $grant-type as xs:string, $protected-resource-url as xs:anyURI) as element(service-provider)
{
    <service-provider>
        <client_id>
            {$client-id}
        </client_id>
        <client_secret>
            {$client-secret}
        </client_secret>
        <authorization-grant>
            <url>
                {$auth-grant-url}
            </url>
            <redirect_uri>
                {$auth-grant-redirect-uri}
            </redirect_uri>
            <response_type>
                {$response-type}
            </response_type>
            <state>
                {$state}
            </state>
            <scope>
                {$scope}
            </scope>
            <approval_prompt>
                {$approval-prompt}
            </approval_prompt>
            <access_type>
                {if(empty($access-type))
                 then
                     "online"
                 else
                     $access-type}
            </access_type>
        </authorization-grant>
        <access-token>
            <url>
                {$access-token-url}
            </url>
            <redirect_uri>
                {$access-token-redirect-uri}
            </redirect_uri>
            <grant_type>
                {$grant-type}
            </grant_type>
        </access-token>
        <protected-resource>
            <url>
                {$protected-resource-url}
            </url>
        </protected-resource>
    </service-provider>
};

(:~
 : This function is to be used when additional parameters are needed. Use this function by passing in the name 
 : and value of parameters you would like to add. It is also optional to pass an already created parameter as an
 : argument if multiple parameters are desired. A parameter will not be added if its value is not passed.
 :)
declare function oauth2:parameters($parameters as element(parameters)?, $name as xs:string, $value as xs:string?) as element(parameters)
{
    if(empty($parameters))
    then
        <parameters>
            <parameter name="{$name}" value="{$value}"/>
        </parameters>
    else if(empty($value))
    then
        $parameters
    else
        <parameters>
            {$parameters//parameter}
            <parameter name="{$name}" value="{$value}"/>
        </parameters>
};

(:~
 : This function is to be used when headers are needed in correspondences with the service provider. Use this
 : function by passing in the name and value of headers you would like to add. It is also optional to pass an 
 : already created header as an argument if multiple headers are desired. A header will not be added if its value
 : is not passed.
 :)
declare function oauth2:headers($headers as element(headers)?, $name as xs:string, $value as xs:string?) as element(headers)
{
    if(empty($headers))
    then
        <headers>
            <header name="{$name}" value="{$value}"/>
        </headers>
    else if(empty($value))
    then
        $headers
    else
        <headers>
            {$headers//header}
            <header name="{$name}" value="{$value}"/>
        </headers>
};

(:~
 : A private function to construct a valid url. The function also calls the 
 : "format-parameters" function on the $parameters argument. If no parameters are supplied,
 : the function simply returns the $url argument.
 :)
declare %private function oauth2:construct-url($url as xs:anyURI, $parameters as element(parameters)?) as xs:anyURI
{ 
    if(empty($parameters))
    then
        $url
    else
       xs:anyURI(concat($url, oauth2:format-parameters($parameters)))
};

(:~
 : A private function to  encode and format the parameters of a URI.
 :)
declare %private function oauth2:format-parameters($parameters as element(parameters)) as xs:string*
{
    let $formatted-parameters := 
        string-join( 
            let $x := $parameters//parameter
            let $y :=
                for $idx at $posx in $x
                return 
                    if ($idx/@name eq "scope")
                    then
                        let $scope :=
                            string-join(
                                for $idt at $post in tokenize($idx/@value, "\+")
                                return
                                    if($post = count($idx/@value))
                                    then 
                                        concat(encode-for-uri($idt), "+")
                                    else 
                                        encode-for-uri($idt),
                        "")
                        return
                            if ($posx = count($x))
                            then
                                concat($idx/@name, "=", $scope)
                            else
                                concat($idx/@name, "=", $scope, "&amp;")
                    else if ($posx = count($x))
                    then
                        concat($idx/@name, "=", encode-for-uri($idx/@value))
                    else
                        concat($idx/@name, "=", encode-for-uri($idx/@value), "&amp;")
            return 
                $y, "")
    return $formatted-parameters 
};

(:~
 : A function to redirect the user to a service-provider for authorization to use the protected resource. By default
 : this function adds the authorization grant redirect_uri, response_type, and client_id, and the contents of 
 : the $parameters argument as parameters of the redirect url. Parameters scope, approval_prompt, and state are 
 : also added if their values were given during the initial creation of the service-provider instance. 
 :)
declare function oauth2:authorization-grant($service-provider as element(service-provider), $parameters as element(parameters)?)
{
    let $parameter1 := oauth2:parameters($parameters, "scope", $service-provider//authorization-grant/scope/text())
    let $parameter2 := oauth2:parameters($parameter1, "redirect_uri", $service-provider//authorization-grant/redirect_uri/text())
    let $parameter3 := oauth2:parameters($parameter2, "response_type", $service-provider//authorization-grant/response_type/text())
    let $parameter4 := oauth2:parameters($parameter3, "client_id", $service-provider//client_id/text())
    let $parameter5 := oauth2:parameters($parameter4, "approval_prompt", $service-provider//authorization-grant/approval_prompt/text())
    let $parameter6 := oauth2:parameters($parameter5, "access_type", $service-provider//authorization-grant/access_type/text())
    let $full-parameters := oauth2:parameters($parameter6, "state", $service-provider//authorization-grant/state/text())
    return
        response:redirect-to(oauth2:construct-url($service-provider//authorization-grant/url/text(), $full-parameters))
};

(:~
 : A function to obtain an access token from the service provider using the code obtained from the 
 : authorization grant. According to OAuth2 specifications, this is done using a "post" request. Client_id,
 : redirect_uri, client_secret, and grant_type, and the $parameters argument are added to the body of 
 : the "post" request by default. The $headers argument will also be added to the header of the "post" request 
 : if supplied. The $parameters argument is required for this function because it is necessary to add the 
 : "code" parameter in order to obtain an access token.
 :)
declare function oauth2:access-token($service-provider as element(service-provider), $parameters as element(parameters), $headers as element(headers)?) as xs:string
{
    if(contains(lower-case($parameters//parameter/@name), "code"))
    then
        let $parameter1 := oauth2:parameters($parameters, "client_id", $service-provider//client_id/text())
        let $parameter2 := oauth2:parameters($parameter1, "redirect_uri", $service-provider//access-token/redirect_uri/text())
        let $parameter3 := oauth2:parameters($parameter2, "client_secret", $service-provider//client_secret/text())
        let $content := oauth2:format-parameters(oauth2:parameters($parameter3, "grant_type", $service-provider//access-token/grant_type/text()))
        let $post-response := httpclient:post($service-provider//access-token/url/text(), $content, false(), $headers)//httpclient:body/text()
        return util:base64-decode($post-response)
    else
        concat("Supplied $parameters argument did not contain a 'code' parameter:", xs:string($parameters))
    
};

(:~
 : A function to obtain an access token from the service provider using the refresh-token obtained from the 
 : authorization grant. According to OAuth2 specifications, this is done using a "post" request. Client_id,
 : client_secret, and grant_type, and the $parameters argument are added to the body of 
 : the "post" request by default. The $headers argument will also be added to the header of the "post" request 
 : if supplied. The $parameters argument is required for this function because it is necessary to add the 
 : "code" parameter in order to obtain an access token.
 :)
declare function oauth2:refresh-token($service-provider as element(service-provider), $parameters as element(parameters), $headers as element(headers)?) as xs:string
{
    if(contains(lower-case($parameters//parameter/@name), "refresh_token"))
    then
        let $parameter1 := oauth2:parameters($parameters, "client_id", $service-provider//client_id/text())
        let $parameter2 := oauth2:parameters($parameter1, "client_secret", $service-provider//client_secret/text())
        let $content := oauth2:format-parameters(oauth2:parameters($parameter2, "grant_type", "refresh_token"))
        let $post-response := httpclient:post($service-provider//access-token/url/text(), $content, false(), $headers)//httpclient:body/text()
        return util:base64-decode($post-response)
    else
        concat("Supplied $parameters argument did not contain a 'code' parameter:", xs:string($parameters))
    
};

(:~
 : Function to get the protected resource using a "get" request. "Get" request is made using the 
 : protected-resource url provided in the creation of the service provider instance. The arguments $parameters 
 : and $headers are included in "get" request if supplied.
 :)
declare function oauth2:protected-resource($service-provider as element(service-provider), $parameters as element(parameters)?, $headers as element(headers)?)
{
    httpclient:get(oauth2:construct-url($service-provider//protected-resource/url/text(), $parameters), false(), $headers)//httpclient:body
};

(:~
 : Function to get the protected resource, using a URL not in your service-provider, using a "get" request. "Get" request is made using the 
 : protected-resource url provided in the creation of the service provider instance. The arguments $parameters 
 : and $headers are included in "get" request if supplied.
 :)
declare function oauth2:protected-resource1($url as xs:anyURI, $parameters as element(parameters)?, $headers as element(headers)?)
{
    httpclient:get(oauth2:construct-url($url, $parameters), false(), $headers)//httpclient:body
    
};

(:~
 : A function to store the service-provider instance as well as any other data that needs to be stored for
 : retrieval after the user is directed back to the client from the service provider during the 
 : authorization grant process. It is recommended that the "state" parameter is used to hold the path + name 
 : and that any information that would have been stored in the "state" parameter to be stored using the $other
 : argument of this function.
 :)
declare function oauth2:store-data($name as xs:string, $path as xs:string, $service-provider as element(service-provider), $other as item()?) as xs:string
{
    try
    {
        let $data := 
            if(empty($other))
            then
                <data>
                    {$service-provider}
                </data>
            else
                <data>
                    {$service-provider}
                    <other>
                        {$other}
                    </other>
                </data>
        return
            xmldb:store($path, $name, $data, "text/xml")
    }
    catch *
    {
        concat("Could not store data at ", $path, " with the name ", $name, ". Please verify that the path exists and that correct permissions are placed on the collection.")
    }
};

(:~
 : A function to retrieve the service provider stored for retrieval after the authorization grant process.
 :)
declare function oauth2:retrieve-sp($path as xs:string) as element(service-provider)
{
    try
    {
        let $data := doc($path)
        return $data//service-provider
    }
    catch *
    {
        concat("Could not retrieve service provider from ", $path, ". Please double-check that the path is correct.")
    }
};

(:~
 : A function to retrieve the "other-data" stored for retrieval after the authorization grant process.
 :)
declare function oauth2:retrieve-other-data($path as xs:string) as item()
{
    try
    {
        let $data := doc($path)
        return 
            $data//other
    }
    catch *
    {
        concat("Error retrieving other-data from ", $path, ".")
    }
};
