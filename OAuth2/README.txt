Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

-----------------------------------------------------------------

This module was created to provide the user of this module, the "client," access to a user's, the "user,"    
protected resources stored by a third-party, the "service-provider," through the IETF standard 
OAuth2 (oauth.net/2/). The user of this module does not have to be familiar with the OAuth2 standard in 
order to use it.

The general flow of use for this module is as follows:
-Create a Service-Provider instance
-Add any additional parameters and/or headers as needed using the parameters function
-Store the Service-Provider instance and any other data as needed through the store-data function.
-Redirect the user by calling the authorization-grant function
     -It is recommended to pass the location of the stored resources through the "state" parameter
-Retrieve stored service provider instance and other-data if applicable using appropriate functions
-Extract "code" parameter from URL query body and use it to create a parameter
-Use retrieved data to obtain an access token using the "access-token" function
-Parse out the access token and use it to obtain the protected resource using the "protected-resource function"

@author Zach Graceffa
zachgraceffa@gmail.com
I am open to any criticisms or contributions :-)
