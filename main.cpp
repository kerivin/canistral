#include <QApplication>
#include <QMainWindow>
#include <sqlite3.h>

#ifdef HAS_LIBREOFFICE
#include <uno/environment.h>
#endif

int main(int argc, char *argv[]) {
    // Must create QApplication first
    QApplication app(argc, argv);
    
    // Then create widgets
    QMainWindow mainWindow;
    mainWindow.setWindowTitle("Canistral");
    mainWindow.resize(800, 600);
    mainWindow.show();

    // SQLite example
    sqlite3 *db;
    if(sqlite3_open(":memory:", &db) == SQLITE_OK) {
        sqlite3_close(db);
    }

    #ifdef HAS_LIBREOFFICE
    // LibreOffice initialization
    uno_Environment *env;
    uno_initEnvironment(&env);
    #endif

    // Start event loop
    return app.exec();
}