## Configuring UAA for Web-based Mobile App Authentication

Mobile Apps using web-based authentication often need to use the `authorization_code` grant type. With this grant type, you need to configure a redirect URI that the web browser will redirect to after successful authentication. The mobile operating systeem needs to recognize this redirect is related to the Mobile App, rather than just being a new page the browser should load. Usually this is accomplished by using a non-http(s) redirect schemes. The Mobile Application registers this scheme with the operating system, thus the Mobile device knows that when it encounters this scheme, it should allow the Mobile App to handle it. Configuring Predix UAA to use a non-http(s) scheme is possible, but unfortunately at this time is not supported by the UAA web interface; the UAA CLI is needed. The steps required to add a non-http(s) redirect URI are as follows:

1. Using the UAA CLI (uaac) login to your UAA service instance with your administrative account: 

   ```
	uaac target https://{your_UAA_service}
	
	uaac token client get admin -s {admin_password}
	```

2. 	Next you need the identifier of the Identity Zone for your UAA instance. This can be obtained in a few ways. The simplest is to log into the UAA Web dashboard, go to the Client Management tab, and look at the "admin" client. This client should have an authority for the zone that looks like: `zone.92ebf753-a472-5eb4-fbc8-a5582655b551.admin` In this case the zone identifier is "92ebf753-a472-5eb4-fbc8-a5582655b551". Alternatively the zone id can be obtained through the uaac tool. The command `uaac curl -k /identity-zones` will output the configuration for all the configured identity zones, the identifier of the zone is among the output. So a command like: 

  `uaac curl -k /identity-zones | grep "\"id\""`

   Will output a line like:

   `"id": "92ebf753-a472-5eb4-fbc8-a5582655b551",`

3. Now that the zone identifier is known, the entire zone configuration can be retrieved:

   `uaac curl -k /identity-zones/{zone_identifier} > zone.json`

   This creates a file named zone.json on your local machine that contains the zone configuration, among some other data.

4. Open the newly-created zone.json file in your prefered text editor. Find the line that says "RESPONSE BODY:" and remove this line, and all lines above it. The first line of the file should now contain only a single open brace: "{".

5.  Now find the key "redirectURIProtocolWhiteList". This should look like:

    ```
      ...
      },
      "redirectURIProtocolWhiteList": [
        "http",
        "https"
      ],
      ...
    ```
    
6. Add your non-http(s) URI protocol here, usually this will be short and related to your application. For this example we'll use "predixsdk":

    ```
      ...
      },
      "redirectURIProtocolWhiteList": [
        "http",
        "https",
        "predixsdk"
      ],
      ...
    ```

7. Save the file, then using the uaac tool, update the zone configuration:

	```
	uaac curl -k /identity-zones/{zone_identifier} -X PUT -H 'Content-Type: application/json' -d "$(cat zone.json)"
	```
	
8. Now you should be able to use the UAA web dashboard to create your client configuration, with a URI redirect using the newly created URI protocol. In your UAA dashboard go to Manage Clients, then create or edit the client you want to use with your Mobile App.

9. For web-based authentication ensure the Authorized Grant Types includes "authorization_code" (and optionally "refresh_token" to support biometric authentication.) and add a redirect URI that includes the newly created non-http(s) scheme. The redirect URI must be in the format: `{scheme}://{hostname}/{path}`. Even if the hostname and path are not strictly needed by your mobile app, the format must include them; for example, using the `predixsdk` scheme we added above, we can create a redirect URI like: `predixsdk://predix.io/authorization_grant`

#### Final steps, add the custom scheme to your Mobile App.
After adding your custom scheme to UAA, the final piece is registering this scheme in your mobile app. For iOS Apps, this is done in Xcode, via the app's Info.plist. Add a URL Type, with the URL Scheme configured in UAA. Note that only the URL Scheme is configured in the Info.plist, not the entire redirect URI.

After adding the URL Type to the info plist, you can then use a UAABrowserAuthenticationHandler or SFAuthenticationSessionHandler class with your redirect URL to perform web-based authentication against your UAA service.

For examples see the SafariViewControllerDemo or SFAuthenticationSessionDemo  projects.

