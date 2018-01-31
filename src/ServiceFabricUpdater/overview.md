## Service Fabric Updater ##

The **Service Fabric Updater** can update key parts of the Application and Service Manifest files at build or release time. 

Currently this task supports updating the following items:

**ApplicationManifest.xml**

- Application Version
    
    *There are two options for the version, full version replace or add a trailing revision to the current version.*

- Application Name

    **Tenant**

    *A tenant is a short code that can be used to define ownership of an application eg. 'Freight.Api.ServiceFabric-XXX' where XXX is the tenant.*

    **Environment**

    *An environment is another short code that can be selected from a drop down list to define the purpose of the application eg. 'Freight.Api.ServiceFabric-CI' where CI is the environment.*

**ServiceManifest.xml**

- Service Version

    *There are two options for the version, full version replace or add a trailing revision to the current version.*

- Port Number

    *The port the application should be accessed through.*

### Quick steps to get started ###

1. Ensure it is a Service Fabric project that is being built/released.
2. Add the 'Service Fabric Updater' custom task to the build or release definition.
3. Enter the required information.
4. Save the definition.
5. Queue a new build or create a new release.

### Known issue(s)

- None

### Learn More

The [source](https://github.com/eShopWorld/devopsflex-vsts-tasks) to this extension is available. Feel free to take, fork, and extend.

### Minimum supported environments ###

- Visual Studio Team Services

### Contributors ###

We thank the following contributor(s) for this extension: 

### Feedback ###
- Add a review below.