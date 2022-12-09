# ConfigMaps and Secrets

## Learning Goals

- learn how to create configmaps and secrets
- learn how to use configmaps and secrets in a deployment

## Introduction

Configmaps and secrets are a way to store information that is used by several deployments and pods in your cluster. In that way you have one place to change the information.

Both configmaps and secrets are key-value pairs, but secrets are encoded and configmaps are not.

> :bulb: Secrets are not encrypted, but they are encoded. This means that if someone gets access to the cluster, they can still read the values, but they are not in plain text.


## ConfigMaps

Configmaps are for configuration, that doesn't really belong in code but needs to change. Examples include loadbalancer configurations, jenkins configuration and so forth.

TODO: add more information
<details>
<summary>:bulb: If an explanaition becomes too long, the more detailed parts can be encapsulated in a drop down section</summary>
</details>

## Secrets

Secrets are a way to store things that you do not want floating around in your code.

It's things like passwords for databases, API keys and certificates.

Rather than hardcode this sensitive information and commit it to git for all the world to see, we source these values from environment variables.
TODO: add more information

## Exercise

### Overview

- Add the database part of the application
- Change the database user into a configmap and implement that in both backend and database
- Change the database password into a secret, and implement that in both backend and database.

### Step by step instructions

<details>
<summary>More Details</summary>

**take the same bullet names as above and put them in to illustrate how far the student have gone**

- all actions that you believe the student should do, should be in a bullet

> :bulb: Help can be illustrated with bulbs in order to make it easy to distinguish.

</details>

### Clean up

If anything needs cleaning up, here is the section to do just that.