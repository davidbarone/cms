@ECHO OFF
CLS

:menu
CLS
ECHO --------------------------------------------------------------------------------
ECHO                            DBARONE MAINTENANCE MENU                             
ECHO          Note: This script requires that puTTY is installed in the path.
ECHO --------------------------------------------------------------------------------
ECHO.
ECHO FILES / HOST                           DOCKER
ECHO.
ECHO 1 - Copy client to linode - ALL        4 - Display docker images on linode host
ECHO 2 - Copy client to linode - Dockerfile 5 - Display docker containers on linode host
ECHO 3 - Copy linode to client - ALL        6 - Delete a docker image on linode host
ECHO A - Log into linode host               7 - Delete a docker container on linode host
ECHO Q - Quit program                       8 - Build image from Dockerfile
ECHO                                        9 - Linode SUB MENU
ECHO.                              
ECHO LUA APP CONTAINER                      LUA DB CONTAINER
ECHO.
ECHO B - Launch interactive lua container 
ECHO.
:start
set /P c=Select option:
if /I "%c%" EQU "1" goto :do_1
if /I "%c%" EQU "2" goto :do_2
if /I "%c%" EQU "3" goto :do_3
if /I "%c%" EQU "4" goto :do_4
if /I "%c%" EQU "5" goto :do_5
if /I "%c%" EQU "6" goto :do_6
if /I "%c%" EQU "7" goto :do_7
if /I "%c%" EQU "8" goto :do_8
if /I "%c%" EQU "9" goto :do_9
if /I "%c%" EQU "A" goto :do_A
if /I "%c%" EQU "B" goto :do_B
if /I "%c%" EQU "Q" goto :quit
goto :start

:do_1
REM Delete files on linode host (in home path)
PLINK david@173.230.152.164 rm -rf ~/docker; mkdir ~/docker
REM Copy files from client to linode host
PSCP -r ./src/* david@173.230.152.164:/home/david/docker
goto :end

:do_2
PSCP -r ./src/lua.Dockerfile david@173.230.152.164:/home/david/docker
goto :end

:do_3
del ./src -r
mkdir ./src
PSCP -r david@173.230.152.164:/home/david/docker ./src
goto :end

:do_4
PLINK david@173.230.152.164 docker images
goto :end

:do_5
PLINK david@173.230.152.164 docker ps -a
goto :end

:do_6
PLINK david@173.230.152.164 docker images
set /P id=Enter name of image to delete:
PLINK david@173.230.152.164 docker rmi %id% -f
goto :end


:do_8
set /P name=Enter name of docker image to create:
PLINK david@173.230.152.164 cd /home/david/docker; docker build -f ./lua.Dockerfile . -t %name%
goto :end

:do_9
PUTTY -ssh david@173.230.152.164 -m cmd.txt -t
goto :end

:do_A
PUTTY david@173.230.152.164
goto :end

:do_B
set /P image=Enter name of docker image to instantiate:
set /P container=Enter name of container:
set /P port=Enter port number:

:B_choice
set /P c=Do you want to remove container on exit [Y/N]?
if /I "%c%" EQU "Y" (
	@echo docker run --rm -it -p %port%:80 --name %container% %image% bin/bash > cmd.txt
	PUTTY -ssh david@173.230.152.164 -m cmd.txt -t
	PAUSE
	del cmd.txt
	goto :end
)
if /I "%c%" EQU "N" (
	@echo docker run -it -p %port%:80 --name %container% %image% bin/bash > cmd.txt
	PUTTY -ssh david@173.230.152.164 -m cmd.txt -t
	PAUSE
	del cmd.txt
	goto :end
)
goto :choice

:end
PAUSE The script has completed. Press a key to return to menu.
goto :menu

:quit
EXIT
