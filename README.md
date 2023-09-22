This repository contains the work I did for a previous employer to automate the software release process. I wrote everything in PowerShell and split them up into modules for each step of the process.

## Summary
The following is all of the modules and a description of their function, in the order they would be run during the automated process.

### Read-ReleaseEmail.ps1
Software releases were distributed via a release email that contained the changed software components. This script is given the subject line of that email, reads the email, collects the installer files and creates a CSV file with the names of the components that are being changed and the new version numbers. 

### Write-ComponentsYAML
In the configs folder there is a components.yaml file. That yaml file contains information specifc to each software component, like the type of software the component is (service/application), the default machine that they are downloaded to and the templeted service names. This module takes the CSV file created during the previous step and fills in the file with the respective information for the changed components. This yaml file will be used for the next step

### StageComponents


### Generate-Gameplan