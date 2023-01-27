# Home Assistant Add-on: NetFoundry OpenZITI

## Installation

Follow these steps to get the add-on installed on your system:

1. Navigate in your Home Assistant frontend to **Supervisor** -> **Add-on Store**.
2. Find the "NetFoundry OpenZITI" add-on and click it.
3. Click on the "INSTALL" button.

## How to Use

Regardless of which system controls the endpoint (CloudZITI or OpenZITI) the endpoint must be registered as a valid identity.

1. Register a new endpoint in your CloudZITI or OpenZITI control system.
2. A JWT (Java Web Token) is the output, in plain ASCII text, of the ZITI Controller. You will need to copy the text within the JWT file and paste it exactly into the configuration pane's "Enrollment JWT" field.
3. Once successfully registered after the application is started (Check Logs), remove the JWT text from the field. If this is not done, re-enrollment will be attempted at each startup delaying the startup.

You may register more than one identity (once per application startup) if desired, however, at least one identity is required to run.

For more information, see the open source project page at [OpenZITI](https://github.com/openziti).
