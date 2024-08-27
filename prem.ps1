#& "C:\Users\musta\Downloads\azcopy_windows_amd64_10.26.0\azcopy_windows_amd64_10.26.0\azcopy.exe" --version


#Connect-AzAccount -devicecode

#Set-AzContext -Subscriptionid "cab0dd75-6443-42cd-887e-ad4a333f38c9"

& "C:\Users\musta\Downloads\azcopy_windows_amd64_10.26.0\azcopy_windows_amd64_10.26.0\azcopy.exe" copy "https://testingpremncr.file.core.windows.net/seh?sv=2022-11-02&ss=f&srt=sco&sp=rwdlc&se=2024-08-11T22:46:01Z&st=2024-08-11T14:46:01Z&spr=https,http&sig=Erd6u0rDrErhfIQlatxC1IXQyuQZYGdf7JAawcAnznw%3D" "https://testingpremnco.file.core.windows.net/sehrish?sv=2022-11-02&ss=f&srt=sco&sp=rwdlc&se=2024-08-11T22:47:43Z&st=2024-08-11T14:47:43Z&spr=https,http&sig=KxIffsVnEsX0Dl08M06O0nmQeg6RHe%2BYb1S79enpVA0%3D" --recursive --overwrite=ifSourceNewer

