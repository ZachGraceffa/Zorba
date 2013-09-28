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
