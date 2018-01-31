# devopsflex-vsts-tasks
Custom tasks written to make VSTS build / release definitions more readable and reusable for our multi environment, multi tenanted eco system.

[](https://eshopworld.visualstudio.com/_apis/public/build/definitions/310eec01-7d3c-402e-b179-74a206e8d4e3/116/badge)

## Structure 

The overall folder structure is shown below. If you are adding a new task then follow the pattern by creating a project and then adding it to the solution.

```
├── src    
    ├── ServiceFabricUpdater 
        └── ServiceFabricUpdater.csproj      
    └── [YOUR_NEW_TASK] 
        └── [YOUR_NEW_TASK].csproj]
    └── VSTSExtensionTasks.sln   
├── .gitignore                     
├── LICENSE    
├── README.md                  

```

## Creating a new task

An easy way to create a new task is to use [yeoman](http://yeoman.io/) to scaffold out the basics, see [ALM Rangers Generator](https://github.com/ALM-Rangers/generator-vsts-extension) for a full tutorial.

## Task List

- [Service Fabric Updater](https://github.com/eShopWorld/devopsflex-vsts-tasks/blob/master/src/ServiceFabricUpdater/overview.md)
