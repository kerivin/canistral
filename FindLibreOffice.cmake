if(WIN32)
    set(LibreOffice_DIR "C:/Program Files/LibreOffice/sdk" CACHE PATH "LibreOffice SDK path" FORCE)
    set(LibreOffice_INCLUDE_DIRS
        "C:/Program Files/LibreOffice/sdk/include"
    )
    set(LibreOffice_LIBRARIES
        "C:/Program Files/LibreOffice/program/cppuhelper.dll"
    )
    execute_process(COMMAND ${LibreOffice_DIR}/setsdkenv_windows.bat)
elseif(APPLE)
    set(LibreOffice_DIR "/usr/local/opt/libreoffice/sdk" CACHE PATH "LibreOffice SDK path" FORCE)
    set(LibreOffice_INCLUDE_DIRS
        "/Applications/LibreOffice.app/Contents/Resources/include"
    )
    set(LibreOffice_LIBRARIES
        "/Applications/LibreOffice.app/Contents/Resources/lib/libcppuhelper.dylib"
    )
    execute_process(COMMAND ${LibreOffice_DIR}/setsdkenv_unix.sh)
else()
    set(LibreOffice_DIR "/usr/lib/libreoffice/sdk" CACHE PATH "LibreOffice SDK path" FORCE)
    set(LibreOffice_INCLUDE_DIRS 
        "${LibreOffice_DIR}/include"
    )
    set(LibreOffice_LIBRARIES
        "${LibreOffice_DIR}/lib/libuno_cppuhelpergcc3.so"
        "${LibreOffice_DIR}/lib/libuno_sal.so"
    )
    execute_process(COMMAND ${LibreOffice_DIR}/setsdkenv_unix.sh)
endif()