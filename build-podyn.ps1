# Build podyn for Windows and export to C:\Tools directory
mvn package

# Deploy to C:/tools
cp target/podyn-1.0.jar C:/tools/podyn-1.0.jar

# Make wrapper powershell script to call podyn and pass along args
echo 'java -jar C:/tools/podyn-1.0.jar $args' > C:/tools/podyn.ps1
