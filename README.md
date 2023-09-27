This repository contains the work I did for a previous employer to automate the software release process. I wrote everything in PowerShell and split them up into modules for each step of the process.

## Summary
The following is all of the modules and a description of their function, in the order they would be run during the automated process.

### Read-ReleaseEmail.ps1
Software releases were distributed via a release email that contained the changed software components. This script is given the subject line of that email, reads the email, collects the installer files and creates a CSV file with the names of the components that are being changed and the new version numbers. 

### Write-ComponentsYAML
In the configs folder there is a components.yaml file. That yaml file contains information specifc to each software component, like the type of software the component is (service/application), the default machine that they are downloaded to and the templeted service names. This module takes the CSV file created during the previous step and fills in the file with the respective information for the changed components. This yaml file will be used for the next step

### StageComponents
Using the components.yaml file that was created in the previous step, this module reads the components that are being changed and moves the necessary files and installer to it's respective machine. After this, someone would have to manually remote desktop into each machine and run the installers. This is the only part that I hadn't automated, but I did plan on working on this.

### Switch-StartupToolXML
Most of the services are started and stopped through an app. There is an XML file with information that points to the components that are started by the app. This module updates the XML file to include the updated components using the components.yaml

### Generate-Gameplan
The normal process for switching over the out going software to the new software included a number of people manually switching enabling and disabling services, and manually creating and moving shortcuts for applications. This module generated a PowerShell script that could be run to automate this step. It runs based on the components that are marked as changed in the components.yaml file and writes a PowerShell command based on the information in that file. This script makes use of the Create-Shortcut, StartStop-Service and Switch-Symlink modules which are the general actions that are done during the software switch over.

