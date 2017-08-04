# AzureSiteRecoverySetup
Using PowerShell to automate the setup and configuration of Azure Site Recovery

PowerShell script to automate the entire setup and configuration of ASR for VMware and Physical servers.

The sections commented out are the automated process of downloading the Configr & Process server (MicrosoftAzureSiteRecoveryUnifiedSetup.exe), extracting it, creating the MySQL credentials file for the installation of MySql. Then running the installation of the Config & Process server silently, using the MySql credentials file.  And also where to download the Mobility Service installer, with a link to the instructions to install it from the cmd line.  If you are going to install the Config & Process server on the same server you run the script from you could use the code included to complete that as well.


