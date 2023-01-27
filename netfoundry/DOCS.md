# Home Assistant Add-on: NetFoundry OpenZITI

## What is NetFoundry OpenZITI?

This add-on adds the following functionality to your Home Assistant:

- An ultra secure and smart overlay which can be accessed by this endpoint.
- Upon service assignment, this endpoint can reach private resources or permit access to its own private resources as deemed in the CloudZITI NetFoundry Console (or OpenZITI open source variant.)
- This is useful for allowing your Home Assistant to reach and extend access to non-local resources (perhaps geographically or in different VLANs).

## Installation

Follow these steps to get the add-on installed on your system:

1. Navigate in your Home Assistant frontend to **Supervisor** -> **Add-on Store**.
2. Find the "NetFoundry OpenZITI" add-on and click it.
3. Click on the "INSTALL" button.

## How to Use

Regardless of which system controls the endpoint (CloudZITI or OpenZITI) the endpoint must be registered as a valid identity.

1. Register a new endpoint in your CloudZITI or OpenZITI control system.
2. A JWT (Java Web Token) is the output, in plain ASCII text, of the ZITI Controller. You will need to copy the text within the JWT file and paste it exactly into the configuration pane's "EnrollmentJWT" field.
3. Once successfully registered after the application is started (Check Logs), you may remove the JWT text from the field.

You may register more than one identity (once per application startup) if desired, however, at least one identity is required to run.

For more information, see the open source project page at [OpenZITI](https://github.com/openziti).
